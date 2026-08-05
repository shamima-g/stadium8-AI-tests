/**
 * Tier 2 — invariants over a recorded end-to-end workflow run.
 *
 * Replays one real run (a git bundle + generated-docs tree captured by hand — see
 * fixtures/golden-run/README.md) and asserts the cross-cutting properties that only
 * make sense across a whole epic. No live AI at test time.
 *
 * Until a golden run is captured, the invariant blocks SKIP VISIBLY (a notice prints);
 * the harness meta-checks below still run, so this file is never a vacuous green.
 */

import { describe, it, expect, afterAll } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import Ajv from 'ajv';
import { loadGoldenRun } from '../helpers/golden-run';
import { epicStateSchema } from '../helpers/schemas/epic-state.schema';
import { roleViolation } from '../tier-1-unit/artifact-lint/linters';

const golden = loadGoldenRun();
afterAll(() => golden.cleanup());

if (!golden.present) {
  // eslint-disable-next-line no-console -- intentional visible skip notice
  console.warn(`\n[tier-2 recorded-run] SKIPPED — ${golden.reason}\n`);
}

const ajv = new Ajv({ allErrors: true, strict: false });
const validateState = ajv.compile(epicStateSchema);

/** Absolute paths of every epic directory in the run's generated-docs/epics/. */
function epicDirs(docsDir: string): string[] {
  const epicsRoot = path.join(docsDir, 'epics');
  if (!fs.existsSync(epicsRoot)) return [];
  return fs.readdirSync(epicsRoot, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => path.join(epicsRoot, e.name));
}

function storyFiles(epicDir: string): string[] {
  const dir = path.join(epicDir, 'stories');
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter((f) => /^story-.+\.md$/.test(f)).map((f) => path.join(dir, f));
}

/** An epic parked ahead by `/plan` waits at this phase (between PLAN and BUILD). */
const PARKED_PHASE = 'READY-TO-BUILD';

interface EpicStateShape {
  phase?: string;
  stories?: Record<string, unknown>;
  epic?: { dependsOn?: unknown };
}
interface EpicRecord { dir: string; slug: string; state: EpicStateShape }

/**
 * Every epic dir paired with its parsed state.json. A missing or malformed state.json is
 * skipped here — the artifact-invariants block is what *fails* a malformed one; this helper
 * only classifies the ones it can read (e.g. to tell a parked epic from a built one).
 */
function epicRecords(docsDir: string): EpicRecord[] {
  const out: EpicRecord[] = [];
  for (const dir of epicDirs(docsDir)) {
    const f = path.join(dir, 'state.json');
    if (!fs.existsSync(f)) continue;
    try {
      out.push({ dir, slug: path.basename(dir), state: JSON.parse(fs.readFileSync(f, 'utf8')) as EpicStateShape });
    } catch {
      /* ignore — a malformed state.json is caught by the artifact-invariants block */
    }
  }
  return out;
}

/** Epics parked ahead by `/plan` (phase === READY-TO-BUILD). */
function parkedEpics(docsDir: string): EpicRecord[] {
  return epicRecords(docsDir).filter((e) => e.state?.phase === PARKED_PHASE);
}

// ---------------------------------------------------------------------------
// Harness meta-checks — ALWAYS run (keep the file non-vacuous even with no fixture)
// ---------------------------------------------------------------------------

describe('recorded-run harness', () => {
  it('PASS: the loader returns a well-formed status object', () => {
    expect(typeof golden.present).toBe('boolean');
    if (golden.present) {
      expect(golden.docsDir, 'a present run must expose a docsDir').toBeTruthy();
    } else {
      expect(golden.reason.length, 'an absent run must explain why (for the skip notice)').toBeGreaterThan(0);
    }
  });

  it('PASS: capture instructions exist for whoever records the run', () => {
    const readme = path.resolve(__dirname, '..', 'fixtures', 'golden-run', 'README.md');
    expect(fs.existsSync(readme)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Artifact invariants — run when a golden run (bundle OR docs tree) is present
// ---------------------------------------------------------------------------

describe.skipIf(!golden.present)('recorded run — artifact invariants', () => {
  const docsDir = golden.docsDir as string;

  it('PASS: every epic state.json validates against the epic-state schema', () => {
    const epics = epicDirs(docsDir);
    expect(epics.length, 'the run should contain at least one epic').toBeGreaterThan(0);
    for (const dir of epics) {
      const stateFile = path.join(dir, 'state.json');
      expect(fs.existsSync(stateFile), `${dir} is missing state.json`).toBe(true);
      const state = JSON.parse(fs.readFileSync(stateFile, 'utf8'));
      expect(validateState(state), `${stateFile}: ${JSON.stringify(validateState.errors)}`).toBe(true);
    }
  });

  it('PASS: every story declares a role and carries acceptance criteria', () => {
    const offenders: string[] = [];
    for (const dir of epicDirs(docsDir)) {
      for (const file of storyFiles(dir)) {
        const content = fs.readFileSync(file, 'utf8');
        const role = roleViolation(content);
        if (role) offenders.push(`${file}: ${role}`);
        // Tolerant acceptance-criteria signal (tighten to the real format once captured).
        const hasAC = /acceptance|criteri/i.test(content) || /^\s*[-*]\s+/m.test(content);
        if (!hasAC) offenders.push(`${file}: no acceptance criteria / checklist found`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('PASS: every built epic has a decision journal with entries', () => {
    // journal.md is a BUILD-phase artifact (appended per story commit), so a PLAN or a
    // `/plan`-parked (READY-TO-BUILD) epic legitimately has none yet — don't require it there.
    for (const e of epicRecords(docsDir)) {
      if (e.state?.phase === 'PLAN' || e.state?.phase === PARKED_PHASE) continue;
      const journal = path.join(e.dir, 'journal.md');
      expect(fs.existsSync(journal), `${e.dir} is missing journal.md`).toBe(true);
      expect(fs.readFileSync(journal, 'utf8').trim().length, `${journal} is empty`).toBeGreaterThan(0);
    }
  });

  it('PASS: absence canaries — no retired telemetry ledger or project-brief', () => {
    expect(fs.existsSync(path.join(docsDir, 'context', 'telemetry.ndjson'))).toBe(false);
    expect(fs.existsSync(path.join(docsDir, 'specs', 'project-brief.md'))).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Git-topology invariants — run only when the run was loaded from a bundle
// ---------------------------------------------------------------------------

describe.skipIf(!golden.present || !golden.hasGit)('recorded run — git topology', () => {
  const git = golden.git as NonNullable<typeof golden.git>;

  function epicRefs(): string[] {
    const out = git('branch', '-a', '--format=%(refname:short)');
    return out.stdout.split(/\r?\n/).map((s) => s.trim()).filter((s) => /(^|\/)epic\/[a-z0-9-]+$/.test(s));
  }

  it('PASS: at least one epic/<slug> branch exists in the recording', () => {
    expect(epicRefs().length, 'expected at least one epic/<slug> ref').toBeGreaterThan(0);
  });

  it('PASS: an epic reached main via a merge (not a direct push)', () => {
    const merged = git('branch', '-a', '--merged', 'main', '--format=%(refname:short)').stdout;
    const mergedEpic = merged.split(/\r?\n/).some((s) => /(^|\/)epic\/[a-z0-9-]+$/.test(s.trim()));
    const hasMergeCommit = git('log', '--merges', '--oneline', 'main').stdout.trim().length > 0;
    expect(mergedEpic && hasMergeCommit, 'main should contain a merge of an epic/<slug> branch').toBe(true);
  });

  it('PASS: an epic branch has at least as many commits as it has stories', () => {
    const docsDir = golden.docsDir as string;
    const slug = (golden.meta.epicSlug as string) || epicRefs()[0]?.split('/').pop() || '';
    const ref = epicRefs().find((r) => r.endsWith(`epic/${slug}`)) ?? epicRefs()[0];
    const commitCount = Number(git('rev-list', '--count', ref).stdout.trim() || '0');
    const epicDir = path.join(docsDir, 'epics', slug);
    const stories = fs.existsSync(epicDir) ? storyFiles(epicDir).length : 0;
    expect(commitCount, `epic ${slug} should have ≥ ${stories} commits`).toBeGreaterThanOrEqual(stories);
  });
});

// ---------------------------------------------------------------------------
// Parked-epic invariants (/plan) — run only when the recording contains an epic
// parked at READY-TO-BUILD. Feature-detected off the recording itself, so a
// version (or a capture) without /plan SKIPS VISIBLY rather than failing.
//
// Only the deterministic *traces* a parked epic leaves are asserted here; the
// /plan behaviours with an irreducible live core (the story approval actually
// firing, the mid-flow redirect, live merge-block enforcement across two
// sessions) stay in Tier 3 — see workflow-tests.md §8.
// ---------------------------------------------------------------------------

const hasParkedEpic = golden.present && parkedEpics(golden.docsDir as string).length > 0;

if (golden.present && !hasParkedEpic) {
  // eslint-disable-next-line no-console -- intentional visible skip notice
  console.warn(`\n[tier-2 recorded-run] /plan invariants SKIPPED — the recording has no epic parked at ${PARKED_PHASE} (capture one with /plan to activate them)\n`);
}

describe.skipIf(!hasParkedEpic)('recorded run — /plan parked-epic invariants (artifacts)', () => {
  const docsDir = golden.docsDir as string;

  it('PASS: every parked epic carries an approved story list (planned, not just drafted)', () => {
    // plan-stories-approved (trace) + plan-parked: parking happens *after* PLAN, so a parked
    // epic must already carry its broken-down stories — both on disk and recorded in state.json.
    const offenders: string[] = [];
    for (const e of parkedEpics(docsDir)) {
      if (storyFiles(e.dir).length === 0) offenders.push(`${e.slug}: parked at ${PARKED_PHASE} but has no story files`);
      if (!e.state?.stories || Object.keys(e.state.stories).length === 0) {
        offenders.push(`${e.slug}: parked at ${PARKED_PHASE} but state.json records no stories`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('PASS: a parked epic that depends on an unbuilt epic records that dependency (blocked-ahead)', () => {
    // plan-blocked-ahead: an epic may be planned ahead while still blocked; if it is, the block
    // must be recorded as a dependency. Conditional invariant — a parked epic with no deps
    // neither passes nor fails it (there is nothing to record).
    const offenders: string[] = [];
    for (const e of parkedEpics(docsDir)) {
      const deps = e.state?.epic?.dependsOn;
      if (Array.isArray(deps)) {
        const bad = deps.filter((d) => typeof d !== 'string' || !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(d));
        if (bad.length) offenders.push(`${e.slug}: malformed dependsOn ${JSON.stringify(bad)}`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });
});

describe.skipIf(!hasParkedEpic || !golden.hasGit)('recorded run — /plan parked-epic invariants (git topology)', () => {
  const git = golden.git as NonNullable<typeof golden.git>;
  const docsDir = golden.docsDir as string;

  const allBranches = (): string[] =>
    git('branch', '-a', '--format=%(refname:short)').stdout.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
  const branchExists = (name: string): boolean =>
    allBranches().some((b) => b === name || b.endsWith(`/${name}`));

  it('PASS: a parked epic has NOT started building — no epic/<slug> branch exists for it', () => {
    // plan-no-build-started: /plan parks WITHOUT building, and a build only ever happens on the
    // epic branch — so that branch's absence is the robust "no build started" signal.
    const offenders: string[] = [];
    for (const e of parkedEpics(docsDir)) {
      if (branchExists(`epic/${e.slug}`)) {
        offenders.push(`${e.slug}: an epic/${e.slug} branch exists — a parked epic must not have started building`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('PASS: no leftover plan/<slug> planning worktree/branch remains', () => {
    // plan-parked: /plan does its work in a throwaway plan/<slug> worktree and must clean it up
    // once the epic is parked on main.
    const offenders: string[] = [];
    for (const e of parkedEpics(docsDir)) {
      if (branchExists(`plan/${e.slug}`)) offenders.push(`${e.slug}: a plan/${e.slug} branch was left behind`);
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('PASS: a parked epic is parked on main (its state.json is committed on the default branch)', () => {
    // plan-parked: the parked record lands on main via a docs(plan) commit, so main's history
    // touches it. (Tightening to the exact docs(plan) subject is deferred until a golden run
    // with a parked epic is captured — matching this file's tolerant-until-recorded stance.)
    const offenders: string[] = [];
    for (const e of parkedEpics(docsDir)) {
      const rel = path.posix.join('generated-docs', 'epics', e.slug, 'state.json');
      if (!git('log', '--oneline', 'main', '--', rel).stdout.trim()) {
        offenders.push(`${e.slug}: no commit on main touches ${rel} — parked epic is not on main`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });
});
