/**
 * Tests for scripts/generate-test-report.cjs (the Markdown run-report generator).
 *
 * Exercises the pure functions (buildModel, fmtDuration, render) against a
 * synthetic Vitest JSON payload — no recursive Vitest spawn.
 */

import { describe, it, expect } from 'vitest';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
// eslint-disable-next-line @typescript-eslint/no-var-requires
const gen = require('../../scripts/generate-test-report.cjs') as {
  buildModel: (json: unknown) => any;
  fmtDuration: (ms: number | null) => string;
  render: (model: any, env: any, tel: any, version: string, now: Date, extra?: any) => string;
  buildProvenance: (opts: any, env: any) => any;
};

// Minimal Vitest JSON shape: two files in different tiers, one failure with a message.
const SAMPLE = {
  startTime: 1_000,
  testResults: [
    {
      name: 'C:/repo/QA-TESTS/tier-1-unit/scripts/foo.test.ts',
      startTime: 1_000,
      endTime: 3_000,
      assertionResults: [
        { fullName: 'foo PASS: works', status: 'passed', duration: 12, failureMessages: [] },
        { fullName: 'foo FAIL: catches', status: 'failed', duration: 8, failureMessages: ['AssertionError: expected 1 to be 0'] },
      ],
    },
    {
      name: 'C:/repo/QA-TESTS/tier-1-unit/consistency/bar.test.ts',
      startTime: 1_500,
      endTime: 2_000,
      assertionResults: [
        { fullName: 'bar PASS: holds', status: 'passed', duration: 5, failureMessages: [] },
        { fullName: 'bar skipped one', status: 'skipped', duration: 0, failureMessages: [] },
      ],
    },
  ],
};

describe('generate-test-report — buildModel', () => {
  it('PASS: tallies counts, groups by layer, and keeps the failure message', () => {
    const m = gen.buildModel(SAMPLE);
    expect(m.counts).toEqual({ total: 4, passed: 2, failed: 1, skipped: 1 });
    // Two layers, derived from tier + first sub-folder.
    const layerNames = m.layers.map((l: any) => l.layer).sort();
    expect(layerNames).toEqual(['tier-1-unit › consistency', 'tier-1-unit › scripts']);
    const failing = m.tests.find((t: any) => t.result === 'failed');
    expect(failing.message).toContain('expected 1 to be 0');
  });

  it('FAIL: does not count a skipped test as passed', () => {
    const m = gen.buildModel(SAMPLE);
    expect(m.counts.passed).not.toBe(m.counts.total); // 2 passed of 4
    expect(m.counts.skipped).toBe(1);
  });
});

describe('generate-test-report — fmtDuration', () => {
  it('PASS: formats sub-second, seconds, and minutes', () => {
    expect(gen.fmtDuration(320)).toBe('320ms');
    expect(gen.fmtDuration(9_400)).toBe('9.4s');
    expect(gen.fmtDuration(676_000)).toBe('11m 16s');
  });

  it('FAIL: returns a placeholder for a missing duration rather than NaN', () => {
    expect(gen.fmtDuration(null)).toBe('—');
    expect(gen.fmtDuration(NaN)).toBe('—');
  });
});

describe('generate-test-report — render', () => {
  const ENV = { runBy: 'tester', machine: 'BOX', node: 'v24', vitest: '2.1.9', commit: 'abc', branch: 'main', os: 'win32 10' };

  it('PASS: emits the plain-language sections and a "needs attention" block with the failure detail', () => {
    const m = gen.buildModel(SAMPLE);
    const md = gen.render(m, ENV, null, '0.1.0', new Date(1_000));
    // Section headings are written for a non-developer reader.
    expect(md).toContain('## In short');
    expect(md).toContain('## How each area did');
    expect(md).toContain('## What needs attention');
    expect(md).toContain('## Every check we ran');
    // The headline verdict is plain language, and the failure detail survives.
    expect(md).toContain('❌ Some checks need attention');
    expect(md).toContain('expected 1 to be 0');
  });

  it('FAIL: an all-pass run is not reported as needing attention', () => {
    const passOnly = { startTime: 0, testResults: [{ name: 'C:/repo/QA-TESTS/tier-1-unit/x/y.test.ts', startTime: 0, endTime: 1, assertionResults: [{ fullName: 'ok', status: 'passed', duration: 1, failureMessages: [] }] }] };
    const md = gen.render(gen.buildModel(passOnly), ENV, null, '0.1.0', new Date(0));
    expect(md).toContain('✅ All clear');
    expect(md).not.toContain('Some checks need attention');
  });

  it('PASS: shows a lines-of-code section when that data is supplied', () => {
    const m = gen.buildModel(SAMPLE);
    const loc = { total: 1234, totalFiles: 10, rows: [{ label: 'App the team is building (web/src)', files: 10, lines: 1234 }] };
    const md = gen.render(m, ENV, null, '0.1.0', new Date(1_000), { loc, surfaces: [] });
    expect(md).toContain('## Lines of code in the application');
    expect(md).toContain('1,234');
  });

  it('PASS: renders the provenance rows (command, repository, branch, version tested) when supplied', () => {
    const m = gen.buildModel(SAMPLE);
    const provenance = {
      command: 'node scripts/generate-test-report.cjs --label dev-v1.2.0 --target dev --ref v1.2.0',
      repository: 'https://github.com/stadium-software/stadium-8',
      branch: 'v1.2.0 (commit abc1234)',
      versionTested: 'v1.2.0',
      testedAt: 'C:/AI/.../.targets/dev-v1.2.0',
    };
    const md = gen.render(m, ENV, null, '0.1.0', new Date(1_000), { surfaces: [], provenance });
    expect(md).toContain('| Repository | https://github.com/stadium-software/stadium-8 |');
    expect(md).toContain('| Branch / ref | v1.2.0 (commit abc1234) |');
    expect(md).toContain('| Version tested | v1.2.0 |');
    expect(md).toContain('generate-test-report.cjs --label dev-v1.2.0');
  });

  it('FAIL-guard: without provenance, no repository/version rows are emitted', () => {
    const md = gen.render(gen.buildModel(SAMPLE), ENV, null, '0.1.0', new Date(1_000));
    expect(md).not.toContain('| Repository |');
    expect(md).not.toContain('| Version tested |');
  });
});

describe('generate-test-report — buildProvenance', () => {
  it('PASS: a --target run resolves the repo from targets.json and uses the ref as the version', () => {
    const p = gen.buildProvenance({ target: 'dev', ref: 'v1.2.0', label: 'dev-v1.2.0' }, {});
    expect(p.repository).toBe('https://github.com/stadium-software/stadium-8');
    expect(p.versionTested).toBe('v1.2.0');
    expect(p.command).toContain('generate-test-report.cjs');
  });

  it('FAIL-guard: a local run (no --target) reports "local checkout", never a crash', () => {
    const p = gen.buildProvenance({}, { branch: 'main' });
    expect(p.versionTested).toBe('local checkout');
    expect(p.branch).toBe('main');
  });
});

describe('generate-test-report — friendlyArea', () => {
  it('PASS: maps a known layer to plain language and tidies an unknown one', () => {
    expect(gen.friendlyArea('tier-1-unit › scripts')).toBe('Helper tools work correctly');
    // Unknown layer: drop the tier prefix, tidy the casing.
    expect(gen.friendlyArea('tier-9-future › widget-things')).toBe('Widget things');
  });
});
