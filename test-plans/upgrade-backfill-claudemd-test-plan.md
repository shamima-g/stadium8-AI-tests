# Test plan — an in-flight project backfills its project section at the next merge (no migration step, no question)

**Testing against:** the template clone at `C:\TestsArchives\stadium8-tests\28-09-2026` (commit
`34a574a`, dev marker — shipped user file is `CLAUDE.user.md`, see the intake plan's "Which file is
under test"). **Third in the series:** pairs with `intake-claudemd-project-overview-test-plan.md`
(INTAKE) and `merge-claudemd-recheck-test-plan.md` (epic merge). This plan covers the
**backfill/migration path**.
**Run static tier (PowerShell):**
`$env:REPO_ROOT="C:\TestsArchives\stadium8-tests\28-09-2026"; $env:EXPECT_TEMPLATE="1"; npm run test:tier1`
(from `c:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests`).

---

## ⛔ Reachability — BOTH live halves are blocked (only Tier 1 ships now)

1. **Upgrade half — no fetchable change-carrying version.** The feature (upgrade.md's *never touch
   `## Project Overview`* + the `project-overview.md` spec) exists **only in untagged dev** (this
   clone, commit `34a574a`; CHANGELOG has it under **`[Unreleased]`**). Every published tag `/upgrade`
   can discover (`gh release view` → `git ls-remote --tags stadium-software/stadium-8`, upgrade.md:60–75;
   `apply-template.js --ref <tag>` fetches from the same repo) is **pre-feature** (latest dated release
   is v1.3.0, 2026-08-12). So a real `/upgrade` can only upgrade *to* a feature-less version — there is
   nothing to observe. **Hard prerequisite:** publish the feature as a fetchable tag/branch, **or**
   build a local-source upgrade driver overriding both Step-1 discovery and Step-3 fetch
   (`apply-template.js` accepts `--repo`/`--template` for local dogfooding). Reachable in *mechanism*,
   but with **no valid target** until then.
2. **Backfill half — inherits the merge GATING BLOCKER.** Backfill *is* B7.2.6, downstream of
   `gh pr merge`; `build` short-circuits at continue.md:648 (no remote), `concurrent`'s bare remote
   can't satisfy `gh`. See `merge-claudemd-recheck-test-plan.md`.
3. **Tier 1 is unaffected and ships now** — it pins the change-carrying upgrade.md + the spec, no run
   needed. In fact the "no migration step" clause is **fundamentally a Tier-1 property** of the
   change-carrying `upgrade.md` (see below), which is why Tier 1 carries most of this AC's weight.

---

## The feature under test

A project built on an older release has a `CLAUDE.md` whose `## Project Overview` is the **generic
template text** (INTAKE never wrote facts — the feature didn't exist). The design backfills it
**lazily, with no dedicated migration**:

1. **The change-carrying `/upgrade` does NOT add an overview migration and asks nothing about it.**
   upgrade.md:178 — *"**`CLAUDE.md`** — **never touch `## Project Overview`**, which the workflow
   maintains"*; Step 5:176 *"never ask"*. Step 6's `/migrate-legacy` migrates **workflow state**, not
   CLAUDE.md (there is no migrations framework; `/migrate-legacy` is a state-*shape* converter). So the
   upgrade updates the template sections and leaves the overview generic. **"No migration step" is thus
   a property of the change-carrying upgrade.md — Tier-1 provable directly.**
2. **The next epic merge backfills it** via **B7.2.6**, because the spec
   ([project-overview.md:40](.claude/shared/project-overview.md)) defines stale as *"it contradicts
   `project.md`, **or a stated fact is missing**"* — generic text has **all** facts missing. Per
   project-overview.md:3 the overview is written *"at INTAKE, then … at every epic merge — the only two
   points it is ever written"*; for a pre-feature project INTAKE wrote nothing, so the **first real
   write is the next merge**.

**Acceptance criterion (as given).** A project already partway through its epics picks up its project
section at the next merge — no separate migration step, and no question asked.

---

## What the council changed — the load-bearing reframe

### Prove a WITNESSED TRANSITION, never end-state agreement (this is the whole game)
`project.md` predates the feature and **already holds the facts**, and the `transactions` fixture's real
roles/auth/data-source **coincide with the spec's own canonical example** (project-overview.md:26–30 is
literally File Importer/Approver/session/existing-API). So "the overview agrees with `project.md`" is
reachable with **zero working code** — a dead B7.2.6, or a generic template that happened to embed the
example, both pass an end-state agreement check. Every backfill assertion must instead be a **proven
this-commit transition**:

- **Precondition — certify the baseline is genuinely stale.** Before any merge, assert the captured
  pre-merge overview **FAILS** the maintained-section check against `project.md` (≥1 checked field
  absent or contradicting). If it already agrees, the fixture is **invalid for a backfill test —
  discard it, don't score it**. Where possible **seed the fixture to disagree** (a generic overview
  that omits the real roles/mode), so a do-nothing B7.2.6 leaves a **detectable contradiction** →
  red.
- **Transition — the write happened, in this commit.** The overview **blob OID changed** across
  `<merge>^1..<merge>`, and the change is carried by the `chore(<slug>): mark epic complete` commit
  (not branch-side: `<merge>^1..<merge>^2 -- CLAUDE.md` empty).
- **Postcondition — it landed correct.** Post-merge overview passes the maintained-section check
  (field-wise agreement, structural whitelist, `withinBudget`, perms/palette pointered).
- **Teeth are per-field transitions**, not a whole-section byte-diff — a byte-diff conflates "the
  template shared a token"; a per-field "was absent/contradicting → now present/agreeing" cannot.

### The three end-state checks the plan must NOT rely on alone
1. "agrees with project.md" — satisfied by a no-op on an already-correct/coincidental overview → pair
   with the stale precondition + OID-change transition.
2. "differs from the generic baseline" — false-red if the baseline was an author-written *correct*
   overview (B7.2.6 rightly no-ops, spec:40 "worded differently is not stale"); false-green if the
   baseline shared example facts → use certified-stale baseline + per-field teeth.
3. "settle: second merge OID == first" — **trivially true if the backfill never ran** (both no-op).
   Chain it: settle OID **== the known-backfilled OID** and **≠ the baseline OID**.

### "No question about CLAUDE.md" — whitelist by CALL-SITE, not keyword
A broken `/upgrade` that asks *"Refresh the project summary at the top?"* dodges any overview/CLAUDE.md
keyword filter (false-green); and Step 6 `/migrate-legacy`'s own "migrate" prompt trips a keyword filter
(false-red). Instead **enumerate the only legit AUQ sites** — Step 1 go-ahead (upgrade.md:84), Step 9.4
check-fail (:333), Step 9.5 apply (:341) — and assert the upgrade's AUQ stream contains **only** those,
by call-site identity; any AUQ not matching a known site fails regardless of wording. Treat
`/migrate-legacy`'s prompts as a separate permitted stream, and prove Step 6 did **workflow-state**
migration by its **effect** (state.json shape change), not by prompt text. Fail-closed if any AUQ can't
be matched.

### Proof-of-life for the upgrade run = the templateRef marker advanced, NOT a CR/Policies diff
"CR/Policies updated proves the upgrade ran" is **unsound and near-certain to false-red here**: this
feature's release changed `project-overview.md`/`continue.md`/`upgrade.md` but likely **not** the
numbered Critical Rules / Policies in `CLAUDE.md`, so Step 5 legitimately makes zero CR/Policies edits.
Anchor proof-of-life to the **guaranteed** artifact: the `templateRef` marker (in `CLAUDE.md` /
`template-version.json`) **advanced** from the pre-change ref to the target (upgrade.md:78–82 re-stamps
every run), plus the merged upgrade commit exists. Do **not** assert CR/Policies changed.

### Section extraction across upgrade — fence-aware, exactly-one, blob-OID EOL
`extractSection` is already fence-aware and fail-closed on a missing heading (built + unit-tested).
Additionally require **exactly one** heading match (fail-closed on 0 or >1), and define "overview span
unchanged across upgrade" by **git blob OID** (with `.gitattributes` pinning `CLAUDE.md text eol=lf`,
or normalize both sides) — the Windows sandbox's autocrlf would false-red a raw byte compare. A section
**reorder** with identical text is an accepted PASS (keyed by heading text, never an ordinal).

---

## Setup

- **Pre-change build (baseline):** build the `transactions` project on the last pre-feature release
  (`-Target release -Ref v1.3.0`), ≥1 epic merged. **Capture** the `## Project Overview` section
  (text + blob OID) and `project.md`. **Certify the baseline is stale** — it must FAIL the
  maintained-section check vs `project.md`; if the shipped generic text happens to agree, **seed a
  deliberate stale overview** (omit the real roles + wrong/absent data-source mode) so the backfill is
  a real, witnessable transition.
- **Upgrade target:** the change-carrying version — requires publishing it as a fetchable tag/branch,
  or a local-source upgrade driver (see reachability #1). Run `/upgrade`, approve.
- **Fact-neutral next epic:** verify neutrality on main's `project.md` across its merge.

---

## Tier 1 — static regression-guards (mutation-coupled) — SHIPPABLE NOW

Shared `tier-1-unit/intake-overview/` suite: two NEW guards + the already-committed B7.2.6 guards.

### NEW `upgradeLeavesOverviewAlone(upgradeMd)` — MUST be Step-5-span-scoped
⚠ `never ask` appears at upgrade.md:176 (the target, Step 5) **and** :265 (Step 9, unrelated), and
`never touch` appears 3× (:118, :169 for `web/*`, :178 for the overview). A whole-file `/never ask/`
stays green when :176 is deleted (rescued by :265) — a strawman. Scope to the **Step 5 span** and
co-anchor the never-touch to `## Project Overview` (unique to :178); whitespace-collapse (the phrase
wraps :175–176) and tolerate the em-dash:

```ts
function upgradeStep5(md: string): string {
  const ls = md.split(/\r?\n/);
  const s = ls.findIndex((l) => /^##\s*Step 5\b/.test(l));
  if (s < 0) return '';
  const e = ls.findIndex((l, i) => i > s && /^##\s*Step 6\b/.test(l));
  return ls.slice(s, e < 0 ? undefined : e).join('\n');
}
export function upgradeLeavesOverviewAlone(upgradeMd: string): boolean {
  const flat = upgradeStep5(upgradeMd).replace(/\s+/g, ' ');
  return /never touch\s+`?##\s*Project Overview`?/i.test(flat) && /Do this yourself\s*[—–-]\s*never ask/i.test(flat);
}
```
Mutation tests (each RED): delete the `## Project Overview` never-touch clause; delete the Step-5
`Do this yourself — never ask`. **Negative control (must still be RED):** delete :176 but keep :265's
`never ask the user…` — proves the Step-5 scoping (a whole-file guard would false-green here). *Guard
for AC clause 1 — the "no migration step" property.*

### NEW `staleIncludesMissingFact(specMd)` — ordered-anchored
Pin both halves of project-overview.md:40 in order, so a narrowed definition goes red:
```ts
export const staleIncludesMissingFact = (specMd: string): boolean =>
  /Stale means[^\n]*contradicts\s+`?project\.md`?[^\n]*,\s*or a stated fact is missing/i.test(specMd);
```
Mutation (RED): reduce to "contradicts `project.md`" only — a generic overview *omits* rather than
*contradicts*, so without this half it would never backfill. **Documented Tier-3-only miss:** a
*qualified* narrowing ("…missing **that the epic changed**") keeps the substring but breaks the
fact-neutral backfill — catchable only behaviourally, not by a static substring. *Load-bearing.*

### Already-built guards this AC leans on
`mergeRecheckWired`, `mergeLeavesCleanWhenNoChange`, `markCompleteStagesClaudeMd`, `statesTwoWritePoints`
(INTAKE + merge only — no third migration write), `statesCorrectDontRewrite`, `statesSilence`.

---

## Tier 2 — recorded-run invariants (BLOCKED: upgrade target + mergeable sandbox)

Anchored to the captured baseline, the merge SHA + slug, and blob OIDs.

**Upgrade capture:**
- Overview span **byte-identical** (blob OID) to the captured generic baseline — not backfilled during
  upgrade.
- **AUQ whitelist:** the upgrade's AUQ stream contains only the three known sites (Step 1/9.4/9.5) —
  no unknown-site AUQ (fail-closed).
- **Proof-of-life:** `templateRef` advanced pre-change → target; the merged upgrade commit exists.
  *(Not CR/Policies.)*

**Backfill-merge capture (fact-neutral epic) — as a witnessed transition:**
- Precondition: pre-merge overview **fails** the maintained-section check (certified stale).
- Transition: overview blob OID **changed** in `<merge>..HEAD`, carried by `chore(<slug>): mark epic
  complete`; `<merge>^1..<merge>^2 -- CLAUDE.md` empty; neutrality proven — `project.md`
  §Roles/§Auth/§DataSource byte-identical across `<merge>^1..<merge>`.
- Postcondition: **per-field** transitions (each checked fact absent/contradicting before → present/
  agreeing after), structural whitelist holds, perms/palette pointered, `withinBudget`.

**Settle capture (second fact-neutral merge):** overview blob OID **== the backfilled OID** and **≠
the baseline OID** — one-time backfill, not never-ran, not perpetual churn.

---

## Tier 3 — behavioural (the AC walkthrough) — BLOCKED (both prerequisites)

1. **Upgrade leaves it generic, silently.** `/upgrade` + approve → overview span == certified-stale
   baseline; AUQ stream only the three known sites; templateRef advanced. *(Note: with the running
   pre-change upgrade.md having no overview logic, this largely corroborates the Tier-1 property that
   the change-carrying version added no migration.)*
2. **Next merge backfills (witnessed transition).** Build + merge the fact-neutral epic → stale→correct
   transition proven per above; neutrality on main proves the epic didn't cause it.
3. **Settles.** Second neutral merge leaves the backfilled OID unchanged.

Run serialized (no concurrent writer to origin).

---

## Acceptance-criteria → test traceability

| Clause | Tier 1 (mutation-coupled) | Tier 2 (transition-anchored) | Tier 3 (live) |
|---|---|---|---|
| `/upgrade`: no migration step / no CLAUDE.md question | `upgradeLeavesOverviewAlone` (Step-5-scoped) | overview OID == certified-stale baseline; AUQ only known sites; templateRef advanced | upgrade completes; overview generic; only known AUQ sites |
| next merge backfills (epic changed nothing) | `mergeRecheckWired` + `staleIncludesMissingFact` + `statesTwoWritePoints` | stale precondition + OID-change transition + neutrality on main | witnessed stale→correct; neutrality proven |
| agrees with project.md; perms/palette pointered; ≤12/≤150 | (behavioural) | per-field transitions + structural whitelist + `withinBudget` | judge + wc on the copied section |
| one-time, no churn | `mergeLeavesCleanWhenNoChange` | settle OID == backfilled OID ≠ baseline OID | second neutral merge no-ops (vs a proven write) |

---

## Feasibility & prerequisites

- **⛔ No fetchable change-carrying version — GATING for the upgrade half.** Publish the feature as a
  tag/branch, or build a local-source driver overriding upgrade.md Step-1 discovery + Step-3 fetch
  (`apply-template.js --repo/--template`). Until then the upgrade half has no valid target.
- **⛔ Mergeable Tier-3 sandbox — GATING for the backfill half** (inherited; merge plan).
- **`/upgrade` scenario / cross-version driver — net-new.** `-Scenario` is `build|plan|concurrent`;
  none runs `/upgrade`. `Resolve-Tier3Template -Target release -Ref <tag>` clones one version; the
  second version is fetched by `/upgrade` itself (over the network) — so single-version scaffolding is
  fine **once a feature target is fetchable**. `/upgrade` needs **network** (not `gh` specifically —
  it degrades to git-only), and the gh-PR apply path is unavailable in-sandbox (bare/no remote), so
  drive the **local apply path**.
- **Baseline release is identifiable = v1.3.0**; capture its generic overview and certify staleness.
- **AUQ extractor by call-site — net-new.** `Read-ClaudeEvent` records only file/command; parse the
  retained gzipped `*-claude.jsonl` for `AskUserQuestion` events and match against the enumerated
  sites; fail-closed.
- **Multi-golden slots — net-new**, compounded (this plan adds upgrade / backfill / settle captures).
- **Reused as-is (built + unit-tested):** `extractSection` (fence-aware, fail-closed), `analyzeStructure`,
  `roleSetEquals`, `neverPresentTokenLeaks`, `withinBudget`; the committed B7.2.6 Tier-1 guards.

---

## Suggested order of work

1. **Ship Tier 1 now** — `upgradeLeavesOverviewAlone` (Step-5-scoped, with the negative control) +
   `staleIncludesMissingFact` (ordered anchor), with mutation fixtures. This carries the "no migration
   step" clause directly.
2. Resolve the upgrade target (publish a tag or a local-source driver) → run the **upgrade half**
   (overview generic, AUQ only known sites, templateRef advanced).
3. Resolve the merge gating blocker → run the **backfill** as a witnessed transition on a
   certified-stale fixture, then **settle**; capture goldens (blob-OID, merge SHA + slug).
4. Multi-golden slots; freeze the upgrade / backfill / settle invariants.

---

## Appendix — evidence

- `/upgrade` leaves the overview alone, silently: [upgrade.md](.claude/commands/upgrade.md) Step 5:173–194
  — *"never touch `## Project Overview`"* :178, *"…Do this / yourself — never ask"* :175–176, template-
  section merge :179–187; Step 6 `/migrate-legacy` = workflow-**state** migration :200–209; templateRef
  re-stamp :78–82. Legit AUQ sites: Step 1 go-ahead :84, **Step 9.4** check-fail :333, Step 9.5 apply
  :341. `never ask` also at :265 (Step 9, why Step-5 scoping matters); `never touch` also :118/:169.
  No migrations framework — only `/migrate-legacy` (state-shape).
- The feature is **Unreleased**: CHANGELOG `[Unreleased] → Changed` "CLAUDE.md now describes your app";
  latest dated release v1.3.0 (2026-08-12); `template-version.json` `templateRef v1.3.0`. So the
  pre-change baseline = v1.3.0 and the upgrade **target is untagged dev** (reachability #1).
- Backfill rides B7.2.6: [continue.md](.claude/commands/continue.md) re-align :737, no-op :741,
  mark-complete staging :748–749; no-remote short-circuit (gating blocker) :648.
- Stale includes missing facts: [project-overview.md](.claude/shared/project-overview.md) :40; two
  write points :3; canonical example that coincides with the transactions facts :26–30; budget :7;
  Never-present incl. palette :19.
- Reused analysis + guards: `AI-tests/helpers/project-overview.ts`;
  `AI-tests/tier-1-unit/intake-overview/rules.ts`.
- Harness limits: `-Scenario build|plan|concurrent`; `Resolve-Tier3Template` (Run-QATests.ps1:167);
  `apply-template.js` `--ref/--repo/--template` (:32,:791–801); `Read-ClaudeEvent` file/command only;
  single `fixtures/golden-run/` slot; `Setup.ps1` prereqs (no `gh`).
