/**
 * Tests for .claude/scripts/quality-gates.js
 *
 * The script runs Gates 2-5 (security / code quality / testing / performance) against the web/
 * app and returns a structured report; `--json` makes it machine-readable and its exit code is
 * pass(0)/fail(1). The workflow trusts it to report **truthfully** — a real failure is never
 * dressed up as a pass (workflow-tests.md §3 promise E).
 *
 * These drive the REAL runner over a synthetic minimal web/ using `--checks lint`, so only the
 * Code-Quality gate's ESLint sub-check runs (`npm run lint`) — no toolchain needed, and its
 * pass/fail is the process exit code. The gate's verdict is controlled by the temp project's
 * `lint` script (exit 0 = green, exit 1 = red), giving a genuine good/broken: pass-when-green and
 * fail-when-red. (Previously these only ran `--help`, so they never exercised a real gate — see
 * the DESIGN-COVERAGE.md AC6 note.)
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import fs from 'node:fs';
import path from 'node:path';
import { createTempProject, runScript } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/quality-gates.js';

/** A minimal web/ whose `lint` script decides the Code-Quality gate's verdict. */
function seedWeb(root: string, lintExit: 0 | 1): void {
  const web = path.join(root, 'web');
  fs.mkdirSync(path.join(web, 'src'), { recursive: true });
  fs.writeFileSync(
    path.join(web, 'package.json'),
    JSON.stringify(
      {
        name: 'test-web',
        version: '0.0.0',
        scripts: {
          lint: `exit ${lintExit}`,
          test: 'exit 0',
          'format:check': 'exit 0',
          build: 'exit 0',
        },
      },
      null,
      2,
    ),
  );
  fs.writeFileSync(path.join(web, 'tsconfig.json'), JSON.stringify({ compilerOptions: { noEmit: true } }, null, 2));
}

interface GateJson {
  overallStatus?: string;
  failedGates?: string[];
}

function runGate(root: string) {
  // --checks lint → only the Code-Quality gate's ESLint sub-check runs (npm run lint); its
  // pass/fail is the exit code, so no eslint/toolchain install is needed.
  // scriptLocation:'temp' runs the COPY inside the temp project, so quality-gates.js's
  // getProjectRoot() (anchored to the script's own .claude/) resolves web/ to THIS temp web/,
  // not the real template's — running from the repo would test the template's own app.
  return runScript(SCRIPT, ['--checks', 'lint', '--json'], {
    cwd: root,
    timeout: 60_000,
    scriptLocation: 'temp',
  });
}

describe('quality-gates.js — reports truthfully (pass-when-green / fail-when-red)', () => {
  let project: TempProject;
  beforeEach(() => {
    project = createTempProject();
  });
  afterEach(() => {
    project.cleanup(); // RB-0 — the throwaway temp project is discarded
  });

  it('PASS: a green gate reports pass and exits 0 (no "conditional pass")', () => {
    seedWeb(project.root, 0);
    const r = runGate(project.root);
    expect(r.exitCode, r.stderr).toBe(0);
    expect(r.stdout.toLowerCase(), 'binary pass/fail only').not.toContain('conditional pass');
    const j = r.parsedJson as GateJson | undefined;
    if (j) {
      expect(j.overallStatus).toBe('pass');
      expect(j.failedGates ?? []).toEqual([]);
    }
  });

  it('FAIL: a red gate reports fail and exits 1 — a real failure is never dressed up as a pass', () => {
    seedWeb(project.root, 1);
    const r = runGate(project.root);
    expect(r.exitCode, 'a failing gate must exit non-zero').toBe(1);
    const j = r.parsedJson as GateJson | undefined;
    if (j) {
      expect(j.overallStatus).toBe('fail');
      expect(j.failedGates ?? []).toContain('codeQuality');
    }
  });

  it('FAIL-guard: the runner discriminates — the same runner passes green and fails red', () => {
    seedWeb(project.root, 0);
    const green = runGate(project.root).exitCode;
    const p2 = createTempProject();
    try {
      seedWeb(p2.root, 1);
      const red = runGate(p2.root).exitCode;
      expect({ green, red }, 'green must pass (0) and red must fail (1)').toEqual({ green: 0, red: 1 });
    } finally {
      p2.cleanup(); // RB-0
    }
  });
});
