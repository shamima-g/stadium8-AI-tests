/**
 * TG-33 — No error-suppression directives in generated code.
 *
 * Rule: TypeScript files under web/src/ (.ts / .tsx) must never contain
 * eslint-disable, @ts-ignore, @ts-expect-error, or @ts-nocheck — they hide
 * real problems.
 *
 * The rule is tested against fixtures (deterministic). A regression scan runs
 * the same rule over the real web/src/ when generated code exists, and is
 * skipped (visibly) otherwise.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';
import { findSuppressions, walkFiles, isSourceFile } from './linters';

describe('TG-33 rule — findSuppressions', () => {
  it('FAIL: flags a @ts-ignore', () => {
    expect(findSuppressions('const x: number = "no"; // @ts-ignore\n')).toContain('@ts-ignore');
  });

  it('FAIL: flags an eslint-disable-next-line', () => {
    expect(findSuppressions('// eslint-disable-next-line\nexport const Foo = () => null;\n'))
      .toContain('eslint-disable');
  });

  it('FAIL: flags every directive variant', () => {
    const bad = '// @ts-nocheck\n/* @ts-expect-error */\n// eslint-disable\n// @ts-ignore\n';
    expect(findSuppressions(bad)).toHaveLength(4);
  });

  it('PASS: clean code has no suppressions', () => {
    expect(findSuppressions('export const x: number = 42;\n')).toHaveLength(0);
  });
});

const SRC_DIR = path.join(REPO_ROOT, 'web', 'src');
const hasSrc = fs.existsSync(SRC_DIR);

describe('TG-33 regression — real web/src/', () => {
  it.skipIf(!hasSrc)('has no suppression directives in any source file', () => {
    const offenders: string[] = [];
    for (const file of walkFiles(SRC_DIR, isSourceFile)) {
      if (findSuppressions(fs.readFileSync(file, 'utf8')).length > 0) {
        offenders.push(path.relative(REPO_ROOT, file));
      }
    }
    expect(offenders, `Suppression directives found in: ${offenders.join(', ')}`).toHaveLength(0);
  });
});
