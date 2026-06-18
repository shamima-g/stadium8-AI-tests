/**
 * S8-76 Phase 6 — Tier 2 invariant.
 *
 * When a QA fix cycle occurs (user selected "Issues found" → developer fixed →
 * re-verify), the spec-compliance-watchdog MUST still run after re-verification
 * succeeds. The orchestrator must never short-circuit straight to Call C just
 * because a fix cycle happened.
 *
 * Per the watchdog agent's "QA Fix Cycle Drift" edge case, fix-cycle changes
 * are exactly the kind of drift the watchdog is supposed to catch — running it
 * is mandatory, not optional.
 *
 * Status: skipped pending harvest. The current golden log does not exercise a
 * QA fix cycle (the manual verification answer in TEST-INPUTS is "All tests
 * pass"), so this invariant has no production data to assert against until a
 * fix-cycle harvest exists. Activate by harvesting a log where the user picks
 * "Issues found" once before passing.
 *
 * Pattern source: issues-found-delegates.test.ts.
 */

import { describe, it, expect } from 'vitest';
import { loadGoldenLog } from '../verify-session-behavior';

describe('Tier 2 — watchdog runs even after a QA fix cycle', () => {
  const loaded = loadGoldenLog('full-happy-path');

  const fixCyclePresent =
    loaded.available &&
    loaded.log!.events.some(
      e => e.type === 'prompt' && /issues found/i.test(e.content ?? ''),
    );

  const watchdogPresent =
    loaded.available &&
    loaded.log!.events.some(
      e => e.type === 'subagent_start' && e.subagentType === 'spec-compliance-watchdog',
    );

  // Skip until BOTH conditions hold in the harvested log: a fix cycle occurred
  // AND watchdog events are tracked. Either alone makes this invariant silent.
  const ready = fixCyclePresent && watchdogPresent;

  it.skipIf(!ready)(
    'PASS: at least one spec-compliance-watchdog launch follows the most recent "Issues found" → re-verify cycle',
    () => {
      const log = loaded.log!;
      const lastIssuesFound = [...log.events]
        .map((e, i) => ({ e, i }))
        .reverse()
        .find(({ e }) => e.type === 'prompt' && /issues found/i.test(e.content ?? ''));

      expect(lastIssuesFound).toBeDefined();

      const after = log.events.slice(lastIssuesFound!.i + 1);
      const watchdogAfterFix = after.find(
        ev => ev.type === 'subagent_start' && ev.subagentType === 'spec-compliance-watchdog',
      );

      expect(
        watchdogAfterFix,
        'no spec-compliance-watchdog launch occurred after the QA fix cycle — orchestrator may have short-circuited to Call C',
      ).toBeDefined();
    },
  );

  it.skipIf(!ready)(
    'PASS: between the post-fix watchdog launch and Call C, the orchestrator did not pass any "ignore fix-cycle changes" instruction',
    () => {
      // The orchestrator-rules.md policy forbids telling the watchdog to skip
      // fix-cycle changes. Any subagent prompt to spec-compliance-watchdog
      // containing wording like "ignore", "skip", or "don't flag" near
      // "fix cycle" is a policy violation.
      const log = loaded.log!;
      const watchdogStarts = log.events.filter(
        e => e.type === 'subagent_start' && e.subagentType === 'spec-compliance-watchdog',
      );

      const FORBIDDEN = /(ignore|skip|don'?t flag)[^\n]{0,80}fix[- ]cycle/i;

      for (const w of watchdogStarts) {
        const prompt = String((w.args as { prompt?: string } | undefined)?.prompt ?? '');
        expect(
          FORBIDDEN.test(prompt),
          `watchdog launched with a forbidden suppression instruction: ${prompt.slice(0, 200)}`,
        ).toBe(false);
      }
    },
  );

  it.skipIf(!ready)(
    'FAIL: detector flags a synthesised forbidden prompt',
    () => {
      const FORBIDDEN = /(ignore|skip|don'?t flag)[^\n]{0,80}fix[- ]cycle/i;
      const synthesised = 'Run Call A. Please ignore any fix-cycle changes the developer made.';
      expect(FORBIDDEN.test(synthesised)).toBe(true);
    },
  );
});
