/**
 * The maintainer report surfaces the user-involvement summary + decision log (post-v1.2.0) — #5.
 *
 * The maintainer report leads with how involved the user had to be — how many phases ran
 * unattended, the typical answer time — and logs every question verbatim with the option chosen.
 * All of it is read from `generated-docs/reports/build-cost-data.json` (written by the cost
 * generator from the transcripts). This proves the WHOLE chain surfaces that content through the
 * real `--audience maintainer` subprocess — collect → render → write — over a POPULATED cost
 * file. (The pure renderers are unit-tested co-located; #9 already proves the no-crash path on a
 * partial file — this proves a populated file's content actually reaches the page.)
 *
 * Feature-detected on the generator; skips on older cuts.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import {
  createTempProject,
  seedProjectMd,
  seedEpicState,
  seedStoryFile,
  gitSandbox,
  runScript,
  REPO_ROOT,
} from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const BUILD_REPORT = '.claude/scripts/generate-build-report-html.js';
const BR_PRESENT = fs.existsSync(path.join(REPO_ROOT, BUILD_REPORT));

const REPORT_HTML = 'generated-docs/reports/build-report.html';
const COST_DATA = 'generated-docs/reports/build-cost-data.json';

function seedBuiltProject(project: TempProject): void {
  const git = gitSandbox(project.root);
  seedProjectMd(project.root, { name: 'Team Task Manager' });
  git.commit('intake');
  git.git('checkout', '-q', '-b', 'epic/task-x');
  seedStoryFile(project.root, { slug: 'task-x', index: 1, title: 'Nav' });
  seedEpicState(project.root, {
    slug: 'task-x',
    name: 'Tasks',
    phase: 'BUILD',
    stories: { '1': { status: 'in-progress' } },
  });
  git.commit('build');
}

// The distinctive question text we expect to surface verbatim in the decision log.
const QUESTION = 'Which sign-in method should launch use';

// A minimal but valid build-cost-data.json: enough for readInsightsSummary (needs `grand`) to
// return a populated summary that renders the involvement panel and the verbatim decision log.
// The involvement figures are chosen so their RENDERED values are pinnable: two unattended
// buckets over one costed bucket → the "phases run unattended" stat reads exactly `2 / 1`, and a
// 45 000 ms median answer time → the "typical answer" reads exactly `45s`.
const COST_FIXTURE = {
  generatedAt: '2026-05-01T00:00:00Z',
  grand: { costUsd: 12.5, totalTokens: 120000, output: 40000, calls: 200, cacheHit: 0.5 },
  answerStatsTotal: { medianMs: 45000, maxMs: 120000, samples: 3 },
  // The waiting-on-user card (which carries "typical answer") renders only when waits are present.
  waitsTotal: { approvalMs: 60000, approvalCount: 2, generalMs: 30000, generalCount: 1, stallMs: 0, stallCount: 0 },
  unattendedBuckets: ['BUILD story-1', 'BUILD story-2'],
  stallThresholdMin: 10,
  buckets: [
    {
      label: 'INTAKE',
      questionsAsked: 1,
      tokens: { costUsd: 5 },
      decisions: [{ header: 'Sign-in', question: QUESTION, answer: 'Email and password', resolved: true, waitMs: 45000 }],
    },
  ],
};

// A DIFFERENT set of involvement figures: three unattended buckets over two costed buckets
// (`3 / 2`) and a 90 000 ms median answer time (`1m 30s`). Rendering this instead of COST_FIXTURE
// must move both figures — the guard against a hard-coded / placeholder count or time.
const COST_FIXTURE_VARIED = {
  ...COST_FIXTURE,
  answerStatsTotal: { medianMs: 90000, maxMs: 180000, samples: 5 },
  unattendedBuckets: ['BUILD story-1', 'BUILD story-2', 'BUILD story-3'],
  buckets: [
    { label: 'INTAKE', questionsAsked: 1, tokens: { costUsd: 5 }, decisions: [] },
    { label: 'BUILD', questionsAsked: 0, tokens: { costUsd: 7 }, decisions: [] },
  ],
};

describe('maintainer report — user-involvement summary + decision log (post-v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => {
    project = createTempProject();
  });
  afterEach(() => {
    project.cleanup(); // RB-0 — the throwaway temp project is discarded
  });

  it.skipIf(!BR_PRESENT)('PASS: a populated cost file surfaces the unattended-phase count, answer time, and the logged question', () => {
    seedBuiltProject(project);
    project.write(COST_DATA, JSON.stringify(COST_FIXTURE));

    const r = runScript(BUILD_REPORT, ['--root', project.root, '--no-insights'], { cwd: project.root });
    expect(r.exitCode, r.stderr).toBe(0);
    const html = project.read(REPORT_HTML);

    // Involvement summary: how many phases ran with no input, and the typical answer time.
    expect(html, 'the unattended-phases stat is present').toContain('phases run unattended');
    expect(html, 'the typical answer time is shown').toContain('typical answer');
    // …and the VALUES are the ones from the cost file, not just the labels — two unattended
    // buckets over one costed bucket, and a 45s median answer. A hard-coded figure fails here.
    expect(html, 'the unattended-phase count is computed from the file (2 / 1)').toContain('2 / 1');
    expect(html, 'the typical answer time is computed from the file (45s)').toContain('typical answer 45s');
    // Verbatim decision log: the question surfaces from the cost file.
    expect(html, 'the logged question surfaces verbatim').toContain(QUESTION);
  });

  // Teeth: the involvement FIGURES move with the input. Rendering a different cost file yields
  // different rendered values (3 / 2, 1m 30s) and none of the first file's values — proving the
  // count and time are data-derived, not a hard-coded or placeholder string.
  it.skipIf(!BR_PRESENT)('PASS (teeth): the unattended count and answer time change with the cost file', () => {
    seedBuiltProject(project);
    project.write(COST_DATA, JSON.stringify(COST_FIXTURE_VARIED));
    const r = runScript(BUILD_REPORT, ['--root', project.root, '--no-insights'], { cwd: project.root });
    expect(r.exitCode, r.stderr).toBe(0);
    const html = project.read(REPORT_HTML);
    expect(html, 'the new fixture renders its own unattended count').toContain('3 / 2');
    expect(html, 'the new fixture renders its own answer time').toContain('typical answer 1m 30s');
    expect(html, "the first fixture's count must not appear").not.toContain('2 / 1');
    expect(html, "the first fixture's answer time must not appear").not.toContain('typical answer 45s');
  });

  // Teeth: the content is data-driven — a question NOT in the file never appears, so the PASS
  // above proves the file was consumed, not that the page always prints these strings.
  it.skipIf(!BR_PRESENT)('PASS (teeth): a question absent from the cost file does not appear', () => {
    seedBuiltProject(project);
    project.write(COST_DATA, JSON.stringify(COST_FIXTURE));
    const r = runScript(BUILD_REPORT, ['--root', project.root, '--no-insights'], { cwd: project.root });
    expect(r.exitCode, r.stderr).toBe(0);
    const html = project.read(REPORT_HTML);
    expect(html, 'an unlogged question must not appear').not.toContain('Which database engine should we use');
  });
});
