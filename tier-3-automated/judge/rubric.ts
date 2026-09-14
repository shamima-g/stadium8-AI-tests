/**
 * S8-134-145 — Tier 3 output-quality judge RUBRIC.
 *
 * The subjective acceptance criteria (act-from-first-line, at-a-glance, only-the-
 * actionable-part, shown-once, no-blind-approvals) can't be settled by a regex, so a
 * live run is scored by an LLM judge against these questions. Per the suite's design the
 * judge is RECORD-ONLY — its score is logged like `rulesMissed`, never a red/green gate —
 * and it must first clear the calibration gate (see calibration.ts) before its verdicts
 * count.
 *
 * This file is data only: the rubric the judge is prompted with, and which AC each item
 * covers. The actual model call is a pluggable seam that lands with the Tier-3 judge infra.
 */

export type Verdict = 'pass' | 'fail';

export interface RubricItem {
  /** Stable id, e.g. "J1". */
  id: string;
  /** The acceptance criterion this scores (1-8). */
  ac: number;
  /** Short name. */
  name: string;
  /** The pass/fail question put to the judge about a single user-facing message/hand-back. */
  question: string;
  /** A concrete PASS anchor for the prompt. */
  passAnchor: string;
  /** A concrete FAIL anchor for the prompt. */
  failAnchor: string;
}

export const JUDGE_RUBRIC: RubricItem[] = [
  {
    id: 'J1',
    ac: 5,
    name: 'first-line-actionable',
    question: 'Can the reader act on this message from its first line, without reading to the end to find the point?',
    passAnchor: '"Dashboard Overview is done and merged. Build the next with /start."',
    failAnchor: '"Okay, so now that all the checks have finished, the dashboard is ready."',
  },
  {
    id: 'J2',
    ac: 4,
    name: 'at-a-glance',
    // Single concept: nothing beyond outcome + next step. (The "has an outcome + next
    // action" presence side is covered mechanically by checkHandBack in Tier 2.)
    question: 'Is this hand-back trimmed to just the outcome and the next step, with no recap or extra detail added?',
    passAnchor: 'A two-line close: the outcome, then the next command.',
    failAnchor: 'A six-line recap narrating each story and every check that ran.',
  },
  {
    id: 'J3',
    ac: 3,
    name: 'only-actionable-part',
    question: 'Where an agent reported back, does only the part the user must act on reach them (no raw internal report fields)?',
    passAnchor: 'A flagged assumption surfaced in plain words at the manual-test approval.',
    failAnchor: 'The raw return block with fields like tier2JournalEntries shown to the user.',
  },
  {
    id: 'J4',
    ac: 7,
    name: 'shown-once',
    question: 'Is the approved content presented once on the review page, with the chat pointing to it rather than repeating it?',
    passAnchor: '"Six stories for Sign in — details on the review page."',
    failAnchor: 'The chat reproduces the full story list that is already on the page.',
  },
  {
    id: 'J5',
    ac: 8,
    name: 'no-blind-approvals',
    question: 'Was the user shown what they are being asked to approve before the approval prompt fired?',
    passAnchor: 'A headline describing the stories precedes the approve prompt.',
    failAnchor: 'The approve prompt appears with no preceding description of what "this" is.',
  },
];

/** The judge is record-only. This documents (and lets a test assert) that it never gates. */
export const JUDGE_GATES_THE_BUILD = false;

// ---------------------------------------------------------------------------
// The judge seam (not yet implemented) — the pluggable model call.
// ---------------------------------------------------------------------------

/** One thing to score: the user-facing text and which rubric item to apply. */
export interface JudgeTask {
  rubricId: string; // e.g. "J2"
  text: string; // the user-facing message/hand-back under review
}

/**
 * The contract the live judge must implement. It maps a task to a pass/fail verdict.
 * NOT built here — it needs the Tier-3 model-call infra. Defining it now lets the
 * calibration harness and the (future) live run share one typed seam, and keeps the
 * record-only integration (log the score like `rulesMissed`, never fail the build) on the
 * caller side, never inside the judge.
 */
export interface JudgeAdapter {
  score(task: JudgeTask): Promise<Verdict>;
}
