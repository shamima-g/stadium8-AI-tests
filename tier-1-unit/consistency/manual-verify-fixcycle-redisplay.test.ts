/**
 * Manual-test approval — fix-cycle re-display carries ticks forward.
 *
 * When the user reports a problem at the manual-test approval, the orchestrator
 * fixes it, walks back through the epic-end checks, and RE-DISPLAYS the approval —
 * regenerating `manual-tests.html` from `state.json.epic.manualTestResults` so that
 * previously-passed tests stay ticked and ONLY the tests the fix affected come back
 * unchecked for re-verification. The loop is capped at 3 manual-test fix cycles.
 *
 * Canonical source: `.claude/commands/continue.md` § Step B7.1 (and the
 * check-off page's pre-tick rule in `.claude/shared/approval-pattern.md`).
 * (The retired S8-80 `verification-checklist.md` / orchestrator-rules mechanism
 * no longer exists.)
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const CONTINUE = path.join(REPO_ROOT, '.claude', 'commands', 'continue.md');
const APPROVAL = path.join(REPO_ROOT, '.claude', 'shared', 'approval-pattern.md');

/**
 * continue.md re-displays after a fix by regenerating the check-off page from the
 * persisted results, carrying prior ticks forward (not re-asking the whole list).
 */
function carriesTicksForward(continueMd: string): boolean {
  return (
    /manualTestResults/.test(continueMd) &&
    /carry (those )?ticks forward/i.test(continueMd) &&
    /re-?display/i.test(continueMd)
  );
}

describe('manual-test approval — fix-cycle re-display', () => {
  it('PASS: continue.md re-displays the approval carrying previously-passed ticks forward', () => {
    expect(carriesTicksForward(fs.readFileSync(CONTINUE, 'utf8'))).toBe(true);
  });

  it('PASS: only the affected tests come back unchecked after a fix', () => {
    const md = fs.readFileSync(CONTINUE, 'utf8');
    expect(md).toMatch(/uncheck only the tests the fix affected/i);
  });

  it('PASS: the manual-test fix loop is capped at 3 cycles', () => {
    const md = fs.readFileSync(CONTINUE, 'utf8');
    expect(md).toMatch(/3 manual-test fix cycles/i);
  });

  it('PASS: the check-off page pre-ticks from prior results (approval-pattern.md)', () => {
    const md = fs.readFileSync(APPROVAL, 'utf8');
    expect(md).toMatch(/manualTestResults/);
    expect(md).toMatch(/pre-?tick/i);
  });
});

describe('manual-test approval — fix-cycle re-display — failure-path coverage', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: a tampered continue.md that re-asks the whole list from scratch is detected', () => {
    project.write(
      '.claude/commands/continue.md',
      '# /continue\n\nAfter a fix, show the whole checklist again and ask the user.\n',
    );
    const tampered = fs.readFileSync(
      path.join(project.root, '.claude', 'commands', 'continue.md'),
      'utf8',
    );
    expect(carriesTicksForward(tampered)).toBe(false);
  });
});
