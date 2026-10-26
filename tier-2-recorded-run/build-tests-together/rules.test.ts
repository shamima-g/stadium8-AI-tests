/**
 * build-tests-together — Tier-2 detector unit tests (T2.3 / T2.4). Each is mutation-coupled: true on the
 * good shape AND false on the broken shape, so the invariants are proven falsifiable even while the GOOD
 * golden slot is still absent (the control-parity T2.2 check is calibrated separately by the divergent
 * slot + the Tier-1 control-refs tests). Pure, template-independent.
 */

import { describe, it, expect } from 'vitest';
import { missingFileOffense, routableFixmeOffense } from './rules';

describe('T2.3 missingFileOffense', () => {
  it('no offense when both files present', () => {
    expect(missingFileOffense('task-board', '1', true, true, true)).toBeNull();
  });
  it('OFFENSE when the e2e spec is missing', () => {
    expect(missingFileOffense('task-board', '1', true, false, true)).toMatch(/missing web\/e2e/);
  });
  it('OFFENSE when a Vitest file is expected (agent reported tests) but missing', () => {
    expect(missingFileOffense('task-board', '2', false, true, true)).toMatch(/missing .*__tests__.*\.test\.tsx/);
  });
  it('no offense when the Vitest file is absent AND not expected (story had no vitest-tagged AC)', () => {
    expect(missingFileOffense('task-board', '3', false, true, false)).toBeNull();
  });
});

describe('T2.4 routableFixmeOffense', () => {
  const REAL = `import { test, expect } from '@playwright/test';\ntest('loads board', async ({ page }) => { await page.goto('/b'); });`;
  const A11Y_PLUS_STUB = `test('does X', async ({ page }) => { await page.goto('/x'); });\ntest('a11y', async () => {});`;
  const NON_ROUTABLE = `// Non-routable: no page to drive\ntest('Epic 1, Story 2 (deferred to consumer stories)', () => {\n  test.fixme();\n});`;
  const ROUTABLE_ABUSE = `test('does X (deferred until API lands)', () => {\n  test.fixme();\n});`; // routable, no marker

  it('no offense for a spec with a real live test()', () => {
    expect(routableFixmeOffense(REAL)).toBe(false);
    expect(routableFixmeOffense(A11Y_PLUS_STUB)).toBe(false);
  });
  it('no offense for a declared non-routable stub (// Non-routable: marker)', () => {
    expect(routableFixmeOffense(NON_ROUTABLE)).toBe(false);
  });
  it('OFFENSE when a routable spec is all test.fixme() with no non-routable marker', () => {
    expect(routableFixmeOffense(ROUTABLE_ABUSE)).toBe(true);
  });
  it('OFFENSE is not satisfied by the word "deferred" in a test title (structured marker required)', () => {
    // guards against the leaky whole-file substring scan the council flagged
    expect(routableFixmeOffense(ROUTABLE_ABUSE)).toBe(true);
  });
});
