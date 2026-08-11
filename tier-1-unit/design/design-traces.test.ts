/**
 * Deterministic halves of the Tier-3 build-from-design scenarios (#14/#15).
 *
 * These prove the pure assertion functions good AND broken over synthetic scaffolds, with the
 * REAL `.claude/templates/design-digest.md` as the canonical "unfilled" broken case — so the
 * checks are grounded in the template, not hand-built literals. The eventual live run
 * (tier-3-automated, a real AI build against the design benchmark) exercises these SAME functions
 * over a captured run; only the irreducible live cores (the read-back actually shown at Intake,
 * a design conflict actually asking which wins) stay record-only there. This is the three-tier
 * split the `/plan` scenarios use — see workflow-tests.md §8.
 *
 * Feature-detected on the design-interpreter agent; skips on templates that predate the feature.
 */

import { it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { REPO_ROOT } from '../../helpers';
import {
  digestReadyForIntake,
  decisionsPreserved,
  decisionsIn,
  changesScopedTo,
} from '../../helpers/design-digest';

const DESIGN_INTERPRETER = path.join(REPO_ROOT, '.claude', 'agents', 'design-interpreter.md');
const PRESENT = fs.existsSync(DESIGN_INTERPRETER);
const DIGEST_TEMPLATE = path.join(REPO_ROOT, '.claude', 'templates', 'design-digest.md');

// A filled digest — a real read-back: a named screen, a concrete palette value, all required
// sections, and a recorded decision. Modelled on the template's shape.
const FILLED_DIGEST = `# Design Digest — Team Task Manager

| Field | Value |
|---|---|
| Last updated | 2026-05-01T00:00:00Z |

## Your Decisions

- Sign-in uses email + password, no SSO for launch (you told us, 2026-05-01)

## Screens

### Task list
- **Purpose:** the main list of tasks
- **Fields:** Label "Title", placeholder "What needs doing?"
- **Copy:** heading "Your tasks", empty state "Nothing here yet"

### Task detail
- **Purpose:** view and edit a single task

## Palette & Typography

| Role | Value | Source |
|---|---|---|
| Primary | \`#2563eb\` | inline :root block |

## Data Shapes

Task: id, title, status, dueDate

## Assets

None supplied.

## Translate, Don't Copy

Rebuilt in this stack, not pixel-copied.

## Uncertainties

- The exact due-date format wasn't specified in the design.
`;

describe('build-from-design — deterministic digest traces (#14/#15)', () => {
  // ---- #14: the digest is a filled read-back, not the unfilled template ----

  it.skipIf(!PRESENT)('PASS: a filled digest is ready for Intake (real screens + palette + all sections)', () => {
    const r = digestReadyForIntake(FILLED_DIGEST);
    expect(r.ok, JSON.stringify(r)).toBe(true);
    expect(r.realScreens).toBeGreaterThanOrEqual(2);
    expect(r.hasRealPalette).toBe(true);
    expect(r.missingSections).toEqual([]);
  });

  it.skipIf(!PRESENT || !fs.existsSync(DIGEST_TEMPLATE))(
    'BROKEN: the unfilled digest template is NOT ready (placeholders only)',
    () => {
      const template = fs.readFileSync(DIGEST_TEMPLATE, 'utf8');
      const r = digestReadyForIntake(template);
      // Grounded in the real template: all `[Screen name]` / `#XXXXXX` placeholders, so not ready.
      expect(r.ok, JSON.stringify(r)).toBe(false);
      expect(r.realScreens).toBe(0);
      expect(r.hasRealPalette).toBe(false);
    },
  );

  it.skipIf(!PRESENT)('BROKEN: a digest missing the Uncertainties section is not ready', () => {
    const noUncertainties = FILLED_DIGEST.replace(/## Uncertainties[\s\S]*$/, '');
    const r = digestReadyForIntake(noUncertainties);
    expect(r.ok).toBe(false);
    expect(r.missingSections).toContain('Uncertainties');
  });

  // ---- #15a: decisions survive a re-read (reconciled in place, never dropped) ----

  it.skipIf(!PRESENT)('PASS: a re-read that keeps prior decisions (and adds one) preserves them', () => {
    const before = FILLED_DIGEST;
    const after = FILLED_DIGEST.replace(
      '## Your Decisions\n',
      '## Your Decisions\n\n- Export button renamed to "Download CSV" (you told us, 2026-05-08)\n',
    );
    expect(decisionsIn(before).length).toBeGreaterThan(0);
    const r = decisionsPreserved(before, after);
    expect(r.ok, JSON.stringify(r)).toBe(true);
    expect(r.dropped).toEqual([]);
  });

  it.skipIf(!PRESENT)('BROKEN: a re-read that drops a prior decision is caught', () => {
    const before = FILLED_DIGEST;
    // Re-read rewrote the section from the design and lost the sign-in decision.
    const after = FILLED_DIGEST.replace(
      /## Your Decisions[\s\S]*?\n## Screens/,
      '## Your Decisions\n\n- Nothing yet.\n\n## Screens',
    );
    const r = decisionsPreserved(before, after);
    expect(r.ok).toBe(false);
    expect(r.dropped.join(' ')).toMatch(/email \+ password/);
  });

  // ---- #15b: a design update rebuilds only the named screens ----

  it.skipIf(!PRESENT)('PASS: a rebuild scoped to the named screens touches nothing else', () => {
    const allowed = [/web\/src\/app\/tasks\//, /web\/src\/components\/task-/];
    const changed = ['web/src/app/tasks/page.tsx', 'web/src/components/task-list.tsx'];
    const r = changesScopedTo(changed, allowed);
    expect(r.ok, JSON.stringify(r)).toBe(true);
    expect(r.stray).toEqual([]);
  });

  it.skipIf(!PRESENT)('BROKEN: a rebuild that changes an un-named screen is caught', () => {
    const allowed = [/web\/src\/app\/tasks\//, /web\/src\/components\/task-/];
    const changed = ['web/src/app/tasks/page.tsx', 'web/src/app/settings/page.tsx'];
    const r = changesScopedTo(changed, allowed);
    expect(r.ok).toBe(false);
    expect(r.stray).toEqual(['web/src/app/settings/page.tsx']);
  });
});
