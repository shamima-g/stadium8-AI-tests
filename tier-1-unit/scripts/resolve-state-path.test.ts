/**
 * Tests for .claude/scripts/resolve-state-path.js
 *
 * The single source of truth for "where is the active workflow state.json?", used by
 * the dashboard and all three PowerShell hooks. `--branch` overrides git detection.
 *   epic/<kebab-slug> → kind: epic, path generated-docs/epics/<slug>/state.json
 *   anything else     → kind: none, path null
 *   invalid slug      → status: error (exit 1)
 * The legacy generated-docs/context/workflow-state.json is NOT a valid source.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, seedEpicState, seedLegacyState, runScript } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/resolve-state-path.js';

interface Resolution {
  status: string;
  kind: string | null;
  branch: string | null;
  slug: string | null;
  path: string | null;
  exists: boolean;
}

function resolve(root: string, branch: string) {
  return runScript(SCRIPT, ['--branch', branch, '--root', root], { cwd: root });
}

describe('resolve-state-path.js — epic branch', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: epic/<slug> resolves to the per-epic state.json path', () => {
    const r = resolve(project.root, 'epic/task-browsing');
    expect(r.exitCode, r.stderr).toBe(0);
    const res = r.json<Resolution>();
    expect(res.status).toBe('ok');
    expect(res.kind).toBe('epic');
    expect(res.slug).toBe('task-browsing');
    expect(res.path).toBe('generated-docs/epics/task-browsing/state.json');
    expect(res.exists).toBe(false); // no file seeded yet
  });

  it('PASS: reports exists:true once the state.json is present', () => {
    seedEpicState(project.root, { slug: 'task-browsing', name: 'Task Browsing' });
    const res = resolve(project.root, 'epic/task-browsing').json<Resolution>();
    expect(res.kind).toBe('epic');
    expect(res.exists).toBe(true);
  });
});

describe('resolve-state-path.js — non-epic and invalid', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: on main it resolves to kind:none with no path', () => {
    const res = resolve(project.root, 'main').json<Resolution>();
    expect(res.status).toBe('ok');
    expect(res.kind).toBe('none');
    expect(res.path).toBeNull();
  });

  it('FAIL: an invalid (non-kebab) epic slug is an error (exit 1)', () => {
    const r = resolve(project.root, 'epic/BadSlug');
    expect(r.exitCode).toBe(1);
    const res = r.json<Resolution>();
    expect(res.status).toBe('error');
    expect(res.kind).toBeNull();
  });

  it('FAIL: legacy workflow-state.json is NOT treated as a valid state source', () => {
    // Even with a legacy file present, a non-epic branch resolves to kind:none —
    // it must never point at generated-docs/context/workflow-state.json.
    seedLegacyState(project.root);
    const res = resolve(project.root, 'main').json<Resolution>();
    expect(res.kind).toBe('none');
    expect(res.path).toBeNull();
  });
});
