/**
 * `/continue` on a non-epic branch reports the project's real state — it does not
 * dead-end with a generic "not on an epic branch" message, and it never points the
 * user at an action they can't take.
 *
 * dev@main's continue.md Step 1b ("No epic on this branch — report where the project
 * stands") runs `collect-dashboard-data.js --format=text` and prints it as-is, then
 * routes the user: a `git checkout` for an epic that HAS a branch, `/start` for a
 * PARKED one — and never a checkout for a parked epic (it has no branch). It also
 * never starts a build (only `/start` does).
 *
 * These are doc/structure checks over continue.md's Step 1b — the instruction the
 * orchestrator follows. They prove the instruction is present and correctly shaped;
 * the live behaviour (that a real run names the *right* parked epic) is a Tier-3
 * eyeball. Each predicate is exercised good (real continue.md) AND broken (a tampered
 * copy) per workflow-tests.md §2 rule 1. Feature-detected on the Step 1b report
 * surface, so templates that only emit the generic message (≤ v1.2.0) SKIP, never
 * fail (§14). RB: temp-project cleanup only.
 *
 * Acceptance criteria covered: names the parked epic + its build command; never
 * suggests an impossible action (a parked-epic checkout); never builds — only /start
 * builds; the report is the same collector output /status shows, so they can't drift.
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT, describeTemplate, createTempProject } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const CONTINUE = path.join(REPO_ROOT, '.claude', 'commands', 'continue.md');
const STATUS = path.join(REPO_ROOT, '.claude', 'commands', 'status.md');
const CONTINUE_MD = fs.existsSync(CONTINUE) ? fs.readFileSync(CONTINUE, 'utf8') : '';

/** Step 1b — the "no epic on this branch" report, from its heading to the next rule/section. */
function noEpicSection(md: string): string {
  // Terminate at the next sub-heading (`### `) too, not just a rule/section — else the
  // capture bleeds into a following `### Step 1c`/`###` and the substring predicates can
  // match text that belongs to that later section (a false PASS).
  const m = md.match(/###\s*Step 1b\b[\s\S]*?(?=\n###\s|\n---|\n## )/i);
  return m ? m[0] : '';
}

// Predicates — each is asserted true over the real doc and false over a tampered one.
/** (report/g) The no-epic path reports state via the shared collector. Tolerates
 * other flags between `.js` and `--format=text` (e.g. `--root .`) so a valid
 * invocation with reordered args isn't missed. */
const reportsRealState = (s: string) => /collect-dashboard-data\.js\b[^\n]*--format=text/.test(s);
/** (c) It never starts a build; only /start builds. */
const neverBuilds = (s: string) => /never start a build/i.test(s) && /\/start\b/.test(s);
/** (a) It names the parked epic and routes it to /start. */
const namesParkedWithStart = (s: string) => /parked/i.test(s) && /\/start\b/.test(s);
/** (b) It never offers a checkout for a parked epic (which has no branch). */
const noParkedCheckout = (s: string) => /never offer a checkout for a parked epic/i.test(s);

const SECTION = noEpicSection(CONTINUE_MD);
// Feature-detect on the PRESENCE of the Step 1b section (its heading), independent of any
// assertion: a template that only emits the generic "not on an epic branch" line
// (≤ v1.2.0) has no Step 1b → SKIP, never fail. Gating on the section — not on
// reportsRealState — means a Step 1b that drops the collector call FAILS the report check
// rather than silently skipping the whole suite (and masking the routing/no-build checks).
const PRESENT = SECTION.length > 0;

describeTemplate('/continue no-epic report — Step 1b reports real state (dev@main)', () => {
  it.skipIf(!PRESENT)('PASS: the no-epic path reports project state via the shared collector', () => {
    expect(reportsRealState(SECTION)).toBe(true);
  });

  it.skipIf(!PRESENT)('PASS: it never starts a build — only /start builds', () => {
    expect(neverBuilds(SECTION)).toBe(true);
  });

  it.skipIf(!PRESENT)('PASS: it names the parked epic and routes it to /start', () => {
    expect(namesParkedWithStart(SECTION)).toBe(true);
  });

  it.skipIf(!PRESENT)('PASS: it never offers a checkout for a parked epic (no such branch)', () => {
    expect(noParkedCheckout(SECTION)).toBe(true);
  });

  it.skipIf(!PRESENT)('PASS: the report is the same collector output /status shows (cannot drift)', () => {
    const status = fs.existsSync(STATUS) ? fs.readFileSync(STATUS, 'utf8') : '';
    expect(reportsRealState(SECTION), '/continue Step 1b runs the collector').toBe(true);
    expect(reportsRealState(status), '/status runs the same collector + format').toBe(true);
  });
});

describe('/continue no-epic report — broken cases are caught', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject(); });
  afterEach(() => { project.cleanup(); });

  function sectionOf(md: string): string {
    project.write('.claude/commands/continue.md', md);
    return noEpicSection(
      fs.readFileSync(path.join(project.root, '.claude', 'commands', 'continue.md'), 'utf8'),
    );
  }

  it('FAIL: the generic "not on an epic branch" message does not report real state', () => {
    // The pre-feature message: a dead-end pointer, no collector, no parked routing.
    const s = sectionOf([
      '## Step 1: Read State',
      '',
      '- **`kind: "none"`** → Not on an epic branch. Run /start to begin a new epic,',
      '  or `git checkout` an existing `epic/*` branch to resume one.',
      '',
      '---',
      '## Phase: PLAN',
      '',
    ].join('\n'));
    expect(reportsRealState(s)).toBe(false);
    expect(neverBuilds(s)).toBe(false);
    expect(namesParkedWithStart(s)).toBe(false);
  });

  it('FAIL: a Step 1b that offers a checkout for a parked epic is caught', () => {
    // The report surface IS present (so it would not skip), but the routing is wrong —
    // it tells the user to check out a branch a parked epic does not have.
    const s = sectionOf([
      '### Step 1b: No epic on this branch',
      '',
      '```bash',
      'node .claude/scripts/collect-dashboard-data.js --format=text',
      '```',
      '',
      'Then `git checkout epic/<slug>` for the parked epic to resume it.',
      '',
      '---',
      '## Phase: PLAN',
    ].join('\n'));
    expect(reportsRealState(s)).toBe(true);   // present → would not skip
    expect(noParkedCheckout(s)).toBe(false);  // ...but the parked-checkout guard is missing → red
  });
});
