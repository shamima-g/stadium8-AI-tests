/**
 * Human-review harness — Step 3: the `ingest-verdict` command.
 *
 * A browser can't save a file to a chosen folder, so the reviewer copies the verdict JSON and this command
 * PLACES it in the slot's review/ dir — after validating its stamp against the capture (fail-closed), so a
 * verdict for a different/changed capture is refused, not filed. The validation is a pure, unit-tested
 * function; the clipboard/Downloads/file gathering + the write are the thin I/O wrapper.
 *
 * Usage (run via tsx):
 *   ingest-verdict <slotReviewDir> [--file <path> | --from-clipboard | --text <json>]
 *   (default source: newest verdict*.json in ~/Downloads)
 * The slot review dir must contain `manifest.json` ({ items: EvidenceItem[] }) — the capture writes it
 * next to review.html, and it is the single source of the expected stamp (stampFor(items)).
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { stampFor, type EvidenceItem, type Outcome } from './human-review';

export interface IngestResult {
  ok: boolean;
  error?: string;
  verdict?: unknown;
  /** the stamp the slot's manifest expects — surfaced for messages/debugging */
  expectedStamp: string;
}

const OUTCOMES = new Set<Outcome>(['pass', 'fail', 'skip']);

/**
 * Rebuild a CLEAN verdict from a stamp-validated body: only known fields, `results` restricted to valid
 * outcomes, `citations` to strings, and the dangerous `__proto__` key dropped. Neutralizes the
 * verbatim-passthrough vector (garbage/non-object results, prototype keys) that a downstream consumer
 * deep-merging or trusting `results`'s shape could otherwise hit.
 */
function sanitizeVerdict(v: Record<string, unknown>, stamp: string) {
  const asObj = (o: unknown): Record<string, unknown> =>
    o && typeof o === 'object' && !Array.isArray(o) ? (o as Record<string, unknown>) : {};
  const rin = asObj(v.results);
  const cin = asObj(v.citations);
  const results: Record<string, Outcome> = {};
  const citations: Record<string, string> = {};
  for (const k of Object.keys(rin)) {
    if (k === '__proto__') continue;
    const val = rin[k];
    if (typeof val === 'string' && OUTCOMES.has(val as Outcome)) results[k] = val as Outcome;
  }
  for (const k of Object.keys(cin)) {
    if (k === '__proto__') continue;
    if (typeof cin[k] === 'string') citations[k] = cin[k] as string;
  }
  return {
    stamp,
    reviewer: typeof v.reviewer === 'string' ? v.reviewer : '',
    reviewedAt: typeof v.reviewedAt === 'string' ? v.reviewedAt : '',
    results,
    citations,
  };
}

/**
 * Pure: validate an incoming verdict against the capture's manifest. Fail-closed — a non-object body, a
 * missing/empty stamp, or a stamp that doesn't match `stampFor(manifestItems)` is refused.
 */
export function ingestVerdict(manifestItems: EvidenceItem[], incomingText: string): IngestResult {
  const expectedStamp = stampFor(manifestItems);
  let v: unknown;
  try {
    v = JSON.parse(incomingText);
  } catch (e) {
    return { ok: false, error: `verdict is not valid JSON: ${(e as Error).message}`, expectedStamp };
  }
  if (!v || typeof v !== 'object' || Array.isArray(v)) {
    return { ok: false, error: 'verdict is not a JSON object', expectedStamp };
  }
  const rawStamp = (v as { stamp?: unknown }).stamp;
  const vs = typeof rawStamp === 'string' ? rawStamp.trim() : '';
  if (!vs) {
    return { ok: false, error: 'verdict has no stamp — it was not produced by this review page', expectedStamp };
  }
  if (vs !== expectedStamp) {
    return {
      ok: false,
      error: `stamp mismatch — this verdict is for a different/changed capture (expected ${expectedStamp.slice(0, 12)}…, got ${vs.slice(0, 12)}…). Re-review the current review.html.`,
      expectedStamp,
    };
  }
  return { ok: true, verdict: sanitizeVerdict(v as Record<string, unknown>, expectedStamp), expectedStamp };
}

// ── I/O wrapper (not unit-tested; smoke-tested at Step 7) ───────────────────────────────────────────

/** Read the OS clipboard as text, cross-platform. Returns '' if no clipboard tool is available. */
export function readClipboard(): string {
  try {
    if (process.platform === 'win32') return execFileSync('powershell', ['-NoProfile', '-Command', 'Get-Clipboard'], { encoding: 'utf8' });
    if (process.platform === 'darwin') return execFileSync('pbpaste', [], { encoding: 'utf8' });
    return execFileSync('sh', ['-c', 'xclip -selection clipboard -o 2>/dev/null || xsel --clipboard --output 2>/dev/null'], { encoding: 'utf8' });
  } catch {
    return '';
  }
}

/** Newest `verdict*.json` in ~/Downloads, or '' if none. */
export function newestDownloadedVerdict(): string {
  const dir = path.join(os.homedir(), 'Downloads');
  try {
    const hits = fs
      .readdirSync(dir)
      .filter((f) => /^verdict.*\.json$/i.test(f))
      .map((f) => ({ f, m: fs.statSync(path.join(dir, f)).mtimeMs }))
      .sort((a, b) => b.m - a.m);
    return hits.length ? fs.readFileSync(path.join(dir, hits[0].f), 'utf8') : '';
  } catch {
    return '';
  }
}

function readManifestItems(reviewDir: string): EvidenceItem[] {
  const p = path.join(reviewDir, 'manifest.json');
  const m = JSON.parse(fs.readFileSync(p, 'utf8')) as { items?: EvidenceItem[] };
  if (!Array.isArray(m.items)) throw new Error(`${p} has no items[]`);
  return m.items;
}

export function runCli(argv: string[]): number {
  const reviewDir = argv[0];
  if (!reviewDir) {
    console.error('usage: ingest-verdict <slotReviewDir> [--file <path> | --from-clipboard | --text <json>]');
    return 2;
  }
  try {
    const fileIdx = argv.indexOf('--file');
    const textIdx = argv.indexOf('--text');
    if (fileIdx >= 0 && !argv[fileIdx + 1]) { console.error('--file needs a path'); return 2; }
    let incoming = '';
    if (fileIdx >= 0) incoming = fs.readFileSync(argv[fileIdx + 1], 'utf8');
    else if (textIdx >= 0) incoming = argv[textIdx + 1] ?? '';
    else if (argv.includes('--from-clipboard')) incoming = readClipboard();
    else incoming = newestDownloadedVerdict();

    if (!incoming.trim()) {
      console.error('no verdict found: copy the verdict JSON from review.html, or pass --file <path> / --text <json>. (On Linux, install xclip or xsel for clipboard access.)');
      return 1;
    }
    const items = readManifestItems(reviewDir); // may throw: ENOENT / malformed / no items[]
    const res = ingestVerdict(items, incoming);
    if (!res.ok) {
      console.error('REFUSED: ' + res.error);
      return 1;
    }
    const out = path.join(reviewDir, 'verdict.json');
    fs.writeFileSync(out, JSON.stringify(res.verdict, null, 2));
    console.log('verdict placed -> ' + out);
    return 0;
  } catch (e) {
    // a missing --file, missing/malformed manifest.json, or an unreadable path lands here as a clean
    // message + nonzero exit, never a raw stack trace (and never a write, so no good verdict is clobbered).
    console.error('ERROR: ' + (e as Error).message);
    return 1;
  }
}

// Run as a CLI when invoked directly (tsx), not when imported by a test.
if (process.argv[1] && /ingest-verdict\.(ts|js|mjs)$/.test(process.argv[1])) {
  process.exit(runCli(process.argv.slice(2)));
}
