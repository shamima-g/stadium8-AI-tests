/**
 * Both build reports land in one place — generated-docs/reports/ (post-v1.2.0) — planned #1.
 *
 * The reports were split into two audience pages, and BOTH now write under
 * `generated-docs/reports/` (derived from `resolve-state-path.js` REPORTS_DIR_REL) so every
 * generated report sits in one folder. This runs the real generator for each audience and
 * asserts the location invariant — and that neither leaks back to the old root path (the move
 * that quietly broke the XSS-escaping test until it was re-pointed).
 *
 * Feature-detected on the stakeholders audience (the split marker); skips on older cuts.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import {
  createTempProject,
  seedProjectMd,
  seedEpicState,
  seedStoryFile,
  gitSandbox,
  runScript,
  REPO_ROOT,
} from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const BUILD_REPORT = '.claude/scripts/generate-build-report-html.js';
const BR_PRESENT = fs.existsSync(path.join(REPO_ROOT, BUILD_REPORT));
// The stakeholders audience arrived with the split — the versions this invariant applies to.
const SPLIT = BR_PRESENT && fs.readFileSync(path.join(REPO_ROOT, BUILD_REPORT), 'utf8').includes('stakeholders');

function seedBuiltProject(project: TempProject): void {
  const git = gitSandbox(project.root);
  seedProjectMd(project.root, { name: 'Team Task Manager' });
  git.commit('intake');
  git.git('checkout', '-q', '-b', 'epic/task-x');
  seedStoryFile(project.root, { slug: 'task-x', index: 1, title: 'Nav' });
  seedEpicState(project.root, {
    slug: 'task-x',
    name: 'Tasks',
    phase: 'BUILD',
    stories: { '1': { status: 'in-progress' } },
  });
  git.commit('build');
}

function generate(project: TempProject, audience: string) {
  return runScript(BUILD_REPORT, ['--root', project.root, '--no-insights', '--audience', audience], {
    cwd: project.root,
  });
}

describe('both build reports land under generated-docs/reports/ (post-v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => {
    project = createTempProject();
  });
  afterEach(() => {
    project.cleanup(); // RB-0 — the throwaway temp project is discarded
  });

  it.skipIf(!SPLIT)(
    'PASS: maintainer and stakeholders reports both write under generated-docs/reports/, not the old root',
    () => {
      seedBuiltProject(project);
      const m = generate(project, 'maintainer');
      expect(m.exitCode, m.stderr).toBe(0);
      const s = generate(project, 'stakeholders');
      expect(s.exitCode, s.stderr).toBe(0);

      // Good case: both pages land in the one reports/ folder.
      expect(project.exists('generated-docs/reports/build-report.html'), 'maintainer under reports/').toBe(true);
      expect(
        project.exists('generated-docs/reports/build-report-stakeholders.html'),
        'stakeholders under reports/',
      ).toBe(true);

      // Broken case / teeth: neither leaks to the pre-v1.2.0 root location.
      expect(project.exists('generated-docs/build-report.html'), 'maintainer must NOT be at the old root path').toBe(
        false,
      );
      expect(
        project.exists('generated-docs/build-report-stakeholders.html'),
        'stakeholders must NOT be at the old root path',
      ).toBe(false);
    },
  );
});
