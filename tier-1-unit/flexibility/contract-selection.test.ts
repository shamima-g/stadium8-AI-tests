/**
 * Per-version contract selection (workflow-tests.md area O, Decision 2). The
 * active target selects its OWN recipe (template-contract.<target>.json), with
 * the single default as the fallback — so each version is judged against its own
 * shape, never the other's.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { contractPathFor } from '../../helpers/template-contract';

describe('contract selection — good case', () => {
  it('PASS: an active target picks its own contract file', () => {
    expect(path.basename(contractPathFor('dev'))).toBe('template-contract.dev.json');
    expect(path.basename(contractPathFor('release'))).toBe('template-contract.release.json');
  });

  it('PASS: no target falls back to the single default contract', () => {
    // contractPathFor()'s default arg is process.env.QA_TARGET, so "no target" means
    // the env is genuinely unset. Isolate it here — otherwise running under the
    // test:target harness (QA_TARGET=dev|release) leaks in and this fails spuriously.
    const saved = process.env.QA_TARGET;
    delete process.env.QA_TARGET;
    try {
      expect(path.basename(contractPathFor(undefined))).toBe('template-contract.json');
      expect(path.basename(contractPathFor())).toBe('template-contract.json');
    } finally {
      if (saved !== undefined) process.env.QA_TARGET = saved;
    }
  });

  it('BROKEN: a target with no matching contract file falls back to the default (never crashes)', () => {
    expect(path.basename(contractPathFor('does-not-exist'))).toBe('template-contract.json');
  });
});

describe('the per-target contracts exist and are well-formed', () => {
  const QA_ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..', '..');
  const required = ['stages', 'storyStatuses', 'e2eStatusesCore', 'docNameIds'];

  for (const target of ['dev', 'release']) {
    it(`PASS: template-contract.${target}.json has every required list`, () => {
      const p = contractPathFor(target);
      expect(path.basename(p)).toBe(`template-contract.${target}.json`);
      const c = JSON.parse(fs.readFileSync(p, 'utf8'));
      for (const key of required) {
        expect(Array.isArray(c[key]), `${target}.${key}`).toBe(true);
        expect(c[key].length, `${target}.${key} non-empty`).toBeGreaterThan(0);
      }
    });
  }

  it('PASS: the release contract matches the documented seven-stage order', () => {
    const c = JSON.parse(fs.readFileSync(contractPathFor('release'), 'utf8'));
    // Independent hand-pinned oracle (v1.2.0 added READY-TO-BUILD) — deliberately a
    // literal, not a re-read of the file under test, so it can still go red on drift.
    expect(c.stages).toEqual(['PLAN', 'READY-TO-BUILD', 'BUILD', 'EPIC-END', 'MANUAL-TEST', 'COMPLETE-ON-BRANCH', 'COMPLETE']);
  });
});
