/**
 * Step 1 unit tests — the human-review verdict contract, stamp, and fail-closed reader
 * (`helpers/human-review.ts`). Pure functions over synthetic fixtures; good AND broken case per check
 * (workflow-tests §2 rule 1). The fail-closed and CRLF cases are the load-bearing ones.
 */
import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {
  canonicalizeText,
  stampFor,
  loadVerdict,
  loadLatestVerdict,
  formatReviewTimestamp,
  readSlotBenchmark,
  classifyCheck,
  isSettled,
  repoRelative,
  checkOutcome,
  type EvidenceItem,
} from '../../helpers/human-review';

const EV: EvidenceItem[] = [
  { id: 'a', criterion: 'Is A right?', evidence: 'line one\nline two' },
  { id: 'b', criterion: 'Is B right?', evidence: 'blue #2563eb' },
];

function withReviewDir(fn: (dir: string, write: (v: unknown) => void) => void) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'hr-verdict-'));
  try {
    fn(dir, (v) => fs.writeFileSync(path.join(dir, 'verdict.json'), typeof v === 'string' ? v : JSON.stringify(v)));
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

describe('canonicalizeText — CRLF/LF and trailing-space invariance', () => {
  it('CRLF and LF canonicalize to the same string', () => {
    expect(canonicalizeText('a\r\nb\r\n')).toBe(canonicalizeText('a\nb'));
  });
  it('trailing spaces and trailing blank lines do not matter', () => {
    expect(canonicalizeText('a   \nb\t\n\n\n')).toBe('a\nb');
  });
  it('but the actual content still matters (not everything collapses)', () => {
    expect(canonicalizeText('a\nb')).not.toBe(canonicalizeText('a\nc'));
  });
});

describe('stampFor — deterministic, order-independent, CRLF-stable, content-sensitive', () => {
  it('is stable across evidence item order', () => {
    expect(stampFor(EV)).toBe(stampFor([EV[1], EV[0]]));
  });
  it('is identical for CRLF vs LF evidence (the Windows landmine)', () => {
    const crlf = EV.map((e) => ({ ...e, evidence: e.evidence.replace(/\n/g, '\r\n') }));
    expect(stampFor(crlf)).toBe(stampFor(EV));
  });
  it('CHANGES when any evidence byte changes (so a changed capture gets a new stamp)', () => {
    const changed = [EV[0], { ...EV[1], evidence: 'pink #ec4899' }];
    expect(stampFor(changed)).not.toBe(stampFor(EV));
  });
  it('NO separator-injection collision — a crafted single blob can not masquerade as a two-item set', () => {
    const oneBlob = [{ id: 'a', criterion: 'q', evidence: 'x\n--\n#b\ny' }];
    const twoItems = [{ id: 'a', criterion: 'q', evidence: 'x' }, { id: 'b', criterion: 'q', evidence: 'y' }];
    expect(stampFor(oneBlob)).not.toBe(stampFor(twoItems));
  });
  it('rejects duplicate ids (they would collapse to one verdict key)', () => {
    expect(() => stampFor([{ id: 'a', criterion: 'q', evidence: '1' }, { id: 'a', criterion: 'q', evidence: '2' }]))
      .toThrow(/duplicate evidence id/);
  });
});

describe('loadVerdict — fail-closed', () => {
  const stamp = stampFor(EV);

  it('no file => not present (skip), not stale', () => {
    withReviewDir((dir) => {
      const v = loadVerdict(dir, stamp);
      expect(v.present).toBe(false);
      expect(v.stale).toBe(false);
      expect(v.reason).toMatch(/awaiting review/);
    });
  });

  it('matching stamp => present, not stale, results readable', () => {
    withReviewDir((dir, write) => {
      write({ stamp, results: { a: 'pass' }, citations: { a: 'looks right' } });
      const v = loadVerdict(dir, stamp);
      expect(v.present).toBe(true);
      expect(v.stale).toBe(false);
      expect(v.results.a).toBe('pass');
    });
  });

  it('mismatched stamp => stale (capture changed since review)', () => {
    withReviewDir((dir, write) => {
      write({ stamp: 'deadbeef', results: { a: 'pass' }, citations: { a: 'x' } });
      const v = loadVerdict(dir, stamp);
      expect(v.stale).toBe(true);
      expect(v.results).toEqual({}); // results cleared when stale
    });
  });

  it('FAIL-CLOSED: verdict with NO stamp => stale (not a match), even if currentStamp is empty too', () => {
    withReviewDir((dir, write) => {
      write({ results: { a: 'pass' }, citations: { a: 'x' } }); // no stamp field
      expect(loadVerdict(dir, stamp).stale).toBe(true);
      expect(loadVerdict(dir, '').stale).toBe(true); // empty===empty must NOT pass
    });
  });

  it('FAIL-CLOSED: empty currentStamp => stale even against a stamped verdict', () => {
    withReviewDir((dir, write) => {
      write({ stamp, results: { a: 'pass' }, citations: { a: 'x' } });
      expect(loadVerdict(dir, '   ').stale).toBe(true);
    });
  });

  it('unparseable verdict => stale (not silently treated as present/pass)', () => {
    withReviewDir((dir, write) => {
      write('{ not json');
      const v = loadVerdict(dir, stamp);
      expect(v.stale).toBe(true);
      expect(v.results).toEqual({});
    });
  });

  it('a non-object body (null / scalar / array) => stale, no crash', () => {
    for (const body of ['null', '42', '"x"', '[]']) {
      withReviewDir((dir, write) => {
        write(body);
        const v = loadVerdict(dir, stamp);
        expect(v.stale, `body ${body}`).toBe(true);
        expect(v.results).toEqual({});
      });
    }
  });
});

describe('formatReviewTimestamp — the Tier-3 yyyyMMdd-HHmmss convention', () => {
  it('zero-pads month/day/hour/minute/second', () => {
    expect(formatReviewTimestamp(new Date(2026, 0, 5, 9, 3, 7))).toBe('20260105-090307');
  });
  it('a late-year double-digit date', () => {
    expect(formatReviewTimestamp(new Date(2026, 11, 25, 14, 30, 45))).toBe('20261225-143045');
  });
  it('fixed-width always (padded year + seconds) — every output is exactly 15 chars', () => {
    expect(formatReviewTimestamp(new Date(2026, 0, 1, 0, 0, 0))).toHaveLength(15);
    expect(formatReviewTimestamp(new Date(2026, 0, 1, 0, 0, 0))).toMatch(/^\d{8}-\d{6}$/);
  });
  it('sorts lexicographically == chronologically (so newest-dir-first is newest-run-first)', () => {
    const a = formatReviewTimestamp(new Date(2026, 9, 5, 13, 23, 10));
    const b = formatReviewTimestamp(new Date(2026, 9, 5, 13, 23, 55)); // 45s later, same minute
    expect(a < b).toBe(true); // seconds keep same-minute runs distinct AND ordered
  });
});

describe('loadLatestVerdict — newest matching dated verdict wins, fail-closed', () => {
  const stamp = stampFor(EV);
  // Make a benchmark dir with dated run subfolders, each optionally holding a verdict.json.
  function withBenchmarkDir(fn: (dir: string, put: (ts: string, v: unknown) => void) => void) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'hr-latest-'));
    const put = (ts: string, v: unknown) => {
      const d = path.join(dir, ts);
      fs.mkdirSync(d, { recursive: true });
      fs.writeFileSync(path.join(d, 'verdict.json'), typeof v === 'string' ? v : JSON.stringify(v));
    };
    try { fn(dir, put); } finally { fs.rmSync(dir, { recursive: true, force: true }); }
  }

  it('no benchmark dir => not present (skip), not stale', () => {
    const v = loadLatestVerdict(path.join(os.tmpdir(), 'hr-does-not-exist-xyz'), stamp);
    expect(v.present).toBe(false);
    expect(v.stale).toBe(false);
    expect(v.from).toBeNull();
  });

  it('dir with no verdict files => not present (skip)', () => {
    withBenchmarkDir((dir) => {
      fs.mkdirSync(path.join(dir, '20260101-000000'), { recursive: true }); // empty dated folder
      const v = loadLatestVerdict(dir, stamp);
      expect(v.present).toBe(false);
      expect(v.stale).toBe(false);
    });
  });

  it('a matching verdict => present, readable, with its source dir', () => {
    withBenchmarkDir((dir, put) => {
      put('20260101-090000', { stamp, results: { a: 'pass' }, citations: { a: 'ok' } });
      const v = loadLatestVerdict(dir, stamp);
      expect(v.present).toBe(true);
      expect(v.stale).toBe(false);
      expect(v.results.a).toBe('pass');
      expect(v.from).toBe(path.join(dir, '20260101-090000'));
    });
  });

  it('the NEWEST matching verdict wins (a re-review supersedes an earlier one)', () => {
    withBenchmarkDir((dir, put) => {
      put('20260101-090000', { stamp, results: { a: 'fail' }, citations: {} });
      put('20260202-103000', { stamp, results: { a: 'pass' }, citations: { a: 'now correct' } });
      const v = loadLatestVerdict(dir, stamp);
      expect(v.results.a).toBe('pass');
      expect(v.from).toBe(path.join(dir, '20260202-103000'));
    });
  });

  it('an older verdict of IDENTICAL evidence (same stamp) is still honoured when the newest is stale', () => {
    withBenchmarkDir((dir, put) => {
      put('20260101-090000', { stamp, results: { a: 'pass' }, citations: { a: 'ok' } }); // matches current
      put('20260202-103000', { stamp: 'deadbeef', results: { a: 'pass' }, citations: { a: 'x' } }); // different capture
      const v = loadLatestVerdict(dir, stamp);
      expect(v.present).toBe(true);
      expect(v.stale).toBe(false);
      expect(v.from).toBe(path.join(dir, '20260101-090000'));
    });
  });

  it('FAIL-CLOSED: verdicts exist but NONE match the current stamp => stale (re-review), never a vacuous pass', () => {
    withBenchmarkDir((dir, put) => {
      put('20260101-090000', { stamp: 'deadbeef', results: { a: 'pass' }, citations: { a: 'x' } });
      const v = loadLatestVerdict(dir, stamp);
      expect(v.present).toBe(true);
      expect(v.stale).toBe(true);
      expect(v.results).toEqual({});
      expect(v.from).toBeNull();
    });
  });

  it('FAIL-CLOSED: a NON-timestamp folder (latest/, UPPERCASE) can NOT beat the newest real timestamp', () => {
    withBenchmarkDir((dir, put) => {
      // The real, newest re-review says No.
      put('20260202-103000', { stamp, results: { a: 'fail' }, citations: {} });
      // Junk folders holding a stale "Yes" — their names sort ABOVE digits lexicographically. Must be ignored.
      put('latest', { stamp, results: { a: 'pass' }, citations: { a: 'resurrected' } });
      put('ZZZ-backup', { stamp, results: { a: 'pass' }, citations: { a: 'resurrected' } });
      fs.mkdirSync(path.join(dir, '.git'), { recursive: true });
      const v = loadLatestVerdict(dir, stamp);
      expect(v.results.a).toBe('fail'); // the real newest timestamp wins — the junk "Yes" did NOT resurrect
      expect(v.from).toBe(path.join(dir, '20260202-103000'));
    });
  });
});

describe('readSlotBenchmark — one trimmed, path-safe benchmark for writer and reader', () => {
  function withSlot(metaBenchmark: unknown): string {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'hr-slot-'));
    const reviewDir = path.join(root, 'review');
    fs.mkdirSync(reviewDir, { recursive: true });
    fs.writeFileSync(path.join(root, 'meta.json'), JSON.stringify({ benchmark: metaBenchmark }));
    return reviewDir;
  }

  it('returns the trimmed benchmark (writer and reader can never disagree on whitespace)', () => {
    expect(readSlotBenchmark(withSlot('  contact-form  '))).toBe('contact-form');
  });
  it('throws when there is no usable benchmark', () => {
    expect(() => readSlotBenchmark(withSlot(''))).toThrow(/benchmark/);
    expect(() => readSlotBenchmark(withSlot(42))).toThrow(/benchmark/);
  });
  it('rejects path separators and traversal (no escaping TestResults/review)', () => {
    expect(() => readSlotBenchmark(withSlot('a/b'))).toThrow(/path separators|\.\./);
    expect(() => readSlotBenchmark(withSlot('..'))).toThrow(/path separators|\.\./);
    expect(() => readSlotBenchmark(withSlot('a\\b'))).toThrow(/path separators|\.\./);
  });
});

describe('classifyCheck / isSettled — the single honouring source of truth', () => {
  const v = (results: Record<string, 'pass' | 'fail'>, citations: Record<string, string> = {}) => ({ results, citations });

  it('a Yes WITH a citation => honoured + settled', () => {
    const d = v({ a: 'pass' }, { a: 'because X' });
    expect(classifyCheck(d, 'a')).toBe('honoured');
    expect(isSettled(d, 'a')).toBe(true);
  });
  it('a reviewer No => rejected + settled (a completed decision, even though it reds)', () => {
    const d = v({ a: 'fail' });
    expect(classifyCheck(d, 'a')).toBe('rejected');
    expect(isSettled(d, 'a')).toBe(true);
  });
  it('a Yes WITHOUT a (usable) citation => uncited + NOT settled', () => {
    expect(classifyCheck(v({ a: 'pass' }, {}), 'a')).toBe('uncited');
    expect(classifyCheck(v({ a: 'pass' }, { a: '   ' }), 'a')).toBe('uncited');
    expect(isSettled(v({ a: 'pass' }, {}), 'a')).toBe(false);
  });
  it('no answer => unreviewed + NOT settled', () => {
    expect(classifyCheck(v({}), 'a')).toBe('unreviewed');
    expect(isSettled(v({}), 'a')).toBe(false);
  });
  it('agrees with checkOutcome: settled-or-not lines up with honoured-pass vs everything-else', () => {
    // honoured => checkOutcome pass; uncited/rejected => fail; unreviewed => skip. isSettled = honoured||rejected.
    expect(checkOutcome({ present: true, stale: false, reason: '', results: { a: 'pass' }, citations: { a: 'c' } }, 'a').outcome).toBe('pass');
    expect(checkOutcome({ present: true, stale: false, reason: '', results: { a: 'pass' }, citations: {} }, 'a').outcome).toBe('fail'); // uncited
  });
});

describe('repoRelative — the ingest-command path shape', () => {
  it('an in-repo path relativizes to forward-slash, no leading .. (the documented ingest arg)', () => {
    const abs = path.resolve(__dirname, '..', '..', 'fixtures', 'golden-runs', 'intake-contact-form', 'review');
    expect(repoRelative(abs)).toBe('fixtures/golden-runs/intake-contact-form/review');
  });
  it('a path outside the repo falls back to the absolute path (never a broken ..)', () => {
    const outside = path.resolve(os.tmpdir(), 'somewhere-else', 'review');
    const out = repoRelative(outside);
    expect(out).toBe(outside);
    expect(out.startsWith('..')).toBe(false);
  });
});

describe('checkOutcome — a Yes needs an evidence citation', () => {
  const base = { present: true, stale: false, reason: '', citations: {} as Record<string, string>, results: {} as Record<string, 'pass' | 'fail' | 'skip'> };

  it('pass WITH a citation => pass', () => {
    const v = { ...base, results: { a: 'pass' as const }, citations: { a: 'blue kept, no pink' } };
    expect(checkOutcome(v, 'a').outcome).toBe('pass');
  });
  it('pass WITHOUT a citation => downgraded to fail (bare Yes not honoured)', () => {
    const v = { ...base, results: { a: 'pass' as const }, citations: {} };
    const o = checkOutcome(v, 'a');
    expect(o.outcome).toBe('fail');
    expect(o.reason).toMatch(/without an evidence citation/);
  });
  it('pass with a whitespace-only citation => fail', () => {
    const v = { ...base, results: { a: 'pass' as const }, citations: { a: '   ' } };
    expect(checkOutcome(v, 'a').outcome).toBe('fail');
  });
  it('explicit fail => fail', () => {
    const v = { ...base, results: { a: 'fail' as const }, citations: {} };
    expect(checkOutcome(v, 'a').outcome).toBe('fail');
  });
  it('unreviewed id => skip', () => {
    expect(checkOutcome(base, 'missing').outcome).toBe('skip');
  });
  it('pass with a NON-STRING citation => fail, no crash', () => {
    for (const bad of [42, { x: 1 }, true, ['x']] as unknown[]) {
      const v = { ...base, results: { a: 'pass' as const }, citations: { a: bad as unknown as string } };
      expect(checkOutcome(v, 'a').outcome).toBe('fail');
    }
  });
});
