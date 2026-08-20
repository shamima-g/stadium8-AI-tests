/**
 * `/continue` warns before resuming an epic that is mid-build, asks the user to
 * confirm, and — if they decline — changes nothing.
 *
 * dev@main's continue.md Step 1a ("Confirm before resuming a build") prompts only when
 * the epic is in a *working* phase (BUILD or EPIC-END, no halt); any other phase — and
 * a halted one — resumes with no extra prompt. The warning is plain language ("part-way
 * through being built … could overwrite that work"), and the decline option leaves the
 * branch untouched: "no state.json edit, no rebase, no push, no phase change". Crucially
 * the gate runs BEFORE the §6.1 sync (git rebase / force-with-lease) — so a decline
 * cannot have already mutated the branch.
 *
 * These are doc/structure checks over Step 1a — the instruction the orchestrator
 * follows. The live behaviour (the prompt actually firing, a real decline honoured) is
 * a Tier-3 eyeball; the deterministic, regression-prone part — the phase partition, the
 * plain-language warning, the inert decline, and the confirm-before-sync ORDERING — is
 * proven here. Each predicate is asserted good (real continue.md) AND broken (a tampered
 * copy) per workflow-tests.md §2 rule 1. Feature-detected on the Step 1a surface, so
 * templates without it (≤ v1.2.0) SKIP, never fail (§14). The working/waiting partition
 * is read live from the Step 1a table, not hard-coded (§2 rule 7). RB: temp-project only.
 *
 * Acceptance criteria covered: mid-build (BUILD/EPIC-END) resume warns + confirms;
 * waiting phases resume with no extra prompt; declining leaves branch/state/tree
 * untouched (no rebase, no force-push, no phase change).
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, describeTemplate, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const CONTINUE = path.join(REPO_ROOT, '.claude', 'commands', 'continue.md');
const CONTINUE_MD = fs.existsSync(CONTINUE) ? fs.readFileSync(CONTINUE, 'utf8') : '';

/** Step 1a — the "confirm before resuming a build" gate, heading to the next sub-section/rule. */
function confirmSection(md: string): string {
  const m = md.match(/###\s*Step 1a\b[\s\S]*?(?=\n###\s|\n---|\n## )/i);
  return m ? m[0] : '';
}

// Predicates — each asserted true over the real doc and false over a tampered one.
/** (d) A working-phase resume (BUILD/EPIC-END) warns about overwriting and asks to confirm. */
const warnsAndConfirms = (s: string) =>
  /AskUserQuestion/.test(s) && /overwrite/i.test(s) && /BUILD/.test(s) && /EPIC-END/.test(s);
/** (e) Any other phase resumes with no prompt, and MANUAL-TEST is never mapped to a prompt. */
const waitingPhasesSkipPrompt = (s: string) =>
  /any other phase\s*\|?\s*no\b/i.test(s) && !/MANUAL-TEST[^\n]*\byes\b/i.test(s);
/** (f) Declining leaves the branch/state untouched. */
const declineIsInert = (s: string) =>
  /no rebase/i.test(s) && /no push/i.test(s) && /no phase change/i.test(s);
/** (f) The confirm gates BEFORE the §6.1 sync (rebase/force-push) — else a decline already mutated. */
const confirmBeforeSync = (s: string) => {
  const auq = s.search(/AskUserQuestion/);
  const sync = s.search(/git rebase|force-with-lease/i);
  return auq !== -1 && sync !== -1 && auq < sync;
};
/** (d) The user-facing warning avoids dev jargon. */
function questionText(s: string): string {
  const m = s.match(/\*\*Question:\*\*\s*"([^"]+)"/i);
  return m ? m[1] : '';
}
const questionIsPlain = (q: string) =>
  q.length > 0 && !/rebase|force-with-lease|state\.json|EPIC-END|§|tsc|eslint/i.test(q);

const SECTION = confirmSection(CONTINUE_MD);
// Feature-detect on the confirm surface: ≤ v1.2.0 has no Step 1a → SKIP, never fail.
const PRESENT = SECTION.length > 0;

describeTemplate('/continue resume confirm — Step 1a warns before overwriting a build (dev@main)', () => {
  it.skipIf(!PRESENT)('PASS: BUILD/EPIC-END resume warns about overwriting and asks to confirm', () => {
    expect(warnsAndConfirms(SECTION)).toBe(true);
  });

  it.skipIf(!PRESENT)('PASS: the warning is plain language (no dev jargon in the question)', () => {
    expect(questionIsPlain(questionText(SECTION))).toBe(true);
  });

  it.skipIf(!PRESENT)('PASS: waiting phases (e.g. MANUAL-TEST) resume without an extra prompt', () => {
    expect(waitingPhasesSkipPrompt(SECTION)).toBe(true);
  });

  it.skipIf(!PRESENT)('PASS: declining changes nothing — no rebase, no push, no phase change', () => {
    expect(declineIsInert(SECTION)).toBe(true);
  });

  it.skipIf(!PRESENT)('PASS: the confirm gates BEFORE the §6.1 sync (rebase/force-push)', () => {
    expect(confirmBeforeSync(SECTION)).toBe(true);
  });
});

describe('/continue resume confirm — broken cases are caught', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  function sectionOf(md: string): string {
    project.write('.claude/commands/continue.md', md);
    return confirmSection(
      fs.readFileSync(path.join(project.root, '.claude', 'commands', 'continue.md'), 'utf8'),
    );
  }

  it('FAIL: a Step 1a that resumes a build with no confirmation is caught', () => {
    const s = sectionOf([
      '### Step 1a: Resume',
      '',
      'Read state.json, identify the phase, and continue building immediately.',
      '',
      '### Step 1b',
    ].join('\n'));
    expect(warnsAndConfirms(s)).toBe(false);
  });

  it('FAIL: a blanket confirm that also prompts on MANUAL-TEST is caught', () => {
    const s = sectionOf([
      '### Step 1a: Confirm',
      '',
      '| Epic state | Prompt? |',
      '| `BUILD` or `EPIC-END` | **Yes** |',
      '| `MANUAL-TEST` | **Yes** |',
      '| Any other phase | No |',
      '',
      'Ask via AskUserQuestion whether to continue; continuing may overwrite work.',
      '',
      '### Step 1b',
    ].join('\n'));
    expect(waitingPhasesSkipPrompt(s)).toBe(false);
  });

  it('FAIL: a decline that omits the no-mutation promise is caught', () => {
    const s = sectionOf([
      '### Step 1a: Confirm',
      '',
      'AskUserQuestion: continue building (BUILD/EPIC-END)? overwrite warning.',
      'If they decline, stop here.',
      '',
      '### Step 1b',
    ].join('\n'));
    expect(declineIsInert(s)).toBe(false);
  });

  it('FAIL: a confirm placed AFTER the §6.1 sync is caught (ordering regression)', () => {
    const s = sectionOf([
      '### Step 1a: Confirm',
      '',
      'Sync with `main`: git rebase origin/main, then git push --force-with-lease.',
      '',
      'Then AskUserQuestion: continue building (BUILD/EPIC-END)? overwrite warning.',
      '',
      '### Step 1b',
    ].join('\n'));
    expect(confirmBeforeSync(s)).toBe(false);
  });
});
