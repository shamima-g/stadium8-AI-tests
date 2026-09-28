# Test plan — every epic merge re-aligns CLAUDE.md with project.md, and never churns

**Testing against:** the template clone at `C:\TestsArchives\stadium8-tests\28-09-2026` (commit
`34a574a`, dev marker — shipped user file is `CLAUDE.user.md`, see the intake plan's "Which file is
under test"). **Pairs with** `intake-claudemd-project-overview-test-plan.md`: that plan covers the
*first* write point (INTAKE); this one covers the *second* (epic merge).
**Run static tier (PowerShell):**
`$env:REPO_ROOT="C:\TestsArchives\stadium8-tests\28-09-2026"; $env:EXPECT_TEMPLATE="1"; npm run test:tier1`
(from `c:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests`).

---

## ⛔ GATING BLOCKER (read first) — the harness cannot run B7.2.6 today

The feature under test lives **entirely downstream of `gh pr merge`**, and no Tier-3 scenario can
reach it:

- **`build` (the default scenario) short-circuits before the merge.** At B7.2.1
  ([continue.md:648](.claude/commands/continue.md)): *"check the remote; if `git remote -v` is empty,
  **the rest of B7.2 doesn't apply**"* — it prints a manual-merge line and ends `/continue`. The
  `build` scaffold copies the template **excluding `.git`** and creates **no remote**, so B7.2.5
  (merge) and **B7.2.6 (the CLAUDE.md re-check) never execute.**
- **`concurrent` has only a *local bare* remote** (`git init --bare`), which is non-empty so the flow
  proceeds to B7.2.2 `gh pr create` — but `gh` needs github.com and **isn't even a Setup
  prerequisite**. It can't create/merge a PR against a file remote.

**Consequence:** all of Tier 2 and Tier 3 below — correction, idempotence/no-churn, one-commit-after-
merge topology, and the design-update discriminator — are **unreachable on today's harness**, and the
three Tier-2 golden captures **cannot be produced**. **A mergeable Tier-3 sandbox is a gating
prerequisite, not an assumed capability.** It requires one of:

1. a real throwaway GitHub repo per run + authenticated `gh` (network, auth, cleanup, a new mandatory
   prerequisite; flaky), or
2. a **product change** so B7.2.6 also runs on the no-remote **local-merge** path
   (`git checkout main && git merge epic/<slug>`) — arguably the right fix, since the re-check
   shouldn't depend on GitHub.

**Tier 1 is unaffected and ships now** (it only pins wording/wiring in `continue.md`; no merge needed).

---

## The feature under test

`## Project Overview` in the shipped `CLAUDE.md` is written at exactly two points (spec:
[.claude/shared/project-overview.md](.claude/shared/project-overview.md)). This plan is the **second
point: every epic merge**, wired at [continue.md](.claude/commands/continue.md) **B7.2.6**. At merge,
the workflow:

1. **Re-checks the section against `project.md`** and **corrects a stale or hand-altered fact** —
   silently (no prompt, no message, "including when correcting words the user wrote").
2. **Does nothing when it already agrees** — "Write nothing when nothing is stale — leave `CLAUDE.md`
   **byte-for-byte untouched**." The no-op `git diff --quiet -- CLAUDE.md || git checkout -- CLAUDE.md`
   (continue.md:741) discards any accidental rewrite so the file **never churns**.

The corrected write is performed by the **orchestrator** at B7.2.6:737 (an `Edit` on `main` after the
`:725` checkout) and then **staged by** the `chore(<slug>): mark epic complete` commit
(continue.md:747–750). *(Note: `mark-epic-complete.js` itself only flips `state.json` `phase` →
`COMPLETE`; it does not touch `CLAUDE.md` — see "corrections" below.)*

**Acceptance criterion (as given).** Every epic merge brings CLAUDE.md back into line with project.md,
and does nothing when it already agrees: a stale/hand-altered fact is corrected without a prompt; a
section that already agrees is left byte-for-byte untouched, so the file never churns.

---

## Already implemented — so this is a REGRESSION-GUARD + behavioural plan

B7.2.6 and the spec exist today, so every static check passes now. **Tier 1 is a wiring/wording
regression-guard only** (mutation-coupled), and **the AC is a live walkthrough** — proven at Tier 3
*once the gating blocker is lifted*, with Tier 2 freezing invariants from captured merge runs. The
reusable analysis core is already built and unit-tested in `AI-tests/helpers/project-overview.ts`
(`extractSection`, `analyzeStructure`, `roleSetEquals`, `neverPresentTokenLeaks`,
`criticalRulesAndPoliciesUnchanged`); this plan reuses it.

---

## What the council changed / honesty corrections

### The reframe that closes most holes: anchor to the epic's OWN merge SHA + slug, never "the state of main"
`git pull origin main` at B7.2.5:725 makes post-merge `main` a **shared, racy surface** in a
parallel-epic project (transactions has parallel epics). Another epic's mark-complete (which *does*
touch `CLAUDE.md`) can land between our merge and our pull and be dragged into local `main` — causing
a **false-red** (our idempotent case sees a foreign CLAUDE.md commit), a **false-green** (a foreign
correction re-aligns the shared overview, masking that *our* B7.2.6 was broken), or **baseline drift**
(our "noted bytes" change under us). **Every objective assertion is therefore re-expressed relative to
this epic's merge SHA (captured from `gh pr merge`) and its slug**, and the AC run is **serialized**
(no concurrent writer to origin). Concretely:
- Evaluate only the first-parent range **`<merge>..HEAD`**, and require the CLAUDE.md-touching commit
  to be **`chore(<this-slug>): mark epic complete`** — attributed by slug, not "a mark-complete commit".
- "One new CLAUDE.md commit after the merge" = **exactly one commit in `<merge>..HEAD` whose diff
  touches `CLAUDE.md`**, and it is this epic's mark-complete commit. (Counting "commits since setup"
  wrongly includes the setup's own stale edit.)

### Byte-identity is the teeth — and must be measured by git blob OID, not filesystem bytes
"Never churns" = **byte-identity**, not fact-agreement (spec:40 "worded differently … is *not*
stale", so a still-correct *rewrite* is a violation). But REPO_ROOT is `C:\…` where `core.autocrlf`
flips LF↔CRLF on checkout — a naive working-tree byte compare **false-reds** a clean no-churn run, and
a normalized line-array read (`Get-Content` without `-Raw`) **false-greens** an EOL/trailing-newline
churn. **Compare git object identity:** `git rev-parse <ref>:CLAUDE.md` OIDs, or
`git diff --quiet <premerge-sha> <post-sha> -- CLAUDE.md` — autocrlf-invariant. (Or pin
`CLAUDE.md text eol=lf` for the run and read raw incl. trailing newline.)

### Every "no-change" assertion needs a proof-of-life (inertness control)
A B7.2.6 with its alignment step (continue.md:737) **deleted** — a fully dead feature — passes *both*
the idempotent and design-update "no-change" cases (nothing changed because nothing runs). So each
no-change case must include a **positive control proving B7.2.6 executed in that same run**. Best form:
in the **design-update merge, also pre-stale one real overview fact** and assert it got corrected
while the palette was ignored — one run proves *both* "corrects a stale fact" and "ignores a
non-overview project.md change".

### The design-update discriminator is vacuous unless §Styling provably moved ON MAIN
The point is "project.md §Styling changed but overview didn't". If the palette export is identical, or
§Styling never reaches `main`, "overview unchanged" passes for the wrong reason. **Diff
`<merge>^1:generated-docs/project.md` vs `<merge>:generated-docs/project.md` on the §Styling block and
require a real palette-value delta** before concluding the overview correctly ignored it. *(§Styling
reaches `main` via the normal merge commit at continue.md:715; the mechanism is the
`epic-branch-concurrency.md §6.2` design-source carve-out (:188–201) — NOT continue.md:720, which is
the unrelated behind-main rebase reference.)*

### Facts are compared FIELD-WISE; never substring-scan for `mocks`
The correct data-source line is literally `Data source: … No mocks.` — it **contains** the token
`mocks`. A "assert `mocks` is gone" check false-reds the *correct* corrected file. **Parse the
data-source bullet's mode value and compare field-wise to `project.md` §Data Source** (`Data source` +
`Mock layer required`). `roleSetEquals` covers only the role set; **data source and auth need their
own field comparisons** (the setup stales *both* a role and the data-source mode, so both must be
independently asserted corrected).

### Correction must be MINIMAL — assert a structural diff, not just field-agreement
The byte-identity teeth apply only to the *idempotent* case; in the *correction* case a broken step
could fix the roles/mode yet **rewrite the lead-in or auth line** (spec:42 forbids trimming the user's
words). Field-agreement is necessary-not-sufficient. **Assert the corrected file differs from the
pre-stale intake baseline in EXACTLY the two staled regions and nowhere else** (structural diff), so
the lead-in, pointer line, and auth are proven byte-identical.

### No CLAUDE.md edit may ride in from the epic branch
"One post-merge commit touches CLAUDE.md" doesn't catch a CLAUDE.md edit made *on the branch* (spec:39
forbids writing the overview from an `epic/*` branch). **Also assert
`git log <merge>^1..<merge>^2 -- CLAUDE.md` is empty** (nothing on the branch side touched CLAUDE.md).

### Fact-neutrality is measured on main's project.md, not assumed from the brief
A §6.1 change or a prior epic can land a §Roles/§Auth/§DataSource edit on `main` (continue.md:720
contemplates exactly this), making a *correct* re-align non-idempotent → false-red. **Assert
`project.md` §Roles/§Auth/§DataSource are byte-identical on main across `<merge>^1..<merge>`** — verify
neutrality on the actual delta, not brief-declared intent.

### Silence is a fail-closed, tightly-scoped structural check
"Zero `AskUserQuestion` during B7.2.6" over a flat `*-claude.jsonl` with no phase markers: **fail
CLOSED if the window anchors aren't found** (never "no window ⇒ zero ⇒ pass"). Scope the window from
`git pull origin main` (:725) completion to the `mark-epic-complete.js` invocation — this excludes
B7.2.4's merge-approval AUQ (:704) and B7.2.5's rebase/conflict-halt AUQs by construction, so no
text-classification is needed.

---

## Setup (carries scenario 1 — the intake/transactions project)

Start from the completed INTAKE state of the `transactions` project (intake plan scenario 1), on a
**mergeable release-shaped sandbox** (see the gating blocker) so the shipped file is `CLAUDE.md`. Then:

- **Stale the overview on main:** edit `CLAUDE.md` §Project Overview so the Roles bullet names a role
  **not** in `project.md` (add `` `Auditor` ``) *and* the Data-source bullet states the **wrong** mode
  (flip mocks↔live), and commit it on main (`git commit -m "test: stale the overview"`). Capture the
  **pre-stale intake baseline** (blob OID) and the **stale** blob OID.
- **Fact-neutral epic:** a plain feature epic (e.g. search/filter, file-summary) whose build changes
  no role/auth/data-source fact. Verify neutrality **on main's project.md across the merge**, not just
  the brief (above).
- Keep a **design-update export with a genuinely different palette** aside for the last step.

---

## Tier 1 — static regression-guards (mutation-coupled) — SHIPPABLE NOW

In `tier-1-unit/intake-overview/` (shared suite): the two NEW guards below, plus the already-built
`mergeRecheckWired`, `statesCorrectDontRewrite`, `statesSilence`, `statesTwoWritePoints`.

### NEW `markCompleteStagesClaudeMd(continueMd)` — commit-block-scoped, `git add`-lines only
⚠ **The intake-council whole-file-grep bug re-appears here, worse:** the idempotence no-op at
continue.md:**741** (`… || git checkout -- CLAUDE.md`) sits **8 lines above** the mark-complete commit
at :749, inside any lookback window. A naive block grep for `CLAUDE.md` stays GREEN when `CLAUDE.md`
is dropped from the `git add` at :748 — the stated mutation becomes a strawman. **The detector MUST
inspect only `git add` lines** (port `intakeCommitStagesClaudeMd` verbatim, changing the anchor):

```ts
export function markCompleteStagesClaudeMd(continueMd: string): boolean {
  const lines = continueMd.split(/\r?\n/);
  const commitIdx = lines.findIndex((l) => /git commit -m "chore\([^)]*\): mark epic complete"/i.test(l));
  if (commitIdx === -1) return false;
  for (let i = commitIdx - 1; i >= 0 && i >= commitIdx - 10; i--) {
    const l = lines[i];
    if (/git commit\b/.test(l)) break;
    if (!/(^|\s)git add\b/.test(l)) continue;          // REQUIRED: skips :741's `git checkout -- CLAUDE.md`
    if (/git add\s+(?:-A|--all|\.)(?:\s|$)/.test(l)) return true;
    if (/\bCLAUDE\.md\b/.test(l)) return true;
  }
  return false;
}
```
Mutation tests (each RED): drop `CLAUDE.md` from :748 **while leaving :741 intact** (the exact
false-green config); rename/remove the mark-complete commit. Stay GREEN: split staging (`git add …
state.json` then `git add CLAUDE.md`); whole-tree `git add -A`.

### NEW `mergeLeavesCleanWhenNoChange(continueMd)` — match the WHOLE expression
Matching only the `git checkout` fragment lets real regressions through. Pin the full bash expression
(exact literal is correct — it's a command, not prose):

```ts
export const mergeLeavesCleanWhenNoChange = (continueMd: string): boolean =>
  /git diff --quiet -- CLAUDE\.md \|\| git checkout -- CLAUDE\.md/.test(continueMd.replace(/[ \t]+/g, ' '));
```
Mutation tests (each RED): delete `|| git checkout -- CLAUDE.md`; delete the `git diff --quiet …||`
half (bare `git checkout` → **always discards corrections**); `||`→`&&`; drop `--quiet`; change the
pathspec off `CLAUDE.md`.

### Already-built guards this AC leans on
`mergeRecheckWired` (B7.2.6 alignment sentence → red if deleted); `statesCorrectDontRewrite`
("byte-for-byte untouched" → the no-churn spec teeth); `statesSilence`; `statesTwoWritePoints`.

**Not in Tier 1:** all correction/no-churn/silence *behaviour* — behavioural (Tier 3).

---

## Tier 2 — recorded-run invariants (BLOCKED on the mergeable sandbox + a second golden-run slot)

Needs three merge captures (correction / idempotent / design-update) as `repo.bundle`s carrying
`CLAUDE.md`, and multi-golden loader support (the single `fixtures/golden-run/` slot is occupied by
`minimal-concurrent`). All assertions anchor to the captured **merge SHA + slug**:

**Correction merge (stale → corrected):**
- Overview facts agree with `project.md` **field-wise**: roles by `roleSetEquals`; **data-source mode**
  by parsed field compare; auth method + forbid. The injected `Auditor` and wrong mode are gone.
- **Structural minimality:** corrected file differs from the pre-stale intake baseline in exactly the
  two staled regions; lead-in, pointer line, auth byte-identical.
- Critical Rules + Policies byte-identical across the merge (self-diff).
- **Topology:** exactly one commit in `<merge>..HEAD` touches `CLAUDE.md`; it is
  `chore(<slug>): mark epic complete`; **`<merge>^1..<merge>^2 -- CLAUDE.md` is empty** (no branch-side edit).

**Idempotent merge (already agrees):**
- `CLAUDE.md` blob OID **identical** to the pre-merge blob (`git rev-parse`), not "still correct".
- No commit in `<merge>..HEAD` touches `CLAUDE.md`.
- **Neutrality verified on main:** `project.md` §Roles/§Auth/§DataSource byte-identical across
  `<merge>^1..<merge>`.

**Design-update merge (palette changed) — with inertness control:**
- `project.md §Styling` on main **provably moved**: `<merge>^1` vs `<merge>` §Styling block differs by
  a real palette value.
- **Proof-of-life:** one real overview fact was pre-staled and **was corrected** in this same merge…
- …while the **palette was ignored**: the overview's non-staled regions stay byte-identical and no
  palette/hex leaked (`neverPresentTokenLeaks`).

---

## Tier 3 — behavioural (the AC walkthrough) — BLOCKED on the mergeable sandbox

Once a mergeable sandbox exists, plus the merge scenario driver, the fact-neutral epic, a real
design-swap→build→merge driver (see feasibility — this does **not** exist yet), and the
`AskUserQuestion` extractor:

1. **Correction, silent.** Build + merge the neutral epic via `/continue`. Assert: facts agree
   field-wise; `Auditor` and wrong mode gone; **minimal** (structural diff = only the two regions);
   and **zero AUQ in the fail-closed B7.2.6 window** (`git pull`→`mark-epic-complete.js`), with B7.2.4
   excluded by construction.
2. **One commit, attributed, after the merge.** In `<merge>..HEAD`, exactly one CLAUDE.md-touching
   commit = `chore(<slug>): mark epic complete`; `<merge>^1..<merge>^2 -- CLAUDE.md` empty.
3. **Idempotence — no churn.** Capture the CLAUDE.md blob OID. Build + merge a **second** neutral
   epic. Assert blob OID identical and no CLAUDE.md-touching commit in that epic's `<merge>..HEAD`.
4. **Design-update discriminator (with proof-of-life).** Pre-stale one overview fact; drop the
   changed-palette export into `documentation/`; `/start`, build + merge. Assert §Styling moved on
   main, the pre-staled fact **was corrected** (B7.2.6 alive), and the rest of the overview stayed
   byte-identical (palette ignored).

Run the whole AC **serialized** (no concurrent writer to origin).

---

## Acceptance-criteria → test traceability

| Clause | Tier 1 (mutation-coupled) | Tier 2 (anchored to merge SHA+slug) | Tier 3 (live, serialized) |
|---|---|---|---|
| corrects a stale/hand-altered fact | `mergeRecheckWired` | roles + **data-source + auth field-wise**; structural minimality | corrected + minimal (structural diff) + proof-of-life |
| without a prompt | `statesSilence` | — | zero AUQ in fail-closed B7.2.6 window |
| already-agrees → byte-for-byte untouched | `mergeLeavesCleanWhenNoChange` + `statesCorrectDontRewrite` | blob OID identical; no CLAUDE.md commit in `<merge>..HEAD` | 2nd epic: blob OID identical, no commit |
| one commit after the merge | `markCompleteStagesClaudeMd` | one CLAUDE.md-touch in `<merge>..HEAD`, slug-attributed; branch side empty | same, live |
| never churns (design-update) | (behavioural) | §Styling moved on main; overview unchanged; proof-of-life correction | palette ignored, staled fact corrected, rest byte-identical |

---

## Feasibility & prerequisites

- **⛔ Mergeable Tier-3 sandbox — GATING BLOCKER** (see top). No scenario runs `gh pr merge`; `build`
  short-circuits at continue.md:648 (no remote), `concurrent` uses a bare remote `gh` can't use, `gh`
  isn't installed. Everything Tier-2-and-up depends on lifting this.
- **Merge scenario driver — net-new.** `-Scenario` is `ValidateSet('build','plan','concurrent')`; none
  builds *and* merges through B7.2.6.
- **Design-swap→build→merge driver — net-new (NOT reusable).** There is no `plan-epic-scope` live
  driver and no `-Scenario design`; design coverage today is Tier-1 replays over
  `fixtures/design-capture/` + record-only operator rules. The earlier "reuse the AC6 driver" line was
  wrong — that driver doesn't exist.
- **`AskUserQuestion` extractor — net-new.** `Read-ClaudeEvent` records only file/command, never the
  tool name; the raw gzipped `*-claude.jsonl` is retained, so a new parser can find AUQ blocks — but
  there are no B7.x phase markers, so the window must be proxied by the `git pull`→`mark-epic-complete`
  commands and **fail closed** if those anchors aren't found.
- **Second golden-run slot — net-new**, compounded (three merge captures needed).
- **Stale-CLAUDE.md injection mid-run — feasible** (the sandbox `main` is a real local repo the driver
  can commit to between phases).
- **Fact-neutral epic — net-new but feasible** (transactions decomposes into feature epics; author +
  verify neutrality on main's project.md across the merge).
- **Shallow clone is a NON-issue** (correcting the intake note): `--depth 1` applies only to the
  `.targets/` checkout; the built app's history is created fresh by the run, so
  `git log -- CLAUDE.md` / ancestor checks work. Topology is unreachable only because no merge commit
  is produced (the gating blocker), not because of shallowness.

---

## Suggested order of work

1. **Ship Tier 1 now** — `mergeLeavesCleanWhenNoChange` + `markCompleteStagesClaudeMd` (exact code
   above) with their full mutation-test sets; they need no merge.
2. **Resolve the gating blocker** — decide between a real-GitHub sandbox and putting B7.2.6 on the
   local-merge path; this is the prerequisite for everything below.
3. Build the merge scenario driver + neutral epic + stale-injection; run the correction + idempotence
   walkthrough serialized; capture golden runs (anchored to merge SHA + slug, blob-OID compares).
4. Build the design-swap driver; run the design-update discriminator **with the proof-of-life
   correction**; capture it. Add the `AskUserQuestion` extractor for the silence window.
5. Add multi-golden-slot support; freeze the three Tier-2 merge invariants.

---

## Appendix — evidence

- Merge wiring: [continue.md](.claude/commands/continue.md) — **no-remote short-circuit B7.2.1:648**
  (the gating blocker); B7.2.4 merge-approval AUQ :704; B7.2.5 `gh pr merge` + cleanup + `git pull` :712–727,
  behind-main rebase :720; **B7.2.6** re-align sentence :737, idempotence no-op (single line) :741,
  `mark-epic-complete.js` :747, `git add … state.json CLAUDE.md` :748, `chore(<slug>): mark epic complete`
  :749, branch-switch note (re: the **state.json** CLI, not the overview) :753.
- `mark-epic-complete.js` mutates only `state.json` (`phase`→`COMPLETE`) — it does **not** write
  `CLAUDE.md`; the overview correction is the orchestrator step at :737, merely staged by :748.
- Spec: [project-overview.md](.claude/shared/project-overview.md) — "only two points it is ever
  written" :3; "Correct, don't rewrite" + "worded differently … is not stale" :40; "leave CLAUDE.md
  byte-for-byte untouched" :41; "never trim the user's own words" :42; "Silent — no prompt, no
  message" :43; "Never from an `epic/*` branch" :39; Never-present incl. palette :19.
- §Styling reaches main at merge: `epic-branch-concurrency.md §6.2` **design-source carve-out**
  (:188–201; §Styling+globals.css at :192, "only its §Styling section may be edited on a branch"
  :201) — landed via the normal merge commit at continue.md:715 (NOT the :720 rebase reference).
- Reusable analysis (built + unit-tested): `AI-tests/helpers/project-overview.ts` (`extractSection`,
  `analyzeStructure`, `roleSetEquals`, `neverPresentTokenLeaks`, `criticalRulesAndPoliciesUnchanged`);
  existing guards in `AI-tests/tier-1-unit/intake-overview/rules.ts` (`mergeRecheckWired`,
  `statesCorrectDontRewrite`, `statesSilence`, `statesTwoWritePoints`).
- Harness limits: `Run-QATests.ps1` `-Scenario ValidateSet('build','plan','concurrent')`, `--depth 1`
  `.targets/` clone (:196), gzipped `*-claude.jsonl` retention (:213); `live-driver.ps1`
  `New-Tier3Scaffold` excludes `.git` (:34), `New-Tier3BareRemote` local bare remote (:1047),
  `Read-ClaudeEvent` file/command only (:312–321); `Setup.ps1` prereqs (no `gh`);
  `helpers/golden-run.ts` single `fixtures/golden-run/` slot.
