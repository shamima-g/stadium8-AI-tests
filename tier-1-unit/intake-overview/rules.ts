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

/**
 * "Stale" includes a MISSING fact, not only a contradicting one — the clause that makes a generic
 * (all-facts-absent) overview count as stale and get backfilled at the next merge. Ordered-anchored
 * across the definition sentence so narrowing it to "contradicts project.md" only turns it red (a
 * generic overview contradicts nothing — it omits — so without this half the backfill never fires).
 * A *qualified* narrowing ("…missing that the epic changed") keeps the substring and is only catchable
 * behaviourally (Tier 3), not by this static guard.
 */
export const staleIncludesMissingFact = (specMd: string): boolean =>
  /Stale means[^\n]*contradicts\s+`?project\.md`?[^\n]*,\s*or a stated fact is missing/i.test(specMd);

// ── Over the wiring (start.md, continue.md) — anchor on CONTENT, not "Step 9.4" labels ────────

/** INTAKE writes CLAUDE.md's `## Project Overview` per the spec. */
export function intakeWritesOverview(startMd: string): boolean {
  const t = startMd.replace(/\s+/g, ' ');
  return /write\b.{0,10}`?CLAUDE\.md`?.{0,15}`?## Project Overview`?/i.test(t) && /project-overview\.md/i.test(t);
}

/**
 * The actual shell commands in a doc: lines inside ``` fences (comments and blanks dropped). When a
 * doc has NO fence the whole input is treated as commands — so a bare-command test fixture works
 * while a real markdown doc is scoped to its fences. This is what stops a `git …`/`CLAUDE.md`
 * reference in PROSE or a COMMENT from being mistaken for a live command (the whole-file-grep bug
 * this file preaches against — see the header).
 */
function commandLines(md: string): string[] {
  const lines = md.split(/\r?\n/);
  const hasFence = lines.some((l) => /^\s*```/.test(l));
  const out: string[] = [];
  let inFence = false;
  for (const raw of lines) {
    if (/^\s*```/.test(raw)) { inFence = !inFence; continue; }
    if (hasFence && !inFence) continue; // scope to fences when the doc has them
    const t = raw.trim();
    if (t === '' || t.startsWith('#') || t.startsWith('<!--')) continue;
    out.push(t);
  }
  return out;
}

/**
 * Does the commit matched by `commitRe` stage CLAUDE.md? Over COMMAND lines only, so a CLAUDE.md
 * mention in prose/comment can't satisfy it, and anchored at line start so the idempotence no-op
 * (`git checkout -- CLAUDE.md`, which contains CLAUDE.md but isn't a `git add`) is skipped. Requires
 * EVERY matching commit's `git add` block — bounded by the previous commit, not a magic line count —
 * to stage CLAUDE.md (by name, or a whole-tree add). Using `every` (not first-match) means an example
 * commit that keeps CLAUDE.md can't mask a real one that drops it. Empty match → false.
 */
function everyCommitStagesClaudeMd(md: string, commitRe: RegExp): boolean {
  const cmds = commandLines(md);
  const idxs = cmds.map((l, i) => (commitRe.test(l) ? i : -1)).filter((i) => i >= 0);
  if (idxs.length === 0) return false;
  return idxs.every((ci) => {
    for (let i = ci - 1; i >= 0; i--) {
      const l = cmds[i];
      if (/^git commit\b/.test(l)) break; // previous commit — block boundary
      if (!/^git add\b/.test(l)) continue;
      if (/^git add\s+(?:-A|--all|\.)(?:\s|$)/.test(l)) return true;
      if (/\bCLAUDE\.md\b/.test(l)) return true;
    }
    return false;
  });
}

/**
 * INTAKE's commit (`git commit -m "docs(project): …"`) stages CLAUDE.md. Block-scoped, command-lines
 * only, every-match — see `everyCommitStagesClaudeMd`. A whole-tree add or a split `git add CLAUDE.md`
 * line stays green; a dropped CLAUDE.md, or an unrelated `git add -A` under a different commit, is red.
 */
export const intakeCommitStagesClaudeMd = (startMd: string): boolean =>
  everyCommitStagesClaudeMd(startMd, /^git commit -m "docs\(project\):/i);

/** The merge-time (B7.2.6) re-check brings the overview into line with project.md per the spec. */
export function mergeRecheckWired(continueMd: string): boolean {
  const t = continueMd.replace(/\s+/g, ' ');
  return (
    /bring\b.{0,10}`?CLAUDE\.md`?.{0,20}`?## Project Overview`?.{0,20}into line with/i.test(t) &&
    /project-overview\.md/i.test(t)
  );
}

/**
 * B7.2.6 leaves CLAUDE.md alone when nothing was stale — the idempotence no-op that stops the file
 * churning. Pins the WHOLE bash expression (a `git checkout` fragment grep stays green under `||`→`&&`,
 * dropped `--quiet`, a repointed pathspec, or a deleted `git diff --quiet` half that ALWAYS discards
 * corrections). Over COMMAND lines only and anchored `^…$`, so the literal appearing in prose/a
 * comment/a "don't do this" example can't false-green a reverted live command. Mutations that go red:
 * delete the `|| git checkout` half; delete the `git diff --quiet … ||` half; `||`→`&&`; drop
 * `--quiet`; repoint the pathspec.
 */
export const mergeLeavesCleanWhenNoChange = (continueMd: string): boolean =>
  commandLines(continueMd).some((l) => /^git diff --quiet -- CLAUDE\.md\s*\|\|\s*git checkout -- CLAUDE\.md$/.test(l));

/**
 * The `chore(<slug>): mark epic complete` commit stages CLAUDE.md, so a B7.2.6 correction lands on
 * main. Command-lines only + anchored + every-match (see `everyCommitStagesClaudeMd`): the
 * idempotence no-op `git checkout -- CLAUDE.md` (continue.md:741) sits just above the commit and
 * contains CLAUDE.md, but is skipped because it isn't a `^git add` line. Whole-tree and split staging
 * stay green; dropping CLAUDE.md from the `git add` (leaving :741 intact) is red.
 */
export const markCompleteStagesClaudeMd = (continueMd: string): boolean =>
  everyCommitStagesClaudeMd(continueMd, /^git commit -m "chore\([^)]*\): mark epic complete"/i);

// ── Over upgrade.md (the backfill/migration path) ─────────────────────────────────────────────

/** The `## Step 5` … `## Step 6` span of upgrade.md — the mixed-file merge step. */
function upgradeStep5(upgradeMd: string): string {
  const ls = upgradeMd.split(/\r?\n/);
  const s = ls.findIndex((l) => /^##\s*Step 5\b/.test(l));
  if (s < 0) return '';
  const e = ls.findIndex((l, i) => i > s && /^##\s*Step 6\b/.test(l));
  return ls.slice(s, e < 0 ? undefined : e).join('\n');
}

/**
 * `/upgrade` adds NO overview migration: Step 5 states it never touches `## Project Overview` and
 * never asks. SCOPED to the Step 5 span — `never ask` also appears at Step 9 (upgrade.md:265) and
 * `never touch` at the `web/*` rules, so a whole-file grep would false-green when the Step-5 clause is
 * removed. Whitespace-collapsed (the "Do this yourself — never ask" phrase wraps two lines) and
 * em-dash tolerant. Mutations that go red: delete the `## Project Overview` never-touch clause; delete
 * the Step-5 `Do this yourself — never ask` (even if the Step-9 `never ask` survives).
 */
export function upgradeLeavesOverviewAlone(upgradeMd: string): boolean {
  const flat = upgradeStep5(upgradeMd).replace(/\s+/g, ' ');
  return (
    /never touch\s+`?##\s*Project Overview`?/i.test(flat) &&
    /Do this yourself\s*[—–-]\s*never ask/i.test(flat)
  );
}
