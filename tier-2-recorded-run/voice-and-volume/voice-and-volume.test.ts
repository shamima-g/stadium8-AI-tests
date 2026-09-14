/**
 * S8-134-145 — "Voice and volume" output discipline (Tier 2, invariants over a run).
 *
 * Scope: the three governed commands — /start, /continue, /plan.
 *
 * Layers:
 *   1. Invariant tests — inline good/bad fixtures; the real contract, always run. Every
 *      invariant is TWO-SIDED (a clean case PASSES, a planted violation FAILS).
 *   2. Source-derived lists — forbidden agent/phase names come from the template.
 *   3. Capture regression — runs the invariants over a REAL captured transcript once one
 *      exists at fixtures/golden-run/voice-and-volume/*.json. Skips visibly until then; a
 *      fail-closed check rejects an empty extraction as a vacuous green.
 *
 * The capture layer waits on the marker convention (which must tag each message's
 * `audience` AND, for the approval checks, a `role`) + a captured run — see the plan.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { TEMPLATE_DIR, TEMPLATE_PRESENT } from '../../helpers';
import { agentNamesFromFilenames, extractEpicPhases } from '../../tier-1-unit/voice-and-volume/rules';
import {
  findLeaks,
  findNarration,
  startsWithPreamble,
  isProgressMarker,
  checkHandBack,
  hasNextAction,
  messageKind,
  nonConformingMessages,
  carriesWorkflowOnlyMarker,
  findRawReturnFields,
  flaggedAssumptionReworded,
  showsCoverageLine,
  showsManualTestChecklist,
  approvalsWithoutHeadline,
  approvalRolesMissing,
  chatRepeatsPage,
  extractionIsEmpty,
  userMessages,
  type ForbiddenLists,
  type Transcript,
} from './invariants';

const LISTS: ForbiddenLists = {
  agentNames: ['developer', 'test-generator', 'feature-planner', 'playwright-runner'],
  phaseNames: ['PLAN', 'BUILD', 'EPIC-END', 'MANUAL-TEST', 'COMPLETE', 'READY-TO-BUILD', 'COMPLETE-ON-BRANCH'],
};

// ---------------------------------------------------------------------------
// Fail-closed extractor (the anti-vacuous guard)
// ---------------------------------------------------------------------------

describe('extractionIsEmpty (fail-closed)', () => {
  it('TRUE: a non-empty run with no user-facing message', () => {
    expect(extractionIsEmpty({ messages: [{ audience: 'internal', text: 'x' }] })).toBe(true);
  });
  it('FALSE: a run with a user-facing message', () => {
    expect(extractionIsEmpty({ messages: [{ audience: 'user', text: 'Done.' }] })).toBe(false);
  });
  it('FALSE: an empty run (nothing to be vacuous about)', () => {
    expect(extractionIsEmpty({ messages: [] })).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// AC2 — no internal mechanism leaks
// ---------------------------------------------------------------------------

describe('AC2 — no internal mechanism leaks', () => {
  it('PASS: a clean result message has no leaks', () => {
    expect(findLeaks('Sign in and the dashboard are done. Build the next with /start.', LISTS)).toEqual([]);
  });

  it('FAIL: agent name, phase, path, branch, and script all flagged', () => {
    const bad =
      'test-generator finished. Phase BUILD on epic/auth-shell; wrote generated-docs/epics/x/state.json ' +
      'via collect-dashboard-data.js.';
    const kinds = findLeaks(bad, LISTS).map((l) => l.kind);
    expect(kinds).toEqual(expect.arrayContaining(['agent-name', 'phase-name', 'branch', 'path', 'script']));
  });

  it('PASS (carve-out): a command the user must run is allowed in a fenced block', () => {
    const ok = 'Not running? Start it with:\n\n```bash\nnpm --prefix web run dev\n```';
    expect(findLeaks(ok, LISTS)).toEqual([]);
  });

  it('FAIL (regression): a leak sharing a command-prefixed line is still caught', () => {
    // stripCarveOuts must not drop the whole line — the path/state.json here must be seen.
    const bad = 'cd generated-docs/epics/auth && cat state.json';
    expect(findLeaks(bad, LISTS).map((l) => l.kind)).toEqual(expect.arrayContaining(['path']));
  });

  it('does NOT match BUILD inside READY-TO-BUILD', () => {
    const leaks = findLeaks('Two epics are READY-TO-BUILD next.', LISTS).filter((l) => l.kind === 'phase-name');
    // READY-TO-BUILD itself is a phase name (correctly flagged); the point is BUILD alone is not double-counted.
    expect(leaks.map((l) => l.token)).toEqual(['READY-TO-BUILD']);
  });

  it('does NOT match COMPLETE inside COMPLETE-ON-BRANCH', () => {
    const leaks = findLeaks('It reached COMPLETE-ON-BRANCH.', LISTS).filter((l) => l.kind === 'phase-name');
    expect(leaks.map((l) => l.token)).toEqual(['COMPLETE-ON-BRANCH']);
  });

  it('catches a Title-case hyphenated phase leak (EPIC-End)', () => {
    expect(findLeaks('Moving to Epic-End now.', LISTS).some((l) => l.kind === 'phase-name')).toBe(true);
  });

  it('does NOT flag ordinary tech names (Node.js, Chart.js)', () => {
    expect(findLeaks('The charts use Node.js and Chart.js.', LISTS)).toEqual([]);
  });

  it('does NOT flag bare "developer" (ambiguous — left to the judge)', () => {
    expect(findLeaks('A developer can pick this up later.', LISTS)).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// AC1 — every message is a decision, result, or progress marker
// ---------------------------------------------------------------------------

describe('AC1 — message kinds', () => {
  it('classifies the three allowed kinds', () => {
    expect(messageKind('Approve these stories?')).toBe('decision');
    expect(messageKind('Dashboard is done and merged.')).toBe('result');
    expect(messageKind('Story 3 of 6 built')).toBe('progress');
  });

  it('FAIL: narration/chit-chat is "other"', () => {
    expect(messageKind('Generating tests… Running quality gates…')).toBe('other');
    expect(messageKind('Thanks so much for your patience here!')).toBe('other');
  });

  it('nonConformingMessages returns only the user "other" messages', () => {
    const t: Transcript = {
      messages: [
        { audience: 'user', text: 'Dashboard is done.' },
        { audience: 'internal', text: 'whatever internal note' },
        { audience: 'user', text: 'Just bear with me a moment while things whir.' },
      ],
    };
    expect(nonConformingMessages(t).map((m) => m.text)).toEqual(['Just bear with me a moment while things whir.']);
  });
});

describe('AC1/AC6 — no in-flight step narration', () => {
  it('PASS: one line per finished piece of work', () => {
    expect(findNarration('Story 3 of 6 built.')).toHaveLength(0);
  });
  it('FAIL: narration of internal steps is flagged', () => {
    expect(findNarration('Generating tests… Running quality gates… Committing…').length).toBeGreaterThanOrEqual(2);
  });
});

describe('AC6 — progress is an at-a-glance marker', () => {
  it('PASS: "Story 3 of 6 built" is a marker', () => {
    expect(isProgressMarker('Story 3 of 6 built')).toBe(true);
  });
  it('FAIL: a count buried in a sentence is not a marker', () => {
    expect(isProgressMarker("We're now 3 of 6 through the build and wiring up the checks and tests.")).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// AC5 — the first line carries the point
// ---------------------------------------------------------------------------

describe('AC5 — first line carries the point', () => {
  it('PASS: leads with the outcome', () => {
    expect(startsWithPreamble('Dashboard is done and merged.')).toBe(false);
  });
  it('FAIL: opens with a preamble/recap', () => {
    expect(startsWithPreamble('Okay, so now that the tests have all run, the dashboard is done.')).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// AC4 — hand-back shape (outcome + next action, nothing after)
// ---------------------------------------------------------------------------

describe('AC4 — hand-back shape', () => {
  it('PASS: short, points-first, has a next action, no narration', () => {
    expect(checkHandBack('Dashboard Overview is done and merged.\nBuild the next epic with /start.').ok).toBe(true);
  });

  it('FAIL (length only): too long even when clean and actionable', () => {
    const hb = 'Story one done.\nStory two done.\nStory three done.\nStory four done.\nBuild the next with /start.';
    expect(checkHandBack(hb).reasons).toContain('too long (5 lines)');
  });

  it('FAIL (no next action): an outcome with nowhere to go', () => {
    expect(checkHandBack('Sign in is finished.').reasons).toContain('no next action');
  });

  it('FAIL (bundled): long + narrated + preamble', () => {
    const hb =
      'Okay, so here is what happened.\nGenerating tests… Running quality gates… Committing…\n' +
      'We did story one.\nThen story two.\nThen story three.\nAnd now it is merged. Build next with /start.';
    expect(checkHandBack(hb).reasons.length).toBeGreaterThanOrEqual(2);
  });

  it('hasNextAction detects slash commands and imperatives', () => {
    expect(hasNextAction('Build the next with /start.')).toBe(true);
    expect(hasNextAction('It is finished.')).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// AC3 — inter-agent reports (accepted labelled exception)
// ---------------------------------------------------------------------------

describe('AC3 — agent return handling', () => {
  it('PASS: the developer block carries the "(For the workflow only)" marker', () => {
    expect(carriesWorkflowOnlyMarker('DEVELOPER COMPLETE\n(For the workflow only)\nstory: x')).toBe(true);
  });
  it('FAIL: a developer block without the marker', () => {
    expect(carriesWorkflowOnlyMarker('DEVELOPER COMPLETE\nstory: x')).toBe(false);
  });

  it('FAIL: a raw return block (other agents must not surface these) is caught', () => {
    const raw = 'tier2JournalEntries: ["added sort"]\nunverifiedAssumptions: ["newest-first"]';
    expect(findRawReturnFields(raw).length).toBeGreaterThanOrEqual(2);
  });
  it('PASS: a clean result has no raw return fields', () => {
    expect(findRawReturnFields('Sign in is done and merged.')).toHaveLength(0);
  });

  it('PASS: a flagged assumption is reworded (not a raw field)', () => {
    expect(flaggedAssumptionReworded('Before you sign off: we assumed orders sort newest-first — worth a check.')).toBe(true);
  });
  it('FAIL: the raw unverifiedAssumptions field is not "reworded"', () => {
    expect(flaggedAssumptionReworded('unverifiedAssumptions: ["orders newest-first"]')).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// AC1 must-show — the user is shown what they need
// ---------------------------------------------------------------------------

describe('AC1 must-show — required content is present', () => {
  const withText = (text: string): Transcript => ({ messages: [{ audience: 'user', text }] });

  it('PASS/FAIL: the INTAKE coverage line', () => {
    expect(showsCoverageLine(withText('Everything you asked for is covered.'))).toBe(true);
    expect(showsCoverageLine(withText('Starting on the first epic.'))).toBe(false);
  });

  it('PASS/FAIL: the manual-test "check these first" list', () => {
    expect(showsManualTestChecklist(withText('Check these first: sign-in and reset.'))).toBe(true);
    expect(showsManualTestChecklist(withText('All done.'))).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// AC8 — never approve something not shown
// ---------------------------------------------------------------------------

describe('AC8 — approvals are introduced first', () => {
  it('PASS: an approval preceded by a headline', () => {
    const t: Transcript = {
      messages: [
        { audience: 'user', role: 'headline', text: 'Six stories for Sign in — review on the page.' },
        { audience: 'internal', text: 'feature-planner returned…' },
        { audience: 'user', role: 'approval', text: 'Approve these stories?' },
      ],
    };
    expect(approvalsWithoutHeadline(t)).toEqual([]);
  });

  it('FAIL: an approval fired with no prior headline', () => {
    const t: Transcript = {
      messages: [
        { audience: 'internal', text: 'feature-planner returned…' },
        { audience: 'user', role: 'approval', text: 'Approve these stories?' },
      ],
    };
    expect(approvalsWithoutHeadline(t)).toEqual([1]);
  });

  it('FAIL-CLOSED: an approval-looking message with no role tag (convention unwired)', () => {
    const t: Transcript = { messages: [{ audience: 'user', text: 'Approve these stories?' }] };
    expect(approvalRolesMissing(t)).toBe(true);
  });
  it('PASS: role-tagged approvals do not trip the guard', () => {
    const t: Transcript = { messages: [{ audience: 'user', role: 'approval', text: 'Approve these stories?' }] };
    expect(approvalRolesMissing(t)).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// AC7 — chat points to the page, does not repeat it
// ---------------------------------------------------------------------------

describe('AC7 — chat points, does not repeat', () => {
  const page =
    'Story 1: sign in with email and password. Story 2: reset a forgotten password via email link. ' +
    'Story 3: stay signed in across sessions with a remember-me option on the login form.';

  it('PASS: a headline that points, not repeats (even when long)', () => {
    expect(chatRepeatsPage('Six stories cover sign in, password reset, and staying logged in — full detail is on the review page for you.', page)).toBe(false);
  });

  it('FAIL: a headline that reproduces a run of the page content', () => {
    expect(chatRepeatsPage('Story 2: reset a forgotten password via email link. Story 3: stay signed in across sessions with a remember-me option', page)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// 2. Source-derived forbidden lists (skip visibly when no template)
// ---------------------------------------------------------------------------

function templateLists(): ForbiddenLists {
  return {
    agentNames: agentNamesFromFilenames(fs.readdirSync(path.join(TEMPLATE_DIR, 'agents'))),
    phaseNames: extractEpicPhases(fs.readFileSync(path.join(TEMPLATE_DIR, 'scripts', 'lib', 'epic-state.js'), 'utf8')),
  };
}

describe.skipIf(!TEMPLATE_PRESENT)('forbidden lists derive from the template', () => {
  it('a template-derived leak scan flags a real agent + phase name', () => {
    const lists = templateLists();
    expect(lists.agentNames).toEqual(expect.arrayContaining(['test-generator', 'feature-planner']));
    expect(lists.phaseNames).toEqual(expect.arrayContaining(['BUILD', 'EPIC-END']));
    const leaks = findLeaks('test-generator finished; phase EPIC-END.', lists);
    expect(leaks.map((l) => l.kind)).toEqual(expect.arrayContaining(['agent-name', 'phase-name']));
  });
});

// ---------------------------------------------------------------------------
// 3. Capture regression — runs over a real transcript once one exists
// ---------------------------------------------------------------------------

const CAPTURE_DIR = path.join(__dirname, '..', '..', 'fixtures', 'golden-run', 'voice-and-volume');
const captures = fs.existsSync(CAPTURE_DIR) ? fs.readdirSync(CAPTURE_DIR).filter((f) => f.endsWith('.json')) : [];

describe.skipIf(captures.length === 0)('captured runs obey the invariants', () => {
  const lists = TEMPLATE_PRESENT ? templateLists() : LISTS;

  it.each(captures)('%s — user-facing messages are clean and conform', (file) => {
    const t = JSON.parse(fs.readFileSync(path.join(CAPTURE_DIR, file), 'utf8')) as Transcript;
    // Fail-closed: an empty extraction from a non-empty run is a vacuous green.
    expect(extractionIsEmpty(t), 'extractor found no user-facing text in a non-empty run').toBe(false);
    expect(approvalRolesMissing(t), 'approvals present but no role tags — marker convention unwired').toBe(false);

    const offenders: string[] = [];
    for (const m of userMessages(t)) {
      const leaks = findLeaks(m.text, lists);
      if (leaks.length) offenders.push(`leak: ${leaks.map((l) => l.token).join(', ')}`);
      if (findNarration(m.text).length) offenders.push(`narration: ${m.text.slice(0, 40)}…`);
      if (messageKind(m.text) === 'other') offenders.push(`not a decision/result/marker: ${m.text.slice(0, 40)}…`);
      if (findRawReturnFields(m.text).length && !carriesWorkflowOnlyMarker(m.text))
        offenders.push(`raw return fields unlabelled: ${m.text.slice(0, 40)}…`);
      if (m.role === 'handback' && !checkHandBack(m.text).ok)
        offenders.push(`hand-back shape: ${checkHandBack(m.text).reasons.join(', ')}`);
    }
    expect(approvalsWithoutHeadline(t), 'approval not preceded by a headline').toEqual([]);
    expect(offenders, offenders.join('\n')).toHaveLength(0);
  });
});

if (captures.length === 0) {
  // eslint-disable-next-line no-console
  console.warn(
    '[voice-and-volume Tier 2] No captured runs yet — capture regression SKIPPED.\n' +
      `  Add tagged transcripts at ${CAPTURE_DIR}\\*.json once the marker convention lands.`,
  );
}
