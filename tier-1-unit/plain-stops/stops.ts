/**
 * Plain-language stops — Tier 1 static detectors (updated template @ 18-09-2026).
 *
 * The feature reworks every point where the workflow STOPS to ask the user something so the
 * question is plain and actionable. These are pure functions over file *content*, tested
 * against inline fixtures (the real contract) and run over the real template as a regression.
 *
 * Scoping (per the council): a command file is INSTRUCTION prose, not user output. So the
 * phrase checks run only over the EXTRACTED stop strings (question text + option labels the
 * user actually sees), never the whole file. Whether a stop READS plainly is a live/judge
 * call, NOT done here — these are red tripwires (necessary, not sufficient) + doc gates.
 *
 * Not a *.test.ts file, so Vitest never collects it as a suite.
 */

const norm = (s: string): string => s.replace(/\s+/g, ' ').trim();
const listItem = (l: string): RegExpExecArray | null => /^(\s*)(?:[-*]|\d+\.)\s/.exec(l);
const STRUCTURAL = /^(header|question|options)\b/i;

// ---------------------------------------------------------------------------
// Stop extractor
// ---------------------------------------------------------------------------

export interface Stop {
  raw: string;
  line: number; // 1-based line of the AskUserQuestion line
  strings: string[]; // user-facing strings: quoted text + bold option labels (whitespace-normalised)
}

/**
 * A line OPENS a stop only if it invokes AskUserQuestion AND either ends with a colon (an
 * intro to a following menu) or carries a quote after the call (an inline question). A bare
 * prose mention (e.g. "Present approvals via `AskUserQuestion`.") is NOT a stop.
 */
function opensStop(line: string): boolean {
  const k = line.indexOf('AskUserQuestion');
  if (k === -1) return false;
  return /:\s*$/.test(line) || /"/.test(line.slice(k));
}

/**
 * Extract every AskUserQuestion stop and its user-facing strings.
 *  - Intro-colon menus: capture the following list; stop at a sibling list item at a LOWER
 *    indent (a different branch), a non-indented paragraph, a heading, or the list's end.
 *  - Inline stops: capture only the wrapped paragraph — a following list item / blank / heading
 *    ends it (so instruction steps below an inline stop aren't swallowed).
 * Strings = quoted "…" text (anywhere in the block) + **bold** labels that LEAD a list item
 * (not arbitrary emphasis), minus the structural Header/Question/Options labels.
 */
export function extractStops(md: string): Stop[] {
  const lines = md.split(/\r?\n/);
  const stops: Stop[] = [];
  for (let i = 0; i < lines.length; i++) {
    if (!opensStop(lines[i])) continue;
    const block: string[] = [lines[i]];
    let j = i + 1;
    if (/:\s*$/.test(lines[i])) {
      let menuIndent: number | null = null;
      for (; j < lines.length; j++) {
        const l = lines[j];
        if (/^#{1,6}\s/.test(l)) break;
        if (l.trim() === '') {
          let k = j + 1;
          while (k < lines.length && lines[k].trim() === '') k++;
          const nxt = lines[k] ?? '';
          const nl = listItem(nxt);
          const stillMenu =
            (nl && (menuIndent === null || nl[1].length >= menuIndent)) || /^\s{2,}\S/.test(nxt);
          if (stillMenu) { block.push(l); continue; }
          break;
        }
        const li = listItem(l);
        if (li) {
          const ind = li[1].length;
          if (menuIndent === null) menuIndent = ind;
          else if (ind < menuIndent) break;
          block.push(l);
          continue;
        }
        if (/^\s+\S/.test(l)) { block.push(l); continue; }
        break;
      }
    } else {
      for (; j < lines.length; j++) {
        const l = lines[j];
        if (l.trim() === '' || /^#{1,6}\s/.test(l) || listItem(l)) break;
        block.push(l);
      }
    }
    const raw = block.join('\n');
    const set = new Set<string>();
    for (const m of raw.matchAll(/"([^"]+)"/g)) set.add(norm(m[1]));
    for (const l of block) {
      const bm = /^\s*(?:[-*]|\d+\.)\s+\*\*([^*]+)\*\*/.exec(l);
      if (bm) {
        const s = norm(bm[1]);
        if (!STRUCTURAL.test(s) && !s.endsWith(':')) set.add(s);
      }
    }
    stops.push({ raw, line: i + 1, strings: [...set].filter(Boolean) });
    i = j - 1;
  }
  return stops;
}

// ---------------------------------------------------------------------------
// AC2 red tripwires — developer-facing phrasing must be gone from stop strings
// ---------------------------------------------------------------------------

export const BAD_STOP_PHRASES: RegExp[] = [
  /walk me through the issue/i,
  /diagnose locally/i,
  /mark non-routable/i,
  /force merge anyway/i,
  /manual intervention needed/i,
  /\b\d+ manual-test fix cycles\b/i,
  /\bhalt\b/i,
];

export interface StopOffender {
  line: number;
  string: string;
  phrase: string;
}

/** Bad developer-facing phrases found in any stop's user-facing strings (empty = clean). */
export function findBadPhrasesInStops(md: string): StopOffender[] {
  const out: StopOffender[] = [];
  for (const stop of extractStops(md)) {
    for (const s of stop.strings) {
      for (const rx of BAD_STOP_PHRASES) {
        if (rx.test(s)) out.push({ line: stop.line, string: s, phrase: rx.source });
      }
    }
  }
  return out;
}

export const SLUG_IN_STOP = /<slug>|story-<n>-<slug>|epic\/<slug>/i;

/** Stop strings that leak a slug placeholder instead of a plain name (empty = clean). */
export function findSlugInStops(md: string): StopOffender[] {
  const out: StopOffender[] = [];
  for (const stop of extractStops(md)) {
    for (const s of stop.strings) {
      if (SLUG_IN_STOP.test(s)) out.push({ line: stop.line, string: s, phrase: SLUG_IN_STOP.source });
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// AC3 — forbidden vocabulary in the user-facing docs
// ---------------------------------------------------------------------------

export interface VocabHit {
  line: number;
  term: string;
}

/**
 * Blank out inline code and LANGUAGE-TAGGED fenced blocks (```bash/```json/…), preserving
 * line count. Untagged fences (often user-facing OUTPUT examples) stay scannable — a `halt`
 * shown to the user inside an output block must still be caught.
 */
function stripCode(md: string): string {
  const noTagged = md.replace(/```[a-zA-Z][\w-]*\r?\n[\s\S]*?```/g, (b) => b.replace(/[^\n]/g, ' '));
  return noTagged.replace(/`[^`\n]+`/g, (m) => ' '.repeat(m.length));
}

/**
 * Old-behaviour vocabulary in text a user reads: `halt*`, `tier 4`/`tier four`, and the
 * developer-message sense of `verbatim`. Carve-outs: Tier 1/2/3 (only 4 is banned) and the
 * legitimate "verbatim log(s)" (a build-report feature).
 */
export function findForbiddenDocVocab(md: string): VocabHit[] {
  const hits: VocabHit[] = [];
  stripCode(md).split(/\r?\n/).forEach((line, idx) => {
    const ln = idx + 1;
    for (const m of line.matchAll(/\bhalt\w*/gi)) hits.push({ line: ln, term: m[0] });
    for (const m of line.matchAll(/tier[\s-]*(?:4|four)\b/gi)) hits.push({ line: ln, term: m[0] });
    for (const m of line.matchAll(/\bverbatim\b/gi)) {
      if (/^\s+logs?\b/i.test(line.slice((m.index ?? 0) + m[0].length))) continue; // "verbatim log(s)" carve-out
      hits.push({ line: ln, term: m[0] });
    }
  });
  return hits;
}

// ---------------------------------------------------------------------------
// AC3 — links must resolve (extraction only; fs in the test)
// ---------------------------------------------------------------------------

export interface DocLink {
  line: number;
  target: string;
}

export function extractMarkdownLinks(md: string): DocLink[] {
  const out: DocLink[] = [];
  md.split(/\r?\n/).forEach((line, idx) => {
    for (const m of line.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) out.push({ line: idx + 1, target: m[1].trim() });
  });
  return out;
}

/** A link target we can/should resolve to a file (skip any URI scheme, protocol-relative,
 * pure anchors, placeholders, and generated paths — testing only the path part). */
export function isResolvableLinkTarget(target: string): boolean {
  if (/^[a-z][a-z0-9+.-]*:/i.test(target) || target.startsWith('//')) return false; // any scheme / protocol-relative
  const pathPart = target.split(/[#?]/)[0];
  if (!pathPart) return false; // pure anchor / query
  if (pathPart.includes('<') || pathPart.includes('generated-docs/')) return false; // placeholder / generated
  return true;
}

// ---------------------------------------------------------------------------
// Must-survive — correct existing behaviour the rework must not delete
// ---------------------------------------------------------------------------

/** The tick-persistence rule (only affected tests unticked; previously-passed stay ticked). */
export function hasTickPersistence(continueMd: string): boolean {
  return /uncheck only the tests the fix affected/i.test(continueMd) || /carry those ticks forward/i.test(continueMd);
}
