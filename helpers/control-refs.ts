/**
 * control-refs — extract accessible-control references from a generated test file and compare the
 * two files a story's `test-generator` writes (the Vitest `.test.tsx` and the Playwright `.spec.ts`).
 *
 * Feature under test (build-tests-together, commit 4666e23): ONE agent writes both files per story, so a
 * control has the same ROLE and NAME — and is "found the same way" — in both. See
 * test-generator.md:296 ("fix its role and accessible name once … In both files, find each control the
 * same way") and the success criterion :384. The reported regression was a control queried as a radio
 * group in one file and a dropdown in the other.
 *
 * WHAT THIS CHECKS (and the one thing it honestly can't):
 *   - Join key is the control's ACCESSIBLE NAME, normalised. The two files cover DISJOINT acceptance
 *     criteria (coverage is a single tag per AC: vitest | playwright | none — test-generator.md:20), so
 *     a control that appears in both is matched by name, NOT by AC id. For every name present in both
 *     files we assert the set of (strategy, role) signatures matches — this catches:
 *       • role divergence   — getByRole('radio', {name:'Status'})  vs getByRole('combobox', {name:'Status'})
 *       • strategy divergence — getByRole('textbox', {name:'Email'}) vs getByLabel('Email')  ("same way")
 *   - It CANNOT catch same-control / different-name divergence (Vitest 'Priority' vs Playwright
 *     'Priority level') — nothing static ties those two names to one control. That residual is REPORTED
 *     (names in one file only are listed as UNCOMPARED) for a human to eyeball in PROOF.md, never
 *     silently swallowed.
 *   - A story with no shared name is SKIPPED-with-notice (status 'skipped-no-overlap'), never green.
 *   - A file that clearly contains queries but parses to zero refs THROWS (a silent empty map must not
 *     read as a pass).
 *
 * ROBUSTNESS (council-hardened): query tokens inside comments and string literals are MASKED before
 * call-starts are located, so a commented-out or quoted `getByRole(` can't inject a phantom signature
 * (which previously could mask a real divergence or flag a false one). Playwright `locator('role=…')`
 * selectors are extracted too, and names are canonicalised (regex ^/$ anchors + `\`-escapes + string
 * escapes stripped) so `/^Save$/`, `'Save'`, and `'Save \(now\)'` join as the same control.
 *
 * Pure, string-only. No filesystem, no template dependency — the caller reads the two files.
 */

/** How a control was queried. 'role' carries an explicit ARIA role; the rest imply one (or none). */
export type QueryStrategy =
  | 'role'
  | 'label'
  | 'placeholder'
  | 'displayValue'
  | 'text'
  | 'testId'
  | 'altText'
  | 'title';

export interface ControlRef {
  /** The query family used (role / label / testId / …). */
  strategy: QueryStrategy;
  /** Explicit ARIA role for `strategy: 'role'`; null for every other strategy. */
  role: string | null;
  /** Raw accessible name / label text / test-id as written (string or regex source); null if dynamic. */
  name: string | null;
  /** Normalised join key for `name` (lowercased, de-regexed, de-escaped, whitespace-collapsed); null if unresolvable. */
  nameKey: string | null;
  /** True when the name was a RegExp literal (`/save/i`) rather than a string. */
  nameIsPattern: boolean;
  /** False when role/name came from a variable or template literal we can't resolve statically. */
  resolved: boolean;
  /** The matched source snippet, for evidence in PROOF.md. */
  raw: string;
}

/** A (strategy, role) signature string used for set comparison, e.g. "role=combobox" or "label". */
export type Signature = string;

export interface ParityResult {
  /** Normalised names present in BOTH files, with each side's signatures and whether they match. */
  shared: Array<{ nameKey: string; vitest: Signature[]; playwright: Signature[]; match: boolean }>;
  /** The subset of `shared` whose signatures differ — the real defects. */
  mismatches: Array<{ nameKey: string; vitest: Signature[]; playwright: Signature[] }>;
  /** The parity check could not compare these — reported, never counted as a pass. */
  uncompared: {
    vitestOnly: string[];
    playwrightOnly: string[];
    /** Refs whose name could not be resolved to a join key (dynamic variable/template, or no name given). */
    unresolved: ControlRef[];
  };
  /** How many shared names were actually compared. */
  comparedCount: number;
  /** 'match' when every shared control agrees; 'mismatch' when any differ; 'skipped-no-overlap' when none shared. */
  status: 'match' | 'mismatch' | 'skipped-no-overlap';
}

// ---------------------------------------------------------------------------
// Query method → strategy. Covers Testing-Library (getBy/findBy/queryBy, All variants) and Playwright.
// ---------------------------------------------------------------------------

const METHOD_STRATEGY: Record<string, QueryStrategy> = {
  Role: 'role',
  LabelText: 'label',
  PlaceholderText: 'placeholder',
  DisplayValue: 'displayValue',
  Text: 'text',
  TestId: 'testId',
  AltText: 'altText',
  Title: 'title',
};

// Playwright uses getByLabel / getByPlaceholder; Testing-Library uses getByLabelText / getByPlaceholderText.
const METHOD_ALIASES: Record<string, keyof typeof METHOD_STRATEGY> = {
  Label: 'LabelText',
  Placeholder: 'PlaceholderText',
};

/** Matches the start of a query call: getByRole( / findAllByLabelText( / page.getByRole( etc. */
const QUERY_RE =
  /\b(?:get|find|query)(?:All)?By(Role|LabelText|Label|PlaceholderText|Placeholder|DisplayValue|TestId|Text|AltText|Title)\s*\(/g;

/** Matches Playwright `.locator('role=button[name="Save"]')` string selectors (inner quotes allowed). */
const LOCATOR_RE = /\.locator\(\s*(['"`])((?:\\.|(?!\1)[\s\S])*?)\1\s*\)/g;

/**
 * Produce a same-length copy of the source with comment bodies and string/template-literal CONTENTS
 * blanked to spaces, so QUERY_RE finds only real call starts (indices stay aligned with the original).
 */
function maskNonCode(src: string): string {
  const out = src.split('');
  const n = src.length;
  type S = 'code' | 'line' | 'block' | 'sq' | 'dq' | 'tq';
  let state: S = 'code';
  for (let i = 0; i < n; i++) {
    const c = src[i];
    const c2 = src[i + 1];
    if (state === 'code') {
      if (c === '/' && c2 === '/') { state = 'line'; out[i] = ' '; out[i + 1] = ' '; i++; continue; }
      if (c === '/' && c2 === '*') { state = 'block'; out[i] = ' '; out[i + 1] = ' '; i++; continue; }
      if (c === "'") { state = 'sq'; continue; }
      if (c === '"') { state = 'dq'; continue; }
      if (c === '`') { state = 'tq'; continue; }
      continue; // leave code as-is
    }
    if (state === 'line') {
      if (c === '\n') state = 'code';
      else out[i] = ' ';
      continue;
    }
    if (state === 'block') {
      if (c === '*' && c2 === '/') { out[i] = ' '; out[i + 1] = ' '; i++; state = 'code'; }
      else if (c !== '\n') out[i] = ' ';
      continue;
    }
    // inside a string / template literal
    const q = state === 'sq' ? "'" : state === 'dq' ? '"' : '`';
    if (c === '\\') { out[i] = ' '; if (i + 1 < n && src[i + 1] !== '\n') out[i + 1] = ' '; i++; continue; }
    if (c === q) { state = 'code'; continue; }
    if (c !== '\n') out[i] = ' ';
  }
  return out.join('');
}

/** From the index of a '(' return the balanced argument substring (quote- and nest-aware), or null. */
function sliceCallArgs(src: string, openParen: number): string | null {
  let depth = 0;
  let quote: string | null = null;
  for (let i = openParen; i < src.length; i++) {
    const ch = src[i];
    const prev = src[i - 1];
    if (quote) {
      if (ch === quote && prev !== '\\') quote = null;
      continue;
    }
    if (ch === '"' || ch === "'" || ch === '`') { quote = ch; continue; }
    if (ch === '(' || ch === '[' || ch === '{') depth++;
    else if (ch === ')' || ch === ']' || ch === '}') {
      depth--;
      if (depth === 0) return src.slice(openParen + 1, i);
    }
  }
  return null;
}

interface ParsedName {
  name: string | null;
  nameKey: string | null;
  nameIsPattern: boolean;
  resolved: boolean;
}

/** Final normalise for a join key: collapse whitespace, trim, lowercase. */
function normaliseName(raw: string): string {
  return raw.replace(/\s+/g, ' ').trim().toLowerCase();
}

/** Resolve JS string escapes that matter for the accessible name. */
const unescapeString = (s: string): string => s.replace(/\\(['"`\\])/g, '$1');

/** Strip a regex name's ^/$ anchors and `\`-escapes so it joins with the equivalent string name. */
function canonicaliseRegexSource(s: string): string {
  return s
    .replace(/^\^/, '')
    .replace(/\$$/, '')
    .replace(/\\([.*+?^${}()|[\]\\/])/g, '$1');
}

/** Parse a string- or regex-literal name value. Returns resolved:false for anything dynamic. */
function parseNameValue(value: string): ParsedName {
  const v = value.trim();
  // String literal: '…' | "…" | `…` (reject template literals that interpolate).
  const str = v.match(/^(['"`])([\s\S]*)\1$/);
  if (str) {
    if (str[1] === '`' && /\$\{/.test(str[2])) {
      return { name: null, nameKey: null, nameIsPattern: false, resolved: false };
    }
    return { name: str[2], nameKey: normaliseName(unescapeString(str[2])), nameIsPattern: false, resolved: true };
  }
  // Regex literal: /…/flags
  const re = v.match(/^\/((?:\\.|[^/])+)\/[a-z]*$/i);
  if (re) {
    return { name: re[1], nameKey: normaliseName(canonicaliseRegexSource(re[1])), nameIsPattern: true, resolved: true };
  }
  // Variable, call, template with ${…}, etc. — unresolved.
  return { name: null, nameKey: null, nameIsPattern: false, resolved: false };
}

/** Pull the top-level first argument out of a call's arg string (before the first top-level comma). */
function firstArg(args: string): string {
  let depth = 0;
  let quote: string | null = null;
  for (let i = 0; i < args.length; i++) {
    const ch = args[i];
    const prev = args[i - 1];
    if (quote) {
      if (ch === quote && prev !== '\\') quote = null;
      continue;
    }
    if (ch === '"' || ch === "'" || ch === '`') { quote = ch; continue; }
    if (ch === '(' || ch === '[' || ch === '{') depth++;
    else if (ch === ')' || ch === ']' || ch === '}') depth--;
    else if (ch === ',' && depth === 0) return args.slice(0, i);
  }
  return args;
}

/** Extract the `name:` option value from an options object inside the arg string, if any. */
function nameOption(args: string): string | null {
  const m = args.match(/\bname\s*:\s*(\/(?:\\.|[^/])+\/[a-z]*|(['"`])(?:\\.|[^\\])*?\2|[A-Za-z_$][\w$.]*)/);
  return m ? m[1] : null;
}

/** Build a role-strategy ControlRef from a role literal + optional name literal. */
function roleRef(roleArg: string, nameRaw: string | null, raw: string): ControlRef {
  const roleParsed = parseNameValue(roleArg);
  const role = roleParsed.resolved && !roleParsed.nameIsPattern ? roleParsed.name : null;
  const nm = nameRaw
    ? parseNameValue(nameRaw)
    : { name: null, nameKey: null, nameIsPattern: false, resolved: true };
  return {
    strategy: 'role',
    role,
    name: nm.name,
    nameKey: nm.nameKey,
    nameIsPattern: nm.nameIsPattern,
    resolved: role !== null && (nameRaw === null || nm.resolved),
    raw,
  };
}

/** Parse a Playwright role selector body like `role=button[name="Save"]`. */
function parseRoleSelector(body: string, raw: string): ControlRef | null {
  const roleM = body.match(/^\s*role=([a-zA-Z]+)/);
  if (!roleM) return null;
  const nameM = body.match(/\[name=\s*(\/(?:\\.|[^/])+\/[a-z]*|"[^"]*"|'[^']*')/);
  const nm = nameM
    ? parseNameValue(nameM[1])
    : { name: null, nameKey: null, nameIsPattern: false, resolved: true };
  return {
    strategy: 'role',
    role: roleM[1],
    name: nm.name,
    nameKey: nm.nameKey,
    nameIsPattern: nm.nameIsPattern,
    resolved: nm.resolved,
    raw,
  };
}

/**
 * Extract every accessible-control reference from a test file's source.
 * @throws if the source contains query/locator calls but none could be parsed (a silent empty map is a bug).
 */
export function extractControlRefs(source: string): ControlRef[] {
  const masked = maskNonCode(source);
  const refs: ControlRef[] = [];
  let sawQuery = false;

  QUERY_RE.lastIndex = 0;
  let m: RegExpExecArray | null;
  while ((m = QUERY_RE.exec(masked)) !== null) {
    sawQuery = true;
    const methodKey = (METHOD_ALIASES[m[1]] ?? m[1]) as keyof typeof METHOD_STRATEGY;
    const strategy = METHOD_STRATEGY[methodKey];
    const openParen = QUERY_RE.lastIndex - 1;
    const args = sliceCallArgs(source, openParen);
    if (args === null) continue;
    const raw = `${m[0]}${args})`.replace(/\s+/g, ' ').trim();

    if (strategy === 'role') {
      refs.push(roleRef(firstArg(args), nameOption(args), raw));
    } else {
      const nm = parseNameValue(firstArg(args));
      refs.push({ strategy, role: null, name: nm.name, nameKey: nm.nameKey, nameIsPattern: nm.nameIsPattern, resolved: nm.resolved, raw });
    }
  }

  // Playwright role selectors: .locator('role=button[name="Save"]'). Runs on the ORIGINAL source —
  // the selector text lives in a string the masker blanked, so masked would hide it.
  LOCATOR_RE.lastIndex = 0;
  let L: RegExpExecArray | null;
  while ((L = LOCATOR_RE.exec(source)) !== null) {
    const body = L[2];
    if (!/^\s*role=/.test(body)) continue;
    sawQuery = true;
    const ref = parseRoleSelector(body, `.locator('${body}')`);
    if (ref) refs.push(ref);
  }

  if (sawQuery && refs.length === 0) {
    throw new Error('control-refs: source contains query/locator calls but none parsed — extractor bug, not a pass');
  }
  return refs;
}

/** The (strategy, role) signature used for set comparison. */
function signature(ref: ControlRef): Signature {
  return ref.strategy === 'role' ? `role=${ref.role ?? '?'}` : ref.strategy;
}

/** Build name → sorted unique signature list, skipping unresolved names. */
function byName(refs: ControlRef[]): Map<string, Set<Signature>> {
  const map = new Map<string, Set<Signature>>();
  for (const r of refs) {
    if (r.nameKey === null) continue;
    const set = map.get(r.nameKey) ?? new Set<Signature>();
    set.add(signature(r));
    map.set(r.nameKey, set);
  }
  return map;
}

const sorted = (s: Set<Signature>): Signature[] => [...s].sort();
const setsEqual = (a: Set<Signature>, b: Set<Signature>): boolean =>
  a.size === b.size && [...a].every((x) => b.has(x));

/**
 * Compare the two files a story's single agent wrote. Returns a structured parity result:
 * shared controls (and whether they agree), mismatches (the defects), and everything uncompared.
 */
export function compareControls(vitestSrc: string, playwrightSrc: string): ParityResult {
  const vRefs = extractControlRefs(vitestSrc);
  const pRefs = extractControlRefs(playwrightSrc);
  const v = byName(vRefs);
  const p = byName(pRefs);

  const shared: ParityResult['shared'] = [];
  const mismatches: ParityResult['mismatches'] = [];
  for (const [nameKey, vSigs] of v) {
    const pSigs = p.get(nameKey);
    if (!pSigs) continue;
    const match = setsEqual(vSigs, pSigs);
    const row = { nameKey, vitest: sorted(vSigs), playwright: sorted(pSigs), match };
    shared.push(row);
    if (!match) mismatches.push({ nameKey, vitest: row.vitest, playwright: row.playwright });
  }

  const vitestOnly = [...v.keys()].filter((k) => !p.has(k)).sort();
  const playwrightOnly = [...p.keys()].filter((k) => !v.has(k)).sort();
  const unresolved = [...vRefs, ...pRefs].filter((r) => r.nameKey === null);

  const status: ParityResult['status'] =
    mismatches.length > 0 ? 'mismatch' : shared.length === 0 ? 'skipped-no-overlap' : 'match';

  return {
    shared,
    mismatches,
    uncompared: { vitestOnly, playwrightOnly, unresolved },
    comparedCount: shared.length,
    status,
  };
}
