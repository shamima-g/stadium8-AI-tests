/**
 * Cross-script smoke — the two collectors classify a project the same way.
 *
 * v1.2.0 extracted `projectStatus()` into `.claude/scripts/lib/project-status.js` so
 * `/dashboard` and `/build-report` can never disagree on whether a project exists,
 * is missing, or needs migration. This runs BOTH collectors over the same tree in the
 * three states and asserts they return the same `status`. It also exercises the shared
 * `tryGit` wrapper transitively — the build-report collector runs `git log --all
 * --numstat`, the large-output case `lib/git.js` raised the buffer ceiling for.
 *
 * This is the cross-script check the co-located unit tests can't do (they test one
 * script in isolation); it's deliberately a smoke, not a re-test of the classifier's
 * internals. Pins the v1.2.0 shape; the build-report arm feature-detects so it skips
 * cleanly on a template that predates the collector.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, gitSandbox, runScript, REPO_ROOT } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const DASHBOARD = '.claude/scripts/collect-dashboard-data.js';
const BUILD_REPORT = '.claude/scripts/collect-build-report-data.js';

type Status = 'ok' | 'no_project' | 'legacy_detected';
const STATES: Status[] = ['no_project', 'ok', 'legacy_detected'];

function statusFrom(script: string, root: string): Status {
  const r = runScript(script, ['--format=json', '--root', root], { cwd: root });
  expect(r.exitCode, r.stderr).toBe(0);
  return r.json<{ status: Status }>().status;
}

/** Shape the temp tree into one of the three project states, then commit. */
function seedState(project: TempProject, state: Status): void {
  const git = gitSandbox(project.root);
  // A neutral file so every state has something to commit (and doesn't affect status).
  project.write('README.md', '# fixture\n');
  if (state === 'ok') {
    project.write('generated-docs/project.md', '# Project\n');
  } else if (state === 'legacy_detected') {
    project.write('generated-docs/context/workflow-state.json', '{}');
  }
  git.commit('seed');
}

// The build-report collector + shared project-status lib arrived in v1.2.0.
const BR_PRESENT = fs.existsSync(path.join(REPO_ROOT, BUILD_REPORT));

describe('collectors — dashboard and build-report agree on project status (v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  for (const state of STATES) {
    // SKIP (not a fake green) when the build-report collector predates the target
    // version — workflow-tests.md §12 Layer B distinguishes Skipped from Green.
    it.skipIf(!BR_PRESENT)(`PASS: both collectors classify a ${state} tree identically`, () => {
      seedState(project, state);
      const dash = statusFrom(DASHBOARD, project.root);
      const build = statusFrom(BUILD_REPORT, project.root);
      expect(dash, `dashboard misread a ${state} tree`).toBe(state);
      expect(build, 'build-report disagreed with the dashboard on the same tree').toBe(dash);
    });
  }

  it('FAIL: the classifier discriminates (the three states are NOT all the same status)', () => {
    // Guards against a vacuous "agreement": if projectStatus ever returned a constant,
    // the collectors would still agree — but here the three states must yield three
    // distinct statuses, proving the shared classifier actually discriminates.
    const seen = new Set<Status>();
    for (const state of STATES) {
      const p = createTempProject();
      try { seedState(p, state); seen.add(statusFrom(DASHBOARD, p.root)); }
      finally { p.cleanup(); }
    }
    expect(seen.size, `expected 3 distinct statuses, saw: ${[...seen].join(', ')}`).toBe(3);
  });
});
