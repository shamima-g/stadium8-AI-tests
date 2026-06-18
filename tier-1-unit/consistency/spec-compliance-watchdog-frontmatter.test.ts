/**
 * S8-76 Phase 5 — Tier 1 structural lint for the spec-compliance-watchdog agent.
 *
 * Asserts the agent file's contract, not its behaviour. Behavioural drift cases
 * live in Tier 3 §23a-h (TEST-GUIDE.md). The canonical agent description is in
 * QA-TESTS/HOW-IT-WORKS.md §5.
 *
 * Specifically checks:
 *   - .claude/agents/spec-compliance-watchdog.md exists
 *   - YAML frontmatter has required fields (name, description, model, tools)
 *   - tools list includes Read, Write, Glob, Grep, Bash, TodoWrite
 *   - tools list excludes AskUserQuestion (subagent constraint)
 *   - body contains both `## Call A` and `## Call B` sections
 *   - body contains the literal "Gate 6" reference
 *   - body contains the "No Error Suppressions Allowed" section header
 *
 * Pattern source: consistency/agents-frontmatter.test.ts
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import matter from 'gray-matter';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const AGENT_PATH = path.join(REPO_ROOT, '.claude', 'agents', 'spec-compliance-watchdog.md');

const REQUIRED_TOOLS = ['Read', 'Write', 'Glob', 'Grep', 'Bash', 'TodoWrite'];
const FORBIDDEN_TOOLS = ['AskUserQuestion'];

function parseToolList(toolsField: unknown): string[] {
  if (Array.isArray(toolsField)) return toolsField.map(String);
  if (typeof toolsField === 'string') {
    return toolsField.split(',').map(s => s.trim()).filter(Boolean);
  }
  return [];
}

describe('spec-compliance-watchdog — file exists with valid frontmatter', () => {
  it('PASS: agent file exists at the canonical path', () => {
    expect(fs.existsSync(AGENT_PATH)).toBe(true);
  });

  it('PASS: frontmatter has required fields (name, description, model, tools)', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    const parsed = matter(content);
    expect(parsed.data.name).toBe('spec-compliance-watchdog');
    expect(typeof parsed.data.description).toBe('string');
    expect(parsed.data.description.length).toBeGreaterThan(20);
    expect(typeof parsed.data.model).toBe('string');
    expect(parsed.data.tools).toBeDefined();
  });
});

describe('spec-compliance-watchdog — tools list contract', () => {
  it('PASS: tools list includes all required entries', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    const parsed = matter(content);
    const tools = parseToolList(parsed.data.tools);

    const missing = REQUIRED_TOOLS.filter(t => !tools.includes(t));
    expect(
      missing,
      `Watchdog agent is missing required tools: ${missing.join(', ')}`,
    ).toEqual([]);
  });

  it('PASS: tools list excludes AskUserQuestion (Task subagent constraint)', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    const parsed = matter(content);
    const tools = parseToolList(parsed.data.tools);

    const present = FORBIDDEN_TOOLS.filter(t => tools.includes(t));
    expect(
      present,
      `Watchdog agent must not include subagent-incompatible tools: ${present.join(', ')}`,
    ).toEqual([]);
  });
});

describe('spec-compliance-watchdog — body contract', () => {
  it('PASS: body contains a `## Call A` section heading', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    expect(/^## Call A\b/m.test(content)).toBe(true);
  });

  it('PASS: body contains a `## Call B` section heading', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    expect(/^## Call B\b/m.test(content)).toBe(true);
  });

  it('PASS: body references "Gate 6" verbatim', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    expect(content.includes('Gate 6')).toBe(true);
  });

  it('PASS: body contains the "No Error Suppressions Allowed" section', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    expect(/No Error Suppressions Allowed/.test(content)).toBe(true);
  });
});

describe('spec-compliance-watchdog — failure-path coverage', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: a tampered agent file with AskUserQuestion in tools is detected', () => {
    const tampered = `---
name: spec-compliance-watchdog
description: tampered
model: sonnet
tools: Read, Write, Glob, Grep, Bash, TodoWrite, AskUserQuestion
---

# tampered
## Call A
## Call B
Gate 6
### CRITICAL: No Error Suppressions Allowed
`;
    project.write('.claude/agents/spec-compliance-watchdog.md', tampered);
    const parsed = matter(fs.readFileSync(
      path.join(project.root, '.claude', 'agents', 'spec-compliance-watchdog.md'),
      'utf8',
    ));
    const tools = parseToolList(parsed.data.tools);
    const present = FORBIDDEN_TOOLS.filter(t => tools.includes(t));
    expect(present.length).toBeGreaterThan(0);
  });

  it('FAIL: a tampered agent file missing `## Call B` is detected', () => {
    const tampered = `---
name: spec-compliance-watchdog
description: tampered
model: sonnet
tools: Read, Write, Glob, Grep, Bash, TodoWrite
---

# tampered
## Call A
Gate 6
### CRITICAL: No Error Suppressions Allowed
`;
    project.write('.claude/agents/spec-compliance-watchdog.md', tampered);
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'agents', 'spec-compliance-watchdog.md'),
      'utf8',
    );
    expect(/^## Call B\b/m.test(content)).toBe(false);
  });

  it('FAIL: a tampered agent file missing the no-suppression header is detected', () => {
    const tampered = `---
name: spec-compliance-watchdog
description: tampered
model: sonnet
tools: Read, Write, Glob, Grep, Bash, TodoWrite
---

# tampered
## Call A
## Call B
Gate 6
`;
    project.write('.claude/agents/spec-compliance-watchdog.md', tampered);
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'agents', 'spec-compliance-watchdog.md'),
      'utf8',
    );
    expect(/No Error Suppressions Allowed/.test(content)).toBe(false);
  });
});
