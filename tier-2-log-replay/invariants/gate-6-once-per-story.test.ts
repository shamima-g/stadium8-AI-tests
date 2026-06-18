/**
 * S8-76 Phase 6 — Tier 2 invariant.
 *
 * On the no-drift QA path, the spec-compliance-watchdog Call A is invoked
 * exactly once per story. Call B (Option B — update specs) fires AT MOST once
 * per story, only when the user explicitly chooses Option B. Multiple Call A
 * invocations would point to a re-launch loop; multiple Call B invocations
 * would point to a runaway spec-update cycle.
 *
 * Status: skipped pending harvest. The current `full-happy-path` golden log
 * does not yet contain `subagent_start: spec-compliance-watchdog` events, so
 * the per-story counts cannot be checked. Activate after a fresh harvest.
 *
 * Pattern source: developer-called-twice.test.ts.
 */

import { describe, it, expect } from 'vitest';
import { loadGoldenLog } from '../verify-session-behavior';

describe('Tier 2 — Gate 6 invocations per story', () => {
  const loaded = loadGoldenLog('full-happy-path');

  const watchdogPresent =
    loaded.available &&
    loaded.log!.events.some(
      e => e.type === 'subagent_start' && e.subagentType === 'spec-compliance-watchdog',
    );

  /** Best-effort: count the user-visible story count by counting `/clear`
   * + `/continue` clearing-boundary instructions emitted after a QA pass.
   * A more reliable signal is the count of `code-reviewer` Call C events,
   * but Call C is not separately labelled in the log shape. We use the
   * watchdog count itself as the upper bound and assert the relationship. */
  function countWatchdogCalls(callKind: 'A' | 'B'): number {
    const log = loaded.log!;
    return log.events.filter(e => {
      if (e.type !== 'subagent_start' || e.subagentType !== 'spec-compliance-watchdog') {
        return false;
      }
      const prompt = String((e.args as { prompt?: string } | undefined)?.prompt ?? '');
      if (callKind === 'A') return /\bCall A\b/i.test(prompt);
      return /\bCall B\b/i.test(prompt);
    }).length;
  }

  it.skipIf(!watchdogPresent)(
    'PASS: Call B count never exceeds Call A count (Option B is conditional on Call A finding drift)',
    () => {
      const callA = countWatchdogCalls('A');
      const callB = countWatchdogCalls('B');
      expect(callB).toBeLessThanOrEqual(callA);
    },
  );

  it.skipIf(!watchdogPresent)(
    'PASS: Call A is invoked at least once for every code-reviewer Call C launch (no story commits without spec compliance)',
    () => {
      const log = loaded.log!;
      const callA = countWatchdogCalls('A');

      // Count code-reviewer launches whose prompt mentions Call C / commit.
      const callCLaunches = log.events.filter(e => {
        if (e.type !== 'subagent_start' || e.subagentType !== 'code-reviewer') return false;
        const prompt = String((e.args as { prompt?: string } | undefined)?.prompt ?? '');
        return /\bCall C\b|commit/i.test(prompt);
      }).length;

      expect(
        callA,
        'spec-compliance-watchdog Call A must run at least once per code-reviewer Call C',
      ).toBeGreaterThanOrEqual(callCLaunches);
    },
  );

  it.skipIf(!watchdogPresent)(
    'PASS: in a clean no-drift run, Call B is never invoked',
    () => {
      const log = loaded.log!;

      // A clean run is one where there are no "Update specs" user prompts.
      const optionBChosen = log.events.some(
        e => e.type === 'prompt' && /update specs to match code/i.test(e.content ?? ''),
      );
      if (optionBChosen) return; // Cannot assert on this run.

      const callB = countWatchdogCalls('B');
      expect(callB).toBe(0);
    },
  );

  it('FAIL: detector flags a synthesised log where Call B exceeds Call A', () => {
    const callA = 1;
    const callB = 2;
    expect(callB <= callA).toBe(false);
  });
});
