/**
 * Canary — warns if the committed telemetry baseline is older than the
 * orchestrator rules or settings.json. A stale baseline can't reliably anchor
 * the estimate/variance reports.
 *
 * Informational: it fails loudly to remind humans to re-harvest, but skips
 * gracefully when no baseline exists yet (fresh checkout / pre-first-harvest).
 */

import { describe, it, expect } from 'vitest';
import { checkFreshness } from '../verify-session-behavior';

describe('Tier 2 — telemetry-baseline freshness canary', () => {
  const freshness = checkFreshness();

  it('PASS: newest telemetry baseline is newer than orchestrator-rules.md and settings.json', () => {
    if (freshness.message === 'no telemetry baseline harvested yet') {
      // Fresh checkout — nothing harvested; skip per contract.
      return;
    }
    expect(freshness.stale, freshness.message).toBe(false);
  });
});
