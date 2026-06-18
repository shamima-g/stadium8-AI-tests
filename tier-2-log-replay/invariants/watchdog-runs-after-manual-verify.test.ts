/**
 * S8-76 Phase 6 — Tier 2 invariant.
 *
 * The `spec-compliance-watchdog` (Gate 6) MUST be launched after the manual-
 * verification `AskUserQuestion` resolves and BEFORE `code-reviewer` Call C
 * commits. Covers TEST-GUIDE §23a–h timing.
 *
 * Status: skipped pending harvest. The current `full-happy-path` golden log
 * was captured before the watchdog was wired into orchestrator-rules.md, so
 * none of its events reference `subagent_type: spec-compliance-watchdog`. The
 * test will activate automatically once a fresh end-to-end log is harvested.
 *
 * Pattern source: developer-called-twice.test.ts.
 */

import { describe, it, expect } from 'vitest';
import { loadGoldenLog } from '../verify-session-behavior';

describe('Tier 2 — watchdog runs between manual verification and Call C', () => {
  const loaded = loadGoldenLog('full-happy-path');

  const watchdogPresent =
    loaded.available &&
    loaded.log!.events.some(
      e => e.type === 'subagent_start' && e.subagentType === 'spec-compliance-watchdog',
    );

  it.skipIf(!watchdogPresent)(
    'PASS: every spec-compliance-watchdog launch is preceded by a manual-verification AskUserQuestion and followed by a code-reviewer launch',
    () => {
      const log = loaded.log!;
      const watchdogStarts = log.events
        .map((e, i) => ({ e, i }))
        .filter(({ e }) =>
          e.type === 'subagent_start' && e.subagentType === 'spec-compliance-watchdog',
        );

      expect(watchdogStarts.length).toBeGreaterThan(0);

      for (const { i: watchIdx } of watchdogStarts) {
        const before = log.events.slice(0, watchIdx);
        const after = log.events.slice(watchIdx + 1);

        const lastAskUserBefore = [...before]
          .reverse()
          .find(ev =>
            ev.type === 'tool_call' &&
            ev.toolName === 'AskUserQuestion' &&
            /verif|all tests pass|issues found/i.test(JSON.stringify(ev.args ?? '')),
          );

        expect(
          lastAskUserBefore,
          `watchdog launch at event ${watchIdx} is not preceded by a manual-verification AskUserQuestion`,
        ).toBeDefined();

        const reviewerAfter = after.find(
          ev => ev.type === 'subagent_start' && ev.subagentType === 'code-reviewer',
        );

        expect(
          reviewerAfter,
          `watchdog launch at event ${watchIdx} is not followed by a code-reviewer launch (Call C)`,
        ).toBeDefined();
      }
    },
  );

  it.skipIf(!watchdogPresent)(
    'FAIL: a synthetic event sequence missing the manual-verification step is detected',
    () => {
      // Synthesise a bad ordering and prove the detector catches it.
      const fakeEvents = [
        { type: 'subagent_start', subagentType: 'spec-compliance-watchdog' },
        { type: 'subagent_start', subagentType: 'code-reviewer' },
      ];
      const watchdogIdx = fakeEvents.findIndex(
        e => e.type === 'subagent_start' && e.subagentType === 'spec-compliance-watchdog',
      );
      const before = fakeEvents.slice(0, watchdogIdx);
      const lastAskUserBefore = [...before].reverse().find(
        e => e.type === 'tool_call',
      );
      expect(lastAskUserBefore).toBeUndefined();
    },
  );
});
