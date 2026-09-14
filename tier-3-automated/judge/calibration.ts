/**
 * S8-134-145 — Tier 3 judge CALIBRATION math (pure, deterministic).
 *
 * Before the LLM judge's verdicts are allowed to count, it must agree with a fixed,
 * human-labelled set of good/bad examples. This module holds the deterministic scoring; no
 * model call (that is the JudgeAdapter seam in rubric.ts).
 *
 * Trustworthy requires ALL of:
 *   - overall agreement ≥ threshold, AND
 *   - every FAIL-labelled canary caught (fail→pass is the dangerous error), AND
 *   - per-criterion coverage: each rubric criterion's PASS and FAIL both scored right, so a
 *     judge blind to one criterion can't hide behind a high pooled rate.
 *
 * NOTE on the threshold: with a small set (~10 items) `rate ≥ 0.9` means "≤1 disagreement"
 * and is a SMOKE GATE, not a statistically meaningful bar. Grow CALIBRATION_SET materially
 * before treating the numeric threshold as rigorous; the per-criterion + canary rules are
 * the load-bearing checks at small N. Nondeterminism (repeat-sampling the judge and
 * requiring stable verdicts) is handled by the live runner, not here.
 */

import type { Verdict } from './rubric';

export interface Labelled {
  id: string;
  criterion: string; // rubric name, e.g. "first-line-actionable"
  label: Verdict; // the human gold label
}

export interface JudgeVerdict {
  id: string;
  verdict: Verdict;
}

export interface CriterionCoverage {
  criterion: string;
  passCorrect: boolean; // every pass-labelled item for this criterion scored pass
  failCorrect: boolean; // every fail-labelled item for this criterion scored fail
}

export interface CalibrationResult {
  total: number;
  agreed: number;
  rate: number; // agreed / total
  falsePass: number; // fail-labelled scored pass (dangerous — under-flagging)
  falseFail: number; // pass-labelled scored fail (nervous — over-flagging)
  missedCanaries: string[]; // ids of fail-labelled items the judge called pass
  perCriterion: CriterionCoverage[];
  perCriterionOk: boolean; // every criterion's pass AND fail correct
  trustworthy: boolean;
}

export function calibrate(gold: Labelled[], verdicts: JudgeVerdict[], threshold = 0.9): CalibrationResult {
  const byId = new Map(verdicts.map((v) => [v.id, v.verdict]));

  let agreed = 0;
  let falsePass = 0;
  let falseFail = 0;
  const missedCanaries: string[] = [];

  for (const g of gold) {
    const v = byId.get(g.id);
    if (v === g.label) agreed++;
    if (g.label === 'fail' && v !== 'fail') {
      falsePass++;
      missedCanaries.push(g.id);
    }
    if (g.label === 'pass' && v === 'fail') falseFail++;
  }

  // Per-criterion coverage.
  const criteria = [...new Set(gold.map((g) => g.criterion))];
  const perCriterion: CriterionCoverage[] = criteria.map((criterion) => {
    const items = gold.filter((g) => g.criterion === criterion);
    const passItems = items.filter((g) => g.label === 'pass');
    const failItems = items.filter((g) => g.label === 'fail');
    return {
      criterion,
      passCorrect: passItems.length > 0 && passItems.every((g) => byId.get(g.id) === 'pass'),
      failCorrect: failItems.length > 0 && failItems.every((g) => byId.get(g.id) === 'fail'),
    };
  });
  const perCriterionOk =
    perCriterion.length > 0 && perCriterion.every((c) => c.passCorrect && c.failCorrect);

  const total = gold.length;
  const rate = total === 0 ? 0 : agreed / total;
  const trustworthy = total > 0 && rate >= threshold && missedCanaries.length === 0 && perCriterionOk;

  return { total, agreed, rate, falsePass, falseFail, missedCanaries, perCriterion, perCriterionOk, trustworthy };
}
