/**
 * Criterion 2 — everyone who clones a project records under the same project.
 *
 * The workflow mints `transcript-collection.json` (a uuid project id) and commits it, so a second clone /
 * second developer joins the SAME project instead of starting a new one. This proves it deterministically with
 * a real local git repo + `git clone` (no live AI needed): mint → commit → `git ls-files` → clone → the clone
 * reads the same id and mints nothing new.
 *
 * Fail-closed: skips when the feature surface is absent; RED under REQUIRE_TRANSCRIPT_SYNC=1.
 */
import { describe, it, expect, afterEach } from 'vitest';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createTempProject } from '../../helpers/temp-project';
import { PRESENT, runCli, runHook, userPrompt, freshHome, additionalContext } from '../../helpers/transcript-sync';

const RECEIVER = 'https://receiver.test';

function git(cwd: string, ...args: string[]): string {
  return execFileSync('git', args, {
    cwd,
    encoding: 'utf8',
    env: { ...process.env, GIT_CONFIG_GLOBAL: path.join(os.tmpdir(), 'nonexistent-gitconfig'), GIT_CONFIG_SYSTEM: path.join(os.tmpdir(), 'nonexistent-gitconfig') },
  }).trim();
}
function commitAll(cwd: string, message: string): void {
  git(cwd, '-c', 'user.email=t@t.co', '-c', 'user.name=tester', 'commit', '-m', message);
}

const readId = (file: string): string =>
  (JSON.parse(fs.readFileSync(file, 'utf8')) as { projectId: string }).projectId.toLowerCase();

describe.skipIf(!PRESENT)('transcript-collection project id — committed and shared across clones', () => {
  const cleanups: Array<() => void> = [];
  afterEach(() => {
    while (cleanups.length) cleanups.pop()!();
  });

  it('is minted, committed (git ls-files lists it), and a clone joins the same id', () => {
    // A fresh git project (no .release-ignore → not the dev repo).
    const proj = createTempProject({ copyScripts: false, seedGeneratedDocs: false, prefix: 'tsync-a' });
    const { home, cleanup: homeCleanup } = freshHome();
    cleanups.push(proj.cleanup, homeCleanup);
    git(proj.root, 'init', '-q');
    git(proj.root, 'symbolic-ref', 'HEAD', 'refs/heads/main');

    // Mint the id as the first interactive prompt would (the CLI shares core.initProject with the hook).
    const mint = runCli(proj.root, ['--init-project'], { home, receiverUrl: RECEIVER });
    expect(mint.stdout).toMatch(/Created transcript-collection\.json/);
    expect(proj.exists('transcript-collection.json')).toBe(true);

    // Reproduce the INTAKE commit (start.md stages transcript-collection.json).
    git(proj.root, 'add', 'transcript-collection.json');
    commitAll(proj.root, 'docs(project): project setup + epic plan');

    // git ls-files lists it (criterion 2, step 1).
    expect(git(proj.root, 'ls-files', 'transcript-collection.json')).toBe('transcript-collection.json');
    const projectId = readId(proj.join('transcript-collection.json'));
    expect(projectId).toMatch(/^[0-9a-f-]{36}$/);

    // Clone into a second folder.
    const cloneRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'tsync-clone-'));
    cleanups.push(() => { try { fs.rmSync(cloneRoot, { recursive: true, force: true }); } catch { /* best effort */ } });
    const cloneDir = path.join(cloneRoot, 'project-b');
    git(cloneRoot, 'clone', '-q', proj.root, 'project-b');

    // A session in the clone (first message) is asked to show the notice and does NOT mint a new id.
    const res = runHook(cloneDir, userPrompt(), { home, receiverUrl: RECEIVER });
    expect(additionalContext(res), 'the clone is asked to show the notice').toContain('SESSION RECORDING');

    // The clone's id is the one we wrote down (criterion 2, step 4), not a fresh one.
    expect(readId(path.join(cloneDir, 'transcript-collection.json'))).toBe(projectId);
  });
});
