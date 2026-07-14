/**
 * Manual-test approval — free-text issues are handled, then the approval is re-asked.
 *
 * At the manual-test approval the user can report a problem in free text (the
 * "Other" option of the AskUserQuestion). The orchestrator must CLASSIFY that
 * report (checking the epic's `unverifiedAssumptions` "check these first" ledger
 * before the per-story checklist), fix it, and RE-PRESENT the approval — never
 * silently advance. And per the shared approval pattern, the content to approve is
 * always shown as plain text BEFORE the question (no "naked" approval).
 *
 * Canonical sources: `.claude/commands/continue.md` § Step B7.1 and
 * `.claude/shared/approval-pattern.md`.
 * (The retired S8-80 "Re-ask rule (QA manual verification)" block and
 * `verification-checklist.md` no longer exist.)
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const CONTINUE = path.join(REPO_ROOT, '.claude', 'commands', 'continue.md');
const APPROVAL = path.join(REPO_ROOT, '.claude', 'shared', 'approval-pattern.md');

/**
 * continue.md § B7.1 captures a free-text failure via AskUserQuestion and classifies
 * it against the unverifiedAssumptions ledger before the per-story checklist.
 */
function handlesFreeTextIssue(continueMd: string): boolean {
  return (
    /AskUserQuestion/.test(continueMd) &&
    /free-?text/i.test(continueMd) &&
    /unverifiedAssumptions/.test(continueMd)
  );
}

describe('manual-test approval — free-text issue handling', () => {
  it('PASS: continue.md captures a free-text failure and classifies it before fixing', () => {
    expect(handlesFreeTextIssue(fs.readFileSync(CONTINUE, 'utf8'))).toBe(true);
  });

  it('PASS: continue.md re-presents the manual-test approval after the fix (never advances silently)', () => {
    const md = fs.readFileSync(CONTINUE, 'utf8');
    expect(md).toMatch(/re-?(display|present|open).*(manual-test|page|approval)/i);
  });
});

describe('manual-test approval — content shown before the question', () => {
  it('PASS: approval-pattern.md requires the summary/content before calling AskUserQuestion', () => {
    const md = fs.readFileSync(APPROVAL, 'utf8');
    // "... as regular conversation text *before* calling `AskUserQuestion`."
    expect(md).toMatch(/before[*\s]+calling\s+`?AskUserQuestion/i);
  });
});

describe('manual-test approval — free-text handling — failure-path coverage', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: a tampered continue.md that never captures/classifies a free-text issue is detected', () => {
    project.write(
      '.claude/commands/continue.md',
      '# /continue\n\nAsk the user Yes/No. If no, stop. Done.\n',
    );
    const tampered = fs.readFileSync(
      path.join(project.root, '.claude', 'commands', 'continue.md'),
      'utf8',
    );
    expect(handlesFreeTextIssue(tampered)).toBe(false);
  });
});
