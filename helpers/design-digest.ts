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
}

/**
 * Is a digest a filled read-back, not the unfilled template? Ready when every required section
 * is present, at least one real (non-`[placeholder]`) screen was extracted, and the palette
 * carries a concrete colour value (not the `#XXXXXX` placeholder).
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

  const ok = missingSections.length === 0 && realScreens >= 1 && hasRealPalette;
  return { ok, missingSections, realScreens, hasRealPalette };
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

/**
 * A re-read reconciles the digest IN PLACE: every decision recorded before must still be present
 * after (decisions override the design files, so re-reading must never quietly drop one).
 */
export function decisionsPreserved(before: string, after: string): DecisionsPreserved {
  const afterBody = digestSections(after)['Your Decisions'] ?? '';
  const dropped = decisionsIn(before).filter((d) => !afterBody.includes(d));
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
