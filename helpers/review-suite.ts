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
import { loadVerdict, stampFor, type EvidenceItem } from './human-review';
import { reviewDecision, reviewCoverage, reviewRequired, validateChecks, type ReviewCheck } from './review-logic';

export type { ReviewCheck } from './review-logic';

/**
 * Register a vitest suite: one check per criterion + an aggregate coverage line. `items` is the slot's
 * manifest items (so `stampFor(items)` is the current stamp `loadVerdict` re-checks the verdict against).
 * Throws on a mis-wired `checks` list (empty / duplicate / id not in the stamped items).
 */
export function reviewSuite(label: string, reviewDir: string, items: EvidenceItem[], checks: ReviewCheck[]): void {
  validateChecks(items, checks); // fail-closed: a mis-wired suite is a red load error, not a silent green
  const v = loadVerdict(reviewDir, stampFor(items));
  const requireReview = reviewRequired();
  const cov = reviewCoverage(v, checks.map((c) => c.id));

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
