/**
 * S8-80 Phase 6 — Tier 2 invariant: checklist verbatim on free-text re-ask.
 *
 * In a harvested QA log where the user replied to the manual-verification
 * AskUserQuestion with a free-text question (instead of picking one of the
 * three options), the orchestrator must (1) answer the question, then (2)
 * re-ask AskUserQuestion with the FULL checklist content re-displayed
 * verbatim from the persisted file.
 *
 * Detection heuristic for the free-text branch:
 *   A user prompt that follows a manual-verification AskUserQuestion AND does
 *   NOT match any of the three canonical option strings (`All tests pass`,
 *   `Issues found`, `Skip for now`). Such a prompt is a free-text question.
 *
 * SKIP GUARD: This test is skipped when no post-S8-80 golden log is available
 * OR when the harvested log contains no free-text branch (option-pick-only
 * runs trigger the deferred warning).
 *
 * Pattern source: invariants/issues-found-delegates.test.ts, askuser-not-for-text-input.test.ts
 */

import fs from 'node:fs';
import path from 'node:path';
import { describe, it, expect } from 'vitest';
import { loadGoldenLog } from '../verify-session-behavior';

const CHECKLIST_PATH = /generated-docs[\\/]qa[\\/].+story-\d+-[a-z0-9-]+-verification-checklist\.md/i;
const OPTION_PICK = /^(\s*)?(All tests pass|Issues found|Skip for now)(\s*)?$/i;
const MANUAL_VERIFY_HINT = /verify[^.\n]*browser|All tests pass[\s\S]*Issues found[\s\S]*Skip for now|verification checklist/i;

function normalise(text: string): string {
  return text.replace(/\r\n/g, '\n').trim();
}

function extractChecklistPath(raw: string): string | null {
  const m = raw.match(CHECKLIST_PATH);
  return m ? m[0] : null;
}

describe('S8-80 — Tier 2 — checklist verbatim on free-text re-ask', () => {
  const loaded = loadGoldenLog('full-happy-path');

  it.skipIf(!loaded.available)(
    'PASS: every free-text re-ask contains the checklist file content byte-for-byte',
    () => {
      const log = loaded.log!;

      const writeEvent = log.events.find(e =>
        e.type === 'tool_call'
        && e.toolName === 'Write'
        && CHECKLIST_PATH.test(e.raw ?? ''),
      );
      if (!writeEvent) {
        console.warn(
          's8-80 / freetext-verbatim: no checklist Write found in golden log — covered by checklist-file-written-before-manual-verify.test.ts; skipping verbatim check.',
        );
        return;
      }

      const checklistPath = extractChecklistPath(writeEvent.raw ?? '');
      const absChecklistPath = path.resolve(checklistPath!);
      if (!fs.existsSync(absChecklistPath)) {
        console.warn(
          `s8-80 / freetext-verbatim: ${absChecklistPath} no longer exists on disk — re-harvest needed.`,
        );
        return;
      }

      const fileContent = normalise(fs.readFileSync(absChecklistPath, 'utf8'));

      // Find each manual-verification AskUserQuestion and check whether the
      // NEXT user prompt was a free-text reply (i.e., did NOT match any
      // option pick). For each such free-text prompt, the next AskUserQuestion
      // must contain the full file content verbatim.
      const freeTextRePrompts: number[] = [];
      log.events.forEach((e, i) => {
        if (e.type !== 'ask_user_question') return;
        if (!MANUAL_VERIFY_HINT.test(e.raw ?? '')) return;

        const nextPrompt = log.events.slice(i + 1).find(x => x.type === 'prompt');
        if (!nextPrompt) return;

        const promptText = (nextPrompt.content ?? '').trim();
        if (!OPTION_PICK.test(promptText) && promptText.length > 0) {
          freeTextRePrompts.push(log.events.indexOf(nextPrompt));
        }
      });

      if (freeTextRePrompts.length === 0) {
        console.warn(
          's8-80 / freetext-verbatim: golden log contains no free-text reply branch — option-pick-only run; re-harvest with at least one free-text reply to cover this surface (TEST-INPUTS §21c canonical question is "What URL should I be on for AC-2?").',
        );
        return;
      }

      for (const promptIdx of freeTextRePrompts) {
        const window = log.events.slice(promptIdx + 1, promptIdx + 30);
        const reAsk = window.find(ev =>
          ev.type === 'ask_user_question'
          && MANUAL_VERIFY_HINT.test(ev.raw ?? ''),
        );
        expect(
          reAsk,
          `no re-ask AskUserQuestion found within 30 events after free-text reply at event ${promptIdx}. Either the orchestrator did not re-ask, or the re-ask did not include manual-verification content.`,
        ).toBeDefined();

        const reAskText = normalise(reAsk!.raw ?? '');
        expect(
          reAskText.includes(fileContent),
          `re-ask AskUserQuestion at event ${log.events.indexOf(reAsk!)} does not contain the checklist file content verbatim. The orchestrator answered the free-text question but forgot to re-display the full checklist (or replaced it with "see above"). File: ${absChecklistPath}`,
        ).toBe(true);
      }
    },
  );

  it.skipIf(loaded.available)(
    'DEFERRED: skipping until a post-S8-80 golden log with a free-text re-ask branch is harvested',
    () => {
      expect(loaded.available).toBe(false);
      console.warn(
        `s8-80 / Tier 2 deferred: ${loaded.reason ?? 'no golden log'}`,
      );
    },
  );

  it('FAIL: detector flags option-pick replies as not-free-text', () => {
    // Sanity check: the canonical option-pick strings must NOT be classified
    // as free-text replies. A regression here would cause every option pick
    // to incorrectly demand a verbatim re-display.
    expect(OPTION_PICK.test('All tests pass')).toBe(true);
    expect(OPTION_PICK.test('Issues found')).toBe(true);
    expect(OPTION_PICK.test('Skip for now')).toBe(true);
    expect(OPTION_PICK.test('What URL should I be on for AC-2?')).toBe(false);
  });
});
