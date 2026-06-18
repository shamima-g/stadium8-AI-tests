/**
 * Tests for .claude/scripts/generate-telemetry-report.js
 *
 * Unit-level: seeds a telemetry ledger in a temp project and asserts the derived
 * timing/token math. Heavier end-to-end coverage (per-story variance, baseline
 * round-trip) lives in tier-2-log-replay/invariants/telemetry-report-math.test.ts.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import fs from 'node:fs';
import path from 'node:path';
import { createTempProject, runScript } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/generate-telemetry-report.js';

function seedLedger(root: string, lines: string[]): void {
  const dir = path.join(root, 'generated-docs', 'context');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'telemetry.ndjson'), lines.join('\n') + '\n');
}

describe('generate-telemetry-report.js — timing', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: computes per-phase active time and excludes user-wait windows', () => {
    seedLedger(project.root, [
      '{"ts":"2026-06-16T09:00:00.000Z","event":"phase_enter","phase":"INTAKE"}',
      '{"ts":"2026-06-16T09:05:00.000Z","event":"turn_end"}',
      '{"ts":"2026-06-16T09:09:00.000Z","event":"user_input"}',
      '{"ts":"2026-06-16T09:10:00.000Z","event":"phase_exit","phase":"INTAKE"}',
    ]);
    const r = runScript(SCRIPT, ['--timing', '--json'], { cwd: project.root });
    expect(r.exitCode).toBe(0);
    const json = r.json<{ macro: Array<{ phase: string; activeMin: number; wallMin: number }>; excludedWaitMin: number }>();
    const intake = json.macro.find(p => p.phase === 'INTAKE')!;
    expect(intake.wallMin).toBe(10);
    expect(intake.activeMin).toBe(6); // 10m wall − 4m wait
    expect(json.excludedWaitMin).toBe(4);
  });

  it('FAIL: an empty ledger yields no phases (does not invent data)', () => {
    seedLedger(project.root, []);
    const r = runScript(SCRIPT, ['--timing', '--json'], { cwd: project.root });
    const json = r.json<{ macro: unknown[] }>();
    expect(json.macro).toEqual([]);
  });
});

describe('generate-telemetry-report.js — HTML output', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: --html emits a self-contained HTML page with inline SVG charts and no external CDN', () => {
    seedLedger(project.root, [
      '{"ts":"2026-06-16T09:00:00.000Z","event":"phase_enter","phase":"INTAKE"}',
      '{"ts":"2026-06-16T09:10:00.000Z","event":"phase_exit","phase":"INTAKE"}',
      '{"ts":"2026-06-16T09:10:00.000Z","event":"phase_enter","phase":"BUILD","epic":1,"story":1}',
      '{"ts":"2026-06-16T09:35:00.000Z","event":"phase_exit","phase":"BUILD"}',
    ]);
    const out = path.join(project.root, 'report.html');
    const r = runScript(SCRIPT, ['--timing', '--html', '--out', out], { cwd: project.root });
    expect(r.exitCode).toBe(0);
    const html = fs.readFileSync(out, 'utf8');
    expect(html.startsWith('<!doctype html>')).toBe(true);
    expect(html.trim().endsWith('</html>')).toBe(true);
    expect(html).toContain('<svg');            // inline chart, not an <img> to a CDN
    expect(html).toContain('bar-fill');        // bar chart present
    // Self-contained: no external script/style/image hosts.
    expect(/https?:\/\/[^"']*(cdn|jsdelivr|unpkg|googleapis|chart)/i.test(html)).toBe(false);
  });
});

describe('generate-telemetry-report.js — tokens', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: reports tokens unavailable (not fabricated) when no transcript exists', () => {
    seedLedger(project.root, [
      '{"ts":"2026-06-16T09:20:00.000Z","event":"phase_enter","phase":"BUILD","epic":1,"story":1}',
      '{"ts":"2026-06-16T09:45:00.000Z","event":"phase_exit","phase":"BUILD"}',
    ]);
    const r = runScript(SCRIPT, ['--tokens', '--json'], { cwd: project.root });
    const json = r.json<{ tokensAvailable: boolean; macro: Array<{ phase: string; tokens: unknown }> }>();
    expect(json.tokensAvailable).toBe(false);
    expect(json.macro.find(p => p.phase === 'BUILD')!.tokens).toBeNull();
  });
});
