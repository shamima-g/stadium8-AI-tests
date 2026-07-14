/**
 * Branch-and-merge machinery (the mechanical, deterministic slice).
 *
 * The epic-branch workflow relies on real git behaviour: each epic lives on an
 * `epic/<slug>` branch, merges into `main`, is finalised with mark-epic-complete, and
 * shows up as "merged" (not in-flight) on the dashboard afterward. Non-conflicting
 * overlaps between epics combine on their own; same-line overlaps conflict — which is
 * exactly when the workflow halts and asks the user.
 *
 * What stays Tier 3 (not automatable here): whether Claude *chooses* to auto-combine
 * vs. halt, and whether it surfaces both versions to the user. This file tests the git
 * substrate those decisions rest on, using gitSandbox — no live AI.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import {
  createTempProject,
  gitSandbox,
  seedProjectMd,
  seedEpicPlan,
  seedEpicState,
  seedStoryFile,
  runScript,
} from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';
import type { GitSandbox } from '../../helpers/git-sandbox';

const COLLECT = '.claude/scripts/collect-dashboard-data.js';
const MARK_COMPLETE = '.claude/scripts/mark-epic-complete.js';

describe('git-machinery — epic lifecycle: branch → merge → complete → merged on the dashboard', () => {
  let project: TempProject;
  let git: GitSandbox;
  beforeEach(() => {
    project = createTempProject();
    git = gitSandbox(project.root);
  });
  afterEach(() => { project.cleanup(); });

  it('PASS: after merge + mark-epic-complete, the epic shows as merged (COMPLETE), not in-flight', () => {
    // main: shared facts + the plan.
    seedProjectMd(project.root);
    seedEpicPlan(project.root, [{ slug: 'task-browsing', name: 'Task Browsing', goal: 'View tasks' }]);
    git.commit('intake: project.md + epic-plan.md');
    git.git('branch', '-M', 'main');

    // Build the epic on its own branch, ready to merge.
    expect(git.git('checkout', '-q', '-b', 'epic/task-browsing').exitCode).toBe(0);
    seedStoryFile(project.root, { slug: 'task-browsing', index: 1, title: 'View the task list' });
    seedEpicState(project.root, {
      slug: 'task-browsing', name: 'Task Browsing', phase: 'COMPLETE-ON-BRANCH',
      stories: { '1': { status: 'complete', commit: 'abc1234', e2eStatus: 'passed' } },
    });
    git.commit('epic task-browsing: built');

    // Merge into main.
    expect(git.git('checkout', '-q', 'main').exitCode).toBe(0);
    const merge = git.git('merge', '--no-ff', 'epic/task-browsing', '-m', 'merge epic/task-browsing');
    expect(merge.exitCode, merge.stderr).toBe(0);

    // Finalise on main, commit the flip, and delete the merged branch (as the real flow does).
    const mc = runScript(MARK_COMPLETE, ['--slug', 'task-browsing', '--root', project.root], { cwd: project.root });
    expect(mc.exitCode, mc.stderr).toBe(0);
    git.commit('chore(task-browsing): mark complete');
    git.git('branch', '-D', 'epic/task-browsing');

    // The dashboard collector (reading main via git) now sees it as merged, not in-flight.
    const data = runScript(COLLECT, ['--format=json', '--root', project.root], { cwd: project.root })
      .json<{ status: string; merged: { slug: string }[]; inFlight: { status: string }[] }>();
    expect(data.status).toBe('ok');
    expect(data.merged.map((e) => e.slug)).toContain('task-browsing');
    expect(data.inFlight.filter((e) => e.status === 'ok')).toHaveLength(0);
  });
});

// A central design-token file two epics might both touch — the canonical auto-combine case.
// The two accent slots are kept several unchanged lines apart so that edits to each land
// in separate 3-line diff hunks (git merges non-overlapping hunks cleanly; adjacent-line
// edits would conflict on context alone, which isn't the behaviour under test here).
function tokensCss(slotA: string, slotB: string, primary = '#000000'): string {
  return [
    ':root {',
    `  --primary: ${primary};`,
    '  --secondary: #ffffff;',
    `  --accent-slot-a: ${slotA};`,
    '  /* --- spacing tokens --- */',
    '  --space-1: 4px;',
    '  --space-2: 8px;',
    '  --space-3: 16px;',
    '  /* --- accent tokens --- */',
    `  --accent-slot-b: ${slotB};`,
    '}',
    '',
  ].join('\n');
}

const CSS = 'web/src/app/globals.css';

describe('git-machinery — auto-combine vs. conflict substrate', () => {
  let project: TempProject;
  let git: GitSandbox;
  beforeEach(() => {
    project = createTempProject();
    git = gitSandbox(project.root);
    seedProjectMd(project.root);
    project.write(CSS, tokensCss('initial', 'initial'));
    git.commit('base: central design tokens');
    git.git('branch', '-M', 'main');
  });
  afterEach(() => { project.cleanup(); });

  it('PASS: two epics adding different tokens combine on their own (clean merge)', () => {
    // epic/a fills slot-a; epic/b (branched from the same base) fills slot-b — different lines.
    git.git('checkout', '-q', '-b', 'epic/a');
    project.write(CSS, tokensCss('#111111', 'initial'));
    git.commit('epic a: add accent A');

    git.git('checkout', '-q', 'main');
    git.git('checkout', '-q', '-b', 'epic/b');
    project.write(CSS, tokensCss('initial', '#222222'));
    git.commit('epic b: add accent B');

    git.git('checkout', '-q', 'main');
    expect(git.git('merge', '--no-ff', 'epic/a', '-m', 'merge a').exitCode).toBe(0);
    const mergeB = git.git('merge', '--no-ff', 'epic/b', '-m', 'merge b');
    expect(mergeB.exitCode, mergeB.stderr).toBe(0); // auto-combined, no conflict

    const css = project.read(CSS);
    expect(css).toContain('--accent-slot-a: #111111;');
    expect(css).toContain('--accent-slot-b: #222222;');
  });

  it('FAIL: two epics changing the SAME token line conflict (the workflow\'s halt trigger)', () => {
    git.git('checkout', '-q', '-b', 'epic/c');
    project.write(CSS, tokensCss('initial', 'initial', '#111111')); // changes --primary
    git.commit('epic c: primary → #111111');

    git.git('checkout', '-q', 'main');
    git.git('checkout', '-q', '-b', 'epic/d');
    project.write(CSS, tokensCss('initial', 'initial', '#222222')); // changes the SAME line
    git.commit('epic d: primary → #222222');

    git.git('checkout', '-q', 'main');
    expect(git.git('merge', '--no-ff', 'epic/c', '-m', 'merge c').exitCode).toBe(0);
    const mergeD = git.git('merge', '--no-ff', 'epic/d', '-m', 'merge d');
    expect(mergeD.exitCode).not.toBe(0); // conflict — git can't auto-combine

    expect(project.read(CSS)).toContain('<<<<<<<'); // conflict markers present
    git.git('merge', '--abort');
  });
});
