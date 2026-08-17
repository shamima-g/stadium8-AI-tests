/**
 * Per-epic state.json — schema validation, transition-graph shape, and a
 * drift guard that pins the template's phase/status enums to the documented
 * epic-branch contract.
 *
 * The schema is single-sourced from `.claude/scripts/lib/epic-state.js`
 * (see helpers/schemas/epic-state.schema.ts), so it can't drift from the producer.
 * This suite additionally asserts the template's enums still match the model this
 * suite (and workflow-tests.md) is written against — if the template changes its
 * phases, that's an intentional change and this test forces the docs/fixtures to
 * be updated alongside it.
 */

import { it, expect } from 'vitest';
import Ajv from 'ajv';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, seedEpicState, runScript } from '../../helpers';
import {
  epicStateSchema,
  defaultEpicState,
  EPIC_PHASES,
  STORY_STATUS_VALUES,
  E2E_STATUS_VALUES,
  VALID_TRANSITIONS,
} from '../../helpers/schemas/epic-state.schema';
import type { TempProject } from '../../helpers/temp-project';

const ajv = new Ajv({ allErrors: true, strict: false });
const validate = ajv.compile(epicStateSchema);

describe('state.json schema — valid documents', () => {
  it('PASS: defaultEpicState() output validates', () => {
    const state = defaultEpicState({ slug: 'task-browsing', name: 'Task Browsing' });
    expect(validate(state), JSON.stringify(validate.errors, null, 2)).toBe(true);
  });

  it('PASS: a hand-seeded epic state (BUILD, mixed story statuses) validates', () => {
    const p = createTempProject();
    try {
      seedEpicState(p.root, {
        slug: 'task-browsing',
        name: 'Task Browsing',
        phase: 'BUILD',
        stories: {
          '1': { status: 'complete', commit: 'abc1234', e2eStatus: 'passed' },
          '2': { status: 'in-progress' },
        },
      });
      const state = JSON.parse(p.read('generated-docs/epics/task-browsing/state.json'));
      expect(validate(state), JSON.stringify(validate.errors, null, 2)).toBe(true);
    } finally {
      p.cleanup();
    }
  });

  it('PASS: every phase in the enum is a valid state.phase', () => {
    for (const phase of EPIC_PHASES) {
      const state = { ...defaultEpicState({ slug: 'e', name: 'E' }), phase };
      expect(validate(state), `phase ${phase}: ${JSON.stringify(validate.errors)}`).toBe(true);
    }
  });

  it('PASS: the state.json written by `epic-state.js --init` validates', () => {
    const p = createTempProject();
    try {
      const r = runScript(
        '.claude/scripts/epic-state.js',
        ['--init', '--name', 'Task Browsing', '--branch', 'epic/task-browsing', '--root', p.root],
        { cwd: p.root },
      );
      expect(r.exitCode, r.stderr).toBe(0);
      const state = JSON.parse(p.read('generated-docs/epics/task-browsing/state.json'));
      expect(validate(state), JSON.stringify(validate.errors, null, 2)).toBe(true);
    } finally {
      p.cleanup();
    }
  });

  // Determinism: two `--init` runs with the same name/branch produce the SAME state.json once the
  // only-legitimately-varying fields (the createdAt/lastUpdated timestamps) are set aside. The
  // workflow relies on a fresh epic starting from an identical, predictable shape every time — a
  // stray env-dependent default or field-ordering wobble would break resume/replay downstream.
  it('PASS: `--init` is deterministic (identical state.json modulo timestamps)', () => {
    const initOnce = () => {
      const p = createTempProject();
      try {
        const r = runScript(
          '.claude/scripts/epic-state.js',
          ['--init', '--name', 'Task Browsing', '--branch', 'epic/task-browsing', '--root', p.root],
          { cwd: p.root },
        );
        expect(r.exitCode, r.stderr).toBe(0);
        const state = JSON.parse(p.read('generated-docs/epics/task-browsing/state.json')) as {
          epic: { createdAt?: unknown }; lastUpdated?: unknown;
        };
        // Prove the timestamps were actually present (so stripping them isn't hiding a diff),
        // then normalise them away — a record of *when*, not part of the initial shape.
        expect(typeof state.epic.createdAt, 'createdAt is stamped').toBe('string');
        expect(typeof state.lastUpdated, 'lastUpdated is stamped').toBe('string');
        state.epic.createdAt = '<ts>';
        state.lastUpdated = '<ts>';
        return JSON.stringify(state);
      } finally {
        p.cleanup();
      }
    };
    expect(initOnce()).toBe(initOnce());
  });
});

describe('state.json schema — invalid documents are rejected', () => {
  const base = () => defaultEpicState({ slug: 'task-browsing', name: 'Task Browsing' });

  it('FAIL: a phase not in EPIC_PHASES (e.g. legacy "INTAKE") is rejected', () => {
    expect(validate({ ...base(), phase: 'INTAKE' })).toBe(false);
  });

  it('FAIL: an unknown story status is rejected', () => {
    expect(validate({ ...base(), stories: { '1': { status: 'wip' } } })).toBe(false);
  });

  it('FAIL: a missing epic.slug is rejected', () => {
    const s = base() as { epic: Record<string, unknown> };
    delete s.epic.slug;
    expect(validate(s)).toBe(false);
  });

  it('FAIL: a non-kebab epic.slug is rejected', () => {
    const s = base() as { epic: Record<string, unknown> };
    s.epic.slug = 'Task Browsing';
    expect(validate(s)).toBe(false);
  });
});

describe('state.json — transition graph is well-formed', () => {
  it('PASS: every transition key and target is a known phase', () => {
    for (const [from, targets] of Object.entries(VALID_TRANSITIONS)) {
      expect(EPIC_PHASES, `from-phase ${from}`).toContain(from);
      for (const to of targets) {
        expect(EPIC_PHASES, `to-phase ${to}`).toContain(to);
      }
    }
  });

  it('PASS: PLAN → BUILD is allowed', () => {
    expect(VALID_TRANSITIONS['PLAN']).toContain('BUILD');
  });

  it('FAIL: PLAN → MANUAL-TEST is NOT a valid transition (proves the graph is restrictive)', () => {
    expect(VALID_TRANSITIONS['PLAN'] ?? []).not.toContain('MANUAL-TEST');
  });

  // The WHOLE allowed-move set, pinned to a hand-written literal (the human tripwire, like the
  // EPIC_PHASES pin below). This is what gives "only valid stage moves are accepted" real teeth:
  // every legal edge is enumerated, so adding a skip-a-stage edge (e.g. PLAN → COMPLETE) or
  // dropping the READY-TO-BUILD park fails here and forces a deliberate hand-edit + doc update.
  // NB this pins the transition TABLE the template exports; enforcing it at runtime (refusing a
  // move whose inputs aren't ready, and the per-story BUILD loop) is the orchestrator's job and is
  // exercised in Tier 3 — epic-state.js itself only writes the initial state via `--init`.
  it('PASS: VALID_TRANSITIONS equals the documented epic-branch graph', () => {
    expect(VALID_TRANSITIONS).toEqual({
      'PLAN': ['READY-TO-BUILD', 'BUILD'],
      'READY-TO-BUILD': ['BUILD'],
      'BUILD': ['EPIC-END'],
      'EPIC-END': ['MANUAL-TEST', 'BUILD'],
      'MANUAL-TEST': ['COMPLETE-ON-BRANCH', 'BUILD'],
      'COMPLETE-ON-BRANCH': ['COMPLETE'],
      'COMPLETE': [],
    });
  });
});

describe('state.json — enums match the documented epic-branch contract (drift guard)', () => {
  it('PASS: EPIC_PHASES equals the documented seven-stage list', () => {
    // Hand-pinned literal, NOT read from the contract — this is the human tripwire
    // (workflow-tests.md §13.1/§13.3). A phase change must fail here and force a
    // deliberate hand-edit + triage. v1.2.0 added READY-TO-BUILD (the /plan
    // plan-ahead park, between PLAN and BUILD) — see CHANGELOG.md [1.2.0].
    expect(EPIC_PHASES).toEqual([
      'PLAN',
      'READY-TO-BUILD',
      'BUILD',
      'EPIC-END',
      'MANUAL-TEST',
      'COMPLETE-ON-BRANCH',
      'COMPLETE',
    ]);
  });

  it('PASS: STORY_STATUS_VALUES equals the documented set', () => {
    expect([...STORY_STATUS_VALUES].sort()).toEqual(
      ['complete', 'halted', 'in-progress', 'pending'].sort(),
    );
  });

  it('PASS: E2E_STATUS_VALUES contains the documented core statuses', () => {
    for (const s of ['deferred', 'passed', 'passed-after-fix', 'failed']) {
      expect(E2E_STATUS_VALUES).toContain(s);
    }
  });
});
