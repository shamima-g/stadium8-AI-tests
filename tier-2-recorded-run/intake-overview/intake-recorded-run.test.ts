/**
 * Tier-2 recorded-run invariants for the INTAKE write of CLAUDE.md's `## Project Overview`.
 *
 * Benchmark: **contact-form** (3 roles Visitor/Support Agent/Admin with distinct RBAC, BFF auth, a
 * data source — the lightest fixture that exercises every intake check). Captured by a live `/start`
 * intake run against a release-shaped template, stopped after the intake commit, frozen into the
 * `intake-contact-form` golden slot (see the implementation plan + the intake-capture-benchmark memo).
 *
 * These assert over the CAPTURED run using the already-unit-tested pure core (auditOverview +
 * resolveShippedUserFile). They skip visibly until the capture exists — never a vacuous green.
 *
 * Todos covered when the capture lands: #461 structural whitelist, #462 facts set-equality,
 * #463 never-present + budget, #464 Critical-Rules/Policies unchanged, #465 commit-introduced facts.
 *
 * KNOWN PRODUCT GAP (determinism-checked): the captured INTAKE output does NOT conform to the template's
 * own project-overview.md spec — 2 of 2 completed capture runs (2026-09-30) omitted the pointer line,
 * wrote roles as prose (not backticked exact strings), and labelled the bullet "Data" not "Data source".
 * The full-audit conformance test below is therefore marked `it.fails` (a documented expected-failure);
 * the specific deviations are pinned so a change in failure mode is visible. Tracked for the template
 * owner in findings/intake-project-overview-nonconformance.md. Remove the `.fails` + pin when fixed.
 */
import { describe, it, expect, afterAll } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { loadGoldenRun } from '../../helpers/golden-run';
import { resolveShippedUserFile, auditOverview, criticalRulesAndPoliciesUnchanged, PLACEHOLDER } from '../../helpers/project-overview';

const golden = loadGoldenRun('intake-contact-form');
if (!golden.present) {
  // eslint-disable-next-line no-console
  console.warn('[intake-recorded-run] skipping — ' + golden.reason);
}
afterAll(() => golden.cleanup()); // remove the temp bundle clone (matches the canonical recorded-run suite)

// Resolve the shipped file (CLAUDE.md in a release capture; CLAUDE.user.md in a dev one) + project.md.
const shipped = golden.present && golden.root ? resolveShippedUserFile(golden.root) : null;
const claudeMd = shipped ? fs.readFileSync(shipped.path, 'utf8') : '';
const projectMd = (() => {
  if (!golden.present || !golden.docsDir) return '';
  const p = path.join(golden.docsDir, 'project.md');
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : '';
})();

describe.skipIf(!golden.present)('intake recorded run — CLAUDE.md ## Project Overview (contact-form)', () => {
  it('the capture exposes the shipped CLAUDE.md and generated-docs/project.md', () => {
    expect(shipped, 'a shipped CLAUDE.md / CLAUDE.user.md is present in the capture').not.toBeNull();
    expect(projectMd, 'generated-docs/project.md is present in the capture').not.toBe('');
  });

  it('the pre-intake placeholder is gone — the section describes this project', () => {
    expect(PLACEHOLDER.test(claudeMd)).toBe(false);
  });

  // KNOWN PRODUCT GAP — tracked in findings/intake-project-overview-nonconformance.md.
  // The template's live INTAKE output does NOT yet conform to its own .claude/shared/project-overview.md:
  // across 2 of 2 completed capture runs (2026-09-30) the overview omits the pointer line, writes roles as
  // prose instead of backticked exact strings, and labels the third bullet "Data" not "Data source".
  // This test still asserts the TRUE invariant, but is marked `.fails` so the suite stays green on a
  // DOCUMENTED gap rather than a naked red. When the template is fixed the body will stop throwing, which
  // `it.fails` turns into a RED — at that point delete `.fails` here AND remove the known-gap pin below to
  // restore a normal conformance guard.
  it.fails('the written overview passes the full audit — structure + facts (set-equality) + budget + no-leak (#461-463) [KNOWN GAP]', () => {
    const a = auditOverview(claudeMd, projectMd);
    expect(a.found, 'has a ## Project Overview section').toBe(true);
    expect(a.structure.ok, `structure: ${a.structure.reasons.join('; ')}`).toBe(true);
    expect(a.roles.equal, `overview roles ${JSON.stringify(a.roles.overview)} == project roles ${JSON.stringify(a.roles.project)}`).toBe(true);
    expect(a.budget.ok, `budget ${a.budget.lineCount} lines / ${a.budget.wordCount} words`).toBe(true);
    expect(a.leaks, `leaks: ${a.leaks.map((l) => l.kind).join(', ')}`).toEqual([]);
    expect(a.ok, a.reasons.join(' | ')).toBe(true);
  });

  // Precise pin of the CURRENT (buggy) reality in the frozen capture, so a CHANGE in the failure mode is
  // caught rather than silently absorbed by the coarse `.fails` above. Remove together with the `.fails`
  // marker once the template is fixed. Each assertion flips when the corresponding defect is fixed.
  it('known-gap pin: the frozen capture is non-conforming in exactly the tracked ways (remove when fixed)', () => {
    const a = auditOverview(claudeMd, projectMd);
    expect(a.ok, 'KNOWN GAP (findings/intake-project-overview-nonconformance.md) — expected non-conforming today').toBe(false);
    expect(a.structure.pointerLineCount, 'tracked defect #1: no pointer line').toBe(0);
    expect(a.roles.overview, 'tracked defect #2: roles written as prose, not backticked exact strings').toEqual([]);
    expect(a.structure.bulletLabels, 'tracked defect #3: third bullet is "Data", not "Data source"').toContain('Data');
  });
});

// #464 Critical-Rules/Policies unchanged + #465 commit-introduced — need the capture's git history.
describe.skipIf(!golden.present || !golden.hasGit)('intake recorded run — git-fact invariants', () => {
  const git = golden.git as NonNullable<typeof golden.git>;
  const rel = shipped ? path.basename(shipped.path) : 'CLAUDE.md';

  it('the intake commit (docs(project)) is what wrote the overview (#465, not latest-touch)', () => {
    const subjects = git('log', '--format=%s', '--', rel).stdout;
    expect(subjects, `commits touching ${rel}`).toMatch(/docs\(project\)/i);
    // and the landed section is real facts, not the placeholder
    expect(PLACEHOLDER.test(claudeMd)).toBe(false);
  });

  it('Critical Rules + Policies are byte-unchanged across the intake write (#464, self-diff)', () => {
    const firstSha = git('log', '--reverse', '--format=%H', '--', rel).stdout.split(/\r?\n/).filter(Boolean)[0];
    expect(firstSha, `${rel} has history`).toBeTruthy();
    const before = git('show', `${firstSha}:${rel}`).stdout;
    expect(criticalRulesAndPoliciesUnchanged(before, claudeMd)).toBe(true);
  });
});
