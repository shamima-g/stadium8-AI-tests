/**
 * /plan epic-scope (Tier 1, static regression-guards). Feature: /plan handles project-fact-change
 * and design-update epics instead of redirecting to /start. Already implemented, so the regression
 * checks are GREEN-now and pin the wording against a future revert.
 *
 * Every guard is MUTATION-COUPLED: a unit test proves it passes on the real wording AND fails on a
 * mutated copy (the deletion it guards against). These are a wording net only — the ACs are proven
 * behaviourally at Tier 3 (see the plan).
 *
 * Point at a STABLE checkout (PowerShell):
 *   $env:REPO_ROOT="C:\TestsArchives\stadium8-tests\21-09-2026"; $env:EXPECT_TEMPLATE="1"; npm run test:tier1
 *   (18-09-2026 and 21-09-2026 carry a byte-identical .claude at templateRef v1.3.0.)
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { TEMPLATE_DIR, TEMPLATE_PRESENT, TEMPLATE_REF, NO_TEMPLATE_REASON } from '../../helpers';
import {
  hasStep3a,
  hasStep3b,
  tellsWhatMoved,
  stagesPlanByName,
  designStaysOffMain,
  designReachesMainOnlyAtMerge,
  hasDriftCheck,
  hasWorktreeIsolation,
  hasNoStartGuards,
  findProjectFactRedirect,
} from './rules';

// ---------------------------------------------------------------------------
// 1. Detector unit tests — each true on good wording AND false on the mutation
// ---------------------------------------------------------------------------

describe('section-presence guards (mutation = delete the step)', () => {
  it('hasStep3a', () => {
    expect(hasStep3a('## Step 3a: Apply a project-level change')).toBe(true);
    expect(hasStep3a('## Step 3: something else')).toBe(false);
  });
  it('hasStep3b', () => {
    expect(hasStep3b('## Step 3b: Read the changed design')).toBe(true);
    expect(hasStep3b('## Step 4: Lay down the plan')).toBe(false);
  });
  it('tellsWhatMoved — only when the link is in the Step 3c section', () => {
    const good = '## Step 3c: skeleton\n[tell what moved](../shared/design-update.md#tell-the-user-what-moved)\n## Step 4: stories';
    expect(tellsWhatMoved(good)).toBe(true);
    // mutation: the invocation drifted out of Step 3c into Step 4 → must go red.
    const drifted = '## Step 3c: skeleton\nnothing here\n## Step 4: stories\n[link](../shared/design-update.md#tell-the-user-what-moved)';
    expect(tellsWhatMoved(drifted)).toBe(false);
  });
});

describe('AC5 design-off-main guards (mutation = drop the by-name rule / the merge rule)', () => {
  it('stagesPlanByName — rule AND the by-name command; blanket add fails', () => {
    const good =
      'Stage the plan by name — never `git add generated-docs/`:\n' +
      '  git -C <worktree> add generated-docs/epic-plan.md generated-docs/epics/<slug>/';
    expect(stagesPlanByName(good)).toBe(true);
    // mutation: prose kept, but the command reverts to a blanket add → must go red.
    const blanket =
      'Stage the plan by name — never `git add generated-docs/`:\n' +
      '  git -C <worktree> add generated-docs/';
    expect(stagesPlanByName(blanket)).toBe(false);
  });
  it('designStaysOffMain', () => {
    expect(designStaysOffMain('**Nothing of the design lands on `main` here.**')).toBe(true);
    expect(designStaysOffMain('The digest is committed to main now.')).toBe(false);
  });
  it('designReachesMainOnlyAtMerge', () => {
    expect(designReachesMainOnlyAtMerge('its digest ride the epic branch and reach `main` only at merge')).toBe(true);
    expect(designReachesMainOnlyAtMerge('the digest lands on main during planning')).toBe(false);
  });
});

describe('AC6 drift-check guard (mutation = remove the fingerprint compare)', () => {
  it('hasDriftCheck — the ask is bound to the drift context', () => {
    const good =
      'node .claude/scripts/design-fingerprint.js --compare <fp>\n' +
      '- `match: false` otherwise → say what moved, then `AskUserQuestion` —\n' +
      '  **"Adjust the affected stories first"** — re-plan; **"Build the stories as approved"** — continue';
    expect(hasDriftCheck(good)).toBe(true);
    // mutation: compare + match:false stay, but the drift prompt is removed (silently continues) → red.
    const noAsk =
      'node .claude/scripts/design-fingerprint.js --compare <fp>\n' +
      '- `match: false` otherwise → rebuild against the current design and continue.';
    expect(hasDriftCheck(noAsk)).toBe(false);
    expect(hasDriftCheck('the build just rebuilds from the current design')).toBe(false);
  });
});

describe('AC8 worktree-isolation guard (mutation = remove the isolation wording)', () => {
  it('hasWorktreeIsolation', () => {
    const good =
      'All the git work happens in a throwaway worktree cut from the latest `main` … ' +
      'No `epic/<slug>` branch is created here … running `/plan` never disturbs a build in another window.';
    expect(hasWorktreeIsolation(good)).toBe(true);
    expect(hasWorktreeIsolation('/plan works on the current branch directly.')).toBe(false);
  });
});

describe('AC7 residual-redirect hunt', () => {
  it('hasNoStartGuards requires both explicit guards', () => {
    const good = 'never send the user to `/start`. … the stories; don\'t send them to `/start`.';
    expect(hasNoStartGuards(good)).toBe(true);
    expect(hasNoStartGuards('never send the user to `/start`.')).toBe(false); // only one guard
  });

  it('FLAGS a real dead-end (project-fact change routed to /start)', () => {
    expect(findProjectFactRedirect('If a role changes, run `/start` to change that first.').length).toBe(1);
  });

  it('FLAGS a dead-end that wraps across lines', () => {
    expect(findProjectFactRedirect('If a role changes,\nyou will need `/start` to sort that out.').length).toBe(1);
  });

  it('FLAGS a verb-less redirect ("that is a /start job")', () => {
    expect(findProjectFactRedirect('Changing your auth is a `/start` job, not something planning does.').length).toBe(1);
  });

  it('does NOT flag legitimate /start routes or the guard lines', () => {
    const legit = [
      'No `project.md` → run `/start` to set it up and build the first feature.', // no-project setup
      'Build it with `/start` and pick it from the list.', // parked-epic build
      'Either way `/plan` carries it — **never send the user to `/start`**.', // guard (negation)
      "the stories; don't send them to `/start`.", // guard (negation)
    ].join('\n');
    expect(findProjectFactRedirect(legit)).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// Fail-closed: template present when explicitly expected
// ---------------------------------------------------------------------------

it('the template under test is present (and the right one) when EXPECT_TEMPLATE is set', () => {
  if (!process.env.EXPECT_TEMPLATE) return;
  expect(TEMPLATE_PRESENT).toBe(true);
  // Identity check: if EXPECT_TEMPLATE_REF is set, a stale/wrong checkout goes red, not green.
  if (process.env.EXPECT_TEMPLATE_REF) expect(TEMPLATE_REF).toBe(process.env.EXPECT_TEMPLATE_REF);
});

// ---------------------------------------------------------------------------
// 2. Regression over the real template (green-now; pins the behaviour)
// ---------------------------------------------------------------------------

const read = (p: string) => fs.readFileSync(p, 'utf8');
const PLAN = path.join(TEMPLATE_DIR, 'commands', 'plan.md');
const CONTINUE = path.join(TEMPLATE_DIR, 'commands', 'continue.md');
const DESIGN_UPDATE = path.join(TEMPLATE_DIR, 'shared', 'design-update.md');

describe.skipIf(!TEMPLATE_PRESENT)('regression — /plan epic-scope wording is present', () => {
  it('plan.md has Step 3a (project-fact) and Step 3b (design-update)', () => {
    const md = read(PLAN);
    expect(hasStep3a(md), 'Step 3a').toBe(true);
    expect(hasStep3b(md), 'Step 3b').toBe(true);
  });

  it('plan.md tells the user what moved (AC4)', () => {
    expect(tellsWhatMoved(read(PLAN))).toBe(true);
  });

  it('plan.md keeps the design off main at plan time (AC5)', () => {
    const md = read(PLAN);
    expect(stagesPlanByName(md), 'by-name staging').toBe(true);
    expect(designStaysOffMain(md), 'nothing lands on main here').toBe(true);
  });

  it('design-update.md: design reaches main only at merge (AC5)', () => {
    expect(designReachesMainOnlyAtMerge(read(DESIGN_UPDATE))).toBe(true);
  });

  it('continue.md re-checks the parked design and warns on drift (AC6)', () => {
    expect(hasDriftCheck(read(CONTINUE))).toBe(true);
  });

  it('plan.md isolates its work in a worktree (AC8)', () => {
    expect(hasWorktreeIsolation(read(PLAN))).toBe(true);
  });

  it('plan.md carries the no-/start guards and no residual dead-end redirect (AC7)', () => {
    // Fuzzy residual-redirect scan is reliable only on plan.md, whose /plan wording is
    // controlled. start.md is prose-heavy and describes legitimate INTAKE
    // design-reading + build routes that a static scan can't cleanly tell from a dead-end —
    // so residual-redirect detection there is a Tier-3 (semantic) concern, not this scan.
    const md = read(PLAN);
    expect(hasNoStartGuards(md), 'explicit no-/start guards').toBe(true);
    const hits = findProjectFactRedirect(md);
    expect(hits, hits.map((h) => `L${h.line}: ${h.text}`).join('\n')).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// Tier 2 — recorded-run invariants (PENDING). Registered as todos so they are tracked.
// Blocked on: a live-captured parked-epic golden run (a parked design-update run isn't
// synthesizable — it must come from a Tier-3 run first). See plan-epic-scope-test-plan.md § Tier 2.
// ---------------------------------------------------------------------------

// Tier 2 — recorded-run invariants #200 (AC2) and #201 (AC5) are now WIRED in
// tier-2-recorded-run/plan-scope/plan-design-update.test.ts: they run the B10 analysis core
// (helpers/plan-scope.ts — auditParkedDesignUpdate / designStagedOnMain) over the `plan-design-update`
// golden slot and SKIP VISIBLY until that live `/plan` capture exists (the intake Piece-2 pattern).

// ---------------------------------------------------------------------------
// Tier 3 — behavioural (PENDING, the real verification). Registered as todos.
// Blocked on: the plan-facts-changed scorer fix, a mid-run design-file-swap scenario driver,
// an abandon step + inheritance/park-build assertions, and Tier-3 target resolution against the
// archive checkout. See plan-epic-scope-test-plan.md § Tier 3 + § Feasibility.
// ---------------------------------------------------------------------------

describe('Tier 3 — behavioural (pending harness infra + scorer fix)', () => {
  it.todo('AC1/AC3 positive completion: a project-fact epic AND a design-update epic each reach READY-TO-BUILD, write the epic-plan row on main, leave no leftover worktree/branch, and /status shows the parked epic');
  it.todo('AC2 confirm + inherit: fact confirmed → lands on main → two later epics both see it; a stale already-parked epic re-checks the changed fact at build');
  it.todo('AC4 told-what-moved: the plain-language diff appears at approval (not build); plus the negative and the no-digest first-time message');
  it.todo('AC5 clean abandon: pure design-update leaves nothing on main; mixed epic keeps the fact but drops the design; palette/globals.css cleared too');
  it.todo('AC6 park → build against approved design: on drift the build warns and requires a choice (no silent drift or rollback)');
  it.todo('AC8 concurrency: /plan does not disturb a running build; same-fact-different-values surfaces a Tier-4 halt with both values; different sections additive-union auto-merge (benign twin)');
  it.todo('Draft vs new: both Step 3c forks (new epic fresh brief; draft revised brief) end parked with the fields set');
  it.todo('Decline path: a declined project change leaves main untouched; the design-update work still proceeds');
});

if (!TEMPLATE_PRESENT) {
  // eslint-disable-next-line no-console
  console.warn('[plan-scope] ' + NO_TEMPLATE_REASON);
}
