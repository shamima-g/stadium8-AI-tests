/**
 * INTAKE `## Project Overview` (Tier 1, static regression-guards + reusable content analysis).
 *
 * Feature: `/start` writes a lean `## Project Overview` into the shipped CLAUDE.md — headline facts
 * only, everything else pointered, within 12 lines / 150 words, on main in the intake commit,
 * silently, leaving Critical Rules + Policies untouched. Governed by
 * `.claude/shared/project-overview.md`. Already implemented, so the static guards are GREEN-now and
 * pin the wording/wiring against a revert; each is MUTATION-COUPLED (passes on the real text, fails
 * on the regression it guards). The content-analysis helpers are unit-tested here over synthetic
 * good/bad overviews and re-run over real captures at Tier 2/3.
 *
 * Point at a target (PowerShell):
 *   $env:REPO_ROOT="C:\TestsArchives\stadium8-tests\28-09-2026"; $env:EXPECT_TEMPLATE="1"; npm run test:tier1
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { TEMPLATE_DIR, TARGET_ROOT, TEMPLATE_PRESENT, TEMPLATE_REF, NO_TEMPLATE_REASON } from '../../helpers';
import {
  PLACEHOLDER,
  resolveShippedUserFile,
  extractSection,
  withinBudget,
  countWords,
  analyzeStructure,
  neverPresentTokenLeaks,
  parseOverviewRoles,
  roleSetEquals,
  claimsClosedList,
  criticalRulesAndPoliciesUnchanged,
} from '../../helpers/project-overview';
import {
  statesBudget,
  pointerLineExactlyThree,
  neverPresentListIntact,
  allowedFactsIntact,
  statesSilence,
  statesTwoWritePoints,
  statesCorrectDontRewrite,
  intakeWritesOverview,
  intakeCommitStagesClaudeMd,
  mergeRecheckWired,
  mergeLeavesCleanWhenNoChange,
  markCompleteStagesClaudeMd,
  staleIncludesMissingFact,
  upgradeLeavesOverviewAlone,
} from './rules';

// ═══════════════════════════════════════════════════════════════════════════════════════════════
// 1. Static-detector unit tests — each true on the good text AND false on the mutation
// ═══════════════════════════════════════════════════════════════════════════════════════════════

describe('spec guards — project-overview.md (mutation-coupled)', () => {
  it('statesBudget pins the exact literals (mutation: 150 → 200)', () => {
    expect(statesBudget('one pointer line — **within 12 lines and 150 words**.')).toBe(true);
    expect(statesBudget('one pointer line — **within 12 lines and 200 words**.')).toBe(false);
  });

  it('pointerLineExactlyThree counts entries (mutation: append a 4th)', () => {
    const three =
      'Pointer line, exactly three: `generated-docs/project.md` (facts), `generated-docs/epics/` (epics and briefs), `generated-docs/architecture.md` (conventions).';
    expect(pointerLineExactlyThree(three)).toBe(true);
    const four = three.replace('(conventions).', '(conventions), `generated-docs/design/` (design).');
    expect(pointerLineExactlyThree(four)).toBe(false); // 4 targets — self-contradicts "exactly three"
    const dropped = 'Pointer line, exactly three: `generated-docs/project.md`, `generated-docs/architecture.md`.';
    expect(pointerLineExactlyThree(dropped)).toBe(false); // epics/ pointer removed
  });

  it('neverPresentListIntact is span-scoped (mutation: move `permissions` out of the list)', () => {
    const good =
      '| Roles | column headings of §Roles & Permissions | closed list |\n' +
      '**Never present:** permissions, endpoints, palette, compliance domains or requirements, theme, backend connectivity, epics, stories, build progress, timestamps, slugs, NFRs.';
    expect(neverPresentListIntact(good)).toBe(true);
    // mutation: `permissions` deleted FROM THE LIST — but it still occurs at "§Roles & Permissions",
    // so a whole-file grep would stay green. Span-scoping makes it go red.
    const moved =
      '| Roles | column headings of §Roles & Permissions | closed list |\n' +
      '**Never present:** endpoints, palette, compliance domains or requirements, theme, backend connectivity, epics, stories, build progress, timestamps, slugs, NFRs.';
    expect(neverPresentListIntact(moved)).toBe(false);
    // coverage: dropping a token that ISN'T in the AC-headline seven (endpoints) also goes red.
    expect(neverPresentListIntact(good.replace('endpoints, ', ''))).toBe(false);
  });

  it('allowedFactsIntact pins real tokens (mutation: delete the Data-source row)', () => {
    const good =
      '| Roles | headings | closed list; exact string form |\n' +
      '| Auth | Method | session mechanism; what it forbids |\n' +
      '| Data source | Data source + Mock layer | mocks or live |';
    expect(allowedFactsIntact(good)).toBe(true);
    const noDataSource =
      '| Roles | headings | closed list; exact string form |\n' +
      '| Auth | Method | session mechanism; what it forbids |';
    expect(allowedFactsIntact(noDataSource)).toBe(false);
  });

  it('statesSilence / statesTwoWritePoints / statesCorrectDontRewrite', () => {
    expect(statesSilence('- **Silent** — no prompt, no message, including when correcting.')).toBe(true);
    expect(statesSilence('- Announce the change to the user before writing.')).toBe(false);

    const two = 'checked at every epic merge — the only two points it is ever written.\n**Never from an `epic/*` branch** — only where project.md is written.';
    expect(statesTwoWritePoints(two)).toBe(true);
    expect(statesTwoWritePoints('written whenever project.md changes.')).toBe(false);

    const cdr = '**Correct, don\'t rewrite.** … leave `CLAUDE.md` byte-for-byte untouched.';
    expect(statesCorrectDontRewrite(cdr)).toBe(true);
    expect(statesCorrectDontRewrite('Rewrite the section from scratch each merge.')).toBe(false);
  });

  it('staleIncludesMissingFact requires both facets, order/punctuation independent', () => {
    expect(staleIncludesMissingFact('Stale means it contradicts `project.md`, or a stated fact is missing. Worded differently is not stale.')).toBe(true);
    // reorder must NOT false-red (facets checked independently)
    expect(staleIncludesMissingFact('Stale means a stated fact is missing, or it contradicts `project.md`.')).toBe(true);
    // mutation: narrow to contradiction-only → a generic (all-absent) overview would never backfill → red.
    expect(staleIncludesMissingFact('Stale means it contradicts `project.md`.')).toBe(false);
    // mutation: drop the contradiction facet → red.
    expect(staleIncludesMissingFact('Stale means a stated fact is missing.')).toBe(false);
  });
});

describe('upgrade guard — upgrade.md never-touch/never-ask (whole-file, fence-stripped)', () => {
  const GOOD =
    '## Step 5: Merge the mixed files (judgment)\n\n' +
    'Update only the template-owned parts; preserve everything the project added. Do this\n' +
    'yourself — never ask.\n\n' +
    '- **`CLAUDE.md`** — **never touch `## Project Overview`**, which the workflow maintains.\n';

  it('true on the well-formed wording', () => {
    expect(upgradeLeavesOverviewAlone(GOOD)).toBe(true);
  });
  it('mutation: delete the never-touch-overview clause → red', () => {
    expect(upgradeLeavesOverviewAlone(GOOD.replace('**never touch `## Project Overview`**, which the workflow maintains.', 'merge the template sections.'))).toBe(false);
  });
  it('mutation: delete the never-ask clause → red', () => {
    expect(upgradeLeavesOverviewAlone(GOOD.replace('Do this\nyourself — never ask.', 'Do this yourself.'))).toBe(false);
  });
  it('a generic "never touch web/src" (no overview clause) does NOT satisfy it', () => {
    expect(upgradeLeavesOverviewAlone('Never touch `web/src/`. Do this yourself — never ask.')).toBe(false);
  });
  it('a bare "never ask" (not the full phrase) does NOT satisfy it', () => {
    expect(upgradeLeavesOverviewAlone('- never touch `## Project Overview`.\nnever ask the user to review a diff.')).toBe(false);
  });
  it('relaxed adjacency: "never touch the `## Project Overview` section" still matches (no false-red)', () => {
    expect(upgradeLeavesOverviewAlone('never touch the `## Project Overview` section. Do this yourself — never ask.')).toBe(true);
  });
  it('fence-stripped: the phrases only inside a ``` example do NOT count', () => {
    const fencedOnly = '```md\nnever touch `## Project Overview`\nDo this yourself — never ask.\n```\nStep 5 actually rewrites the overview.';
    expect(upgradeLeavesOverviewAlone(fencedOnly)).toBe(false);
  });
});

describe('wiring guards — start.md / continue.md (mutation-coupled)', () => {
  it('intakeWritesOverview (mutation: delete the write step)', () => {
    expect(
      intakeWritesOverview("**4. Write `CLAUDE.md`'s `## Project Overview`** per [project-overview.md](../shared/project-overview.md)."),
    ).toBe(true);
    expect(intakeWritesOverview('**4. Write `generated-docs/epic-plan.md`** from the approved proposal.')).toBe(false);
  });

  it('intakeCommitStagesClaudeMd is scoped to the intake-commit block', () => {
    const COMMIT = 'git commit -m "docs(project): project setup + epic plan"';
    expect(intakeCommitStagesClaudeMd(`git add generated-docs/ documentation/ CLAUDE.md\n${COMMIT}`)).toBe(true);
    // split staging — CLAUDE.md on its own line within the block — stays green (no false-red)
    expect(intakeCommitStagesClaudeMd(`git add generated-docs/ documentation/\ngit add CLAUDE.md\n${COMMIT}`)).toBe(true);
    expect(intakeCommitStagesClaudeMd(`git add -A\n${COMMIT}`)).toBe(true); // whole-tree add still stages it
    // mutation: CLAUDE.md dropped from the intake staging → red
    expect(intakeCommitStagesClaudeMd(`git add generated-docs/ documentation/\n${COMMIT}`)).toBe(false);
    // an unrelated `git add -A` before a DIFFERENT commit must not create a false-green
    const unrelated =
      'git add -A\ngit commit -m "chore: unrelated"\ngit add generated-docs/ documentation/\n' + COMMIT;
    expect(intakeCommitStagesClaudeMd(unrelated)).toBe(false);
  });

  it('mergeRecheckWired (mutation: delete B7.2.6 alignment)', () => {
    expect(
      mergeRecheckWired("First bring `CLAUDE.md`'s `## Project Overview` into line with `generated-docs/project.md`, per [project-overview.md](../shared/project-overview.md)."),
    ).toBe(true);
    expect(mergeRecheckWired('Flip the phase to COMPLETE and commit on main.')).toBe(false);
  });

  it('mergeLeavesCleanWhenNoChange pins the WHOLE no-op expression (5 real regressions go red)', () => {
    const good = '```bash\n# only when you corrected nothing\ngit diff --quiet -- CLAUDE.md || git checkout -- CLAUDE.md\n```';
    expect(mergeLeavesCleanWhenNoChange(good)).toBe(true);
    expect(mergeLeavesCleanWhenNoChange('git diff --quiet -- CLAUDE.md')).toBe(false);         // dropped `|| git checkout`
    expect(mergeLeavesCleanWhenNoChange('git checkout -- CLAUDE.md')).toBe(false);             // bare checkout = always discard corrections
    expect(mergeLeavesCleanWhenNoChange('git diff --quiet -- CLAUDE.md && git checkout -- CLAUDE.md')).toBe(false); // ||→&&
    expect(mergeLeavesCleanWhenNoChange('git diff -- CLAUDE.md || git checkout -- CLAUDE.md')).toBe(false);         // dropped --quiet
    expect(mergeLeavesCleanWhenNoChange('git diff --quiet -- state.json || git checkout -- CLAUDE.md')).toBe(false); // pathspec off CLAUDE.md
    // NOT-a-grep: the literal in prose/comment must NOT count when the live command is broken.
    expect(mergeLeavesCleanWhenNoChange('git checkout -- CLAUDE.md\nNever run git diff --quiet -- CLAUDE.md || git checkout -- CLAUDE.md blindly.')).toBe(false);
    expect(mergeLeavesCleanWhenNoChange('git checkout -- CLAUDE.md\n# ref: git diff --quiet -- CLAUDE.md || git checkout -- CLAUDE.md')).toBe(false);
  });

  it('markCompleteStagesClaudeMd is command-line-scoped, every-match, block-bounded', () => {
    const COMMIT = 'git commit -m "chore(my-slug): mark epic complete"';
    // real shape: the no-op `git checkout -- CLAUDE.md` sits just above the git add + commit.
    const real = 'git diff --quiet -- CLAUDE.md || git checkout -- CLAUDE.md\n' +
      'node .claude/scripts/mark-epic-complete.js --slug my-slug\n' +
      'git add generated-docs/epics/my-slug/state.json CLAUDE.md\n' + COMMIT;
    expect(markCompleteStagesClaudeMd(real)).toBe(true);
    // split staging + whole-tree add stay green (no false-red)
    expect(markCompleteStagesClaudeMd(`git add generated-docs/epics/my-slug/state.json\ngit add CLAUDE.md\n${COMMIT}`)).toBe(true);
    expect(markCompleteStagesClaudeMd(`git add -A\n${COMMIT}`)).toBe(true);
    // MUTATION: drop CLAUDE.md from the git add, LEAVING the `git checkout -- CLAUDE.md` no-op intact —
    // the no-op line contains CLAUDE.md but isn't a `git add`, so this is red.
    expect(markCompleteStagesClaudeMd('git diff --quiet -- CLAUDE.md || git checkout -- CLAUDE.md\ngit add generated-docs/epics/my-slug/state.json\n' + COMMIT)).toBe(false);
    // false-green #1 (comment counted as command): a `# … git add … CLAUDE.md` comment must NOT count.
    expect(markCompleteStagesClaudeMd('# git add generated-docs/epics/my-slug/state.json CLAUDE.md\ngit add generated-docs/epics/my-slug/state.json\n' + COMMIT)).toBe(false);
    // false-green #2 (first-match): an EXAMPLE commit that keeps CLAUDE.md must not mask a REAL one that drops it.
    expect(markCompleteStagesClaudeMd(
      'git add generated-docs/epics/demo/state.json CLAUDE.md\ngit commit -m "chore(demo): mark epic complete"\n' +
      'git add generated-docs/epics/real/state.json\ngit commit -m "chore(real): mark epic complete"')).toBe(false);
    // false-green (prev-commit break): an unrelated `git add -A` under a DIFFERENT commit must not leak in.
    expect(markCompleteStagesClaudeMd(
      'git add -A\ngit commit -m "chore(x): something"\ngit add generated-docs/epics/x/state.json\n' +
      'git commit -m "chore(x): mark epic complete"')).toBe(false);
    // false-red (window): a correct git add many lines above the commit (same block) still passes.
    expect(markCompleteStagesClaudeMd(
      'git add generated-docs/epics/x/state.json CLAUDE.md\n' + 'echo step\n'.repeat(12) + COMMIT)).toBe(true);
    // rename/remove the mark-complete commit → anchor miss → red
    expect(markCompleteStagesClaudeMd('git add generated-docs/ CLAUDE.md\ngit commit -m "chore: something else"')).toBe(false);
  });
});

// ═══════════════════════════════════════════════════════════════════════════════════════════════
// 2. Content-analysis unit tests — the reusable core Tier 2/3 run over real captures
// ═══════════════════════════════════════════════════════════════════════════════════════════════

// A well-formed overview (the spec's "Shape to match", roles kept generic to the fixture).
const GOOD = `## Project Overview

Transaction Import & Approval System: an internal financial-operations console. An Importer uploads bank-transaction files and tracks processing; an Approver reviews, approves, rejects or exports the transactions.

- Roles: \`Importer\`, \`Approver\` (exact backend strings; no other role exists).
- Auth: server-side, browser-managed session cookie. No token in frontend code.
- Data source: existing API, two backend services. Build against mocks unless the backend is up.

Facts and detail: \`generated-docs/project.md\`. Epics and briefs: \`generated-docs/epics/\`. Reusable code and conventions: \`generated-docs/architecture.md\`.`;

describe('extractSection + budget (fixed conventions)', () => {
  it('extracts heading→last-non-blank, trailing blanks excluded', () => {
    const md = `${GOOD}\n\n\n## Repository Structure\n\nstuff`;
    const s = extractSection(md);
    expect(s.found).toBe(true);
    expect(s.lines[0]).toBe('## Project Overview');
    expect(s.lines[s.lines.length - 1]).toMatch(/architecture\.md/); // no trailing blanks
  });

  it('GOOD is within budget; a cosmetic blank before the next heading does NOT inflate lines', () => {
    const b = withinBudget(extractSection(`${GOOD}\n\n\n## Next\n`));
    expect(b.ok).toBe(true);
    expect(b.lineCount).toBeLessThanOrEqual(12);
    expect(b.wordCount).toBeLessThanOrEqual(150);
  });

  it('a 13-line section fails the line budget', () => {
    const bloated = GOOD.replace(
      '- Data source:',
      '- Extra one\n- Extra two\n- Extra three\n- Extra four\n- Extra five\n- Extra six\n- Data source:',
    );
    expect(withinBudget(extractSection(bloated)).ok).toBe(false);
  });

  it('countWords is whitespace tokens (not GNU wc)', () => {
    expect(countWords('one two   three\nfour')).toBe(4);
    expect(countWords('   ')).toBe(0);
  });

  it('fail-closed on a missing heading', () => {
    expect(extractSection('# CLAUDE.md\n\nno overview here').found).toBe(false);
  });

  it('is fence-aware: a `## Project Overview` inside a code fence is not mistaken for the section', () => {
    const md = '# CLAUDE.md\n\n```md\n## Project Overview\nfake sample\n```\n\n## Project Overview\n\nReal lead-in.\n\n- Roles: `A`, `B`.';
    const s = extractSection(md);
    expect(s.found).toBe(true);
    expect(s.text).toContain('Real lead-in.');
    expect(s.text).not.toContain('fake sample');
  });

  it('is indent-aware at the end: an indented next-## still ends the section', () => {
    const s = extractSection('## Project Overview\nbody\n   ## Next\nleak');
    expect(s.text).not.toContain('leak');
    expect(s.lineCount).toBe(2);
  });
});

describe('analyzeStructure — the load-bearing whitelist', () => {
  it('accepts the well-formed shape', () => {
    const r = analyzeStructure(extractSection(GOOD).text);
    expect(r.ok, r.reasons.join('; ')).toBe(true);
    expect(r.bulletLabels.map((l) => l.toLowerCase())).toEqual(['roles', 'auth', 'data source']);
    expect(r.pointerLineCount).toBe(1);
  });

  it('REJECTS a compliance leak smuggled as a 4th bullet (paraphrase-proof)', () => {
    // No literal "compliance" token — a blocklist would miss it; the whitelist catches the extra bullet.
    const leak = GOOD.replace(
      '\nFacts and detail:',
      '\n- Regulatory: must meet GDPR and PCI-DSS before go-live.\n\nFacts and detail:',
    );
    const r = analyzeStructure(extractSection(leak).text);
    expect(r.ok).toBe(false);
    expect(r.bulletLabels.length).toBe(4);
  });

  it('REJECTS a stray sub-heading, table, or code fence', () => {
    expect(analyzeStructure(extractSection(GOOD.replace('\nFacts', '\n### Permissions\nImporter can upload.\n\nFacts')).text).ok).toBe(false);
    expect(analyzeStructure(extractSection(GOOD.replace('\nFacts', '\n| Role | Can |\n|---|---|\n\nFacts')).text).ok).toBe(false);
  });

  it('REJECTS a dropped pointer line (pointer-count != 1)', () => {
    const noPtr = GOOD.split('\n').filter((l) => !/generated-docs\//.test(l)).join('\n');
    expect(analyzeStructure(extractSection(noPtr).text).pointerLineCount).toBe(0);
    expect(analyzeStructure(extractSection(noPtr).text).ok).toBe(false);
  });
});

describe('neverPresentTokenLeaks — cheap NECESSARY gate (with data-source carve-out)', () => {
  it('clean on the GOOD section', () => {
    expect(neverPresentTokenLeaks(extractSection(GOOD).text)).toEqual([]);
  });

  it('does NOT flag the ALLOWED data-source line (existing API / backend services / mocks)', () => {
    expect(neverPresentTokenLeaks('- Data source: existing API, two backend services. Build against mocks.')).toEqual([]);
  });

  it('flags hex (incl. RGBA), any-scheme URLs, ports, endpoint paths, progress %, and slash-dated timestamps', () => {
    expect(neverPresentTokenLeaks('accent #3B82F6').some((l) => l.kind === 'palette/hex')).toBe(true);
    expect(neverPresentTokenLeaks('accent #abcd').some((l) => l.kind === 'palette/hex')).toBe(true); // 4-digit RGBA
    expect(neverPresentTokenLeaks('reachable at https://api.example.com/v1/txns').some((l) => l.kind === 'endpoint/url')).toBe(true);
    expect(neverPresentTokenLeaks('socket ws://host/feed').some((l) => l.kind === 'endpoint/url')).toBe(true); // non-http scheme
    expect(neverPresentTokenLeaks('listens on port 8080').some((l) => l.kind === 'port')).toBe(true);
    expect(neverPresentTokenLeaks('the backend is reachable now').some((l) => l.kind === 'connectivity')).toBe(true);
    expect(neverPresentTokenLeaks('50% complete').some((l) => l.kind === 'progress')).toBe(true);
    expect(neverPresentTokenLeaks('captured 2026/09/28').some((l) => l.kind === 'timestamp')).toBe(true);
  });

  it('is necessary-not-sufficient: a paraphrase leak passes the gate (Tier-3 judge catches it)', () => {
    // "meets GDPR" leaks compliance with no literal token — documents WHY the gate can't stand alone.
    expect(neverPresentTokenLeaks('- Notes: the app meets GDPR.')).toEqual([]);
  });
});

describe('fact agreement — set-equality, not subset (catches a dropped 3rd role)', () => {
  it('parses roles and requires SET EQUALITY against project.md', () => {
    expect(parseOverviewRoles(GOOD)).toEqual(['Importer', 'Approver']);
    expect(roleSetEquals(['Importer', 'Approver'], ['Approver', 'Importer'])).toBe(true);
    // project.md has a 3rd role the overview omitted while still claiming a closed list → must fail.
    expect(roleSetEquals(['Importer', 'Approver'], ['Importer', 'Approver', 'Auditor'])).toBe(false);
  });

  it('claimsClosedList detects the "no other role exists" assertion', () => {
    expect(claimsClosedList(GOOD)).toBe(true);
    expect(claimsClosedList('- Roles: `Importer`, `Approver`.')).toBe(false);
  });
});

describe('criticalRulesAndPoliciesUnchanged — pre-vs-post self-diff (NOT vs a frozen template)', () => {
  const before = '# CLAUDE.md\n\n## Project Overview\n\nNo project yet.\n\n## Critical Rules\n\n### 1. Use Shadcn\n\n## Policies\n\n- Auth intake\n';
  it('true when intake only rewrote the overview', () => {
    const after = before.replace('No project yet.', 'Real app. \n\n- Roles: `A`, `B`.');
    expect(criticalRulesAndPoliciesUnchanged(before, after)).toBe(true);
  });
  it('false when intake touched Critical Rules', () => {
    const after = before.replace('### 1. Use Shadcn', '### 1. Use Shadcn\n### 2. Injected by intake');
    expect(criticalRulesAndPoliciesUnchanged(before, after)).toBe(false);
  });
  it('a user-added rule is NOT flagged (self-diff, so both sides carry it)', () => {
    const withUserRule = before.replace('### 1. Use Shadcn', '### 1. Use Shadcn\n### 99. My own rule');
    const after = withUserRule.replace('No project yet.', 'Real app.');
    expect(criticalRulesAndPoliciesUnchanged(withUserRule, after)).toBe(true);
  });
  it('fail-closed: absent protected sections do NOT pass vacuously', () => {
    const noSections = '# CLAUDE.md\n\n## Project Overview\n\nApp.';
    expect(criticalRulesAndPoliciesUnchanged(noSections, noSections)).toBe(false);
  });
  it('a trailing-space-only heading difference is not a false-red', () => {
    const after = before.replace('## Critical Rules', '## Critical Rules ');
    expect(criticalRulesAndPoliciesUnchanged(before, after)).toBe(true);
  });
});

// ═══════════════════════════════════════════════════════════════════════════════════════════════
// Fail-closed: template AND the shipped-user file present when explicitly expected
// ═══════════════════════════════════════════════════════════════════════════════════════════════

it('template + shipped-user file resolve when EXPECT_TEMPLATE is set', () => {
  if (!process.env.EXPECT_TEMPLATE) return;
  expect(TEMPLATE_PRESENT).toBe(true);
  // TEMPLATE_PRESENT only probes .claude/scripts — the overview lives in the top-level shipped file,
  // so assert THAT resolved too (a cleaned-up overview target must fail, not skip).
  const shipped = resolveShippedUserFile(TARGET_ROOT);
  expect(shipped, 'no shipped-user file (CLAUDE.md/CLAUDE.user.md) at target').not.toBeNull();
  if (process.env.EXPECT_TEMPLATE_REF) expect(TEMPLATE_REF).toBe(process.env.EXPECT_TEMPLATE_REF);
});

// ═══════════════════════════════════════════════════════════════════════════════════════════════
// 3. Regression over the real template (green-now; pins spec + wiring + the placeholder anchor)
// ═══════════════════════════════════════════════════════════════════════════════════════════════

const read = (p: string) => fs.readFileSync(p, 'utf8');
const SPEC = path.join(TEMPLATE_DIR, 'shared', 'project-overview.md');
const START = path.join(TEMPLATE_DIR, 'commands', 'start.md');
const CONTINUE = path.join(TEMPLATE_DIR, 'commands', 'continue.md');
const UPGRADE = path.join(TEMPLATE_DIR, 'commands', 'upgrade.md');

describe.skipIf(!TEMPLATE_PRESENT)('regression — spec + wiring present in the real template', () => {
  it('project-overview.md states budget, exactly-3 pointers, never-present list, allowed facts', () => {
    const md = read(SPEC);
    expect(statesBudget(md), 'budget').toBe(true);
    expect(pointerLineExactlyThree(md), 'exactly-3 pointers').toBe(true);
    expect(neverPresentListIntact(md), 'never-present list').toBe(true);
    expect(allowedFactsIntact(md), 'allowed facts').toBe(true);
  });

  it('project-overview.md states silence, two write points, correct-don\'t-rewrite, stale-includes-missing', () => {
    const md = read(SPEC);
    expect(statesSilence(md), 'silence').toBe(true);
    expect(statesTwoWritePoints(md), 'two write points').toBe(true);
    expect(statesCorrectDontRewrite(md), "correct-don't-rewrite").toBe(true);
    expect(staleIncludesMissingFact(md), 'stale includes a missing fact (backfill trigger)').toBe(true);
  });

  it('upgrade.md adds no overview migration (never touch ## Project Overview / never ask)', () => {
    expect(upgradeLeavesOverviewAlone(read(UPGRADE))).toBe(true);
  });

  it('start.md writes the overview and stages CLAUDE.md in the intake commit', () => {
    const md = read(START);
    expect(intakeWritesOverview(md), 'write step').toBe(true);
    expect(intakeCommitStagesClaudeMd(md), 'stages CLAUDE.md').toBe(true);
  });

  it('continue.md wires B7.2.6: re-check, idempotence no-op, and mark-complete staging CLAUDE.md', () => {
    const md = read(CONTINUE);
    expect(mergeRecheckWired(md), 're-align sentence').toBe(true);
    expect(mergeLeavesCleanWhenNoChange(md), 'idempotence no-op').toBe(true);
    expect(markCompleteStagesClaudeMd(md), 'mark-complete stages CLAUDE.md').toBe(true);
  });

  it('must-survive tripwire: the shipped-user file still carries the PLACEHOLDER anchor', () => {
    // Protects the Tier-3 "placeholder gone" baseline: both import PLACEHOLDER, so a reworded
    // template placeholder forces the Tier-3 anchor to update in lockstep instead of rotting.
    const shipped = resolveShippedUserFile(TARGET_ROOT);
    expect(shipped, NO_TEMPLATE_REASON).not.toBeNull();
    const section = extractSection(read(shipped!.path));
    expect(section.found, 'shipped file has a ## Project Overview').toBe(true);
    expect(PLACEHOLDER.test(section.text), 'pre-intake placeholder present').toBe(true);
  });
});

// ═══════════════════════════════════════════════════════════════════════════════════════════════
// Tier 2 — recorded-run invariants (PENDING). Blocked on a captured intake golden run + a SECOND
// golden-run slot (the single fixtures/golden-run/ slot is occupied by minimal-concurrent). The
// analysis above (extractSection / analyzeStructure / neverPresentTokenLeaks / roleSetEquals /
// criticalRulesAndPoliciesUnchanged) is what these will call — see the test plan § Tier 2.
// ═══════════════════════════════════════════════════════════════════════════════════════════════

describe('Tier 2 — recorded-run invariants (pending a captured intake golden run)', () => {
  it.todo('structural whitelist holds over the written CLAUDE.md (lead-in + 3 bullets + 1 pointer line, nothing else)');
  it.todo('facts by set-equality vs project.md §Roles/§Authentication/§Data Source; closed-list claim true; auth forbid clause present');
  it.todo('never-present token gate clean; data-source line allowed; budget met under the fixed conventions');
  it.todo('Critical Rules + Policies spans byte-identical across the write (pre-vs-post self-diff)');
  it.todo('the commit that INTRODUCED the fact bytes is the intake commit on main; span is non-placeholder (git blame, not latest-touch)');
});

// ═══════════════════════════════════════════════════════════════════════════════════════════════
// Tier 3 — behavioural (PENDING, the real AC verification). Blocked on: a net-new intake scenario
// (or build-scenario post-run asserts), an AskUserQuestion extractor over the raw *-claude.jsonl(.gz)
// for the silence check, a near-ceiling budget fixture, and -Target release resolution. See the
// test plan § Tier 3 + § Feasibility.
// ═══════════════════════════════════════════════════════════════════════════════════════════════

describe('Tier 3 — behavioural (pending harness infra)', () => {
  it.todo('facts stated, correct, and agree with project.md — incl. role→action mapping and the auth forbid clause (judge)');
  it.todo('placeholder (shared PLACEHOLDER) is gone, replaced by this project\'s facts');
  it.todo('detail is pointered not present — semantic judge per never-present category (paraphrase-proof)');
  it.todo('budget ≤12 lines / ≤150 words on the copied section; stressed by a near-ceiling fixture (3+ / long verbatim roles)');
  it.todo('landed on main in the intake commit; ZERO AskUserQuestion between intake-approval and the CLAUDE.md commit');
  it.todo('Critical Rules + Policies unchanged by intake (self-diff)');
  it.todo('second write point: B7.2.6 corrects a staled fact without rewriting, or leaves the file untouched when nothing is stale');
});

if (!TEMPLATE_PRESENT) {
  // eslint-disable-next-line no-console
  console.warn('[intake-overview] ' + NO_TEMPLATE_REASON);
}
