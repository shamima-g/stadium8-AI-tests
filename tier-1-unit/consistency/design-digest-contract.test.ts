/**
 * Build-from-an-existing-design — the design digest is a wired contract (post-v1.2.0) — #13.
 *
 * The design feature is deliberately AI-driven and schema-free: `design-interpreter` is the
 * ONLY thing that reads the raw design a user drops in `documentation/`, and it emits a
 * normalized digest at `generated-docs/design/digest.md` that "every downstream consumer reads
 * instead of the raw design" — a quarantine boundary, so a design's format drift has exactly one
 * place to fix. The reading itself is live behaviour (Tier 3, #14/#15) and its wording is out of
 * scope (§15). What IS deterministic — and what this checks — is the WIRING: the writer emits the
 * digest, a format template defines its shape, and downstream agents read that path (not a
 * dangling one-off). This is a cross-doc drift check, the kind the suite exists for; it does not
 * assert prose. Feature-detected on the design-interpreter agent; skips on older cuts.
 */

import { it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { REPO_ROOT } from '../../helpers';

const CLAUDE_DIR = path.join(REPO_ROOT, '.claude');
const DESIGN_INTERPRETER_REL = '.claude/agents/design-interpreter.md';
const DIGEST_TEMPLATE_REL = '.claude/templates/design-digest.md';
const PRESENT = fs.existsSync(path.join(REPO_ROOT, DESIGN_INTERPRETER_REL));

// The digest path, matched by its distinctive suffix so it never collides with the
// hyphenated template filename `design-digest.md`.
const DIGEST = 'design/digest.md';

function walk(dir: string, acc: string[] = []): string[] {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === 'node_modules' || e.name === '.git') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else acc.push(p);
  }
  return acc;
}

/** Repo-relative (posix) files under .claude whose text contains `needle`. */
function filesReferencing(needle: string): string[] {
  return walk(CLAUDE_DIR)
    .filter((f) => {
      try {
        return fs.readFileSync(f, 'utf8').includes(needle);
      } catch {
        return false;
      }
    })
    .map((f) => path.relative(REPO_ROOT, f).replace(/\\/g, '/'));
}

describe('build-from-design — the design digest is a wired contract (post-v1.2.0)', () => {
  it.skipIf(!PRESENT)('PASS: design-interpreter emits the digest, a template shapes it, and downstream agents read it', () => {
    const refs = filesReferencing(DIGEST);

    // The writer — the sole reader of the raw design — names the digest it emits.
    expect(refs, 'design-interpreter (the writer) references the digest path').toContain(DESIGN_INTERPRETER_REL);

    // The digest has a format template — the shape downstream consumers rely on.
    expect(fs.existsSync(path.join(REPO_ROOT, DIGEST_TEMPLATE_REL)), 'a design-digest template defines its shape').toBe(
      true,
    );

    // "Every downstream consumer reads the digest instead of the raw design": at least one
    // planning/build agent references the path, so it's a shared contract, not a dangling
    // one-off in the writer.
    const downstream = refs.filter((f) => /agents\/(developer|feature-planner|intake-agent)\.md$/.test(f));
    expect(
      downstream.length,
      `at least one downstream agent must read the digest; all refs:\n${refs.join('\n')}`,
    ).toBeGreaterThan(0);
  });

  // Teeth over the real tree: the scanner isn't matching everything — a made-up digest path is
  // referenced nowhere, so the matches above are a real signal.
  it.skipIf(!PRESENT)('PASS (teeth): a non-existent digest path is referenced by nothing', () => {
    expect(filesReferencing('design/nonexistent-digest.md')).toEqual([]);
  });
});
