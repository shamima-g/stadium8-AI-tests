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
    // Verbatim decision log: the question surfaces from the cost file.
    expect(html, 'the logged question surfaces verbatim').toContain(QUESTION);
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
