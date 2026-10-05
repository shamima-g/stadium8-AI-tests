/**
 * The VERBOSITY ("Voice and volume") subjective criteria (ACs 3/4/5/7/8), re-homed here when the AI/LLM
 * judge (tier-3-automated/judge/) was retired (2026-10-02: no AI judge).
 *
 * These are judged on the tool's USER-FACING MESSAGES, which aren't reliably extractable from a capture
 * (would need the declined message-tagging/B14 or a paid live capture + guessing). DECISION 2026-10-02:
 * they stay checked BY HAND (the manual-tests docs / coverage matrix), NOT auto-wired into the browser
 * review harness. So this file is the canonical CRITERIA LIST for that manual check — the question + what a
 * pass/fail looks like — not a pending auto-wiring. (Contrast: the artifact-reviewable intake/design checks
 * ARE auto-wired — see helpers/intake-review.ts + helpers/plan-review.ts.)
 */
export interface VerbosityCheckDef {
  /** stable review-check id */
  id: string;
  /** the template acceptance criterion this corresponds to (for traceability) */
  ac: number;
  /** the question the reviewer answers */
  criterion: string;
  /** what a pass vs a fail looks like (shown as guidance) */
  guidance: string;
}

export const VERBOSITY_REVIEW_CHECKS: VerbosityCheckDef[] = [
  {
    id: 'verbosity-first-line-actionable',
    ac: 5,
    criterion: 'Can the reader act on this message from its first line, without reading to the end to find the point?',
    guidance: 'PASS: "Dashboard Overview is done and merged. Build the next with /start." · FAIL: "Okay, so now that all the checks have finished, the dashboard is ready."',
  },
  {
    id: 'verbosity-at-a-glance',
    ac: 4,
    criterion: 'Is this hand-back trimmed to just the outcome and the next step, with no recap or extra detail added?',
    guidance: 'PASS: a two-line close — the outcome, then the next command. · FAIL: a six-line recap narrating each story and every check that ran.',
  },
  {
    id: 'verbosity-only-actionable-part',
    ac: 3,
    criterion: 'Where an agent reported back, does only the part the user must act on reach them (no raw internal report fields)?',
    guidance: 'PASS: a flagged assumption surfaced in plain words at the manual-test approval. · FAIL: the raw return block with fields like tier2JournalEntries shown to the user.',
  },
  {
    id: 'verbosity-shown-once',
    ac: 7,
    criterion: 'Is the approved content presented once on the review page, with the chat pointing to it rather than repeating it?',
    guidance: 'PASS: "Six stories for Sign in — details on the review page." · FAIL: the chat reproduces the full story list that is already on the page.',
  },
  {
    id: 'verbosity-no-blind-approvals',
    ac: 8,
    criterion: 'Was the user shown what they are being asked to approve before the approval prompt fired?',
    guidance: 'PASS: a headline describing the stories precedes the approve prompt. · FAIL: the approve prompt appears with no preceding description of what "this" is.',
  },
];
