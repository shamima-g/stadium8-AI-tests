/**
 * Step 4 unit tests — the pure review decision logic (`helpers/review-logic.ts`): reviewRequired (the gate),
 * reviewDecision (skip/red/green), reviewCoverage (N of M), and validateChecks (fail-closed wiring guard).
 * Good AND broken case per check. (reviewSuite is thin vitest glue over these, exercised at Step 7.)
 */
import { describe, it, expect } from 'vitest';
import { reviewRequired, reviewDecision, reviewCoverage, validateChecks } from '../../helpers/review-logic';
import type { LoadedVerdict, EvidenceItem } from '../../helpers/human-review';

function verdict(partial: Partial<LoadedVerdict>): LoadedVerdict {
  return { present: true, stale: false, reason: '', results: {}, citations: {}, ...partial };
}

describe('reviewRequired — mirrors EXPECT_TEMPLATE (any non-empty value enables)', () => {
  it('off when unset or empty/whitespace', () => {
    expect(reviewRequired({})).toBe(false);
    expect(reviewRequired({ REQUIRE_REVIEW: '' })).toBe(false);
    expect(reviewRequired({ REQUIRE_REVIEW: '   ' })).toBe(false);
  });
  it('ON for any non-empty value — including the CI-canonical ones that === "1" would miss', () => {
    for (const val of ['1', 'true', 'TRUE', 'yes', '0', 'false']) {
      expect(reviewRequired({ REQUIRE_REVIEW: val }), `value ${val}`).toBe(true);
    }
  });
});

describe('reviewDecision — skip/red/green + REQUIRE', () => {
  const reviewed = verdict({ results: { a: 'pass', b: 'fail' }, citations: { a: 'cited' } });

  it('a reviewed Yes (with citation) => pass, both modes', () => {
    expect(reviewDecision(reviewed, 'a', false).action).toBe('pass');
    expect(reviewDecision(reviewed, 'a', true).action).toBe('pass');
  });
  it('a reviewed No => fail, both modes', () => {
    expect(reviewDecision(reviewed, 'b', false).action).toBe('fail');
    expect(reviewDecision(reviewed, 'b', true).action).toBe('fail');
  });
  it('a Yes WITHOUT a citation => fail even in dev mode', () => {
    expect(reviewDecision(verdict({ results: { a: 'pass' }, citations: {} }), 'a', false).action).toBe('fail');
  });
  it('unreviewed => SKIP in dev, RED under REQUIRE', () => {
    expect(reviewDecision(reviewed, 'never', false).action).toBe('skip');
    const d = reviewDecision(reviewed, 'never', true);
    expect(d.action).toBe('fail');
    expect(d.reason).toMatch(/REQUIRE_REVIEW/);
  });
  it('a STALE verdict => skip in dev, red under REQUIRE (results cleared)', () => {
    const stale = verdict({ stale: true });
    expect(reviewDecision(stale, 'a', false).action).toBe('skip');
    expect(reviewDecision(stale, 'a', true).reason).toMatch(/stale/);
  });
});

describe('reviewCoverage — N of M settled', () => {
  it('counts an honoured Yes + a recorded No as settled, skips as not', () => {
    const v = verdict({ results: { a: 'pass', b: 'fail' }, citations: { a: 'c' } });
    expect(reviewCoverage(v, ['a', 'b', 'c'])).toEqual({ reviewed: 2, total: 3, state: 'reviewed' });
  });
  it('a citation-less Yes does NOT count as settled (the gate fails it, so it must not read as done)', () => {
    // Was previously (wrongly) counted as answered — that let the coverage line go green + silenced the notice
    // while the check actually failed. It must now keep the set incomplete.
    expect(reviewCoverage(verdict({ results: { a: 'pass' }, citations: {} }), ['a']).reviewed).toBe(0);
  });
  it('absent => 0 reviewed, "awaiting review"; stale => "verdict STALE"', () => {
    expect(reviewCoverage(verdict({ present: false }), ['a', 'b'])).toEqual({ reviewed: 0, total: 2, state: 'awaiting review' });
    expect(reviewCoverage(verdict({ stale: true }), ['a']).state).toMatch(/STALE/);
  });
});

describe('validateChecks — fail-closed wiring guard', () => {
  const items: EvidenceItem[] = [{ id: 'a', criterion: 'q', evidence: 'x' }, { id: 'b', criterion: 'q', evidence: 'y' }];
  it('accepts a well-formed checks list (unique ids, all present in items)', () => {
    expect(() => validateChecks(items, [{ id: 'a', criterion: 'qa' }, { id: 'b', criterion: 'qb' }])).not.toThrow();
  });
  it('throws on an EMPTY checks list', () => {
    expect(() => validateChecks(items, [])).toThrow(/no checks/);
  });
  it('throws on DUPLICATE check ids', () => {
    expect(() => validateChecks(items, [{ id: 'a', criterion: 'q1' }, { id: 'a', criterion: 'q2' }])).toThrow(/duplicate check id/);
  });
  it('throws on a check id with NO matching evidence item (orphan)', () => {
    expect(() => validateChecks(items, [{ id: 'z', criterion: 'q' }])).toThrow(/no evidence item/);
  });
});
