/**
 * `review:status` — a one-look answer to "is any human review waiting for me?" without running the whole
 * suite. It scans the review slots under fixtures/golden-runs/ * /review/ and, for each, reports whether its
 * recorded verdict is present (reviewed), absent (pending), or stale (the capture changed since review) —
 * naming the review.html to open and the exact `ingest-verdict` command for anything that still needs a
 * person. Read-only: it files nothing and never fails the process (the gate is REQUIRE_REVIEW in the suite).
 */
import fs from 'node:fs';
import path from 'node:path';
import {
  stampFor,
  loadLatestVerdict,
  reviewResultsDir,
  readSlotBenchmark,
  classifyCheck,
  fileUrl,
  repoRelative,
  type EvidenceItem,
} from './human-review';

export type ReviewState = 'reviewed' | 'pending' | 'stale' | 'error';

export interface StatusRow {
  slot: string;
  benchmark: string | null;
  state: ReviewState;
  reviewed: number;
  total: number;
  reviewHtml: string;
  ingestArg: string;
  detail?: string;
}

/** The default review-slots root: `<repo>/fixtures/golden-runs` (helpers/.. is the repo root). */
export function defaultSlotsRoot(): string {
  return path.resolve(__dirname, '..', 'fixtures', 'golden-runs');
}

/** The review INPUT dirs under a golden-runs root — any `<root>/<slot>/review/` holding a manifest.json. */
export function discoverReviewSlots(goldenRunsRoot: string): string[] {
  let names: string[];
  try {
    names = fs
      .readdirSync(goldenRunsRoot, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name)
      .sort();
  } catch {
    return [];
  }
  const slots: string[] = [];
  for (const name of names) {
    const reviewDir = path.join(goldenRunsRoot, name, 'review');
    if (fs.existsSync(path.join(reviewDir, 'manifest.json'))) slots.push(reviewDir);
  }
  return slots;
}

/** The review state of one slot (reads its manifest + the newest matching verdict). Never throws. */
export function slotStatus(reviewDir: string): StatusRow {
  const slot = path.basename(path.dirname(reviewDir));
  const base = { slot, reviewHtml: path.join(reviewDir, 'review.html'), ingestArg: repoRelative(reviewDir) };

  let items: EvidenceItem[];
  try {
    const m = JSON.parse(fs.readFileSync(path.join(reviewDir, 'manifest.json'), 'utf8')) as { items?: EvidenceItem[] };
    if (!Array.isArray(m.items)) throw new Error('manifest has no items[]');
    items = m.items;
  } catch (e) {
    return { ...base, benchmark: null, state: 'error', reviewed: 0, total: 0, detail: `manifest unreadable: ${(e as Error).message}` };
  }

  let benchmark: string;
  try {
    benchmark = readSlotBenchmark(reviewDir);
  } catch (e) {
    return { ...base, benchmark: null, state: 'error', reviewed: 0, total: items.length, detail: (e as Error).message };
  }

  const v = loadLatestVerdict(reviewResultsDir(benchmark), stampFor(items));
  const total = items.length;
  if (v.stale) return { ...base, benchmark, state: 'stale', reviewed: 0, total, detail: v.reason };
  // "reviewed" must mean SETTLED (an honoured Yes or a recorded No) — the SAME rule the gate uses. A
  // citation-less Yes is NOT settled (the gate fails it), so it keeps the slot PENDING rather than showing a
  // misleading "OK / reviewed". `classifyCheck` is the shared source of truth with reviewCoverage + PROOF.md.
  const classes = items.map((it) => classifyCheck(v, it.id));
  const reviewed = classes.filter((c) => c === 'honoured' || c === 'rejected').length;
  const uncited = classes.filter((c) => c === 'uncited').length;
  const state: ReviewState = total > 0 && reviewed >= total ? 'reviewed' : 'pending';
  const detail = uncited > 0 ? `${uncited} Yes missing a citation — not honoured` : undefined;
  return { ...base, benchmark, state, reviewed, total, detail };
}

const TAG: Record<ReviewState, string> = { reviewed: 'OK   ', pending: 'TODO ', stale: 'STALE', error: 'ERR  ' };

/** Render the status rows as a plain-text report; only pending/stale/error rows carry action lines. Pure. */
export function formatStatusReport(rows: StatusRow[]): string {
  if (!rows.length) return 'No review slots found under fixtures/golden-runs/*/review/.';
  const needing = rows.filter((r) => r.state !== 'reviewed').length;
  const lines: string[] = [`Review status — ${rows.length} slot(s), ${needing} needing attention:`, ''];
  for (const r of rows) {
    const bench = r.benchmark ? ` [${r.benchmark}]` : '';
    const summary =
      r.state === 'error' ? (r.detail ?? 'error')
      : r.state === 'stale' ? 'stale — the capture changed, re-review'
      : `${r.reviewed}/${r.total} reviewed${r.detail ? ` (${r.detail})` : ''}`;
    lines.push(`  ${TAG[r.state]}  ${r.slot}${bench} — ${summary}`);
    if (r.state !== 'reviewed') {
      lines.push(`           open  ${fileUrl(r.reviewHtml)}`);
      if (r.state !== 'error') lines.push(`           then  npm run ingest-verdict ${r.ingestArg}`);
    }
  }
  return lines.join('\n');
}

/** CLI: `review:status [goldenRunsRoot]` — prints the report. Read-only. Exits 0 normally; 2 when any slot is
 *  in an `error` state (broken manifest/meta) so it doubles as a lightweight config sanity check. A `pending`
 *  or `stale` slot is a normal "awaiting review" state and stays exit 0 (the hard gate is REQUIRE_REVIEW). */
export function runStatusCli(argv: string[]): number {
  const root = argv[0] ? path.resolve(argv[0]) : defaultSlotsRoot();
  const rows = discoverReviewSlots(root).map(slotStatus);
  console.log(formatStatusReport(rows));
  return rows.some((r) => r.state === 'error') ? 2 : 0;
}
