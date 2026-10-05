/**
 * Unit tests for `review:status` (helpers/review-status.ts): the pure report formatter, and a real scan over
 * a temp golden-runs tree covering pending / reviewed / stale / error. Verdicts are filed into a temp
 * REVIEW_RESULTS_ROOT so the real repo tree is never touched.
 */
import { describe, it, expect, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { discoverReviewSlots, slotStatus, formatStatusReport, runStatusCli, type StatusRow } from '../../helpers/review-status';
import { stampFor, reviewResultsDir, formatReviewTimestamp, type EvidenceItem } from '../../helpers/human-review';

const ITEMS: EvidenceItem[] = [
  { id: 'a', criterion: 'A?', evidence: 'alpha' },
  { id: 'b', criterion: 'B?', evidence: 'beta' },
];

describe('formatStatusReport — readable, action lines only where needed', () => {
  const rows: StatusRow[] = [
    { slot: 'done', benchmark: 'bx', state: 'reviewed', reviewed: 2, total: 2, reviewHtml: 'C:\\x\\review.html', ingestArg: 'fixtures/x/review' },
    { slot: 'todo', benchmark: 'by', state: 'pending', reviewed: 0, total: 2, reviewHtml: 'C:\\y\\review.html', ingestArg: 'fixtures/y/review' },
    { slot: 'changed', benchmark: 'bz', state: 'stale', reviewed: 0, total: 2, reviewHtml: 'C:\\z\\review.html', ingestArg: 'fixtures/z/review' },
  ];
  const out = formatStatusReport(rows);

  it('summarises how many need attention (pending + stale, not reviewed)', () => {
    expect(out).toContain('3 slot(s)');
    expect(out).toContain('2 needing attention');
  });
  it('prints open+ingest lines for pending and stale, but NOT for reviewed', () => {
    expect(out).toContain('npm run ingest-verdict fixtures/y/review');
    expect(out).toContain('npm run ingest-verdict fixtures/z/review');
    expect(out).not.toContain('fixtures/x/review'); // the reviewed slot carries no action lines
  });
  it('empty => a clear "none found" message', () => {
    expect(formatStatusReport([])).toMatch(/No review slots/);
  });
});

describe('discoverReviewSlots + slotStatus — real scan over a temp tree', () => {
  const made: string[] = [];
  afterEach(() => {
    delete process.env.REVIEW_RESULTS_ROOT;
    for (const d of made.splice(0)) fs.rmSync(d, { recursive: true, force: true });
  });

  function tempTree() {
    const goldenRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'rs-golden-'));
    const resultsRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'rs-results-'));
    made.push(goldenRoot, resultsRoot);
    const addSlot = (slot: string, benchmark: unknown) => {
      const reviewDir = path.join(goldenRoot, slot, 'review');
      fs.mkdirSync(reviewDir, { recursive: true });
      fs.writeFileSync(path.join(goldenRoot, slot, 'meta.json'), JSON.stringify({ benchmark }));
      fs.writeFileSync(path.join(reviewDir, 'manifest.json'), JSON.stringify({ items: ITEMS }));
      fs.writeFileSync(path.join(reviewDir, 'review.html'), '<!--r-->');
      return reviewDir;
    };
    const fileVerdict = (benchmark: string, verdict: unknown) => {
      const dir = path.join(reviewResultsDir(benchmark), formatReviewTimestamp(new Date()));
      fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(path.join(dir, 'verdict.json'), JSON.stringify(verdict));
    };
    return { goldenRoot, resultsRoot, addSlot, fileVerdict };
  }

  it('discovers only dirs that have review/manifest.json', () => {
    const { goldenRoot, addSlot } = tempTree();
    addSlot('s1', 'b1');
    fs.mkdirSync(path.join(goldenRoot, 'not-a-slot'), { recursive: true }); // no review/manifest.json
    const slots = discoverReviewSlots(goldenRoot);
    expect(slots).toHaveLength(1);
    expect(slots[0]).toContain(path.join('s1', 'review'));
  });

  it('PENDING when no verdict is filed', () => {
    const { resultsRoot, addSlot } = tempTree();
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    const r = slotStatus(addSlot('s1', 'b1'));
    expect(r.state).toBe('pending');
    expect(r.reviewed).toBe(0);
    expect(r.total).toBe(2);
    expect(r.benchmark).toBe('b1');
  });

  it('REVIEWED when a matching verdict is filed (answered counts, Yes-or-No)', () => {
    const { resultsRoot, addSlot, fileVerdict } = tempTree();
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    const reviewDir = addSlot('s1', 'b1');
    fileVerdict('b1', { stamp: stampFor(ITEMS), results: { a: 'pass', b: 'fail' }, citations: { a: 'ok' } });
    const r = slotStatus(reviewDir);
    expect(r.state).toBe('reviewed');
    expect(r.reviewed).toBe(2);
  });

  it('STALE when the filed verdict is for a different capture', () => {
    const { resultsRoot, addSlot, fileVerdict } = tempTree();
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    const reviewDir = addSlot('s1', 'b1');
    fileVerdict('b1', { stamp: 'deadbeef', results: { a: 'pass' } });
    const r = slotStatus(reviewDir);
    expect(r.state).toBe('stale');
  });

  it('PENDING (not reviewed) when a Yes has no citation — must agree with the gate, which fails it', () => {
    const { resultsRoot, addSlot, fileVerdict } = tempTree();
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    const reviewDir = addSlot('s1', 'b1');
    // a = honoured Yes, b = citation-less Yes → b is NOT settled, so the slot stays pending (never "OK").
    fileVerdict('b1', { stamp: stampFor(ITEMS), results: { a: 'pass', b: 'pass' }, citations: { a: 'ok' } });
    const r = slotStatus(reviewDir);
    expect(r.state).toBe('pending');
    expect(r.reviewed).toBe(1); // only the honoured one counts
    expect(r.detail).toMatch(/citation/i);
  });

  it('ERROR for a slot whose meta.json has no benchmark (never throws)', () => {
    const { goldenRoot, addSlot } = tempTree();
    const reviewDir = addSlot('s1', 'b1');
    fs.writeFileSync(path.join(goldenRoot, 's1', 'meta.json'), JSON.stringify({ note: 'x' }));
    const r = slotStatus(reviewDir);
    expect(r.state).toBe('error');
    expect(r.benchmark).toBeNull();
  });

  it('ERROR (never throws) for an unreadable manifest.json — bad JSON or no items[]', () => {
    const { addSlot } = tempTree();
    const bad = addSlot('s1', 'b1');
    fs.writeFileSync(path.join(bad, 'manifest.json'), '{ not json');
    expect(() => slotStatus(bad)).not.toThrow();
    expect(slotStatus(bad).state).toBe('error');

    const noItems = addSlot('s2', 'b2');
    fs.writeFileSync(path.join(noItems, 'manifest.json'), JSON.stringify({ nope: true }));
    expect(slotStatus(noItems).state).toBe('error');
  });

  it('runStatusCli exits 0 for pending-only, 2 when any slot is in error', () => {
    const { goldenRoot, resultsRoot, addSlot } = tempTree();
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    addSlot('ok-pending', 'b1'); // valid slot, no verdict => pending
    expect(runStatusCli([goldenRoot])).toBe(0);

    const broken = addSlot('broken', 'b2');
    fs.writeFileSync(path.join(path.dirname(broken), 'meta.json'), JSON.stringify({ note: 'no benchmark' }));
    expect(runStatusCli([goldenRoot])).toBe(2);
  });
});
