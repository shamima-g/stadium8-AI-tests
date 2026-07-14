/**
 * Consistency — every .claude/shared/* and .claude/policies/* doc is referenced
 * somewhere, and every reference to one resolves.
 *
 * The existing cross-doc-references test only checks policy paths mentioned in
 * CLAUDE.md. This broadens the net to the whole template corpus (CLAUDE.md,
 * CLAUDE.user.md, agents, commands, and the shared/policy docs themselves), catching:
 *   - an ORPHANED shared/policy doc that nothing links to (dead weight / rot);
 *   - a BROKEN reference to a shared/policy file that was renamed or removed.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';

const CLAUDE_DIR = path.join(REPO_ROOT, '.claude');
const SHARED_DIR = path.join(CLAUDE_DIR, 'shared');
const POLICIES_DIR = path.join(CLAUDE_DIR, 'policies');

/** All files that may reference a shared/policy doc: the .claude md/json corpus + root CLAUDE files. */
function collectReferencers(): { path: string; text: string }[] {
  const out: { path: string; text: string }[] = [];
  const walk = (dir: string): void => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        if (e.name === 'node_modules' || e.name.startsWith('.')) continue;
        walk(full);
      } else if (/\.(md|json)$/.test(e.name)) {
        out.push({ path: full, text: fs.readFileSync(full, 'utf8') });
      }
    }
  };
  walk(CLAUDE_DIR);
  for (const root of ['CLAUDE.md', 'CLAUDE.user.md']) {
    const p = path.join(REPO_ROOT, root);
    if (fs.existsSync(p)) out.push({ path: p, text: fs.readFileSync(p, 'utf8') });
  }
  return out;
}

function listTargets(dir: string): string[] {
  return fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => /\.(md|json)$/.test(f)) : [];
}

/** Every `(shared|policies)/<file>.(md|json)` mention in `text`, regardless of a ./ or .claude/ prefix. */
function extractSharedPolicyRefs(text: string): { dir: string; file: string }[] {
  const out: { dir: string; file: string }[] = [];
  for (const m of text.matchAll(/\b(shared|policies)\/([a-z0-9-]+\.(?:md|json))/g)) {
    out.push({ dir: m[1], file: m[2] });
  }
  return out;
}

describe('shared/ + policies/ — no orphans', () => {
  const referencers = collectReferencers();
  const targets = [
    ...listTargets(SHARED_DIR).map((f) => ({ dir: 'shared', file: f, abs: path.join(SHARED_DIR, f) })),
    ...listTargets(POLICIES_DIR).map((f) => ({ dir: 'policies', file: f, abs: path.join(POLICIES_DIR, f) })),
  ];

  it('PASS: there are shared and policy docs to check (sanity)', () => {
    expect(targets.length).toBeGreaterThan(8);
  });

  for (const t of targets) {
    it(`PASS: ${t.dir}/${t.file} is referenced by at least one other file`, () => {
      const referenced = referencers.some((r) => r.path !== t.abs && r.text.includes(t.file));
      expect(referenced, `${t.dir}/${t.file} appears orphaned — nothing references it`).toBe(true);
    });
  }
});

describe('shared/ + policies/ — every reference resolves', () => {
  it('PASS: no reference points at a missing shared/policy file', () => {
    const broken: string[] = [];
    for (const r of collectReferencers()) {
      for (const ref of extractSharedPolicyRefs(r.text)) {
        const target = path.join(CLAUDE_DIR, ref.dir, ref.file);
        if (!fs.existsSync(target)) {
          broken.push(`${path.relative(REPO_ROOT, r.path)} → ${ref.dir}/${ref.file}`);
        }
      }
    }
    expect(broken, `Broken shared/policy references:\n${broken.join('\n')}`).toEqual([]);
  });
});

describe('shared/ + policies/ — the detectors work (good/broken)', () => {
  it('PASS: extractSharedPolicyRefs finds refs with and without a prefix', () => {
    const refs = extractSharedPolicyRefs(
      'see [x](.claude/policies/testing-policy.md) and ../shared/approval-pattern.md and shared/roles-snippets.md',
    );
    const files = refs.map((r) => `${r.dir}/${r.file}`);
    expect(files).toContain('policies/testing-policy.md');
    expect(files).toContain('shared/approval-pattern.md');
    expect(files).toContain('shared/roles-snippets.md');
  });

  it('FAIL: an orphan (unreferenced basename) is detectable in a synthetic corpus', () => {
    const corpus = [
      { path: 'a.md', text: 'links to shared/used.md only' },
      { path: 'shared/used.md', text: 'content' },
      { path: 'shared/orphan.md', text: 'content' },
    ];
    const isReferenced = (file: string, self: string) =>
      corpus.some((r) => r.path !== self && r.text.includes(file));
    expect(isReferenced('used.md', 'shared/used.md')).toBe(true);
    expect(isReferenced('orphan.md', 'shared/orphan.md')).toBe(false); // orphan caught
  });
});
