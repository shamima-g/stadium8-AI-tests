/**
 * Human-review harness — Step 4 (pure core). The decision logic behind the review test-wiring, with NO
 * vitest import, so it is reusable at runtime and unit-testable without the test runner (the vitest glue
 * lives in review-suite.ts). See test-plans/human-review-harness-plan.md.
 */
import { checkOutcome, type LoadedVerdict, type EvidenceItem } from './human-review';

export type ReviewAction = 'pass' | 'fail' | 'skip';
export interface ReviewCheck {
  id: string;
  criterion: string;
}

/**
 * Whether review is REQUIRED (release gate). Mirrors the repo's EXPECT_TEMPLATE idiom
 * (`if (!process.env.EXPECT_TEMPLATE) return`): enabled by ANY non-empty value, off only when unset/empty.
 * This avoids the trap where a plausible CI value (`true`, `0`) silently disables the gate.
 */
export function reviewRequired(env: NodeJS.ProcessEnv = process.env): boolean {
  return !!(env.REQUIRE_REVIEW && env.REQUIRE_REVIEW.trim());
}

/** Pure: what the test for check `id` should DO, given the loaded verdict and whether review is required. */
export function reviewDecision(v: LoadedVerdict, id: string, requireReview: boolean): { action: ReviewAction; reason: string } {
  const o = checkOutcome(v, id);
  if (o.outcome === 'skip' && requireReview) {
    return { action: 'fail', reason: `#${id}: unreviewed and REQUIRE_REVIEW set — ${v.stale ? 'verdict stale, re-review the current capture' : 'not reviewed'}` };
  }
  return { action: o.outcome, reason: o.reason };
}

/** Pure: coverage summary. `reviewed` = checks the reviewer actually answered (pass or fail), not skips. */
export function reviewCoverage(v: LoadedVerdict, ids: string[]): { reviewed: number; total: number; state: string } {
  const reviewed = ids.filter((id) => checkOutcome(v, id).outcome !== 'skip').length;
  const state = v.stale ? 'verdict STALE — re-review' : !v.present ? 'awaiting review' : 'reviewed';
  return { reviewed, total: ids.length, state };
}

/**
 * Fail-closed wiring guard. A review suite must have >=1 check, unique check ids, and every check id must
 * correspond to a stamped evidence item (else the stamp/verdict cannot speak to it). Throws — surfacing as
 * a red suite-load error rather than a silently-green empty/mis-wired suite.
 */
export function validateChecks(items: EvidenceItem[], checks: ReviewCheck[]): void {
  if (!checks.length) throw new Error('reviewSuite: no checks supplied (wiring error)');
  const ids = checks.map((c) => c.id);
  const dup = ids.find((id, i) => ids.indexOf(id) !== i);
  if (dup) throw new Error(`reviewSuite: duplicate check id '${dup}'`);
  const itemIds = new Set(items.map((i) => i.id));
  const orphan = ids.find((id) => !itemIds.has(id));
  if (orphan) throw new Error(`reviewSuite: check id '${orphan}' has no evidence item in the stamped manifest`);
}
