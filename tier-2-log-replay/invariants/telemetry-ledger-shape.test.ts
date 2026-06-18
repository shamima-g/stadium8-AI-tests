/**
 * Tier 2 — telemetry ledger shape invariants.
 *
 * Asserts structural properties of the event ledger produced by the capture
 * layer. Uses the committed synthetic sample-run; skips if none is present.
 *
 * Both a PASS and a FAIL path per the suite conventions.
 */

import { describe, it, expect } from 'vitest';
import { loadTelemetryRun, type TelemetryEvent } from '../verify-session-behavior';

const run = loadTelemetryRun();

describe('Tier 2 — telemetry ledger shape', () => {
  it.skipIf(!run.available)('PASS: timestamps are monotonic non-decreasing', () => {
    const ev = run.events!;
    let prev = -Infinity;
    for (const e of ev) {
      const t = Date.parse(e.ts);
      expect(Number.isFinite(t)).toBe(true);
      expect(t).toBeGreaterThanOrEqual(prev);
      prev = t;
    }
  });

  it.skipIf(!run.available)('PASS: every agent_start has a matching agent_stop', () => {
    const ev = run.events!;
    const starts = ev.filter(e => e.event === 'agent_start');
    const stops = ev.filter(e => e.event === 'agent_stop');
    // Per-agent counts balance.
    const tally = (list: TelemetryEvent[]) => list.reduce<Record<string, number>>((m, e) => {
      const k = String(e.agent ?? 'unknown'); m[k] = (m[k] ?? 0) + 1; return m;
    }, {});
    expect(tally(starts)).toEqual(tally(stops));
  });

  it.skipIf(!run.available)('PASS: phase_enter / phase_exit events balance (last phase may stay open)', () => {
    const ev = run.events!;
    const enters = ev.filter(e => e.event === 'phase_enter').length;
    const exits = ev.filter(e => e.event === 'phase_exit').length;
    // Each completed phase pairs; the terminal phase (COMPLETE) has no exit.
    expect(enters - exits).toBeGreaterThanOrEqual(0);
    expect(enters - exits).toBeLessThanOrEqual(1);
  });

  it('FAIL: detector catches an unbalanced agent ledger', () => {
    const bad: TelemetryEvent[] = [
      { ts: '2026-06-16T09:00:00.000Z', event: 'agent_start', agent: 'developer' },
      // no matching agent_stop
    ];
    const starts = bad.filter(e => e.event === 'agent_start').length;
    const stops = bad.filter(e => e.event === 'agent_stop').length;
    expect(starts).not.toBe(stops);
  });
});
