/**
 * Step 1 unit tests — the human-review verdict contract, stamp, and fail-closed reader
 * (`helpers/human-review.ts`). Pure functions over synthetic fixtures; good AND broken case per check
 * (workflow-tests §2 rule 1). The fail-closed and CRLF cases are the load-bearing ones.
 */
import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { canonicalizeText, stampFor, loadVerdict, checkOutcome, type EvidenceItem } from '../../helpers/human-review';

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
