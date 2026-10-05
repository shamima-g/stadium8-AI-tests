/**
 * Unit tests for `reviewAnnouncement` — the actionable "a human decision is waiting" notice reviewSuite
 * prints when a slot has pending/stale checks. Pure (returns the message or null), so "fully reviewed =>
 * silent" and the message shape are tested without capturing console output.
 */
import { describe, it, expect } from 'vitest';
import path from 'node:path';
import { reviewAnnouncement } from '../../helpers/review-suite';
import { fileUrl } from '../../helpers/human-review';

const DIR = path.resolve('fixtures', 'golden-runs', 'intake-contact-form', 'review');

describe('reviewAnnouncement — surfaces a waiting review (never buried in a skip count)', () => {
  it('returns null when fully reviewed and current (nothing to say)', () => {
    expect(reviewAnnouncement('L', DIR, { stale: false }, { reviewed: 2, total: 2 }, false)).toBeNull();
  });

  it('announces pending with the review.html link and the exact ingest command', () => {
    const msg = reviewAnnouncement('intake', DIR, { stale: false }, { reviewed: 0, total: 2 }, false);
    expect(msg).not.toBeNull();
    expect(msg!).toContain('[review pending] intake');
    expect(msg!).toContain('2 of 2 unreviewed'); // 2 unreviewed out of 2 total
    expect(msg!).toContain('skipped in dev');
    expect(msg!).toContain(fileUrl(path.join(DIR, 'review.html')));
    expect(msg!).toContain('npm run ingest-verdict');
  });

  it('partially reviewed is still announced (coverage incomplete)', () => {
    const msg = reviewAnnouncement('intake', DIR, { stale: false }, { reviewed: 1, total: 2 }, false);
    expect(msg!).toContain('1 of 2 unreviewed');
  });

  it('under REQUIRE_REVIEW the effect reads RED, not skip', () => {
    const msg = reviewAnnouncement('intake', DIR, { stale: false }, { reviewed: 0, total: 2 }, true);
    expect(msg!).toContain('RED under REQUIRE_REVIEW');
  });

  it('announces stale (capture changed) distinctly from pending', () => {
    const msg = reviewAnnouncement('intake', DIR, { stale: true }, { reviewed: 0, total: 2 }, false);
    expect(msg!).toContain('[review stale] intake');
    expect(msg!).toContain('re-review');
  });
});
