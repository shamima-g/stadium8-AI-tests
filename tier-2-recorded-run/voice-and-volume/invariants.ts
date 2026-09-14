/**
 * S8-134-145 — "Voice and volume" output-discipline invariants (Tier 2).
 *
 * Pure functions that check the invariants over the messages a user actually read.
 * Decoupled from HOW those messages are separated from internal chatter: every function
 * operates on a `Transcript` — an ordered list of `{ audience: 'user' | 'internal', text }`
 * messages. The template's forthcoming *marker convention* supplies that `audience` tag on
 * a real run; until then these run against inline fixtures, which is the real contract.
 *
 * The forbidden-name lists (agent names, phase names) are DERIVED FROM THE TEMPLATE via
 * the Tier-1 helpers, never hand-copied.
 *
 * Carve-out: the rule allows internal detail when it *is* the thing being decided or
 * reported — chiefly a command the user must run, shown in a fenced code block.
 * `stripCarveOuts` removes fenced blocks before the leak scan. Genuinely ambiguous cases
 * (a lone `main`, a short SHA, a bare deliverable path in prose) are deliberately left to
 * the Tier-3 judge, not forced through a regex.
 *
 * Not a *.test.ts file, so Vitest never collects it as a suite.
 */

// ---------------------------------------------------------------------------
// Transcript model — what the marker convention will yield on a real run
// ---------------------------------------------------------------------------

export type Audience = 'user' | 'internal';

export interface Msg {
  audience: Audience;
  text: string;
  /** Role the marker convention stamps; the approval checks REQUIRE it (see plan prereq). */
  role?: 'headline' | 'approval' | 'handback' | 'progress' | 'message';
}

export interface Transcript {
  messages: Msg[];
}

/** Only the messages the user actually read. */
export function userMessages(t: Transcript): Msg[] {
  return t.messages.filter((m) => m.audience === 'user');
}

/**
 * FAIL-CLOSED: true when a transcript that clearly had assistant turns yielded no
 * user-facing text. A "no leaks / all clean" result over an empty extraction is a
 * vacuous green, so the caller must treat this as a failure, not a pass.
 */
export function extractionIsEmpty(t: Transcript): boolean {
  return t.messages.length > 0 && userMessages(t).length === 0;
}

// ---------------------------------------------------------------------------
// Forbidden-name leak scan (AC2)
// ---------------------------------------------------------------------------

export interface ForbiddenLists {
  agentNames: string[];
  phaseNames: string[];
}

export interface Leak {
  token: string;
  kind: 'agent-name' | 'phase-name' | 'path' | 'branch' | 'sha' | 'script';
}

const escapeRegex = (s: string): string => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/**
 * Remove the carve-out surface before scanning: fenced code blocks (a command the user
 * must run is shown fenced, per the rule). We do NOT drop whole command-prefixed lines —
 * that hid leaks that shared the line (e.g. `cd generated-docs/x && cat state.json`).
 */
export function stripCarveOuts(text: string): string {
  return text.replace(/```[\s\S]*?```/g, ' ');
}

/** Internal names/paths/ids leaked into the given user-facing text (empty = clean). */
export function findLeaks(userText: string, lists: ForbiddenLists): Leak[] {
  const scan = stripCarveOuts(userText);
  const leaks: Leak[] = [];
  const push = (token: string, kind: Leak['kind']) => leaks.push({ token, kind });

  // Agent names — only the unambiguous hyphenated forms (e.g. `feature-planner`). Bare
  // words like "developer" collide with English, so they're left to the judge.
  for (const name of lists.agentNames) {
    if (!name.includes('-')) continue;
    if (new RegExp(`\\b${escapeRegex(name)}\\b`, 'i').test(scan)) push(name, 'agent-name');
  }

  // Phase names. Hyphenated multi-word phases (EPIC-END, READY-TO-BUILD, …) don't collide
  // with English, so match them case-INsensitively (catches "Epic-End"). Bare single-word
  // phases (PLAN/BUILD/COMPLETE) match ALL-CAPS only, to avoid "building"/"plan" false-reds.
  // Boundaries `(?<![A-Za-z0-9-])…(?![A-Za-z0-9-])` spare BUILD inside READY-TO-BUILD and
  // COMPLETE inside COMPLETE-ON-BRANCH.
  for (const ph of lists.phaseNames) {
    const body = `(?<![A-Za-z0-9-])${escapeRegex(ph)}(?![A-Za-z0-9-])`;
    const rx = ph.includes('-') ? new RegExp(body, 'i') : new RegExp(body);
    if (rx.test(scan)) push(ph, 'phase-name');
  }

  // Internal paths + the state file.
  for (const m of scan.match(/\b(?:generated-docs|web\/src|\.claude)\/[^\s`)]+/gi) ?? []) push(m, 'path');
  if (/\bstate\.json\b/i.test(scan)) push('state.json', 'path');

  // Epic branch names.
  for (const m of scan.match(/\bepic\/[a-z0-9-]+/gi) ?? []) push(m, 'branch');

  // Commit SHAs — full 40-hex only (unambiguous), not part of a longer hex run. Short SHAs
  // need context, so they are judge-territory.
  for (const m of scan.match(/\b[0-9a-f]{40}(?![0-9a-f])/gi) ?? []) push(m, 'sha');

  // Script names — only hyphenated internal basenames (collect-dashboard-data.js,
  // resolve-state-path.js). Single-word tech/library names (node.js, chart.js, vue.js) are
  // not internal scripts and would be false-reds.
  for (const m of scan.match(/\b[a-z0-9]+(?:-[a-z0-9]+)+\.(?:js|mjs|cjs)\b/gi) ?? []) push(m, 'script');

  return leaks;
}

// ---------------------------------------------------------------------------
// Message kind (AC1 — every message is a decision, result, or progress marker)
// ---------------------------------------------------------------------------

export type MessageKind = 'decision' | 'result' | 'progress' | 'other';

/**
 * Best-effort kind of a user-facing message. `'other'` is the AC1 violation ("anything
 * else is not shown"). This is a mechanical backstop; the nuanced call is the Tier-3 judge.
 */
export function messageKind(text: string): MessageKind {
  if (isProgressMarker(text)) return 'progress';
  if (/\?\s*$/m.test(text) || /\b(approve|which|do you want|would you like|choose|confirm)\b/i.test(text))
    return 'decision';
  if (/\b(done|built|merged|ready|passed|failed|created|added|fixed|complete|live|updated|removed)\b/i.test(text))
    return 'result';
  return 'other';
}

/** User messages that are none of the three allowed kinds (empty = all conform). */
export function nonConformingMessages(t: Transcript): Msg[] {
  return userMessages(t).filter((m) => messageKind(m.text) === 'other');
}

// ---------------------------------------------------------------------------
// Anti-pattern text checks (AC1 narration, AC5 first line, AC6 progress)
// ---------------------------------------------------------------------------

/** In-flight step narration — steps inside one piece of work that should say nothing. */
export const NARRATION_PATTERNS: RegExp[] = [
  /\bgenerating tests\b/i,
  /\brunning (?:the )?quality gates?\b/i,
  /\bcommitting\b/i,
  /\brunning (?:the )?(?:type ?check|lint|vitest|playwright)\b/i,
  /\bstate resolved\b/i,
  /\bcutting (?:a )?branch\b/i,
  /\bstory \d+ starting\b/i,
];

/** Narration anti-patterns present in the text (empty = clean). */
export function findNarration(text: string): RegExp[] {
  return NARRATION_PATTERNS.filter((rx) => rx.test(text));
}

/** Preamble/recap openers — the point should be on the first line, not after a wind-up. */
export const PREAMBLE_PATTERNS: RegExp[] = [
  /^\s*(?:okay|ok|alright|so),?\s/i,
  /^\s*(?:now that|now,|let me|i(?:'ll| will) now|first,? i)\b/i,
  /^\s*(?:i(?:'ve| have) (?:just )?(?:finished|completed|been))\b/i,
  /^\s*(?:to recap|as a reminder|just to recap)\b/i,
];

/** True when the first line is a preamble/recap rather than the point (AC5 violation). */
export function startsWithPreamble(text: string): boolean {
  const firstLine = text.split(/\r?\n/).find((l) => l.trim().length > 0) ?? '';
  return PREAMBLE_PATTERNS.some((rx) => rx.test(firstLine));
}

/** A short, structured progress marker like "Story 3 of 6 built" (AC6 must-show). It must
 * be the whole (short) line, not a count buried in a sentence. */
export function isProgressMarker(text: string): boolean {
  const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  if (lines.length > 2) return false;
  return lines.some((l) => /^\w[\w ]*\b\d+\s*(?:of|\/)\s*\d+\b[\w ]*$/.test(l));
}

// ---------------------------------------------------------------------------
// Hand-back shape (AC4 — outcome + next action, nothing after)
// ---------------------------------------------------------------------------

/** True when the text carries a next-action cue: a slash command or an imperative. */
export function hasNextAction(text: string): boolean {
  return (
    /\/(start|continue|plan|status|dashboard)\b/.test(text) ||
    /\b(build|run|open|review|approve|check|restart|merge)\b/i.test(text)
  );
}

export interface HandBackCheck {
  ok: boolean;
  reasons: string[];
}

/**
 * A hand-back is the outcome + the next action, nothing after: short (≤ 4 non-empty
 * lines), no in-flight narration, first line is the point (no preamble), AND a next action
 * is present. Shape only — the "reads at a glance" judgement is Tier 3 (J2).
 */
export function checkHandBack(text: string): HandBackCheck {
  const reasons: string[] = [];
  const lines = text.split(/\r?\n/).filter((l) => l.trim().length > 0);
  if (lines.length > 4) reasons.push(`too long (${lines.length} lines)`);
  if (findNarration(text).length > 0) reasons.push('contains step narration');
  if (startsWithPreamble(text)) reasons.push('opens with preamble, not the point');
  if (!hasNextAction(text)) reasons.push('no next action');
  return { ok: reasons.length === 0, reasons };
}

// ---------------------------------------------------------------------------
// Agent-return handling (AC3)
// ---------------------------------------------------------------------------

/** Raw return-block field labels/headers that must never reach the user as-is. */
export const RETURN_FIELD_LABELS: RegExp[] = [
  /\btier1Decisions\b/,
  /\btier2JournalEntries\b/,
  /\bunverifiedAssumptions\b/,
  /\btestVerification\b/,
  /\btemplateFeedback\b/,
  /\bbriefUpdates\b/,
  /\bDEVELOPER (?:COMPLETE|UNABLE TO RESOLVE)\b/,
  /\bTESTS WRITTEN\b/,
  /\bMOCK DATA READY\b/,
];

/** Raw return-block field labels present in the text (empty = none leaked). */
export function findRawReturnFields(text: string): RegExp[] {
  return RETURN_FIELD_LABELS.filter((rx) => rx.test(text));
}

/** AC3 accepted exception: the developer block carries the "(For the workflow only)" marker. */
export function carriesWorkflowOnlyMarker(text: string): boolean {
  return /\(for the workflow only\)/i.test(text);
}

/** A flagged assumption surfaced in plain words (must-show), not as a raw field. */
export function flaggedAssumptionReworded(text: string): boolean {
  return (
    /\b(before you sign off|worth a (?:quick )?check|we assumed|double-check|check these first)\b/i.test(text) &&
    findRawReturnFields(text).length === 0
  );
}

// ---------------------------------------------------------------------------
// Must-show presence checks (AC1)
// ---------------------------------------------------------------------------

/** The INTAKE coverage line the user must see. */
export function showsCoverageLine(t: Transcript): boolean {
  return userMessages(t).some((m) => /\b(everything you asked for is covered|is covered|coverage)\b/i.test(m.text));
}

/** The manual-test "check these first" list the user must see when assumptions exist. */
export function showsManualTestChecklist(t: Transcript): boolean {
  return userMessages(t).some((m) => /\b(check these first|before you sign off|worth a (?:quick )?check)\b/i.test(m.text));
}

// ---------------------------------------------------------------------------
// Approval invariants (AC7, AC8) — depend on the marker convention stamping `role`
// ---------------------------------------------------------------------------

/**
 * AC8 — every approval request is preceded by a user-facing HEADLINE (role:'headline')
 * describing what's being approved. Returns indices of approval messages with no preceding
 * headline (empty = all approvals were introduced).
 */
export function approvalsWithoutHeadline(t: Transcript): number[] {
  const offenders: number[] = [];
  const msgs = t.messages;
  for (let i = 0; i < msgs.length; i++) {
    if (msgs[i].role !== 'approval') continue;
    const priorHeadline = msgs
      .slice(0, i)
      .some((m) => m.audience === 'user' && m.role === 'headline' && m.text.trim().length > 0);
    if (!priorHeadline) offenders.push(i);
  }
  return offenders;
}

/**
 * AC8 fail-closed guard: a run that fires approvals but never stamps a `role:'approval'`
 * (marker convention not wired) must FAIL, not silently pass. Returns true when there is at
 * least one user message that looks like an approval prompt yet no message carries the role.
 */
export function approvalRolesMissing(t: Transcript): boolean {
  const looksLikeApproval = t.messages.some(
    (m) => m.audience === 'user' && /\bapprove\b|\bproceed\b\?|\?\s*$/i.test(m.text),
  );
  const anyTagged = t.messages.some((m) => m.role === 'approval');
  return looksLikeApproval && !anyTagged;
}

/**
 * AC7 — the chat headline points to the review page rather than repeating it. Flags a
 * repeat when the headline reproduces a run of the page's own words (punctuation- and
 * case-insensitive).
 */
export function chatRepeatsPage(chatHeadline: string, pageText: string, minRun = 8): boolean {
  const words = (s: string) =>
    s
      .toLowerCase()
      .replace(/[^\p{L}\p{N}\s]/gu, ' ')
      .replace(/\s+/g, ' ')
      .trim()
      .split(' ')
      .filter(Boolean);
  const page = words(pageText);
  const chat = words(chatHeadline);
  if (chat.length < minRun) return false;
  const pageJoined = ' ' + page.join(' ') + ' ';
  for (let i = 0; i + minRun <= chat.length; i++) {
    const run = ' ' + chat.slice(i, i + minRun).join(' ') + ' ';
    if (pageJoined.includes(run)) return true;
  }
  return false;
}
