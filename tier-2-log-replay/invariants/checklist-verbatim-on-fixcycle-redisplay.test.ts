/**
 * S8-80 Phase 6 — Tier 2 invariant: checklist verbatim on fix-cycle re-display.
 *
 * In a harvested QA log that includes at least one "Issues found" fix cycle,
 * the assistant message that re-asks the verification question after the fix
 * MUST contain the EXACT byte sequence of the persisted checklist file. No
 * abbreviation, no paraphrasing, no "see above". This invariant catches the
 * exact regression S8-80 fixed.
 *
 * Implementation:
 *   1. Find the checklist file path written by Call B (first matching Write).
 *   2. Read the file content from disk (the canonical text).
 *   3. For each "Issues found" prompt, find the next response/ask_user_question
 *      event in the same conversation arc.
 *   4. Assert that response/event raw text contains the file content
 *      byte-for-byte (after CRLF normalisation).
 *
 * SKIP GUARD: This test is skipped when no post-S8-80 golden log is available.
 * Additionally, even when a log is present, the test only runs if the log
 * contains at least one "Issues found" fix cycle — happy-path-only logs
 * trigger the deferred warning.
 *
 * Pattern source: invariants/issues-found-delegates.test.ts
 */

import fs from 'node:fs';
import path from 'node:path';
import { describe, it, expect } from 'vitest';
import { loadGoldenLog } from '../verify-session-behavior';

const CHECKLIST_PATH = /generated-docs[\\/]qa[\\/].+story-\d+-[a-z0-9-]+-verification-checklist\.md/i;

function normalise(text: string): string {
  return text.replace(/\r\n/g, '\n').trim();
}

function extractChecklistPath(raw: string): string | null {
  const m = raw.match(CHECKLIST_PATH);
  return m ? m[0] : null;
}

describe('S8-80 — Tier 2 — checklist verbatim on fix-cycle re-display', () => {
  const loaded = loadGoldenLog('full-happy-path');

  it.skipIf(!loaded.available)(
    'PASS: every fix-cycle re-ask contains the checklist file content byte-for-byte',
    () => {
      const log = loaded.log!;

      // Locate the Write that persisted the checklist
      const writeEvent = log.events.find(e =>
        e.type === 'tool_call'
        && e.toolName === 'Write'
        && CHECKLIST_PATH.test(e.raw ?? ''),
      );
      if (!writeEvent) {
        console.warn(
          's8-80 / fixcycle-verbatim: no checklist Write found in golden log — covered by checklist-file-written-before-manual-verify.test.ts; skipping verbatim check.',
        );
        return;
      }

      const checklistPath = extractChecklistPath(writeEvent.raw ?? '');
      expect(checklistPath, 'could not extract checklist path from Write event').not.toBeNull();

      const absChecklistPath = path.resolve(checklistPath!);
      if (!fs.existsSync(absChecklistPath)) {
        // The file referenced in the log no longer exists on disk (story
        // since cleaned up). Re-harvesting will be needed; flag and skip
        // rather than fail.
        console.warn(
          `s8-80 / fixcycle-verbatim: ${absChecklistPath} no longer exists on disk — re-harvest needed.`,
        );
        return;
      }

      const fileContent = normalise(fs.readFileSync(absChecklistPath, 'utf8'));

      // Find every "Issues found" prompt and the next assistant
      // response/ask_user_question that follows it in the same conversation.
      const issuesPrompts = log.events
        .map((e, i) => ({ e, i }))
        .filter(({ e }) => e.type === 'prompt' && /issues found/i.test(e.content ?? ''));

      if (issuesPrompts.length === 0) {
        console.warn(
          's8-80 / fixcycle-verbatim: golden log contains no "Issues found" cycle — happy-path-only run; re-harvest with at least one fix cycle to cover this surface.',
        );
        return;
      }

      for (const { i } of issuesPrompts) {
        const window = log.events.slice(i + 1, i + 30);
        const reAsk = window.find(ev =>
          ev.type === 'ask_user_question'
          && /All tests pass[\s\S]*Issues found[\s\S]*Skip for now/i.test(ev.raw ?? ''),
        );
        expect(
          reAsk,
          `no re-verification AskUserQuestion found within 30 events after "Issues found" at event ${i}`,
        ).toBeDefined();

        const reAskText = normalise(reAsk!.raw ?? '');
        expect(
          reAskText.includes(fileContent),
          `re-verification AskUserQuestion at event ${log.events.indexOf(reAsk!)} does not contain the checklist file content verbatim. The orchestrator paraphrased, abbreviated, or replaced the checklist with "see above". File: ${absChecklistPath}`,
        ).toBe(true);
      }
    },
  );

  it.skipIf(loaded.available)(
    'DEFERRED: skipping until a post-S8-80 golden log with a fix cycle is harvested',
    () => {
      expect(loaded.available).toBe(false);
      console.warn(
        `s8-80 / Tier 2 deferred: ${loaded.reason ?? 'no golden log'}`,
      );
    },
  );

  it('FAIL: detector flags missing verbatim content', () => {
    // Validate the detector logic independently of any golden log.
    const fileContent = 'Step 1: do X\nStep 2: do Y';
    const reAskTextDrifted = 'Step 1: do something\nStep 2: do something else';
    expect(reAskTextDrifted.includes(fileContent)).toBe(false);
  });
});
