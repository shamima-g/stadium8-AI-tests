/**
 * S8-76 Phase 5 — Tier 1 artifact-lint variant of TG-33 for the watchdog itself.
 *
 * The spec-compliance-watchdog agent file MUST contain the no-suppression policy
 * block verbatim. If the block is silently removed or weakened, the agent could
 * start emitting suppression directives in Option B updates, which would smuggle
 * `// @ts-ignore` etc. into generated-docs files.
 *
 * Specifically checks:
 *   - The literal section header "No Error Suppressions Allowed" is present
 *   - All five forbidden directives are listed verbatim:
 *       // eslint-disable
 *       // eslint-disable-next-line
 *       // @ts-expect-error
 *       // @ts-ignore
 *       // @ts-nocheck
 *
 * Pattern source: artifact-lint/no-suppression-directives.test.ts
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const AGENT_PATH = path.join(REPO_ROOT, '.claude', 'agents', 'spec-compliance-watchdog.md');

const REQUIRED_HEADER = /No Error Suppressions Allowed/;

const REQUIRED_DIRECTIVES = [
  '// eslint-disable',
  '// eslint-disable-next-line',
  '// @ts-expect-error',
  '// @ts-ignore',
  '// @ts-nocheck',
];

describe('artifact-lint — watchdog agent retains the no-suppression policy block', () => {
  it('PASS: the section header "No Error Suppressions Allowed" is present', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    expect(REQUIRED_HEADER.test(content)).toBe(true);
  });

  it('PASS: every forbidden directive is listed verbatim in the agent body', () => {
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    const missing = REQUIRED_DIRECTIVES.filter(d => !content.includes(d));
    expect(
      missing,
      `Watchdog agent is missing forbidden-directive listings: ${missing.join(', ')}`,
    ).toEqual([]);
  });
});

describe('artifact-lint — watchdog agent contains no suppression directives in its own body', () => {
  it('PASS: directives only appear inside the policy listing, not as live code suppressions', () => {
    // The agent file legitimately mentions the directives because it forbids them.
    // What we forbid is a suppression appearing OUTSIDE the policy block — e.g., on a
    // line that is not a markdown list item and not inside a code fence labelled as a
    // policy listing. As a structural proxy, assert that every occurrence of a
    // directive token sits on a line that begins with a markdown list marker (`- `).
    const content = fs.readFileSync(AGENT_PATH, 'utf8');
    const lines = content.split(/\r?\n/);

    const offending: string[] = [];
    for (const line of lines) {
      for (const directive of REQUIRED_DIRECTIVES) {
        if (line.includes(directive) && !/^\s*-\s/.test(line)) {
          offending.push(line.trim());
        }
      }
    }
    expect(
      offending,
      `Suppression directive found outside the policy listing: ${offending.join(' | ')}`,
    ).toEqual([]);
  });
});

describe('artifact-lint — failure-path coverage', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  it('FAIL: a tampered watchdog file with the policy block removed is detected', () => {
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
    expect(REQUIRED_HEADER.test(content)).toBe(false);
  });

  it('FAIL: a tampered watchdog file missing one of the forbidden directives is detected', () => {
    // Same body as the real agent, but with `// @ts-nocheck` removed from the listing.
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

### CRITICAL: No Error Suppressions Allowed

**Forbidden suppressions:**
- \`// eslint-disable\`
- \`// eslint-disable-next-line\`
- \`// @ts-expect-error\`
- \`// @ts-ignore\`
`;
    project.write('.claude/agents/spec-compliance-watchdog.md', tampered);
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'agents', 'spec-compliance-watchdog.md'),
      'utf8',
    );
    const missing = REQUIRED_DIRECTIVES.filter(d => !content.includes(d));
    expect(missing.length).toBeGreaterThan(0);
    expect(missing).toContain('// @ts-nocheck');
  });

  it('FAIL: a tampered watchdog with a stray suppression outside the policy listing is detected', () => {
    const tampered = `---
name: spec-compliance-watchdog
description: tampered
model: sonnet
tools: Read, Write, Glob, Grep, Bash, TodoWrite
---

# tampered

## Call A
Use \`// @ts-ignore\` when the type system is wrong.
## Call B
Gate 6

### CRITICAL: No Error Suppressions Allowed
- \`// eslint-disable\`
- \`// eslint-disable-next-line\`
- \`// @ts-expect-error\`
- \`// @ts-ignore\`
- \`// @ts-nocheck\`
`;
    project.write('.claude/agents/spec-compliance-watchdog.md', tampered);
    const content = fs.readFileSync(
      path.join(project.root, '.claude', 'agents', 'spec-compliance-watchdog.md'),
      'utf8',
    );
    const lines = content.split(/\r?\n/);
    const offending: string[] = [];
    for (const line of lines) {
      for (const directive of REQUIRED_DIRECTIVES) {
        if (line.includes(directive) && !/^\s*-\s/.test(line)) {
          offending.push(line.trim());
        }
      }
    }
    expect(offending.length).toBeGreaterThan(0);
  });
});
