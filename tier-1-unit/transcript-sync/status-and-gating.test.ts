/**
 * Criterion 3 — the `/status` recording line (incl. the dev-repo line), plus the core invariant
 * "nothing is sent until the notice has been shown".
 *
 * The status line is checked through the real CLI (`transcript-sync.js --status`). The send-gate is checked by
 * loading the target's core in-process with an injected `fetch` spy and a stubbed transcript store: with no
 * noticed session nothing is bound so `fetch` is never called; once a session is recorded in notices.json a
 * catch-up binds the file and reaches the network. Fully offline.
 *
 * Fail-closed: skips when the feature surface is absent; RED under REQUIRE_TRANSCRIPT_SYNC=1.
 */
import { describe, it, expect, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { PRESENT, runCli, loadCore, uuid, freshHome } from '../../helpers/transcript-sync';
import { createTempProject } from '../../helpers/temp-project';

const RECEIVER = 'https://receiver.test';
const DEV_REPO_LINE = 'Session recording: off (this is the template dev repo).';

describe.skipIf(!PRESENT)('session-recording /status line', () => {
  const cleanups: Array<() => void> = [];
  afterEach(() => {
    while (cleanups.length) cleanups.pop()!();
  });

  function project(opts: { devRepo?: boolean } = {}): { root: string; home: string } {
    const proj = createTempProject({ copyScripts: false, seedGeneratedDocs: false, prefix: 'tsync-status' });
    const { home, cleanup } = freshHome();
    cleanups.push(proj.cleanup, cleanup);
    if (opts.devRepo) proj.write('.release-ignore', 'dev repo sentinel\n');
    return { root: proj.root, home };
  }

  it('reads exactly the dev-repo line in the template dev repo', () => {
    const { root, home } = project({ devRepo: true });
    const res = runCli(root, ['--status'], { home, receiverUrl: RECEIVER });
    expect(res.exitCode).toBe(0);
    expect(res.stdout.trim()).toBe(DEV_REPO_LINE);
  });

  it('reads an "on for this project" line in a normal configured project', () => {
    const { root, home } = project();
    const res = runCli(root, ['--status'], { home, receiverUrl: RECEIVER });
    expect(res.exitCode).toBe(0);
    expect(res.stdout.trim()).toMatch(/^Session recording: on for this project/);
  });

  it('prints nothing, and reports configured:false, when no receiver is set (feature inert)', () => {
    const { root, home } = project();
    const res = runCli(root, ['--status'], { home, receiverUrl: '' });
    expect(res.exitCode).toBe(0);
    expect(res.stderr).toBe('');
    expect(res.stdout.trim()).toBe('');
    // Positive signal (not just empty stdout): the machine-readable status says it is off.
    const json = runCli(root, ['--status', '--json'], { home, receiverUrl: '' });
    expect((json.parsedJson as { configured?: boolean })?.configured).toBe(false);
  });
});

describe.skipIf(!PRESENT)('nothing is sent until the notice is shown — then earlier sessions catch up', () => {
  const cleanups: Array<() => void> = [];
  afterEach(() => {
    while (cleanups.length) cleanups.pop()!();
  });

  it('no network before a noticed session; after one notice, the current AND an earlier session upload', async () => {
    const { createCore } = loadCore();
    const proj = createTempProject({ copyScripts: false, seedGeneratedDocs: false, prefix: 'tsync-gate' });
    const { home, cleanup } = freshHome();
    cleanups.push(proj.cleanup, cleanup);

    // Two real transcripts on disk: the session that shows the notice, and an EARLIER, different session that
    // never showed it (the "earlier sessions still on the machine" case). The stubbed store surfaces both.
    const noticeSession = uuid();
    const olderSession = uuid();
    const currentFile = proj.write(`transcripts/${noticeSession}.jsonl`, JSON.stringify({ type: 'user', text: 'now' }) + '\n');
    const olderFile = proj.write(`transcripts/${olderSession}.jsonl`, JSON.stringify({ type: 'user', text: 'earlier' }) + '\n');
    const past = new Date('2020-01-01T00:00:00Z');
    fs.utimesSync(olderFile, past, past); // genuinely older on disk

    const deviceId = uuid();
    const urls: string[] = [];
    const fetchSpy = async (url: string) => {
      urls.push(String(url));
      if (/\/v1\/devices$/.test(String(url))) {
        // A real 200 registration, so the sweep proceeds PAST device-registration to the transcript PUT/POST.
        return { status: 200, text: async () => JSON.stringify({ machineId: deviceId, deviceKey: 'k', registeredAt: '2020-01-01T00:00:00Z' }), headers: { get: () => null } };
      }
      return { status: 200, text: async () => '', headers: { get: (n: string) => (n === 'x-blob-length' ? '1000000' : null) } };
    };
    const store = {
      SESSION_ID: /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
      discoverTranscriptDirs: () => ({ dirs: [path.dirname(currentFile)] }),
      listTranscriptFiles: () => [
        { file: currentFile, sessionId: noticeSession, kind: 'main', name: `${noticeSession}.jsonl` },
        { file: olderFile, sessionId: olderSession, kind: 'main', name: `${olderSession}.jsonl` },
      ],
    };
    const core = createCore({ fetch: fetchSpy, store, env: { STADIUM_RECEIVER_URL: RECEIVER, STADIUM_BUILDER_HOME: home } });

    const init = core.initProject(proj.root);
    expect(init.ok).toBe(true);
    const projectId = init.collection.projectId as string;

    // Before any notice → nothing is bound → no network at all (the privacy gate).
    await core.catchUp({ root: proj.root, noticeSession });
    expect(urls, 'no network before the notice has been shown').toEqual([]);

    // One session shows the notice → it unlocks the whole project's backlog.
    core.recordSessionNotice(noticeSession, projectId, new Date().toISOString());
    await core.catchUp({ root: proj.root, noticeSession });

    expect(urls.some((u) => /\/v1\/devices$/.test(u)), 'device registers once a file is bound').toBe(true);
    expect(urls.some((u) => u.includes(noticeSession)), 'the noticed session is uploaded').toBe(true);
    expect(urls.some((u) => u.includes(olderSession)), 'an EARLIER session on the machine is also uploaded').toBe(true);
  });
});
