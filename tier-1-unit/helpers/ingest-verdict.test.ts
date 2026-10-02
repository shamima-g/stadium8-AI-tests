/**
 * Step 3 unit tests — the pure `ingestVerdict` stamp-validation (`helpers/ingest-verdict.ts`). Fail-closed:
 * only a verdict whose stamp matches the capture's manifest is accepted. Good AND broken case per check.
 * (The clipboard/Downloads/file I/O is a thin wrapper, smoke-tested at Step 7, not here.)
 */
import { describe, it, expect } from 'vitest';
import { ingestVerdict } from '../../helpers/ingest-verdict';
import { stampFor, type EvidenceItem } from '../../helpers/human-review';

const ITEMS: EvidenceItem[] = [
  { id: 'a', criterion: 'Is A right?', evidence: 'alpha' },
  { id: 'b', criterion: 'Is B right?', evidence: 'beta' },
];
const STAMP = stampFor(ITEMS);

describe('ingestVerdict — fail-closed stamp validation', () => {
  it('ACCEPTS a verdict whose stamp matches the manifest', () => {
    const r = ingestVerdict(ITEMS, JSON.stringify({ stamp: STAMP, results: { a: 'pass' }, citations: { a: 'ok' } }));
    expect(r.ok).toBe(true);
    expect((r.verdict as { results: unknown }).results).toEqual({ a: 'pass' });
  });

  it('REFUSES a verdict stamped for a different capture (mismatch)', () => {
    const r = ingestVerdict(ITEMS, JSON.stringify({ stamp: 'deadbeef', results: {} }));
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/stamp mismatch/);
  });

  it('REFUSES a verdict with no stamp (not produced by the review page)', () => {
    const r = ingestVerdict(ITEMS, JSON.stringify({ results: { a: 'pass' } }));
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/no stamp/);
  });

  it('REFUSES an empty/whitespace stamp (with a stamp-related reason)', () => {
    const r = ingestVerdict(ITEMS, JSON.stringify({ stamp: '   ' }));
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/stamp/);
  });

  it('SANITIZES the accepted verdict — garbage results, non-string citations, and __proto__ are dropped', () => {
    const dirty = JSON.stringify({
      stamp: STAMP,
      reviewer: 'alice',
      results: { a: 'pass', b: 'MAYBE', c: 42 },        // only a valid outcome survives
      citations: { a: 'ok', b: 99 },                     // non-string dropped
      evil: 123,                                         // unknown field dropped
      // eslint-disable-next-line no-proto
      ['__proto__' as string]: { polluted: true },
    });
    const r = ingestVerdict(ITEMS, dirty);
    expect(r.ok).toBe(true);
    const v = r.verdict as Record<string, unknown>;
    expect(v.results).toEqual({ a: 'pass' });
    expect(v.citations).toEqual({ a: 'ok' });
    expect(v).not.toHaveProperty('evil');
    expect(({} as Record<string, unknown>).polluted).toBeUndefined(); // no prototype pollution
  });

  it('REFUSES a non-object / non-JSON body (no crash)', () => {
    for (const bad of ['null', '42', '"x"', '[]', '{ not json']) {
      const r = ingestVerdict(ITEMS, bad);
      expect(r.ok, `body ${bad}`).toBe(false);
    }
  });

  it('the expected stamp tracks the manifest — a changed manifest refuses an old-but-once-valid verdict', () => {
    const oldVerdict = JSON.stringify({ stamp: STAMP, results: { a: 'pass' } });
    const changedItems = [ITEMS[0], { ...ITEMS[1], evidence: 'BETA CHANGED' }];
    const r = ingestVerdict(changedItems, oldVerdict);
    expect(r.ok).toBe(false);
    expect(r.error).toMatch(/stamp mismatch/);
  });
});
