/**
 * Replay of the real design-taskboard live run (build-from-design #14/#15).
 *
 * Runs the deterministic assertion functions (helpers/design-digest.ts) over the COMMITTED
 * capture in fixtures/design-capture/ — the artifacts of an actual AI build — so the design
 * traces are gating and replayable with no live AI. Complements design-traces.test.ts (which
 * proves the functions good/broken over synthetic scaffolds); this proves they hold over the
 * real run. The two live cores (readback-confirmed, conflict-asks) are eyeballed and recorded in
 * the fixture README — see it for the full verdict table.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import {
  digestReadyForIntake,
  digestSections,
  decisionsPreserved,
  changesScopedTo,
} from '../../helpers/design-digest';

const DIR = path.resolve(__dirname, '..', '..', 'fixtures', 'design-capture');
const read = (f: string) => fs.readFileSync(path.join(DIR, f), 'utf8');

const intake = read('digest.intake.md');
const beforeUpdate = read('digest.before-update.md');
const afterUpdate = read('digest.after-update.md');
const changedPaths = read('phase2.changed-paths.txt')
  .split(/\r?\n/)
  .map((l) => l.trim())
  .filter(Boolean);

describe('design-capture replay — real run traces (#14/#15)', () => {
  // ---- #14 ----
  it('design-digest-written: the intake digest is a filled read-back', () => {
    const r = digestReadyForIntake(intake);
    expect(r.ok, JSON.stringify(r)).toBe(true);
    expect(r.realScreens, 'Board + Task detail + Settings').toBeGreaterThanOrEqual(3);
    expect(r.hasRealPalette).toBe(true);
    expect(r.missingSections).toEqual([]);
  });

  it('design-uncertainties-surfaced: the intake digest names the due-date it could not determine', () => {
    const uncertainties = digestSections(intake)['Uncertainties'] ?? '';
    expect(uncertainties.length, 'Uncertainties is non-empty').toBeGreaterThan(0);
    expect(uncertainties.toLowerCase()).toMatch(/due-date|due date/);
  });

  // ---- #15 ----
  it('design-decisions-preserved: the design update kept every prior decision (reconciled in place)', () => {
    const r = decisionsPreserved(beforeUpdate, afterUpdate);
    expect(r.ok, `dropped: ${r.dropped.join(' | ')}`).toBe(true);
    expect(r.dropped).toEqual([]);
  });

  it('design-conflict-asks (recorded): the after-digest records blue kept over the update purple', () => {
    // The resolution is recorded in the digest, not invented: blue stays, purple not applied.
    expect(afterUpdate).toMatch(/#2563eb/);
    expect(afterUpdate.toLowerCase()).toMatch(/purple|#7c3aed/);
    expect(afterUpdate.toLowerCase()).toMatch(/not applied|blue.*wins|reaffirmed|stays blue/);
  });

  it('design-update-scoped: only Board + Task detail screen routes changed — Settings untouched', () => {
    const BOARD = /web\/src\/app\/\(app\)\/page\.tsx$/;
    const TASK_DETAIL = /web\/src\/app\/\(app\)\/tasks\/\[id\]\/page\.tsx$/;
    // Every changed app SCREEN route (…(app)/**/page.tsx) must be Board or Task detail.
    const screenRoutes = changedPaths.filter((p) => /web\/src\/app\/\(app\)\/.*page\.tsx$/.test(p));
    const scope = changesScopedTo(screenRoutes, [BOARD, TASK_DETAIL]);
    expect(scope.ok, `stray screen routes: ${scope.stray.join(', ')}`).toBe(true);

    // The rebuild actually happened (both named screens present)…
    expect(screenRoutes.some((p) => BOARD.test(p)), 'Board changed').toBe(true);
    expect(screenRoutes.some((p) => TASK_DETAIL.test(p)), 'Task detail changed').toBe(true);
    // …and the un-named screen was left alone.
    expect(changedPaths.some((p) => /\(app\)\/settings\//.test(p)), 'Settings must be untouched').toBe(false);
  });
});
