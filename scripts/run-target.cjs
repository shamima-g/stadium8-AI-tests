#!/usr/bin/env node
'use strict';
/**
 * run-target.cjs — the "tune in" button. One command tests any template at any
 * version:
 *
 *   node scripts/run-target.cjs --target dev --ref v1.1.0
 *   npm run test:target -- --target release --ref v1.0.0
 *
 * What it does, in order:
 *   1. Resolve the named channel from targets.json → its repo URL + contract.
 *   2. Clone that repo at that ref into a throwaway checkout under .targets/
 *      (gitignored, always fresh — never a stale prior checkout).
 *   3. Print the Layer-A drift banner: the version the suite was written for
 *      (VERSION) vs the version under test (template-version.json), the gap, and
 *      the changelog entries that explain it.
 *   4. Run the report generator with REPO_ROOT pointed at the checkout and
 *      QA_TARGET set (so each version is judged against its OWN recipe), filing
 *      results under TestResults/<target>-<ref>/.
 *
 * Flags: --target <name> (required), --ref <tag|branch> (default: repo default
 * branch), --reuse (skip re-clone if the checkout already exists), plus any of
 * the report flags (--with-web, --with-e2e, --with-gates, --no-open, --exit-code)
 * which are passed straight through.
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { resolveTarget, ensureTargetsDir } = require('../helpers/targets.cjs');
const { versionGap } = require('../helpers/template-version.cjs');
const { parseChangelog, entriesBetween } = require('../helpers/changelog.cjs');

const QA_ROOT = path.resolve(__dirname, '..');
const TARGETS_DIR = path.join(QA_ROOT, '.targets');
const REPORT = path.join(QA_ROOT, 'scripts', 'generate-test-report.cjs');

const PASSTHROUGH = new Set(['--with-web', '--with-e2e', '--with-gates', '--no-open', '--exit-code']);

function parseArgs(argv) {
  const a = argv.slice(2);
  const o = { target: null, ref: null, reuse: false, passthrough: [] };
  for (let i = 0; i < a.length; i++) {
    if (a[i] === '--target') o.target = a[++i];
    else if (a[i] === '--ref') o.ref = a[++i];
    else if (a[i] === '--reuse') o.reuse = true;
    else if (PASSTHROUGH.has(a[i])) o.passthrough.push(a[i]);
  }
  return o;
}

function die(msg) {
  console.error(`\n[run-target] ${msg}\n`);
  process.exit(2);
}

/** Clone repo@ref into destination. Always fresh unless --reuse. Fatal on failure. */
function checkout(repo, ref, dest, reuse) {
  if (fs.existsSync(dest)) {
    if (reuse) {
      console.log(`[run-target] reusing existing checkout at ${dest}`);
      return;
    }
    fs.rmSync(dest, { recursive: true, force: true });
  }
  ensureTargetsDir(path.dirname(dest));
  const args = ['clone', '--depth', '1'];
  if (ref) args.push('--branch', ref);
  args.push(repo, dest);
  console.log(`[run-target] git ${args.join(' ')}`);
  const r = spawnSync('git', args, { stdio: 'inherit' });
  if (r.status !== 0) {
    // Never leave a half-clone behind that a later run might mistake for good.
    fs.rmSync(dest, { recursive: true, force: true });
    die(`clone failed for ${repo} @ ${ref || '(default branch)'} — check the ref exists. No stale checkout left behind.`);
  }
}

/** Print the Layer-A drift banner and return the gap for the sidecar. */
function driftBanner(targetRoot, ref) {
  const gap = versionGap(targetRoot, QA_ROOT);
  const line = '─'.repeat(64);
  console.log(`\n${line}`);
  console.log('  VERSION GAP (Layer A)');
  console.log(`  Suite written for : ${gap.suite ?? 'unknown'}   (VERSION)`);
  console.log(`  Template under test: ${gap.template ?? 'unknown'}   (${gap.source})`);
  if (gap.direction === 'in-sync') {
    console.log('  Gap               : none — suite and template are the same version.');
  } else if (gap.direction === 'unknown') {
    console.log('  Gap               : unknown — a version could not be read. Treat results with care.');
  } else {
    const ahead = gap.direction === 'suite-ahead' ? 'the SUITE is newer' : 'the TEMPLATE is newer';
    console.log(`  Gap               : ${ahead} — see the changelog entries below.`);
    console.log('  Failures touching these changes may be the GAP, not a bug.');
    // Explain the gap from the template's own changelog, when present.
    const clPath = path.join(targetRoot, 'CHANGELOG.md');
    if (fs.existsSync(clPath) && gap.suite && gap.template) {
      const versions = parseChangelog(fs.readFileSync(clPath, 'utf8'));
      const lo = gap.direction === 'suite-ahead' ? gap.template : gap.suite;
      const hi = gap.direction === 'suite-ahead' ? gap.suite : gap.template;
      const entries = entriesBetween(versions, lo, hi);
      if (entries.length) {
        console.log(`\n  What changed between ${lo} and ${hi} (${entries.length} entries):`);
        for (const e of entries.slice(0, 20)) {
          const lead = e.text.length > 90 ? e.text.slice(0, 87) + '…' : e.text;
          console.log(`    • [${e.version} ${e.type}] ${lead}`);
        }
        if (entries.length > 20) console.log(`    …and ${entries.length - 20} more (see CHANGELOG.md).`);
      }
    }
  }
  console.log(`${line}\n`);
  return gap;
}

function main() {
  const opts = parseArgs(process.argv);
  if (!opts.target) die('missing --target <name>. Known targets live in targets.json.');

  let target;
  try {
    target = resolveTarget(opts.target);
  } catch (e) {
    die(e.message);
  }

  const ref = opts.ref || null;
  const label = `${opts.target}-${ref || 'default'}`;
  const dest = path.join(TARGETS_DIR, label);

  console.log(`[run-target] target=${opts.target} repo=${target.repo} ref=${ref || '(default branch)'}`);
  checkout(target.repo, ref, dest, opts.reuse);
  driftBanner(dest, ref);

  // Aim the suite: REPO_ROOT → the checkout, QA_TARGET → which recipe to judge by.
  const env = { ...process.env, REPO_ROOT: dest, QA_TARGET: opts.target };
  const reportArgs = [
    REPORT,
    '--label', label,
    '--target', opts.target,
    '--ref', ref || 'default',
    ...opts.passthrough,
  ];
  console.log(`[run-target] node ${path.basename(REPORT)} ${reportArgs.slice(1).join(' ')}`);
  const r = spawnSync('node', reportArgs, { cwd: QA_ROOT, env, stdio: 'inherit' });
  process.exit(typeof r.status === 'number' ? r.status : 1);
}

main();
