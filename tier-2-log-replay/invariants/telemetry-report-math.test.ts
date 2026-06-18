/**
 * Tier 2 — telemetry report math.
 *
 * Runs .claude/scripts/generate-telemetry-report.js against the committed
 * synthetic sample-run and asserts the derived numbers — timing (with user-wait
 * excluded), token attribution, per-story rollup, and estimate/variance against a
 * baseline derived from the same run.
 *
 * The expected values mirror the fixture:
 *   INTAKE  09:00→09:10 wall 10m, minus wait 09:05→09:09 (4m) = 6m active
 *   PLAN    09:10→09:20 = 10m
 *   BUILD   09:20→09:45 = 25m
 *   test-generator 09:20:30→09:25:30 = 5m ; developer 09:26→09:40 = 14m
 *   tokens  sample @09:21 = 1200 (in tg span) ; @09:30 = 3900 (in developer span)
 */

import { it, expect, beforeAll, afterAll } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { loadTelemetryRun, runReport } from '../verify-session-behavior';

const run = loadTelemetryRun();

function phase(report: Record<string, unknown>, name: string): any {
  return (report.macro as any[]).find(p => p.phase === name);
}

describe('Tier 2 — telemetry report: timing', () => {
  it.skipIf(!run.available)('PASS: active time excludes the user-wait window', () => {
    const r = runReport('timing', run.root!);
    expect(phase(r, 'INTAKE').wallMin).toBe(10);
    expect(phase(r, 'INTAKE').activeMin).toBe(6); // 10m wall − 4m wait
    expect(phase(r, 'BUILD').activeMin).toBe(25);
    expect((r as any).excludedWaitMin).toBe(4);
  });

  it.skipIf(!run.available)('PASS: granular agent spans are correct', () => {
    const r = runReport('timing', run.root!);
    const g = r.granular as any[];
    expect(g.find(a => a.agent === 'test-generator').activeMin).toBe(5);
    expect(g.find(a => a.agent === 'developer').activeMin).toBe(14);
  });

  it('FAIL: a non-existent phase is not present in the report', () => {
    const r = runReport('timing', run.available ? run.root! : process.cwd());
    const macro = (r.macro as any[]) || [];
    expect(macro.find(p => p.phase === 'DESIGN')).toBeUndefined();
  });
});

describe('Tier 2 — telemetry report: tokens', () => {
  it.skipIf(!run.available)('PASS: tokens attribute to the phase and agent that own the timestamp', () => {
    const r = runReport('tokens', run.root!);
    expect((r as any).tokensAvailable).toBe(true);
    const build = (r.macro as any[]).find(p => p.phase === 'BUILD');
    expect(build.tokens.total).toBe(5100); // 1200 + 3900
    const g = r.granular as any[];
    expect(g.find(a => a.agent === 'test-generator').tokens.total).toBe(1200);
    expect(g.find(a => a.agent === 'developer').tokens.total).toBe(3900);
  });
});

describe('Tier 2 — telemetry report: estimate/variance vs golden baseline', () => {
  let tmpRoot: string;

  beforeAll(() => {
    if (!run.available) return;
    // Copy the sample run into a tmp root, derive a baseline there, so we can
    // exercise --estimate / --final without committing a baseline file.
    tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'tel-run-'));
    const ctxFrom = path.join(run.root!, 'generated-docs', 'context');
    const ctxTo = path.join(tmpRoot, 'generated-docs', 'context');
    fs.mkdirSync(ctxTo, { recursive: true });
    for (const f of fs.readdirSync(ctxFrom)) fs.copyFileSync(path.join(ctxFrom, f), path.join(ctxTo, f));
    fs.copyFileSync(path.join(run.root!, 'transcript.jsonl'), path.join(tmpRoot, 'transcript.jsonl'));
    runReport('write-baseline', tmpRoot);
  });

  afterAll(() => { if (tmpRoot) fs.rmSync(tmpRoot, { recursive: true, force: true }); });

  it.skipIf(!run.available)('PASS: estimate reads the harvested baseline and reports counts', () => {
    const r = runReport('estimate', tmpRoot);
    expect((r as any).baselineAvailable).toBe(true);
    expect((r as any).counts.stories).toBe(1);
    expect((r as any).perPhase.find((p: any) => p.phase === 'BUILD').scaledByStoryCount).toBe(true);
  });

  it.skipIf(!run.available)('PASS: final report computes per-story variance against the baseline (zero for the baseline run itself)', () => {
    const r = runReport('final', tmpRoot);
    const story = (r as any).perStory[0];
    expect(story.actualActiveMin).toBe(19); // 5 + 14
    expect(story.varianceMin).toBe(0);      // identical to the baseline it was derived from
  });

  it('FAIL: estimate without a baseline reports baselineAvailable=false', () => {
    const empty = fs.mkdtempSync(path.join(os.tmpdir(), 'tel-empty-'));
    try {
      const r = runReport('estimate', empty);
      expect((r as any).baselineAvailable).toBe(false);
    } finally {
      fs.rmSync(empty, { recursive: true, force: true });
    }
  });
});
