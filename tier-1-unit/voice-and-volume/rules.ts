/**
 * S8-134-145 — "Voice and volume" output-discipline rules (Tier 1, static).
 *
 * Pure functions, one concern each, decoupled from the filesystem so they can be
 * tested against known-good / known-bad fixtures deterministically (the rule is the
 * unit under test, not "what the template happens to contain right now"). The test
 * file feeds these inline samples AND runs the same functions over the real template
 * under `TEMPLATE_DIR` — that regression scan skips visibly when no template is
 * present, so a missing template can't show a vacuous green.
 *
 * These also produce the two source-of-truth name lists (agent names, phase names)
 * that Tier 2's leak scan consumes — derived from the template, never hand-copied,
 * so they can't rot when the workflow renames a phase or an agent.
 *
 * Not a *.test.ts file, so Vitest never collects it as a suite.
 */

// ---------------------------------------------------------------------------
// Source-of-truth name lists (derived from the template, for Tier 2 to reuse)
// ---------------------------------------------------------------------------

/**
 * Agent names, from the `.claude/agents/*.md` filenames. `README.md` is not an
 * agent. e.g. "developer.md" -> "developer".
 */
export function agentNamesFromFilenames(filenames: string[]): string[] {
  return filenames
    .filter((n) => n.endsWith('.md') && n.toLowerCase() !== 'readme.md')
    .map((n) => n.replace(/\.md$/, ''))
    .sort();
}

/**
 * The phase names, parsed out of the `EPIC_PHASES = Object.freeze([ ... ])` block
 * in `scripts/lib/epic-state.js`. We parse rather than import so the check never
 * executes template code and works the same on any checkout.
 * Returns [] when the block isn't found.
 */
export function extractEpicPhases(epicStateJs: string): string[] {
  const block = epicStateJs.match(/EPIC_PHASES\s*=\s*Object\.freeze\(\s*\[([\s\S]*?)\]\s*\)/);
  if (!block) return [];
  const items = block[1].match(/'([^']+)'|"([^"]+)"/g) ?? [];
  return items.map((s) => s.slice(1, -1));
}

// ---------------------------------------------------------------------------
// The shared rule is present and complete (orchestrator-rules.md)
// ---------------------------------------------------------------------------

export interface RulePresence {
  section: boolean; // the "Voice and volume" heading
  threeKinds: boolean; // "every message is a decision, a result, or a progress marker"
  neverShown: boolean; // the "Never shown:" list
  carveOut: boolean; // the single carve-out
}

/** Which pieces of the Voice-and-volume rule are present in the given content. */
export function checkVoiceAndVolume(content: string): RulePresence {
  return {
    section: /^#{1,6}\s*voice and volume\b/im.test(content),
    threeKinds:
      /every message is a decision, a result, or a progress marker/i.test(content),
    neverShown: /never shown\s*:/i.test(content),
    carveOut: /carve-?out/i.test(content),
  };
}

/** The Voice-and-volume rule pieces that are missing (empty = complete). */
export function missingRuleParts(content: string): Array<keyof RulePresence> {
  const p = checkVoiceAndVolume(content);
  return (Object.keys(p) as Array<keyof RulePresence>).filter((k) => !p[k]);
}

// ---------------------------------------------------------------------------
// The three governed commands load the rule verbatim
// ---------------------------------------------------------------------------

/**
 * True when a command *reads the rule in* (not merely links to it). The three
 * orchestrator commands `cat` it at the top of their body; a passing hyperlink
 * elsewhere is not the same as loading it, so we require the `cat` load.
 */
export function loadsSharedRule(commandContent: string): boolean {
  // `cat` at a word boundary (not `wildcat`), quoted or unquoted path.
  return /(^|\s)cat\s+["']?[^"'\n]*orchestrator-rules\.md/im.test(commandContent);
}

/** The three commands that must load the shared rule. */
export const GOVERNED_COMMANDS = ['start', 'continue', 'plan'] as const;

// ---------------------------------------------------------------------------
// Agent-return exception: developer/test-generator blocks (AC3, accepted)
// ---------------------------------------------------------------------------

/** True when the agent's return block carries the "(For the workflow only)" marker. */
export function hasWorkflowOnlyMarker(agentContent: string): boolean {
  return /\(for the workflow only\)/i.test(agentContent);
}

/**
 * True when the agent file still contains the stale "shown to the user verbatim"
 * wording — a known leftover that contradicts the "for the workflow only" intent
 * and is slated for removal by the engineer.
 */
export function hasVerbatimLeftover(agentContent: string): boolean {
  return /shown to the user verbatim/i.test(agentContent);
}
