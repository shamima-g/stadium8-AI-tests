/**
 * Tests for .claude/scripts/validate-generated-doc-names.js
 *
 * Repo-wide audit that walks generated-docs/ and web/e2e/ and classifies each file
 * against .claude/shared/generated-doc-conventions.json.
 *   exit 0 = no drift · exit 1 = drift found · exit 2 = schema missing/malformed.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, runScript, REPO_ROOT } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/validate-generated-doc-names.js';
const CONVENTIONS_REL = path.join('.claude', 'shared', 'generated-doc-conventions.json');

function seedConventions(root: string): void {
  const dst = path.join(root, CONVENTIONS_REL);
  fs.mkdirSync(path.dirname(dst), { recursive: true });
  fs.copyFileSync(path.join(REPO_ROOT, CONVENTIONS_REL), dst);
}

function runValidator(root: string) {
  return runScript(SCRIPT, ['--format=json', '--root', root], { cwd: root });
}

describe('validate-generated-doc-names.js', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); seedConventions(project.root); });
  afterEach(() => { project.cleanup(); });

  it('PASS: a correctly-named tree reports "ok" with zero drift (exit 0)', () => {
    project.write('generated-docs/project.md', '# Project\n');
    project.write('generated-docs/epics/task-browsing/state.json', '{}');
    project.write('generated-docs/epics/task-browsing/stories/story-3-nav.md', '# Story 3\n');
    project.write('web/e2e/epic-task-browsing-story-3-nav.spec.ts', 'test("x", () => {});\n');

    const r = runValidator(project.root);
    expect(r.exitCode, r.stderr).toBe(0);
    const json = r.json<{ status: string; counts: { drift: number; ok: number } }>();
    expect(json.status).toBe('ok');
    expect(json.counts.drift).toBe(0);
    expect(json.counts.ok).toBeGreaterThanOrEqual(4);
  });

  it('FAIL: a drift-named epic file is reported (status "drift", exit 1)', () => {
    project.write('generated-docs/project.md', '# Project\n');
    project.write('generated-docs/epics/task-browsing/epic-state.json', '{}'); // drift: should be state.json
    project.write('generated-docs/epics/task-browsing/stories/story-3.md', '# Story 3\n'); // drift: missing slug

    const r = runValidator(project.root);
    expect(r.exitCode).toBe(1);
    const json = r.json<{ status: string; counts: { drift: number }; drift: { path: string }[] }>();
    expect(json.status).toBe('drift');
    expect(json.counts.drift).toBe(2);
    const driftPaths = json.drift.map((d) => d.path).join(' ');
    expect(driftPaths).toMatch(/epic-state\.json/);
    expect(driftPaths).toMatch(/story-3\.md/);
  });

  it('FAIL: a missing conventions schema exits 2 (can\'t audit without the source of truth)', () => {
    fs.rmSync(path.join(project.root, CONVENTIONS_REL));
    const r = runValidator(project.root);
    expect(r.exitCode).toBe(2);
  });
});
