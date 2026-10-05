/**
 * Human-review harness — wiring the design-update subjective checks to the `plan-design-update` capture.
 *
 * These review the ARTIFACTS the build-from-design flow produces (from the committed capture) — they are
 * the artifact RESIDUE of #14/#15: the digest is the read-back artifact (#14), and the held decision is the
 * recorded outcome of the conflict (#15). The LIVE cores — was the read-back actually SHOWN at intake (#14),
 * was the conflict actually ASKED at plan time (#15) — are message/live and stay MANUAL (by hand), not wired.
 *
 * Checks:
 *   plan-design-digest-faithful — does the digest describe the design correctly + plainly, flagging what it
 *     could not determine? Evidence = the digest PLUS the design source (design-notes + tokens) to check it
 *     against, so "correctly" is actually answerable (not just "is it plain").
 *   plan-design-decision-clear — is each held design decision recorded clearly/correctly (value won, over
 *     what)? Evidence = the parked epic's designDecisions (self-contained).
 *
 * Pure over strings; the caller reads the capture (digest.md + design source + the parked epic's state.json).
 */
import fs from 'node:fs';
import path from 'node:path';
import type { ReviewManifest } from './build-review';
import type { ReviewCheck } from './review-logic';

export const PLAN_REVIEW_CHECKS: ReviewCheck[] = [
  { id: 'plan-design-digest-faithful', criterion: 'Does the design digest describe the design correctly and in plain language (screens, palette, and honestly flagging what it could NOT determine) — checked against the design source?' },
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

/** Extract the digest, the design SOURCE (design-notes + tokens — the dependable core to check the digest
 *  against), and the parked design-update epic's state.json from a checked-out capture root, then build the
 *  manifest. Shared by the bundle generator AND the drift-guard test, so "what's committed" and "what the
 *  builder would produce now" stay in lock-step. */
export function buildPlanReviewManifestFromCapture(root: string, label = 'plan-design-update'): ReviewManifest {
  const read = (rel: string) => {
    const p = path.join(root, rel);
    return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : '';
  };
  const digest = read('generated-docs/design/digest.md');
  const notes = read('documentation/design/design-notes.md');
  const tokens = read('documentation/design/tokens.css');
  const source = [notes && `--- design-notes.md ---\n${notes.trim()}`, tokens && `--- tokens.css ---\n${tokens.trim()}`]
    .filter(Boolean)
    .join('\n\n');
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
  return buildPlanReviewManifest(digest, parked, source, label);
}

/**
 * Build the design review manifest from a captured design digest, the design source (to check the digest
 * against), and the parked epic's state.json.
 */
export function buildPlanReviewManifest(digestMd: string, parkedStateJson: string, designSource = '', label = 'plan-design-update'): ReviewManifest {
  const digestBlock = digestMd.trim()
    ? `--- the design digest on main (the BASELINE design; a design UPDATE was parked off-main, so this baseline may still show pre-update values — its held choice is the decision-clarity check) ---\n${digestMd.trim()}`
    : '(no design digest found)';
  const sourceBlock = designSource.trim()
    ? `\n\n--- the design SOURCE to check the digest against (documentation/design) ---\n${designSource.trim()}`
    : '\n\n(design source not available — judge plainness/uncertainty-flagging only)';
  return {
    captureLabel: `${label} — design review`,
    items: [
      {
        id: 'plan-design-digest-faithful',
        criterion: PLAN_REVIEW_CHECKS[0].criterion,
        guidance: 'PASS: the digest matches the design source and plainly captures the screens/palette and flags what it could not determine. FAIL: a fact that contradicts/invents beyond the source, jargon, or an uncertainty silently dropped.',
        evidence: `${digestBlock}${sourceBlock}`,
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
