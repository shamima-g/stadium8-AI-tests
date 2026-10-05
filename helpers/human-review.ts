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

export type CheckStatus = 'honoured' | 'rejected' | 'uncited' | 'unreviewed';

/**
 * Classify one check against a verdict using the SAME honouring rule as `checkOutcome` — the single source of
 * truth for "is this a completed, trustworthy human decision?". Every "are we done?" surface (coverage line,
 * the in-run notice, `review:status`, the PROOF.md count) MUST derive from this, so none of them can disagree
 * with the gate:
 *   - `honoured`   — a Yes WITH an evidence citation (green at test time).
 *   - `rejected`   — a reviewer No (a real recorded decision; red, but the review IS complete).
 *   - `uncited`    — a Yes with no (usable) citation. The gate fails it ("not honoured"), so it must NOT read
 *                    as done anywhere — the reviewer has to go back and cite.
 *   - `unreviewed` — no answer yet.
 */
export function classifyCheck(v: Pick<LoadedVerdict, 'results' | 'citations'>, id: string): CheckStatus {
  const r = v.results[id];
  if (r === 'fail') return 'rejected';
  if (r === 'pass') {
    const raw = v.citations[id];
    return typeof raw === 'string' && raw.trim() ? 'honoured' : 'uncited';
  }
  return 'unreviewed';
}

/** A completed human decision: an honoured Yes or a recorded No. A citation-less Yes / no answer is NOT settled. */
export function isSettled(v: Pick<LoadedVerdict, 'results' | 'citations'>, id: string): boolean {
  const s = classifyCheck(v, id);
  return s === 'honoured' || s === 'rejected';
}

// ── Where a RECORDED verdict lives (separate from the committed review INPUTS) ───────────────────────
//
// The fixtures slot keeps the review inputs (review.html + manifest.json). The recorded human decision is
// an OUTPUT, filed under the same TestResults root + timestamp convention as Tier-3:
//   <repo>/TestResults/review/<benchmark>/<yyyyMMdd-HHmmss>/{verdict.json, PROOF.md}
// So each review makes a new dated folder (a history), and the test reads the newest verdict whose stamp
// still matches the current capture. `__dirname` is helpers/, so `..` is the AI-tests repo root — the same
// root Run-QATests.ps1 uses (`$PSScriptRoot/../TestResults`). REVIEW_RESULTS_ROOT overrides it (for tests).

/** The dated run-folder shape, shared by the writer (ingest) and the reader (loadLatestVerdict). */
export const REVIEW_TS_RE = /^\d{8}-\d{6}$/; // yyyyMMdd-HHmmss

/** Root of the review results tree: `<repo>/TestResults/review` (or $REVIEW_RESULTS_ROOT). */
export function reviewResultsRoot(): string {
  const override = process.env.REVIEW_RESULTS_ROOT;
  return override && override.trim()
    ? path.resolve(override)
    : path.resolve(__dirname, '..', 'TestResults', 'review');
}

/** The per-benchmark review results dir: `<root>/<benchmark>`. */
export function reviewResultsDir(benchmark: string): string {
  return path.join(reviewResultsRoot(), benchmark);
}

/** Tier-3 run-folder stamp: fixed-width local-time `yyyyMMdd-HHmmss` (matches Run-QATests.ps1's pattern,
 *  with seconds so two reviews in the same minute don't collide). Every field is zero-padded, including the
 *  year, so lexicographic order == chronological order — the invariant `loadLatestVerdict`'s sort relies on. */
export function formatReviewTimestamp(d: Date): string {
  const p = (n: number, w = 2) => String(n).padStart(w, '0');
  return `${p(d.getFullYear(), 4)}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

/**
 * Resolve + normalize the benchmark a slot's verdicts are filed under, read from the slot's `meta.json` (one
 * dir up from its review/). Trimmed, and rejected if it holds path separators or `..` — so the writer
 * (ingest) and the reader (the suite) always agree on one safe folder name. This is the SINGLE source of
 * the benchmark for both sides. Throws (fail-closed) when meta.json is missing or has no usable benchmark.
 */
export function readSlotBenchmark(slotReviewDir: string): string {
  const metaPath = path.join(path.dirname(slotReviewDir), 'meta.json');
  const meta = JSON.parse(fs.readFileSync(metaPath, 'utf8')) as { benchmark?: unknown };
  const raw = typeof meta.benchmark === 'string' ? meta.benchmark.trim() : '';
  if (!raw) {
    throw new Error(`${metaPath} has no string "benchmark" — needed to file the verdict under TestResults/review/<benchmark>/`);
  }
  if (/[\\/]|\.\./.test(raw)) {
    throw new Error(`${metaPath} "benchmark" must not contain path separators or "..": ${JSON.stringify(raw)}`);
  }
  return raw;
}

/** An absolute path as a clickable `file:///` URL (forward slashes) — opens straight from a terminal/editor. */
export function fileUrl(absPath: string): string {
  return 'file:///' + absPath.replace(/\\/g, '/').replace(/^\//, '');
}

/** `absPath` relative to the AI-tests repo root (forward slashes), e.g. `fixtures/golden-runs/<slot>/review`
 *  — the shape the `ingest-verdict` command documents. Falls back to the absolute path if it's outside the
 *  repo (e.g. a different drive), so the printed command is always runnable. */
export function repoRelative(absPath: string): string {
  const rel = path.relative(path.resolve(__dirname, '..'), absPath);
  return rel && !rel.startsWith('..') && !path.isAbsolute(rel) ? rel.replace(/\\/g, '/') : absPath;
}

export interface LoadedLatestVerdict extends LoadedVerdict {
  /** the dated run dir the active verdict came from (null when none is active). */
  from: string | null;
}

/**
 * Load the ACTIVE verdict for a benchmark from its dated review folders. Among every
 * `TestResults/review/<benchmark>/<ts>/verdict.json` whose stamp matches `currentStamp`, the NEWEST (folder
 * name is `yyyyMMdd-HHmm`, so lexicographic order == chronological) wins — a re-review supersedes, while an
 * older review of byte-identical evidence (same stamp) is still honoured. Fail-closed, exactly like
 * `loadVerdict`: a benchmark dir holding verdicts but none matching the current stamp reports **stale**
 * (re-review); no dir / no verdict files reports **not-present** (skip). Never a vacuous pass.
 */
export function loadLatestVerdict(benchmarkDir: string, currentStamp: string): LoadedLatestVerdict {
  const notPresent = (reason: string): LoadedLatestVerdict =>
    ({ present: false, stale: false, reason, results: {}, citations: {}, from: null });
  if (!fs.existsSync(benchmarkDir)) return notPresent(`no reviews under ${benchmarkDir} — awaiting review`);

  let dirs: string[];
  try {
    dirs = fs
      .readdirSync(benchmarkDir, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name)
      // Only genuine yyyyMMdd-HHmmss run folders. A stray/junk/uppercase name (e.g. "latest", a backup) must
      // NOT be considered — letters sort ABOVE digits, so an unfiltered junk folder could masquerade as the
      // newest and resurrect a superseded verdict (a vacuous green). Filtering keeps the sort honest.
      .filter((n) => REVIEW_TS_RE.test(n))
      .sort((a, b) => (a < b ? 1 : a > b ? -1 : 0)); // newest (highest timestamp) first
  } catch {
    return notPresent(`cannot read ${benchmarkDir} — awaiting review`);
  }

  let sawVerdict = false;
  let newestStaleReason = '';
  for (const name of dirs) {
    const dir = path.join(benchmarkDir, name);
    if (!fs.existsSync(path.join(dir, 'verdict.json'))) continue;
    sawVerdict = true;
    const v = loadVerdict(dir, currentStamp); // reuse the same fail-closed reader (reads <dir>/verdict.json)
    if (v.present && !v.stale) return { ...v, from: dir };
    if (!newestStaleReason) newestStaleReason = v.reason; // the newest file's reason (dirs are newest-first)
  }
  if (sawVerdict) {
    return {
      present: true,
      stale: true,
      reason: newestStaleReason || 'no recorded verdict matches the current capture — re-review',
      results: {},
      citations: {},
      from: null,
    };
  }
  return notPresent(`no verdict.json under ${benchmarkDir} — awaiting review`);
}
