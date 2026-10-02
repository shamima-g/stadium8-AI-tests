/**
 * Human-review harness — Step 2: the review-page generator.
 *
 * `buildReviewHtml(manifest)` turns a review manifest into a SELF-CONTAINED `review.html` (no server, no
 * network, no external refs) that a person opens to judge each check Yes/No/Skip and then copies a
 * `verdict.json`. Design points forced by the Step-1 council:
 *   - The stamp hashes the EXACT evidence string shown (`stampFor` over the same items), so "what the
 *     reviewer saw" == "what the test checks". Text evidence is shown verbatim in an escaped <pre>
 *     (no markdown rendering → no many-to-one divergence); an HTML mockup is shown in a sandboxed,
 *     script-less <iframe srcdoc> and the stamp covers its source bytes.
 *   - A "Yes" REQUIRES a non-empty evidence citation — enforced by `assembleVerdict`, a pure exported
 *     function whose source is embedded into the page, so the browser runs exactly what the unit tests
 *     test (no untested in-page logic).
 *   - Copy-to-clipboard + a select-all <textarea> are the primary output (a file download can't choose
 *     its path and Safari opens JSON inline — the `ingest-verdict` command places the file, Step 3).
 *
 * The page is injection-safe and zero-network by escaping + the sandboxed iframe (council-verified). A CSP
 * meta tag is deliberately DEFERRED to the Step-7 live wiring, where it can be browser-smoke-tested — an
 * untested CSP risks silently blocking the srcdoc mockup (a gating design-review check), so it's not added
 * blind here.
 */
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

export function buildReviewHtml(manifest: ReviewManifest): string {
  const items = manifest.items;
  const stamp = stampFor(items); // same helper loadVerdict's caller uses → stamps agree by construction

  const sections = items
    .map((it) => {
      const ev =
        it.kind === 'html-mockup'
          ? `<iframe class="mockup" sandbox="" srcdoc="${escapeHtml(it.evidence)}"></iframe>`
          : `<pre class="evidence">${escapeHtml(it.evidence)}</pre>`;
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
  .evidence { background: #f6f8fa; padding: .75rem; border-radius: 6px; white-space: pre-wrap; overflow-x: auto; }
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
