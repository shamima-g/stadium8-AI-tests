/**
 * Tests for .claude/scripts/generate-dashboard-html.js
 *
 * Renders generated-docs/dashboard.html (+ a sibling dashboard-data.json) from the
 * epic-branch payload produced by collect-dashboard-data.js. Must:
 *  - Always write dashboard.html, for every collect status (no_project / legacy / ok)
 *  - Include <meta http-equiv="refresh" content="10"> so the browser auto-refreshes
 *  - Be deterministic for a fixed state, and reflect a change in state
 *  - Never throw (it's fire-and-forget during the workflow)
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import {
  createTempProject,
  seedProjectMd,
  seedEpicPlan,
  seedEpicState,
  seedStoryFile,
  gitSandbox,
  runScript,
} from '../../helpers';
import { normalise } from '../../helpers/snapshot';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/generate-dashboard-html.js';
const HTML = 'generated-docs/dashboard.html';

describe('generate-dashboard-html.js', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: writes dashboard.html with an auto-refresh meta tag when a project exists', () => {
    seedProjectMd(project.root, { name: 'Team Task Manager' });
    seedEpicPlan(project.root, [{ slug: 'task-browsing', name: 'Task Browsing', goal: 'View tasks' }]);

    const r = runScript(SCRIPT, ['--root', project.root], { cwd: project.root });
    expect(r.exitCode).toBe(0);
    expect(project.exists(HTML)).toBe(true);
    const html = project.read(HTML);
    expect(html).toContain('http-equiv="refresh"');
    expect(html).toMatch(/content="?10"?/);
  });

  it('FAIL: still writes usable HTML (never a half-written/empty file) with no project at all', () => {
    // Fire-and-forget: even the "nothing started" state must produce a real page,
    // not crash or leave an empty file.
    const r = runScript(SCRIPT, ['--root', project.root], { cwd: project.root });
    expect(r.exitCode).toBe(0);
    expect(project.exists(HTML)).toBe(true);
    const html = project.read(HTML);
    expect(html.length).toBeGreaterThan(200);
    expect(html).toContain('http-equiv="refresh"');
  });
});

describe('generate-dashboard-html.js — snapshot (stable HTML)', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: produces deterministic HTML for a fixed state (after normalising timestamps)', () => {
    seedProjectMd(project.root, { name: 'Team Task Manager' });
    seedEpicPlan(project.root, [{ slug: 'task-browsing', name: 'Task Browsing', goal: 'View tasks' }]);

    runScript(SCRIPT, ['--root', project.root], { cwd: project.root });
    const html = project.read(HTML);
    runScript(SCRIPT, ['--root', project.root], { cwd: project.root });
    const html2 = project.read(HTML);

    expect(normalise(html)).toBe(normalise(html2));
  });

  it('FAIL: different states produce different HTML (proves the normaliser isn\'t stripping signal)', () => {
    // State A: nothing started (no_project banner).
    runScript(SCRIPT, ['--root', project.root], { cwd: project.root });
    const a = project.read(HTML);

    // State B: an in-flight epic mid-BUILD on its branch.
    const git = gitSandbox(project.root);
    seedProjectMd(project.root, { name: 'Team Task Manager' });
    seedEpicPlan(project.root, [{ slug: 'task-browsing', name: 'Task Browsing', goal: 'View tasks' }]);
    git.commit('intake');
    git.git('checkout', '-q', '-b', 'epic/task-browsing');
    seedStoryFile(project.root, { slug: 'task-browsing', index: 1, title: 'View the task list' });
    seedEpicState(project.root, {
      slug: 'task-browsing',
      name: 'Task Browsing',
      phase: 'BUILD',
      stories: { '1': { status: 'in-progress' } },
    });
    git.commit('build');
    runScript(SCRIPT, ['--root', project.root], { cwd: project.root });
    const b = project.read(HTML);

    expect(normalise(a)).not.toBe(normalise(b));
  });
});
