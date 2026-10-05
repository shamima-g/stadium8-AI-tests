/**
 * Human-review harness — wiring the design-update subjective checks to the `plan-design-update` capture.
 *
 * These review the ARTIFACTS the build-from-design flow produces (reviewable from the committed capture),
 * NOT the live behaviour: the design digest's faithfulness/plainness, and whether each held design
 * decision is recorded clearly and correctly. (The live read-back-SHOWN-at-intake (#14) and
 * conflict-ASKED-at-plan (#15) cores are transcript/eyeball and are not wired here.)
 *
 * Pure over strings; the caller reads the capture (digest.md + the parked epic's state.json).
 */
import fs from 'node:fs';
import path from 'node:path';
import type { ReviewManifest } from './build-review';
import type { ReviewCheck } from './review-logic';

export const PLAN_REVIEW_CHECKS: ReviewCheck[] = [
  { id: 'plan-design-digest-faithful', criterion: 'Does the design digest describe the design correctly and in plain language (screens, palette, and honestly flagging what it could NOT determine)?' },
  { id: 'plan-design-decision-clear', criterion: 'Is each held design decision recorded clearly and correctly — which value won, over what it superseded, in plain words?' },
];

/** Extract the parked epic's designDecisions (the held choices) as readable evidence, from its state.json. */
export function decisionsEvidence(parkedStateJson: string): string {
  try {
    const j = JSON.parse(parkedStateJson) as { epic?: { designDecisions?: unknown } };
    const dd = j?.epic?.designDecisions;
    if (Array.isArray(dd) && dd.length) {
      return dd.map((d, i) => `#${i + 1}: ${typeof d === 'string' ? d : JSON.stringify(d, null, 2)}`).join('\n\n');
    }
  } catch {
    /* fall through */
  }
  return '(no designDecisions recorded on the parked epic)';
}

/** Extract the digest + the parked design-update epic's state.json from a checked-out capture root, then
 *  build the manifest. Shared by the bundle generator AND the drift-guard test, so "what's committed" and
 *  "what the builder would produce now" stay in lock-step. */
export function buildPlanReviewManifestFromCapture(root: string, label = 'plan-design-update'): ReviewManifest {
  const dp = path.join(root, 'generated-docs', 'design', 'digest.md');
  const digest = fs.existsSync(dp) ? fs.readFileSync(dp, 'utf8') : '';
  const epicsDir = path.join(root, 'generated-docs', 'epics');
  let parked = '';
  if (fs.existsSync(epicsDir)) {
    for (const d of fs.readdirSync(epicsDir)) {
      const sp = path.join(epicsDir, d, 'state.json');
      if (fs.existsSync(sp)) {
        const s = fs.readFileSync(sp, 'utf8');
        if (/"parkedDesignUpdate"\s*:\s*true/.test(s)) { parked = s; break; }
      }
    }
  }
  return buildPlanReviewManifest(digest, parked, label);
}

/** Build the design review manifest from a captured design digest + the parked epic's state.json. */
export function buildPlanReviewManifest(digestMd: string, parkedStateJson: string, label = 'plan-design-update'): ReviewManifest {
  return {
    captureLabel: `${label} — design review`,
    items: [
      {
        id: 'plan-design-digest-faithful',
        criterion: PLAN_REVIEW_CHECKS[0].criterion,
        guidance: 'PASS: the digest faithfully and plainly captures the screens/palette and flags what it could not determine. FAIL: a wrong/invented fact, jargon, or an uncertainty silently dropped.',
        evidence: digestMd.trim()
          ? `(This is the design digest on main — the BASELINE design. A design UPDATE was parked off-main; its held choice is the decision-clarity check, so this baseline digest may still show the pre-update values.)\n\n${digestMd.trim()}`
          : '(no design digest found)',
      },
      {
        id: 'plan-design-decision-clear',
        criterion: PLAN_REVIEW_CHECKS[1].criterion,
        guidance: 'PASS: each decision states the winning value and what it superseded, in plain words. FAIL: ambiguous, the wrong winner, or unreadable.',
        evidence: decisionsEvidence(parkedStateJson),
      },
    ],
  };
}
