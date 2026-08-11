/**
 * A report for one project never folds in a same-prefix sibling's work (post-v1.2.0).
 *
 * Claude Code stores each project's transcripts under ~/.claude/projects/<slug>/, where
 * <slug> is the project's absolute path with every non-alphanumeric char replaced by '-'.
 * The workflow makes each parallel-plan worktree a SIBLING dir (`../<project>-plan-<epic>`),
 * whose slug extends the project's — so those transcripts must be counted. But three separate
 * checkouts sitting side by side (`my-app`, `my-app-QA`, `my-app-upsidedown`) also share the
 * prefix, and folding a stranger's spend in inflates the effort report's cost ratios — the
 * numbers a client is quoted. The fix asks git `worktree list`: a listed sibling belongs, an
 * unlisted one is a different project whatever it's named.
 *
 * The template's `lib/report-core.tests.js` covers the matcher in isolation. This drives the
 * exported `discoverTranscriptDirs()` over a REAL git worktree and a REAL non-worktree sibling
 * — the integration angle the unit test stubs — importing the live module under test.
 * Feature-detected on `report-core.mjs`; skips cleanly on a template that predates it.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { pathToFileURL } from 'node:url';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, gitSandbox, REPO_ROOT } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const RC_REL = '.claude/scripts/lib/report-core.mjs';
const RC_PRESENT = fs.existsSync(path.join(REPO_ROOT, RC_REL));

// Mirrors report-core.mjs slugifyPath — same transform the store uses for a dir name.
const slugifyPath = (p: string): string => p.replace(/[^a-zA-Z0-9]/g, '-');

async function loadDiscover(): Promise<
  (root: string, override?: string) => { dirs: string[]; slug: string; projectsRoot: string }
> {
  const mod = await import(pathToFileURL(path.join(REPO_ROOT, RC_REL)).href);
  return mod.discoverTranscriptDirs;
}

describe('transcript discovery — a same-prefix sibling is not counted as this project (v1.2.0)', () => {
  let project: TempProject;
  let overrideRoot = '';
  let worktreePath = '';

  beforeEach(() => {
    project = createTempProject();
    overrideRoot = '';
    worktreePath = '';
  });
  afterEach(() => {
    if (worktreePath) fs.rmSync(worktreePath, { recursive: true, force: true });
    if (overrideRoot) fs.rmSync(overrideRoot, { recursive: true, force: true });
    project.cleanup();
  });

  it.skipIf(!RC_PRESENT)(
    'a git-worktree sibling is included; a same-prefix NON-worktree sibling is excluded',
    async () => {
      const git = gitSandbox(project.root);
      project.write('README.md', '# fixture\n');
      git.commit('seed');

      const base = path.basename(project.root);
      // A real worktree of THIS repo, created as a sibling like the workflow does.
      worktreePath = path.join(path.dirname(project.root), `${base}-plan-epicx`);
      const wt = git.git('worktree', 'add', '--detach', worktreePath, 'HEAD');
      expect(wt.exitCode, `git worktree add failed: ${wt.stderr}`).toBe(0);

      // Build a transcripts store snapshot with three same-prefix dirs.
      const slug = slugifyPath(project.root);
      overrideRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'qa-transcripts-'));
      const mk = (name: string) => fs.mkdirSync(path.join(overrideRoot, name), { recursive: true });
      mk(slug); // primary — this project's own transcripts
      mk(`${slug}-plan-epicx`); // the worktree's transcripts — must be INCLUDED
      mk(`${slug}-QA`); // a same-prefix stranger, not a worktree — must be EXCLUDED

      const discoverTranscriptDirs = await loadDiscover();
      const { dirs } = discoverTranscriptDirs(project.root, overrideRoot);
      const names = dirs.map((d) => path.basename(d));

      // Good case: the project's own + its real worktree are discovered.
      expect(names, "the project's own transcripts are found").toContain(slug);
      expect(names, 'a real git-worktree sibling belongs to the project').toContain(`${slug}-plan-epicx`);
      // Broken case (the fix): a same-prefix NON-worktree must not be folded in. If the
      // discovery regressed to a bare prefix match, `${slug}-QA` would appear here → red.
      expect(names, 'a same-prefix non-worktree sibling must not be counted').not.toContain(`${slug}-QA`);
    },
  );
});
