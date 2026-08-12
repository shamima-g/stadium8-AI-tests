/**
 * The build report survives a missing/foreign figure — one bad number never loses
 * the whole page (post-v1.2.0).
 *
 * The maintainer report reads two external inputs alongside the git-derived data:
 * `generated-docs/reports/build-cost-data.json` and `…/build-effort-data.json`. A file
 * left over from an older template version — or copied in from another project — has a
 * different shape, and a naive `.toFixed()` on a missing key used to throw inside the page
 * template and cost the reader the WHOLE report rather than one section. Post-v1.2.0 it
 * degrades: any figure it can't read shows as a dash and the rest of the page generates.
 *
 * The template's own `generate-build-report-html.tests.js` proves this at the pure
 * `renderEffort()` level. This adds the seam that unit test can't: the real CLI end to end
 * — collect, render, WRITE the file, exit 0 — over a subprocess, so a regression that only
 * surfaces through `main()` (a missing mkdir, a throw before write) is still caught.
 * Feature-detected on the generator; skips cleanly on a template that predates it.
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

const REPORT_HTML = 'generated-docs/reports/build-report.html';
const EFFORT_DATA = 'generated-docs/reports/build-effort-data.json';
const COST_DATA = 'generated-docs/reports/build-cost-data.json';

/** A real, built epic on its branch so the generator has a project to report on. */
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

function generate(project: TempProject) {
  return runScript(BUILD_REPORT, ['--root', project.root, '--no-insights'], { cwd: project.root });
}

describe('build report degrades on a partial/foreign data file (v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => {
    project = createTempProject();
  });
  afterEach(() => {
    project.cleanup(); // RB-0 — the throwaway temp project is discarded
  });

  it.skipIf(!BR_PRESENT)(
    'PASS: a partial effort/cost data file still produces the whole page (no lost report)',
    () => {
      seedBuiltProject(project);
      // The shapes a stale generator or another project leaves behind: valid JSON, but
      // missing the keys the renderers reach for.
      project.write(
        EFFORT_DATA,
        JSON.stringify({ costComplete: true, totals: {}, benchmarks: null, categories: [], epics: [] }),
      );
      project.write(COST_DATA, JSON.stringify({ generatedAt: '2020-01-01T00:00:00Z' }));

      const r = generate(project);
      // Whole page was still produced — the failure mode this fixes is "no page at all".
      expect(r.exitCode, r.stderr).toBe(0);
      expect(project.exists(REPORT_HTML), 'the page was still written').toBe(true);
      const html = project.read(REPORT_HTML);

      // The partial effort file WAS consumed (section present) — it wasn't silently dropped,
      // so the degradation below is over the real, data-derived render.
      expect(html, 'the effort section rendered from the partial file').toContain('Effort benchmarks');
      // …and it degraded instead of leaking a broken figure. `\bNaN\b` avoids matching `isNaN(`.
      expect(html, 'no NaN leaked into a rendered figure').not.toMatch(/\bNaN\b/);
      expect(html, 'no "undefined" leaked into visible text').not.toMatch(/>[^<]*\bundefined\b[^<]*</);
    },
  );

  it.skipIf(!BR_PRESENT)(
    'PASS: a corrupt (non-JSON) data file is ignored, and the page still generates',
    () => {
      seedBuiltProject(project);
      project.write(EFFORT_DATA, 'not json {{{');
      project.write(COST_DATA, '<<< also not json');

      const r = generate(project);
      expect(r.exitCode, r.stderr).toBe(0);
      expect(project.exists(REPORT_HTML), 'a corrupt input must not take the page down').toBe(true);
      const html = project.read(REPORT_HTML);
      expect(html.length, 'a real page, not a stub').toBeGreaterThan(2000);
      expect(html, 'no NaN leaked into a rendered figure').not.toMatch(/\bNaN\b/);
    },
  );
});
