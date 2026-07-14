/**
 * loadGoldenRun() — loads the committed recording of one real end-to-end workflow run
 * that the Tier-2 recorded-run invariants replay (no live AI at test time).
 *
 * A golden run is captured once by hand (see fixtures/golden-run/README.md) and lives
 * in `fixtures/golden-run/` in one of two forms:
 *
 *   1. `repo.bundle`      — a `git bundle create … --all` of the repo AFTER an epic has
 *                           been built and merged to `main`. Preferred: it carries the
 *                           branch topology and commit history the invariants check.
 *   2. `generated-docs/`  — a plain copy of the run's generated-docs tree. Enough for
 *                           the artifact invariants, but the git-topology checks skip.
 *
 * Optional `meta.json` records `{ epicSlug, capturedAt, templateVersion, ... }`.
 *
 * When neither form is present the loader reports `present: false` with a reason, and
 * the Tier-2 suite skips visibly rather than showing a vacuous green.
 */

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';

const FIXTURE_DIR = path.resolve(__dirname, '..', 'fixtures', 'golden-run');
const BUNDLE = path.join(FIXTURE_DIR, 'repo.bundle');
const DOCS_IN_FIXTURE = path.join(FIXTURE_DIR, 'generated-docs');
const META = path.join(FIXTURE_DIR, 'meta.json');

export interface GoldenRun {
  /** True when a usable golden run (bundle or docs tree) is present. */
  present: boolean;
  /** One-line reason shown in the skip notice when `present` is false. */
  reason: string;
  /** True when the run was loaded from a git bundle (topology checks can run). */
  hasGit: boolean;
  /** Root of the checked-out run (bundle clone) or the fixture dir (docs-only). */
  root: string | null;
  /** Path to the run's generated-docs/ tree, or null when absent. */
  docsDir: string | null;
  /** Run git in `root` (bundle mode only); null in docs-only mode. */
  git: ((...args: string[]) => { exitCode: number; stdout: string; stderr: string }) | null;
  /** Parsed meta.json (or {}). */
  meta: Record<string, unknown>;
  /** Removes any temp clone. Idempotent. Safe to call when nothing was created. */
  cleanup: () => void;
}

function readMeta(): Record<string, unknown> {
  try {
    return JSON.parse(fs.readFileSync(META, 'utf8'));
  } catch {
    return {};
  }
}

function absent(reason: string): GoldenRun {
  return { present: false, reason, hasGit: false, root: null, docsDir: null, git: null, meta: readMeta(), cleanup: () => {} };
}

export function loadGoldenRun(): GoldenRun {
  if (!fs.existsSync(FIXTURE_DIR)) {
    return absent(`no fixtures/golden-run/ directory — capture a run first (see fixtures/golden-run/README.md)`);
  }

  // Preferred: a git bundle. Clone it into a temp working tree (default branch = main).
  if (fs.existsSync(BUNDLE)) {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), `golden-run-${crypto.randomBytes(4).toString('hex')}-`));
    const git = (...args: string[]) => {
      const res = spawnSync('git', ['-C', root, ...args], { encoding: 'utf8' });
      return { exitCode: typeof res.status === 'number' ? res.status : 1, stdout: res.stdout ?? '', stderr: res.stderr ?? '' };
    };
    const clone = spawnSync('git', ['clone', '--quiet', BUNDLE, root], { encoding: 'utf8' });
    if (clone.status !== 0) {
      fs.rmSync(root, { recursive: true, force: true });
      return absent(`fixtures/golden-run/repo.bundle could not be cloned: ${clone.stderr?.trim()}`);
    }
    return {
      present: true,
      reason: '',
      hasGit: true,
      root,
      docsDir: path.join(root, 'generated-docs'),
      git,
      meta: readMeta(),
      cleanup: () => { try { fs.rmSync(root, { recursive: true, force: true }); } catch { /* ignore */ } },
    };
  }

  // Fallback: a plain generated-docs tree (artifact checks only, no git topology).
  if (fs.existsSync(DOCS_IN_FIXTURE)) {
    return {
      present: true,
      reason: '',
      hasGit: false,
      root: FIXTURE_DIR,
      docsDir: DOCS_IN_FIXTURE,
      git: null,
      meta: readMeta(),
      cleanup: () => {},
    };
  }

  return absent(`fixtures/golden-run/ exists but has neither repo.bundle nor generated-docs/ — capture a run (see its README.md)`);
}
