/**
 * Plan-scope (B10) — pure analysis of a PARKED design-update epic, feeding the Tier-2 recorded-run
 * invariant #201 and the Tier-3 live scorer. No I/O: the caller reads `state.json` + (for the
 * digest-not-on-main check) the paths the park staged to `main`, and passes strings in.
 *
 * Field names are the template's REAL ones, not invented — verified in the 28-09-2026 snapshot:
 *   - `epic.parkedDesignUpdate` (bool)         plan.md:218, continue.md:188, epic-state.js:24
 *   - `epic.designFingerprint` (string|null)   plan.md:219/260 (null at park, written non-null by the
 *                                              fingerprint step), continue.md:206
 *   - `epic.designDecisions` (array)           plan.md:220/161, continue.md:221
 * And the behaviour under test: "Nothing of the design lands on `main` here. The digest is refreshed
 * only in the worktree and never staged" (plan.md Step 3b).
 */

export interface PlanEpicState {
  epic?: {
    parkedDesignUpdate?: unknown;
    designFingerprint?: unknown;
    designDecisions?: unknown;
    [k: string]: unknown;
  };
  [k: string]: unknown;
}

/** Fail-closed parse: malformed or non-object JSON → null (never throws). */
export function parsePlanEpicState(json: string): PlanEpicState | null {
  try {
    const o = JSON.parse(json);
    return o && typeof o === 'object' && !Array.isArray(o) ? (o as PlanEpicState) : null;
  } catch {
    return null;
  }
}

export interface ParkedDesignAudit {
  ok: boolean;
  reasons: string[];
  isParkedDesignUpdate: boolean;
  fingerprintSet: boolean;
  decisionsCount: number;
}

/**
 * A fully-parked design-update epic must carry, in `state.json.epic`:
 *   parkedDesignUpdate === true, a non-empty designFingerprint (written at plan time), and a
 *   non-empty designDecisions[]. Any missing/placeholder field fails closed with a named reason.
 */
export function auditParkedDesignUpdate(state: PlanEpicState | null): ParkedDesignAudit {
  const reasons: string[] = [];
  const epic = state?.epic;
  if (!epic || typeof epic !== 'object' || Array.isArray(epic)) {
    return { ok: false, reasons: ['no epic object in state.json'], isParkedDesignUpdate: false, fingerprintSet: false, decisionsCount: 0 };
  }

  const isParkedDesignUpdate = epic.parkedDesignUpdate === true;
  if (!isParkedDesignUpdate) reasons.push('epic.parkedDesignUpdate is not true');

  const fp = epic.designFingerprint;
  const fingerprintSet = typeof fp === 'string' && fp.trim().length > 0;
  if (!fingerprintSet) reasons.push('epic.designFingerprint is null/empty — fingerprint not written at plan time');

  const dd = epic.designDecisions;
  const isArr = Array.isArray(dd);
  const decisionsCount = isArr ? (dd as unknown[]).length : 0;
  if (!isArr) reasons.push('epic.designDecisions is not an array');
  else if (decisionsCount === 0) reasons.push('epic.designDecisions is empty — no held design choice');

  return { ok: reasons.length === 0, reasons, isParkedDesignUpdate, fingerprintSet, decisionsCount };
}

/** Matches a design digest/source path that must NOT be staged to `main` at plan time. */
const DESIGN_PATH_ON_MAIN = /(^|\/)generated-docs\/design\//i;

export interface DesignOnMainResult {
  ok: boolean;
  offenders: string[];
}

/**
 * The design-update's refreshed digest/source may NOT land on `main` — it stays in the worktree
 * (plan.md Step 3b). Given the paths the park staged to `main` (the test feeds these from
 * `git show --name-only <docs(plan) commit>`), none may live under `generated-docs/design/`.
 * `ok === true` means the design stayed off `main` (the good case).
 */
export function designStagedOnMain(mainChangedPaths: string[]): DesignOnMainResult {
  const offenders = mainChangedPaths
    .map((p) => p.replace(/\\/g, '/'))
    .filter((p) => DESIGN_PATH_ON_MAIN.test(p));
  return { ok: offenders.length === 0, offenders };
}
