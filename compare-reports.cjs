#!/usr/bin/env node
/**
 * compare-reports.cjs — quick visual comparison of the last N test-report runs.
 *
 * Reads the report-*.json sidecars in QA-TESTS/TestResults/ (written by
 * generate-test-report.cjs), takes the most recent N (default 5), and prints
 * two ASCII bar charts to the terminal:
 *   1. Total build time per run
 *   2. Total tokens used per run
 * ...plus a small table (when | time | tokens | cost | pass rate | run by).
 *
 * This does not recompute anything — it only reads the numbers the report
 * generator already saved. Token/cost columns show "—" for runs that were
 * generated without --telemetry-root (no AI usage recorded).
 *
 * Usage:
 *   node scripts/compare-reports.cjs            # last 5 runs
 *   node scripts/compare-reports.cjs --last 8   # last 8 runs
 *   node scripts/compare-reports.cjs --json     # machine-readable, no charts
 */
'use strict';

const fs = require('fs');
const path = require('path');

const OUT_DIR = path.resolve(__dirname, '..', 'TestResults');

function parseArgs(argv) {
  const a = argv.slice(2);
  const o = { last: 5, json: false };
  for (let i = 0; i < a.length; i++) {
    if (a[i] === '--last') o.last = Math.max(1, parseInt(a[++i], 10) || 5);
    else if (a[i] === '--json') o.json = true;
  }
  return o;
}

function fmtDuration(ms) {
  if (ms == null || !Number.isFinite(ms)) return '—';
  if (ms < 1000) return `${Math.round(ms)}ms`;
  const s = ms / 1000;
  if (s < 60) return `${Math.round(s * 10) / 10}s`;
  const m = Math.floor(s / 60);
  return `${m}m ${Math.round(s - m * 60)}s`;
}

function fmtTokens(t) {
  return t == null ? '—' : Number(t).toLocaleString('en-US');
}

/** Read every report-*.json sidecar, newest first by fileStamp. */
function loadSidecars() {
  let files;
  try {
    files = fs.readdirSync(OUT_DIR).filter(f => /^report-.*\.json$/.test(f));
  } catch {
    return [];
  }
  const rows = files
    .map(f => {
      try { return JSON.parse(fs.readFileSync(path.join(OUT_DIR, f), 'utf8')); }
      catch { return null; }
    })
    .filter(Boolean);
  rows.sort((a, b) => String(b.fileStamp).localeCompare(String(a.fileStamp)));
  return rows;
}

/** A single horizontal bar, scaled to the largest value in the set. */
function bar(value, max, width) {
  if (value == null || !Number.isFinite(value) || max <= 0) return '';
  const filled = Math.max(value > 0 ? 1 : 0, Math.round((value / max) * width));
  return '█'.repeat(filled);
}

function chart(title, rows, valueOf, fmt) {
  const vals = rows.map(valueOf).filter(v => Number.isFinite(v));
  const max = vals.length ? Math.max(...vals) : 0;
  const labelW = Math.max(...rows.map(r => labelOf(r).length), 4);
  const out = [`  ${title}`, '  ' + '─'.repeat(title.length)];
  if (!vals.length) {
    out.push('  (no data recorded for these runs)');
    return out.join('\n');
  }
  for (const r of rows) {
    const v = valueOf(r);
    const label = labelOf(r).padEnd(labelW);
    const b = bar(v, max, 32);
    const shown = Number.isFinite(v) ? fmt(v) : '—';
    out.push(`  ${label} │ ${b} ${shown}`);
  }
  return out.join('\n');
}

function labelOf(r) {
  // Prefer a short date label from the friendly stamp, else the fileStamp.
  return r.runFriendly || r.runIso || r.fileStamp || '?';
}

function main() {
  const opts = parseArgs(process.argv);
  const all = loadSidecars();
  const rows = all.slice(0, opts.last);

  if (opts.json) {
    console.log(JSON.stringify({
      count: rows.length,
      requested: opts.last,
      runs: rows.map(r => ({
        when: labelOf(r), fileStamp: r.fileStamp,
        durationMs: r.durationMs ?? null, tokens: r.tokens ?? null,
        costUsd: r.costUsd ?? null, counts: r.counts || null, runBy: r.runBy || null,
      })),
    }, null, 2));
    return;
  }

  console.log('');
  console.log(`Comparison of the last ${rows.length} test ${rows.length === 1 ? 'report' : 'reports'}` +
    (all.length > rows.length ? ` (of ${all.length} on record)` : '') + ':');
  console.log('');

  if (rows.length === 0) {
    console.log('  No reports found in TestResults/. Run a report first:');
    console.log('    npm run report');
    console.log('');
    return;
  }

  // Charts read oldest→newest so the trend reads left-to-right top-to-bottom.
  const chrono = [...rows].reverse();

  console.log(chart('Total build time per run', chrono, r => r.durationMs, fmtDuration));
  console.log('');
  console.log(chart('Total tokens used per run', chrono, r => r.tokens, fmtTokens));
  console.log('');

  // Summary table.
  const pad = (s, n) => String(s).padEnd(n);
  const padL = (s, n) => String(s).padStart(n);
  console.log('  When                       Time        Tokens        Cost     Pass    By');
  console.log('  ' + '─'.repeat(74));
  for (const r of rows) {
    const c = r.counts || {};
    const passRate = c.total ? `${c.passed}/${c.total}` : '—';
    const cost = r.costUsd != null ? `$${Number(r.costUsd).toFixed(2)}` : '—';
    console.log('  ' +
      pad(labelOf(r), 26) + ' ' +
      padL(fmtDuration(r.durationMs), 9) + '  ' +
      padL(fmtTokens(r.tokens), 12) + '  ' +
      padL(cost, 8) + '  ' +
      padL(passRate, 6) + '  ' +
      pad(r.runBy || '—', 10));
  }
  console.log('');

  // One-line trend read, when we have at least two runs with the metric.
  trendLine('Build time', chrono, r => r.durationMs, fmtDuration, true);
  trendLine('Token use', chrono, r => r.tokens, fmtTokens, true);
  console.log('');
}

function trendLine(name, chrono, valueOf, fmt, lowerIsBetter) {
  const pts = chrono.map(valueOf).filter(v => Number.isFinite(v));
  if (pts.length < 2) return;
  const first = pts[0], last = pts[pts.length - 1];
  if (first === 0) return;
  const pct = Math.round(((last - first) / first) * 100);
  const dir = pct === 0 ? 'unchanged'
    : pct < 0 ? `down ${Math.abs(pct)}%`
    : `up ${pct}%`;
  const verdict = pct === 0 ? '→ flat'
    : (lowerIsBetter ? (pct < 0 ? '✓ improving' : '✗ worse')
                     : (pct > 0 ? '✓ improving' : '✗ worse'));
  console.log(`  ${name}: ${fmt(first)} → ${fmt(last)} (${dir})  ${verdict}`);
}

if (require.main === module) main();
module.exports = { loadSidecars, fmtDuration, fmtTokens };
