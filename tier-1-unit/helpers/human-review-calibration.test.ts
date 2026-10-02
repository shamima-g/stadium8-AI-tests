/**
 * Step 5 — the harness's OWN broken-case calibration (workflow-tests §2 rule 1).
 *
 * The human-review harness's "assertion" is a person's Yes/No. Rule 1 demands a good AND a broken case —
 * proof the harness can actually FAIL, not only pass. These two recorded fixtures supply it:
 *   - fixtures/human-review-calibration/bad/  — a planted-bad capture (a jargon-filled message) + the
 *     recorded "No" a correct reviewer gives → the harness must resolve it to RED (fail).
 *   - fixtures/human-review-calibration/good/ — a planted-good capture (a plain message) + a recorded
 *     "Yes" (with citation) → GREEN (pass).
 * This proves the full pipeline (loadVerdict → checkOutcome → reviewDecision) carries a reviewer's No to
 * a failing test and a Yes to a passing one. (The "would a human actually catch it" step is inherently
 * human; the fixtures document the expected human answer against clearly bad/good evidence.)
 */
import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { loadVerdict, stampFor, type EvidenceItem } from '../../helpers/human-review';
import { reviewDecision } from '../../helpers/review-logic';

const ROOT = path.resolve(process.cwd(), 'fixtures', 'human-review-calibration');
const CHECK_ID = 'plain-language';

function load(caseDir: string) {
  const dir = path.join(ROOT, caseDir);
  const items = (JSON.parse(fs.readFileSync(path.join(dir, 'manifest.json'), 'utf8')) as { items: EvidenceItem[] }).items;
  const v = loadVerdict(dir, stampFor(items));
  return { dir, items, v };
}

describe('human-review calibration — the harness can FAIL on a bad capture and PASS on a good one', () => {
  it('both recorded verdicts match their capture stamp, and review.html embeds it (regenerate if stampFor changed)', () => {
    for (const c of ['bad', 'good']) {
      const { dir, items, v } = load(c);
      expect(v.present && !v.stale, `${c}: verdict stamp must match its manifest`).toBe(true);
      // the committed review.html baked the same stamp at build time (build-time == read-time)
      const html = fs.readFileSync(path.join(dir, 'review.html'), 'utf8');
      expect(html, `${c}/review.html must embed the capture stamp`).toContain(JSON.stringify(stampFor(items)));
    }
  });

  it('BROKEN case: the planted-bad capture + recorded "No" resolves to RED (fail)', () => {
    const { v, items } = load('bad');
    // the planted evidence really is bad (jargon), so a correct reviewer's "No" is justified
    expect(items[0].evidence).toMatch(/tsc|Tier-4|isLoading|eslint/);
    const d = reviewDecision(v, CHECK_ID, false);
    expect(d.action, d.reason).toBe('fail');
  });

  it('GOOD case: the planted-good capture + recorded "Yes" (with citation) resolves to GREEN (pass)', () => {
    const { v, items } = load('good');
    expect(items[0].evidence).not.toMatch(/tsc|Tier-4|isLoading|eslint/);
    const d = reviewDecision(v, CHECK_ID, false);
    expect(d.action, d.reason).toBe('pass');
  });

  it('a "Yes" in these fixtures only counts because it carries a citation (bare Yes would not pass)', () => {
    const { v } = load('good');
    expect((v.citations[CHECK_ID] ?? '').length).toBeGreaterThan(0);
  });
});
