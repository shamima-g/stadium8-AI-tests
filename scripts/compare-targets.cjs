#!/usr/bin/env node
'use strict';
/**
 * compare-targets.cjs — the "is dev safe to promote to release?" step.
 *
 * Lines two template checkouts up against each other, and for every difference
 * asks the changelog "was this change documented?". The verdict is three-way:
 *
 *   GREEN  — the two templates are identical.
 *   AMBER  — they differ, but every difference is EXPLAINED by a changelog entry
 *            → this is the promote checklist (documented work waiting to ship).
 *            Does NOT fail the run.
 *   RED    — a difference has NO changelog entry behind it → UNEXPLAINED drift.
 *            Fails the run (exit 1).
 *
 * (This refines workflow-tests.md area R / Decision 1 per the agreed "explained → amber" rule.)
 *
 * Usage:
 *   node scripts/compare-targets.cjs --a release --a-ref v1.0.0 --b dev --b-ref v1.1.0
 *   node scripts/compare-targets.cjs --a-root <dir> --b-root <dir>   # already-checked-out
 *
 * The pure comparison functions (diffLive / attribute / verdict) are exported for
 * Tier-1 tests — they take plain data, so both good and broken cases are trivial
 * to feed without cloning anything.
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { readLive } = require('../helpers/template-live.cjs');
const { parseChangelog, findExplaining } = require('../helpers/changelog.cjs');
const { resolveTarget } = require('../helpers/targets.cjs');

const QA_ROOT = path.resolve(__dirname, '..');
const TARGETS_DIR = path.join(QA_ROOT, '.targets');

// Lists compared. "ordered" ones also flag an order-only change.
const LISTS = [
  { key: 'stages', label: 'Stages', ordered: true },
  { key: 'storyStatuses', label: 'Story statuses', ordered: false },
  { key: 'e2eStatuses', label: 'E2E statuses', ordered: false },
  { key: 'docNameIds', label: 'Document names', ordered: false },
  { key: 'agents', label: 'Agents', ordered: false },
  { key: 'commands', label: 'Commands', ordered: false },
];

/**
 * Diff two readLive() results. Returns a flat list of differences:
 *   { list, value, side: 'a'|'b' }  — `value` exists only on `side`.
 * plus order-only notes for ordered lists whose sets match but order differs.
 */
function diffLive(aLive, bLive) {
  const diffs = [];
  for (const { key, ordered } of LISTS) {
    const a = aLive[key] || [];
    const b = bLive[key] || [];
    for (const x of b) if (!a.includes(x)) diffs.push({ list: key, value: x, side: 'b' });
    for (const x of a) if (!b.includes(x)) diffs.push({ list: key, value: x, side: 'a' });
    if (ordered) {
      const sameSet = a.length === b.length && a.every((x) => b.includes(x));
      if (sameSet && a.join('|') !== b.join('|')) {
        diffs.push({ list: key, value: '(order)', side: 'both', order: true });
      }
    }
  }
  return diffs;
}

/**
 * Attribute each diff to a changelog entry on the side that HAS the value.
 * @param {Array} diffs - from diffLive
 * @param {{a: Array, b: Array}} entriesBySide - parsed changelog entries per side
 * @returns diffs annotated with { explained: boolean, by?: string, byVersion?: string }
 */
function attribute(diffs, entriesBySide) {
  return diffs.map((d) => {
    // Order-only changes can't be pinned to a symbol; treat as needing review (unexplained).
    if (d.order) return { ...d, explained: false };
    const entries = d.side === 'a' ? entriesBySide.a : entriesBySide.b;
    const hit = findExplaining(entries || [], d.value);
    return hit
      ? { ...d, explained: true, by: hit.text, byVersion: hit.version }
      : { ...d, explained: false };
  });
}

/** Overall verdict from attributed diffs. */
function verdict(attributed) {
  if (attributed.length === 0) return 'green';
  return attributed.every((d) => d.explained) ? 'amber' : 'red';
}

// ---- CLI plumbing ----

function parseArgs(argv) {
  const a = argv.slice(2);
  const o = { a: null, aRef: null, aRoot: null, b: null, bRef: null, bRoot: null, out: null };
  for (let i = 0; i < a.length; i++) {
    if (a[i] === '--a') o.a = a[++i];
    else if (a[i] === '--a-ref') o.aRef = a[++i];
    else if (a[i] === '--a-root') o.aRoot = a[++i];
    else if (a[i] === '--b') o.b = a[++i];
    else if (a[i] === '--b-ref') o.bRef = a[++i];
    else if (a[i] === '--b-root') o.bRoot = a[++i];
    else if (a[i] === '--out') o.out = a[++i];
  }
  return o;
}

function die(msg) {
  console.error(`\n[compare-targets] ${msg}\n`);
  process.exit(2);
}

/** Ensure a checkout exists for a named target@ref; clone if missing. Returns its root. */
function ensureCheckout(name, ref) {
  const target = resolveTarget(name);
  const label = `${name}-${ref || 'default'}`;
  const dest = path.join(TARGETS_DIR, label);
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(TARGETS_DIR, { recursive: true });
    const args = ['clone', '--depth', '1'];
    if (ref) args.push('--branch', ref);
    args.push(target.repo, dest);
    console.log(`[compare-targets] git ${args.join(' ')}`);
    const r = spawnSync('git', args, { stdio: 'inherit' });
    if (r.status !== 0) {
      fs.rmSync(dest, { recursive: true, force: true });
      die(`clone failed for ${target.repo} @ ${ref || '(default)'}`);
    }
  }
  return dest;
}

function changelogEntries(root) {
  const p = path.join(root, 'CHANGELOG.md');
  if (!fs.existsSync(p)) return [];
  return parseChangelog(fs.readFileSync(p, 'utf8')).flatMap((v) =>
    v.entries.map((e) => ({ ...e, version: v.version })),
  );
}

function renderReport(labelA, labelB, attributed, v) {
  const L = [];
  const icon = v === 'green' ? '✅' : v === 'amber' ? '🟠' : '🔴';
  L.push(`# Template comparison — ${labelA} vs ${labelB}`, '');
  L.push(`**Verdict: ${icon} ${v.toUpperCase()}**`, '');
  if (v === 'green') {
    L.push('The two templates are identical across every compared list. Safe to promote.', '');
    return L.join('\n');
  }
  const explained = attributed.filter((d) => d.explained);
  const unexplained = attributed.filter((d) => !d.explained);
  if (unexplained.length) {
    L.push(`## 🔴 Unexplained differences (${unexplained.length}) — must resolve before promoting`, '');
    L.push('These differ with **no changelog entry** behind them — undocumented drift or a real break.', '');
    L.push('| List | Value | Only in |', '|---|---|---|');
    for (const d of unexplained) {
      L.push(`| ${d.list} | \`${d.value}\` | ${d.side === 'a' ? labelA : d.side === 'b' ? labelB : 'order differs'} |`);
    }
    L.push('');
  }
  if (explained.length) {
    L.push(`## 🟠 Explained — pending promotion (${explained.length})`, '');
    L.push('Documented work present on one side and not the other. This is the promote checklist.', '');
    L.push('| List | Value | Only in | Explained by |', '|---|---|---|---|');
    for (const d of explained) {
      const only = d.side === 'a' ? labelA : labelB;
      const by = d.byVersion ? `${d.byVersion}: ${d.by}` : d.by;
      L.push(`| ${d.list} | \`${d.value}\` | ${only} | ${String(by).replace(/\|/g, '\\|')} |`);
    }
    L.push('');
  }
  return L.join('\n');
}

function main() {
  const opts = parseArgs(process.argv);
  const rootA = opts.aRoot || (opts.a ? ensureCheckout(opts.a, opts.aRef) : null);
  const rootB = opts.bRoot || (opts.b ? ensureCheckout(opts.b, opts.bRef) : null);
  if (!rootA || !rootB) die('need two sides: --a <name> [--a-ref] and --b <name> [--b-ref], or --a-root/--b-root.');

  const labelA = opts.a ? `${opts.a}-${opts.aRef || 'default'}` : path.basename(rootA);
  const labelB = opts.b ? `${opts.b}-${opts.bRef || 'default'}` : path.basename(rootB);

  const diffs = diffLive(readLive(rootA), readLive(rootB));
  const attributed = attribute(diffs, { a: changelogEntries(rootA), b: changelogEntries(rootB) });
  const v = verdict(attributed);
  const report = renderReport(labelA, labelB, attributed, v);

  const outFile = opts.out || path.join(QA_ROOT, 'TestResults', `compare-${labelA}--vs--${labelB}.md`);
  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, report);

  console.log(report);
  console.log(`\n[compare-targets] report written to ${outFile}`);

  // GREEN/AMBER pass (exit 0); only RED (unexplained drift) fails.
  process.exit(v === 'red' ? 1 : 0);
}

module.exports = { diffLive, attribute, verdict };
if (require.main === module) main();
