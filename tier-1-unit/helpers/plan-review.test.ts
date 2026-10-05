/**
 * Unit test — the design-update review-manifest builder (`helpers/plan-review.ts`). Pure over strings:
 * it turns a captured design digest + the parked epic's state.json into the two design-artifact review
 * checks (digest faithfulness, held-decision clarity).
 */
import { describe, it, expect } from 'vitest';
import { buildPlanReviewManifest, decisionsEvidence, PLAN_REVIEW_CHECKS } from '../../helpers/plan-review';

const DIGEST = '# Design Digest\n\nThree screens: Board, Task detail, Settings. Primary blue #2563eb.';
const STATE = JSON.stringify({
  epic: {
    parkedDesignUpdate: true,
    designDecisions: [{ line: 'Primary colour is pink #ec4899 (design wins over the earlier blue #2563eb)', supersedes: 'blue #2563eb' }],
  },
});

describe('decisionsEvidence', () => {
  it('formats the held decisions readably', () => {
    const e = decisionsEvidence(STATE);
    expect(e).toContain('pink #ec4899');
    expect(e).toContain('#1:');
  });
  it('falls back when there are no decisions / malformed state', () => {
    expect(decisionsEvidence(JSON.stringify({ epic: { designDecisions: [] } }))).toMatch(/no designDecisions/);
    expect(decisionsEvidence('{ not json')).toMatch(/no designDecisions/);
  });
});

describe('buildPlanReviewManifest', () => {
  const m = buildPlanReviewManifest(DIGEST, STATE, 'plan-design-update');

  it('produces exactly the two design checks with the catalog ids', () => {
    expect(m.items.map((i) => i.id)).toEqual(PLAN_REVIEW_CHECKS.map((c) => c.id));
  });
  it('the digest check shows the digest; the decision check shows the held decision', () => {
    expect(m.items.find((i) => i.id === 'plan-design-digest-faithful')!.evidence).toContain('Board, Task detail, Settings');
    expect(m.items.find((i) => i.id === 'plan-design-decision-clear')!.evidence).toContain('pink #ec4899');
  });
  it('the captureLabel carries the slot name', () => {
    expect(m.captureLabel).toMatch(/plan-design-update/);
  });
  it('falls back gracefully on an empty digest', () => {
    expect(buildPlanReviewManifest('', STATE).items[0].evidence).toMatch(/no design digest/);
  });
});
