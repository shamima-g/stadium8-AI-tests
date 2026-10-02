/**
 * Human-review harness — Step 7: wire the first REAL subjective check (intake #476/#478) to a capture.
 *
 * Builds the review manifest for the intake overview's subjective residuals — the ones a lookup can't
 * settle (the deterministic structure/budget/leak/role-set checks stay in auditOverview). The evidence is
 * the actual captured overview + the facts from project.md to compare against, so a reviewer can answer:
 *   #476 facts-correct — do the stated facts match project.md and read correctly (role→action, auth clause)?
 *   #478 detail-pointed — is detail pointed-to not dumped, even paraphrased (what the token-gate can't catch)?
 * Pure over strings; the caller reads the capture (via loadGoldenRun + resolveShippedUserFile).
 */
import { extractSection } from './project-overview';
import type { ReviewManifest } from './build-review';
import type { ReviewCheck } from './review-logic';

export const INTAKE_REVIEW_CHECKS: ReviewCheck[] = [
  { id: 'intake-facts-correct', criterion: 'Do the overview\'s stated facts match project.md and read correctly (roles→actions, the auth clause)?' },
  { id: 'intake-detail-pointed', criterion: 'Is detail pointed-to, not dumped — no permissions/endpoints/palette/NFRs inlined, even paraphrased?' },
];

/** The fact-bearing project.md sections #476 needs to compare against (roles, auth, data source) — NOT the
 *  whole file. Scopes the evidence to the relevant facts and avoids dumping unrelated sections (NFRs,
 *  compliance, styling, seeded test accounts) into the shipped review.html. Falls back to the full file if
 *  no matching heading is found. */
export function factSections(projectMd: string): string {
  const wanted = /(roles|permission|authentication|data\s*source)/i;
  const out: string[] = [];
  let keep = false;
  for (const line of projectMd.split(/\r?\n/)) {
    if (/^#{1,6}\s+/.test(line)) keep = wanted.test(line);
    if (keep) out.push(line);
  }
  return out.join('\n').trim() || projectMd.trim();
}

/** Build the intake review manifest from a captured CLAUDE.md + project.md. Evidence = the written overview
 *  section, plus the fact-bearing project.md sections beneath it so the reviewer can compare facts. */
export function buildIntakeReviewManifest(claudeMd: string, projectMd: string, label = 'intake'): ReviewManifest {
  const overview = extractSection(claudeMd).text.trim() || '(no ## Project Overview section found)';
  const factsBlock = `--- the overview as written (CLAUDE.md) ---\n${overview}\n\n--- facts on record (generated-docs/project.md, roles/auth/data) ---\n${factSections(projectMd)}`;
  return {
    captureLabel: `${label} overview — subjective review`,
    items: [
      {
        id: 'intake-facts-correct',
        criterion: INTAKE_REVIEW_CHECKS[0].criterion,
        guidance: 'PASS: every role/action/auth/data statement is true to project.md and the app. FAIL: a wrong, invented, or garbled fact.',
        evidence: factsBlock,
      },
      {
        id: 'intake-detail-pointed',
        criterion: INTAKE_REVIEW_CHECKS[1].criterion,
        guidance: 'PASS: specifics live in the pointed-to docs; the overview stays headline-level. FAIL: endpoints/permissions/palette/NFRs spelled out here, even paraphrased.',
        evidence: overview,
      },
    ],
  };
}
