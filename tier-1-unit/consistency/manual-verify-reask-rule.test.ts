/**
 * S8-80 Phase 5 — Tier 1 wiring lint for the QA manual-verification re-ask rule.
 *
 * When the user replies to the manual-verification AskUserQuestion with a
 * free-text question (instead of picking one of the three options), the
 * orchestrator must answer the question and then re-ask AskUserQuestion with
 * the FULL checklist re-displayed verbatim from the persisted file. The rule
 * that enforces this lives in `.claude/commands/continue.md` as the "Re-ask
 * rule (QA manual verification)" block introduced by commit e5e2a9a.
 *
 * Single-source-of-truth invariant: the rule lives ONLY in continue.md and
 * is NOT duplicated in `.claude/shared/orchestrator-rules.md`. Duplication
 * here is dangerous — Phase 0 verification confirmed only continue.md owns
 * this rule today, and Tier 2 / Tier 3 tests assume that. If a future change
 * accidentally copies the block into orchestrator-rules.md, the two copies
 * will drift over time and the contract degrades silently.
 *
 * Specifically checks:
 *   - .claude/commands/continue.md contains the literal "Re-ask rule (QA manual verification)"
 *     block including the substrings `free-text question`, `verbatim`, and
 *     `verification-checklist.md`
 *   - .claude/shared/orchestrator-rules.md does NOT contain a "Re-ask rule
 *     (QA manual verification)" block (single-source-of-truth invariant)
 *
 * Pattern source: consistency/cross-doc-references.test.ts, gate-6-wired.test.ts
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const CONTINUE_CMD = path.join(REPO_ROOT, '.claude', 'commands', 'continue.md');
const ORCH_RULES = path.join(REPO_ROOT, '.claude', 'shared', 'orchestrator-rules.md');

const REASK_HEADER = /Re-ask rule \(QA manual verification\)/;

describe('S8-80 — continue.md owns the QA manual-verification re-ask rule', () => {
  it('PASS: continue.md contains the "Re-ask rule (QA manual verification)" block', () => {
    const content = fs.readFileSync(CONTINUE_CMD, 'utf8');
    expect(
      REASK_HEADER.test(content),
      'continue.md must contain the literal "Re-ask rule (QA manual verification)" block — without it, the orchestrator forgets to re-display the checklist after a free-text user reply',
    ).toBe(true);
  });

  it('PASS: the re-ask block names the free-text branch, verbatim copy, and the checklist file', () => {
    const content = fs.readFileSync(CONTINUE_CMD, 'utf8');
    const lines = content.split(/\r?\n/);
    const headerIdx = lines.findIndex(l => REASK_HEADER.test(l));
    expect(headerIdx).toBeGreaterThanOrEqual(0);

    // The block proper should fit within ~6 lines after the header.
    const block = lines.slice(headerIdx, headerIdx + 8).join('\n');

    expect(
      /free-text question/.test(block),
      'the re-ask block must mention "free-text question" — that is the trigger for the rule',
    ).toBe(true);
    expect(
      /verbatim/i.test(block),
      'the re-ask block must require verbatim re-display',
    ).toBe(true);
    expect(
      /verification-checklist\.md/.test(block),
      'the re-ask block must point to verification-checklist.md as the source of truth',
    ).toBe(true);
  });
});

describe('S8-80 — re-ask rule is single-source-of-truth in continue.md', () => {
  it('PASS: orchestrator-rules.md does NOT contain a duplicate "Re-ask rule (QA manual verification)" block', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');
    expect(
      REASK_HEADER.test(content),
      'orchestrator-rules.md must NOT contain a duplicate "Re-ask rule (QA manual verification)" header — the rule lives only in continue.md (Phase 0 verified). Duplicates drift over time and silently break the contract.',
    ).toBe(false);
  });
});

describe('S8-80 — re-ask rule wiring — failure-path coverage', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: tampered continue.md missing the re-ask block is detected', () => {
    project.write(
      '.claude/commands/continue.md',
      '# /continue\n\nLaunch code-reviewer Call B. Display checklist. Ask user.\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'commands', 'continue.md'),
      'utf8',
    );
    expect(REASK_HEADER.test(content)).toBe(false);
  });

  it('FAIL: orchestrator-rules.md tampered to duplicate the re-ask block is detected', () => {
    project.write(
      '.claude/shared/orchestrator-rules.md',
      '# Orchestrator Rules\n\n## Re-ask rule (QA manual verification)\n\nDuplicate copy.\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'shared', 'orchestrator-rules.md'),
      'utf8',
    );
    // The duplicate is a violation — the test that runs against the real
    // file should report `expect(...).toBe(false)`, so a tampered file
    // containing the header must produce `true` here (showing the lint would
    // catch it).
    expect(REASK_HEADER.test(content)).toBe(true);
  });
});
