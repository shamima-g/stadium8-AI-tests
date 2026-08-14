/**
 * The build report points to /start before a project exists (post-v1.2.0) — planned #10.
 *
 * Running a report before a project has started used to be mistaken for a report with one
 * detail missing, and produced a page rather than telling the user what to do. Now the
 * collector classifies a fresh tree as `no_project` and returns guidance that names `/start`.
 *
 * The existing collector-project-status test asserts the two collectors AGREE on the status;
 * this asserts the GUIDANCE CONTENT (the /start pointer) that no other test checks. Runs over
 * the real collector as a subprocess. Feature-detected on the collector; skips on older cuts.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, gitSandbox, runScript, REPO_ROOT } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const COLLECTOR = '.claude/scripts/collect-build-report-data.js';
const BR_PRESENT = fs.existsSync(path.join(REPO_ROOT, COLLECTOR));

function collect(root: string) {
  return runScript(COLLECTOR, ['--format=json', '--root', root], { cwd: root });
}

describe('build report points to /start before a project exists (post-v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => {
    project = createTempProject();
  });
  afterEach(() => {
    project.cleanup(); // RB-0 — the throwaway temp project is discarded
  });

  it.skipIf(!BR_PRESENT)('PASS: a no-project tree returns /start guidance, not a report', () => {
    // A committed repo with no generated-docs/project.md = nothing started yet.
    const git = gitSandbox(project.root);
    project.write('README.md', '# fixture\n');
    git.commit('seed');

    const r = collect(project.root);
    expect(r.exitCode, r.stderr).toBe(0);
    const json = r.json<{ status: string; message?: string }>();
    expect(json.status, 'a fresh tree is no_project').toBe('no_project');
    expect(json.message ?? '', 'the guidance names /start').toMatch(/\/start/);
  });

  // Teeth: once a project exists, the collector returns a real report — NOT the /start pointer.
  // Proves the guidance is state-driven, so the PASS above isn't a message the collector always
  // emits.
  it.skipIf(!BR_PRESENT)('PASS (teeth): a started project returns a real report, not the /start pointer', () => {
    const git = gitSandbox(project.root);
    project.write('generated-docs/project.md', '# Project\n');
    git.commit('seed');

    const r = collect(project.root);
    expect(r.exitCode, r.stderr).toBe(0);
    const json = r.json<{ status: string; message?: string }>();
    expect(json.status, 'a project with project.md is ok').toBe('ok');
    expect(json.message ?? '', 'no "run /start to begin" guidance once the project exists').not.toMatch(
      /run \/start to begin/,
    );
  });
});
