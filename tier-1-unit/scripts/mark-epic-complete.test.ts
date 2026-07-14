/**
 * Tests for .claude/scripts/mark-epic-complete.js
 *
 * The final-state transition run on `main` after an epic PR merges: flips
 * generated-docs/epics/<slug>/state.json from COMPLETE-ON-BRANCH (or any phase from
 * EPIC-END onward) to COMPLETE and stamps lastUpdated. A wrong flip or a torn write
 * corrupts the merged-epic record the dashboard and /status read, so it must be
 * exact, idempotent, and refuse premature phases.
 *
 * Output contract: JSON `{ status: 'ok'|'error', slug, phase, path, note?, message? }`.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, seedEpicState, readEpicState, runScript } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/mark-epic-complete.js';
const SEEDED_TS = '2026-04-21T00:00:00.000Z'; // seedEpicState's fixed lastUpdated

describe('mark-epic-complete.js — valid finalisation', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: flips COMPLETE-ON-BRANCH → COMPLETE and refreshes lastUpdated', () => {
    seedEpicState(project.root, { slug: 'task-browsing', name: 'Task Browsing', phase: 'COMPLETE-ON-BRANCH' });
    const r = runScript(SCRIPT, ['--slug', 'task-browsing', '--root', project.root], { cwd: project.root });
    expect(r.exitCode, r.stderr).toBe(0);
    expect((r.parsedJson as { status?: string; phase?: string })?.status).toBe('ok');

    const state = readEpicState(project.root, 'task-browsing');
    expect(state.phase).toBe('COMPLETE');
    expect(state.lastUpdated).not.toBe(SEEDED_TS); // re-stamped
  });

  it('PASS: also finalises from EPIC-END and MANUAL-TEST (uncommitted-tip recovery)', () => {
    for (const phase of ['EPIC-END', 'MANUAL-TEST'] as const) {
      seedEpicState(project.root, { slug: 'task-browsing', name: 'Task Browsing', phase });
      const r = runScript(SCRIPT, ['--slug', 'task-browsing', '--root', project.root], { cwd: project.root });
      expect(r.exitCode, `${phase}: ${r.stderr}`).toBe(0);
      expect(readEpicState(project.root, 'task-browsing').phase).toBe('COMPLETE');
    }
  });

  it('PASS: is idempotent — a second run stays COMPLETE and reports "already complete"', () => {
    seedEpicState(project.root, { slug: 'task-browsing', name: 'Task Browsing', phase: 'COMPLETE-ON-BRANCH' });
    runScript(SCRIPT, ['--slug', 'task-browsing', '--root', project.root], { cwd: project.root });
    const second = runScript(SCRIPT, ['--slug', 'task-browsing', '--root', project.root], { cwd: project.root });
    expect(second.exitCode).toBe(0);
    const json = second.parsedJson as { status?: string; note?: string };
    expect(json?.status).toBe('ok');
    expect(json?.note).toMatch(/already complete/i);
    expect(readEpicState(project.root, 'task-browsing').phase).toBe('COMPLETE');
  });
});

describe('mark-epic-complete.js — refuses invalid input', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: refuses a premature phase (BUILD) and leaves the state untouched', () => {
    seedEpicState(project.root, { slug: 'task-browsing', name: 'Task Browsing', phase: 'BUILD' });
    const r = runScript(SCRIPT, ['--slug', 'task-browsing', '--root', project.root], { cwd: project.root });
    expect(r.exitCode).toBe(1);
    expect((r.parsedJson as { status?: string })?.status).toBe('error');
    // State must NOT have been flipped.
    expect(readEpicState(project.root, 'task-browsing').phase).toBe('BUILD');
  });

  it('FAIL: errors when the epic has no state.json', () => {
    const r = runScript(SCRIPT, ['--slug', 'does-not-exist', '--root', project.root], { cwd: project.root });
    expect(r.exitCode).toBe(1);
    expect((r.parsedJson as { status?: string; message?: string })?.status).toBe('error');
    expect((r.parsedJson as { message?: string })?.message).toMatch(/state\.json/i);
  });

  it('FAIL: rejects a path-traversal slug rather than resolving outside generated-docs/epics', () => {
    const r = runScript(SCRIPT, ['--slug', '../../evil', '--root', project.root], { cwd: project.root });
    expect(r.exitCode).toBe(1);
    expect((r.parsedJson as { status?: string; message?: string })?.status).toBe('error');
    expect((r.parsedJson as { message?: string })?.message).toMatch(/slug/i);
  });

  it('FAIL: missing --slug prints usage and exits non-zero', () => {
    const r = runScript(SCRIPT, ['--root', project.root], { cwd: project.root });
    expect(r.exitCode).not.toBe(0);
  });
});
