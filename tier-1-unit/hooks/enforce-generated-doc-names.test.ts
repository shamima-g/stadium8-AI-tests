/**
 * Tests for .claude/hooks/enforce-generated-doc-names.js
 *
 * PreToolUse gate that blocks Write/Edit/MultiEdit on generated docs whose
 * filenames drift from .claude/shared/generated-doc-conventions.json.
 *   exit 0 = allow (fall through) · exit 2 = block.
 *
 * Covers all six conventions with a good (allowed) and a drift (blocked) case, plus
 * the fall-through paths (non-gated tool, ungoverned file, grandfathered existing
 * file) and the web/ write-location guard.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, runScript, REPO_ROOT } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const HOOK = '.claude/hooks/enforce-generated-doc-names.js';
const CONVENTIONS_REL = path.join('.claude', 'shared', 'generated-doc-conventions.json');

/** The hook reads the conventions from CLAUDE_PROJECT_DIR — copy them into the temp project. */
function seedConventions(root: string): void {
  const dst = path.join(root, CONVENTIONS_REL);
  fs.mkdirSync(path.dirname(dst), { recursive: true });
  fs.copyFileSync(path.join(REPO_ROOT, CONVENTIONS_REL), dst);
}

function runHook(root: string, filePath: string, toolName = 'Write') {
  return runScript(HOOK, [], {
    cwd: root,
    input: JSON.stringify({ tool_name: toolName, tool_input: { file_path: filePath } }),
  });
}

// One good + one drift filename per convention, in the directory that convention governs.
const EPIC = 'generated-docs/epics/task-browsing';
const CASES: { id: string; dir: string; good: string; bad: string }[] = [
  { id: 'project-facts', dir: 'generated-docs', good: 'project.md', bad: 'project-facts.md' },
  { id: 'epic-brief', dir: EPIC, good: 'brief.md', bad: 'epic-brief.md' },
  { id: 'epic-state', dir: EPIC, good: 'state.json', bad: 'epic-state.json' },
  { id: 'epic-journal', dir: EPIC, good: 'journal.md', bad: 'epic-journal.md' },
  { id: 'story-file', dir: `${EPIC}/stories`, good: 'story-3-nav.md', bad: 'story-3.md' },
  { id: 'e2e-spec', dir: 'web/e2e', good: 'epic-task-browsing-story-3-nav.spec.ts', bad: 'story-3-nav.spec.ts' },
];

describe('enforce-generated-doc-names.js — the six conventions', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); seedConventions(project.root); });
  afterEach(() => { project.cleanup(); });

  for (const c of CASES) {
    it(`PASS: [${c.id}] a correctly-named new file is allowed (${c.good})`, () => {
      const r = runHook(project.root, `${c.dir}/${c.good}`);
      expect(r.exitCode, r.stderr).toBe(0);
    });

    it(`FAIL: [${c.id}] a drift-named new file is blocked (${c.bad})`, () => {
      const r = runHook(project.root, `${c.dir}/${c.bad}`);
      expect(r.exitCode).toBe(2);
      expect(r.stderr).toMatch(/Blocked by filename-convention guard/);
    });
  }
});

describe('enforce-generated-doc-names.js — fall-through and guards', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); seedConventions(project.root); });
  afterEach(() => { project.cleanup(); });

  it('PASS: a non-gated tool (Read) falls through', () => {
    expect(runHook(project.root, 'generated-docs/project-facts.md', 'Read').exitCode).toBe(0);
  });

  it('PASS: an ungoverned filename under a governed dir falls through', () => {
    expect(runHook(project.root, `${EPIC}/notes.txt`).exitCode).toBe(0);
  });

  it('PASS: a drift name is grandfathered when the file already exists on disk', () => {
    // Enforcement only stops NEW drift; edits to a pre-existing (legacy) file are allowed.
    project.write(`${EPIC}/epic-state.json`, '{}');
    expect(runHook(project.root, `${EPIC}/epic-state.json`).exitCode).toBe(0);
  });

  it('FAIL: the write-location guard blocks an artifact path nested under web/', () => {
    const r = runHook(project.root, 'web/generated-docs/project.md');
    expect(r.exitCode).toBe(2);
    expect(r.stderr).toMatch(/write-location guard/i);
  });
});
