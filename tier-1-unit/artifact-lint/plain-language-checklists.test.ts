/**
 * TG-34 — Plain language in user-facing verification checklists.
 *
 * Rule: generated-docs/qa/**-verification-checklist.md must not contain
 * engineering jargon (isLoading, Skeleton, tsc, ESLint, Gate 3, vitest, …) —
 * the reader is often a non-developer.
 *
 * The detector is tested against fixtures; a regression scan runs it over the
 * real checklists when any exist, and is skipped (visibly) otherwise.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';
import { findJargon, walkFiles, isChecklist } from './linters';

describe('TG-34 rule — findJargon', () => {
  it('FAIL: flags engineering jargon', () => {
    const bad = 'Verify the Skeleton renders when isLoading is true (ESLint passed).';
    expect(findJargon(bad).length).toBeGreaterThanOrEqual(3);
  });

  it('FAIL: flags a gate reference', () => {
    expect(findJargon('Gate 3 must pass before sign-off.')).not.toHaveLength(0);
  });

  it('PASS: allows plain-language phrasing', () => {
    const good =
      'Verify a loading spinner appears while data loads. ' +
      'The form shows an error if submitted without a title.';
    expect(findJargon(good)).toHaveLength(0);
  });
});

const QA_DIR = path.join(REPO_ROOT, 'generated-docs', 'qa');
const hasChecklists = fs.existsSync(QA_DIR);

describe('TG-34 regression — real verification checklists', () => {
  it.skipIf(!hasChecklists)('contain no engineering jargon', () => {
    const offenders: string[] = [];
    for (const file of walkFiles(QA_DIR, isChecklist)) {
      const hits = findJargon(fs.readFileSync(file, 'utf8'));
      if (hits.length > 0) {
        offenders.push(`${path.relative(REPO_ROOT, file)}: ${hits.map(String).join(', ')}`);
      }
    }
    expect(offenders, `Jargon found:\n${offenders.join('\n')}`).toHaveLength(0);
  });
});
