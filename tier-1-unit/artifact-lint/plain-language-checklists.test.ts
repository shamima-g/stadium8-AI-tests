/**
 * TG-34 — Plain language in the user-facing manual-test checklist.
 *
 * Rule: the manual-test checklist a non-developer reads must not contain
 * engineering jargon (isLoading, Skeleton, tsc, ESLint, Gate 3, vitest, …).
 *
 * Under the epic-branch model the checklist lives INSIDE each story file
 * (`generated-docs/epics/<slug>/stories/story-*.md`), in its manual-test section —
 * not the retired standalone `generated-docs/qa/*-verification-checklist.md`. The
 * detector is tested against fixtures; a regression scan runs it over the manual-test
 * section of the real story files when any exist, and is skipped (visibly) otherwise.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';
import { findJargon, walkFiles, isStoryFile, extractManualChecklist } from './linters';

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

describe('TG-34 rule — extractManualChecklist', () => {
  const story =
    '# Story 1: View the task list\n\n**Role:** Admin\n\n' +
    'targetFile: web/src/app/tasks/page.tsx (tsc must pass)\n\n' +
    '## Manual-test checklist\n- Sign in as an admin and confirm all tasks show.\n\n' +
    '## Acceptance criteria\n- useEffect loads tasks\n';

  it('PASS: extracts only the manual-test section (not the dev metadata around it)', () => {
    const section = extractManualChecklist(story);
    expect(section).toContain('Sign in as an admin');
    // The dev-facing lines outside the section must NOT be pulled in.
    expect(section).not.toMatch(/targetFile|useEffect/);
  });

  it('FAIL: a jargon-laden manual-test line is caught in the extracted section', () => {
    const bad =
      '# Story\n\n## Manual test\n- Confirm the Skeleton hides when isLoading is false.\n';
    expect(findJargon(extractManualChecklist(bad)).length).toBeGreaterThanOrEqual(2);
  });

  it('PASS: returns empty string when there is no manual-test section', () => {
    expect(extractManualChecklist('# Story\n\n**Role:** Admin\n')).toBe('');
  });
});

// Epic-branch layout: the checklist lives in each story file's manual-test section.
const EPICS_DIR = path.join(REPO_ROOT, 'generated-docs', 'epics');
const hasStories = fs.existsSync(EPICS_DIR);

describe('TG-34 regression — real manual-test checklists (in story files)', () => {
  it.skipIf(!hasStories)('contain no engineering jargon', () => {
    const offenders: string[] = [];
    for (const file of walkFiles(EPICS_DIR, isStoryFile)) {
      const section = extractManualChecklist(fs.readFileSync(file, 'utf8'));
      const hits = findJargon(section);
      if (hits.length > 0) {
        offenders.push(`${path.relative(REPO_ROOT, file)}: ${hits.map(String).join(', ')}`);
      }
    }
    expect(offenders, `Jargon found:\n${offenders.join('\n')}`).toHaveLength(0);
  });
});
