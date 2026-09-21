/**
 * Plain-language stops (Tier 1, static). Rework every user-facing STOP so the question is
 * plain; self-repair silently; drop old "halt"/"Tier 4" vocab from user docs.
 *
 * Layers:
 *   1. Detector unit tests — inline fixtures, the real contract, ALWAYS run.
 *   2. Regression over the real template. Several assertions are RED-PENDING by design (they
 *      pin the target until the rework lands). Fail-closed guards prevent a broken extractor
 *      or a wrong REPO_ROOT from turning those tripwires vacuously green.
 *
 * The greps are RED TRIPWIRES (necessary, not sufficient): a green does NOT certify plainness.
 * The behavioural proof (AC1 self-repair; AC2 give-up flow) and the ~357 endpoint menu's prose
 * jargon are live/judge — see the plan's Tier 3 (blocked on new infra + the marker convention).
 *
 * Point at a STABLE checkout:
 *   REPO_ROOT="C:\TestsArchives\stadium8-tests\18-09-2026" EXPECT_TEMPLATE=1 npm run test:tier1
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { TARGET_ROOT, TEMPLATE_DIR, TEMPLATE_PRESENT, TEMPLATE_REF, NO_TEMPLATE_REASON } from '../../helpers';
import {
  extractStops,
  findBadPhrasesInStops,
  isCiFailureStop,
  findSlugInStops,
  findForbiddenDocVocab,
  extractMarkdownLinks,
  isResolvableLinkTarget,
  hasTickPersistence,
  hasProgressMarkerConvention,
  giveUpMessageIssues,
} from './stops';

// ---------------------------------------------------------------------------
// 1. Detector unit tests (always run)
// ---------------------------------------------------------------------------

const SAMPLE_STOP = [
  'When it applies, ask with `AskUserQuestion`:',
  '',
  '- **Header:** "Mid-build"',
  '- **Question:** "**[Epic name]** is part-way through being built. Continue anyway?"',
  '- **Options:**',
  '  - **"Continue"** — shown as *"Pick up building it here."*',
  '  - **"Diagnose locally"** — drop into the failing test output',
  '',
  '**Next paragraph ends the block.**',
].join('\n');

describe('extractStops', () => {
  it('captures the question and option labels, drops structural labels and following prose', () => {
    const s = extractStops(SAMPLE_STOP);
    expect(s).toHaveLength(1);
    expect(s[0].strings).toEqual(expect.arrayContaining(['Continue', 'Diagnose locally', 'Pick up building it here.']));
    expect(s[0].strings.join(' ')).not.toMatch(/Next paragraph/);
  });

  it('ignores a bare prose mention of AskUserQuestion (no phantom stop)', () => {
    expect(extractStops('Present approvals via `AskUserQuestion`.')).toEqual([]);
  });

  it('an inline stop does not swallow the instruction steps below it', () => {
    const inline = [
      '1. `AskUserQuestion` (free-text via "Other"): *"What is the issue?"*',
      '2. **Classify the report** — do X',
      '   - **A failed item** is a data-contract failure',
    ].join('\n');
    const strings = extractStops(inline)[0].strings;
    expect(strings).toEqual(expect.arrayContaining(['What is the issue?', 'Other']));
    expect(strings.join(' ')).not.toMatch(/Classify the report|A failed item/);
  });
});

describe('findBadPhrasesInStops', () => {
  it('FLAGS a developer-facing option label', () => {
    expect(findBadPhrasesInStops(SAMPLE_STOP).map((o) => o.string)).toContain('Diagnose locally');
  });
  it('FLAGS a lowercase "halt" in a stop', () => {
    expect(findBadPhrasesInStops('`AskUserQuestion`:\n- **Question:** "The build will halt — continue?"\n').length).toBeGreaterThan(0);
  });
  it('CLEAN when options are plain', () => {
    expect(findBadPhrasesInStops('`AskUserQuestion`:\n- **"Try again"** — re-run\n- **"Stop for now"** — pause\n')).toEqual([]);
  });
});

// The CI-failure stop is an accepted, scoped exception (ruled intended by the AC owner,
// 2026-09-21): "Diagnose locally" / "Force merge anyway" are allowed THERE only. The exemption
// must be scoped to (that stop) × (those two phrases) and identified by an independent anchor.
describe('CI-failure stop exception (accepted, scoped)', () => {
  const ciStop = [
    '- **Any check fails** → surface to user with `AskUserQuestion`:',
    '  - "Re-run the failing checks" — `gh pr rerun` for the failed runs',
    '  - "Diagnose locally" — drop into the failing test output',
    '  - "Force merge anyway" — proceed with a warning',
  ].join('\n');

  it('identifies the CI stop by its independent anchor, not by the exempted phrases', () => {
    expect(isCiFailureStop(extractStops(ciStop)[0])).toBe(true);
    // SAMPLE_STOP carries "Diagnose locally" but is NOT the CI stop (no gh pr / re-run anchor).
    expect(isCiFailureStop(extractStops(SAMPLE_STOP)[0])).toBe(false);
  });

  it('exempts the two phrases AT the CI stop (clean)', () => {
    expect(findBadPhrasesInStops(ciStop)).toEqual([]);
  });

  it('still flags the two phrases at a NON-CI stop (exemption is scoped to the CI stop)', () => {
    expect(findBadPhrasesInStops(SAMPLE_STOP).map((o) => o.string)).toContain('Diagnose locally');
  });

  it('still flags OTHER developer phrasing at the CI stop (exemption is scoped to the two phrases)', () => {
    const ciPlusOther = ciStop + '\n  - "Walk me through the issue" — hand it to a developer';
    expect(findBadPhrasesInStops(ciPlusOther).map((o) => o.string)).toContain('Walk me through the issue');
  });
});

describe('findSlugInStops', () => {
  it('FLAGS a slug placeholder in a question', () => {
    expect(findSlugInStops('`AskUserQuestion`:\n- **Question:** "Resume epic/<slug> now?"\n').length).toBeGreaterThan(0);
  });
  it('CLEAN when the plain name is used', () => {
    expect(findSlugInStops(SAMPLE_STOP)).toEqual([]);
  });
});

describe('findForbiddenDocVocab', () => {
  it('FLAGS halt and tier 4 (incl. "tier four" and double-space)', () => {
    expect(findForbiddenDocVocab('halt on a Tier 4 call').length).toBeGreaterThanOrEqual(2);
    expect(findForbiddenDocVocab('a Tier four decision').length).toBeGreaterThan(0);
    expect(findForbiddenDocVocab('a Tier  4 decision').length).toBeGreaterThan(0);
  });
  it('does NOT flag Tier 1/2/3', () => {
    expect(findForbiddenDocVocab('Tier 1 auto-merge, Tier 2 handled, Tier 3 recorded.')).toEqual([]);
  });
  it('carves out "verbatim log" and "verbatim logs"', () => {
    expect(findForbiddenDocVocab('the verbatim log of every decision')).toEqual([]);
    expect(findForbiddenDocVocab('the verbatim logs of decisions')).toEqual([]);
  });
  it('FLAGS the developer-message sense of verbatim', () => {
    expect(findForbiddenDocVocab('the agent block is shown verbatim').length).toBeGreaterThan(0);
  });
  it('ignores code identifiers and language-tagged fences, but scans untagged output fences', () => {
    expect(findForbiddenDocVocab('Set `state.json.halt` to persist.')).toEqual([]);
    expect(findForbiddenDocVocab('```bash\nhalt\n```')).toEqual([]);
    expect(findForbiddenDocVocab('```\nthe build will halt\n```').length).toBeGreaterThan(0);
  });
});

describe('links + tick-persistence', () => {
  it('filters resolvable link targets (skips schemes, anchors, placeholders, generated)', () => {
    const links = extractMarkdownLinks('[a](../x.md) [b](https://y) [c](#h) [d](generated-docs/z.md) [e](ftp://f) [g](./real.md#generated-docs/frag)');
    const resolvable = links.filter((l) => isResolvableLinkTarget(l.target)).map((l) => l.target);
    expect(resolvable).toEqual(['../x.md', './real.md#generated-docs/frag']);
  });
  it('hasTickPersistence detects the carry-forward rule', () => {
    expect(hasTickPersistence('…uncheck only the tests the fix affected…')).toBe(true);
    expect(hasTickPersistence('everything resets each time')).toBe(false);
  });
  it('hasProgressMarkerConvention detects the "N of M" marker anchored to its rule', () => {
    expect(hasProgressMarkerConvention('a count of finished work is fine ("Story 3 of 6 built")')).toBe(true);
    expect(hasProgressMarkerConvention('narrate every internal step as it happens')).toBe(false);
    // semantic-flip / stray example must NOT keep it green — the guidance sentence must be present.
    expect(hasProgressMarkerConvention('for example, "Story 3 of 6 built", but never show a running count')).toBe(false);
  });

  it('giveUpMessageIssues flags developer phrasing / slug in a give-up message', () => {
    expect(giveUpMessageIssues('Sign in couldn\'t be finished after a few tries — keep trying, or move on?')).toEqual([]);
    expect(giveUpMessageIssues('HALT: 3 manual-test fix cycles on story-2-<slug>').length).toBeGreaterThanOrEqual(2);
  });
});

// ---------------------------------------------------------------------------
// Fail-closed: template must be present when explicitly expected (CI opt-in)
// ---------------------------------------------------------------------------

it('the template under test is present (and the right one) when EXPECT_TEMPLATE is set', () => {
  if (!process.env.EXPECT_TEMPLATE) return;
  expect(TEMPLATE_PRESENT).toBe(true);
  // Identity check: if EXPECT_TEMPLATE_REF is set, a stale/wrong checkout goes red, not green.
  if (process.env.EXPECT_TEMPLATE_REF) expect(TEMPLATE_REF).toBe(process.env.EXPECT_TEMPLATE_REF);
});

// ---------------------------------------------------------------------------
// 2. Regression over the real template
// ---------------------------------------------------------------------------

const read = (p: string) => fs.readFileSync(p, 'utf8');
const CONTINUE = path.join(TEMPLATE_DIR, 'commands', 'continue.md');
const ORCH_RULES = path.join(TEMPLATE_DIR, 'shared', 'orchestrator-rules.md');
const CLAUDE_USER = path.join(TARGET_ROOT, 'CLAUDE.user.md');
const HELP_DIR = path.join(TARGET_ROOT, '.template-docs', 'users', 'Help');
const PEER_CMDS = ['start', 'plan', 'migrate-legacy']
  .map((c) => path.join(TEMPLATE_DIR, 'commands', `${c}.md`))
  .filter((p) => fs.existsSync(p));

// AC3 SCOPE (amended 2026-09-21, ruled by the AC owner/engineer): `.claude/WORKFLOWS.md` is an
// INTERNAL developer/maintainer reference, not text the end-user reads — so it is OUT OF SCOPE for
// AC3's "no old vocabulary" check. AC3 covers the genuinely user-facing docs below.
function userDocs(): string[] {
  const docs = [CLAUDE_USER];
  if (fs.existsSync(HELP_DIR)) docs.push(...fs.readdirSync(HELP_DIR).filter((f) => f.endsWith('.md')).map((f) => path.join(HELP_DIR, f)));
  return docs.filter((p) => fs.existsSync(p));
}

describe.skipIf(!TEMPLATE_PRESENT)('regression — stops in continue.md', () => {
  it('fail-closed: the extractor finds stops that actually yield user-facing strings', () => {
    const stops = extractStops(read(CONTINUE));
    expect(stops.length).toBeGreaterThanOrEqual(5);
    expect(stops.filter((s) => s.strings.length > 0).length).toBeGreaterThanOrEqual(5);
  });

  // The CI-failure stop is an accepted, scoped exception (AC2 amended — ruled intended by the AC
  // owner, 2026-09-21). Every OTHER stop must still be free of developer-facing phrasing.
  it('no developer-facing phrasing in any stop (CI-failure stop excepted)', () => {
    const bad = findBadPhrasesInStops(read(CONTINUE));
    expect(bad, bad.map((o) => `L${o.line}: "${o.string}"`).join('\n')).toEqual([]);
  });

  // Fail-closed positive: the exception must correspond to a REAL, present CI stop that still
  // carries both exempted phrases — otherwise the check above would pass vacuously.
  it('the CI-failure stop exists and still carries the two exempted phrases', () => {
    const ciStops = extractStops(read(CONTINUE)).filter(isCiFailureStop);
    expect(ciStops.length, 'exactly one CI-failure stop').toBe(1);
    const joined = ciStops[0].strings.join(' | ');
    expect(joined).toMatch(/diagnose locally/i);
    expect(joined).toMatch(/force merge anyway/i);
  });

  it('no slug placeholder leaks into a stop question', () => {
    expect(findSlugInStops(read(CONTINUE))).toEqual([]);
  });

  it('tick-persistence rule survives (must-survive)', () => {
    expect(hasTickPersistence(read(CONTINUE))).toBe(true);
  });

  it('the "N of M" progress-marker convention survives (must-survive)', () => {
    expect(hasProgressMarkerConvention(read(ORCH_RULES))).toBe(true);
  });
});

describe.skipIf(!TEMPLATE_PRESENT)('regression — stops in peer commands', () => {
  // May be red-pending if the rework hasn't reached start.md / plan.md / migrate-legacy.md.
  it.each(PEER_CMDS)('%s stops carry no developer-facing phrasing', (p) => {
    const bad = findBadPhrasesInStops(read(p));
    expect(bad, bad.map((o) => `L${o.line}: "${o.string}"`).join('\n')).toEqual([]);
  });
});

describe.skipIf(!TEMPLATE_PRESENT)('regression — user-facing docs (AC3)', () => {
  // NOTE: `.claude/WORKFLOWS.md` is intentionally NOT scanned here — it was ruled an internal
  // developer reference (see AC3 SCOPE note above), so its "halt"/"Tier 4" wording is out of
  // AC3's scope. Residual gap: there is no user-facing "unexpected stop" help entry in Help/* to
  // rewrite; if one is wanted, that's a separate must-show (Tier-3 / manual), recorded in the plan.

  it('CLAUDE.user.md exists and is clean of the old vocabulary', () => {
    expect(fs.existsSync(CLAUDE_USER)).toBe(true);
    expect(findForbiddenDocVocab(read(CLAUDE_USER))).toEqual([]);
  });

  const helpFiles = fs.existsSync(HELP_DIR) ? fs.readdirSync(HELP_DIR).filter((f) => f.endsWith('.md')) : [];
  it('the Help docs exist', () => {
    expect(helpFiles.length).toBeGreaterThan(0);
  });
  it.each(helpFiles)('Help/%s is clean of the old vocabulary', (f) => {
    expect(findForbiddenDocVocab(read(path.join(HELP_DIR, f)))).toEqual([]);
  });

  it('every resolvable link in the user docs points at a file that exists', () => {
    const broken: string[] = [];
    let resolved = 0;
    for (const doc of userDocs()) {
      const dir = path.dirname(doc);
      for (const link of extractMarkdownLinks(read(doc))) {
        if (!isResolvableLinkTarget(link.target)) continue;
        const filePart = link.target.split('#')[0];
        if (!filePart) continue;
        if (fs.existsSync(path.resolve(dir, filePart))) resolved++;
        else broken.push(`${path.relative(TARGET_ROOT, doc)}:${link.line} → ${link.target}`);
      }
    }
    expect(resolved, 'fail-closed: no links were actually resolved').toBeGreaterThan(0);
    expect(broken, broken.join('\n')).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// Tier 3 — behavioural (PENDING). Registered as todos so they are tracked in the suite.
// Blocked on: a live-run harness (drive /continue, delete files mid-run, force repeated
// failures, answer prompts turn-by-turn) AND the message-tagging (audience/role) that lets a
// test tell the user's messages from internal chatter. These cannot be honestly built until
// that infra lands — see plain-language-stops-test-plan.md, Tier 3.
// ---------------------------------------------------------------------------

describe('Tier 3 — behavioural (pending live-run harness + message-tagging)', () => {
  it.todo('AC1 self-repair: delete brief + next story → /continue restores them silently (no question, no technical output), next message is the "Story N of M built" hand-back, tree clean, only normal story commits');
  it.todo('AC1 positive surface: a genuine user-environment failure surfaces as exactly ONE plain line');
  it.todo('AC1 boundary: deleting state.json surfaces the plain "run /start" line, not a technical error');
  // The give-up message's PLAINNESS half is now testable now (giveUpMessageIssues, tested above);
  // only the live parts remain — the actual message from a real run, its option count, and that
  // it names the story in plan words.
  it.todo('AC2 give-up (live): the real give-up message names the story in the user\'s plan words, re-evaluates, and offers >=2 non-developer options');
  it.todo('AC2 keep-trying: choosing "keep trying" runs one more round; check-off page returns with only the affected test unticked, previously-passed still ticked');
  it.todo('AC2 other-option: reporting again and choosing a different option continues as expected');
});

// Two open items are DECISIONS, not deferred tests, so they live in the plan/tracker, not here
// (a `.todo` implies a test will be written; these aren't tests until the decision is made):
//   - whether a user-facing "unexpected stop" help entry should exist (none does today), and
//   - whether start.md is user-facing (→ a prose vocab check) or internal like WORKFLOWS.md.
// See plain-language-stops-test-plan.md § Implementation status.

if (!TEMPLATE_PRESENT) {
  // eslint-disable-next-line no-console
  console.warn('[plain-stops] ' + NO_TEMPLATE_REASON);
}
