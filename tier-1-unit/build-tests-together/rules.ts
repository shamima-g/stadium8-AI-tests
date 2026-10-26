/**
 * build-tests-together — Tier 1 wording/wiring regression-guards (template @ stadium-builder 26-10,
 * v1.4.0 + commit 4666e23 "write each story's Vitest and Playwright tests together").
 *
 * The feature is ALREADY implemented, so every guard passes today. A guard therefore proves nothing
 * unless it can also go RED on the exact regression it protects — so each detector is exercised BOTH
 * ways in the test file: true on the real (26-10) wording, false on the two-call baseline wording taken
 * verbatim from stadium-builder23-10 (continue.md:290 / test-generator.md:11,22).
 *
 * Coupling (verified against the real 23-10 vs 26-10 files):
 *   - T1.1, T1.2, T1.3 — coupled to the two-call → one-call regression (the core of the feature).
 *   - noVitestTagsNoFile — also coupled: the clause is present in 26-10 but absent in the 23-10 split model.
 *   - testGeneratorOutputPaths + the B0.2 import clause — coupled to the `app-frontend/` → `web/` rename
 *     that shipped with this work (they go red on the 23-10 paths).
 *   - specNameRegexIntact, routableNeedsLiveTest, and the bare B0-before-B0.2 ordering — genuinely
 *     synthetic: identical in 23-10 and 26-10, so their broken case is a deliberate mutation, not the
 *     baseline. (See the test plan, "What the council changed".)
 * Detectors favour a loose, feature-preserving-reword-tolerant match over verbatim phrasing; the
 * real-template regression block in wiring.test.ts backstops any drift.
 *
 * Pure functions over file content. Not a *.test.ts file, so Vitest never collects it.
 */

/** Extract a `### Step <id>:` section up to the next `Step ` header (or EOF). */
export function stepSection(continueMd: string, id: string): string | null {
  const startRe = new RegExp(`^#{1,6}\\s*Step ${id.replace('.', '\\.')}:`, 'im');
  const m = startRe.exec(continueMd);
  if (!m) return null;
  const rest = continueMd.slice(m.index);
  // Next `### Step …` header after this one (its line starts with a newline in `rest`).
  const next = /\n#{1,6}\s*Step /.exec(rest);
  return next ? rest.slice(0, next.index) : rest;
}

// ---------------------------------------------------------------------------
// T1.1 — continue.md B0.2 launches ONE test-generator call per story (coupled to the real regression)
// ---------------------------------------------------------------------------

export function spawnsOneTestGeneratorPerStory(continueMd: string): boolean {
  const sec = stepSection(continueMd, 'B0.2');
  if (!sec) return false;
  const oneCall = /launch (?:one|a single)\s+`?test-generator`?\s+call/i.test(sec);
  const writesBoth = /writes? both (?:test )?files/i.test(sec);
  const hasStoryMode = /\bmode:\s*story\b/i.test(sec);
  const twoCall = /launch two\s+`?test-generator`?\s+calls/i.test(sec);
  const splitModes = /\bmode:\s*vitest\b/i.test(sec) && /\bmode:\s*playwright\b/i.test(sec);
  return oneCall && writesBoth && hasStoryMode && !twoCall && !splitModes;
}

// ---------------------------------------------------------------------------
// T1.2 — test-generator.md: mode "story" writes BOTH files; no per-story vitest/playwright split
// ---------------------------------------------------------------------------

export function testGeneratorStoryModeBoth(tgMd: string): boolean {
  const oneCallBoth = /one call per story writes both/i.test(tgMd); // :11
  const storyModeBoth = /["'`]story["'`][^\n]{0,40}writes? both (?:test )?files/i.test(tgMd); // :22
  const splitModes = /["'`]*vitest["'`]*\s*·\s*["'`]*playwright["'`]*/i.test(tgMd); // 23-10 :22
  return oneCallBoth && storyModeBoth && !splitModes;
}

// ---------------------------------------------------------------------------
// T1.3 — the parity mechanism + success criterion (coupled: absent in the two-agent baseline)
// ---------------------------------------------------------------------------

export function hasParityMechanism(tgMd: string): boolean {
  // Two loose anchors (reorder/reword-tolerant): the "list controls before writing" step AND the
  // "same way in both files" instruction. Both are absent in the two-agent 23-10 baseline.
  const listsControls =
    /list the stor(?:y['’]?s|ies) controls/i.test(tgMd) || /before writing (?:either|both)/i.test(tgMd);
  const sameWayBoth = /find each control the same way/i.test(tgMd);
  return listsControls && sameWayBoth;
}

export function hasParitySuccessCriterion(tgMd: string): boolean {
  return /every control is found and interacted with the same way in both files/i.test(tgMd); // :384
}

// ---------------------------------------------------------------------------
// T1.4 — shared mock-data (B0) runs before the test batch (B0.2), which imports it (synthetic guard)
// ---------------------------------------------------------------------------

export function sharedMocksBeforeTestBatch(continueMd: string): boolean {
  const b0 = continueMd.search(/^#{1,4}\s*Step B0:/im);
  const b02 = continueMd.search(/^#{1,4}\s*Step B0\.2:/im);
  if (b0 < 0 || b02 < 0 || b0 >= b02) return false;
  const sec = stepSection(continueMd, 'B0.2');
  return !!sec && /import the epic['’]?s shared mock data from\s+`?web\/src\/mocks\/data\//i.test(sec);
}

// ---------------------------------------------------------------------------
// T1.5 — filename regex + the two Rule-10 output paths are intact (synthetic guard)
// ---------------------------------------------------------------------------

export function specNameRegexIntact(namingMd: string): boolean {
  return namingMd.includes('^epic-[a-z][a-z0-9-]*-story-\\d+-[a-z][a-z0-9-]*\\.spec\\.ts$');
}

export function testGeneratorOutputPaths(tgMd: string): boolean {
  return (
    /web\/src\/__tests__\/integration\/epic-<slug>-story-<N>-<title>\.test\.tsx/i.test(tgMd) &&
    /web\/e2e\/epic-<slug>-story-<N>-<title>\.spec\.ts/i.test(tgMd)
  );
}

// ---------------------------------------------------------------------------
// T1.6 — policy rules: no-vitest-tags → no file; routable stories need a live test() (synthetic guard)
// ---------------------------------------------------------------------------

export function noVitestTagsNoFile(tgMd: string): boolean {
  return /no\s+`?vitest`?\s+tags?\s*(?:→|->|—)\s*write no Vitest file/i.test(tgMd); // :298
}

export function routableNeedsLiveTest(tgMd: string): boolean {
  return /routable stories have at least one live\s+`?test\(\)`?/i.test(tgMd); // :385
}
