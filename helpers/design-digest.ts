/**
 * Deterministic assertions for the build-from-design traces (Tier-3 #14/#15).
 *
 * The design feature's *reading* is live (an AI comprehends the files), but the artifacts it
 * leaves are deterministic: a normalized digest at `generated-docs/design/digest.md`, a
 * "Your Decisions" record that survives a re-read, and a scoped rebuild that touches only the
 * screens the user named. These pure functions assert those traces. They get their good/broken
 * cases as Tier-1 unit tests over synthetic scaffolds (and the REAL digest template as the
 * canonical "unfilled" broken case); the eventual live run exercises the same checks over a
 * captured run — the three-tier split the `/plan` scenarios use (workflow-tests.md §8).
 *
 * No template access here — callers pass the markdown/paths. Format is modelled on
 * `.claude/templates/design-digest.md`: H2 sections, `[bracketed]` placeholders, `#XXXXXX`.
 */

/** Split a digest into its `## ` sections → { title: body }. Text before the first H2 is dropped. */
export function digestSections(md: string): Record<string, string> {
  const out: Record<string, string> = {};
  let current: string | null = null;
  const buf: string[] = [];
  const flush = () => {
    if (current !== null) out[current] = buf.join('\n').trim();
    buf.length = 0;
  };
  for (const line of md.split(/\r?\n/)) {
    const h2 = /^##\s+(.+?)\s*$/.exec(line);
    if (h2 && !line.startsWith('###')) {
      flush();
      current = h2[1].trim();
    } else if (current !== null) {
      buf.push(line);
    }
  }
  flush();
  return out;
}

const REQUIRED_SECTIONS = ['Your Decisions', 'Screens', 'Palette & Typography', 'Uncertainties'];

export interface DigestReadiness {
  ok: boolean;
  missingSections: string[];
  realScreens: number;
  hasRealPalette: boolean;
  realUncertainties: number;
}

/**
 * Is a digest a filled read-back, not the unfilled template? Ready when every required section
 * is present, at least one real (non-`[placeholder]`) screen was extracted, the palette carries a
 * concrete colour value (not the `#XXXXXX` placeholder), and Uncertainties has at least one real
 * item.
 *
 * The Uncertainties requirement is a FILLED-vs-TEMPLATE discriminator, not a claim that every
 * design must be ambiguous: the empty template's Uncertainties holds only guidance prose (no real
 * bullets), while a real read-back — per the design-interpreter's "never omit Uncertainties" /
 * "state what you couldn't determine" contract — always surfaces at least its assumptions. It
 * fixes the earlier inert gate that checked only that the section EXISTED (an empty section passed).
 */
export function digestReadyForIntake(md: string): DigestReadiness {
  const sections = digestSections(md);
  const missingSections = REQUIRED_SECTIONS.filter((s) => !(s in sections));

  const screensBody = sections['Screens'] ?? '';
  const realScreens = (screensBody.match(/^###\s+(.+)$/gm) ?? [])
    .map((h) => h.replace(/^###\s+/, '').trim())
    // A `### [Screen name]` heading is an unfilled placeholder; a real one has an actual name.
    .filter((name) => name.length > 0 && !/^\[.*\]$/.test(name)).length;

  const paletteBody = sections['Palette & Typography'] ?? '';
  const hasRealPalette = /#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?\b/.test(paletteBody.replace(/#X{3,6}/gi, ''));

  const realUncertainties = uncertaintiesItems(md).length;

  const ok = missingSections.length === 0 && realScreens >= 1 && hasRealPalette && realUncertainties >= 1;
  return { ok, missingSections, realScreens, hasRealPalette, realUncertainties };
}

/** The real (non-placeholder, non-"none") list items under `## Uncertainties`. */
export function uncertaintiesItems(md: string): string[] {
  const body = digestSections(md)['Uncertainties'] ?? '';
  return body
    .split(/\r?\n/)
    .filter((l) => /^\s*[-*]\s+/.test(l))
    .map((l) => l.replace(/^\s*[-*]\s+/, '').replace(/\*\*/g, '').trim())
    .filter((l) => l.length > 0 && !/^\[.*\]$/.test(l) && !/^(none|nothing)\b/i.test(l));
}

/**
 * Is a specific can't-use topic surfaced under Uncertainties rather than silently dropped? This is
 * the AC5 teeth: given a design element the workflow couldn't use, the digest names it.
 */
export function surfacesUncertainty(md: string, pattern: RegExp): boolean {
  return uncertaintiesItems(md).some((item) => pattern.test(item));
}

/** The non-empty, non-placeholder list items under `## Your Decisions`. */
export function decisionsIn(md: string): string[] {
  const body = digestSections(md)['Your Decisions'] ?? '';
  return body
    .split(/\r?\n/)
    .map((l) => l.replace(/^\s*[-*]\s+/, '').trim())
    .filter((l) => l.length > 0 && !/^\[.*\]$/.test(l) && !/nothing (yet|here)/i.test(l));
}

export interface DecisionsPreserved {
  ok: boolean;
  dropped: string[];
}

/** The stable topic of a decision: its leading `**bold**` label, else the whole line. */
export function decisionKey(item: string): string {
  const m = /^\*\*(.+?)\*\*/.exec(item.trim());
  return (m ? m[1] : item).trim();
}

/**
 * A re-read reconciles the digest IN PLACE: every decision recorded before must still be present
 * after (decisions override the design files, so re-reading must never quietly drop one).
 *
 * "Present" means the decision's TOPIC survives — reconciled wording is expected and fine (the
 * digest updates a decision in place, e.g. "New task" → "Add task", and tells you what moved). A
 * DROPPED decision loses its topic entirely. So match on the stable key, not the verbatim line —
 * an exact-line match would wrongly flag every legitimately-reconciled decision as dropped.
 */
export function decisionsPreserved(before: string, after: string): DecisionsPreserved {
  const afterBody = digestSections(after)['Your Decisions'] ?? '';
  const dropped = decisionsIn(before).filter((d) => !afterBody.includes(decisionKey(d)));
  return { ok: dropped.length === 0, dropped };
}

export interface ScopeResult {
  ok: boolean;
  stray: string[];
}

/**
 * A design update rebuilds only the screens the user named: every changed path must match one of
 * the allowed patterns. A path outside them is scope creep (an un-named screen changed).
 */
export function changesScopedTo(changedPaths: string[], allowed: (RegExp | string)[]): ScopeResult {
  const matches = (p: string) => allowed.some((a) => (a instanceof RegExp ? a.test(p) : p.includes(a)));
  const stray = changedPaths.filter((p) => !matches(p));
  return { ok: stray.length === 0, stray };
}

// ── Navigability (AC3): every designed screen has a live route to move through ───────────────

/** Real (non-placeholder) screen names — the `### ` headings under `## Screens`. */
export function screenNames(md: string): string[] {
  const body = digestSections(md)['Screens'] ?? '';
  return (body.match(/^###\s+(.+)$/gm) ?? [])
    .map((h) => h.replace(/^###\s+/, '').trim())
    .filter((n) => n.length > 0 && !/^\[.*\]$/.test(n));
}

/**
 * The Next.js app-router URL a `page.tsx` file serves: everything under `app/`, with route groups
 * `(group)/` dropped and `/page.tsx` removed. `app/(app)/tasks/[id]/page.tsx` → `/tasks/[id]`;
 * `app/page.tsx` → `/`. Returns null for a non-route file.
 */
export function routeForPageFile(file: string): string | null {
  const p = file.replace(/\\/g, '/');
  const i = p.lastIndexOf('/app/');
  const appRel = i >= 0 ? p.slice(i + '/app/'.length) : p.startsWith('app/') ? p.slice('app/'.length) : null;
  if (appRel === null || !/(^|\/)page\.[jt]sx?$/.test(appRel)) return null;
  const segs = appRel.replace(/\/?page\.[jt]sx?$/, '').split('/').filter((s) => s && !/^\(.*\)$/.test(s));
  return '/' + segs.join('/');
}

/** The distinct route URLs implied by a list of files (page.tsx files only). */
export function appRoutePaths(files: string[]): string[] {
  return [...new Set(files.map(routeForPageFile).filter((r): r is string => r !== null))];
}

/**
 * AC3 navigability: given an authored screen→route map (which designed screen lives at which URL)
 * and the app's real routes, return the screens whose route is missing — a screen with nowhere to
 * live means the user can't move to it. Empty = every designed screen is reachable.
 */
export function unroutedScreens(screenToRoute: Record<string, string>, routePaths: string[]): string[] {
  const routes = new Set(routePaths);
  return Object.entries(screenToRoute)
    .filter(([, route]) => !routes.has(route))
    .map(([screen]) => screen);
}
