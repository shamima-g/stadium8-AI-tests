/**
 * TG-38 — Every story file declares a non-empty Role.
 *
 * Rule: generated-docs/epics/<slug>/stories/story-*.md must declare a role with a
 * real value (not blank, "N/A", "TBD", or "unknown"). The role may be given as a
 * bold marker (`**Role:** admin` / `**Roles:** …`), a metadata-table row
 * (`| Role | admin |` / `| Roles | Importer, Approver |`), or a `## Roles` heading
 * whose first line is the value (`## Roles\n\n- User`), singular or plural.
 *
 * The rule is tested against fixtures; a regression scan runs it over the real
 * epic story tree when one exists, and is skipped (visibly) otherwise.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';
import { extractRole, roleViolation, walkFiles, isStoryFile, EMPTY_ROLE_VALUES } from './linters';

describe('TG-38 rule — extractRole / roleViolation', () => {
  it('PASS: extracts a standard role and reports no violation', () => {
    expect(extractRole('# Story\n\n**Role:** Admin\n')).toBe('Admin');
    expect(roleViolation('# Story\n\n**Role:** Admin\n')).toBeNull();
  });

  it('PASS: "All authenticated users" is a valid non-restricted role', () => {
    const content = '# Story\n\n**Role:** All authenticated users\n';
    expect(roleViolation(content)).toBeNull();
    expect(EMPTY_ROLE_VALUES.has('all authenticated users')).toBe(false);
  });

  it('PASS: accepts a plain metadata-table row, singular or plural', () => {
    expect(extractRole('# Story\n\n| Role | Approver |\n')).toBe('Approver');
    expect(extractRole('# Story\n\n| Roles | Importer, Approver |\n')).toBe('Importer, Approver');
    expect(roleViolation('# Story\n\n| Roles | Importer, Approver |\n')).toBeNull();
  });

  it('PASS: accepts the bold plural marker', () => {
    expect(extractRole('# Story\n\n**Roles:** Importer, Approver\n')).toBe('Importer, Approver');
    expect(roleViolation('# Story\n\n**Roles:** Importer, Approver\n')).toBeNull();
  });

  it('PASS: accepts a `## Roles` heading with a bulleted value (dev/main story format)', () => {
    const content = '# Story 1\n\n## Roles\n\n- User (signed-in)\n\n## Requirement IDs\n\nR1\n';
    expect(extractRole(content)).toBe('User (signed-in)');
    expect(roleViolation(content)).toBeNull();
  });

  it('PASS: accepts a `## Role` heading with a plain (unbulleted) value', () => {
    expect(extractRole('# Story\n\n## Role\nAdmin\n')).toBe('Admin');
    expect(roleViolation('# Story\n\n## Role\nAdmin\n')).toBeNull();
  });

  it('FAIL: an empty `## Roles` section (heading straight into the next heading) is missing', () => {
    expect(roleViolation('# Story\n\n## Roles\n\n## Next\n\ncontent\n')).toBe('missing **Role:** field');
  });

  it('FAIL: flags an empty table-row role', () => {
    expect(roleViolation('# Story\n\n| Roles |  |\n')).not.toBeNull();
  });

  it('FAIL: flags an empty role', () => {
    expect(roleViolation('# Story\n\n**Role:**\n')).not.toBeNull();
  });

  it('FAIL: flags "N/A" as empty/ambiguous', () => {
    expect(roleViolation('# Story\n\n**Role:** N/A\n')).toMatch(/empty\/ambiguous/);
  });

  it('FAIL: flags a story with no Role field at all', () => {
    expect(roleViolation('# Story\n\nNo role declared.\n')).toBe('missing **Role:** field');
  });
});

// Epic-branch layout: story files live under generated-docs/epics/<slug>/stories/.
// walkFiles recurses, so pointing at the epics root and matching story-*.md finds them.
const EPICS_DIR = path.join(REPO_ROOT, 'generated-docs', 'epics');
const hasStories = fs.existsSync(EPICS_DIR);

describe('TG-38 regression — real story files', () => {
  it.skipIf(!hasStories)('every story file has a valid Role', () => {
    const offenders: string[] = [];
    for (const file of walkFiles(EPICS_DIR, isStoryFile)) {
      const problem = roleViolation(fs.readFileSync(file, 'utf8'));
      if (problem) offenders.push(`${path.relative(REPO_ROOT, file)}: ${problem}`);
    }
    expect(offenders, offenders.join('\n')).toHaveLength(0);
  });
});
