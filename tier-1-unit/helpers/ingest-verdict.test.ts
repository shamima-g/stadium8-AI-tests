/**
 * Step 3 unit tests — the pure `ingestVerdict` stamp-validation (`helpers/ingest-verdict.ts`). Fail-closed:
 * only a verdict whose stamp matches the capture's manifest is accepted. Good AND broken case per check.
 * (The clipboard/Downloads/file I/O is a thin wrapper, smoke-tested at Step 7, not here.)
 */
import { describe, it, expect, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { ingestVerdict, runCli, buildProofMd, type CleanVerdict } from '../../helpers/ingest-verdict';
import { stampFor, loadLatestVerdict, reviewResultsDir, fileUrl, type EvidenceItem } from '../../helpers/human-review';

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

describe('buildProofMd — human-readable, with Yes/No, citations, and file:// links', () => {
  const verdict: CleanVerdict = {
    stamp: STAMP,
    reviewer: 'alice',
    reviewedAt: '2026-10-05T10:00:00Z',
    results: { a: 'pass', b: 'fail' },
    citations: { a: 'alpha matches the source' },
  };
  const md = buildProofMd({
    benchmark: 'contact-form',
    slot: 'intake-contact-form',
    items: ITEMS,
    verdict,
    reviewHtmlPath: path.join('C:', 'x', 'review.html'),
    verdictJsonPath: path.join('C:', 'y', 'verdict.json'),
  });

  it('records the benchmark, slot, reviewer, and coverage', () => {
    expect(md).toContain('contact-form');
    expect(md).toContain('intake-contact-form');
    expect(md).toContain('alice');
    expect(md).toContain('2/2 settled'); // honoured Yes + recorded No both count
  });
  it('renders a Yes with its citation and a No', () => {
    expect(md).toMatch(/Is A right\?.*Yes.*alpha matches the source/);
    expect(md).toMatch(/Is B right\?.*No/);
  });
  it('a pass with no citation is flagged as NOT honoured (determinism != authenticity)', () => {
    const noCite = buildProofMd({
      benchmark: 'b', slot: 's', items: ITEMS,
      verdict: { ...verdict, results: { a: 'pass' }, citations: {} },
      reviewHtmlPath: 'r.html', verdictJsonPath: 'v.json',
    });
    expect(noCite).toMatch(/NOT honoured/);
  });
  it('links to both the review page and the verdict as file:// URLs', () => {
    expect(md).toContain(fileUrl(path.join('C:', 'x', 'review.html')));
    expect(md).toContain(fileUrl(path.join('C:', 'y', 'verdict.json')));
    expect(fileUrl('C:\\a\\b.html')).toBe('file:///C:/a/b.html');
  });
});

describe('runCli — files the verdict + PROOF.md under TestResults/review/<benchmark>/<ts>/', () => {
  const made: string[] = [];
  afterEach(() => {
    delete process.env.REVIEW_RESULTS_ROOT;
    for (const d of made.splice(0)) fs.rmSync(d, { recursive: true, force: true });
  });

  // A temp slot: <tmp>/<slot>/meta.json + review/{manifest.json, review.html}
  function makeSlot(benchmark: string) {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ingest-cli-'));
    made.push(root);
    const slotDir = path.join(root, 'intake-contact-form');
    const reviewDir = path.join(slotDir, 'review');
    fs.mkdirSync(reviewDir, { recursive: true });
    fs.writeFileSync(path.join(slotDir, 'meta.json'), JSON.stringify({ benchmark }));
    fs.writeFileSync(path.join(reviewDir, 'manifest.json'), JSON.stringify({ items: ITEMS }));
    fs.writeFileSync(path.join(reviewDir, 'review.html'), '<!-- review -->');
    const resultsRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'ingest-results-'));
    made.push(resultsRoot);
    return { reviewDir, resultsRoot };
  }

  it('files under the benchmark NAMED IN meta.json (not a constant), then loadLatestVerdict reads it back green', () => {
    // A distinctive benchmark so this pins "reads meta.json" — a hardcoded constant would file elsewhere and fail.
    const BENCH = 'zeta-benchmark-xyz';
    const { reviewDir, resultsRoot } = makeSlot(BENCH);
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    const verdict = JSON.stringify({ stamp: STAMP, reviewer: 'bob', results: { a: 'pass', b: 'pass' }, citations: { a: 'ok', b: 'ok' } });

    const code = runCli([reviewDir, '--text', verdict]);
    expect(code).toBe(0);

    // The verdict did NOT land in the inputs dir...
    expect(fs.existsSync(path.join(reviewDir, 'verdict.json'))).toBe(false);
    // ...it landed under TestResults/review/<the meta.json benchmark>/<ts>/, and NOWHERE else.
    expect(fs.readdirSync(resultsRoot)).toEqual([BENCH]); // proves it read the benchmark, didn't hardcode one
    const benchDir = path.join(resultsRoot, BENCH);
    const dated = fs.readdirSync(benchDir);
    expect(dated).toHaveLength(1);
    expect(dated[0]).toMatch(/^\d{8}-\d{6}$/); // yyyyMMdd-HHmmss
    const runDir = path.join(benchDir, dated[0]);
    expect(fs.existsSync(path.join(runDir, 'verdict.json'))).toBe(true);
    expect(fs.existsSync(path.join(runDir, 'PROOF.md'))).toBe(true);

    // And the suite loader reads it back as the active verdict.
    const v = loadLatestVerdict(reviewResultsDir(BENCH), STAMP);
    expect(v.present).toBe(true);
    expect(v.stale).toBe(false);
    expect(v.results).toEqual({ a: 'pass', b: 'pass' });
  });

  it('REFUSES a stamp-mismatched verdict and writes NOTHING', () => {
    const { reviewDir, resultsRoot } = makeSlot('contact-form');
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    const code = runCli([reviewDir, '--text', JSON.stringify({ stamp: 'deadbeef', results: { a: 'pass' } })]);
    expect(code).toBe(1);
    expect(fs.existsSync(path.join(resultsRoot, 'contact-form'))).toBe(false);
  });

  it('errors clearly when the slot meta.json has no benchmark (nothing filed)', () => {
    const { reviewDir, resultsRoot } = makeSlot('contact-form');
    fs.writeFileSync(path.join(path.dirname(reviewDir), 'meta.json'), JSON.stringify({ note: 'no benchmark' }));
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    const code = runCli([reviewDir, '--text', JSON.stringify({ stamp: STAMP, results: { a: 'pass' }, citations: { a: 'ok' } })]);
    expect(code).toBe(1);
    expect(fs.existsSync(path.join(resultsRoot, 'contact-form'))).toBe(false);
  });

  it('REFUSES a benchmark with a path separator (no escaping TestResults/review), writes nothing', () => {
    const { reviewDir, resultsRoot } = makeSlot('../escape');
    process.env.REVIEW_RESULTS_ROOT = resultsRoot;
    const code = runCli([reviewDir, '--text', JSON.stringify({ stamp: STAMP, results: { a: 'pass' }, citations: { a: 'ok' } })]);
    expect(code).toBe(1);
    expect(fs.readdirSync(resultsRoot)).toEqual([]); // nothing created
  });
});
