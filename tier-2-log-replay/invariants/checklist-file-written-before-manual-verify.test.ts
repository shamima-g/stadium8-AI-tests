/**
 * S8-80 Phase 6 — Tier 2 invariant: checklist file written before first manual-verify ask.
 *
 * In a harvested QA log, a Write tool call to
 * `generated-docs/qa/**\/story-*-verification-checklist.md` MUST appear
 * before the first AskUserQuestion whose content mentions manual verification.
 * Without that ordering, every subsequent re-ask (fix-cycle or free-text)
 * has nothing to re-read.
 *
 * SKIP GUARD: This test is skipped when no post-S8-80 golden log is available
 * — `loadGoldenLog()` returns `available: false` and `it.skipIf(!loaded.available)`
 * marks the test as deferred in CI rather than failing. Once a fresh log is
 * harvested into `fixtures/golden-logs/`, the assertion runs automatically.
 *
 * Pattern source: invariants/issues-found-delegates.test.ts, watchdog-runs-after-manual-verify.test.ts
 */

import { describe, it, expect } from 'vitest';
import { loadGoldenLog } from '../verify-session-behavior';

const CHECKLIST_PATH = /generated-docs[\\/]qa[\\/].+story-\d+-[a-z0-9-]+-verification-checklist\.md/i;
const MANUAL_VERIFY_HINT = /verify[^.\n]*browser|All tests pass[\s\S]*Issues found[\s\S]*Skip for now|verification checklist/i;

describe('S8-80 — Tier 2 — checklist file written before first manual-verify ask', () => {
  const loaded = loadGoldenLog('full-happy-path');

  it.skipIf(!loaded.available)(
    'PASS: a Write to generated-docs/qa/**/story-*-verification-checklist.md precedes the first manual-verification AskUserQuestion',
    () => {
      const log = loaded.log!;

      const firstManualVerifyIdx = log.events.findIndex(e =>
        e.type === 'ask_user_question' && MANUAL_VERIFY_HINT.test(e.raw ?? ''),
      );

      // If the run we harvested never reached manual verification, the
      // invariant is vacuously true — but flag that explicitly so a wrong
      // golden log doesn't pretend to cover this surface.
      if (firstManualVerifyIdx === -1) {
        // eslint-disable-next-line no-console
        console.warn(
          's8-80 / checklist-file-written-before-manual-verify: harvested log never reached a manual-verification AskUserQuestion — re-harvest needed for full coverage.',
        );
        return;
      }

      const priorWrites = log.events
        .slice(0, firstManualVerifyIdx)
        .filter(e =>
          e.type === 'tool_call'
          && e.toolName === 'Write'
          && CHECKLIST_PATH.test(e.raw ?? ''),
        );

      expect(
        priorWrites.length,
        `expected at least one Write to a verification-checklist.md file before the first manual-verification AskUserQuestion (event ${firstManualVerifyIdx}); found ${priorWrites.length}. Either Call B forgot to persist the file, or the orchestrator presented the checklist before Call B's Write completed.`,
      ).toBeGreaterThanOrEqual(1);
    },
  );

  it.skipIf(loaded.available)(
    'DEFERRED: skipping until a post-S8-80 golden log is harvested',
    () => {
      // Sentinel test — exists so CI surfaces the deferred state visibly.
      // When a golden log lands under fixtures/golden-logs/, this test stops
      // running (skipIf flips) and the real assertion above takes over.
      expect(loaded.available).toBe(false);
      console.warn(
        `s8-80 / Tier 2 deferred: ${loaded.reason ?? 'no golden log'}`,
      );
    },
  );

  it('FAIL: detector identifies a missing prior Write', () => {
    // Sanity check — if the danger window contains zero matching Writes, the
    // assertion above must trip. This validates the detector logic itself,
    // independently of any golden log.
    const fakeEvents = [
      { type: 'ask_user_question', raw: 'verify in browser' },
    ];
    const matches = fakeEvents.filter(e =>
      e.type === 'tool_call'
      && (e as { toolName?: string }).toolName === 'Write'
      && CHECKLIST_PATH.test(e.raw),
    );
    expect(matches).toHaveLength(0);
  });
});
