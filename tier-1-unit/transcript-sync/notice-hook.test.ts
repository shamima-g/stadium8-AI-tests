/**
 * Criterion 1 (the recording notice) + Criterion 3 (headless & dev-repo record nothing) — hook behaviour.
 *
 * Drives the target's `transcript-sync-hook.js` over throwaway projects with all side-effects redirected to a
 * temp STADIUM_BUILDER_HOME (see helpers/transcript-sync.ts). The hook does NOT emit a `systemMessage` (the VS
 * Code extension receives one but never displays it). Instead, on UserPromptSubmit it asks Claude — through
 * `hookSpecificOutput.additionalContext` — to open its reply with the notice, repeating every prompt until a
 * Stop records the session in notices.json. The Stop records a session ONLY once Claude's own reply has shown
 * the notice — proven either by the final reply (`last_assistant_message`) or the session transcript — and
 * withholds it otherwise (the consent-before-upload gate). These tests assert BOTH directions of that gate, the
 * transcript route and its anti-spoof filters (a sub-agent `isSidechain` reply or another session's text does
 * not count), and that the first-sentence proof tolerates a reformatted/linked notice.
 *
 * Scope notes: these tests prove the hook ASKS (or suppresses), records once shown, and withholds when not —
 * that Claude's reply renders *under* the first message is a UI behaviour checked by the manual walkthrough
 * (tier-3 transcript-recording-live.ps1 -Phase notice). The headless cases set CLAUDE_CODE_ENTRYPOINT by hand to
 * prove the hook TREATS that value as headless; that a real `claude -p` actually sets such a value is the gated
 * live ps1's job. Suppression is asserted by empty stdout AND exit 0 AND empty stderr (so a swallowed crash
 * can't masquerade as "suppressed"). Observing the detached `--catch-up` spawn is out of scope here (brittle for
 * a unit); that nothing uploads before a session is recorded is covered in status-and-gating.test.ts.
 *
 * Fail-closed: skips when the feature surface is absent in the target; RED under REQUIRE_TRANSCRIPT_SYNC=1.
 */
import { describe, it, expect, afterEach } from 'vitest';
import fs from 'node:fs';
import { createTempProject, type TempProject } from '../../helpers/temp-project';
import {
  PRESENT, runHook, userPrompt, uuid, freshHome, additionalContext, stop, loadCore, targetFile, NOTICE_REL,
} from '../../helpers/transcript-sync';

const REQUIRE = /^(1|true|yes)$/i.test(process.env.REQUIRE_TRANSCRIPT_SYNC ?? '');
const RECEIVER = 'https://receiver.test';

describe('transcript-sync feature present', () => {
  (PRESENT || REQUIRE ? it : it.skip)(
    'the hook + CLI exist in the target template (point REPO_ROOT at a template that has the feature)',
    () => {
      expect(PRESENT, 'transcript-sync-hook.js / transcript-sync.js not found in the target .claude').toBe(true);
    }
  );
});

if (!PRESENT) {
  // eslint-disable-next-line no-console
  console.warn('[transcript-sync] feature absent in target — notice-hook checks skipped (REQUIRE_TRANSCRIPT_SYNC=1 to red)');
}

describe.skipIf(!PRESENT)('session-recording notice hook', () => {
  const cleanups: Array<() => void> = [];
  afterEach(() => {
    while (cleanups.length) cleanups.pop()!();
  });

  function project(opts: { devRepo?: boolean } = {}): { proj: TempProject; home: string } {
    const proj = createTempProject({ copyScripts: false, seedGeneratedDocs: false, prefix: 'tsync-proj' });
    const { home, cleanup } = freshHome();
    cleanups.push(proj.cleanup, cleanup);
    if (opts.devRepo) proj.write('.release-ignore', 'template dev repo sentinel\n');
    return { proj, home };
  }

  /** A suppressed run: empty stdout, exit 0, empty stderr (no swallowed crash), nothing asked, and no id minted. */
  function expectSuppressed(res: ReturnType<typeof runHook>, proj: TempProject): void {
    expect(res.stdout.trim()).toBe('');
    expect((res.parsedJson as { systemMessage?: string })?.systemMessage).toBeUndefined();
    expect(additionalContext(res)).toBe('');
    expect(res.exitCode).toBe(0);
    expect(res.stderr).toBe('');
    expect(proj.exists('transcript-collection.json')).toBe(false);
  }

  /**
   * A configured project whose id file has been minted by a first (interactive) prompt — the state every Stop
   * test starts from. Returns the handles a Stop test needs to assert whether notices.json recorded the session.
   */
  interface Armed {
    proj: TempProject;
    home: string;
    session: string;
    notice: string;
    projectId: string;
    core: { sessionNotice(sessionId: string, projectId: string): unknown };
  }
  function arm(): Armed {
    const { proj, home } = project();
    const session = uuid();
    // The first prompt mints transcript-collection.json and asks for the notice.
    runHook(proj.root, userPrompt(session), { home, receiverUrl: RECEIVER });
    const notice = targetFile(NOTICE_REL);
    const projectId = (
      JSON.parse(fs.readFileSync(proj.join('transcript-collection.json'), 'utf8')) as { projectId: string }
    ).projectId;
    const core = loadCore().createCore({ env: { STADIUM_BUILDER_HOME: home, STADIUM_RECEIVER_URL: RECEIVER } }) as Armed['core'];
    return { proj, home, session, notice, projectId, core };
  }

  /** The notice's first sentence — the only part the hook requires a reply to echo (noticeProof). */
  const firstSentence = (notice: string): string => notice.match(/^[\s\S]*?[.!?](?=\s|$)/)?.[0] ?? notice;

  it('asks Claude (via additionalContext) to show the SESSION RECORDING notice on the first prompt, pointing to the help page', () => {
    const { proj, home } = project();
    const res = runHook(proj.root, userPrompt(), { home, receiverUrl: RECEIVER });
    // The notice travels in additionalContext for Claude to show in its reply — NOT a hook systemMessage, which
    // the VS Code extension receives but never displays.
    expect((res.parsedJson as { systemMessage?: string })?.systemMessage).toBeUndefined();
    const ctx = additionalContext(res);
    expect(ctx).toContain('SESSION RECORDING');
    expect(ctx).toContain('.template-docs/users/Help/Session-Recording.md');
    // The ask path also mints the project's id file locally (no network).
    expect(proj.exists('transcript-collection.json')).toBe(true);
  });

  it('asks again every prompt until a Stop records the shown session, then stays silent — and a new session asks again', () => {
    const { proj, home } = project();
    const session = uuid();

    // First prompt → the notice request.
    expect(additionalContext(runHook(proj.root, userPrompt(session), { home, receiverUrl: RECEIVER })))
      .toContain('SESSION RECORDING');

    // Same session, still no Stop has recorded it → the hook asks AGAIN (the request repeats until shown).
    expect(additionalContext(runHook(proj.root, userPrompt(session), { home, receiverUrl: RECEIVER })))
      .toContain('SESSION RECORDING');

    // A Stop whose assistant reply contains the notice → the session is recorded in notices.json.
    const notice = targetFile(NOTICE_REL);
    const stopRes = runHook(proj.root, stop(session, notice), { home, receiverUrl: RECEIVER });
    expect(stopRes.exitCode).toBe(0);
    const projectId = (
      JSON.parse(fs.readFileSync(proj.join('transcript-collection.json'), 'utf8')) as { projectId: string }
    ).projectId;
    const core = loadCore().createCore({ env: { STADIUM_BUILDER_HOME: home, STADIUM_RECEIVER_URL: RECEIVER } });
    expect(core.sessionNotice(session, projectId), 'the shown session is now listed in notices.json').toBeTruthy();

    // Recorded now → the same session is no longer asked (and not a swallowed crash).
    const after = runHook(proj.root, userPrompt(session), { home, receiverUrl: RECEIVER });
    expect(after.stdout.trim()).toBe('');
    expect(additionalContext(after)).toBe('');
    expect(after.exitCode).toBe(0);
    expect(after.stderr).toBe('');

    // A brand-new session in the same project → asks again (a new session re-tells the user).
    expect(additionalContext(runHook(proj.root, userPrompt(uuid()), { home, receiverUrl: RECEIVER })))
      .toContain('SESSION RECORDING');
  });

  // The consent-before-upload gate: a session is enrolled for upload ONLY once Claude's own reply showed the
  // notice. The positive direction is above; these pin the negative and the two proof routes.
  it('a Stop whose reply never showed the notice records nothing, and the ask keeps repeating (consent gate)', () => {
    const { proj, home, session, projectId, core } = arm();
    // Claude replied, but without ever showing the notice.
    const res = runHook(proj.root, stop(session, 'Sure — here is what you asked for.'), { home, receiverUrl: RECEIVER });
    expect(res.exitCode).toBe(0);
    expect(core.sessionNotice(session, projectId), 'an un-shown session must NOT be enrolled for upload').toBeFalsy();
    // Not recorded → the next prompt still asks.
    expect(additionalContext(runHook(proj.root, userPrompt(session), { home, receiverUrl: RECEIVER })))
      .toContain('SESSION RECORDING');
  });

  it('records the session when the notice is proven by the transcript, not last_assistant_message', () => {
    const { proj, home, session, notice, projectId, core } = arm();
    // The final reply carries nothing; the proof lives in a main-session assistant block in the transcript.
    const line = JSON.stringify({ type: 'assistant', sessionId: session, message: { content: [{ type: 'text', text: notice }] } });
    const transcriptPath = proj.write(`transcripts/${session}.jsonl`, line + '\n');
    const res = runHook(proj.root, stop(session, '', transcriptPath), { home, receiverUrl: RECEIVER });
    expect(res.exitCode).toBe(0);
    expect(core.sessionNotice(session, projectId), 'a transcript-proven session is recorded').toBeTruthy();
  });

  it('a notice shown only by a sub-agent (isSidechain) or in another session is not proof', () => {
    const { proj, home, session, notice, projectId, core } = arm();
    // Both lines carry the notice but neither is a user-visible reply of THIS session.
    const sidechain = JSON.stringify({ type: 'assistant', isSidechain: true, sessionId: session, message: { content: [{ type: 'text', text: notice }] } });
    const foreign = JSON.stringify({ type: 'assistant', sessionId: uuid(), message: { content: [{ type: 'text', text: notice }] } });
    const transcriptPath = proj.write(`transcripts/${session}.jsonl`, sidechain + '\n' + foreign + '\n');
    const res = runHook(proj.root, stop(session, '', transcriptPath), { home, receiverUrl: RECEIVER });
    expect(res.exitCode).toBe(0);
    expect(core.sessionNotice(session, projectId), 'only the main session’s own reply counts as having shown the notice').toBeFalsy();
  });

  it('a reformatted reply — first sentence only, re-punctuated, help path linked — still counts as shown', () => {
    const { proj, home, session, notice, projectId, core } = arm();
    // The realistic production shape: Claude bolds the notice and turns the help path into a link, dropping the
    // verbatim second sentence. noticeProof + comparableText must tolerate this.
    const reformatted = `> **${firstSentence(notice)}** — [details](https://example.test/help)`;
    const res = runHook(proj.root, stop(session, reformatted), { home, receiverUrl: RECEIVER });
    expect(res.exitCode).toBe(0);
    expect(core.sessionNotice(session, projectId), 'a first-sentence match after normalization is enough').toBeTruthy();
  });

  it('a headless Stop that shows the notice still records nothing (a headless run never uploads)', () => {
    const { proj, home, session, notice, projectId, core } = arm();
    const res = runHook(proj.root, stop(session, notice), { home, receiverUrl: RECEIVER, entrypoint: 'sdk' });
    expect(res.exitCode).toBe(0);
    expect(core.sessionNotice(session, projectId), 'headless sessions are never enrolled').toBeFalsy();
  });

  it.each(['sdk', 'print'])('a headless run (CLAUDE_CODE_ENTRYPOINT=%s) shows nothing and mints nothing', (entry) => {
    const { proj, home } = project();
    expectSuppressed(runHook(proj.root, userPrompt(), { home, receiverUrl: RECEIVER, entrypoint: entry }), proj);
  });

  it('the template dev repo (.release-ignore) shows nothing and mints nothing', () => {
    const { proj, home } = project({ devRepo: true });
    expectSuppressed(runHook(proj.root, userPrompt(), { home, receiverUrl: RECEIVER }), proj);
  });

  it('with no receiver configured the feature is inert (no notice, no id file)', () => {
    const { proj, home } = project();
    expectSuppressed(runHook(proj.root, userPrompt(), { home, receiverUrl: '' }), proj);
  });
});
