/**
 * test-generator-spawns — unit tests for the stream-json transcript parser (build-tests-together).
 * Template-independent: imports the helper directly and reads local ./fixtures/transcripts/ (portable).
 * A final smoke test runs against a REAL captured transcript when one is present in TestResults/.
 *
 * Note: story numbers are unique only WITHIN an epic; the capture for this feature stops after the first
 * epic's B0.2, so de-dup by story number is safe there. The multi-epic smoke test asserts only
 * epic-independent facts (split count, verdict, epic-mocks count).
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { analyzeTestGeneratorSpawns, parseTestGeneratorSpawns } from '../../helpers/test-generator-spawns';

const transcript = (name: string) =>
  fs.readFileSync(path.join(__dirname, 'fixtures', 'transcripts', name), 'utf8');

describe('analyzeTestGeneratorSpawns — one-agent (good)', () => {
  const a = analyzeTestGeneratorSpawns(transcript('one-agent.jsonl'));

  it('verdict is one-agent-per-story with no split spawns', () => {
    expect(a.verdict).toBe('one-agent-per-story');
    expect(a.splitSpawns).toHaveLength(0);
  });
  it('exactly one epic-mocks bootstrap', () => {
    expect(a.epicMocks).toHaveLength(1);
  });
  it('covers each distinct story once, de-duping a resumed re-spawn', () => {
    expect(a.distinctStories).toEqual(['1', '2']);
    expect(a.storySpawns).toHaveLength(3); // story 2 spawned twice (resume)
    expect(a.storiesWithMultipleStoryCalls).toEqual(['2']);
  });
  it('excludes nested (non-direct) spawns and non-test-generator Tasks', () => {
    const ids = a.spawns.map((s) => s.toolUseId);
    expect(ids).not.toContain('tg-nested'); // caller.type === 'subagent'
    expect(ids).not.toContain('dev-1'); // subagent_type developer
    expect(ids).toEqual(['tg-mocks', 'tg-s1', 'tg-s2', 'tg-s2b']);
  });
  it('reads the return marker from both string and array tool_result content', () => {
    const s1 = a.spawns.find((s) => s.toolUseId === 'tg-s1')!; // array content
    const s2 = a.spawns.find((s) => s.toolUseId === 'tg-s2')!; // string content
    expect(s1.returnMarker).toBe('TESTS WRITTEN');
    expect(s2.returnMarker).toBe('TESTS WRITTEN');
    expect(a.epicMocks[0].returnMarker).toBe('MOCK DATA READY');
  });
});

describe('analyzeTestGeneratorSpawns — two-agent (regression)', () => {
  const a = analyzeTestGeneratorSpawns(transcript('two-agent.jsonl'));

  it('verdict is two-agent-per-story; split spawns present, zero story spawns', () => {
    expect(a.verdict).toBe('two-agent-per-story');
    expect(a.splitSpawns).toHaveLength(4);
    expect(a.storySpawns).toHaveLength(0);
  });
  it('still covers 2 distinct stories and one epic-mocks', () => {
    expect(a.distinctStories).toEqual(['1', '2']);
    expect(a.epicMocks).toHaveLength(1);
  });
});

describe('parse robustness', () => {
  it('falls back to the return marker when the prompt has no mode token', () => {
    const jsonl = [
      JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', id: 'x1', name: 'Task', input: { subagent_type: 'test-generator', description: 'd', prompt: 'no mode here\n- story: 3' }, caller: { type: 'direct' } }] } }),
      JSON.stringify({ type: 'user', message: { content: [{ type: 'tool_result', tool_use_id: 'x1', content: 'TESTS WRITTEN: foo' }] } }),
    ].join('\n');
    const [s] = parseTestGeneratorSpawns(jsonl);
    expect(s.mode).toBe('story');
    expect(s.storyKey).toBe('3');
  });
  it('ignores malformed lines and non-content events', () => {
    const jsonl = 'not json\n{"type":"system"}\n' +
      JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', id: 'm', name: 'Task', input: { subagent_type: 'test-generator', description: 'd', prompt: '- mode: epic-mocks' }, caller: { type: 'direct' } }] } });
    const a = analyzeTestGeneratorSpawns(jsonl);
    expect(a.epicMocks).toHaveLength(1);
  });
});

// Real-data smoke test — runs only when a captured transcript is present.
const REAL = path.join(
  __dirname, '..', '..', 'TestResults',
  'minimal-concurrent@dev-main', 'opus', '20260804-090039', 'tier3-live', '20260804-090039-claude.jsonl',
);
describe.skipIf(!fs.existsSync(REAL))('real captured transcript (minimal-concurrent, a two-agent run)', () => {
  const a = analyzeTestGeneratorSpawns(fs.readFileSync(REAL, 'utf8'));
  it('classifies the real split run as two-agent with 4 split spawns and 2 epic-mocks', () => {
    expect(a.verdict).toBe('two-agent-per-story');
    expect(a.splitSpawns).toHaveLength(4);
    expect(a.epicMocks).toHaveLength(2); // 2 epics
    expect(a.storySpawns).toHaveLength(0);
  });
});
