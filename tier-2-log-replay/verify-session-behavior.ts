/**
 * verify-session-behavior — shared utilities for Tier 2 telemetry tests.
 *
 * HISTORY: Tier 2 used to replay `.claude/logs/*.md` session logs. The current
 * 4-phase template no longer emits those logs, so that mechanism was retired.
 * Tier 2 now asserts over the **telemetry ledger** (telemetry.ndjson) produced by
 * the capture layer (.claude/scripts/lib/telemetry.js + hooks), plus the reports
 * derived from it by .claude/scripts/generate-telemetry-report.js.
 *
 * Tests load a telemetry run (a directory containing generated-docs/context/
 * telemetry.ndjson and optionally a transcript). If none is present they skip
 * gracefully — a fresh checkout has no harvested run, and CI must still pass.
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { REPO_ROOT } from '../helpers';

/** Where committed synthetic + harvested telemetry runs live. */
export const GOLDEN_TELEMETRY_DIR = path.resolve(__dirname, '..', 'fixtures', 'golden-telemetry');

export interface TelemetryEvent {
  ts: string;
  event: string;
  phase?: string | null;
  epic?: number | null;
  story?: number | null;
  agent?: string | null;
  [k: string]: unknown;
}

export interface TelemetryRun {
  available: boolean;
  reason?: string;
  /** Project root passed to the report generator (the run directory). */
  root?: string;
  /** Parsed ledger events. */
  events?: TelemetryEvent[];
}

/**
 * Load the most recent telemetry run directory under golden-telemetry/.
 * A run directory contains generated-docs/context/telemetry.ndjson.
 */
export function loadTelemetryRun(pattern = ''): TelemetryRun {
  if (!fs.existsSync(GOLDEN_TELEMETRY_DIR)) {
    return { available: false, reason: `golden-telemetry directory not found at ${GOLDEN_TELEMETRY_DIR}` };
  }
  const runs = fs.readdirSync(GOLDEN_TELEMETRY_DIR, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name)
    .filter(n => (pattern ? n.toLowerCase().includes(pattern.toLowerCase()) : true))
    .filter(n => fs.existsSync(path.join(GOLDEN_TELEMETRY_DIR, n, 'generated-docs', 'context', 'telemetry.ndjson')))
    .sort()
    .reverse();
  if (runs.length === 0) {
    return { available: false, reason: 'no telemetry run harvested yet — see fixtures/golden-telemetry/README.md' };
  }
  const root = path.join(GOLDEN_TELEMETRY_DIR, runs[0]);
  const ledger = path.join(root, 'generated-docs', 'context', 'telemetry.ndjson');
  const events = fs.readFileSync(ledger, 'utf8')
    .split(/\r?\n/).map(l => l.trim()).filter(Boolean)
    .map(l => { try { return JSON.parse(l) as TelemetryEvent; } catch { return null; } })
    .filter((e): e is TelemetryEvent => e !== null);
  return { available: true, root, events };
}

/** Run generate-telemetry-report.js against a run dir and return the parsed JSON. */
export function runReport(mode: string, root: string, extraArgs: string[] = []): Record<string, unknown> {
  const script = path.join(REPO_ROOT, '.claude', 'scripts', 'generate-telemetry-report.js');
  const res = spawnSync('node', [script, `--${mode}`, '--json', '--root', root, ...extraArgs], {
    encoding: 'utf8', timeout: 20_000,
  });
  try { return JSON.parse(res.stdout); } catch { return { __parseError: true, stdout: res.stdout, stderr: res.stderr }; }
}

/**
 * Telemetry-baseline freshness canary. Warns when the committed baseline is older
 * than orchestrator-rules.md / settings.json — a baseline that predates a rules
 * change can't meaningfully anchor estimates. Skips when no baseline exists yet.
 */
export function checkFreshness(): { stale: boolean; message: string } {
  const rules = path.resolve(REPO_ROOT, '.claude', 'shared', 'orchestrator-rules.md');
  const settings = path.resolve(REPO_ROOT, '.claude', 'settings.json');

  if (!fs.existsSync(GOLDEN_TELEMETRY_DIR)) {
    return { stale: true, message: 'no telemetry baseline harvested yet' };
  }
  const baselines = fs.readdirSync(GOLDEN_TELEMETRY_DIR)
    .filter(f => f === 'baseline.json' || f.endsWith('.baseline.json'))
    .map(f => fs.statSync(path.join(GOLDEN_TELEMETRY_DIR, f)).mtimeMs);
  if (baselines.length === 0) {
    return { stale: true, message: 'no telemetry baseline harvested yet' };
  }
  const newest = Math.max(...baselines);
  const critical = Math.max(
    fs.existsSync(rules) ? fs.statSync(rules).mtimeMs : 0,
    fs.existsSync(settings) ? fs.statSync(settings).mtimeMs : 0,
  );
  if (newest < critical) {
    return { stale: true, message: 'telemetry baseline is older than orchestrator-rules.md or settings.json — re-harvest' };
  }
  return { stale: false, message: 'baseline is fresh' };
}
