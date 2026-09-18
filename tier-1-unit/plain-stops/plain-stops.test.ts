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
import { TARGET_ROOT, TEMPLATE_DIR, TEMPLATE_PRESENT, NO_TEMPLATE_REASON } from '../../helpers';
import {
  extractStops,
  findBadPhrasesInStops,
  findSlugInStops,
  findForbiddenDocVocab,
  extractMarkdownLinks,
  isResolvableLinkTarget,
  hasTickPersistence,
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
});

// ---------------------------------------------------------------------------
// Fail-closed: template must be present when explicitly expected (CI opt-in)
// ---------------------------------------------------------------------------

it('the template under test is present when EXPECT_TEMPLATE is set', () => {
  if (process.env.EXPECT_TEMPLATE) expect(TEMPLATE_PRESENT).toBe(true);
});

// ---------------------------------------------------------------------------
// 2. Regression over the real template
// ---------------------------------------------------------------------------

const read = (p: string) => fs.readFileSync(p, 'utf8');
const CONTINUE = path.join(TEMPLATE_DIR, 'commands', 'continue.md');
const WORKFLOWS = path.join(TEMPLATE_DIR, 'WORKFLOWS.md');
const CLAUDE_USER = path.join(TARGET_ROOT, 'CLAUDE.user.md');
const HELP_DIR = path.join(TARGET_ROOT, '.template-docs', 'users', 'Help');
const PEER_CMDS = ['start', 'plan', 'migrate-legacy']
  .map((c) => path.join(TEMPLATE_DIR, 'commands', `${c}.md`))
  .filter((p) => fs.existsSync(p));

function userDocs(): string[] {
  const docs = [WORKFLOWS, CLAUDE_USER];
  if (fs.existsSync(HELP_DIR)) docs.push(...fs.readdirSync(HELP_DIR).filter((f) => f.endsWith('.md')).map((f) => path.join(HELP_DIR, f)));
  return docs.filter((p) => fs.existsSync(p));
}

describe.skipIf(!TEMPLATE_PRESENT)('regression — stops in continue.md', () => {
  it('fail-closed: the extractor finds stops that actually yield user-facing strings', () => {
    const stops = extractStops(read(CONTINUE));
    expect(stops.length).toBeGreaterThanOrEqual(5);
    expect(stops.filter((s) => s.strings.length > 0).length).toBeGreaterThanOrEqual(5);
  });

  // RED-PENDING until the rework removes the developer-facing options.
  it('[red-pending] no developer-facing phrasing in any stop', () => {
    const bad = findBadPhrasesInStops(read(CONTINUE));
    expect(bad, bad.map((o) => `L${o.line}: "${o.string}"`).join('\n')).toEqual([]);
  });

  it('no slug placeholder leaks into a stop question', () => {
    expect(findSlugInStops(read(CONTINUE))).toEqual([]);
  });

  it('tick-persistence rule survives (must-survive)', () => {
    expect(hasTickPersistence(read(CONTINUE))).toBe(true);
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
  // RED-PENDING: WORKFLOWS.md still has a "Halt Conditions" section + "Tier 4".
  it('[red-pending] WORKFLOWS.md has no halt/Tier 4/verbatim vocabulary', () => {
    const hits = findForbiddenDocVocab(read(WORKFLOWS));
    expect(hits, hits.map((h) => `L${h.line}: ${h.term}`).join('\n')).toEqual([]);
  });

  // RED-PENDING must-show: the stale "unexpected stop" entry must be rewritten (old framing gone).
  it('[red-pending] the stale "BUILD halted" help entry is rewritten', () => {
    expect(read(WORKFLOWS)).not.toMatch(/BUILD halted on something I didn'?t expect/i);
  });

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

if (!TEMPLATE_PRESENT) {
  // eslint-disable-next-line no-console
  console.warn('[plain-stops] ' + NO_TEMPLATE_REASON);
}
