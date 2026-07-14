/**
 * generated-doc-conventions.json — internal consistency + agreement with the
 * consumers and the human-readable mirror.
 *
 * The JSON is the single source of truth for generated-doc filenames, read by both
 * the enforce-generated-doc-names.js hook and the validate-generated-doc-names.js
 * audit, and mirrored in naming-conventions.md. This test guards that:
 *   - the six expected conventions are present and well-formed;
 *   - each convention is self-consistent (its `example` is OK, its `counterexample`
 *     is drift) — a mistyped pattern is caught here;
 *   - naming-conventions.md documents each convention;
 *   - both consuming scripts actually read the conventions file (so a rename is caught).
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';

const CONVENTIONS = path.join(REPO_ROOT, '.claude', 'shared', 'generated-doc-conventions.json');
const NAMING_MD = path.join(REPO_ROOT, '.claude', 'shared', 'naming-conventions.md');
const HOOK = path.join(REPO_ROOT, '.claude', 'hooks', 'enforce-generated-doc-names.js');
const VALIDATOR = path.join(REPO_ROOT, '.claude', 'scripts', 'validate-generated-doc-names.js');

const EXPECTED_IDS = ['project-facts', 'epic-brief', 'epic-state', 'epic-journal', 'story-file', 'e2e-spec'];

interface Convention {
  id: string;
  dirGlob: string;
  filenamePattern: string;
  badPattern: string;
  example: string;
  counterexample: string;
  rationale: string;
}

function loadConventions(): Convention[] {
  return JSON.parse(fs.readFileSync(CONVENTIONS, 'utf8')).conventions as Convention[];
}

describe('generated-doc-conventions.json — shape', () => {
  it('PASS: contains exactly the six expected conventions', () => {
    const ids = loadConventions().map((c) => c.id).sort();
    expect(ids).toEqual([...EXPECTED_IDS].sort());
  });

  it('PASS: every convention has the required fields', () => {
    for (const c of loadConventions()) {
      for (const field of ['id', 'dirGlob', 'filenamePattern', 'badPattern', 'example', 'counterexample', 'rationale'] as const) {
        expect(c[field], `${c.id}.${field}`).toBeTruthy();
      }
    }
  });
});

describe('generated-doc-conventions.json — self-consistency', () => {
  it('PASS: each convention\'s example matches its filenamePattern', () => {
    for (const c of loadConventions()) {
      expect(new RegExp(c.filenamePattern).test(c.example), `${c.id}: example "${c.example}" vs ${c.filenamePattern}`).toBe(true);
    }
  });

  it('FAIL-shape: each counterexample is drift — matches badPattern but NOT filenamePattern', () => {
    for (const c of loadConventions()) {
      expect(new RegExp(c.badPattern).test(c.counterexample), `${c.id}: counterexample "${c.counterexample}" should match badPattern`).toBe(true);
      expect(new RegExp(c.filenamePattern).test(c.counterexample), `${c.id}: counterexample "${c.counterexample}" must NOT match filenamePattern`).toBe(false);
    }
  });
});

describe('generated-doc-conventions.json — agreement with consumers + mirror', () => {
  it('PASS: naming-conventions.md documents every convention (by example filename)', () => {
    const md = fs.readFileSync(NAMING_MD, 'utf8');
    for (const c of loadConventions()) {
      expect(md.includes(c.example), `naming-conventions.md is missing "${c.example}" (${c.id})`).toBe(true);
    }
  });

  it('PASS: both the hook and the validator read generated-doc-conventions.json', () => {
    expect(fs.readFileSync(HOOK, 'utf8')).toContain('generated-doc-conventions.json');
    expect(fs.readFileSync(VALIDATOR, 'utf8')).toContain('generated-doc-conventions.json');
  });
});
