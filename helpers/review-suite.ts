/**
 * Human-review harness — Step 4 (vitest glue). `reviewSuite(...)` registers one vitest check per subjective
 * criterion against a slot's recorded verdict, with a uniform skip/red/green discipline + the fail-closed
 * REQUIRE_REVIEW gate:
 *   - reviewed Yes(+citation) -> green;  reviewed No -> red;
 *   - unreviewed/stale -> SKIP by default (visible, never a fake pass), RED when REQUIRE_REVIEW is set
 *     (release runs). In dev an INCOMPLETE coverage line is itself registered as a skip (not a reassuring
 *     green), so "all green" can't hide an unreviewed set.
 * The pure decisions live in review-logic.ts (no vitest import); this file is the thin glue.
 */
import { describe, it, expect } from 'vitest';
import path from 'node:path';
import {
  loadLatestVerdict,
  stampFor,
  readSlotBenchmark,
  reviewResultsDir,
  fileUrl,
  repoRelative,
  type EvidenceItem,
  type LoadedLatestVerdict,
} from './human-review';
import { reviewDecision, reviewCoverage, reviewRequired, validateChecks, type ReviewCheck } from './review-logic';

export type { ReviewCheck } from './review-logic';

/**
 * The actionable notice printed when a slot has pending/stale reviews — pure (returns the message or null),
 * so "all reviewed ⇒ silent" and the message shape are unit-testable without capturing console output. It
 * names the review page to open and the exact `ingest-verdict` command, so a user running the suite learns a
 * human decision is waiting instead of seeing an opaque "N skipped".
 */
export function reviewAnnouncement(
  label: string,
  reviewDir: string,
  loaded: { stale: boolean },
  cov: { reviewed: number; total: number },
  requireReview: boolean,
): string | null {
  const pending = cov.reviewed < cov.total;
  if (!pending && !loaded.stale) return null; // fully reviewed and current — nothing to announce
  const kind = loaded.stale ? 'stale' : 'pending';
  const what = loaded.stale
    ? 'the capture changed since review — re-review'
    : `${cov.total - cov.reviewed} of ${cov.total} unreviewed`;
  const effect = requireReview ? 'RED under REQUIRE_REVIEW' : 'skipped in dev';
  return [
    `[review ${kind}] ${label} — ${what} (${effect}).`,
    `  open  ${fileUrl(path.join(reviewDir, 'review.html'))}`,
    `  then  npm run ingest-verdict ${repoRelative(reviewDir)}`,
  ].join('\n');
}

/**
 * Register a vitest suite: one check per criterion + an aggregate coverage line. `reviewDir` is the slot's
 * committed inputs dir (holds manifest.json + review.html); the benchmark (and thus the results dir the
 * recorded verdict is read from) is resolved from the slot's meta.json via the SAME helper the writer uses,
 * so reader and writer can't disagree. `items` is the slot's manifest items (so `stampFor(items)` is the
 * current stamp the loader re-checks the verdict against). The newest dated verdict whose stamp still
 * matches is read. Throws on a mis-wired `checks` list (empty / dup / orphan id).
 */
export function reviewSuite(label: string, reviewDir: string, items: EvidenceItem[], checks: ReviewCheck[]): void {
  validateChecks(items, checks); // fail-closed: a mis-wired suite is a red load error, not a silent green
  // Resolve the benchmark (reads the slot meta.json). A broken/missing meta.json is fail-closed as a single
  // RED test for THIS slot — not an uncaught throw at collection time, which would take down every other test
  // in the file. (Mirrors how review:status reports such a slot as one `error` row.)
  let resultsDir: string;
  try {
    resultsDir = reviewResultsDir(readSlotBenchmark(reviewDir));
  } catch (e) {
    describe(label, () => {
      it('[review config] slot meta.json resolves a benchmark', () => {
        throw e;
      });
    });
    return;
  }
  const v: LoadedLatestVerdict = loadLatestVerdict(resultsDir, stampFor(items));
  const requireReview = reviewRequired();
  const cov = reviewCoverage(v, checks.map((c) => c.id));

  // Make a waiting human decision visible during a normal test run (not buried in an opaque skip count).
  const notice = reviewAnnouncement(label, reviewDir, v, cov, requireReview);
  if (notice) console.warn(notice);

  describe(label, () => {
    for (const c of checks) {
      const d = reviewDecision(v, c.id, requireReview);
      const body = () => {
        if (d.action === 'fail') throw new Error(d.reason);
        // 'pass' -> green. ('skip' is registered via it.skip and never runs this body.)
      };
      if (d.action === 'skip') it.skip(c.criterion, body);
      else it(c.criterion, body);
    }
    // Coverage line: green when complete; under REQUIRE it fails if anything is unreviewed; in dev an
    // incomplete line is a SKIP (not a reassuring green) so a zero-coverage set can't read as all-green.
    const incomplete = cov.reviewed < cov.total;
    const covBody = () => {
      if (requireReview) expect(cov.reviewed, `${cov.total - cov.reviewed} subjective check(s) unreviewed`).toBe(cov.total);
    };
    const name = `[coverage] ${cov.reviewed}/${cov.total} reviewed — ${cov.state}`;
    if (!requireReview && incomplete) it.skip(name, covBody);
    else it(name, covBody);
  });
}
