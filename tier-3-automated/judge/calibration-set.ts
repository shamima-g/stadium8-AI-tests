/**
 * S8-134-145 — Tier 3 judge CALIBRATION SET (human-labelled).
 *
 * A fixed set of good/bad examples, one pass and one fail per rubric criterion, that the
 * LLM judge must score correctly before its live verdicts count. Each `fail` item is also
 * a canary: the judge MUST catch it (see calibration.ts). Grow this set over time; keep it
 * human-labelled and checked into the repo so the gate is reproducible.
 */

import type { Verdict } from './rubric';

export interface CalibrationExample {
  id: string;
  criterion: string; // rubric name
  label: Verdict;
  text: string; // the user-facing message/hand-back shown to the judge
}

export const CALIBRATION_SET: CalibrationExample[] = [
  // J1 — first-line-actionable
  { id: 'C-J1-pass', criterion: 'first-line-actionable', label: 'pass', text: 'Dashboard Overview is done and merged. Build the next with /start.' },
  { id: 'C-J1-fail', criterion: 'first-line-actionable', label: 'fail', text: 'Okay, so now that all the checks have finished, I can tell you the dashboard is ready.' },

  // J2 — at-a-glance
  { id: 'C-J2-pass', criterion: 'at-a-glance', label: 'pass', text: 'Sign in is built and tested.\nReview it on the page, then approve to merge.' },
  { id: 'C-J2-fail', criterion: 'at-a-glance', label: 'fail', text: 'Here is a recap: story one added the form, story two added validation, story three added the reset link, story four wired the API, and all quality gates then passed on the third attempt.' },

  // J3 — only-actionable-part
  { id: 'C-J3-pass', criterion: 'only-actionable-part', label: 'pass', text: 'Before you sign off: we assumed orders sort newest-first — worth a quick check.' },
  { id: 'C-J3-fail', criterion: 'only-actionable-part', label: 'fail', text: 'tier2JournalEntries: ["added sort"]; unverifiedAssumptions: ["orders newest-first"]; testVerification: vitest 12/12.' },

  // J4 — shown-once
  { id: 'C-J4-pass', criterion: 'shown-once', label: 'pass', text: 'Six stories for Sign in — details are on the review page.' },
  { id: 'C-J4-fail', criterion: 'shown-once', label: 'fail', text: 'Story 1: sign in with email/password. Story 2: reset password. Story 3: remember me. Story 4: lock after 5 fails. Story 5: sign out. Story 6: session expiry. (All of this is also on the page.)' },

  // J5 — no-blind-approvals
  { id: 'C-J5-pass', criterion: 'no-blind-approvals', label: 'pass', text: 'Here are the six stories for Sign in (on the page). Approve to start building?' },
  { id: 'C-J5-fail', criterion: 'no-blind-approvals', label: 'fail', text: 'Does this look right? Approve to continue.' },
];
