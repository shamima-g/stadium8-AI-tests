/**
 * Human-review harness — Step 2: the review-page generator.
 *
 * `buildReviewHtml(manifest)` turns a review manifest into a SELF-CONTAINED `review.html` (no server, no
 * network, no external refs) that a person opens to judge each check Yes/No/Skip and then copies a
 * `verdict.json`. Design points forced by the Step-1 council:
 *   - The stamp hashes the EXACT raw evidence string (`stampFor` over the same items), so "what the test
 *     checks" is fixed to the capture's bytes regardless of presentation. Text evidence IS markdown source
 *     lifted from the generated docs, so it is rendered to safe HTML (tables/headings/etc) for a legible
 *     review via `renderEvidenceMarkdown` — escape-then-format, so injected markup stays inert exactly as
 *     the old escaped <pre> guaranteed, and the stamp still covers the raw bytes (not the rendered HTML).
 *     An HTML mockup is shown in a sandboxed, script-less <iframe srcdoc> and the stamp covers its source.
 *   - A "Yes" REQUIRES a non-empty evidence citation — enforced by `assembleVerdict`, a pure exported
 *     function whose source is embedded into the page, so the browser runs exactly what the unit tests
 *     test (no untested in-page logic).
 *   - Copy-to-clipboard + a select-all <textarea> are the primary output (a file download can't choose
 *     its path and Safari opens JSON inline — the `ingest-verdict` command places the file, Step 3).
 *
 * The page is injection-safe and zero-network by escaping + the sandboxed iframe (council-verified: no
 * fetch/XHR, only navigator.clipboard.writeText). A CSP <meta> is still DEFERRED: it must be smoke-tested
 * in a real browser (not available here) because a wrong frame-src could silently block the srcdoc mockup
 * (a gating design-review check). The page is network-free by construction regardless, so CSP is
 * defense-in-depth, not load-bearing. Revisit when a browser is available.
 */
import fs from 'node:fs';
import path from 'node:path';
import { stampFor, type EvidenceItem, type Outcome } from './human-review';

export interface ReviewItem extends EvidenceItem {
  /** how to render the evidence: verbatim text (default) or an HTML mockup in a sandboxed iframe */
  kind?: 'text' | 'html-mockup';
}
export interface ReviewManifest {
  captureLabel: string;
  items: ReviewItem[];
}

export interface Selection {
  id: string;
  outcome: Outcome;
  citation: string;
}
export interface AssembleResult {
  ok: boolean;
  errors: string[];
  verdict?: {
    stamp: string;
    reviewer: string;
    reviewedAt: string;
    results: Record<string, Outcome>;
    citations: Record<string, string>;
  };
}

/**
 * Pure: turn the reviewer's selections into a verdict object, enforcing "a Yes needs a citation".
 * Exported AND embedded into the page (via .toString()) so the browser runs exactly this. Plain-JS only
 * (no TS-runtime features) so its compiled source is valid in the browser.
 */
export function assembleVerdict(selections: Selection[], stamp: string, reviewer: string, nowIso: string): AssembleResult {
  const errors = [];
  const results = {};
  const citations = {};
  for (const s of selections) {
    results[s.id] = s.outcome;
    const cite = (typeof s.citation === 'string' ? s.citation : '').trim();
    if (cite) citations[s.id] = cite;
    if (s.outcome === 'pass' && !cite) errors.push('"' + s.id + '": a Yes needs a one-line evidence citation.');
  }
  if (errors.length) return { ok: false, errors };
  return { ok: true, errors: [], verdict: { stamp, reviewer, reviewedAt: nowIso, results, citations } };
}

export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Inline markdown on text that is ALREADY HTML-escaped. Order matters only in that we never introduce a
 * raw `<`/`>`: every tag we emit is literal and the content between markers stays escaped, so this cannot
 * reintroduce live HTML. A markdown link renders as its label only (no href) — the page is zero-network by
 * construction and we never want a clickable external target in review evidence.
 */
function mdInline(escaped: string): string {
  return escaped
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '<a>$1</a>');
}

/**
 * Append a small colour swatch after any hex colour token (`#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`),
 * whether it sits bare in text or inside a `<code>` span. Runs on already-formatted HTML; the captured
 * `#aabbcc` strings are strict hex, so the injected `style`/`title` carry no attacker-controlled bytes.
 * A single `.replace` pass never re-scans its own output, so the swatch's own style value is not re-matched.
 */
function withColorSwatches(html: string): string {
  return html.replace(/(<code>)?#([0-9a-fA-F]{3,8})(<\/code>)?(?![0-9a-fA-F])/g, (m, open, hex, close) => {
    if (![3, 4, 6, 8].includes(hex.length)) return m; // 5- and 7-digit runs aren't valid hex colours
    const token = `${open ?? ''}#${hex}${close ?? ''}`;
    return `${token}<span class="swatch" style="background:#${hex}" title="#${hex}"></span>`;
  });
}

/** escape THEN inline THEN swatch — the one safe path from a raw evidence fragment to display HTML. */
function fmt(raw: string): string {
  return withColorSwatches(mdInline(escapeHtml(raw)));
}

function splitRow(line: string): string[] {
  return line
    .trim()
    .replace(/^\|/, '')
    .replace(/\|$/, '')
    .split('|')
    .map((c) => c.trim());
}

function isTableSeparator(line: string): boolean {
  return /^\s*\|?[\s:|-]+\|?\s*$/.test(line) && line.includes('-');
}

/**
 * Render a SUBSET of markdown (headings, tables, bold, inline code, links-as-text, blockquotes, lists,
 * horizontal rules, paragraphs) to safe HTML. The evidence IS markdown source lifted from the generated
 * docs, so rendering it makes the reviewer's job legible without changing what the stamp covers: the stamp
 * hashes the RAW evidence string (`stampFor`), never this HTML. Every text fragment passes through `fmt`
 * (escape-then-inline), so injected markup is inert — exactly as the old escaped `<pre>` guaranteed.
 */
export function renderEvidenceMarkdown(raw: string): string {
  const lines = raw.replace(/\r\n?/g, '\n').split('\n');
  const out: string[] = [];
  let i = 0;

  const isBlockStart = (line: string, next: string | undefined): boolean =>
    /^\s*$/.test(line) ||
    /^(#{1,6})\s+/.test(line) ||
    /^\s*([-*_])\1{2,}\s*$/.test(line) ||
    /^\s*>\s?/.test(line) ||
    /^\s*[-*]\s+/.test(line) ||
    (/^\s*\|.*\|\s*$/.test(line) && next !== undefined && isTableSeparator(next));

  while (i < lines.length) {
    const line = lines[i];

    // Table: a pipe row immediately followed by a separator row.
    if (/^\s*\|.*\|\s*$/.test(line) && i + 1 < lines.length && isTableSeparator(lines[i + 1])) {
      const header = splitRow(line);
      i += 2; // consume header + separator
      const rows: string[][] = [];
      while (i < lines.length && /^\s*\|.*\|\s*$/.test(lines[i])) {
        rows.push(splitRow(lines[i]));
        i++;
      }
      const thead = '<thead><tr>' + header.map((c) => `<th>${fmt(c)}</th>`).join('') + '</tr></thead>';
      const tbody =
        '<tbody>' +
        rows.map((r) => '<tr>' + header.map((_, idx) => `<td>${fmt(r[idx] ?? '')}</td>`).join('') + '</tr>').join('') +
        '</tbody>';
      out.push(`<table class="md-table">${thead}${tbody}</table>`);
      continue;
    }

    // Heading — demoted two levels so evidence headings sit under the page's own <h2>.
    const h = /^(#{1,6})\s+(.*)$/.exec(line);
    if (h) {
      const level = Math.min(6, h[1].length + 2);
      out.push(`<h${level}>${fmt(h[2].trim())}</h${level}>`);
      i++;
      continue;
    }

    // Horizontal rule (a line of only ---, ***, or ___).
    if (/^\s*([-*_])\1{2,}\s*$/.test(line)) {
      out.push('<hr>');
      i++;
      continue;
    }

    // Blockquote (one or more consecutive `>` lines).
    if (/^\s*>\s?/.test(line)) {
      const quote: string[] = [];
      while (i < lines.length && /^\s*>\s?/.test(lines[i])) {
        quote.push(lines[i].replace(/^\s*>\s?/, ''));
        i++;
      }
      out.push(`<blockquote>${fmt(quote.join(' ').trim())}</blockquote>`);
      continue;
    }

    // Unordered list (one or more consecutive `-`/`*` items).
    if (/^\s*[-*]\s+/.test(line)) {
      const items: string[] = [];
      while (i < lines.length && /^\s*[-*]\s+/.test(lines[i])) {
        items.push(lines[i].replace(/^\s*[-*]\s+/, ''));
        i++;
      }
      out.push('<ul>' + items.map((it) => `<li>${fmt(it.trim())}</li>`).join('') + '</ul>');
      continue;
    }

    // Blank line — paragraph separator.
    if (/^\s*$/.test(line)) {
      i++;
      continue;
    }

    // Paragraph — gather consecutive plain lines.
    const para: string[] = [];
    while (i < lines.length && !isBlockStart(lines[i], lines[i + 1])) {
      para.push(lines[i]);
      i++;
    }
    out.push(`<p>${fmt(para.join(' ').trim())}</p>`);
  }

  return out.join('\n');
}

export function buildReviewHtml(manifest: ReviewManifest): string {
  const items = manifest.items;
  const stamp = stampFor(items); // same helper loadVerdict's caller uses → stamps agree by construction

  const sections = items
    .map((it) => {
      const ev =
        it.kind === 'html-mockup'
          ? `<iframe class="mockup" sandbox="" srcdoc="${escapeHtml(it.evidence)}"></iframe>`
          : `<div class="evidence md">${renderEvidenceMarkdown(it.evidence)}</div>`;
      return `<section class="check" data-id="${escapeHtml(it.id)}">
  <h2>${escapeHtml(it.criterion)}</h2>
  ${it.guidance ? `<p class="guidance">${escapeHtml(it.guidance)}</p>` : ''}
  ${ev}
  <div class="verdict">
    <label><input type="radio" name="r-${escapeHtml(it.id)}" value="pass"> Yes</label>
    <label><input type="radio" name="r-${escapeHtml(it.id)}" value="fail"> No</label>
    <label><input type="radio" name="r-${escapeHtml(it.id)}" value="skip" checked> Skip</label>
    <input type="text" class="cite" placeholder="Evidence citation (required for Yes)">
  </div>
</section>`;
    })
    .join('\n');

  // Embed the exact pure function the unit tests test, so the page runs tested code.
  const assembleSrc = assembleVerdict.toString();

  return renderPage(manifest, stamp, sections, assembleSrc);
}

/**
 * Write the review bundle to `reviewDir`: `manifest.json` (the SINGLE shared source of the evidence — the
 * same items this page is stamped from, which `ingest-verdict` + `loadVerdict` re-read) and `review.html`.
 * So the stamp the page embeds, the stamp ingest validates, and the stamp the test re-checks are identical
 * by construction (all `stampFor(manifest.items)`).
 */
export function writeReview(reviewDir: string, manifest: ReviewManifest): { manifestPath: string; htmlPath: string } {
  fs.mkdirSync(reviewDir, { recursive: true });
  const manifestPath = path.join(reviewDir, 'manifest.json');
  const htmlPath = path.join(reviewDir, 'review.html');
  fs.writeFileSync(manifestPath, JSON.stringify({ captureLabel: manifest.captureLabel, items: manifest.items }, null, 2));
  fs.writeFileSync(htmlPath, buildReviewHtml(manifest));
  return { manifestPath, htmlPath };
}

function renderPage(manifest: ReviewManifest, stamp: string, sections: string, assembleSrc: string): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Review — ${escapeHtml(manifest.captureLabel)}</title>
<style>
  body { font: 15px/1.5 system-ui, sans-serif; max-width: 900px; margin: 1rem auto; padding: 0 1rem; }
  .check { border: 1px solid #ccc; border-radius: 8px; padding: 1rem; margin: 1rem 0; }
  .guidance { color: #555; font-style: italic; }
  .evidence { background: #f6f8fa; padding: .75rem; border-radius: 6px; overflow-x: auto; }
  .evidence.md > *:first-child { margin-top: 0; }
  .evidence.md > *:last-child { margin-bottom: 0; }
  .evidence h3, .evidence h4, .evidence h5, .evidence h6 { margin: .6rem 0 .3rem; line-height: 1.3; }
  .evidence p { margin: .4rem 0; }
  .evidence ul { margin: .4rem 0; padding-left: 1.2rem; }
  .evidence code { background: #eaeef2; padding: .05rem .3rem; border-radius: 4px; font-family: ui-monospace, monospace; font-size: 13px; }
  .evidence .swatch { display: inline-block; width: .85em; height: .85em; margin: 0 .15rem 0 .35rem; border: 1px solid rgba(0,0,0,.25); border-radius: 3px; vertical-align: middle; }
  .evidence blockquote { margin: .5rem 0; padding: .1rem .75rem; border-left: 3px solid #d0d7de; color: #555; }
  .evidence hr { border: none; border-top: 1px solid #d0d7de; margin: .75rem 0; }
  .evidence table.md-table { border-collapse: collapse; margin: .5rem 0; font-size: 14px; }
  .evidence table.md-table th, .evidence table.md-table td { border: 1px solid #d0d7de; padding: .3rem .55rem; text-align: left; vertical-align: top; }
  .evidence table.md-table th { background: #eaeef2; }
  .mockup { width: 100%; height: 320px; border: 1px solid #ddd; border-radius: 6px; }
  .verdict { margin-top: .5rem; display: flex; gap: 1rem; align-items: center; flex-wrap: wrap; }
  .cite { flex: 1; min-width: 200px; padding: .3rem; }
  #out { width: 100%; height: 160px; font-family: monospace; }
  button { padding: .5rem 1rem; font-size: 1rem; cursor: pointer; }
  #err { color: #b00; white-space: pre-wrap; }
</style>
</head>
<body>
<h1>Review — ${escapeHtml(manifest.captureLabel)}</h1>
<p>Judge each check, add a one-line citation for every <b>Yes</b>, then <b>Build verdict</b> and <b>Copy</b>.
Place it with <code>npm run ingest-verdict</code> (it will not save to a folder from the browser).</p>
${sections}
<p>
  <label>Reviewer: <input id="reviewer" type="text" placeholder="your name"></label>
  <button id="build">Build verdict</button>
  <button id="copy">Copy</button>
</p>
<div id="err"></div>
<textarea id="out" readonly placeholder="the verdict JSON appears here"></textarea>
<script>
const STAMP = ${JSON.stringify(stamp)};
const assembleVerdict = ${assembleSrc};
function collect() {
  return [...document.querySelectorAll('.check')].map(function (sec) {
    const id = sec.getAttribute('data-id');
    const picked = sec.querySelector('input[type=radio]:checked');
    return { id: id, outcome: picked ? picked.value : 'skip', citation: (sec.querySelector('.cite').value || '') };
  });
}
document.getElementById('build').addEventListener('click', function () {
  const reviewer = (document.getElementById('reviewer').value || '').trim();
  const res = assembleVerdict(collect(), STAMP, reviewer, new Date().toISOString());
  const err = document.getElementById('err'), out = document.getElementById('out');
  if (!res.ok) { err.textContent = 'Fix before building:\\n- ' + res.errors.join('\\n- '); out.value = ''; return; }
  err.textContent = ''; out.value = JSON.stringify(res.verdict, null, 2);
});
document.getElementById('copy').addEventListener('click', function () {
  const out = document.getElementById('out');
  if (!out.value) { document.getElementById('err').textContent = 'Build the verdict first.'; return; }
  out.select();
  if (navigator.clipboard) navigator.clipboard.writeText(out.value); else document.execCommand('copy');
});
</script>
</body>
</html>`;
}
