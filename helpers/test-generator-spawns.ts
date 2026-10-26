/**
 * test-generator-spawns — parse a `claude -p --output-format stream-json` transcript and report how BUILD
 * spawned its `test-generator` agents, so Tier-2/Tier-3 can assert the single-agent-per-story contract
 * (build-tests-together, commit 4666e23):
 *   - T3.1: one `test-generator` call per story (distinct stories covered == story count), epic-mocks ∈ {0,1}
 *   - T3.2: NO story gets a separate Vitest agent and a separate Playwright agent (the two-agent baseline)
 *
 * TRANSCRIPT SHAPE (verified against real captures): each JSONL line is one event. A spawn is an
 * `assistant` line whose `message.content[]` holds `{ type:'tool_use', id, name:'Task',
 * input:{ subagent_type, description, prompt }, caller:{ type } }`. The agent's return is a later `user`
 * line with `{ type:'tool_result', tool_use_id, content }` (content is a string OR an array of text blocks).
 *
 * CLASSIFICATION — robust across template versions:
 *   - `subagent_type` is a STRUCTURED field → reliable filter for `test-generator`.
 *   - `mode` and the story number are NOT structured — but the orchestrator writes clean `- mode: <x>` and
 *     `- story: <N>` input lines into the prompt (confirmed in real runs), so we read those. The return
 *     marker (`MOCK DATA READY` / `TESTS WRITTEN` / `BASELINE:`) corroborates when present (26-10), but is
 *     absent in older runs, so it is a fallback, never the sole signal.
 *   - `caller.type === 'direct'` marks a top-level orchestrator spawn; nested sub-agent spawns are excluded.
 *   - Story coverage is de-duplicated by story number, so a resumed/regenerated batch (continue.md B0.2
 *     `:308`) that re-spawns a story does not inflate the count.
 *
 * Pure, string-only (takes the transcript text). No filesystem.
 */

export type TgMode = 'epic-mocks' | 'story' | 'vitest' | 'playwright' | 'unknown';
export type TgReturnMarker = 'MOCK DATA READY' | 'TESTS WRITTEN' | 'BASELINE' | null;

export interface TgSpawn {
  /** The Task tool_use id (unique per spawn). */
  toolUseId: string;
  /** Mode from the prompt's `- mode:` line, corroborated by the return marker. */
  mode: TgMode;
  /** Story number from the prompt's `- story:` line (or description), or null for epic-mocks / unknown. */
  storyKey: string | null;
  /** The spawn's `description` input. */
  description: string;
  /** The agent's return marker, when the version emits one. */
  returnMarker: TgReturnMarker;
  /** True when spawned directly by the orchestrator (caller.type === 'direct' or absent). */
  isTopLevel: boolean;
}

export interface TgSpawnAnalysis {
  /** Top-level `test-generator` spawns, in transcript order. */
  spawns: TgSpawn[];
  /** The `epic-mocks` bootstrap spawns (expected 0 or 1 per epic). */
  epicMocks: TgSpawn[];
  /** Per-story single-agent spawns (`mode: story`). */
  storySpawns: TgSpawn[];
  /** Per-story split spawns (`mode: vitest` / `mode: playwright`) — the two-agent regression signal. */
  splitSpawns: TgSpawn[];
  /** Distinct story numbers covered by story/split spawns. */
  distinctStories: string[];
  /** Story numbers covered by more than one `mode: story` call (resume/dup) — informational. */
  storiesWithMultipleStoryCalls: string[];
  /** 'one-agent-per-story' | 'two-agent-per-story' | 'mixed' | 'none'. */
  verdict: 'one-agent-per-story' | 'two-agent-per-story' | 'mixed' | 'none';
}

function resultText(content: unknown): string {
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .map((b) => (b && typeof b === 'object' && 'text' in b ? String((b as { text?: unknown }).text ?? '') : ''))
      .join('\n');
  }
  return '';
}

function parseMode(prompt: string): TgMode {
  const line = prompt.match(/^\s*-?\s*mode:\s*["'`]?(epic-mocks|story|vitest|playwright)\b/im);
  if (line) return line[1].toLowerCase() as TgMode;
  const inline = prompt.match(/running in\s+["'`]?(epic-mocks|story|vitest|playwright)["'`]?\s+mode/i);
  return inline ? (inline[1].toLowerCase() as TgMode) : 'unknown';
}

function parseStoryKey(prompt: string, description: string): string | null {
  const fromPrompt = prompt.match(/^\s*-?\s*story:\s*(?:Story\s*)?(\d+)/im);
  if (fromPrompt) return fromPrompt[1];
  const fromDesc = description.match(/\bstory\s*(\d+)/i);
  return fromDesc ? fromDesc[1] : null;
}

function parseReturnMarker(text: string): TgReturnMarker {
  if (/MOCK DATA READY/i.test(text)) return 'MOCK DATA READY';
  if (/TESTS WRITTEN/i.test(text)) return 'TESTS WRITTEN';
  if (/^\s*BASELINE:/im.test(text)) return 'BASELINE';
  return null;
}

/** Parse all top-level `test-generator` Task spawns from a stream-json transcript. */
export function parseTestGeneratorSpawns(jsonl: string): TgSpawn[] {
  const lines = jsonl.split(/\r?\n/).filter((l) => l.trim());
  const returns = new Map<string, string>();
  const objs: Array<Record<string, unknown>> = [];
  for (const l of lines) {
    let o: Record<string, unknown>;
    try { o = JSON.parse(l); } catch { continue; }
    objs.push(o);
    const msg = (o.message ?? o) as { content?: unknown };
    if (!Array.isArray(msg.content)) continue;
    for (const b of msg.content as Array<Record<string, unknown>>) {
      if (b.type === 'tool_result' && typeof b.tool_use_id === 'string') {
        returns.set(b.tool_use_id, resultText(b.content));
      }
    }
  }

  const spawns: TgSpawn[] = [];
  for (const o of objs) {
    const msg = (o.message ?? o) as { content?: unknown };
    if (!Array.isArray(msg.content)) continue;
    for (const b of msg.content as Array<Record<string, unknown>>) {
      if (b.type !== 'tool_use' || b.name !== 'Task') continue;
      const input = (b.input ?? {}) as { subagent_type?: string; prompt?: string; description?: string };
      if (input.subagent_type !== 'test-generator') continue;
      const caller = b.caller as { type?: string } | undefined;
      const isTopLevel = !caller || caller.type === 'direct';
      const prompt = input.prompt ?? '';
      const description = input.description ?? '';
      const retText = typeof b.id === 'string' ? returns.get(b.id) ?? '' : '';
      let mode = parseMode(prompt);
      // Corroborate/repair from the return marker when the prompt mode is unknown.
      if (mode === 'unknown') {
        const marker = parseReturnMarker(retText);
        if (marker === 'MOCK DATA READY') mode = 'epic-mocks';
        else if (marker === 'TESTS WRITTEN') mode = 'story';
      }
      spawns.push({
        toolUseId: typeof b.id === 'string' ? b.id : '',
        mode,
        storyKey: mode === 'epic-mocks' ? null : parseStoryKey(prompt, description),
        description,
        returnMarker: parseReturnMarker(retText),
        isTopLevel,
      });
    }
  }
  return spawns;
}

/** Analyze the single-agent-per-story contract from a stream-json transcript. */
export function analyzeTestGeneratorSpawns(jsonl: string): TgSpawnAnalysis {
  const all = parseTestGeneratorSpawns(jsonl);
  // De-duplicate by tool_use id, keep only top-level orchestrator spawns.
  const seen = new Set<string>();
  const spawns = all.filter((s) => {
    if (!s.isTopLevel) return false;
    if (s.toolUseId && seen.has(s.toolUseId)) return false;
    if (s.toolUseId) seen.add(s.toolUseId);
    return true;
  });

  const epicMocks = spawns.filter((s) => s.mode === 'epic-mocks');
  const storySpawns = spawns.filter((s) => s.mode === 'story');
  const splitSpawns = spawns.filter((s) => s.mode === 'vitest' || s.mode === 'playwright');

  const storyKeys = [...storySpawns, ...splitSpawns].map((s) => s.storyKey).filter((k): k is string => k !== null);
  const distinctStories = [...new Set(storyKeys)].sort((a, b) => Number(a) - Number(b) || a.localeCompare(b));

  const storyModeCounts = new Map<string, number>();
  for (const s of storySpawns) if (s.storyKey) storyModeCounts.set(s.storyKey, (storyModeCounts.get(s.storyKey) ?? 0) + 1);
  const storiesWithMultipleStoryCalls = [...storyModeCounts.entries()].filter(([, n]) => n > 1).map(([k]) => k).sort();

  const verdict: TgSpawnAnalysis['verdict'] =
    splitSpawns.length > 0 && storySpawns.length > 0
      ? 'mixed'
      : splitSpawns.length > 0
        ? 'two-agent-per-story'
        : storySpawns.length > 0
          ? 'one-agent-per-story'
          : 'none';

  return { spawns, epicMocks, storySpawns, splitSpawns, distinctStories, storiesWithMultipleStoryCalls, verdict };
}
