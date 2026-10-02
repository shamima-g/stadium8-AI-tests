/**
 * Human-review harness — Step 1: the verdict contract, the capture stamp, and a FAIL-CLOSED reader.
 *
 * Subjective checks (the ones no lookup can settle) are judged by a person in a browser; the verdict is
 * saved to `verdict.json` and read here deterministically — NO AI at test time. See
 * test-plans/human-review-harness-plan.md. This module is the data layer every other piece reads:
 *   - `stampFor(evidence)` ties a verdict to the EXACT evidence shown (a normalized content hash, so a
 *     changed capture can't reuse an old Yes). Normalized → identical on Windows (CRLF) and POSIX (LF).
 *   - `loadVerdict(dir, currentStamp)` is FAIL-CLOSED: no file → not-present (skip); a present file whose
 *     stamp is missing/empty/mismatched → stale (skip, re-review) — never `undefined === undefined` → pass.
 *   - `checkOutcome(v, id)` honours a 'pass' ONLY when it carries a non-empty evidence citation (a bare Yes
 *     is not trusted; determinism ≠ authenticity).
 */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export type Outcome = 'pass' | 'fail' | 'skip';

export interface EvidenceItem {
  /** stable check id (e.g. 'intake-facts-correct') */
  id: string;
  /** the question the reviewer answers */
  criterion: string;
  /** what "pass" looks like (optional guidance) */
  guidance?: string;
  /** the exact evidence shown to the reviewer (pre-rendered text/HTML) — what the stamp covers */
  evidence: string;
}

/** LF line endings, trailing whitespace trimmed per line, no trailing blank lines — so CRLF vs LF, or an
 *  editor adding a final newline, never changes the stamp. */
export function canonicalizeText(s: string): string {
  return s
    .replace(/\r\n?/g, '\n')
    .split('\n')
    .map((l) => l.replace(/[ \t]+$/, ''))
    .join('\n')
    .replace(/\n+$/, '');
}

/**
 * The capture stamp: sha256 over the canonicalized evidence in stable id order. Computed identically at
 * build time (baked into review.html) and at read time (here), so build and test agree cross-platform.
 *
 * Encoding is **JSON over `[{id, canon}]`** (not an in-band `#id … --` join): JSON escapes newlines and
 * quotes, so item boundaries are unambiguous — a crafted evidence blob containing a separator can NOT
 * masquerade as a different multi-item set (the injection collision a join would allow). Duplicate ids are
 * rejected (they'd collapse to one verdict key). Known limitation: `canonicalizeText` trims trailing
 * whitespace, so trailing-space-significant evidence (inside code/`<pre>`) is not byte-bound — fine for the
 * prose/messages these checks review; hash raw if a future check needs whitespace-exact binding.
 */
export function stampFor(items: EvidenceItem[]): string {
  const ids = items.map((i) => i.id);
  const dupes = [...new Set(ids.filter((id, i) => ids.indexOf(id) !== i))];
  if (dupes.length) throw new Error(`stampFor: duplicate evidence id(s): ${dupes.join(', ')}`);
  const norm = [...items]
    .sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
    .map((it) => ({ id: it.id, evidence: canonicalizeText(it.evidence) }));
  return crypto.createHash('sha256').update(JSON.stringify(norm), 'utf8').digest('hex');
}

export interface VerdictFile {
  stamp?: string;
  reviewer?: string;
  reviewedAt?: string;
  results?: Record<string, Outcome>;
  citations?: Record<string, string>;
}

export interface LoadedVerdict {
  /** a verdict file exists AND its stamp matches the current capture (safe to read results) */
  present: boolean;
  /** a file exists but its stamp is missing/empty/mismatched (or unparseable) — needs (re)review */
  stale: boolean;
  /** human-readable reason for present/stale state */
  reason: string;
  results: Record<string, Outcome>;
  citations: Record<string, string>;
}

/**
 * Fail-closed verdict loader. `currentStamp` = `stampFor(the capture's current evidence)`.
 * A missing/empty stamp on EITHER side is treated as stale (never a match), so an unstamped or hand-made
 * verdict can't silently pass a capture.
 */
export function loadVerdict(slotReviewDir: string, currentStamp: string): LoadedVerdict {
  const p = path.join(slotReviewDir, 'verdict.json');
  if (!fs.existsSync(p)) {
    return { present: false, stale: false, reason: `no verdict at ${p} — awaiting review`, results: {}, citations: {} };
  }
  let v: VerdictFile;
  try {
    const parsed = JSON.parse(fs.readFileSync(p, 'utf8'));
    // A non-object body (null / scalar / array) is not a verdict — stale, don't crash on `v.stamp`.
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      return { present: true, stale: true, reason: 'verdict.json is not an object', results: {}, citations: {} };
    }
    v = parsed as VerdictFile;
  } catch (e) {
    return { present: true, stale: true, reason: `verdict.json is unparseable: ${(e as Error).message}`, results: {}, citations: {} };
  }
  const vs = typeof v.stamp === 'string' ? v.stamp.trim() : '';
  const cs = typeof currentStamp === 'string' ? currentStamp.trim() : '';
  if (!vs || !cs || vs !== cs) {
    const reason = !vs ? 'verdict has no stamp' : !cs ? 'no current stamp supplied' : 'stamp mismatch — the capture changed since review';
    return { present: true, stale: true, reason, results: {}, citations: {} };
  }
  return { present: true, stale: false, reason: '', results: v.results ?? {}, citations: v.citations ?? {} };
}

/**
 * The per-check outcome a test asserts on. A 'pass' is honoured ONLY with a non-empty evidence citation —
 * a bare Yes (or a hand-edited verdict with no citation) is downgraded to 'fail'. A stale/absent verdict
 * yields 'skip' for every id (its results are already cleared by loadVerdict).
 */
export function checkOutcome(v: LoadedVerdict, id: string): { outcome: Outcome; reason: string } {
  const r = v.results[id];
  if (r === 'pass') {
    const raw = v.citations[id];
    const cite = typeof raw === 'string' ? raw.trim() : ''; // non-string citation => treated as none (no crash)
    if (!cite) return { outcome: 'fail', reason: `#${id}: 'pass' without an evidence citation — not honoured` };
    return { outcome: 'pass', reason: '' };
  }
  if (r === 'fail') return { outcome: 'fail', reason: `#${id}: reviewer said No` };
  return { outcome: 'skip', reason: `#${id}: not reviewed` };
}
