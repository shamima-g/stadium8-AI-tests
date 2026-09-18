/**
 * /plan epic-scope — Tier 1 wording regression-guards (updated template @ 18-09-2026).
 *
 * The feature (/plan handles project-fact-change and design-update epics) is ALREADY
 * implemented, so every guard passes today. A guard therefore proves nothing unless it can
 * also go RED on the exact regression it protects — so each detector is exercised BOTH ways:
 * true on the real (good) text, and false on a mutated copy (the bad fixture = the deletion
 * that must turn it red). These guards are a regression net on wording, NOT AC verification —
 * the ACs (git topology, inheritance, merge/abandon, concurrency) are proven at Tier 3.
 *
 * Pure functions over file content. Not a *.test.ts file, so Vitest never collects it.
 */

// ---------------------------------------------------------------------------
// Section-presence guards (plan.md)
// ---------------------------------------------------------------------------

/** AC1 — the project-level-change path exists. */
export const hasStep3a = (planMd: string): boolean => /^#{1,4}\s*Step 3a:/im.test(planMd);

/** AC3 — the design-update path exists. */
export const hasStep3b = (planMd: string): boolean => /^#{1,4}\s*Step 3b:/im.test(planMd);

/** AC4 — the plan tells the user what moved AT THE STEP 3C (brief) approval, not at build. */
export function tellsWhatMoved(planMd: string): boolean {
  const m = planMd.match(/##\s*Step 3c\b[\s\S]*?(?=\n##\s|$)/i);
  return !!m && /design-update\.md#tell-the-user-what-moved/i.test(m[0]);
}

// ---------------------------------------------------------------------------
// AC5 — design stays off `main` until merge (the /plan by-name staging rule)
// ---------------------------------------------------------------------------

/**
 * The park commit stages by name — the RULE (prose) and the COMMAND both — and there is no
 * un-negated blanket `git add generated-docs/` line that would sweep the design onto main.
 */
export function stagesPlanByName(planMd: string): boolean {
  const rule = /stage the plan by name/i.test(planMd) && /never\s+`?git add generated-docs\/`?/i.test(planMd);
  const byNameCmd = /git (?:-C <worktree> )?add generated-docs\/epic-plan\.md/i.test(planMd);
  const blanketAdd = planMd
    .split(/\r?\n/)
    .some((l) => /git (?:-C \S+ )?add generated-docs\/(?:["'`\s]|$)/i.test(l) && !/never/i.test(l) && !l.trimStart().startsWith('#'));
  return rule && byNameCmd && !blanketAdd;
}

/** plan.md states nothing of the design lands on `main` at plan time. */
export const designStaysOffMain = (planMd: string): boolean =>
  /nothing of the design lands on\s+`?main`?\s+here/i.test(planMd);

/** design-update.md states the design reaches `main` only at merge. */
export const designReachesMainOnlyAtMerge = (designUpdateMd: string): boolean =>
  /reach(?:es)?\s+`?main`?\s+only\s+(?:at|when).*merge/i.test(designUpdateMd);

// ---------------------------------------------------------------------------
// AC6 — the build re-checks the parked design and warns on drift (continue.md)
// ---------------------------------------------------------------------------

/**
 * READY-TO-BUILD compares the stored fingerprint and, on mismatch, ASKS the user (with the
 * two real options). The `AskUserQuestion` must be bound to the drift ("match: false …
 * otherwise") context — not just present somewhere in continue.md (there are ~11 AUQs) — so
 * deleting the drift prompt actually turns this red.
 */
export function hasDriftCheck(continueMd: string): boolean {
  const t = continueMd.replace(/\s+/g, ' ');
  const compares = /design-fingerprint\.js\s+--compare/i.test(t);
  const asksOnDrift = /match:\s*`?false`?.{0,160}?otherwise.{0,260}?AskUserQuestion/i.test(t);
  const options = /adjust the affected stories/i.test(t) && /build the stories as approved/i.test(t);
  return compares && asksOnDrift && options;
}

// ---------------------------------------------------------------------------
// AC8 — /plan works in an isolated worktree, never disturbing a build
// ---------------------------------------------------------------------------

export const hasWorktreeIsolation = (planMd: string): boolean => {
  const t = planMd.replace(/\s+/g, ' '); // collapse so the wording can wrap across lines
  return (
    /worktree cut from .*?\bmain\b/i.test(t) &&
    /no `?epic\/<slug>`? branch is created/i.test(t) &&
    /never disturbs a build/i.test(t)
  );
};

// ---------------------------------------------------------------------------
// AC7 — no dead-end redirect (hunt the residual, don't grep the good phrase)
// ---------------------------------------------------------------------------

/** The explicit guards that a project-fact/design change is NOT sent to /start. */
export const hasNoStartGuards = (planMd: string): boolean =>
  /never send the user to\s+`?\/start`?/i.test(planMd) && /don'?t send them to\s+`?\/start`?/i.test(planMd);

const FACT_KEYWORDS = /\b(roles?|auth|sign-?in|backend|compliance|styling|colou?rs?|palette|design|project[- ]?facts?|project-level)\b/i;
// Legitimate /start routes (build an epic, set up a project, re-init, migrate) — allowed even
// alongside a fact keyword. Checked in a window around the /start (words before OR after).
const LEGIT_ROUTE = /\b(?:build|set (?:it|one|them|this) up|set up|pick it|pick (?:it )?from|initiali[sz]|re-?init|migrat|line it up|to plan|to build|to set)\b/i;
// A negation adjacent to /start: "never send … to /start" — the guard, not a redirect.
const START_NEGATION = /(?:never|don'?t|do not)\s+\w*\s*(?:send|redirect|point|route|push)\b/i;

export interface RedirectHit {
  line: number;
  text: string;
}

/**
 * Residual dead-end redirect: text that routes a project-fact/design change TO `/start` as the
 * place to make it. Uses a 3-line window (so a redirect wrapping across lines is caught), and
 * excludes legitimate routes (build/setup/init) and the negated guard lines. This is a wording
 * tripwire — the semantic "is this really a dead-end" call belongs to Tier 3. Empty = clean.
 */
export function findProjectFactRedirect(md: string): RedirectHit[] {
  const lines = md.split(/\r?\n/);
  const out: RedirectHit[] = [];
  for (let i = 0; i < lines.length; i++) {
    if (!/\/start/i.test(lines[i])) continue;
    const window = [lines[i - 1] ?? '', lines[i], lines[i + 1] ?? ''].join(' ').replace(/\s+/g, ' ');
    if (!FACT_KEYWORDS.test(window)) continue; // legit non-fact routes
    if (START_NEGATION.test(window)) continue; // guard line
    if (LEGIT_ROUTE.test(window)) continue; // build/setup/init route
    out.push({ line: i + 1, text: lines[i].trim() });
  }
  return out;
}
