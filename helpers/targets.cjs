'use strict';
/**
 * targets.cjs — resolve a named template channel to its repo + contract.
 *
 * Reads ../targets.json (the channel list). One place so `run-target.cjs`,
 * `compare-targets.cjs`, and the Tier-1 channel tests all agree. Pure lookups —
 * an unknown name is a loud error, never a silent default onto the wrong repo.
 */

const fs = require('fs');
const path = require('path');

const QA_ROOT = path.resolve(__dirname, '..');
const TARGETS_PATH = path.join(QA_ROOT, 'targets.json');
const TARGETS_DIR = path.join(QA_ROOT, '.targets');

/**
 * Ensure the throwaway-checkout dir exists AND is marked CommonJS.
 *
 * `.targets/` lives inside this suite, whose own package.json declares
 * `"type": "module"`. Without a boundary, Node resolves that field when it loads
 * a cloned template's CommonJS script (`.claude/scripts/**.js`, which use
 * `require`/`module.exports`) — walking up past `.targets/` to the suite root — and
 * treats the script as ESM, so it throws `require is not defined` at load. Dropping
 * a `{"type":"commonjs"}` marker at `.targets/` stops that walk-up at the checkout
 * boundary, so template scripts load as the CommonJS they are. Vitest's own `.ts`
 * tests are transformed by Vite regardless, so this marker never affects them.
 *
 * Idempotent: safe to call before every clone. Returns the dir.
 */
function ensureTargetsDir(dir = TARGETS_DIR) {
  fs.mkdirSync(dir, { recursive: true });
  const marker = path.join(dir, 'package.json');
  if (!fs.existsSync(marker)) {
    fs.writeFileSync(marker, JSON.stringify({ type: 'commonjs' }, null, 2) + '\n');
  }
  return dir;
}

/** @typedef {{ repo: string, contract: string, description?: string }} Target */

/** Load and return the raw targets map ({ name → Target }). Throws if the file is missing/invalid. */
function loadTargets(file = TARGETS_PATH) {
  const raw = JSON.parse(fs.readFileSync(file, 'utf8'));
  const targets = raw.targets || {};
  if (!targets || typeof targets !== 'object' || Object.keys(targets).length === 0) {
    throw new Error(`targets.json has no "targets" — nothing to aim at (${file})`);
  }
  return targets;
}

/** The list of known channel names, sorted. */
function targetNames(file = TARGETS_PATH) {
  return Object.keys(loadTargets(file)).sort();
}

/**
 * Resolve one named channel. Throws a clear, actionable error for an unknown name
 * (listing the known ones) rather than defaulting — a silent default would aim the
 * whole suite at the wrong repo.
 * @param {string} name
 * @returns {Target & { name: string }}
 */
function resolveTarget(name, file = TARGETS_PATH) {
  const targets = loadTargets(file);
  const t = targets[name];
  if (!t) {
    const known = Object.keys(targets).sort().join(', ') || '(none)';
    throw new Error(`Unknown target "${name}". Known targets: ${known}. Add it to targets.json to test a new template.`);
  }
  if (!t.repo) throw new Error(`Target "${name}" has no "repo" URL in targets.json.`);
  if (!t.contract) throw new Error(`Target "${name}" has no "contract" file in targets.json.`);
  return { name, ...t };
}

module.exports = { loadTargets, targetNames, resolveTarget, ensureTargetsDir, TARGETS_PATH, TARGETS_DIR, QA_ROOT };
