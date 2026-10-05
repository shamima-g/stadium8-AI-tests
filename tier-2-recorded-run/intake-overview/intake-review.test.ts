/**
 * Step 7 — the first REAL human-review check wired end-to-end (intake #476 facts-correct, #478
 * detail-pointed) against the `intake-contact-form` capture.
 *
 * The review bundle (manifest.json + review.html) was generated from the capture into the slot's review/
 * dir (helpers/intake-review.ts + writeReview). This suite loads that manifest and registers the review
 * checks via `reviewSuite`: with no verdict yet they SKIP visibly ("awaiting review") — never a fake pass;
 * a reviewer opens review.html, answers Yes/No, and `npm run ingest-verdict <dir>` places verdict.json,
 * after which these turn green/red (proven end-to-end by the Step-5 calibration). The deterministic intake
 * invariants stay in intake-recorded-run.test.ts; this file is ONLY the subjective residuals.
 */
import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { reviewSuite } from '../../helpers/review-suite';
import { INTAKE_REVIEW_CHECKS, buildIntakeReviewManifestFromCapture } from '../../helpers/intake-review';
import { loadGoldenRun } from '../../helpers/golden-run';
import { stampFor, type EvidenceItem } from '../../helpers/human-review';

const SLOT_DIR = path.resolve(process.cwd(), 'fixtures', 'golden-runs', 'intake-contact-form');
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
  console.warn('[intake-review] review bundle not generated — run the intake review generator first');
}

// The review bundle is a COMMITTED artifact (generated from the committed capture) — its absence is a
// failure (fail-closed), not a silent all-skip. Only the VERDICT is legitimately absent-until-reviewed.
describe('intake review bundle — committed and present', () => {
  it('manifest.json + review.html exist in the slot (regenerate the bundle if this reds)', () => {
    expect(present, `missing ${manifestPath}`).toBe(true);
    expect(fs.existsSync(path.join(REVIEW_DIR, 'review.html'))).toBe(true);
  });
});

// Sanity on the generated bundle (what the reviewer opens / what ingest validates against).
describe.skipIf(!present)('intake review bundle — well-formed', () => {
  it('review.html exists and embeds the manifest stamp (build-time == read-time)', () => {
    const html = fs.readFileSync(path.join(REVIEW_DIR, 'review.html'), 'utf8');
    expect(html).toContain(JSON.stringify(stampFor(items)));
  });
  it('the manifest carries exactly the two subjective intake checks', () => {
    expect(items.map((i) => i.id).sort()).toEqual(INTAKE_REVIEW_CHECKS.map((c) => c.id).sort());
  });
});

// Drift guard: the committed bundle must still equal what the builder produces now.
describe.skipIf(!present)('committed bundle has NOT drifted from the builder', () => {
  it('the committed manifest stamp equals a fresh rebuild from the capture (regenerate if this reds)', () => {
    const g = loadGoldenRun('intake-contact-form');
    try {
      expect(g.present, g.reason).toBe(true);
      const rebuilt = buildIntakeReviewManifestFromCapture(g.root as string, 'intake-contact-form');
      expect(stampFor(rebuilt.items)).toBe(stampFor(items));
    } finally {
      g.cleanup();
    }
  });
});

// The wired review checks: skip-until-reviewed (dev), red under REQUIRE_REVIEW, green/red once a verdict lands.
if (present) {
  reviewSuite('intake overview — subjective human review (#476 facts, #478 detail)', REVIEW_DIR, items, INTAKE_REVIEW_CHECKS);
} else {
  describe.skip('intake overview — subjective human review (bundle not generated)', () => {
    it.skip('awaiting review bundle', () => {});
  });
}
