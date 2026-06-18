#!/usr/bin/env node
/**
 * generate-test-report.cjs — writes a friendly, plain-language report after a test run.
 *
 * Output: QA-TESTS/TestResults/report-<version>-<timestamp>.md  (+ a matching .json
 *         sidecar) and a rebuilt index.md run-history page. The timestamp in the
 *         filename means a new file every run — nothing is ever overwritten.
 *
 * The report is written for a human reader, not a developer. It covers up to four
 * things, and includes only the ones that actually have data:
 *
 *   1. Project & workflow checks  — the QA suite that always runs here (Vitest).
 *   2. The app's own tests        — the web/ unit + integration tests (Vitest).
 *   3. Using the app like a person — the web/ end-to-end tests (Playwright).
 *   4. Final quality gates        — security, code style, build, and tests.
 *
 * It also counts the lines of code in the project, and (when a live workflow run
 * is present) shows how many AI tokens were used and the rough cost.
 *
 * Usage:
 *   node scripts/generate-test-report.cjs                 # run the QA suite, then write the report
 *   node scripts/generate-test-report.cjs --results <vitest.json>  # use an existing QA result file
 *   node scripts/generate-test-report.cjs --with-web      # also run the app's own tests
 *   node scripts/generate-test-report.cjs --with-e2e      # also run the click-through tests
 *   node scripts/generate-test-report.cjs --with-gates    # also run the final quality gates
 *   node scripts/generate-test-report.cjs --telemetry-root <dir>   # include AI tokens + cost
 *   node scripts/generate-test-report.cjs --out <path>    # write to a specific file
 *   node scripts/generate-test-report.cjs --no-open       # don't pop the report open
 *   node scripts/generate-test-report.cjs --exit-code     # exit non-zero if any check needs attention
 *
 * The heavier surfaces (web tests, click-through tests, quality gates) only RUN
 * when you ask for them with the flags above. The rest of the time, the report
 * quietly reuses the most recent saved result for each (and says how old it is),
 * so the everyday report stays fast.
 */
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const QA_ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(QA_ROOT, '..');
const WEB_ROOT = path.join(REPO_ROOT, 'web');
const OUT_DIR = path.join(QA_ROOT, 'TestResults');

// Code-file extensions we count as "lines of code".
const CODE_EXTS = new Set(['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.css', '.scss']);

// ----------------------------------------------------------------------------
// args
// ----------------------------------------------------------------------------
function parseArgs(argv) {
  const a = argv.slice(2);
  const o = {
    results: null, out: null, telemetryRoot: null, open: true,
    withWeb: false, withE2e: false, withGates: false, exitCode: false,
  };
  for (let i = 0; i < a.length; i++) {
    if (a[i] === '--results') o.results = a[++i];
    else if (a[i] === '--out') o.out = a[++i];
    else if (a[i] === '--telemetry-root') o.telemetryRoot = a[++i];
    else if (a[i] === '--no-open') o.open = false;
    else if (a[i] === '--with-web') o.withWeb = true;
    else if (a[i] === '--with-e2e') o.withE2e = true;
    else if (a[i] === '--with-gates') o.withGates = true;
    else if (a[i] === '--exit-code') o.exitCode = true;
  }
  // Never try to pop a window open in CI / non-interactive shells.
  if (process.env.CI) o.open = false;
  return o;
}

/** Open the finished report in the default app (fire-and-forget, cross-platform). */
function openReport(file) {
  try {
    const cmd = process.platform === 'win32' ? 'cmd'
      : process.platform === 'darwin' ? 'open' : 'xdg-open';
    const args = process.platform === 'win32' ? ['/c', 'start', '', file] : [file];
    spawnSync(cmd, args, { stdio: 'ignore', detached: true, shell: false });
  } catch { /* opening is best-effort — never fail the run over it */ }
}

// ----------------------------------------------------------------------------
// small helpers
// ----------------------------------------------------------------------------
function sh(cmd, args, cwd) {
  try {
    const r = spawnSync(cmd, args, { cwd: cwd || QA_ROOT, encoding: 'utf8', timeout: 15000 });
    return (r.status === 0 && r.stdout) ? r.stdout.trim() : null;
  } catch { return null; }
}

function pkgVersion() {
  try { return JSON.parse(fs.readFileSync(path.join(QA_ROOT, 'package.json'), 'utf8')).version || '0.0.0'; }
  catch { return '0.0.0'; }
}

function vitestVersion() {
  try { return JSON.parse(fs.readFileSync(path.join(QA_ROOT, 'node_modules', 'vitest', 'package.json'), 'utf8')).version; }
  catch { return null; }
}

/** ms → "11m 16s" / "9.4s" / "320ms". */
function fmtDuration(ms) {
  if (ms == null || !Number.isFinite(ms)) return '—';
  if (ms < 1000) return `${Math.round(ms)}ms`;
  const s = ms / 1000;
  if (s < 60) return `${(Math.round(s * 10) / 10)}s`;
  const m = Math.floor(s / 60);
  return `${m}m ${Math.round(s - m * 60)}s`;
}

function pad2(n) { return String(n).padStart(2, '0'); }
const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'];
function stampParts(d) {
  const h = d.getHours();
  const h12 = ((h + 11) % 12) + 1;
  const ampm = h < 12 ? 'am' : 'pm';
  return {
    iso: `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())} ${pad2(h)}:${pad2(d.getMinutes())}:${pad2(d.getSeconds())}`,
    file: `${d.getFullYear()}${pad2(d.getMonth() + 1)}${pad2(d.getDate())}-${pad2(h)}${pad2(d.getMinutes())}`,
    timeOnly: `${pad2(h)}:${pad2(d.getMinutes())}:${pad2(d.getSeconds())}`,
    // "18 June 2026, 6:37am" — the human-friendly form used in the report body.
    friendly: `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}, ${h12}:${pad2(d.getMinutes())}${ampm}`,
    friendlyTime: `${h12}:${pad2(d.getMinutes())}${ampm}`,
  };
}

function esc(s) { return String(s == null ? '' : s).replace(/\|/g, '\\|').replace(/\r?\n/g, ' '); }
function plural(n, one, many) { return n === 1 ? one : (many || one + 's'); }

// ----------------------------------------------------------------------------
// run / load Vitest JSON
// ----------------------------------------------------------------------------
/**
 * Run the QA Vitest suite. Streams the normal output to the terminal (so the
 * person watching still sees live results) AND captures a JSON copy we read back.
 */
function runVitest() {
  const tmp = path.join(os.tmpdir(), `qa-vitest-${process.pid}.json`);
  const res = spawnSync('npx', ['vitest', 'run', '--reporter=default', '--reporter=json', `--outputFile=${tmp}`], {
    cwd: QA_ROOT, encoding: 'utf8', timeout: 600000, stdio: ['ignore', 'inherit', 'inherit'],
    shell: process.platform === 'win32',
  });
  let json = null;
  try { json = JSON.parse(fs.readFileSync(tmp, 'utf8')); } catch { /* ignore */ }
  try { fs.unlinkSync(tmp); } catch { /* ignore */ }
  return json;
}

function loadResults(opts) {
  if (opts.results) return JSON.parse(fs.readFileSync(opts.results, 'utf8'));
  const json = runVitest();
  if (!json) throw new Error('Could not obtain Vitest JSON results (run failed or produced no output).');
  return json;
}

// ----------------------------------------------------------------------------
// model the QA results
// ----------------------------------------------------------------------------
// "Layer" = the tier + first sub-folder, e.g. "tier-1-unit › scripts". Anchored
// on the "tier-*" segment so it survives any checkout path; falls back to a path
// relative to QA_ROOT.
function layerOf(fileName) {
  const parts = String(fileName).replace(/\\/g, '/').split('/').filter(Boolean);
  const tierIdx = parts.findIndex(p => /^tier-/.test(p));
  if (tierIdx !== -1) {
    const tier = parts[tierIdx];
    const sub = parts[tierIdx + 1];
    return sub && tierIdx + 2 < parts.length ? `${tier} › ${sub}` : tier;
  }
  const rel = path.relative(QA_ROOT, fileName).replace(/\\/g, '/').split('/').filter(Boolean);
  return rel.length >= 2 ? `${rel[0]} › ${rel[1]}` : (rel[0] || String(fileName));
}

// Plain-language names for the technical "layer" folders. Anything not listed
// falls back to a tidied-up version of the folder name.
const AREA_NAMES = {
  'tier-1-unit › artifact-lint': 'Project files follow the rules',
  'tier-1-unit › consistency': 'Everything lines up and is consistent',
  'tier-1-unit › hooks': 'Built-in safety checks',
  'tier-1-unit › schemas': 'Saved data has the right shape',
  'tier-1-unit › scripts': 'Helper tools work correctly',
  'tier-2-log-replay › invariants': 'Workflow records stay trustworthy',
};
function friendlyArea(layer) {
  if (AREA_NAMES[layer]) return AREA_NAMES[layer];
  // Fallback: drop the "tier-N-..." prefix, replace the divider, tidy casing.
  const tail = String(layer).split('›').pop().trim().replace(/[-_]/g, ' ');
  return tail ? tail.charAt(0).toUpperCase() + tail.slice(1) : String(layer);
}

function statusOf(a) {
  // Vitest: "passed" | "failed" | "skipped" | "pending" (todo) | "disabled"
  if (a.status === 'passed') return 'passed';
  if (a.status === 'failed') return 'failed';
  return 'skipped';
}

function buildModel(json) {
  const tests = [];
  let minStart = Infinity, maxEnd = -Infinity;

  for (const tf of json.testResults || []) {
    const layer = layerOf(tf.name);
    if (Number.isFinite(tf.startTime)) minStart = Math.min(minStart, tf.startTime);
    if (Number.isFinite(tf.endTime)) maxEnd = Math.max(maxEnd, tf.endTime);
    for (const a of tf.assertionResults || []) {
      tests.push({
        layer,
        title: a.fullName || [...(a.ancestorTitles || []), a.title].filter(Boolean).join(' › ') || a.title,
        result: statusOf(a),
        duration: typeof a.duration === 'number' ? a.duration : null,
        message: (a.failureMessages && a.failureMessages.length) ? a.failureMessages.join('\n') : null,
      });
    }
  }

  const counts = { total: tests.length, passed: 0, failed: 0, skipped: 0 };
  for (const t of tests) counts[t.result]++;

  // Per-layer rollup
  const byLayer = {};
  for (const t of tests) {
    const L = (byLayer[t.layer] = byLayer[t.layer] || { layer: t.layer, total: 0, passed: 0, failed: 0, skipped: 0, duration: 0 });
    L.total++; L[t.result]++; L.duration += (t.duration || 0);
  }
  const layers = Object.values(byLayer).sort((a, b) => a.layer.localeCompare(b.layer));

  // Total duration: prefer file start→end wall-clock; fall back to summed test time.
  let totalMs = (Number.isFinite(minStart) && Number.isFinite(maxEnd) && maxEnd >= minStart)
    ? (maxEnd - minStart) : tests.reduce((a, t) => a + (t.duration || 0), 0);
  if (json.startTime && Number.isFinite(maxEnd) && maxEnd > json.startTime) totalMs = maxEnd - json.startTime;

  return { tests, counts, layers, totalMs, startTime: json.startTime || minStart };
}

// ----------------------------------------------------------------------------
// extra surfaces: the app's own tests, click-through tests, quality gates
// ----------------------------------------------------------------------------
// Each surface is reduced to a small, uniform shape:
//   { key, name, ran, available, counts:{passed,failed,skipped,total}, durationMs, note, asOf }
// "ran" = we ran it just now; "available" = we have data (fresh or saved).

function emptyCounts() { return { total: 0, passed: 0, failed: 0, skipped: 0 }; }

/** Cache a surface's raw result next to the reports so a later report can reuse it. */
function cacheFile(key) { return path.join(OUT_DIR, `.last-${key}.json`); }
function saveCache(key, payload) {
  try { fs.mkdirSync(OUT_DIR, { recursive: true }); fs.writeFileSync(cacheFile(key), JSON.stringify(payload)); }
  catch { /* best-effort */ }
}
function loadCache(key) {
  try { return JSON.parse(fs.readFileSync(cacheFile(key), 'utf8')); } catch { return null; }
}

/** Count passed/failed/skipped across a Vitest JSON payload (any project). */
function summarizeVitestJson(json) {
  const c = emptyCounts();
  let minStart = Infinity, maxEnd = -Infinity;
  for (const tf of json.testResults || []) {
    if (Number.isFinite(tf.startTime)) minStart = Math.min(minStart, tf.startTime);
    if (Number.isFinite(tf.endTime)) maxEnd = Math.max(maxEnd, tf.endTime);
    for (const a of tf.assertionResults || []) {
      const s = statusOf(a);
      c[s]++; c.total++;
    }
  }
  const durationMs = (Number.isFinite(minStart) && Number.isFinite(maxEnd)) ? maxEnd - minStart : null;
  return { counts: c, durationMs };
}

/** Run the app's own Vitest tests in web/ and capture JSON. */
function runWebVitest() {
  if (!fs.existsSync(path.join(WEB_ROOT, 'package.json'))) return null;
  const tmp = path.join(os.tmpdir(), `web-vitest-${process.pid}.json`);
  spawnSync('npx', ['vitest', 'run', '--reporter=json', `--outputFile=${tmp}`], {
    cwd: WEB_ROOT, encoding: 'utf8', timeout: 600000, stdio: 'ignore',
    shell: process.platform === 'win32',
  });
  let json = null;
  try { json = JSON.parse(fs.readFileSync(tmp, 'utf8')); } catch { /* ignore */ }
  try { fs.unlinkSync(tmp); } catch { /* ignore */ }
  return json;
}

/** Run the Playwright click-through tests in web/ and capture JSON. */
function runE2e() {
  if (!fs.existsSync(path.join(WEB_ROOT, 'package.json'))) return null;
  const r = spawnSync('npx', ['playwright', 'test', '--reporter=json'], {
    cwd: WEB_ROOT, encoding: 'utf8', timeout: 600000, maxBuffer: 50 * 1024 * 1024,
    shell: process.platform === 'win32',
  });
  try { return JSON.parse(r.stdout); } catch { return null; }
}

/** Reduce a Playwright JSON report to passed/failed/skipped counts + duration. */
function summarizePlaywrightJson(json) {
  const c = emptyCounts();
  const walk = (suite) => {
    for (const spec of suite.specs || []) {
      for (const t of spec.tests || []) {
        const st = (t.results && t.results.length) ? t.results[t.results.length - 1].status : t.status;
        c.total++;
        if (st === 'passed' || st === 'expected') c.passed++;
        else if (st === 'skipped') c.skipped++;
        else c.failed++;
      }
    }
    for (const child of suite.suites || []) walk(child);
  };
  for (const s of json.suites || []) walk(s);
  const durationMs = json.stats && Number.isFinite(json.stats.duration) ? json.stats.duration : null;
  return { counts: c, durationMs };
}

/** Run the final quality gates and capture JSON. */
function runGates() {
  const script = path.join(REPO_ROOT, '.claude', 'scripts', 'quality-gates.js');
  if (!fs.existsSync(script)) return null;
  const r = spawnSync('node', [script, '--json'], {
    cwd: REPO_ROOT, encoding: 'utf8', timeout: 600000, maxBuffer: 50 * 1024 * 1024,
    shell: false,
  });
  try { return JSON.parse(r.stdout); } catch { return null; }
}

const GATE_NAMES = {
  gate2_security: 'Security',
  gate3_codeQuality: 'Code style & build',
  gate4_testing: 'Tests',
  gate5_performance: 'Speed',
};
/** Reduce the quality-gates JSON to per-gate pass/fail, counted as "checks". */
function summarizeGatesJson(json) {
  const c = emptyCounts();
  const gateRows = [];
  for (const [key, gate] of Object.entries(json.gates || {})) {
    const name = GATE_NAMES[key] || key;
    c.total++;
    if (gate.status === 'pass') c.passed++;
    else if (gate.status === 'skip') c.skipped++;
    else c.failed++;
    gateRows.push({ name, status: gate.status });
  }
  return { counts: c, durationMs: null, gateRows };
}

/**
 * Gather one surface: run it now if asked, else fall back to the saved copy.
 * Returns the uniform surface shape (or a "not available" stub).
 */
function gatherSurface(key, name, runNow, runFn, summarizeFn) {
  if (runNow) {
    const json = runFn();
    if (json) {
      const s = summarizeFn(json);
      const stamp = stampParts(new Date());
      saveCache(key, { asOf: stamp.iso, ...s });
      return { key, name, ran: true, available: true, asOf: stamp.iso, ...s };
    }
    return { key, name, ran: true, available: false, counts: emptyCounts(), durationMs: null,
      note: 'We tried to run this but could not read a result.' };
  }
  const cached = loadCache(key);
  if (cached && cached.counts) {
    return { key, name, ran: false, available: true, asOf: cached.asOf || null,
      counts: cached.counts, durationMs: cached.durationMs ?? null, gateRows: cached.gateRows,
      note: cached.asOf ? `Reused the saved result from ${cached.asOf}.` : 'Reused a saved result.' };
  }
  return { key, name, ran: false, available: false, counts: emptyCounts(), durationMs: null,
    note: 'Not run yet — no saved result to show.' };
}

// ----------------------------------------------------------------------------
// lines of code
// ----------------------------------------------------------------------------
/** All files tracked by git (respects .gitignore); falls back to []. */
function trackedFiles() {
  const out = sh('git', ['-C', REPO_ROOT, 'ls-files'], REPO_ROOT);
  if (!out) return [];
  return out.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
}

/** Count non-blank lines in a file (best-effort). */
function nonBlankLines(absPath) {
  try {
    const text = fs.readFileSync(absPath, 'utf8');
    let n = 0;
    for (const line of text.split(/\r?\n/)) if (line.trim() !== '') n++;
    return n;
  } catch { return 0; }
}

/**
 * Count lines of code in the golden-harvest application — i.e. everything under
 * web/ that the team writes to build the app, including its TDD tests. The
 * workflow tooling under .claude/ (which ships with the template, not written
 * by the team) is deliberately left out. Only real code files count
 * (.ts/.tsx/.js/.css, …); docs and data don't.
 */
function countLinesOfCode() {
  const buckets = {
    app:    { label: 'Application code (web/src)', files: 0, lines: 0 },
    tests:  { label: 'TDD tests (unit, integration, click-through)', files: 0, lines: 0 },
    setup:  { label: 'Application setup & configuration', files: 0, lines: 0 },
  };
  let counted = false;
  for (const rel of trackedFiles()) {
    const ext = path.extname(rel).toLowerCase();
    if (!CODE_EXTS.has(ext)) continue;
    const posix = rel.replace(/\\/g, '/');
    if (!posix.startsWith('web/')) continue; // application only — skip .claude/ tooling and the QA harness
    const lines = nonBlankLines(path.join(REPO_ROOT, rel));
    if (lines === 0) continue;
    counted = true;
    const isTest = /\.(test|spec)\.[tj]sx?$/.test(posix) || /(^|\/)e2e\//.test(posix) || /__tests__\//.test(posix);
    let b;
    if (isTest) b = buckets.tests;
    else if (posix.startsWith('web/src/')) b = buckets.app;
    else b = buckets.setup;
    b.files++; b.lines += lines;
  }
  if (!counted) return null;
  const rows = Object.values(buckets).filter(b => b.files > 0);
  const total = rows.reduce((a, b) => a + b.lines, 0);
  const totalFiles = rows.reduce((a, b) => a + b.files, 0);
  return { rows, total, totalFiles };
}

// ----------------------------------------------------------------------------
// environment + telemetry
// ----------------------------------------------------------------------------
function environment() {
  const ci = process.env.GITHUB_ACTOR || process.env.BUILD_REQUESTEDFOR || (process.env.CI ? 'CI agent' : null);
  const gitUser = sh('git', ['config', 'user.name']);
  const runBy = ci || gitUser || os.userInfo().username;
  return {
    runBy,
    machine: process.env.GITHUB_RUNNER_NAME || os.hostname(),
    node: process.version,
    vitest: vitestVersion(),
    commit: sh('git', ['-C', REPO_ROOT, 'rev-parse', '--short', 'HEAD']),
    branch: sh('git', ['-C', REPO_ROOT, 'rev-parse', '--abbrev-ref', 'HEAD']),
    os: `${os.platform()} ${os.release()}`,
  };
}

/** Pull macro token + cost totals from the telemetry report, if a ledger exists. */
function telemetryTotals(telemetryRoot) {
  if (!telemetryRoot) return null;
  const ledger = path.join(telemetryRoot, 'generated-docs', 'context', 'telemetry.ndjson');
  if (!fs.existsSync(ledger)) return null;
  const script = path.join(REPO_ROOT, '.claude', 'scripts', 'generate-telemetry-report.js');
  if (!fs.existsSync(script)) return null;
  const out = sh('node', [script, '--tokens', '--json', '--root', telemetryRoot]);
  if (!out) return null;
  try {
    const r = JSON.parse(out);
    const tokens = (r.macro || []).reduce((a, p) => a + (p.tokens ? p.tokens.total : 0), 0);
    return { tokens, costUsd: r.costAvailable ? r.totalCostUsd : null, available: r.tokensAvailable };
  } catch { return null; }
}

// ----------------------------------------------------------------------------
// render
// ----------------------------------------------------------------------------
function resultIcon(r) { return r === 'passed' ? '✅' : r === 'failed' ? '❌' : '⏭️'; }

/** The headline verdict, in plain words. */
function overall(counts) {
  return counts.failed === 0
    ? `✅ All clear — ${counts.passed} passed, ${counts.failed} need attention, ${counts.skipped} not run`
    : `❌ Needs attention — ${counts.passed} passed, ${counts.failed} need attention, ${counts.skipped} not run`;
}

/** A one-sentence, friendly count line for any surface. */
function surfaceSentence(c) {
  const bits = [`${c.passed} passed`];
  if (c.failed) bits.push(`${c.failed} need attention`);
  if (c.skipped) bits.push(`${c.skipped} not run`);
  return bits.join(', ');
}

function render(model, env, tel, version, now, extra) {
  extra = extra || {};
  const loc = extra.loc || null;
  const surfaces = extra.surfaces || []; // extra surfaces beyond the QA suite

  const s = stampParts(now);
  const started = model.startTime ? stampParts(new Date(model.startTime)) : s;
  const ended = model.startTime && Number.isFinite(model.totalMs)
    ? stampParts(new Date(model.startTime + model.totalMs)) : s;

  // Combined totals across every surface that has data.
  const grand = { total: model.counts.total, passed: model.counts.passed, failed: model.counts.failed, skipped: model.counts.skipped };
  for (const su of surfaces) {
    if (!su.available) continue;
    grand.total += su.counts.total; grand.passed += su.counts.passed;
    grand.failed += su.counts.failed; grand.skipped += su.counts.skipped;
  }

  const L = [];
  L.push(`# Test report — ${s.friendly}`, '');
  L.push('A plain-language summary of every check we ran on the project, and how each one did.', '');

  // ── In short ──────────────────────────────────────────────────────────────
  L.push('## In short', '');
  L.push(`**${grand.failed === 0 ? '✅ All clear' : '❌ Some checks need attention'}**`, '');
  L.push(`We ran **${grand.total}** ${plural(grand.total, 'check')} in total: `
    + `**${grand.passed} passed**`
    + (grand.failed ? `, **${grand.failed} ${plural(grand.failed, 'needs', 'need')} attention**` : '')
    + (grand.skipped ? `, ${grand.skipped} not run this time` : '')
    + '.', '');
  if (loc) {
    L.push(`The application and its tests come to **${loc.total.toLocaleString('en-US')} lines of code** across ${loc.totalFiles} ${plural(loc.totalFiles, 'file')}.`, '');
  }

  // ── The numbers ─────────────────────────────────────────────────────────────
  const tokensCell = tel && tel.available ? `${tel.tokens.toLocaleString('en-US')} tokens` : 'No AI was used in these checks';
  const costCell = tel && tel.costUsd != null ? `$${Number(tel.costUsd).toFixed(2)}` : '—';
  L.push('## The numbers', '');
  L.push('| | |', '|---|---|');
  L.push(`| Result | ${grand.failed === 0 ? '✅ All clear' : '❌ Needs attention'} |`);
  L.push(`| Checks run | ${grand.total} |`);
  L.push(`| Passed | ${grand.passed} |`);
  L.push(`| Need attention | ${grand.failed} |`);
  L.push(`| Not run this time | ${grand.skipped} |`);
  L.push(`| Time taken | ${fmtDuration(model.totalMs)} |`);
  if (loc) L.push(`| Lines of code (app + tests) | ${loc.total.toLocaleString('en-US')} |`);
  L.push(`| AI usage | ${tokensCell} |`);
  if (tel && tel.costUsd != null) L.push(`| Rough AI cost | ${costCell} |`);
  L.push(`| Run by | ${esc(env.runBy)} on ${esc(env.machine)} |`);
  L.push(`| When | ${started.friendly} → finished ${ended.friendlyTime} |`);
  L.push('');

  // ── How each area did ──────────────────────────────────────────────────────
  L.push('## How each area did', '');
  L.push('| Area | Result | Passed | Need attention | Not run |', '|---|:--:|--:|--:|--:|');
  // The always-present QA suite, broken down by area.
  for (const l of model.layers) {
    const icon = l.failed === 0 ? '✅' : '❌';
    L.push(`| ${esc(friendlyArea(l.layer))} | ${icon} | ${l.passed} | ${l.failed} | ${l.skipped} |`);
  }
  // Extra surfaces (only the ones we have data for).
  for (const su of surfaces) {
    if (!su.available) {
      L.push(`| ${esc(su.name)} | — | — | — | — |`);
      continue;
    }
    const icon = su.counts.failed === 0 ? '✅' : '❌';
    L.push(`| ${esc(su.name)} | ${icon} | ${su.counts.passed} | ${su.counts.failed} | ${su.counts.skipped} |`);
  }
  L.push('');
  // Footnotes for surfaces that reused saved data or had none.
  const notes = surfaces.filter(su => su.note);
  if (notes.length) {
    for (const su of notes) L.push(`> **${esc(su.name)}:** ${esc(su.note)}`);
    L.push('');
  }

  // ── Lines of code ────────────────────────────────────────────────────────────
  if (loc) {
    L.push('## Lines of code in the application', '');
    L.push('This counts the code written to build the app and its tests (it ignores blank lines, notes, data files, and the workflow tooling that ships with the template).', '');
    L.push('| Part of the project | Files | Lines of code |', '|---|--:|--:|');
    for (const b of loc.rows) {
      L.push(`| ${esc(b.label)} | ${b.files} | ${b.lines.toLocaleString('en-US')} |`);
    }
    L.push(`| **Total** | **${loc.totalFiles}** | **${loc.total.toLocaleString('en-US')}** |`);
    L.push('');
  }

  // ── What needs attention ──────────────────────────────────────────────────────
  const failed = model.tests.filter(t => t.result === 'failed');
  if (failed.length) {
    L.push('## What needs attention', '');
    L.push(`${failed.length} ${plural(failed.length, 'check')} did not pass. Here is what each one was checking and what went wrong:`, '');
    for (const t of failed) {
      L.push(`### ❌ ${esc(t.title)}`, `_Area: ${esc(friendlyArea(t.layer))}_`, '');
      L.push('```', (t.message || '(no details were captured)').trim(), '```', '');
    }
  } else {
    L.push('## What needs attention', '');
    L.push('Nothing — every check passed. 🎉', '');
  }

  // ── Every check we ran ─────────────────────────────────────────────────────────
  L.push('## Every check we ran', '');
  L.push('The full list, in case you want the detail. ✅ passed · ❌ needs attention · ⏭️ not run.', '');
  L.push('| Check | Area | Result | Time |', '|---|---|:--:|--:|');
  for (const t of model.tests) {
    L.push(`| ${esc(t.title)} | ${esc(friendlyArea(t.layer))} | ${resultIcon(t.result)} | ${fmtDuration(t.duration)} |`);
  }
  L.push('');

  // ── Footer ─────────────────────────────────────────────────────────────────────
  L.push('---', '');
  L.push(`<sub>Generated ${s.iso} · QA suite version ${esc(version)} · `
    + `code version ${esc(env.commit || 'n/a')} on branch ${esc(env.branch || 'n/a')} · `
    + `Node ${esc(env.node)}${env.vitest ? `, Vitest ${esc(env.vitest)}` : ''}. `
    + `Time taken is the real wall-clock time; checks run side by side, so it is shorter than adding up each one.</sub>`, '');

  return L.join('\n');
}

// ----------------------------------------------------------------------------
// sidecar + index
// ----------------------------------------------------------------------------
// Each run drops a small JSON sidecar next to its report; the index is rebuilt
// from all sidecars (robust — no Markdown re-parsing).
function writeSidecar(reportFile, meta) {
  try { fs.writeFileSync(reportFile.replace(/\.md$/, '.json'), JSON.stringify(meta, null, 2)); }
  catch { /* best-effort */ }
}

function rebuildIndex(outDir) {
  let rows = [];
  try {
    rows = fs.readdirSync(outDir)
      .filter(f => /^report-.*\.json$/.test(f))
      .map(f => { try { return JSON.parse(fs.readFileSync(path.join(outDir, f), 'utf8')); } catch { return null; } })
      .filter(Boolean);
  } catch { return null; }

  // Newest first (the fileStamp is a sortable YYYYMMDD-HHMM string).
  rows.sort((a, b) => (String(b.fileStamp)).localeCompare(String(a.fileStamp)));

  const L = [];
  L.push('# Test report history', '');
  L.push('Every test run we have recorded, newest at the top. Click a date to open the full report.', '');
  L.push('_This page rebuilds itself after every test run._', '');

  if (rows.length === 0) {
    L.push('No runs recorded yet.');
  } else {
    const latest = rows[0];
    const verdict = latest.overall === 'pass' ? '✅ All clear' : '❌ Needs attention';
    L.push(`**Most recent run:** ${verdict} — ${latest.counts.passed} passed, ${latest.counts.failed} need attention `
      + `· [open the full report](${esc(latest.report)})`, '');
    L.push('| When | Result | Passed | Need attention | Not run | Time | Lines of code | AI cost | Run by | Report |',
           '|---|:--:|--:|--:|--:|--:|--:|--:|---|---|');
    for (const r of rows) {
      const icon = r.overall === 'pass' ? '✅' : '❌';
      const loc = r.linesOfCode != null ? Number(r.linesOfCode).toLocaleString('en-US') : '—';
      const cost = r.costUsd != null ? `$${Number(r.costUsd).toFixed(2)}` : '—';
      const when = r.runFriendly || r.runIso;
      L.push(`| ${esc(when)} | ${icon} | ${r.counts.passed} | ${r.counts.failed} | ${r.counts.skipped} | ${fmtDuration(r.durationMs)} | ${loc} | ${cost} | ${esc(r.runBy)} | [open](${esc(r.report)}) |`);
    }
  }
  const indexFile = path.join(outDir, 'index.md');
  try { fs.writeFileSync(indexFile, L.join('\n')); return indexFile; } catch { return null; }
}

// ----------------------------------------------------------------------------
// main
// ----------------------------------------------------------------------------
function main() {
  const opts = parseArgs(process.argv);
  const now = new Date();
  const version = pkgVersion();

  const json = loadResults(opts);
  const model = buildModel(json);
  const env = environment();
  const tel = telemetryTotals(opts.telemetryRoot);
  const loc = countLinesOfCode();

  // Gather the extra surfaces (run if asked; otherwise reuse the saved result).
  const surfaces = [
    gatherSurface('web', "The app's own tests", opts.withWeb, runWebVitest, summarizeVitestJson),
    gatherSurface('e2e', 'Using the app like a person would', opts.withE2e, runE2e, summarizePlaywrightJson),
    gatherSurface('gates', 'Final quality gates', opts.withGates, runGates, summarizeGatesJson),
  ];

  const md = render(model, env, tel, version, now, { loc, surfaces });

  const stamp = stampParts(now);
  const outFile = opts.out || path.join(OUT_DIR, `report-${version}-${stamp.file}.md`);
  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, md);

  // Combined failure count across every surface that has data.
  let combinedFailed = model.counts.failed;
  for (const su of surfaces) if (su.available) combinedFailed += su.counts.failed;

  // Sidecar metadata + rebuilt index (skip both when --out points elsewhere).
  let indexFile = null;
  if (!opts.out) {
    writeSidecar(outFile, {
      version, fileStamp: stamp.file, runIso: stamp.iso, runFriendly: stamp.friendly,
      overall: combinedFailed === 0 ? 'pass' : 'fail',
      counts: model.counts, durationMs: model.totalMs,
      linesOfCode: loc ? loc.total : null,
      runBy: env.runBy, machine: env.machine,
      tokens: tel && tel.available ? tel.tokens : null,
      costUsd: tel && tel.costUsd != null ? tel.costUsd : null,
      report: path.basename(outFile),
    });
    indexFile = rebuildIndex(OUT_DIR);
  }

  if (opts.open) {
    openReport(outFile);
    if (indexFile) openReport(indexFile);
  }

  console.log(JSON.stringify({
    status: 'ok',
    report: outFile,
    index: indexFile,
    opened: opts.open,
    overall: combinedFailed === 0 ? 'pass' : 'fail',
    counts: model.counts,
    linesOfCode: loc ? loc.total : null,
    durationMs: model.totalMs,
  }, null, 2));

  // When asked (e.g. wired into `npm test`), reflect test failures in the exit code.
  if (opts.exitCode && combinedFailed > 0) process.exit(1);
}

// Export pure functions for unit testing; only run when invoked directly.
module.exports = {
  buildModel, render, fmtDuration, layerOf, environment, friendlyArea,
  countLinesOfCode, summarizeVitestJson, summarizePlaywrightJson, summarizeGatesJson,
};
if (require.main === module) main();
