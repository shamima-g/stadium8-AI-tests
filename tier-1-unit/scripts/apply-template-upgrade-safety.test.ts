/**
 * Upgrade deletion-safety — the /upgrade delivery step must never eat the user's work.
 *
 * `apply-template.js` is the ONE workflow script that deletes files during `/upgrade`:
 * it prunes template files a newer version retired. v1.2.0 reworked exactly this path
 * (the release's headline change — "an upgrade now uses the new version's machinery"),
 * and the RELEASE channel ships the script with **no** co-located test. The single
 * failure mode that could destroy work is deleting a file the user owns.
 *
 * This drives a real, offline upgrade over a throwaway project (the checkout under test
 * IS the target template, via `--template`) and asserts the line is drawn correctly:
 * retired TEMPLATE files are removed, and the user's own work stays byte-for-byte. It is
 * a cross-repo end-to-end smoke — running the real script to a real filesystem outcome —
 * not a re-test of apply-template's unit internals (workflow-tests.md §13.6). RB-0.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, runScript, REPO_ROOT } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const APPLY = '.claude/scripts/apply-template.js';
const PRESENT = fs.existsSync(path.join(REPO_ROOT, APPLY));

// Files the template permanently RETIRED — apply-template's named-backstop sweep deletes
// these on any upgrade, whether the project tracks them or not (RETIRED_PATHS in the script).
const RETIRED = [
  '.github/workflows/pr-checks.yml',
  '.templatesyncignore',
  'scripts/parse-logs.ps1',
];

// The user's OWN work — must survive an upgrade untouched. A spread across the places
// users legitimately add things: app code (web/src — never walked), a custom command (a
// prune-exempt .claude dir), and generated / authored docs (never template-owned).
const USER_FILES: Array<[string, string]> = [
  ['web/src/app/page.tsx', 'USER APP CODE — must survive\n'],
  ['.claude/commands/my-custom.md', '# my custom command — must survive\n'],
  ['generated-docs/project.md', '# project facts — must survive\n'],
  ['documentation/notes.md', 'user spec — must survive\n'],
];

describe('apply-template — /upgrade deletion safety (v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); }); // RB-0

  it.skipIf(!PRESENT)('deletes retired template files but never the user\'s own work', () => {
    // Seed both kinds of file, and assert the preconditions so a no-op run can't pass
    // vacuously — every path below must actually exist before the upgrade runs.
    for (const rel of RETIRED) project.write(rel, 'retired template file\n');
    for (const [rel, body] of USER_FILES) project.write(rel, body);
    for (const rel of RETIRED) expect(project.exists(rel), `${rel} missing pre-upgrade`).toBe(true);
    for (const [rel] of USER_FILES) expect(project.exists(rel), `${rel} missing pre-upgrade`).toBe(true);

    // Run the real upgrade offline: the checkout under test is the target template.
    const r = runScript(
      APPLY,
      ['--template', REPO_ROOT, '--project', project.root, '--skip-lockfile'],
      { cwd: project.root, timeout: 60_000 },
    );
    expect(r.exitCode, r.stderr).toBe(0);

    // Sanity: the upgrade actually APPLIED machinery (so "user files survived" can't be a
    // side effect of the script doing nothing). WORKFLOWS.md is template-owned and copied in.
    expect(project.exists('.claude/WORKFLOWS.md'), 'upgrade did not apply machinery — it may have no-opped').toBe(true);

    // Retired template files are pruned...
    for (const rel of RETIRED) {
      expect(project.exists(rel), `retired template file ${rel} should have been deleted`).toBe(false);
    }
    // ...and every user file survives, byte-for-byte. (If the pruner ever over-reaches,
    // THIS is the assertion that turns red — the failure mode that would destroy work.)
    for (const [rel, body] of USER_FILES) {
      expect(project.exists(rel), `USER FILE ${rel} was destroyed by the upgrade`).toBe(true);
      expect(project.read(rel), `USER FILE ${rel} was modified by the upgrade`).toBe(body);
    }
  }, 60_000);
});
