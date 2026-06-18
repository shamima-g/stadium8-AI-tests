/**
 * S8-80 Phase 5 — Tier 1 wiring lint for manual verification checklist persistence.
 *
 * The QA manual-verification-checklist re-display contract (HOW-IT-WORKS §4.9)
 * relies on Call B writing the checklist to a canonical file so subsequent
 * fix-cycle and free-text re-asks can re-read it. If any of the three workflow
 * files silently drops the "MUST persist" instruction, the file disappears,
 * and downstream re-display behaviour degrades to whatever the orchestrator
 * happens to remember in context — which is exactly the regression S8-80 fixed.
 *
 * Specifically checks:
 *   - .claude/agents/code-reviewer.md contains a "Persist the checklist to file"
 *     section anchor with `verification-checklist.md` referenced in the
 *     file-write paragraph
 *   - .claude/commands/continue.md Call B launch prompt contains the literal
 *     "You MUST persist the checklist to generated-docs/qa/" instruction
 *   - .claude/shared/orchestrator-rules.md Call B launch prompt contains the
 *     same literal "You MUST persist the checklist to generated-docs/qa/"
 *     instruction (catches drift between the two orchestrator files)
 *
 * Pattern source: consistency/cross-doc-references.test.ts, gate-6-wired.test.ts
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const CODE_REVIEWER = path.join(REPO_ROOT, '.claude', 'agents', 'code-reviewer.md');
const CONTINUE_CMD = path.join(REPO_ROOT, '.claude', 'commands', 'continue.md');
const ORCH_RULES = path.join(REPO_ROOT, '.claude', 'shared', 'orchestrator-rules.md');

const PERSIST_INSTRUCTION = /You MUST persist the checklist to generated-docs\/qa\//;

describe('S8-80 — code-reviewer.md persists the checklist to file', () => {
  it('PASS: code-reviewer.md has a "Persist the checklist to file" anchor that names verification-checklist.md', () => {
    const content = fs.readFileSync(CODE_REVIEWER, 'utf8');

    expect(
      /Persist the checklist to file/.test(content),
      'code-reviewer.md must contain the literal "Persist the checklist to file" section anchor',
    ).toBe(true);

    // The file-write paragraph must reference verification-checklist.md within
    // proximity of the persist anchor (not just somewhere in the file).
    const lines = content.split(/\r?\n/);
    const anchorIdx = lines.findIndex(l => /Persist the checklist to file/.test(l));
    const checklistRefIdx = lines.findIndex(
      (l, i) => i >= anchorIdx && /verification-checklist\.md/.test(l),
    );
    expect(
      checklistRefIdx >= 0 && checklistRefIdx - anchorIdx <= 10,
      'code-reviewer.md must reference verification-checklist.md within 10 lines of the persist anchor',
    ).toBe(true);
  });
});

describe('S8-80 — continue.md Call B prompt requires checklist persistence', () => {
  it('PASS: continue.md contains the literal "You MUST persist the checklist to generated-docs/qa/" instruction', () => {
    const content = fs.readFileSync(CONTINUE_CMD, 'utf8');
    expect(
      PERSIST_INSTRUCTION.test(content),
      'continue.md Call B prompt must include the literal "You MUST persist the checklist to generated-docs/qa/" instruction',
    ).toBe(true);
  });
});

describe('S8-80 — orchestrator-rules.md Call B prompt requires checklist persistence', () => {
  it('PASS: orchestrator-rules.md contains the same persist instruction as continue.md', () => {
    const content = fs.readFileSync(ORCH_RULES, 'utf8');
    expect(
      PERSIST_INSTRUCTION.test(content),
      'orchestrator-rules.md Call B prompt must include the literal "You MUST persist the checklist to generated-docs/qa/" instruction (drift between the two orchestrator files breaks the contract)',
    ).toBe(true);
  });
});

describe('S8-80 — checklist persistence wiring — failure-path coverage', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: tampered code-reviewer.md without the persist anchor is detected', () => {
    project.write(
      '.claude/agents/code-reviewer.md',
      '# code-reviewer\n\nCall B runs gates. Returns checklist text.\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'agents', 'code-reviewer.md'),
      'utf8',
    );
    expect(/Persist the checklist to file/.test(content)).toBe(false);
  });

  it('FAIL: tampered continue.md missing the persist instruction is detected', () => {
    project.write(
      '.claude/commands/continue.md',
      '# /continue\n\nLaunch code-reviewer Call B. Return gate results.\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'commands', 'continue.md'),
      'utf8',
    );
    expect(PERSIST_INSTRUCTION.test(content)).toBe(false);
  });

  it('FAIL: tampered orchestrator-rules.md missing the persist instruction is detected', () => {
    project.write(
      '.claude/shared/orchestrator-rules.md',
      '# Orchestrator Rules\n\nLaunch code-reviewer. Return gate results.\n',
    );
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'shared', 'orchestrator-rules.md'),
      'utf8',
    );
    expect(PERSIST_INSTRUCTION.test(content)).toBe(false);
  });
});
