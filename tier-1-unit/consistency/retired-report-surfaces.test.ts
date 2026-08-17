/**
 * The retired report commands/skills are gone (post-v1.2.0) — planned #2.
 *
 * The reports were split into two audience skills (`build-report-maintainer`,
 * `build-report-stakeholders`). The old single `/build-report` command, `/workflow-insights`,
 * and the `build-report-all` / `-cost` / `-effort` skills were removed (apply-template.js prunes
 * them on `/upgrade`; changelog: "/build-report, /workflow-insights and the three older report
 * commands are gone"). A lingering `/build-report` would bypass the shared procedure the two
 * skills now use, so this canary catches one creeping back.
 *
 * Gated on a POSITIVE signal of the post-split state (the maintainer skill exists), so it runs
 * only on the versions that did the split and skips — never fails — on older templates that
 * still legitimately ship the old surfaces.
 */

import { it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { REPO_ROOT } from '../../helpers';

const exists = (rel: string): boolean => fs.existsSync(path.join(REPO_ROOT, rel));

// Positive marker for the split: the two audience skills that replaced the old surfaces.
const NEW_REPORTS = exists('.claude/skills/build-report-maintainer');

// The literal surfaces the split retired. NOTE on `/workflow-insights`: it only ever shipped as a
// SKILL directory (`.claude/skills/workflow-insights/`, present through v1.2.0), never as a
// `.claude/commands/*.md` — an earlier version of this canary watched the wrong (command) path, so
// a lingering workflow-insights skill would not have been caught. Watch the real skill dir.
const RETIRED = [
  '.claude/commands/build-report.md',
  '.claude/skills/workflow-insights',
  '.claude/skills/build-report-all',
  '.claude/skills/build-report-cost',
  '.claude/skills/build-report-effort',
];

describe('retired report commands/skills are gone (post-v1.2.0)', () => {
  it.skipIf(!NEW_REPORTS)('PASS: none of the retired report surfaces exist', () => {
    const lingering = RETIRED.filter(exists);
    expect(lingering, `retired report surfaces must be removed:\n${lingering.join('\n')}`).toEqual([]);
  });

  // Teeth: the existence check discriminates — the surfaces that REPLACED them ARE present,
  // so the all-absent result above isn't fs.existsSync silently returning false for everything.
  it.skipIf(!NEW_REPORTS)('PASS (teeth): the replacement report skills ARE present', () => {
    expect(exists('.claude/skills/build-report-maintainer'), 'maintainer skill present').toBe(true);
    expect(exists('.claude/skills/build-report-stakeholders'), 'stakeholders skill present').toBe(true);
  });
});
