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

  it('PASS: every epic has a decision journal with entries', () => {
    for (const dir of epicDirs(docsDir)) {
      const journal = path.join(dir, 'journal.md');
      expect(fs.existsSync(journal), `${dir} is missing journal.md`).toBe(true);
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
