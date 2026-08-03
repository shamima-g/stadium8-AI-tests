/**
 * Security canary — the report generators HTML-escape data-derived strings.
 *
 * v1.2.0 centralised HTML escaping in `.claude/scripts/lib/html-escape.js` (`esc`) and
 * routed BOTH generated pages through it — the dashboard and the new build report.
 * Epic names and story titles are user/AI-authored and flow verbatim into that HTML,
 * so an unescaped `<script>` would execute in the browser the moment the user opens
 * `/dashboard` or `/build-report`. This pins that both generators escape such strings.
 *
 * Peer to the bash-permission-checker fuzz: a security invariant of generated output,
 * not a cosmetic check. Each generator gets a good case (payload present, but only in
 * escaped form) and the file carries a detector-teeth case proving the check isn't
 * vacuous. Pins the v1.2.0 shape (older versions: use the matching-version suite).
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

const DASHBOARD = '.claude/scripts/generate-dashboard-html.js';
const BUILD_REPORT = '.claude/scripts/generate-build-report-html.js';

// The build report + shared html-escape lib arrived in v1.2.0. Feature-detect so the
// build-report arm SKIPS (a distinct, honest state — not a fake green) on a template
// that predates it, per workflow-tests.md §12 Layer B. The dashboard has shipped for
// longer, so its arm is unconditional.
const BR_PRESENT = fs.existsSync(path.join(REPO_ROOT, BUILD_REPORT));

// Unmistakable in output, dangerous if unescaped, and quote-free so the escaped form
// is unambiguous (esc maps < > & " ' — we only rely on < > here).
const XSS = '<script>alert(1)</script>';
const RAW_MARKER = '<script>alert(1)'; // the dangerous raw substring
const ESC_MARKER = '&lt;script&gt;alert(1)'; // esc()'s output for the same

/** Seed an in-flight epic whose NAME and a story TITLE both carry the XSS payload. */
function seedMaliciousEpic(project: TempProject): void {
  const git = gitSandbox(project.root);
  seedProjectMd(project.root, { name: 'Team Task Manager' });
  git.commit('intake');
  git.git('checkout', '-q', '-b', 'epic/task-x');
  seedStoryFile(project.root, { slug: 'task-x', index: 1, title: `Nav ${XSS}` });
  seedEpicState(project.root, {
    slug: 'task-x',
    name: `Tasks ${XSS}`,
    phase: 'BUILD',
    stories: { '1': { status: 'in-progress' } },
  });
  git.commit('build');
}

describe('report generators — HTML-escape data-derived strings (v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('PASS: the dashboard escapes a markup-bearing epic name / story title', () => {
    seedMaliciousEpic(project);
    const r = runScript(DASHBOARD, ['--root', project.root], { cwd: project.root });
    expect(r.exitCode, r.stderr).toBe(0);
    const html = project.read('generated-docs/dashboard.html');
    expect(html, 'the payload should reach the page (escaped)').toContain(ESC_MARKER);
    expect(html, 'the raw <script> must never appear').not.toContain(RAW_MARKER);
  });

  it.skipIf(!BR_PRESENT)('PASS: the build report escapes a markup-bearing epic name / story title', () => {
    seedMaliciousEpic(project);
    const r = runScript(BUILD_REPORT, ['--root', project.root, '--no-insights'], { cwd: project.root });
    expect(r.exitCode, r.stderr).toBe(0);
    const html = project.read('generated-docs/build-report.html');
    expect(html, 'the payload should reach the page (escaped)').toContain(ESC_MARKER);
    expect(html, 'the raw <script> must never appear').not.toContain(RAW_MARKER);
  });

});

// The broken case lives INSIDE each PASS test above, not in a separate assertion: the
// `.not.toContain(RAW_MARKER)` runs against the generator's REAL output, so if the
// template ever stopped escaping, that arm turns red. (An earlier standalone "teeth"
// test only exercised String.includes on hand-built literals — it proved nothing about
// the template, so it was removed as vacuous per workflow-tests.md rule 1.)
