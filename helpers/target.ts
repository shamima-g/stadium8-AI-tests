/**
 * Target resolution — which Stadium-8 repo's .claude/ template is under test.
 *
 * The QA-TESTS folder is self-contained (its own package.json / node_modules)
 * and can be carried anywhere. What it *tests*, though, is a Stadium-8
 * template — the scripts, hooks, agents, and schemas under `.claude/`. This
 * module is the single place that decides where that template lives and whether
 * it's present.
 *
 * Resolution order for the target repo root:
 *   1. The REPO_ROOT env var, if set (point the suite at any checkout:
 *      `REPO_ROOT=/path/to/stadium8-repo npm test`). vitest.config.ts passes it
 *      through when present.
 *   2. Otherwise the parent of QA-TESTS — i.e. the repo this folder sits inside.
 *
 * When no template is found, template-dependent suites skip (see
 * describe-template.ts) instead of crashing, so the folder still runs its
 * template-independent tests anywhere.
 */

import fs from 'node:fs';
import path from 'node:path';

/** Absolute path to the repo whose `.claude/` template is under test. */
export const TARGET_ROOT = process.env.REPO_ROOT
  ? path.resolve(process.env.REPO_ROOT)
  : path.resolve(__dirname, '..', '..');

/** The template directory inside the target repo. */
export const TEMPLATE_DIR = path.join(TARGET_ROOT, '.claude');

/**
 * True when a Stadium-8 template is present at the target. We probe
 * `.claude/scripts` specifically — the suite's scripts/hooks/consistency tests
 * all need it, and its absence is the signal to skip them.
 */
export const TEMPLATE_PRESENT = fs.existsSync(path.join(TEMPLATE_DIR, 'scripts'));

/** Human-readable explanation shown once when the template is missing. */
export const NO_TEMPLATE_REASON =
  `No Stadium-8 template (.claude/) found at: ${TARGET_ROOT}\n` +
  `  Template-dependent tests are being SKIPPED.\n` +
  `  To run them, either run QA-TESTS from inside a Stadium-8 repo (with QA-TESTS/\n` +
  `  at the repo root), or point it at one: REPO_ROOT=/path/to/repo npm test\n` +
  `  Template-independent tests (linters, report math, manifest schema) still run.`;
