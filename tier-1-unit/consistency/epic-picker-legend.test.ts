/**
 * The shared epic-picker legend must match the statuses the collector actually emits.
 *
 * `shared/epic-picker.md` (v1.2.0) prints a glyph legend — `✓ done · ▸ in-flight ·
 * ◆ ready-to-build · ● ready · ⊘ blocked` — used by `/start`, `/plan`, and `/status`
 * to describe each planned epic. Those statuses are DERIVED by
 * `collect-dashboard-data.js` (`plan[].status`). If the legend and the collector drift
 * apart — a glyph for a status the code never produces, or a produced status the legend
 * forgot — the picker misleads the user. This proves they agree, by parsing the legend
 * and observing every status from a real collector run over a 5-state fixture.
 *
 * Behavioural (reads live values on both sides), not a pinned literal — so it holds
 * across versions. Feature-detected on epic-picker.md (skips cleanly if absent). RB-1.
 */

import { it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import {
  REPO_ROOT,
  createTempProject,
  seedProjectMd,
  seedEpicPlan,
  seedEpicState,
  gitSandbox,
  runScript,
  rollback,
} from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const PICKER = path.join(REPO_ROOT, '.claude', 'shared', 'epic-picker.md');
const PRESENT = fs.existsSync(PICKER);
const COLLECT = '.claude/scripts/collect-dashboard-data.js';

/** The backticked status tokens in the legend's glyph table (skips the `status` header). */
function legendStatuses(md: string): string[] {
  const out: string[] = [];
  for (const line of md.split(/\r?\n/)) {
    const cells = line.split('|').map((c) => c.trim());
    if (cells.length < 4 || cells[1] === 'Glyph') continue; // not a data row / header row
    const m = cells[2].match(/^`([a-z][a-z-]*)`$/); // the status cell is exactly a backticked token
    if (m) out.push(m[1]);
  }
  return out;
}

/**
 * Seed one epic per plan status and return the set of statuses the collector derives.
 * done = merged on main; in-flight = a BUILD branch; ready-to-build = a parked branch;
 * ready = a draft with deps met; blocked = a draft with an unmet dep.
 */
function observedStatuses(project: TempProject): Set<string> {
  const git = gitSandbox(project.root);
  // Merged detection reads the `main` branch by name — make the base branch `main`.
  git.git('symbolic-ref', 'HEAD', 'refs/heads/main');
  seedProjectMd(project.root);
  seedEpicPlan(project.root, [
    { slug: 'e-done', name: 'Done One', goal: 'g' },
    { slug: 'e-inflight', name: 'In Flight', goal: 'g' },
    { slug: 'e-rtb', name: 'Parked', goal: 'g' },
    { slug: 'e-ready', name: 'Ready One', goal: 'g' },
    { slug: 'e-blocked', name: 'Blocked One', goal: 'g', dependsOn: ['e-ready'] },
  ]);
  seedEpicState(project.root, { slug: 'e-done', name: 'Done One', phase: 'COMPLETE', stories: {} });
  git.commit('main: plan + merged e-done');

  for (const [slug, phase] of [['e-inflight', 'BUILD'], ['e-rtb', 'READY-TO-BUILD']] as const) {
    expect(git.git('checkout', '-q', '-b', `epic/${slug}`).exitCode).toBe(0);
    seedEpicState(project.root, { slug, name: slug, phase, stories: { '1': { status: 'pending' } } });
    git.commit(`branch ${slug}`);
    expect(git.git('checkout', '-q', 'main').exitCode).toBe(0);
  }
  // e-ready / e-blocked stay drafts (no branch): ready (deps met) and blocked (dep unmet).

  const plan = runScript(COLLECT, ['--root', project.root, '--format=json'], { cwd: project.root })
    .json<{ plan: { status: string }[] }>().plan;
  return new Set(plan.map((e) => e.status));
}

describe('shared/epic-picker.md — legend matches the collector\'s plan statuses (v1.2.0)', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { rollback(project.root, 'RB-1'); project.cleanup(); });

  it.skipIf(!PRESENT)('PASS: every legend glyph is a real status, and every status has a glyph', () => {
    const legend = new Set(legendStatuses(fs.readFileSync(PICKER, 'utf8')));
    expect(legend.size, 'expected the 5-status legend to parse').toBeGreaterThanOrEqual(5);

    const observed = observedStatuses(project);
    // Non-vacuity: the fixture really did exercise all five distinct statuses.
    expect(observed.size, `expected 5 distinct statuses, saw: ${[...observed].sort().join(', ')}`).toBe(5);

    // Agreement both ways: no glyph for a status the code never produces, and no
    // produced status the legend forgot.
    const orphanGlyphs = [...legend].filter((s) => !observed.has(s));
    const missingGlyphs = [...observed].filter((s) => !legend.has(s));
    expect(orphanGlyphs, `legend lists statuses the collector never emits: ${orphanGlyphs.join(', ')}`).toEqual([]);
    expect(missingGlyphs, `collector emits statuses the legend is missing: ${missingGlyphs.join(', ')}`).toEqual([]);
  });

  it('PASS: the legend parser has teeth (finds real rows, skips the header)', () => {
    // A synthetic legend proves the parser distinguishes data rows from the header —
    // so the agreement test above can actually go red on a real orphan/missing glyph.
    const sample = [
      '| Glyph | `status` | Meaning |',
      '|---|---|---|',
      '| ✓ | `done` | Merged |',
      '| ◆ | `ready-to-build` | Parked |',
    ].join('\n');
    expect(legendStatuses(sample).sort()).toEqual(['done', 'ready-to-build']); // NOT the `status` header
  });
});
