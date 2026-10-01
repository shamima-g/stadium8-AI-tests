/**
 * Project-Overview analysis — the reusable core for the INTAKE `## Project Overview` tests
 * (see 28-09-2026/intake-claudemd-project-overview-test-plan.md).
 *
 * These are PURE functions over strings — no template access, callers pass file contents. That
 * lets the SAME checks run at three tiers: Tier 1 unit-tests them over synthetic good/bad
 * overviews; Tier 2 runs them over a captured golden `CLAUDE.md`; Tier 3 runs them over the
 * file a live `/start` actually wrote. The council's core ruling is baked in here:
 *
 *   - `analyzeStructure` is the LOAD-BEARING check — a structural WHITELIST (only a lead-in +
 *     three named bullets + one pointer line may appear; anything else is a leak by construction).
 *   - `neverPresentTokenLeaks` is a CHEAP NECESSARY GATE ONLY — a blocklist that paraphrase
 *     defeats ("GDPR" with no "compliance", "a blue accent" with no hex). It can never, on its
 *     own, turn the AC green; the semantic judge (Tier 3) is what rules on meaning.
 *   - fact agreement is SET-EQUALITY against project.md, never subset/substring.
 *   - "Critical Rules unchanged" is a PRE-vs-POST SELF-DIFF of the same file, never equality to a
 *     frozen template (that false-reds on user-added rules and on /upgrade).
 *
 * The budget conventions are fixed (not left as two options): line count runs from the heading
 * through the last NON-BLANK line before the next `## ` (trailing blanks excluded); word count is
 * an explicit whitespace-token count (the suite runs under Node, not GNU `wc`). Both are ≤ (the
 * spec says "within … 150", i.e. ≤150).
 */

import fs from 'node:fs';
import path from 'node:path';

// ── The pre-intake placeholder (shared constant — Tier-1 tripwire and Tier-3 both import it) ───
//
// The AC's illustrative phrase "Template repository for building frontend applications" exists in
// NO template file — binding to it passes vacuously. This is the REAL shipped placeholder in the
// user file's §Project Overview. A single source of truth so the tripwire and the Tier-3 check
// can never drift.
export const PLACEHOLDER = /No project yet\.\s*Run\s+`?\/start`?\s+to describe/i;

/** The three canonical pointer targets the overview must (and may only) point to. */
export const POINTER_TARGETS = ['generated-docs/project.md', 'generated-docs/epics/', 'generated-docs/architecture.md'] as const;

// ── Which file INTAKE actually writes (marker resolution — net-new, per the plan) ─────────────

export interface ShippedUserFile {
  /** Absolute path to the file INTAKE writes its `## Project Overview` into. */
  path: string;
  /** The `<!-- stadium8-claude: ... -->` marker of the top-level CLAUDE.md, or null. */
  marker: 'user' | 'template-dev' | null;
}

/**
 * Resolve the shipped end-user file under a target repo root.
 *
 * In a RELEASE clone the top-level `CLAUDE.md` carries `<!-- stadium8-claude: user -->` and is the
 * file INTAKE writes. In the DEV repo `CLAUDE.md` carries `template-dev` and only imports
 * `@CLAUDE.user.md` — so the shipped user file is `CLAUDE.user.md`. Asserting against the dev
 * `CLAUDE.md` would test the wrong artifact. Returns null when neither file exists.
 */
export function resolveShippedUserFile(root: string): ShippedUserFile | null {
  const claude = path.join(root, 'CLAUDE.md');
  const claudeUser = path.join(root, 'CLAUDE.user.md');
  let marker: ShippedUserFile['marker'] = null;
  if (fs.existsSync(claude)) {
    const head = fs.readFileSync(claude, 'utf8').slice(0, 400);
    const m = /<!--\s*stadium8-claude:\s*(user|template-dev)\s*-->/i.exec(head);
    marker = (m?.[1] as ShippedUserFile['marker']) ?? null;
  }
  if (marker === 'user') return { path: claude, marker };
  if (marker === 'template-dev') return fs.existsSync(claudeUser) ? { path: claudeUser, marker } : null;
  // No marker: prefer the explicit user file, else the plain CLAUDE.md.
  if (fs.existsSync(claudeUser)) return { path: claudeUser, marker };
  if (fs.existsSync(claude)) return { path: claude, marker };
  return null;
}

// ── Section extraction + budget (fixed conventions) ───────────────────────────────────────────

export interface Section {
  found: boolean;
  /** The whole span INCLUDING the heading line, trailing blank lines trimmed. */
  text: string;
  /** Lines including the heading, trailing blanks excluded. */
  lines: string[];
  /** Line count under the fixed convention (heading included, trailing blanks excluded). */
  lineCount: number;
  /** Whitespace-delimited token count over the whole span. */
  wordCount: number;
}

/** A fence toggle: ``` or ~~~ opening/closing a code block. */
const FENCE = /^\s*(?:```|~~~)/;
/** An ATX H2 with the CommonMark ≤3-space indent tolerance. */
const H2 = /^\s{0,3}##\s/;

/** True when `line` is exactly this H2 heading (not H3, and ≤3-space indented, not a code block). */
function isHeadingLine(line: string, heading: string): boolean {
  return H2.test(line) && line.trim() === heading;
}

/**
 * Locate a `## ` section [start, end) — FENCE-AWARE both when finding the heading and when scanning
 * for the next heading, so a `## Project Overview` written inside an earlier code fence (a docs
 * sample) can't be mistaken for the real section, and a `##` inside the section's own fence can't
 * end it early. The end scan tolerates the same ≤3-space indent the start match does (an indented
 * next-heading still ends the section). Returns null when the heading isn't found outside a fence.
 */
function findSectionBounds(all: string[], heading: string): [number, number] | null {
  let inFence = false;
  let start = -1;
  for (let i = 0; i < all.length; i++) {
    if (FENCE.test(all[i])) { inFence = !inFence; continue; }
    if (!inFence && isHeadingLine(all[i], heading)) { start = i; break; }
  }
  if (start === -1) return null;
  let end = all.length;
  inFence = false;
  for (let i = start + 1; i < all.length; i++) {
    if (FENCE.test(all[i])) { inFence = !inFence; continue; }
    if (!inFence && H2.test(all[i])) { end = i; break; }
  }
  return [start, end];
}

/**
 * Extract a `## ` section: from its heading line through the last NON-BLANK line before the next
 * `## ` heading (or EOF). Trailing blank lines are excluded so a cosmetic blank before the next
 * heading can't inflate the line count. Fail-closed: `found:false` on a missing heading — a caller
 * that expects the section present should treat that as a failure, not a vacuous pass.
 */
export function extractSection(md: string, heading = '## Project Overview'): Section {
  const all = md.split(/\r?\n/);
  const bounds = findSectionBounds(all, heading);
  if (!bounds) return { found: false, text: '', lines: [], lineCount: 0, wordCount: 0 };
  const span = all.slice(bounds[0], bounds[1]);
  while (span.length && span[span.length - 1].trim() === '') span.pop(); // drop trailing blanks
  const text = span.join('\n');
  return { found: true, text, lines: span, lineCount: span.length, wordCount: countWords(text) };
}

/** Whitespace-delimited token count (the executing runtime is Node, not GNU `wc`). */
export function countWords(text: string): number {
  const t = text.trim();
  return t.length === 0 ? 0 : t.split(/\s+/).length;
}

export const LINE_BUDGET = 12;
export const WORD_BUDGET = 150;

export interface Budget {
  ok: boolean;
  lineCount: number;
  wordCount: number;
}

/** Budget is a GATE, not proof of well-formedness — pair it with `analyzeStructure`. */
export function withinBudget(section: Section): Budget {
  return {
    ok: section.lineCount <= LINE_BUDGET && section.wordCount <= WORD_BUDGET,
    lineCount: section.lineCount,
    wordCount: section.wordCount,
  };
}

// ── Structural whitelist (the load-bearing shape check) ───────────────────────────────────────

export interface Structure {
  ok: boolean;
  leadInLines: string[];
  bulletLabels: string[];
  pointerLineCount: number;
  /** Anything outside the allowed shapes — a leak by construction. */
  disallowed: string[];
  reasons: string[];
}

const EXPECTED_BULLETS = ['roles', 'auth', 'data source'];

/** A line is the pointer line when it references at least two of the canonical pointer targets. */
export function isPointerLine(line: string): boolean {
  return (line.match(/generated-docs\//g) ?? []).length >= 2;
}

/** The canonical pointer targets actually present in a section (deduped, in canonical order). */
export function pointersIn(text: string): string[] {
  return POINTER_TARGETS.filter((t) => text.includes(t));
}

/**
 * The overview may contain ONLY: a lead-in (1+ prose lines), exactly three bullets labelled
 * Roles / Auth / Data source, and exactly one pointer line. A sub-heading, table, code fence, a
 * fourth bullet, or a stray paragraph is a leak — regardless of wording. This is what actually
 * enforces "everything else is pointered"; the token gate below is only a cheap backstop.
 */
export function analyzeStructure(sectionText: string): Structure {
  const lines = sectionText.split(/\r?\n/);
  const body = lines[0] !== undefined && /^##\s/.test(lines[0]) ? lines.slice(1) : lines;
  const disallowed: string[] = [];
  const bulletLabels: string[] = [];
  const leadInLines: string[] = [];
  let pointerLineCount = 0;
  let inFence = false;

  for (const raw of body) {
    const t = raw.trim();
    if (t === '') continue;
    if (/^```/.test(t)) { inFence = !inFence; disallowed.push(t); continue; }
    if (inFence) { disallowed.push(t); continue; }
    if (/^#{1,6}\s/.test(t)) { disallowed.push(t); continue; }      // sub-heading
    if (/^\|/.test(t)) { disallowed.push(t); continue; }            // table row
    if (/^[-*]\s+/.test(t)) {
      // Emphasis around the label (`**Roles:**`, `_Auth_`, `` `Data source` ``) is wording, not
      // shape — strip *,_,` before capturing so the label whitelist compares the word, not markup.
      bulletLabels.push(t.replace(/^[-*]\s+/, '').split(':')[0].replace(/[*_`]/g, '').trim());
      continue;
    }
    if (isPointerLine(t)) { pointerLineCount++; continue; }
    leadInLines.push(t);
  }

  const reasons: string[] = [];
  if (bulletLabels.length !== 3) reasons.push(`expected 3 bullets, found ${bulletLabels.length}`);
  // Normalize hyphen/space/case so "Data-source" / "Data Source" / "DATA SOURCE" all match the label.
  const norm = (s: string) => s.replace(/[-\s]+/g, ' ').trim().toLowerCase();
  const labelSet = new Set(bulletLabels.map(norm));
  if (!(labelSet.size === 3 && EXPECTED_BULLETS.every((e) => labelSet.has(e)))) {
    reasons.push(`bullet labels ${JSON.stringify(bulletLabels)} != Roles/Auth/Data source`);
  }
  if (pointerLineCount !== 1) reasons.push(`expected 1 pointer line, found ${pointerLineCount}`);
  if (leadInLines.length < 1) reasons.push('missing lead-in');
  // The spec is a TWO-sentence lead-in; a wall of prose is a leak vector the budget alone misses.
  // Allow slight slack (≤3) but flag a genuine wall.
  const leadInSentences = (leadInLines.join(' ').match(/[.!?](?=\s|$)/g) ?? []).length;
  if (leadInLines.length >= 1 && leadInSentences > 3) reasons.push(`lead-in has ${leadInSentences} sentences (max ~2)`);
  if (disallowed.length) reasons.push(`disallowed content: ${disallowed.join(' | ')}`);

  return { ok: reasons.length === 0, leadInLines, bulletLabels, pointerLineCount, disallowed, reasons };
}

// ── Never-present token gate (NECESSARY, NOT SUFFICIENT) ───────────────────────────────────────

export interface Leak {
  kind: string;
  evidence: string;
}

/**
 * A cheap blocklist for the literal detail that must never appear: hex/palette, endpoint URLs and
 * paths, backend CONNECTIVITY (reachability / smoke-test / base-url), build progress, epic slugs,
 * timestamps. Deliberately does NOT flag the ALLOWED data-source mode ("existing API", "backend
 * services", "mocks") — the forbidden category is connectivity, not the named data source
 * (council finding 8). A paraphrase leak ("meets GDPR", "a blue accent") sails past this by design
 * — that is the Tier-3 semantic judge's job, which is why this is necessary-not-sufficient.
 */
export function neverPresentTokenLeaks(sectionText: string): Leak[] {
  const leaks: Leak[] = [];
  const probe = (kind: string, re: RegExp) => {
    const m = sectionText.match(re);
    if (m) leaks.push({ kind, evidence: m[0] });
  };
  probe('palette/hex', /#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b/); // #RGB #RGBA #RRGGBB #RRGGBBAA
  probe('endpoint/url', /\b[a-z][a-z0-9+.-]*:\/\/\S+/i); // any scheme:// (http, ws, grpc, …)
  probe('endpoint/path', /\/v\d+\//i);
  probe('port', /\bport\s*\d{2,5}\b/i);
  probe('connectivity', /\b(reachable(?:\s+now)?|smoke[-\s]?test|health\s?check|base\s?url)\b/i);
  probe('progress', /\b(\d+\s*(?:of|\/)\s*\d+\s+(?:stories|epics)|in[-\s]flight|not\s+started|\d+%\s*(?:complete|done|built))\b/i);
  probe('epic-slug', /\bepic\/[a-z0-9]+(?:-[a-z0-9]+)+/i);
  probe('timestamp', /\b\d{4}[-/]\d{2}[-/]\d{2}\b/);
  return leaks;
}

// ── Fact agreement (SET-EQUALITY, not subset/substring) ───────────────────────────────────────

/** The role names in the Roles bullet — the backticked `X`, `Y` tokens. */
export function parseOverviewRoles(sectionText: string): string[] {
  const line = sectionText.split(/\r?\n/).find((l) => /^\s*[-*]\s+Roles\b/i.test(l)) ?? '';
  return [...line.matchAll(/`([^`]+)`/g)].map((m) => m[1].trim());
}

/**
 * True only when the two role name sets are EQUAL — a subset (missing a 3rd role) is a fail, and a
 * DUPLICATE in either list is a fail too (a Set alone would collapse `[user, user]` and mask an
 * overview that repeated a role instead of naming the real one). Role names are the spec's "exact
 * backend strings", so the compare is case-SENSITIVE by design.
 */
export function roleSetEquals(overviewRoles: string[], projectRoles: string[]): boolean {
  const a = overviewRoles.map((r) => r.trim());
  const b = projectRoles.map((r) => r.trim());
  const sa = new Set(a);
  const sb = new Set(b);
  if (a.length !== sa.size || b.length !== sb.size) return false; // no duplicates allowed
  return sa.size === sb.size && [...sa].every((r) => sb.has(r));
}

/** Does the Roles bullet actually assert the closed list (so naming only 2 of 3 roles is a lie)? */
export function claimsClosedList(sectionText: string): boolean {
  const line = sectionText.split(/\r?\n/).find((l) => /^\s*[-*]\s+Roles\b/i.test(l)) ?? '';
  return /(no other role|only these roles|closed list|no others?)\b/i.test(line);
}

/**
 * B2 — the PROJECT-side role names, from `project.md` §Roles & Permissions. INTAKE writes a permissions
 * matrix whose first column is "Permission" and whose remaining **column headings are the role names**
 * (see `.claude/shared/roles-snippets.md` — e.g. `| Permission | Owner | Admin | Member | Viewer |`).
 * These are the "exact backend strings" the overview's Roles bullet must equal, so this is the
 * ground-truth side for `roleSetEquals`. Heading-case tolerant; returns [] when the section or its
 * table isn't found (fail-closed — an empty set never spuriously equals a real overview list).
 */
export function parseProjectRoles(projectMd: string): string[] {
  const lines = projectMd.split(/\r?\n/);
  const start = lines.findIndex((l) => /^#{1,6}\s+§?\s*Roles\s*&\s*Permissions\b/i.test(l));
  const from = start === -1 ? 0 : start + 1;
  let end = lines.length;
  for (let i = from; i < lines.length; i++) { if (/^#{1,6}\s/.test(lines[i])) { end = i; break; } }
  for (let i = from; i < end - 1; i++) {
    const header = lines[i];
    const sep = lines[i + 1];
    if (!/^\s*\|.*\|\s*$/.test(header)) continue;            // a `| … |` table row
    if (!/^\s*\|[-:| ]*-[-:| ]*\|\s*$/.test(sep)) continue;  // followed by the `|---|---|` separator
    const cells = header.split('|').slice(1, -1).map((c) => c.replace(/`/g, '').trim());
    // The matrix's first column is the "Permission" label; if it isn't, this isn't the roles table —
    // keep scanning rather than blindly dropping column 0 and returning garbage.
    if (!/^permission$/i.test(cells[0] ?? '')) continue;
    return cells.slice(1).filter(Boolean); // the remaining column headings are the role names
  }
  return [];
}

// ── Critical Rules / Policies unchanged BY INTAKE (self-diff, never vs a frozen template) ──────

/** The raw text of a `## ` section, heading through the line before the next `## ` (or EOF). Fence-aware. */
export function sectionSpan(md: string, heading: string): string {
  const all = md.split(/\r?\n/);
  const bounds = findSectionBounds(all, heading);
  if (!bounds) return '';
  return all.slice(bounds[0], bounds[1]).join('\n');
}

/** Per-line right-trim so a cosmetic trailing-space difference isn't read as a content change. */
const normSpan = (s: string): string => s.split(/\r?\n/).map((l) => l.replace(/\s+$/, '')).join('\n');

/**
 * Did INTAKE leave the Critical Rules and Policies spans unchanged? Compares the SAME file before
 * and after the write (self-diff), span-anchored on the headings so inserting the overview above
 * them doesn't shift the comparison. NOT equality to a pristine template — that false-reds when the
 * user added their own rules (the spec protects the user's own words) or when /upgrade advanced the
 * shipped rules. Fail-closed: if either protected section is ABSENT in `before`, return false rather
 * than pass vacuously (`'' === ''`) — a missing section can't be certified "unchanged".
 */
export function criticalRulesAndPoliciesUnchanged(before: string, after: string): boolean {
  const beforeCR = sectionSpan(before, '## Critical Rules');
  const beforePol = sectionSpan(before, '## Policies');
  if (beforeCR.trim() === '' || beforePol.trim() === '') return false;
  return (
    normSpan(beforeCR) === normSpan(sectionSpan(after, '## Critical Rules')) &&
    normSpan(beforePol) === normSpan(sectionSpan(after, '## Policies'))
  );
}

// ── B5 — Tier-2/3 orchestrator: run every project-overview check over a captured CLAUDE.md ──────

export interface OverviewAudit {
  found: boolean;
  structure: Structure;
  budget: Budget;
  leaks: Leak[];
  roles: { overview: string[]; project: string[]; equal: boolean; closedListClaimed: boolean };
  /** Only computed when a pre-write baseline is supplied; `undefined` means "not checked". */
  crPoliciesUnchanged?: boolean;
  ok: boolean;
  reasons: string[];
}

/**
 * Bundle the whole overview verification over one captured `CLAUDE.md`. Pure over strings — the caller
 * reads `golden.root/CLAUDE.md` (via `resolveShippedUserFile`) + `generated-docs/project.md`, and — for
 * the byte-for-byte self-diff — the PRE-write `CLAUDE.md`. `crPoliciesUnchanged` is only meaningful with
 * that baseline, so it's optional. This is what the parked intake Tier-2/Tier-3 todos will call once a
 * capture exists; it composes the already-built checks so no assertion logic lives in the test file.
 */
export function auditOverview(claudeMd: string, projectMd: string, baselineClaudeMd?: string): OverviewAudit {
  const section = extractSection(claudeMd);
  const structure = analyzeStructure(section.text);
  const budget = withinBudget(section);
  const leaks = neverPresentTokenLeaks(section.text);
  const overviewRoles = parseOverviewRoles(section.text);
  const projectRoles = parseProjectRoles(projectMd);
  const roles = {
    overview: overviewRoles,
    project: projectRoles,
    equal: roleSetEquals(overviewRoles, projectRoles),
    closedListClaimed: claimsClosedList(section.text),
  };
  const crPoliciesUnchanged =
    baselineClaudeMd === undefined ? undefined : criticalRulesAndPoliciesUnchanged(baselineClaudeMd, claudeMd);

  const reasons: string[] = [];
  if (!section.found) reasons.push('no ## Project Overview section');
  if (!structure.ok) reasons.push(`structure: ${structure.reasons.join('; ')}`);
  if (!budget.ok) reasons.push(`budget: ${budget.lineCount} lines / ${budget.wordCount} words`);
  if (leaks.length) reasons.push(`leaks: ${leaks.map((l) => l.kind).join(', ')}`);
  if (!roles.equal) reasons.push(`roles ${JSON.stringify(roles.overview)} != project ${JSON.stringify(roles.project)}`);
  // `closedListClaimed` is ADVISORY, not an `ok` gate: it's a 4-phrase regex, and roleSetEquals
  // already catches the real danger (an overview naming 2 of 3 roles). Whether the closed-list is
  // *meaningfully* asserted is the Tier-3 judge's call, not a phrasing match — reported, not gated.
  if (crPoliciesUnchanged === false) reasons.push('Critical Rules / Policies changed across the write');

  return { found: section.found, structure, budget, leaks, roles, crPoliciesUnchanged, ok: reasons.length === 0, reasons };
}
