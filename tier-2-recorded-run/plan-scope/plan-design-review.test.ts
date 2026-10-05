/**
 * The design-update subjective human-review checks wired to the `plan-design-update` capture: the design
 * digest's faithfulness/plainness, and whether the held pink-vs-blue decision is recorded clearly.
 *
 * Reviews ARTIFACTS from the committed capture (digest.md + the parked epic's state.json) — NOT the live
 * read-back (#14) or conflict-ask (#15), which are transcript/eyeball. The bundle (manifest.json +
 * review.html) is committed in the slot's review/ dir; with no verdict the checks SKIP (dev) / RED
 * (REQUIRE_REVIEW); a reviewer answers on review.html and `npm run ingest-verdict` flips them green/red.
 */
import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { reviewSuite } from '../../helpers/review-suite';
import { PLAN_REVIEW_CHECKS, buildPlanReviewManifestFromCapture } from '../../helpers/plan-review';
import { loadGoldenRun } from '../../helpers/golden-run';
import { stampFor, type EvidenceItem } from '../../helpers/human-review';

const SLOT_DIR = path.resolve(process.cwd(), 'fixtures', 'golden-runs', 'plan-design-update');
const REVIEW_DIR = path.join(SLOT_DIR, 'review'); // committed INPUTS (review.html + manifest.json)
const manifestPath = path.join(REVIEW_DIR, 'manifest.json');
const present = fs.existsSync(manifestPath);
// reviewSuite resolves the benchmark (from the slot meta) and thus the TestResults/review/<benchmark>/<ts>/
// results dir internally — via the SAME helper the ingest writer uses, so writer and reader can't disagree.
const items: EvidenceItem[] = present
  ? (JSON.parse(fs.readFileSync(manifestPath, 'utf8')) as { items: EvidenceItem[] }).items
  : [];

if (!present) {
  // eslint-disable-next-line no-console
  console.warn('[plan-design-review] review bundle not generated');
}

// The bundle is a committed artifact — its absence is a failure, not a silent all-skip.
describe('plan design review bundle — committed and present', () => {
  it('manifest.json + review.html exist in the slot (regenerate the bundle if this reds)', () => {
    expect(present, `missing ${manifestPath}`).toBe(true);
    expect(fs.existsSync(path.join(REVIEW_DIR, 'review.html'))).toBe(true);
  });
});

describe.skipIf(!present)('plan design review bundle — well-formed', () => {
  it('review.html embeds the manifest stamp (build-time == read-time)', () => {
    expect(fs.readFileSync(path.join(REVIEW_DIR, 'review.html'), 'utf8')).toContain(JSON.stringify(stampFor(items)));
  });
  it('the manifest carries exactly the two design checks', () => {
    expect(items.map((i) => i.id).sort()).toEqual(PLAN_REVIEW_CHECKS.map((c) => c.id).sort());
  });
});

// Drift guard: the committed bundle must still equal what the builder produces now — else a builder change
// left the committed review.html/manifest stale (and the stamp would no longer match a fresh review).
describe.skipIf(!present)('committed bundle has NOT drifted from the builder', () => {
  it('the committed manifest stamp equals a fresh rebuild from the capture (regenerate if this reds)', () => {
    const g = loadGoldenRun('plan-design-update');
    try {
      expect(g.present, g.reason).toBe(true);
      const rebuilt = buildPlanReviewManifestFromCapture(g.root as string, 'plan-design-update');
      expect(stampFor(rebuilt.items)).toBe(stampFor(items));
    } finally {
      g.cleanup();
    }
  });
});

// The wired review checks: skip-until-reviewed (dev), red under REQUIRE_REVIEW, green/red once reviewed.
if (present) {
  reviewSuite('plan design-update — subjective human review (digest faithfulness, decision clarity)', REVIEW_DIR, items, PLAN_REVIEW_CHECKS);
} else {
  describe.skip('plan design-update — subjective human review (bundle not generated)', () => {
    it.skip('awaiting review bundle', () => {});
  });
}
