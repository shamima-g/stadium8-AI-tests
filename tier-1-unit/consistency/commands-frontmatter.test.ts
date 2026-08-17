/**
 * Static consistency check — every .claude/commands/*.md has valid YAML frontmatter
 * with a `description` field (required by Claude Code's slash-command loader).
 */

import { it, expect } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import fs from 'node:fs';
import path from 'node:path';
import matter from 'gray-matter';
import { REPO_ROOT } from '../../helpers';

const COMMANDS_DIR = path.join(REPO_ROOT, '.claude', 'commands');

function listCommandFiles(): string[] {
  return fs.readdirSync(COMMANDS_DIR)
    .filter(f => f.endsWith('.md'))
    .filter(f => f !== 'README.md');
}

describe('command frontmatter', () => {
  const files = listCommandFiles();
  expect(files.length).toBeGreaterThan(3);

  for (const file of files) {
    it(`PASS: /${file.replace(/\.md$/, '')} has a non-empty description`, () => {
      const content = fs.readFileSync(path.join(COMMANDS_DIR, file), 'utf8');
      const parsed = matter(content);
      expect(parsed.data).toBeDefined();
      expect(typeof parsed.data.description).toBe('string');
      expect(parsed.data.description.length).toBeGreaterThan(10);
    });
  }
});

describe('command frontmatter — model field valid', () => {
  const files = listCommandFiles();

  for (const file of files) {
    it(`PASS: ${file} either omits model or uses a known value`, () => {
      const content = fs.readFileSync(path.join(COMMANDS_DIR, file), 'utf8');
      const parsed = matter(content);
      const model = parsed.data.model;
      if (model !== undefined) {
        expect(['haiku', 'sonnet', 'opus']).toContain(model);
      }
    });
  }
});

// Slash-command surfaces a user can invoke: a `.claude/commands/<name>.md` file OR a
// `.claude/skills/<name>/` directory (skills are invoked as `/<name>` too — e.g. post-v1.2.0 the
// build-report commands became `/build-report-maintainer` / `-stakeholders` skills). CLAUDE.md
// references either kind, so the cross-reference must resolve against BOTH.
function listSkillNames(): string[] {
  const dir = path.join(REPO_ROOT, '.claude', 'skills');
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => d.name);
}

// Claude Code built-ins have no file in this repo — they resolve globally, so exclude them.
const BUILT_INS = new Set(['/help', '/clear', '/context', '/feedback']);

describe('CLAUDE.md → commands cross-reference', () => {
  it('PASS: every /command referenced in CLAUDE.md resolves to a command file or a skill', () => {
    const claudeMd = fs.readFileSync(path.join(REPO_ROOT, 'CLAUDE.md'), 'utf8');
    const available = new Set([
      ...listCommandFiles().map(f => '/' + f.replace(/\.md$/, '')),
      ...listSkillNames().map(n => '/' + n),
    ]);

    // Every command-shaped token in CLAUDE.md — NOT a hardcoded allowlist (which silently skipped
    // real references like /plan and /upgrade). A reference is `/name` where name is ≥2 chars and
    // does not end in `-`, sitting at a word boundary. The lead boundary (start / space / backtick
    // / bracket) excludes path segments like `web/src` and `@/lib`; the trailing exclusion of
    // `[\w/*-]` excludes multi-segment paths (`/v1/users`) and globs (`/build-report-*`).
    const referenced = new Set<string>();
    for (const m of claudeMd.matchAll(/(?:^|[\s`([])\/([a-z][a-z0-9-]*[a-z0-9])(?![\w/*-])/gm)) {
      referenced.add('/' + m[1]);
    }

    const missing: string[] = [];
    for (const cmd of referenced) {
      if (BUILT_INS.has(cmd)) continue;
      if (!available.has(cmd)) missing.push(cmd);
    }
    expect(
      missing,
      `CLAUDE.md references commands/skills that don't exist: ${missing.join(', ')}`,
    ).toEqual([]);
  });

  // Teeth: the extractor + resolver actually catch a dangling reference — a made-up command that
  // is neither a command file nor a skill is reported. Without this, a matcher that stopped
  // matching (or an over-eager built-in filter) could let the check pass vacuously.
  it('PASS (teeth): a command referenced but absent on disk is detected', () => {
    const available = new Set([
      ...listCommandFiles().map(f => '/' + f.replace(/\.md$/, '')),
      ...listSkillNames().map(n => '/' + n),
    ]);
    const sample = 'Run `/definitely-not-a-real-command` to frobnicate.';
    const referenced = new Set<string>();
    for (const m of sample.matchAll(/(?:^|[\s`([])\/([a-z][a-z0-9-]*[a-z0-9])(?![\w/*-])/gm)) {
      referenced.add('/' + m[1]);
    }
    expect(referenced.has('/definitely-not-a-real-command'), 'the extractor found the token').toBe(true);
    expect(available.has('/definitely-not-a-real-command'), 'and it resolves to nothing').toBe(false);
  });
});
