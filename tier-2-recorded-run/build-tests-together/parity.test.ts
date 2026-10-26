/**
 * Tier 2 — build-tests-together invariants over a recorded BUILD run (no live AI at test time).
 *
 * Feature (commit 4666e23): one `test-generator` per story writes BOTH test files, so both expect the
 * same controls. These invariants replay a frozen capture that STOPPED after Step B0.2 (tests generated,
 * no story built yet) and assert, deterministically:
 *   - T2.1  one agent per story: transcript verdict is one-agent-per-story; distinct stories covered ==
 *           story count; no vitest/playwright split; epic-mocks ≤ 1. (Single-epic capture — asserted.)
 *   - T2.2  control parity: for every story whose two files share a control name, the (strategy, role)
 *           signatures match (helpers/control-refs.compareControls). Stories that share NO control name are
 *           `skipped-no-overlap` — NORMAL here, because coverage tags are disjoint across the two files, so
 *           many stories legitimately reference different controls. Those are SURFACED (counted + logged),
 *           never a silent pass and never a false red; the divergent calibration slot is what proves the
 *           check bites.
 *   - T2.3  both files present per story (spec always; Vitest unless the story had no `vitest`-tagged AC,
 *           read from the transcript return — see rules.missingFileOffense).
 *   - T2.4  routable specs carry a live test() not wrapped in test.fixme() (rules.routableFixmeOffense).
 *
 * SLOT FORM — the GOOD slot is a FLAT docs+web WORKING-TREE copy, NOT a git bundle. The capture stops
 * after B0.2, BEFORE the first story's B5 commit, so the generated test files are uncommitted — a
 * `git bundle --all` would NOT contain them. So the capture copies the post-B0.2 `generated-docs/` and
 * `web/` trees into the slot dir (loadGoldenRun's docs-only branch → root = slot dir), alongside
 * `transcript.jsonl` and a `recorded/` dir for T2.5.
 *
 * SLOTS:
 *   - `build-tests-together-contact-form` (GOOD) — from the live capture; SKIPS until present (set
 *     REQUIRE_BUILD_TESTS_TOGETHER=1 to turn the absent good slot RED for a release run).
 *   - `build-tests-together-divergent` (PLANTED-BAD calibration) — hand-built docs tree, present now: a
 *     valid ONE-agent run whose Story 2 files disagree on a control. Proves T2.2 can go RED.
 *
 * T2.5 (npm test fails pre-build / test:e2e --list / lint) is asserted over the capture's RECORDED command
 * outputs at `fixtures/golden-runs/<slot>/recorded/{npm-test.txt, test-e2e-list.txt, lint.txt}` — added
 * with the live capture, since the frozen tree carries no node_modules to re-run.
 */

import { describe, it, expect, afterAll } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { loadGoldenRun } from '../../helpers/golden-run';
import { compareControls } from '../../helpers/control-refs';
import { analyzeTestGeneratorSpawns, type TgSpawnAnalysis } from '../../helpers/test-generator-spawns';
import { missingFileOffense, routableFixmeOffense } from './rules';

const SLOTS_ROOT = path.resolve(__dirname, '..', '..', 'fixtures', 'golden-runs');
const REQUIRE = /^(1|true|yes)$/i.test(process.env.REQUIRE_BUILD_TESTS_TOGETHER ?? '');

interface Slot {
  present: boolean;
  reason: string;
  root: string | null;
  docsDir: string | null;
  transcript: string | null;
  cleanup: () => void;
}

/** A golden-run slot plus its sidecar transcript.jsonl (which never lives inside a git bundle). */
function loadSlot(slot: string): Slot {
  const g = loadGoldenRun(slot);
  const tf = path.join(SLOTS_ROOT, slot, 'transcript.jsonl');
  const transcript = fs.existsSync(tf) ? fs.readFileSync(tf, 'utf8') : null;
  return { present: g.present, reason: g.reason, root: g.root, docsDir: g.docsDir, transcript, cleanup: g.cleanup };
}

const read = (p: string) => fs.readFileSync(p, 'utf8');

interface EpicRec { slug: string; dir: string; phase?: string; stories: string[] }

function epics(docsDir: string): EpicRec[] {
  const root = path.join(docsDir, 'epics');
  if (!fs.existsSync(root)) return [];
  const out: EpicRec[] = [];
  for (const e of fs.readdirSync(root, { withFileTypes: true })) {
    if (!e.isDirectory()) continue;
    const sf = path.join(root, e.name, 'state.json');
    if (!fs.existsSync(sf)) continue;
    try {
      const st = JSON.parse(read(sf)) as { phase?: string; stories?: Record<string, unknown> };
      out.push({ slug: e.name, dir: path.join(root, e.name), phase: st.phase, stories: Object.keys(st.stories ?? {}) });
    } catch {
      /* malformed state.json is caught by recorded-run's schema check; skip for iteration */
    }
  }
  return out;
}

function storyPair(root: string, slug: string, n: string): { vitest: string | null; playwright: string | null; vfile: string | null; sfile: string | null } {
  const vDir = path.join(root, 'web', 'src', '__tests__', 'integration');
  const eDir = path.join(root, 'web', 'e2e');
  const vfile = fs.existsSync(vDir) ? fs.readdirSync(vDir).find((f) => f.startsWith(`epic-${slug}-story-${n}-`) && f.endsWith('.test.tsx')) ?? null : null;
  const sfile = fs.existsSync(eDir) ? fs.readdirSync(eDir).find((f) => f.startsWith(`epic-${slug}-story-${n}-`) && f.endsWith('.spec.ts')) ?? null : null;
  return {
    vitest: vfile ? read(path.join(vDir, vfile)) : null,
    playwright: sfile ? read(path.join(eDir, sfile)) : null,
    vfile,
    sfile,
  };
}

const BUILT = (e: EpicRec) => e.phase !== 'PLAN' && e.phase !== 'READY-TO-BUILD';

// ---------------------------------------------------------------------------
// Slots (loaded once at module scope; cleaned up in afterAll).
// ---------------------------------------------------------------------------

const good = loadSlot('build-tests-together-contact-form');
const cal = loadSlot('build-tests-together-divergent');
afterAll(() => { good.cleanup(); cal.cleanup(); });

if (!good.present) {
  // eslint-disable-next-line no-console -- intentional visible skip notice
  console.warn(`\n[tier-2 build-tests-together] GOOD slot SKIPPED — ${good.reason}\n  (run the Tier-3 capture to produce fixtures/golden-runs/build-tests-together-contact-form/; set REQUIRE_BUILD_TESTS_TOGETHER=1 to make its absence RED)\n`);
}

// ---------------------------------------------------------------------------
// Harness meta-checks — ALWAYS run (never a vacuous green, even with no good slot)
// ---------------------------------------------------------------------------

describe('build-tests-together Tier-2 harness', () => {
  it('PASS: the planted-bad divergent calibration slot is present (keeps the invariants falsifiable)', () => {
    expect(cal.present, cal.reason).toBe(true);
    expect(cal.transcript, 'calibration slot should carry a transcript.jsonl').toBeTruthy();
  });

  // REQUIRE gate: for a release run, a missing/misnamed good slot is RED, not a silent skip.
  (REQUIRE ? it : it.skip)('REQUIRE_BUILD_TESTS_TOGETHER: the good slot is present', () => {
    expect(good.present, good.reason).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// GOOD slot — the real proof. Skips until the live capture produces the docs+web tree.
// ---------------------------------------------------------------------------

describe.skipIf(!good.present)('build-tests-together — recorded invariants (good slot)', () => {
  // NOTE: describe.skipIf still RUNS this factory at collection time — guard every computation against an
  // absent good slot (null root/docsDir) so the file collects cleanly when the slot isn't present yet.
  const root = good.root ?? '';
  const docsDir = good.docsDir ?? '';
  const built = good.present ? epics(docsDir).filter(BUILT) : [];
  const storyCount = built.reduce((n, e) => n + e.stories.length, 0);
  const analysis: TgSpawnAnalysis | null = good.present && good.transcript ? analyzeTestGeneratorSpawns(good.transcript) : null;

  const vitestExpectedFor = (n: string): boolean => {
    if (!analysis) return true; // conservative: a missing file is flagged, never fail-open
    const s = analysis.storySpawns.find((sp) => sp.storyKey === n);
    return s ? /\.test\.tsx/.test(s.returnText) : true;
  };

  it('PASS: the capture is a single built epic with ≥1 story (non-vacuous guard)', () => {
    // Everything below iterates `built`; an empty set would make the offender-checks vacuously green.
    expect(built.length, 'expected exactly one built epic (single-epic capture)').toBe(1);
    expect(storyCount, 'the built epic should have ≥1 story').toBeGreaterThan(0);
  });

  it('T2.1 PASS: one test-generator per story — no split, epic-mocks ≤ 1, count == stories', () => {
    expect(good.transcript, 'good slot must carry a transcript.jsonl').toBeTruthy();
    const a = analysis as TgSpawnAnalysis;
    expect(a.verdict).toBe('one-agent-per-story');
    expect(a.splitSpawns, 'no story may get a separate vitest/playwright agent').toHaveLength(0);
    expect(a.epicMocks.length).toBeLessThanOrEqual(1);
    expect(a.distinctStories.length, 'distinct stories covered == story count (single-epic)').toBe(storyCount);
  });

  it('T2.2 PASS: every shared control has the same role + strategy in both files', () => {
    const offenders: string[] = [];
    let comparedTotal = 0;
    const noOverlap: string[] = [];
    for (const e of built) {
      for (const n of e.stories) {
        const { vitest, playwright } = storyPair(root, e.slug, n);
        if (!vitest || !playwright) continue; // presence is T2.3's job
        const res = compareControls(vitest, playwright);
        comparedTotal += res.comparedCount;
        if (res.status === 'skipped-no-overlap') noOverlap.push(`${e.slug}/${n}`);
        if (res.status === 'mismatch') {
          offenders.push(`${e.slug} story ${n}: ${res.mismatches.map((m) => `${m.nameKey} [${m.vitest} vs ${m.playwright}]`).join('; ')}`);
        }
      }
    }
    // Surface what was (not) compared — disjoint coverage tags make no-overlap legitimate, so this is
    // informational, never a pass/fail signal on its own; the divergent slot proves the check bites.
    // eslint-disable-next-line no-console
    console.warn(`[tier-2 build-tests-together] parity: compared ${comparedTotal} shared control(s); ${noOverlap.length} story(ies) shared no control name${noOverlap.length ? ` (${noOverlap.join(', ')})` : ''}.`);
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('T2.3 PASS: each story has its spec, and its Vitest file unless it had no vitest-tagged AC', () => {
    const offenders: string[] = [];
    for (const e of built) {
      for (const n of e.stories) {
        const { vfile, sfile } = storyPair(root, e.slug, n);
        const off = missingFileOffense(e.slug, n, vfile !== null, sfile !== null, vitestExpectedFor(n));
        if (off) offenders.push(off);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('T2.4 PASS: every spec carries a live test() (or is a declared non-routable stub)', () => {
    const offenders: string[] = [];
    for (const e of built) {
      for (const n of e.stories) {
        const { playwright, sfile } = storyPair(root, e.slug, n);
        if (!playwright) continue; // missing spec is T2.3's job
        if (routableFixmeOffense(playwright)) offenders.push(`${e.slug} story ${n}: ${sfile} has no live test() and is not a declared non-routable stub`);
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// DIVERGENT calibration slot — present now; proves the parity invariant has teeth.
// ---------------------------------------------------------------------------

describe.skipIf(!cal.present)('build-tests-together — planted-bad calibration (divergent slot)', () => {
  const root = cal.root as string;
  const docsDir = cal.docsDir as string;

  it('CALIBRATION: the transcript is still a clean one-agent-per-story run (T2.1 would pass)', () => {
    const a = analyzeTestGeneratorSpawns(cal.transcript as string);
    expect(a.verdict).toBe('one-agent-per-story');
    expect(a.splitSpawns).toHaveLength(0);
  });

  it('CALIBRATION: T2.2 goes RED — Story 2 controls diverge (radiogroup vs combobox for "Status")', () => {
    const mismatchedStories: string[] = [];
    for (const e of epics(docsDir).filter(BUILT)) {
      for (const n of e.stories) {
        const { vitest, playwright } = storyPair(root, e.slug, n);
        if (!vitest || !playwright) continue;
        if (compareControls(vitest, playwright).status === 'mismatch') mismatchedStories.push(`${e.slug}/${n}`);
      }
    }
    expect(mismatchedStories).toContain('task-board/2');
    expect(mismatchedStories).not.toContain('task-board/1');
  });
});
