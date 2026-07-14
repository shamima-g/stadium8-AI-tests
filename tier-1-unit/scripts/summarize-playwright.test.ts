/**
 * Tests for .claude/scripts/summarize-playwright.js
 *
 * Parses a Playwright JSON report at EPIC-END into top-level stats + failing specs,
 * each mapped back to its story via the epic-<slug>-story-<N>-<title>.spec.ts name.
 *   exit 0 = clean · exit 1 = a spec/test failed OR a run-level error · exit 2 = bad report.
 *
 * A run-level error (webServer/globalSetup) with zero failing specs must still be a
 * FAIL — a verdict from stats alone would call a broken run "pass".
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, runScript } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/summarize-playwright.js';

/** Build a minimal Playwright JSON report. Specs are nested one describe-level deep. */
function report(opts: {
  expected?: number;
  unexpected?: number;
  specs?: { ok: boolean; file: string; title?: string; error?: string }[];
  errors?: string[];
}) {
  const { expected = 0, unexpected = 0, specs = [], errors = [] } = opts;
  return JSON.stringify({
    stats: { expected, unexpected, flaky: 0, skipped: 0, duration: 1234 },
    suites: [
      {
        specs: [],
        suites: [
          {
            specs: specs.map((s) => ({
              ok: s.ok,
              file: s.file,
              title: s.title ?? 'a scenario',
              tests: s.error ? [{ results: [{ errors: [{ message: s.error }] }] }] : [],
            })),
          },
        ],
      },
    ],
    errors: errors.map((message) => ({ message })),
  });
}

function summarize(project: TempProject, reportJson: string) {
  const p = project.write('pw-report.json', reportJson);
  return runScript(SCRIPT, [p, '--json'], { cwd: project.root });
}

describe('summarize-playwright.js', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: a clean run reports result "pass" (exit 0)', () => {
    const r = summarize(project, report({
      expected: 2,
      specs: [
        { ok: true, file: 'epic-task-browsing-story-1-view.spec.ts' },
        { ok: true, file: 'epic-task-browsing-story-2-empty.spec.ts' },
      ],
    }));
    expect(r.exitCode, r.stderr).toBe(0);
    const json = r.json<{ result: string; failures: unknown[] }>();
    expect(json.result).toBe('pass');
    expect(json.failures).toHaveLength(0);
  });

  it('FAIL: a failing spec is reported and mapped to its story number (exit 1)', () => {
    const r = summarize(project, report({
      expected: 1,
      unexpected: 1,
      specs: [
        { ok: true, file: 'epic-task-browsing-story-1-view.spec.ts' },
        { ok: false, file: 'epic-task-browsing-story-2-delete.spec.ts', title: 'deletes a task', error: 'Boom: locator not found' },
      ],
    }));
    expect(r.exitCode).toBe(1);
    const json = r.json<{ result: string; failures: { story: number; file: string; error: string }[] }>();
    expect(json.result).toBe('fail');
    expect(json.failures).toHaveLength(1);
    expect(json.failures[0].story).toBe(2);
    expect(json.failures[0].file).toContain('story-2-delete');
    expect(json.failures[0].error).toMatch(/Boom/);
  });

  it('FAIL: a run-level error with zero failing specs is still a fail (broken-run guard)', () => {
    const r = summarize(project, report({
      expected: 2,
      unexpected: 0,
      specs: [{ ok: true, file: 'epic-task-browsing-story-1-view.spec.ts' }],
      errors: ['Error: dev server (webServer) never started on port 3000'],
    }));
    expect(r.exitCode).toBe(1);
    const json = r.json<{ result: string; errors: string[] }>();
    expect(json.result).toBe('fail');
    expect(json.errors.join(' ')).toMatch(/webServer/);
  });

  it('FAIL: an unparseable / wrong-shape report exits 2 (treat as a run failure)', () => {
    const p = project.write('bad.json', '{ "not": "a playwright report" }');
    const r = runScript(SCRIPT, [p, '--json'], { cwd: project.root });
    expect(r.exitCode).toBe(2);
  });
});
