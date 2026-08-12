/**
 * epicHasDecisionTrail — the Tier-2 journal-invariant refinement, good/broken.
 *
 * The contact-form run surfaced that a minimal design-driven epic can be COMPLETE with no
 * per-epic journal.md — its decisions live in the design digest's "Your Decisions" instead. So the
 * Tier-2 invariant now accepts EITHER a non-empty journal OR the design digest, while keeping teeth
 * (an empty journal, or neither trail, still fails). This proves that logic over synthetic inputs;
 * recorded-run.test.ts applies it over the golden run.
 */

import { describe, it, expect } from 'vitest';
import { epicHasDecisionTrail } from '../../helpers/design-digest';

const DIGEST_WITH_DECISIONS = `## Your Decisions

- Sign-in uses email + password, no SSO (you told us)

## Screens
`;
const DIGEST_EMPTY = `## Your Decisions

*Nothing yet — this fills in as you settle things while we build.*

## Screens
`;

describe('epicHasDecisionTrail — Tier-2 journal refinement', () => {
  it('PASS: a non-empty journal.md is a decision trail', () => {
    expect(epicHasDecisionTrail('- Chose X over Y because Z\n', null)).toEqual({ ok: true, reason: 'journal.md' });
  });

  it('PASS: no journal, but the design digest records decisions (design-driven run)', () => {
    const r = epicHasDecisionTrail(null, DIGEST_WITH_DECISIONS);
    expect(r.ok, JSON.stringify(r)).toBe(true);
    expect(r.reason).toMatch(/design digest/);
  });

  it('BROKEN: a present-but-empty journal.md fails (a real bug, kept with teeth)', () => {
    expect(epicHasDecisionTrail('   \n\n', DIGEST_WITH_DECISIONS).ok).toBe(false);
  });

  it('BROKEN: no journal and no recorded decisions anywhere fails', () => {
    expect(epicHasDecisionTrail(null, null).ok).toBe(false);
    // "Nothing yet" in the digest is not a real decision, so it does not rescue a missing journal.
    expect(epicHasDecisionTrail(null, DIGEST_EMPTY).ok).toBe(false);
  });
});
