/**
 * JSON-schema validation for generated-docs/context/workflow-state.json.
 *
 * Single source of truth: the schema's currentPhase enum is derived from the
 * template's own ALL_PHASES constant (.claude/scripts/lib/workflow-helpers.js) —
 * the same list transition-phase.js validates against — so this test cannot
 * drift from the producer. The "real producer output" block goes one step
 * further and validates the actual JSON transition-phase.js writes, not a fixture.
 */

import { it, expect } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import { createRequire } from 'node:module';
import path from 'node:path';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import {
  createTempProject,
  seedState,
  seedArtifact,
  readState,
  runScript,
  REPO_ROOT,
  TEMPLATE_PRESENT,
} from '../../helpers';
import type { Phase } from '../../helpers';
import { workflowStateSchema } from '../../helpers/schemas/workflow-state.schema';

// Same single source the schema derives from — used to drive the test loops.
const require = createRequire(import.meta.url);
// Only pull the template's phase constants when a template is present. This
// suite is gated on describeTemplate, so when it's absent these stay empty and
// the describes simply skip.
let ALL_PHASES: string[] = [];
let GLOBAL_PHASES: string[] = [];
if (TEMPLATE_PRESENT) {
  ({ ALL_PHASES, GLOBAL_PHASES } = require(
    path.join(REPO_ROOT, '.claude', 'scripts', 'lib', 'workflow-helpers.js')
  ) as { ALL_PHASES: string[]; GLOBAL_PHASES: string[] });
}

const ajv = new Ajv({ allErrors: true, strict: false });
addFormats(ajv);
// Only compile when a template exists — without one the schema's phase enum is
// derived as empty (invalid for ajv), and this whole suite is skipped anyway.
const validate = (TEMPLATE_PRESENT
  ? ajv.compile(workflowStateSchema)
  : (() => false)) as unknown as ReturnType<typeof ajv.compile>;

describe('workflow-state.json schema', () => {
  it('PASS: a fresh default-seeded state validates', () => {
    const p = createTempProject();
    try {
      seedState(p.root);
      const state = JSON.parse(p.read('generated-docs/context/workflow-state.json'));
      const ok = validate(state);
      expect(ok, JSON.stringify(validate.errors, null, 2)).toBe(true);
    } finally {
      p.cleanup();
    }
  });

  it('PASS: every phase the producer can emit validates (derived from ALL_PHASES)', () => {
    expect(ALL_PHASES.length).toBeGreaterThan(0);
    for (const phase of ALL_PHASES) {
      const p = createTempProject();
      try {
        seedState(p.root, { currentPhase: phase as Phase });
        const state = JSON.parse(p.read('generated-docs/context/workflow-state.json'));
        const ok = validate(state);
        expect(ok, `${phase}: ${JSON.stringify(validate.errors)}`).toBe(true);
      } finally {
        p.cleanup();
      }
    }
  });

  it('FAIL: a retired legacy phase is rejected', () => {
    // The old 9-phase model is gone — these must no longer validate. Because the
    // enum is derived from ALL_PHASES, this stays correct without hand-editing.
    for (const phase of ['DESIGN', 'SCOPE', 'STORIES', 'TEST-DESIGN', 'IMPLEMENT', 'QA']) {
      expect(validate({ currentPhase: phase }), `${phase} should be rejected`).toBe(false);
    }
  });

  it('FAIL: an invalid phase value is rejected', () => {
    expect(validate({ currentPhase: 'BOGUS' })).toBe(false);
  });

  it('FAIL: a negative currentEpic is rejected', () => {
    expect(validate({ currentPhase: 'BUILD', currentEpic: -1 })).toBe(false);
  });

  it('FAIL: a missing currentPhase is rejected', () => {
    expect(validate({ featureName: 'Test' })).toBe(false);
  });
});

describe('workflow-state.json schema — real producer output conforms', () => {
  // Black-box: drive the actual transition-phase.js --init and validate the JSON
  // it writes. Catches shape drift the fixtures can't (e.g. fields the producer
  // emits that the schema would reject).
  const SCRIPT = '.claude/scripts/transition-phase.js';

  for (const phase of GLOBAL_PHASES) {
    it(`PASS: \`transition-phase.js --init ${phase}\` writes schema-valid state`, () => {
      const p = createTempProject();
      try {
        // PLAN and BUILD require a project brief to exist first; INTAKE does not
        // (and legitimately writes featureName: null in that case).
        if (phase !== 'INTAKE') seedArtifact(p.root, 'brief');

        const r = runScript(SCRIPT, ['--init', phase], { cwd: p.root });
        expect(r.exitCode, r.stderr || r.stdout).toBe(0);

        const state = readState(p.root);
        const ok = validate(state);
        expect(ok, JSON.stringify(validate.errors, null, 2)).toBe(true);
        expect(state.currentPhase).toBe(phase);
      } finally {
        p.cleanup();
      }
    });
  }
});
