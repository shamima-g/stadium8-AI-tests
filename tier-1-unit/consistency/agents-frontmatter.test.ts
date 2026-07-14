/**
 * Static consistency check — every .claude/agents/*.md has valid YAML frontmatter.
 *
 * Required fields: name, description, model (optional), tools (optional).
 * Also checks that every agent is referenced in .claude/agents/README.md.
 */

import { it, expect } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import fs from 'node:fs';
import path from 'node:path';
import matter from 'gray-matter';
import { REPO_ROOT } from '../../helpers';

const AGENTS_DIR = path.join(REPO_ROOT, '.claude', 'agents');
const AGENTS_README = path.join(AGENTS_DIR, 'README.md');

function listAgentFiles(): string[] {
  return fs.readdirSync(AGENTS_DIR)
    .filter(f => f.endsWith('.md'))
    .filter(f => !f.startsWith('_')) // skip _agent-template.md
    .filter(f => f !== 'README.md')
    .filter(f => f !== 'tone-guide.md'); // not an agent definition
}

describe('agent frontmatter — every agent has required fields', () => {
  const files = listAgentFiles();
  expect(files.length).toBeGreaterThan(5); // sanity: we have real agents

  for (const file of files) {
    it(`PASS: ${file} has valid frontmatter with name + description`, () => {
      const content = fs.readFileSync(path.join(AGENTS_DIR, file), 'utf8');
      const parsed = matter(content);
      expect(parsed.data, `${file} must have YAML frontmatter`).toBeDefined();
      expect(typeof parsed.data.name, `${file}.name must be a string`).toBe('string');
      expect(typeof parsed.data.description, `${file}.description must be a string`).toBe('string');
      expect(parsed.data.description.length).toBeGreaterThan(20);
    });
  }
});

describe('agent frontmatter — name matches filename', () => {
  const files = listAgentFiles();

  for (const file of files) {
    it(`PASS: name in ${file} matches the filename stem`, () => {
      const content = fs.readFileSync(path.join(AGENTS_DIR, file), 'utf8');
      const parsed = matter(content);
      const stem = file.replace(/\.md$/, '');
      expect(parsed.data.name).toBe(stem);
    });
  }
});

describe('agent README consistency', () => {
  it('PASS: every agent file has a matching entry in README.md', () => {
    const readme = fs.readFileSync(AGENTS_README, 'utf8');
    const files = listAgentFiles();

    const missing: string[] = [];
    for (const file of files) {
      const stem = file.replace(/\.md$/, '');
      if (!readme.includes(stem)) {
        missing.push(stem);
      }
    }
    expect(missing, `Agents missing from README: ${missing.join(', ')}`).toEqual([]);
  });

  it('FAIL: README does not list phantom agents that don\'t exist on disk', () => {
    const readme = fs.readFileSync(AGENTS_README, 'utf8');
    const files = new Set(listAgentFiles().map(f => f.replace(/\.md$/, '')));

    // Collect filenames mentioned in README as markdown links to agent files
    const mentioned = new Set<string>();
    for (const m of readme.matchAll(/\[[^\]]+\]\(([a-z0-9-]+)\.md\)/g)) {
      mentioned.add(m[1]);
    }

    const phantoms = [...mentioned].filter(name =>
      !files.has(name)
      && name !== 'README'
      && name !== '_agent-template'
      && name !== 'tone-guide'
    );
    expect(phantoms, `README mentions non-existent agents: ${phantoms.join(', ')}`).toEqual([]);
  });
});

const VALID_MODELS = new Set(['haiku', 'sonnet', 'opus']);

describe('agent frontmatter — model / tools / color are well-formed', () => {
  const files = listAgentFiles();

  for (const file of files) {
    it(`PASS: ${file} has a valid model, non-empty tools, and a colour`, () => {
      const parsed = matter(fs.readFileSync(path.join(AGENTS_DIR, file), 'utf8'));
      const { model, tools, color } = parsed.data as { model?: unknown; tools?: unknown; color?: unknown };

      // model, when present, must be one of the short model tiers.
      if (model !== undefined) {
        expect(VALID_MODELS.has(String(model)), `${file}.model="${String(model)}" must be one of ${[...VALID_MODELS].join(', ')}`).toBe(true);
      }
      // tools, when present, must be a non-empty comma-list string or a non-empty array.
      if (tools !== undefined) {
        const ok = (typeof tools === 'string' && tools.trim().length > 0) || (Array.isArray(tools) && tools.length > 0);
        expect(ok, `${file}.tools must be a non-empty string or array`).toBe(true);
      }
      // color, when present, must be a non-empty string.
      if (color !== undefined) {
        expect(typeof color === 'string' && color.trim().length > 0, `${file}.color must be a non-empty string`).toBe(true);
      }
    });
  }
});

describe('agent README — referenced scripts exist on disk', () => {
  it('PASS: every backticked *.js script named in README.md resolves under .claude/scripts/', () => {
    const readme = fs.readFileSync(AGENTS_README, 'utf8');
    // Only backticked tokens — avoids false hits on ".js" inside "state.json" in prose.
    const referenced = new Set<string>();
    for (const m of readme.matchAll(/`([a-zA-Z0-9_./-]+\.js)`/g)) referenced.add(m[1]);
    expect(referenced.size, 'expected README to reference at least one script').toBeGreaterThan(0);

    const missing = [...referenced].filter(
      (rel) => !fs.existsSync(path.join(REPO_ROOT, '.claude', 'scripts', rel)),
    );
    expect(missing, `README references scripts that don't exist under .claude/scripts/: ${missing.join(', ')}`).toEqual([]);
  });
});
