/**
 * S8-80 Phase 5 — Tier 1 wiring lint for fix-cycle checklist re-display.
 *
 * After every "Issues found" fix cycle, the orchestrator must re-read the
 * persisted checklist file and re-display its content verbatim to the user.
 * The instruction that enforces this lives in `.claude/shared/orchestrator-rules.md`
 * — both inside the fix-cycle coordinator prompt block (around lines 647–651
 * in the post-S8-80 file) and as a standalone "CRITICAL: Always re-present"
 * sentence further down. If either of those silently disappears, the contract
 * weakens to "the orchestrator may paraphrase or abbreviate after a fix",
 * which is exactly the regression S8-80 fixed.
 *
 * Specifically checks orchestrator-rules.md for all of:
 *   - the literal phrase `verification-checklist.md`
 *   - the word `verbatim` (case-insensitive)
 *   - the literal phrase `COMPLETE verification checklist`
 *   - the standalone sentence starting `CRITICAL: Always re-present`
 *
 * Pattern source: consistency/cross-doc-references.test.ts, gate-6-wired.test.ts
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const ORCH_RULES = path.join(REPO_ROOT, '.claude', 'shared', 'orchestrator-rules.md');

describe('S8-80 — orchestrator-rules.md fix-cycle re-display instructions', () => {
  it('PASS: orchestrator-rules.md fix-cycle block references verification-checklist.md', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');
    expect(
      /verification-checklist\.md/.test(content),
      'orchestrator-rules.md must reference verification-checklist.md so the fix-cycle coordinator knows which file to re-read',
    ).toBe(true);
  });

  it('PASS: orchestrator-rules.md mentions "verbatim" in the fix-cycle context', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');
    expect(
      /verbatim/i.test(content),
      'orchestrator-rules.md must use the word "verbatim" to enforce non-paraphrased re-display',
    ).toBe(true);
  });

  it('PASS: orchestrator-rules.md fix-cycle block contains "COMPLETE verification checklist"', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');
    expect(
      /COMPLETE verification checklist/.test(content),
      'orchestrator-rules.md must require the COMPLETE verification checklist (uppercase COMPLETE) to be copied into the NEEDS_APPROVAL payload',
    ).toBe(true);
  });

  it('PASS: orchestrator-rules.md contains the "CRITICAL: Always re-present" sentence', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');
    expect(
      /CRITICAL: Always re-present/.test(content),
      'orchestrator-rules.md must contain the standalone "CRITICAL: Always re-present the full manual verification checklist" instruction — drops here weaken the contract on multi-cycle re-asks',
    ).toBe(true);
  });

  it('PASS: the four anchors live within proximity (single fix-cycle block, not scattered)', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');
    const lines = content.split(/\r?\n/);

    const findAllIdx = (re: RegExp) =>
      lines.map((l, i) => (re.test(l) ? i : -1)).filter(i => i >= 0);

    // verification-checklist.md is referenced multiple times (Call B prompt
    // AND fix-cycle block). COMPLETE verification checklist is unique to the
    // fix-cycle block. The invariant: at least one verification-checklist.md
    // line must appear within 10 lines of the COMPLETE phrase — that proves
    // the fix-cycle block has both anchors.
    const fileIdxs = findAllIdx(/verification-checklist\.md/);
    const completeIdxs = findAllIdx(/COMPLETE verification checklist/);
    const criticalIdxs = findAllIdx(/CRITICAL: Always re-present/);

    expect(fileIdxs.length).toBeGreaterThanOrEqual(1);
    expect(completeIdxs.length).toBeGreaterThanOrEqual(1);
    expect(criticalIdxs.length).toBeGreaterThanOrEqual(1);

    const fileNearComplete = fileIdxs.some(f =>
      completeIdxs.some(c => Math.abs(f - c) <= 10),
    );
    expect(
      fileNearComplete,
      'at least one verification-checklist.md reference must appear within 10 lines of "COMPLETE verification checklist" — that pair lives in the fix-cycle prompt block',
    ).toBe(true);

    const completeNearCritical = completeIdxs.some(c =>
      criticalIdxs.some(k => Math.abs(c - k) <= 30),
    );
    expect(
      completeNearCritical,
      'the CRITICAL: Always re-present sentence must live within 30 lines of the COMPLETE verification checklist phrase — drift here suggests one or the other moved without the matching update',
    ).toBe(true);
  });
});

describe('S8-80 — fix-cycle re-display wiring — failure-path coverage', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: tampered orchestrator-rules.md missing "COMPLETE verification checklist" is detected', () => {
    project.write(
      '.claude/shared/orchestrator-rules.md',
      '# Orchestrator Rules\n\nFix cycle: re-read the checklist and present it.\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'shared', 'orchestrator-rules.md'),
      'utf8',
    );
    expect(/COMPLETE verification checklist/.test(content)).toBe(false);
  });

  it('FAIL: tampered orchestrator-rules.md without the "CRITICAL: Always re-present" sentence is detected', () => {
    project.write(
      '.claude/shared/orchestrator-rules.md',
      '# Orchestrator Rules\n\nverification-checklist.md verbatim COMPLETE verification checklist.\nNo always-re-present sentence here.\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'shared', 'orchestrator-rules.md'),
      'utf8',
    );
    expect(/CRITICAL: Always re-present/.test(content)).toBe(false);
  });
});
