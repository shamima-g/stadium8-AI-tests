/**
 * build-tests-together — Tier-2 per-story detectors (pure, so each gets a good-case AND broken-case unit
 * test in rules.test.ts, per workflow-tests.md §2). The parity check itself lives in
 * helpers/control-refs.compareControls (already calibrated); these cover file-presence (T2.3) and the
 * routable-spec live-test rule (T2.4).
 */

/**
 * T2.3 — a built story needs both test files. The Vitest file is only excused when the story had no
 * `vitest`-tagged AC — which we read from the transcript, NOT from the agent's bare word: `vitestExpected`
 * is true when the story's `test-generator` return listed a `.test.tsx` path (or is unknown → assume
 * expected, so a silently-missing file is flagged, never fail-open).
 */
export function missingFileOffense(
  slug: string,
  n: string,
  hasVitestFile: boolean,
  hasSpecFile: boolean,
  vitestExpected: boolean,
): string | null {
  if (!hasSpecFile) return `${slug} story ${n}: missing web/e2e/epic-${slug}-story-${n}-*.spec.ts`;
  if (vitestExpected && !hasVitestFile) {
    return `${slug} story ${n}: missing web/src/__tests__/integration/epic-${slug}-story-${n}-*.test.tsx (its agent reported Vitest tests)`;
  }
  return null;
}

/** A declared non-routable stub carries a line-start `// Non-routable:` marker (not a free-text word). */
const NON_ROUTABLE_MARKER = /^\s*\/\/\s*non-routable\b/im;

/** Count `test(` call-sites — the version-agnostic stub `test('x', () => { test.fixme() })` counts as one. */
const liveFormCount = (src: string): number => (src.match(/(^|[^.\w])test\s*\(/gm) ?? []).length;
/** Count `test.fixme(` call-sites. */
const fixmeCount = (src: string): number => (src.match(/test\.fixme\s*\(/g) ?? []).length;

/**
 * T2.4 — returns true (OFFENSE) when a spec has no `test()` free of `test.fixme()` and is not a declared
 * non-routable stub. A spec passes when at least one `test(` block carries no fixme (liveForm > fixme),
 * so abusing the version-agnostic stub form on a routable spec (`test('x', () => test.fixme())` with no
 * `// Non-routable:` marker) is correctly flagged — unlike a whole-file substring scan for "deferred".
 */
export function routableFixmeOffense(specSrc: string): boolean {
  if (liveFormCount(specSrc) > fixmeCount(specSrc)) return false; // ≥1 real test() without a fixme
  return !NON_ROUTABLE_MARKER.test(specSrc); // all-fixme / empty → offense unless declared non-routable
}
