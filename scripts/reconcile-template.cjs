#!/usr/bin/env node
/**
 * reconcile-template.cjs — the "what changed?" helper.
 *
 * Run this right after the template changes. It compares the pinned expectations
 * in template-contract.json against the template's own LIVE values, and prints a
 * plain-English checklist of exactly what to update (and where). No test
 * knowledge needed — it names the file and the list to edit.
 *
 * Usage:
 *   node scripts/reconcile-template.cjs            # print the checklist (always exit 0)
 *   node scripts/reconcile-template.cjs --check    # exit non-zero if anything drifted (for CI)
 *   REPO_ROOT=/path/to/repo node scripts/reconcile-template.cjs   # point at another checkout
 *
 * What it compares (each pinned list ↔ its live source in the template):
 *   stages           ↔ .claude/scripts/lib/epic-state.js  (EPIC_PHASES)
 *   storyStatuses    ↔ .claude/scripts/lib/epic-state.js  (STORY_STATUS_VALUES)
 *   e2eStatusesCore  ↔ .claude/scripts/lib/epic-state.js  (E2E_STATUS_VALUES)   [subset check]
 *   docNameIds       ↔ .claude/shared/generated-doc-conventions.json (conventions[].id)
 */
'use strict';

const fs = require('fs');
const path = require('path');

const QA_ROOT = path.resolve(__dirname, '..');
const TARGET_ROOT = process.env.REPO_ROOT
  ? path.resolve(process.env.REPO_ROOT)
  : path.resolve(QA_ROOT, '..');
const CONTRACT_PATH = path.join(QA_ROOT, 'template-contract.json');
const CHECK_MODE = process.argv.includes('--check');

// Tiny ANSI helpers (skipped when output isn't a TTY).
const useColour = process.stdout.isTTY;
const c = (code, s) => (useColour ? `[${code}m${s}[0m` : s);
const bold = (s) => c('1', s);
const green = (s) => c('32', s);
const red = (s) => c('31', s);
const dim = (s) => c('2', s);

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

/** Read the template's live epic-state enums, or null when the template is absent. */
function liveEpicState() {
  const lib = path.join(TARGET_ROOT, '.claude', 'scripts', 'lib', 'epic-state.js');
  if (!fs.existsSync(lib)) return null;
  // Dynamic require of the template under test (path resolved at runtime).
  const mod = require(lib);
  return {
    stages: mod.EPIC_PHASES,
    storyStatuses: mod.STORY_STATUS_VALUES,
    e2eStatuses: mod.E2E_STATUS_VALUES,
  };
}

/** Read the template's live generated-doc IDs, or null when absent. */
function liveDocNameIds() {
  const p = path.join(TARGET_ROOT, '.claude', 'shared', 'generated-doc-conventions.json');
  if (!fs.existsSync(p)) return null;
  return readJson(p).conventions.map((c2) => c2.id);
}

function listNames(dir, suffix) {
  const d = path.join(TARGET_ROOT, '.claude', dir);
  if (!fs.existsSync(d)) return [];
  return fs
    .readdirSync(d)
    .filter((f) => f.endsWith(suffix) && f !== 'README.md' && !f.startsWith('_'))
    .map((f) => f.replace(suffix, ''))
    .sort();
}

// ---- comparison ----

let driftCount = 0;

/** Compare an ordered list (order matters, e.g. stages). */
function reportOrdered(title, listName, pinned, live) {
  const added = live.filter((x) => !pinned.includes(x));
  const removed = pinned.filter((x) => !live.includes(x));
  const sameSet = added.length === 0 && removed.length === 0;
  const orderChanged = sameSet && pinned.join('|') !== live.join('|');

  if (sameSet && !orderChanged) {
    console.log(`  ${green('✓')} ${bold(title)} — up to date`);
    return;
  }
  driftCount++;
  console.log(`  ${red('✗')} ${bold(title)} — CHANGED:`);
  for (const x of added) {
    console.log(`      • the template ADDED "${x}"  ${dim(`→ add it to "${listName}" in template-contract.json`)}`);
  }
  for (const x of removed) {
    console.log(`      • the template REMOVED "${x}"  ${dim(`→ remove it from "${listName}"`)}`);
  }
  if (orderChanged) {
    console.log(`      • the ORDER changed  ${dim(`→ set "${listName}" to: ${JSON.stringify(live)}`)}`);
  }
}

/** Compare an unordered set (order doesn't matter, e.g. statuses, doc IDs). */
function reportSet(title, listName, pinned, live) {
  const added = live.filter((x) => !pinned.includes(x));
  const removed = pinned.filter((x) => !live.includes(x));
  if (added.length === 0 && removed.length === 0) {
    console.log(`  ${green('✓')} ${bold(title)} — up to date`);
    return;
  }
  driftCount++;
  console.log(`  ${red('✗')} ${bold(title)} — CHANGED:`);
  for (const x of added) {
    console.log(`      • the template ADDED "${x}"  ${dim(`→ add it to "${listName}" in template-contract.json`)}`);
  }
  for (const x of removed) {
    console.log(`      • the template REMOVED "${x}"  ${dim(`→ remove it from "${listName}"`)}`);
  }
}

/** Compare a "must contain" subset (pinned core must all still exist live). */
function reportSubset(title, listName, pinnedCore, live) {
  const missing = pinnedCore.filter((x) => !live.includes(x));
  if (missing.length === 0) {
    const extra = live.filter((x) => !pinnedCore.includes(x));
    const note = extra.length ? dim(`  (template also has: ${extra.join(', ')})`) : '';
    console.log(`  ${green('✓')} ${bold(title)} — all pinned core values present${note}`);
    return;
  }
  driftCount++;
  console.log(`  ${red('✗')} ${bold(title)} — CHANGED:`);
  for (const x of missing) {
    console.log(`      • the template no longer has core value "${x}"  ${dim(`→ update "${listName}"`)}`);
  }
}

// ---- run ----

function main() {
  console.log(bold('\nTemplate reconcile — pinned expectations vs the live template'));
  console.log(dim(`Target template: ${TARGET_ROOT}`));
  console.log(dim(`Expectations file: ${CONTRACT_PATH}\n`));

  const contract = readJson(CONTRACT_PATH);
  const epic = liveEpicState();
  const docIds = liveDocNameIds();

  if (!epic && !docIds) {
    console.log(red('No template found at the target — nothing to compare.'));
    console.log(dim('Point at a checkout with REPO_ROOT=/path/to/repo, or run from inside a Stadium-8 repo.\n'));
    process.exit(0);
  }

  console.log(bold('Pinned lists'));
  if (epic) {
    reportOrdered('Stages (order matters)', 'stages', contract.stages, epic.stages);
    reportSet('Story statuses', 'storyStatuses', contract.storyStatuses, epic.storyStatuses);
    reportSubset('E2E statuses (core)', 'e2eStatusesCore', contract.e2eStatusesCore, epic.e2eStatuses);
  } else {
    console.log(dim('  (epic-state.js not found — skipped stages / statuses)'));
  }
  if (docIds) {
    reportSet('Document names', 'docNameIds', contract.docNameIds, docIds);
  } else {
    console.log(dim('  (generated-doc-conventions.json not found — skipped document names)'));
  }

  // Informational — not pinned, shown so new/removed ones are visible at a glance.
  console.log(bold('\nOn disk right now (not pinned — for awareness)'));
  const agents = listNames('agents', '.md').filter((n) => n !== 'tone-guide');
  const commands = listNames('commands', '.md');
  console.log(`  Agents (${agents.length}): ${dim(agents.join(', '))}`);
  console.log(`  Commands (${commands.length}): ${dim(commands.join(', '))}`);

  console.log('');
  if (driftCount === 0) {
    console.log(green(bold('✓ Everything lines up — nothing to update.\n')));
    process.exit(0);
  }
  console.log(
    red(bold(`✗ ${driftCount} list${driftCount === 1 ? '' : 's'} changed.`)) +
      ` Edit ${bold('template-contract.json')} as noted above, then re-run.\n`,
  );
  process.exit(CHECK_MODE ? 1 : 0);
}

main();
