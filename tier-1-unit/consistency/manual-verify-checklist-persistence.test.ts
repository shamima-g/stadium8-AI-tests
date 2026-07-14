/**
 * Manual-test approval — results are persisted so ticks survive a fix cycle.
 *
 * Under the epic-branch workflow the manual-test approval (continue.md § Step B7.1)
 * presents an HTML check-off page (`generated-docs/epics/<slug>/manual-tests.html`)
 * and, when the user hands results back, PERSISTS them to
 * `state.json.epic.manualTestResults` — so a later re-display after a fix can
 * pre-tick the tests that already passed instead of asking the user to re-verify
 * the whole list.
 *
 * Canonical sources: `.claude/commands/continue.md` § B7.1 and
 * `.claude/shared/approval-pattern.md` § "Manual-Test Check-off Page".
 * (The retired S8-80 `verification-checklist.md` / `generated-docs/qa/` mechanism
 * no longer exists.)
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const CONTINUE = path.join(REPO_ROOT, '.claude', 'commands', 'continue.md');
const APPROVAL = path.join(REPO_ROOT, '.claude', 'shared', 'approval-pattern.md');

/** continue.md persists the handed-back results to state.json.epic.manualTestResults. */
function persistsResults(continueMd: string): boolean {
  return /manualTestResults/.test(continueMd) && /manual-tests\.html/.test(continueMd);
}

describe('manual-test approval — check-off page is generated', () => {
  it('PASS: continue.md § B7.1 generates the manual-tests.html check-off page', () => {
    const md = fs.readFileSync(CONTINUE, 'utf8');
    expect(md).toMatch(/manual-tests\.html/);
    expect(md).toMatch(/manual-test approval/i);
  });

  it('PASS: approval-pattern.md documents the Manual-Test Check-off Page and its results payload', () => {
    const md = fs.readFileSync(APPROVAL, 'utf8');
    expect(md).toMatch(/Manual-Test Check-off Page/i);
    expect(md).toMatch(/generated-docs\/epics\/<slug>\/manual-tests\.html/);
    expect(md).toMatch(/manualTestResults/);
  });
});

describe('manual-test approval — results are persisted', () => {
  it('PASS: continue.md persists the handed-back results to state.json.epic.manualTestResults', () => {
    expect(persistsResults(fs.readFileSync(CONTINUE, 'utf8'))).toBe(true);
  });

  describe('failure-path coverage', () => {
    let project: TempProject;
    beforeEach(() => { project = createTempProject(); });
    afterEach(() => { project.cleanup(); });

    it('FAIL: a tampered continue.md that never persists results is detected', () => {
      project.write(
        '.claude/commands/continue.md',
        '# /continue\n\nStep B7.1: show the checklist and ask the user. Done.\n',
      );
      const tampered = fs.readFileSync(
        path.join(project.root, '.claude', 'commands', 'continue.md'),
        'utf8',
      );
      expect(persistsResults(tampered)).toBe(false);
    });
  });
});
