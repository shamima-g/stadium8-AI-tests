/**
 * The stakeholders report renders "Decisions you signed off" from the record (post-v1.2.0) — #4.
 *
 * `/build-report-stakeholders` gained a sign-off section: the product decisions the user was
 * asked for, each in plain language with the date, curated from the build's own authored record
 * at `generated-docs/reports/build-report-decisions.json`. Nothing is invented — a row needs a
 * `decision` and a `choice`, and the section disappears entirely when there's nothing to show.
 *
 * End-to-end over the real generator (`--audience stakeholders`) — the stakeholders page, which
 * no other test exercises end to end. Feature-detected on the stakeholders audience.
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
const SPLIT = BR_PRESENT && fs.readFileSync(path.join(REPO_ROOT, BUILD_REPORT), 'utf8').includes('stakeholders');

const STAKEHOLDERS_HTML = 'generated-docs/reports/build-report-stakeholders.html';
const DECISIONS_JSON = 'generated-docs/reports/build-report-decisions.json';

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

function generateStakeholders(project: TempProject) {
  return runScript(BUILD_REPORT, ['--root', project.root, '--no-insights', '--audience', 'stakeholders'], {
    cwd: project.root,
  });
}

const DECISION = 'How team members sign in';
const CHOICE = 'Email and password, no SSO for launch';
const WHEN = '2026-05-01';

describe('stakeholders report — Decisions you signed off (post-v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => {
    project = createTempProject();
  });
  afterEach(() => {
    project.cleanup(); // RB-0 — the throwaway temp project is discarded
  });

  it.skipIf(!SPLIT)('PASS: signed-off decisions render, dated, from the record — and nothing is invented', () => {
    seedBuiltProject(project);
    project.write(
      DECISIONS_JSON,
      JSON.stringify({
        decisions: [{ area: 'Access', decision: DECISION, choice: CHOICE, when: WHEN }],
        excludedCount: 3,
      }),
    );

    const r = generateStakeholders(project);
    expect(r.exitCode, r.stderr).toBe(0);
    expect(project.exists(STAKEHOLDERS_HTML), 'stakeholders page written').toBe(true);
    const html = project.read(STAKEHOLDERS_HTML);

    // Good case: the section, the decision, its choice, and the date all render from the record.
    expect(html, 'the sign-off section is present').toContain('Decisions you signed off');
    expect(html, 'the decision is rendered').toContain(DECISION);
    expect(html, 'the chosen option is rendered').toContain(CHOICE);
    expect(html, 'the decision date is rendered').toContain(WHEN);

    // Broken case / teeth: the rendered COUNT equals the one record — the section reports exactly
    // "1 decision recorded". An invented or duplicated row would make the generator count 2+ and
    // this would read "2 decisions recorded", turning the assertion red. This is the real
    // anti-fabrication guard: it catches extra rows the single decision/choice strings can't.
    expect(html, 'the sign-off reports exactly the one recorded decision').toContain('1 decision recorded');
    expect(html, 'a decision not in the record must not appear').not.toContain('Two-factor authentication');
  });

  // Teeth: the section is data-driven — with no record, it disappears entirely (proving the
  // PASS above rendered from the file, not from an always-on template block).
  it.skipIf(!SPLIT)('PASS (teeth): with no decisions record, the sign-off section is absent', () => {
    seedBuiltProject(project);
    const r = generateStakeholders(project);
    expect(r.exitCode, r.stderr).toBe(0);
    const html = project.read(STAKEHOLDERS_HTML);
    expect(html, 'no sign-off section without a record').not.toContain('Decisions you signed off');
  });
});
