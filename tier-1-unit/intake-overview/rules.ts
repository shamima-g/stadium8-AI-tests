/**
 * INTAKE `## Project Overview` — Tier 1 static regression-guards (template @ 28-09-2026).
 *
 * The feature (INTAKE writes a lean `## Project Overview` into the shipped CLAUDE.md, governed by
 * `.claude/shared/project-overview.md`) is ALREADY implemented, so every guard passes today. A
 * guard therefore proves nothing unless it can also go RED on the exact regression it protects —
 * so each detector is exercised BOTH ways in the test file: true on the real spec/wiring, false on
 * the mutation it guards against. These are a wording/wiring net only — the AC (a lean, correct,
 * pointered, budgeted section written silently on main) is proven behaviourally at Tier 3.
 *
 * Every span-scoped detector defines its span as tightly as the budget span: the recurring bug is
 * a whole-file grep that stays green because the token also occurs in an ALLOWED context (e.g.
 * `permissions` at "§Roles & Permissions", `epics` at "generated-docs/epics/"). Pure functions
 * over file content. Not a *.test.ts file, so Vitest never collects it.
 */

// ── Over project-overview.md (the governing spec) ─────────────────────────────────────────────

/** AC3 — the budget is stated with the exact literals (a `\d+` pattern would survive 150→200). */
export const statesBudget = (specMd: string): boolean => /within 12 lines and 150 words/i.test(specMd);

/**
 * AC2 — the pointer rule names EXACTLY THREE targets. Scoped to the "Pointer line, exactly three:"
 * sentence only (the example-shape prose lower down also lists the three, so a whole-file count
 * would be wrong). Counts the backticked `generated-docs/...` entries on that line AND requires the
 * "exactly three" literal — so appending a 4th pointer (count → 4) turns it red.
 */
export function pointerLineExactlyThree(specMd: string): boolean {
  const line = specMd.split(/\r?\n/).find((l) => /Pointer line, exactly three:/i.test(l));
  if (!line) return false;
  const targets = [...line.matchAll(/`(generated-docs\/[^`]*)`/g)].map((m) => m[1]);
  const set = new Set(targets);
  return (
    /exactly three/i.test(line) &&
    targets.length === 3 &&
    set.has('generated-docs/project.md') &&
    set.has('generated-docs/epics/') &&
    set.has('generated-docs/architecture.md')
  );
}

/**
 * AC2 — the Never-present list still carries every AC-named pointer-not-content token. SPAN-SCOPED
 * to the `**Never present:**` line only: a whole-file grep for `permissions`/`epics` stays green
 * even when removed from the list (they recur in allowed contexts). Moving a token out of this line
 * into an allowed bullet turns it red.
 */
export function neverPresentListIntact(specMd: string): boolean {
  const line = specMd.split(/\r?\n/).find((l) => /\*\*Never present:\*\*/i.test(l));
  if (!line) return false;
  // ALL twelve tokens the real list carries — not just the AC-headline seven. Dropping any one
  // (e.g. `endpoints`) must turn this red; a partial list is a real regression.
  const required = [
    'permissions', 'endpoints', 'palette', 'compliance', 'theme', 'backend connectivity',
    'epics', 'stories', 'progress', 'timestamps', 'slugs', 'NFRs',
  ];
  return required.every((tok) => new RegExp(tok.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i').test(line));
}

/**
 * AC1 — the three allowed-fact bullet rows (Roles / Auth / Data source) and the constraint each
 * ends in are present. Pins the spec's REAL tokens ("mocks or live", not the AC/plan phrase "by
 * name only", which the spec never uses). Deleting the Data-source row drops both its label and
 * "mocks or live" → red.
 */
export function allowedFactsIntact(specMd: string): boolean {
  const t = specMd.replace(/\r?\n/g, '\n');
  const rows = /\|\s*Roles\s*\|/i.test(t) && /\|\s*Auth\s*\|/i.test(t) && /\|\s*Data source\s*\|/i.test(t);
  const constraints =
    /closed list; exact string form/i.test(t) && /what it forbids/i.test(t) && /mocks or live/i.test(t);
  return rows && constraints;
}

/** AC (silent) — the spec states no prompt / no message. (Necessary only; real silence is Tier 3.) */
export const statesSilence = (specMd: string): boolean => /Silent\b[^\n]{0,12}no prompt, no message/i.test(specMd);

/** The section is written at exactly two points, never from an epic branch. */
export function statesTwoWritePoints(specMd: string): boolean {
  return /the only two points it is ever written/i.test(specMd) && /Never from an .{0,3}epic\/\*.{0,3} branch/i.test(specMd);
}

/** Correct-don't-rewrite + leave the file byte-for-byte untouched when nothing is stale. */
export function statesCorrectDontRewrite(specMd: string): boolean {
  return /Correct, don'?t rewrite/i.test(specMd) && /byte-for-byte untouched/i.test(specMd);
}

// ── Over the wiring (start.md, continue.md) — anchor on CONTENT, not "Step 9.4" labels ────────

/** INTAKE writes CLAUDE.md's `## Project Overview` per the spec. */
export function intakeWritesOverview(startMd: string): boolean {
  const t = startMd.replace(/\s+/g, ' ');
  return /write\b.{0,10}`?CLAUDE\.md`?.{0,15}`?## Project Overview`?/i.test(t) && /project-overview\.md/i.test(t);
}

/**
 * INTAKE's commit stages CLAUDE.md. SCOPED TO THE INTAKE COMMIT: anchor on the intake commit line
 * (`git commit -m "docs(project): …"`) and look back over the `git add` block immediately preceding
 * it. CLAUDE.md must be staged in THAT block — on the bundle line, on its own split line, or via a
 * whole-tree add. Scoping to the block (not the whole file) closes two holes a whole-file scan has:
 * an unrelated `git add -A` elsewhere can't create a false-green, and a legitimate split-staging
 * refactor (`git add CLAUDE.md` on its own line) doesn't false-red.
 */
export function intakeCommitStagesClaudeMd(startMd: string): boolean {
  const lines = startMd.split(/\r?\n/);
  const commitIdx = lines.findIndex((l) => /git commit -m "docs\(project\):/i.test(l));
  if (commitIdx === -1) return false;
  for (let i = commitIdx - 1; i >= 0 && i >= commitIdx - 10; i--) {
    const l = lines[i];
    if (/git commit\b/.test(l)) break; // stop at the previous commit — stay in this commit's block
    if (!/(^|\s)git add\b/.test(l)) continue;
    if (/git add\s+(?:-A|--all|\.)(?:\s|$)/.test(l)) return true;
    if (/\bCLAUDE\.md\b/.test(l)) return true;
  }
  return false;
}

/** The merge-time (B7.2.6) re-check brings the overview into line with project.md per the spec. */
export function mergeRecheckWired(continueMd: string): boolean {
  const t = continueMd.replace(/\s+/g, ' ');
  return (
    /bring\b.{0,10}`?CLAUDE\.md`?.{0,20}`?## Project Overview`?.{0,20}into line with/i.test(t) &&
    /project-overview\.md/i.test(t)
  );
}
