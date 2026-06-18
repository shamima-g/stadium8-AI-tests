/**
 * S8-76 Phase 5 — Tier 1 wiring lint for Gate 6 (spec-compliance watchdog).
 *
 * Asserts that the watchdog is wired into the QA pipeline at three integration
 * points. Without these, Gate 6 silently disappears even if the agent file
 * itself is correct.
 *
 * Specifically checks:
 *   - .claude/policies/quality-gates.md lists "Gate 6" with `spec-compliance-watchdog` as the runner
 *   - .claude/shared/orchestrator-rules.md places the watchdog between manual-verification
 *     and code-reviewer Call C on BOTH the no-issues path and the fix-cycle ("Issues found") path
 *   - .claude/agents/code-reviewer.md Call C staging includes `generated-docs/test-design/`
 *     (so Option B updates land in the commit)
 *
 * Pattern source: consistency/cross-doc-references.test.ts
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const QUALITY_GATES = path.join(REPO_ROOT, '.claude', 'policies', 'quality-gates.md');
const ORCH_RULES = path.join(REPO_ROOT, '.claude', 'shared', 'orchestrator-rules.md');
const CODE_REVIEWER = path.join(REPO_ROOT, '.claude', 'agents', 'code-reviewer.md');

describe('Gate 6 wired into quality-gates.md', () => {
  it('PASS: quality-gates.md declares Gate 6 with the watchdog as the runner', () => {
    const content = fs.readFileSync(QUALITY_GATES, 'utf8');

    expect(/Gate 6/.test(content), 'quality-gates.md must mention "Gate 6"').toBe(true);
    expect(
      /spec-compliance-watchdog/.test(content),
      'quality-gates.md must name spec-compliance-watchdog as the Gate 6 runner',
    ).toBe(true);

    // The agent must be referenced in proximity to Gate 6 (within ~30 lines of
    // a Gate 6 marker), not just mentioned anywhere in the file.
    const lines = content.split(/\r?\n/);
    const gate6Indices = lines
      .map((l, i) => (/Gate 6/.test(l) ? i : -1))
      .filter(i => i >= 0);
    const watchdogIndices = lines
      .map((l, i) => (/spec-compliance-watchdog/.test(l) ? i : -1))
      .filter(i => i >= 0);

    const proximate = gate6Indices.some(g =>
      watchdogIndices.some(w => Math.abs(g - w) <= 30),
    );
    expect(
      proximate,
      'spec-compliance-watchdog must be referenced within 30 lines of a Gate 6 marker',
    ).toBe(true);
  });
});

describe('Gate 6 wired into orchestrator-rules.md', () => {
  it('PASS: orchestrator-rules.md has a Spec Compliance Check section that names the watchdog', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');
    expect(
      /Spec Compliance Check[^\n]*Gate 6/.test(content),
      'orchestrator-rules.md must contain a "Spec Compliance Check (Gate 6)" section header',
    ).toBe(true);
    expect(
      content.match(/spec-compliance-watchdog/g)?.length ?? 0,
      'orchestrator-rules.md must reference spec-compliance-watchdog at least 3 times (definition + no-issues path + fix-cycle path)',
    ).toBeGreaterThanOrEqual(3);
  });

  it('PASS: orchestrator-rules.md references the watchdog on BOTH the no-issues and fix-cycle QA paths', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');

    // No-issues path: manual verification confirmed → spec compliance → Call C
    const noIssuesPath = /After the user confirms manual verification[\s\S]{0,2000}spec-compliance-watchdog/i.test(content)
      || /All tests pass[\s\S]{0,2000}spec-compliance-watchdog/i.test(content);
    expect(
      noIssuesPath,
      'orchestrator-rules.md must wire the watchdog into the no-issues QA path',
    ).toBe(true);

    // Fix-cycle path: "Issues found" / fix coordinator must mention the watchdog or the
    // spec-compliance check that follows the fix cycle.
    const fixCyclePath = /Issues found[\s\S]{0,4000}spec-compliance/i.test(content)
      || /fix coordinator[\s\S]{0,4000}spec-compliance/i.test(content)
      || /QA Fix Cycle[\s\S]{0,4000}spec-compliance/i.test(content);
    expect(
      fixCyclePath,
      'orchestrator-rules.md must wire the watchdog into the fix-cycle QA path too',
    ).toBe(true);
  });
});

describe('Gate 6 wired into code-reviewer Call C staging', () => {
  it('PASS: code-reviewer.md Call C stages generated-docs/test-design/ for Option B updates', () => {
    const content = fs.readFileSync(CODE_REVIEWER, 'utf8');

    // Either the explicit `git add ... generated-docs/test-design/ ...` line
    // or a documented staging step that names the directory is acceptable.
    const stages = /git add[^\n]*generated-docs\/test-design\//.test(content)
      || /stage[^\n]*generated-docs\/test-design\//i.test(content);
    expect(
      stages,
      'code-reviewer.md Call C must stage generated-docs/test-design/ so spec-compliance-watchdog Option B updates are committed',
    ).toBe(true);
  });
});

describe('Gate 6 wiring — failure-path coverage', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: tampered quality-gates.md without a Gate 6 marker is detected', () => {
    project.write('.claude/policies/quality-gates.md', '# Quality Gates\n\nGate 1 only.\n');
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'policies', 'quality-gates.md'),
      'utf8',
    );
    expect(/Gate 6/.test(content)).toBe(false);
  });

  it('FAIL: tampered orchestrator-rules.md missing the watchdog reference is detected', () => {
    project.write(
      '.claude/shared/orchestrator-rules.md',
      '# Orchestrator Rules\n\nNo spec compliance section here.\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'shared', 'orchestrator-rules.md'),
      'utf8',
    );
    expect(/spec-compliance-watchdog/.test(content)).toBe(false);
  });

  it('FAIL: tampered code-reviewer.md without test-design staging is detected', () => {
    project.write(
      '.claude/agents/code-reviewer.md',
      '# code-reviewer\n\nCall C: git add web/src/\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'agents', 'code-reviewer.md'),
      'utf8',
    );
    const stages = /git add[^\n]*generated-docs\/test-design\//.test(content)
      || /stage[^\n]*generated-docs\/test-design\//i.test(content);
    expect(stages).toBe(false);
  });
});
