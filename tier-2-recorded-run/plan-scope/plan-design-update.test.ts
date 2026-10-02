/**
 * Tier-2 recorded-run invariants for a PARKED design-update `/plan` run (#200 AC2, #201 AC5).
 *
 * These assert over a live-captured `/plan` run that parks a design-update epic (and changes one
 * project fact), frozen into the `plan-design-update` golden slot. They run the already-unit-tested
 * B10 analysis core (`helpers/plan-scope.ts`) — no live AI at test time. Until the capture exists they
 * **skip visibly** (never a vacuous green), exactly as the intake Tier-2 suite did before its capture.
 *
 * Scenario locators are recorded in the slot's `meta.json` at capture time (finalised on capture day):
 *   factNeedle       — a NON-styling project fact that lands on `main` at plan time (AC2 / #200)
 *   parkedStatePath  — repo-relative path to the parked design-update epic's `state.json` (AC5 / #201)
 *   planCommit       — the `docs(plan)` commit that parked the epic (for the design-not-on-main check)
 *
 * Todos covered when the capture lands: #200 (fact on main), #201 (parked-epic state fields + design
 * kept off main). See test-plans/parked-tests-implementation-plan.md (B10) + the plan-scope test plan.
 */
import { describe, it, expect, afterAll } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { loadGoldenRun } from '../../helpers/golden-run';
import { parsePlanEpicState, auditParkedDesignUpdate, designStagedOnMain } from '../../helpers/plan-scope';

const golden = loadGoldenRun('plan-design-update');
if (!golden.present) {
  // eslint-disable-next-line no-console
  console.warn('[plan-design-update] skipping — ' + golden.reason);
}
afterAll(() => golden.cleanup()); // remove the temp bundle clone (no-op when the slot is absent)

const meta = golden.meta as { factNeedle?: string; parkedStatePath?: string; planCommit?: string; epicSlug?: string };

// A parked design-update capture is always a git bundle (the design-off-main check needs commit
// topology), so the whole suite is git-gated. The filesystem reads below are the checked-out tree; the
// first test guards that the tree is `main`, so they don't silently depend on which branch the bundle's
// HEAD happened to be captured on.
describe.skipIf(!golden.present || !golden.hasGit)('plan recorded run — parked design-update', () => {
  const git = golden.git as NonNullable<typeof golden.git>;
  const root = golden.root as string;

  it('the capture is checked out on the integration branch (main)', () => {
    expect(git('rev-parse', '--abbrev-ref', 'HEAD').stdout.trim(), 'capture HEAD should be main').toBe('main');
  });

  it('#200 (AC2): the approved project-fact change is present on main', () => {
    expect(meta.factNeedle, 'meta.factNeedle must record the landed fact (set at capture)').toBeTruthy();
    const projectMd = fs.readFileSync(path.join(root, 'generated-docs', 'project.md'), 'utf8');
    // "did the fact land" — match case-insensitively; the tool may render the field name in any case.
    expect(projectMd.toLowerCase(), `project.md on main should contain the approved fact "${meta.factNeedle}"`)
      .toContain((meta.factNeedle as string).toLowerCase());
  });

  it('#201 (AC5): the parked epic state carries parkedDesignUpdate + a fingerprint + decisions[]', () => {
    expect(meta.parkedStatePath, 'meta.parkedStatePath must point at the parked epic state.json (set at capture)').toBeTruthy();
    const p = path.join(root, meta.parkedStatePath as string);
    expect(fs.existsSync(p), `parked epic state.json present at ${meta.parkedStatePath}`).toBe(true);
    const audit = auditParkedDesignUpdate(parsePlanEpicState(fs.readFileSync(p, 'utf8')));
    expect(audit.ok, audit.reasons.join('; ')).toBe(true);
  });

  it('#201 (AC5): nothing of the design landed on main at plan time (plan.md Step 3b)', () => {
    expect(meta.planCommit, 'meta.planCommit must name the docs(plan) commit (set at capture)').toBeTruthy();
    const shown = git('show', '--name-only', '--format=', meta.planCommit as string);
    expect(shown.exitCode, `the docs(plan) commit ${meta.planCommit} is readable`).toBe(0);
    const paths = shown.stdout.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
    const r = designStagedOnMain(paths);
    expect(r.ok, `design files leaked onto main at plan time: ${r.offenders.join(', ')}`).toBe(true);
  });
});
