/**
 * Criterion 1 (the recording notice) + Criterion 3 (headless & dev-repo record nothing) — hook behaviour.
 *
 * Drives the target's `transcript-sync-hook.js` over throwaway projects with all side-effects redirected to a
 * temp STADIUM_BUILDER_HOME (see helpers/transcript-sync.ts). The hook emits the notice as a user-visible
 * `systemMessage`; these tests assert when it does and doesn't.
 *
 * Scope notes: these tests prove the hook EMITS (or suppresses) the notice — that it renders *under* the first
 * message is a UI behaviour checked by the manual walkthrough (tier-3 transcript-recording-live.ps1 -Phase
 * notice). The headless cases set CLAUDE_CODE_ENTRYPOINT by hand to prove the hook TREATS that value as
 * headless; that a real `claude -p` actually sets such a value is the gated live ps1's job. Suppression is
 * asserted by empty stdout AND exit 0 AND empty stderr (so a swallowed crash can't masquerade as "suppressed").
 *
 * Fail-closed: skips when the feature surface is absent in the target; RED under REQUIRE_TRANSCRIPT_SYNC=1.
 */
import { describe, it, expect, afterEach } from 'vitest';
import { createTempProject, type TempProject } from '../../helpers/temp-project';
import { PRESENT, runHook, userPrompt, uuid, freshHome } from '../../helpers/transcript-sync';

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

  /** A suppressed run: empty stdout, exit 0, empty stderr (no swallowed crash), and no id minted. */
  function expectSuppressed(res: ReturnType<typeof runHook>, proj: TempProject): void {
    expect(res.stdout.trim()).toBe('');
    expect((res.parsedJson as { systemMessage?: string })?.systemMessage).toBeUndefined();
    expect(res.exitCode).toBe(0);
    expect(res.stderr).toBe('');
    expect(proj.exists('transcript-collection.json')).toBe(false);
  }

  it('emits the "SESSION RECORDING" notice as a systemMessage on the first prompt, pointing to the help page', () => {
    const { proj, home } = project();
    const res = runHook(proj.root, userPrompt(), { home, receiverUrl: RECEIVER });
    const msg = (res.parsedJson as { systemMessage?: string })?.systemMessage ?? '';
    expect(msg).toMatch(/^SESSION RECORDING/);
    expect(msg).toContain('.template-docs/users/Help/Session-Recording.md');
    // The notice path also mints the project's id file locally (no network).
    expect(proj.exists('transcript-collection.json')).toBe(true);
  });

  it('emits the notice only once per session, but again in a new session', () => {
    const { proj, home } = project();
    const session = uuid();
    const first = runHook(proj.root, userPrompt(session), { home, receiverUrl: RECEIVER });
    expect((first.parsedJson as { systemMessage?: string })?.systemMessage ?? '').toMatch(/^SESSION RECORDING/);

    // Same session, second prompt → no notice (and not a swallowed crash).
    const second = runHook(proj.root, userPrompt(session), { home, receiverUrl: RECEIVER });
    expect(second.stdout.trim()).toBe('');
    expect((second.parsedJson as { systemMessage?: string })?.systemMessage).toBeUndefined();
    expect(second.exitCode).toBe(0);
    expect(second.stderr).toBe('');

    // A brand-new session in the same project → notice again (a new session re-tells the user).
    const third = runHook(proj.root, userPrompt(uuid()), { home, receiverUrl: RECEIVER });
    expect((third.parsedJson as { systemMessage?: string })?.systemMessage ?? '').toMatch(/^SESSION RECORDING/);
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
