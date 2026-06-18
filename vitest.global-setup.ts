/**
 * Global setup — runs once before the suite. Its only job is to print a clear,
 * one-time notice when the QA-TESTS folder is run somewhere with no Stadium-8
 * template to test, so the skipped template-dependent suites aren't a mystery.
 *
 * Resolution mirrors helpers/target.ts; this file can't import that module
 * because globalSetup runs outside the test transform pipeline, so it re-derives
 * TARGET_ROOT the same way (REPO_ROOT env → else the parent repo).
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export default function setup(): void {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const targetRoot = process.env.REPO_ROOT
    ? path.resolve(process.env.REPO_ROOT)
    : path.resolve(here, '..');
  const templatePresent = fs.existsSync(path.join(targetRoot, '.claude', 'scripts'));

  if (!templatePresent) {
    // eslint-disable-next-line no-console
    console.warn(
      `\n[QA-TESTS] No Stadium-8 template (.claude/) found at: ${targetRoot}\n` +
        `[QA-TESTS] Template-dependent suites will be SKIPPED.\n` +
        `[QA-TESTS] Run from inside a Stadium-8 repo, or set REPO_ROOT=/path/to/repo.\n` +
        `[QA-TESTS] Template-independent tests still run.\n`,
    );
  }
}
