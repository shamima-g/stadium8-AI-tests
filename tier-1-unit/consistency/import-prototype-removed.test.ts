/**
 * import-prototype was cleanly removed (post-v1.2.0) — planned #3.
 *
 * The prototype-import feature is gone; you drop design files into `documentation/` instead.
 * This is a CLEAN-REMOVAL canary: it runs only on the versions that removed the script
 * (skipIf it's still present) and asserts nothing dangles — no `/import` command, no caller,
 * no doc still telling the user to run it. A removed script that leaves references behind is a
 * half-finished removal, and that's the failure this catches.
 */

import { it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { REPO_ROOT } from '../../helpers';

const SCRIPT_REL = '.claude/scripts/import-prototype.js';
const SCRIPT_PRESENT = fs.existsSync(path.join(REPO_ROOT, SCRIPT_REL));

function walk(dir: string, acc: string[] = []): string[] {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === 'node_modules' || e.name === '.git') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else acc.push(p);
  }
  return acc;
}

/** Repo-relative files under any of `roots` whose text contains `needle`. */
function referencesTo(needle: string, roots: string[]): string[] {
  const hits: string[] = [];
  for (const root of roots) {
    if (!fs.existsSync(root)) continue;
    for (const f of walk(root)) {
      let text: string;
      try {
        text = fs.readFileSync(f, 'utf8');
      } catch {
        continue;
      }
      if (text.includes(needle)) hits.push(path.relative(REPO_ROOT, f));
    }
  }
  return hits;
}

const CLAUDE_DIR = path.join(REPO_ROOT, '.claude');

describe('import-prototype was cleanly removed (post-v1.2.0)', () => {
  it.skipIf(SCRIPT_PRESENT)('PASS: the script is absent and nothing under .claude references it', () => {
    const refs = referencesTo('import-prototype', [CLAUDE_DIR]);
    expect(refs, `dangling references to a removed script:\n${refs.join('\n')}`).toEqual([]);
  });

  // Teeth over the real tree: the SAME scanner finds references to a script that IS still
  // wired in — so a zero above means "genuinely absent", not "scanner returned nothing".
  it('PASS (teeth): the reference scanner finds references that really exist', () => {
    const refs = referencesTo('resolve-state-path', [CLAUDE_DIR]);
    expect(refs.length, 'scanner should find references to a live, referenced script').toBeGreaterThan(0);
  });
});
