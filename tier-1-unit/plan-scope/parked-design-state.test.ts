/**
 * B10 (Phase 3) — unit tests for the parked design-update STATE scorer (`helpers/plan-scope.ts`).
 * Pure functions over synthetic state.json / changed-path fixtures; each check has a good AND a broken
 * case (rule 1). This is the analysis core the Tier-2 recorded-run invariant #201 will call once a
 * parked design-update `/plan` golden capture exists — exactly as the intake helpers were unit-tested
 * before their capture landed. Field names are the template's real ones (see plan-scope.ts header).
 */
import { describe, it, expect } from 'vitest';
import {
  parsePlanEpicState,
  auditParkedDesignUpdate,
  designStagedOnMain,
} from '../../helpers/plan-scope';

// A well-formed, fully-parked design-update epic (the "good" case).
const GOOD_STATE = JSON.stringify({
  epic: {
    slug: 'taskboard-redesign',
    parkedDesignUpdate: true,
    designFingerprint: 'sha256:ab12cd34',
    designDecisions: [{ topic: 'primary-colour', chose: 'blue' }],
  },
});

describe('parsePlanEpicState — fail-closed', () => {
  it('parses a valid state object', () => {
    expect(parsePlanEpicState(GOOD_STATE)?.epic?.parkedDesignUpdate).toBe(true);
  });
  it('returns null on malformed JSON (not a throw)', () => {
    expect(parsePlanEpicState('{ not json')).toBeNull();
  });
  it('returns null on a non-object top level (array / scalar)', () => {
    expect(parsePlanEpicState('[1,2,3]')).toBeNull();
    expect(parsePlanEpicState('"x"')).toBeNull();
  });
});

describe('auditParkedDesignUpdate — all three fields required', () => {
  it('OK on a fully-parked design-update epic', () => {
    const a = auditParkedDesignUpdate(parsePlanEpicState(GOOD_STATE));
    expect(a.ok, a.reasons.join('; ')).toBe(true);
    expect(a.isParkedDesignUpdate).toBe(true);
    expect(a.fingerprintSet).toBe(true);
    expect(a.decisionsCount).toBe(1);
  });

  it('FAILS when parkedDesignUpdate is not true (mutation: flip the flag)', () => {
    const s = parsePlanEpicState(GOOD_STATE.replace('"parkedDesignUpdate":true', '"parkedDesignUpdate":false'));
    const a = auditParkedDesignUpdate(s);
    expect(a.ok).toBe(false);
    expect(a.reasons.join(' ')).toMatch(/parkedDesignUpdate/);
  });

  it('FAILS when designFingerprint is still null (fingerprint step never ran)', () => {
    const s = parsePlanEpicState(GOOD_STATE.replace('"sha256:ab12cd34"', 'null'));
    const a = auditParkedDesignUpdate(s);
    expect(a.ok).toBe(false);
    expect(a.fingerprintSet).toBe(false);
    expect(a.reasons.join(' ')).toMatch(/designFingerprint/);
  });

  it('ACCEPTS an empty designDecisions array (valid per spec — a conflict-free update holds none)', () => {
    const s = parsePlanEpicState(GOOD_STATE.replace('[{"topic":"primary-colour","chose":"blue"}]', '[]'));
    const a = auditParkedDesignUpdate(s);
    expect(a.ok, a.reasons.join('; ')).toBe(true);  // present + array is enough; non-empty is NOT required
    expect(a.decisionsCount).toBe(0);
  });

  it('FAILS when designDecisions is not an array', () => {
    const s = parsePlanEpicState(GOOD_STATE.replace('[{"topic":"primary-colour","chose":"blue"}]', '"blue"'));
    const a = auditParkedDesignUpdate(s);
    expect(a.ok).toBe(false);
    expect(a.reasons.join(' ')).toMatch(/not an array/);
  });

  it('fails closed on a missing epic object / null state', () => {
    expect(auditParkedDesignUpdate(parsePlanEpicState('{}')).ok).toBe(false);
    expect(auditParkedDesignUpdate(null).ok).toBe(false);
    expect(auditParkedDesignUpdate(null).reasons.join(' ')).toMatch(/no epic object/);
  });
});

describe('designStagedOnMain — the design must stay off main (plan.md Step 3b)', () => {
  it('OK when the park staged only project.md + the epic-plan row (no design paths)', () => {
    const r = designStagedOnMain([
      'generated-docs/project.md',
      'generated-docs/epics/epic-plan.md',
      'generated-docs/epics/taskboard-redesign/brief.md',
    ]);
    expect(r.ok).toBe(true);
    expect(r.offenders).toEqual([]);
  });

  it('FAILS when a design digest/source leaked onto main (the broken case)', () => {
    const r = designStagedOnMain([
      'generated-docs/project.md',
      'generated-docs/design/digest.md', // <- must not be here
    ]);
    expect(r.ok).toBe(false);
    expect(r.offenders).toEqual(['generated-docs/design/digest.md']);
  });

  it('FAILS when documentation/ design source leaked onto main (plan commit must not stage it)', () => {
    const r = designStagedOnMain(['generated-docs/project.md', 'documentation/tokens.css']);
    expect(r.ok).toBe(false);
    expect(r.offenders).toEqual(['documentation/tokens.css']);
  });

  it('normalises Windows backslashes before matching', () => {
    const r = designStagedOnMain(['generated-docs\\design\\tokens.css']);
    expect(r.ok).toBe(false);
    expect(r.offenders).toEqual(['generated-docs/design/tokens.css']);
  });
});
