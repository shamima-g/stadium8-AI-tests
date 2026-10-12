/**
 * Criterion 1 (notice + help-page content) and the static wiring the other criteria rely on. All deterministic
 * reads of the target template — no AI judge, no live run.
 *
 *  - transcript-notice.md starts "SESSION RECORDING" and points to the help page.
 *  - Session-Recording.md lists WHAT is recorded and WHO can read it / where it goes.
 *  - status.md runs `transcript-sync.js --status`; start.md stages transcript-collection.json in the INTAKE
 *    commit; settings.json registers the hook on UserPromptSubmit.
 *
 * Fail-closed: skips when the feature surface is absent; RED under REQUIRE_TRANSCRIPT_SYNC=1.
 */
import { describe, it, expect } from 'vitest';
import { PRESENT, targetFile, NOTICE_REL, HELP_REL, STATUS_CMD_REL, START_CMD_REL } from '../../helpers/transcript-sync';

describe.skipIf(!PRESENT)('session-recording notice + help page content', () => {
  it('the notice starts "SESSION RECORDING" and points to the help page', () => {
    const notice = targetFile(NOTICE_REL).trim();
    expect(notice).toMatch(/^SESSION RECORDING/);
    expect(notice).toContain('.template-docs/users/Help/Session-Recording.md');
  });

  it('the help page lists WHAT is recorded', () => {
    const help = targetFile(HELP_REL);
    expect(help).toMatch(/what is recorded/i);
    expect(help).toMatch(/everything you type/i);           // typed input + replies
    expect(help).toMatch(/files? .*(reads|writes)/i);       // code/files read & written
    expect(help).toMatch(/schemas|specs|sample data/i);     // database schemas / API specs / sample data
    expect(help).toMatch(/file paths/i);                    // paths (contain the username)
  });

  it('the help page says WHO can read the recordings and where they go', () => {
    const help = targetFile(HELP_REL);
    expect(help).toMatch(/Twenty57/);
    expect(help).toMatch(/Azure/i);
    expect(help).toMatch(/only named Twenty57 staff/i);
  });
});

describe.skipIf(!PRESENT)('session-recording wiring', () => {
  it('/status runs `transcript-sync.js --status`', () => {
    expect(targetFile(STATUS_CMD_REL)).toMatch(/transcript-sync\.js --status/);
  });

  it('/start stages transcript-collection.json in the INTAKE commit', () => {
    const start = targetFile(START_CMD_REL);
    expect(start).toMatch(/git add transcript-collection\.json/);
    // It is added alongside the first project commit, not an epic-branch commit.
    expect(start).toMatch(/docs\(project\)/);
  });

  it('the hook is registered on UserPromptSubmit in settings.json', () => {
    const settings = targetFile('.claude/settings.json');
    expect(settings).toContain('transcript-sync-hook.js');
    expect(settings).toContain('UserPromptSubmit');
  });
});
