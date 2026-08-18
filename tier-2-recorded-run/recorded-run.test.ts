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
import { epicHasDecisionTrail } from '../helpers/design-digest';

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

/** True for an epic that has actually been built (past PLAN and not parked ahead). */
function isBuilt(e: EpicRecord): boolean {
  return e.state?.phase !== 'PLAN' && e.state?.phase !== PARKED_PHASE;
}

/** Story numbers declared on disk for an epic, parsed from `story-<N>-*.md`. */
function storyNumbers(epicDir: string): string[] {
  return storyFiles(epicDir)
    .map((f) => /^story-(\d+)-/.exec(path.basename(f))?.[1])
    .filter((n): n is string => Boolean(n));
}

/**
 * The `EPIC_PHASES` the RECORDING itself was produced with, parsed straight from its own
 * `.claude/scripts/lib/epic-state.js`. This grades recorded phases against the version that
 * produced them (not the suite's target), so a retired stage name is caught while a newer
 * legitimate stage is not mis-flagged. Null when the recording carries no template (a
 * docs-only capture) — the phase-validity check then skips visibly.
 */
function recordedEpicPhases(): string[] | null {
  if (!golden.root) return null;
  const lib = path.join(golden.root, '.claude', 'scripts', 'lib', 'epic-state.js');
  if (!fs.existsSync(lib)) return null;
  const m = /EPIC_PHASES\s*=\s*Object\.freeze\(\s*\[([\s\S]*?)\]/.exec(fs.readFileSync(lib, 'utf8'));
  if (!m) return null;
  const phases = [...m[1].matchAll(/['"]([^'"]+)['"]/g)].map((x) => x[1]);
  return phases.length ? phases : null;
}

const recordedPhases = golden.present ? recordedEpicPhases() : null;
const e2eDir = golden.present && golden.root ? path.join(golden.root, 'web', 'e2e') : '';
const hasE2eDir = Boolean(e2eDir) && fs.existsSync(e2eDir);
const claudeDir = golden.present && golden.root ? path.join(golden.root, '.claude') : '';
const hasClaudeDir = Boolean(claudeDir) && fs.existsSync(claudeDir);

if (golden.present && !recordedPhases) {
  // eslint-disable-next-line no-console -- intentional visible skip notice
  console.warn(`\n[tier-2 recorded-run] phase-validity check SKIPPED — the recording carries no .claude/scripts/lib/epic-state.js (docs-only capture)\n`);
}
if (golden.present && !hasE2eDir) {
  // eslint-disable-next-line no-console -- intentional visible skip notice
  console.warn(`\n[tier-2 recorded-run] app-tests check SKIPPED — the recording has no web/e2e/ tree (docs-only capture)\n`);
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

  it.skipIf(!recordedPhases)('PASS: every recorded phase is a current EPIC_PHASE — no retired stage names', () => {
    // Graded against the recording's OWN epic-state.js, so a retired four-phase name (or any
    // stage the producing version didn't define) fails, while a legitimately newer stage does
    // not get mis-flagged. Skips visibly on a docs-only capture (no template in the recording).
    const valid = new Set(recordedPhases as string[]);
    const offenders: string[] = [];
    for (const e of epicRecords(docsDir)) {
      if (typeof e.state?.phase !== 'string' || !valid.has(e.state.phase)) {
        offenders.push(`${e.slug}: phase ${JSON.stringify(e.state?.phase)} is not a current EPIC_PHASE [${[...valid].join(', ')}]`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('PASS: every story declares a role and carries acceptance criteria', () => {
    const offenders: string[] = [];
    for (const dir of epicDirs(docsDir)) {
      for (const file of storyFiles(dir)) {
        const content = fs.readFileSync(file, 'utf8');
        const role = roleViolation(content);
        if (role) offenders.push(`${file}: ${role}`);
        // Acceptance criteria: require a real "Acceptance Criteria" section heading OR a
        // checklist (`- [ ]` / `- [x]`) — not merely any bullet, which the tolerant
        // pre-capture signal accepted. The captured stories carry a `## Acceptance Criteria`
        // heading, so a story that loses it now fails.
        const hasAC = /^#{1,6}\s*acceptance criteria\b/im.test(content) || /^\s*[-*]\s+\[[ xX]\]\s+/m.test(content);
        if (!hasAC) offenders.push(`${file}: no "Acceptance Criteria" section or checklist found`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('PASS: every built epic records a decision trail (journal.md, or the design digest for a design-driven run)', () => {
    // journal.md is a BUILD-phase artifact, so a PLAN or `/plan`-parked epic legitimately has none.
    // Refinement (see helpers/design-digest.ts epicHasDecisionTrail + tier-1-unit/design/decision-trail.test.ts):
    // a minimal design-driven epic can be COMPLETE with no per-epic journal because its decisions
    // live in the design digest's "Your Decisions" instead. Accept either; still fail an empty
    // journal or an epic with no trail at all.
    const digestPath = path.join(docsDir, 'design', 'digest.md');
    const digest = fs.existsSync(digestPath) ? fs.readFileSync(digestPath, 'utf8') : null;
    const offenders: string[] = [];
    for (const e of epicRecords(docsDir)) {
      if (e.state?.phase === 'PLAN' || e.state?.phase === PARKED_PHASE) continue;
      const jf = path.join(e.dir, 'journal.md');
      const journal = fs.existsSync(jf) ? fs.readFileSync(jf, 'utf8') : null;
      const trail = epicHasDecisionTrail(journal, digest);
      if (!trail.ok) offenders.push(`${path.basename(e.dir)}: ${trail.reason}`);
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('PASS: absence canaries — no retired telemetry ledger or project-brief', () => {
    expect(fs.existsSync(path.join(docsDir, 'context', 'telemetry.ndjson'))).toBe(false);
    expect(fs.existsSync(path.join(docsDir, 'specs', 'project-brief.md'))).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Repo-level absence canaries — run only when the recording carries its .claude/
// (bundle capture). A docs-only capture has no .claude, so these SKIP VISIBLY.
// ---------------------------------------------------------------------------

describe.skipIf(!hasClaudeDir)('recorded run — repo absence canaries (retired machinery)', () => {
  it('PASS: no retired code-reviewer agent (superseded by code-review-runner)', () => {
    // The old `code-reviewer` agent was retired; the current surface is `code-review-runner`.
    // Match the exact retired basename so `code-review-runner.md` is NOT a false positive.
    expect(fs.existsSync(path.join(claudeDir, 'agents', 'code-reviewer.md'))).toBe(false);
  });

  it('PASS: no .claude/logs/ session-log directory', () => {
    expect(fs.existsSync(path.join(claudeDir, 'logs'))).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// App tests line up with the stories — run only when the recording carries a
// web/e2e/ tree (bundle capture). A docs-only capture SKIPS VISIBLY.
//
// Tier 2 asserts a spec EXISTS per built story and is real (a live test() or a
// justified test.fixme()). The stricter routable→live / non-routable→fixme
// distinction is a Tier-1 rule (workflow-tests.md §9).
// ---------------------------------------------------------------------------

describe.skipIf(!hasE2eDir)('recorded run — app tests line up with the stories', () => {
  const docsDir = golden.docsDir as string;
  const specs = fs.readdirSync(e2eDir).filter((f) => /\.spec\.[jt]sx?$/.test(f));

  it('PASS: every story in a built epic has a matching, non-empty e2e spec', () => {
    const offenders: string[] = [];
    for (const e of epicRecords(docsDir)) {
      if (!isBuilt(e)) continue; // a parked / PLAN epic has legitimately not produced specs yet
      for (const n of storyNumbers(e.dir)) {
        const spec = specs.find((s) => s.startsWith(`epic-${e.slug}-story-${n}-`));
        if (!spec) {
          offenders.push(`${e.slug} story ${n}: no web/e2e/epic-${e.slug}-story-${n}-*.spec.ts`);
          continue;
        }
        const body = fs.readFileSync(path.join(e2eDir, spec), 'utf8');
        // A live `test(` — not `.test(` (a regex/method call) and not `test.fixme(`/`test.skip(`.
        const hasLiveTest = /(^|[^.\w])test\s*\(/m.test(body);
        const hasJustifiedFixme = /test\.fixme\s*\(/.test(body) && /reason|because|\/\//i.test(body);
        if (!hasLiveTest && !hasJustifiedFixme) {
          offenders.push(`${e.slug} story ${n}: ${spec} has neither a live test() nor a justified test.fixme()`);
        }
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
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

  it('PASS: each story in a built epic has its own feat(<slug>/story-<N>) commit', () => {
    const docsDir = golden.docsDir as string;
    const offenders: string[] = [];
    for (const e of epicRecords(docsDir)) {
      if (!isBuilt(e)) continue; // a parked / PLAN epic has legitimately not committed a build
      const ref = epicRefs().find((r) => r.endsWith(`epic/${e.slug}`)) ?? 'main';
      const subjects = git('log', '--format=%s', ref).stdout;
      for (const n of storyNumbers(e.dir)) {
        const re = new RegExp(`^feat\\(${e.slug}/story-${n}\\b`, 'm');
        if (!re.test(subjects)) {
          offenders.push(`${e.slug} story ${n}: no feat(${e.slug}/story-${n}) commit found on ${ref}`);
        }
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
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

  it('PASS: a parked epic is parked on main via a docs(plan) commit', () => {
    // plan-parked: the parked record lands on main via a `docs(plan)` commit. Assert both that
    // main's history touches the state file AND that a touching commit's subject is `docs(plan)`
    // — a parked epic that arrived via a feat/wip/other commit is not a clean `/plan` parking.
    const offenders: string[] = [];
    for (const e of parkedEpics(docsDir)) {
      const rel = path.posix.join('generated-docs', 'epics', e.slug, 'state.json');
      const subjects = git('log', '--format=%s', 'main', '--', rel).stdout
        .split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
      if (subjects.length === 0) {
        offenders.push(`${e.slug}: no commit on main touches ${rel} — parked epic is not on main`);
      } else if (!subjects.some((s) => /^docs\(plan\)/.test(s))) {
        offenders.push(`${e.slug}: ${rel} is on main but via no docs(plan) commit (subjects: ${subjects.join(' | ')})`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });
});
