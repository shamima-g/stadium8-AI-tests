/**
 * Guards the VERBOSITY review-check catalog (`helpers/verbosity-review-checks.ts`) — the 5 output-quality
 * criteria re-homed from the retired AI judge. Preserves the invariants the old judge.test.ts held
 * (5 checks, ACs 3/4/5/7/8, unique ids) so the migration lost nothing.
 */
import { describe, it, expect } from 'vitest';
import { VERBOSITY_REVIEW_CHECKS } from '../../helpers/verbosity-review-checks';

describe('verbosity review checks — the retired judge criteria, re-homed intact', () => {
  it('has exactly the 5 criteria, covering ACs 3/4/5/7/8', () => {
    expect(VERBOSITY_REVIEW_CHECKS).toHaveLength(5);
    expect(VERBOSITY_REVIEW_CHECKS.map((c) => c.ac).sort((a, b) => a - b)).toEqual([3, 4, 5, 7, 8]);
  });
  it('every check has a unique id and a non-empty criterion + guidance', () => {
    const ids = new Set(VERBOSITY_REVIEW_CHECKS.map((c) => c.id));
    expect(ids.size).toBe(VERBOSITY_REVIEW_CHECKS.length);
    for (const c of VERBOSITY_REVIEW_CHECKS) {
      expect(c.id, 'id').toMatch(/\S/);
      expect(c.criterion.length, `${c.id} criterion`).toBeGreaterThan(10);
      expect(c.guidance, `${c.id} guidance`).toMatch(/PASS:.*FAIL:/s);
    }
  });
});
