/**
 * S8-134-145 — Tier 3 judge: deterministic parts (rubric integrity + calibration math).
 *
 * The live model call is not built here (it needs the Tier-3 judge infra and is record-
 * only). What IS testable now — and is the contract around that call — is: the rubric is
 * complete and covers each subjective AC; the calibration set has a pass AND a fail per
 * criterion; and the calibration math correctly declares a good judge trustworthy and a
 * canary-missing judge not. These run under vitest today.
 */

import { describe, it, expect } from 'vitest';
import { JUDGE_RUBRIC, JUDGE_GATES_THE_BUILD } from './rubric';
import { CALIBRATION_SET } from './calibration-set';
import { calibrate, type JudgeVerdict, type Labelled } from './calibration';

describe('rubric integrity', () => {
  it('covers the five subjective criteria, one item each', () => {
    expect(JUDGE_RUBRIC).toHaveLength(5);
    expect(JUDGE_RUBRIC.map((r) => r.ac).sort()).toEqual([3, 4, 5, 7, 8]);
  });

  it('every item has a unique id, a question, and both anchors', () => {
    const ids = new Set(JUDGE_RUBRIC.map((r) => r.id));
    expect(ids.size).toBe(JUDGE_RUBRIC.length);
    for (const r of JUDGE_RUBRIC) {
      expect(r.question.length, r.id).toBeGreaterThan(10);
      expect(r.passAnchor.length, r.id).toBeGreaterThan(0);
      expect(r.failAnchor.length, r.id).toBeGreaterThan(0);
    }
  });

  it('the judge is record-only (never gates the build)', () => {
    expect(JUDGE_GATES_THE_BUILD).toBe(false);
  });
});

describe('calibration set', () => {
  it('has a pass AND a fail example for every rubric criterion', () => {
    for (const r of JUDGE_RUBRIC) {
      const forCrit = CALIBRATION_SET.filter((c) => c.criterion === r.name);
      expect(forCrit.some((c) => c.label === 'pass'), `${r.name} needs a pass`).toBe(true);
      expect(forCrit.some((c) => c.label === 'fail'), `${r.name} needs a fail`).toBe(true);
    }
  });

  it('has unique ids', () => {
    const ids = new Set(CALIBRATION_SET.map((c) => c.id));
    expect(ids.size).toBe(CALIBRATION_SET.length);
  });
});

describe('calibration math', () => {
  const gold: Labelled[] = CALIBRATION_SET.map((c) => ({ id: c.id, criterion: c.criterion, label: c.label }));

  it('a judge that matches every gold label is trustworthy', () => {
    const verdicts: JudgeVerdict[] = gold.map((g) => ({ id: g.id, verdict: g.label }));
    const r = calibrate(gold, verdicts);
    expect(r.rate).toBe(1);
    expect(r.missedCanaries).toEqual([]);
    expect(r.falsePass).toBe(0);
    expect(r.falseFail).toBe(0);
    expect(r.perCriterionOk).toBe(true);
    expect(r.trustworthy).toBe(true);
  });

  it('a judge blind to ONE criterion is NOT trustworthy even at a high pooled rate', () => {
    // Wrong on a single pass item (C-J2-pass): rate = 9/10 = 0.9 (meets threshold), no
    // missed canary — but per-criterion coverage for "at-a-glance" fails.
    const verdicts: JudgeVerdict[] = gold.map((g) =>
      g.id === 'C-J2-pass' ? { id: g.id, verdict: 'fail' } : { id: g.id, verdict: g.label },
    );
    const r = calibrate(gold, verdicts);
    expect(r.rate).toBeGreaterThanOrEqual(0.9);
    expect(r.missedCanaries).toEqual([]);
    expect(r.falseFail).toBe(1);
    expect(r.perCriterionOk).toBe(false);
    expect(r.trustworthy).toBe(false);
  });

  it('a judge that waves through a canary is NOT trustworthy, even at high overall rate', () => {
    const verdicts: JudgeVerdict[] = gold.map((g) =>
      g.id === 'C-J5-fail' ? { id: g.id, verdict: 'pass' } : { id: g.id, verdict: g.label },
    );
    const r = calibrate(gold, verdicts);
    expect(r.missedCanaries).toContain('C-J5-fail');
    expect(r.trustworthy).toBe(false);
  });

  it('a judge below the agreement threshold is NOT trustworthy', () => {
    // Flip several PASS labels to fail so overall agreement drops below 0.9 without
    // missing a canary (all fail-labelled items still correctly called fail).
    const verdicts: JudgeVerdict[] = gold.map((g) =>
      g.label === 'pass' && g.id !== 'C-J1-pass' ? { id: g.id, verdict: 'fail' } : { id: g.id, verdict: g.label },
    );
    const r = calibrate(gold, verdicts);
    expect(r.missedCanaries).toEqual([]);
    expect(r.rate).toBeLessThan(0.9);
    expect(r.trustworthy).toBe(false);
  });

  it('an empty gold set is never trustworthy (no vacuous pass)', () => {
    expect(calibrate([], []).trustworthy).toBe(false);
  });
});
