/**
 * Tests for .claude/scripts/lib/project-root.js — the CWD-independent repo-root
 * resolver used by workflow scripts and hooks.
 *
 * getProjectRoot() walks up from a start directory (default: the module's own
 * location) to the nearest ancestor holding a `.claude/` or `.git/` marker. The
 * walk-up cases build a throwaway directory tree and assert which ancestor the
 * resolver stops at; they're isolated because the planted marker is always found
 * inside the temp tree before the walk escapes to the OS temp dir. The
 * default-arg case asserts the real anchor: the resolver lands on the target
 * repo root that holds `.claude`.
 */

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { it, expect, beforeAll, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, TARGET_ROOT } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

type GetProjectRoot = (startDir?: string) => string;

let getProjectRoot: GetProjectRoot;

// Load the CJS module under test from the target template. Done in beforeAll so
// the describeTemplate skip-gate has already decided the suite runs (the factory
// is not invoked at all when no template is present).
beforeAll(async () => {
  const modPath = path.join(TARGET_ROOT, '.claude', 'scripts', 'lib', 'project-root.js');
  const mod = await import(pathToFileURL(modPath).href);
  getProjectRoot = (mod.default ?? mod).getProjectRoot as GetProjectRoot;
});

describe('project-root.js — default anchor', () => {
  it('getProjectRoot() returns the target repo root that contains .claude', () => {
    // The module sits at <TARGET_ROOT>/.claude/scripts/lib, so its marker-walk
    // resolves to the repo root by construction.
    const root = getProjectRoot();
    expect(root).toBe(path.resolve(TARGET_ROOT));
    expect(path.isAbsolute(root)).toBe(true);
    expect(fs.existsSync(path.join(root, '.claude'))).toBe(true);
  });
});

describe('project-root.js — walk-up resolution', () => {
  let project: TempProject;
  beforeEach(() => {
    project = createTempProject({ copyScripts: false, seedGeneratedDocs: false, prefix: 'project-root' });
  });
  afterEach(() => { project.cleanup(); });

  it('walks up to the nearest ancestor containing .claude', () => {
    fs.mkdirSync(project.join('.claude'), { recursive: true });
    const start = project.join('a', 'b', 'c');
    fs.mkdirSync(start, { recursive: true });
    expect(getProjectRoot(start)).toBe(path.resolve(project.root));
  });

  it('recognises .git as a fallback marker', () => {
    fs.mkdirSync(project.join('.git'), { recursive: true });
    const start = project.join('x', 'y');
    fs.mkdirSync(start, { recursive: true });
    expect(getProjectRoot(start)).toBe(path.resolve(project.root));
  });

  it('recognises .git when it is a file (git worktree layout)', () => {
    // Worktrees and submodules use a .git FILE, not a directory; existsSync
    // matches both, so the worktree root still resolves correctly.
    fs.writeFileSync(project.join('.git'), 'gitdir: /elsewhere/.git/worktrees/wt\n');
    const start = project.join('pkg');
    fs.mkdirSync(start, { recursive: true });
    expect(getProjectRoot(start)).toBe(path.resolve(project.root));
  });

  it('stops at the nearest marker, not a farther one (nested-repo safety)', () => {
    // Outer marker at <root>/.git, inner marker at <root>/inner/.claude. Starting
    // below inner must resolve to inner — never overshoot to the outer.
    fs.mkdirSync(project.join('.git'), { recursive: true });
    fs.mkdirSync(project.join('inner', '.claude'), { recursive: true });
    const start = project.join('inner', 'sub', 'deep');
    fs.mkdirSync(start, { recursive: true });
    expect(getProjectRoot(start)).toBe(path.resolve(project.root, 'inner'));
  });

  it('returns the start dir itself when it holds the marker', () => {
    fs.mkdirSync(project.join('.claude'), { recursive: true });
    expect(getProjectRoot(project.root)).toBe(path.resolve(project.root));
  });
});
