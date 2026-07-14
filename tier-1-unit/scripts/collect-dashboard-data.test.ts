/**
 * Tests for .claude/scripts/collect-dashboard-data.js
 *
 * Reads epic-branch workflow state across all branches and emits a JSON payload
 * (or compact text for /status). Sources: project.md (shared facts), epic-plan.md
 * (the plan + derived readiness), epic/<slug> branches (in-flight epics, read from
 * their branch tips), and generated-docs/epics/ on main (merged epics).
 *
 *   status: "no_project"      → neither project.md nor legacy state
 *           "legacy_detected" → legacy workflow-state.json but no project.md
 *           "ok"              → project.md present; plan + epics collected
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import {
  createTempProject,
  seedProjectMd,
  seedEpicPlan,
  seedEpicState,
  seedStoryFile,
  seedLegacyState,
  gitSandbox,
  runScript,
  rollback,
} from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/collect-dashboard-data.js';

describe('collect-dashboard-data.js — status detection', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { rollback(project.root, 'RB-1'); project.cleanup(); });

  it('PASS: returns "no_project" when nothing has started', () => {
    const r = runScript(SCRIPT, ['--root', project.root, '--format=json'], { cwd: project.root });
    expect(r.exitCode).toBe(0);
    expect((r.parsedJson as { status?: string })?.status).toBe('no_project');
  });

  it('FAIL: does NOT report "ok" or crash when only legacy state exists', () => {
    // A pre-epic-branch project (legacy workflow-state.json, no project.md) must be
    // steered to /migrate-legacy — never silently rendered as a healthy project.
    seedLegacyState(project.root);
    const r = runScript(SCRIPT, ['--root', project.root, '--format=json'], { cwd: project.root });
    expect(r.exitCode).toBe(0);
    const json = r.parsedJson as { status?: string; message?: string };
    expect(json?.status).toBe('legacy_detected');
    expect(json?.status).not.toBe('ok');
    expect(json?.message).toMatch(/migrate-legacy/);
  });
});

describe('collect-dashboard-data.js — the plan and its readiness', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { rollback(project.root, 'RB-1'); project.cleanup(); });

  it('PASS: with project.md + epic-plan.md, returns "ok" with the plan and derived readiness', () => {
    seedProjectMd(project.root, { name: 'Team Task Manager', slug: 'team-task-manager' });
    seedEpicPlan(project.root, [
      { slug: 'task-browsing', name: 'Task Browsing', goal: 'View and filter tasks' },
      { slug: 'task-actions', name: 'Task Actions', goal: 'Create/edit/delete', dependsOn: ['task-browsing'] },
    ]);

    const r = runScript(SCRIPT, ['--root', project.root, '--format=json'], { cwd: project.root });
    expect(r.exitCode).toBe(0);
    const json = r.json<{
      status: string;
      project: { name: string | null };
      hasPlan: boolean;
      plan: { slug: string; status: string; waitingOn: string[] }[];
    }>();

    expect(json.status).toBe('ok');
    expect(json.project.name).toBe('Team Task Manager');
    expect(json.hasPlan).toBe(true);

    // No branches exist yet → an epic with no deps is "ready"; one that depends on
    // an unfinished epic is "blocked", waiting on that dependency.
    const browsing = json.plan.find((e) => e.slug === 'task-browsing');
    const actions = json.plan.find((e) => e.slug === 'task-actions');
    expect(browsing?.status).toBe('ready');
    expect(actions?.status).toBe('blocked');
    expect(actions?.waitingOn).toContain('task-browsing');
  });

  it('FAIL: does not mark a dependent epic "ready" while its dependency is unmet', () => {
    seedProjectMd(project.root);
    seedEpicPlan(project.root, [
      { slug: 'auth', name: 'Sign in', goal: 'Let people sign in' },
      { slug: 'tasks', name: 'Tasks', goal: 'Show tasks', dependsOn: ['auth'] },
    ]);
    const r = runScript(SCRIPT, ['--root', project.root, '--format=json'], { cwd: project.root });
    const plan = r.json<{ plan: { slug: string; status: string }[] }>().plan;
    expect(plan.find((e) => e.slug === 'tasks')?.status).not.toBe('ready');
  });
});

describe('collect-dashboard-data.js — an in-flight epic on its branch', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { rollback(project.root, 'RB-1'); project.cleanup(); });

  it('PASS: an epic/<slug> branch with a state.json surfaces as in-flight with its phase and story counts', () => {
    const git = gitSandbox(project.root);
    // main: shared facts + the plan.
    seedProjectMd(project.root);
    seedEpicPlan(project.root, [{ slug: 'task-browsing', name: 'Task Browsing', goal: 'View tasks' }]);
    git.commit('intake: project.md + epic-plan.md');

    // Create and check out the epic branch, then add its state + stories.
    expect(git.git('checkout', '-q', '-b', 'epic/task-browsing').exitCode).toBe(0);
    seedStoryFile(project.root, { slug: 'task-browsing', index: 1, title: 'View the task list' });
    seedEpicState(project.root, {
      slug: 'task-browsing',
      name: 'Task Browsing',
      phase: 'BUILD',
      stories: { '1': { status: 'complete', commit: 'abc1234' }, '2': { status: 'in-progress' } },
    });
    git.commit('plan+build: task-browsing');

    const r = runScript(SCRIPT, ['--root', project.root, '--format=json'], { cwd: project.root });
    const json = r.json<{
      status: string;
      inFlight: { slug: string; phase: string | null; status: string; stories: { total: number; complete: number } }[];
    }>();

    expect(json.status).toBe('ok');
    const epic = json.inFlight.find((e) => e.slug === 'task-browsing');
    expect(epic).toBeDefined();
    expect(epic?.status).toBe('ok');
    expect(epic?.phase).toBe('BUILD');
    expect(epic?.stories.total).toBe(2);
    expect(epic?.stories.complete).toBe(1);
  });

  it('FAIL: a branch whose slug is not a valid epic/<kebab-slug> is surfaced, not silently dropped', () => {
    const git = gitSandbox(project.root);
    seedProjectMd(project.root);
    git.commit('intake');
    // An invalid slug (not kebab-case — here uppercase) must still appear in the
    // payload so a broken branch can't hide — collect tags it "invalid-slug"
    // rather than omitting it. (Spaces aren't a valid git refname, so we use case.)
    expect(git.git('checkout', '-q', '-b', 'epic/BadSlug').exitCode).toBe(0);
    git.commit('empty branch commit');

    const r = runScript(SCRIPT, ['--root', project.root, '--format=json'], { cwd: project.root });
    const inFlight = r.json<{ inFlight: { status: string }[] }>().inFlight;
    expect(inFlight.length).toBeGreaterThan(0);
    expect(inFlight.some((e) => e.status !== 'ok')).toBe(true);
  });
});

describe('collect-dashboard-data.js — --format=text', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { rollback(project.root, 'RB-1'); project.cleanup(); });

  it('PASS: text format is human-readable and names the project and its plan', () => {
    seedProjectMd(project.root, { name: 'Team Task Manager', slug: 'team-task-manager' });
    seedEpicPlan(project.root, [{ slug: 'task-browsing', name: 'Task Browsing', goal: 'View tasks' }]);
    const r = runScript(SCRIPT, ['--root', project.root, '--format=text'], { cwd: project.root });
    expect(r.exitCode).toBe(0);
    expect(r.stdout).toContain('Team Task Manager');
    expect(r.stdout).toContain('Task Browsing');
  });

  it('FAIL: text format does not leak raw JSON braces into user-facing output', () => {
    seedProjectMd(project.root);
    const r = runScript(SCRIPT, ['--root', project.root, '--format=text'], { cwd: project.root });
    const looksLikeRawJson = r.stdout.trim().startsWith('{') && r.stdout.trim().endsWith('}');
    expect(looksLikeRawJson).toBe(false);
  });
});
