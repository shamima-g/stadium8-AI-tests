# Tier 3 — the human walkthrough

> This is one of the three tier files. Everything that is shared across all tiers —
> the rules every test follows, the surface-area map, the good-and-broken discipline,
> the helpers and rollbacks, the fixtures, version handling, the maintenance routine,
> and the coverage picture — stays in the hub: [workflow-tests.md](workflow-tests.md).
> This file covers **Tier 3 only**. Tier 3 is the manual, live-AI walkthrough — the
> final word before a release. It is **not** an npm command.

A person runs the real workflow with a real AI and confirms each behaviour — the
final word before a release, and each clean pass is a good moment to re-record the
Tier 2 fixture.

## When to run Tier 3

- Before a major template release
- After changes to the orchestrator rules, an agent, or the hook configuration
- When the Tier 2 golden run needs re-recording (a clean Tier 3 pass is the moment to
  re-record it — see [tier-2.md](tier-2.md))

## What Tier 3 catches that Tiers 1 and 2 cannot

- The real AI behaviour of each agent, not just the scripts supporting it
- Interactions between hooks, agents, and commands that only show up in live sessions
- Whether Claude actually obeys the policy rules (facts-over-template, plain language)
- End-to-end feel — the hands-on check, the dashboard, the dev-server interaction

Tier 3 is expensive but irreplaceable. Tiers 1 and 2 exist to catch most regressions
cheaply so Tier 3 only needs to run occasionally.

## The walkthrough

**Ground the walkthrough in the version under test — not in this doc.** Before you
start, read that version's own workflow docs so you're checking against what it
actually promises: `<template>/.claude/WORKFLOWS.md` and
`<template>/.template-docs/users/` (Getting-Started, Agent-Workflow-Guide,
Quality-Gates). The stages, gates, and commands you'll see are whatever that version
defines. What follows is the **version-independent craft** the walkthrough confirms —
the things no unit test can judge — framed so they apply whatever the exact stage
names are.

**Workflow behaviours to confirm by hand:**

- **`/start` flows straight into work** — setup installs what's missing and continues
  into the first question in one go; it doesn't stall on "setup complete".
- **The stages happen in the template's defined order**, on the epic's own branch,
  with `/continue` picking up wherever you left off after a close-and-return.
- **Every approval shows the content first** — the facts/plan, the story list, the
  hands-on checklist, the merge — never a "naked" approval with nothing to review.
- **Sign-in is always asked openly** — the options are shown with their trade-offs and
  never silently inferred.
- **Building runs on its own** and only stops for a genuinely risky (Level 4) decision
  — a new dependency, a data-shape or auth change, an endpoint the description doesn't
  cover — surfacing the options instead of guessing.
- **The autonomy tiers leave the right trail** — small choices mentioned with the
  saved work, notable ones in the notebook, external unknowns on the "please
  double-check" list before the merge.
- **The end-of-epic checks, the built-in review, and the browser tests all run**, and
  any failure is routed back through the responsible story (at most three tries, then
  it asks you).
- **The hands-on check is genuinely hands-on** — the checklist opens in the browser
  with the double-check items on top and one-click sign-ins; "found a problem" leads to
  a fix and a re-ask (only the affected items un-ticked).
- **The merge waits for you** — it never merges on its own.
- **Recovery is painless** — with the state file gone, checking out the branch and
  running `/continue` still carries on from the right spot (and a hook restores
  bearings after the AI's memory is auto-trimmed).

**Generated-code craft to confirm** (the same rules Tier 1 lints, spot-checked live —
detection recipes in [the surface area](workflow-tests.md#5-what-we-test--the-surface-area)): tests are
written *before* the code and fail first; the code makes them pass; UI primitives come
from `@/components/ui/`; data calls go through the shared client with exact API paths,
never a raw `fetch()`; no error suppressions; user-facing checklists stay in plain
language; each routable story has a real browser test.

> **L6 / grade-by-version rule.** When grading the app Claude builds, grade against the
> rules that shipped **with the version under test** — read them from that version's
> own docs and live values, never from today's. File the result under the version +
> the suite version used (see [testing any template, any version](workflow-tests.md#12-testing-any-template-any-version)).

### `/plan` — planning an epic ahead (feature-detected; v1.2.0's park-ahead command)

Some versions add a **plan-ahead** command that breaks the *next* epic down and parks it
**ready to build** without building it — and that's meant to run in a **second live
session, concurrently with a build**. In the current template this is `/plan`, which parks
an epic at the `READY-TO-BUILD` stage. These are behaviours of the *running* workflow across
*two* live sessions, so — like the rest of Tier 3 — they're confirmed live and **recorded,
never used to fail the run**. Gate this whole area on the surface being present (is a
park-ahead command live? does the stage machine include a ready-to-build stage?), not on a
version number — a version without it **skips**, never fails.

**The good/broken discipline still holds** ([the rules every test follows](workflow-tests.md#2-the-rules-every-test-follows),
[good case / broken case](workflow-tests.md#9-good-case--broken-case--the-discipline)). Each check is a small pure function
(`Get-Tier3PlanRulesMissed` / `Get-Tier3ConcurrentRulesMissed` in `live-driver.ps1`) that reads
the traces a run leaves (git refs, `state.json`, `generated-docs/`), and it gets its **good *and*
broken case as a Pester unit test** in `tier-3-automated/tests/live-driver.Tests.ps1` — over
synthetic scaffolds (a parked epic vs. one still at BUILD; a clean worktree teardown vs. a leftover
`plan/<slug>`). These run in the non-AI **Pester** suite (`npm run test:tier3-unit`), not the vitest
Tier-1 suite. The **live run exercises** those same functions and records the result. So the broken
case lives where it can be proven cheaply and repeatably; the live tier proves the behaviour actually happens.

Two live scenarios drive it, each filed in its own results world so its numbers never mix
with a straight build:

- **PLAN-A — one session, sequential** (runs without a shared remote, using the command's
  single-session local-git fallback): `/start` → build the first epic → plan the next
  (one already outlined at setup, one brand-new) → plan one that depends on an unbuilt epic
  → check `/status` + dashboard → `/start` the parked epic and confirm it builds.
- **PLAN-B — two sessions, concurrent** (needs a shared remote — a bare `origin` added to
  the scaffold): one process builds an epic while a second plans the next, and we check
  neither disturbs the other and `main` stays consistent.

**What each acceptance criterion maps to.** The rule ids below are the **exact strings the
harness pushes to the run's `rulesMissed` list** (`live-driver.ps1`), so they are the
*negative / "missed"* form — a **clean run lists none of them**. (An earlier version of this
table listed positive names like `plan-parked`; those were never emitted. The ids here are what
you actually grep a run's `rulesMissed` for.) Record-only: they never gate.

| Behaviour to confirm | Scenario | What the deterministic assertion reads | Rule id(s) emitted on failure |
|----------------------|:--------:|-----------------------------------------|-------------------------------|
| Something was actually parked | A | at least one epic at `READY-TO-BUILD` | `plan-no-parked-epic` |
| Planning starts **no build work** | A | for the parked slug: **no `epic/<slug>` branch** (`plan-created-epic-branch`) and **no `feat(<slug>…)` commits** (`plan-build-committed`) | `plan-created-epic-branch`, `plan-build-committed` |
| Epic is **broken down** while planning | A | story files on disk for the parked epic *(the approval interaction itself is live — see live cores below)* | `plan-stories-missing` |
| Planning works for a **brand-new epic** | A | the scenario drove the brand-new-epic path (`plannedNewEpic`) *(the outlined-at-setup path is exercised by the run but not separately asserted)* | `plan-new-epic-missing` |
| Planned epic is **parked ready to build** | A | phase `READY-TO-BUILD`; its `state.json` is present on `main` (`plan-not-on-main`) **and arrived via a `docs(plan)` commit** (`plan-not-docs-plan`); no leftover `plan/<slug>` worktree/branch (`plan-worktree-leftover`) | `plan-not-on-main`, `plan-not-docs-plan`, `plan-worktree-leftover` |
| Continuing it **resumes into BUILD** | A | a planned epic (has stories) later produced `feat` commits *(reads the resume trace only — not "stories unchanged / no second approval", which is a live judgement)* | `plan-resume-missing` |
| **Two sessions at once** — one building, one planning | B | both sessions ran with **overlapping wall-clock** | `plan-concurrent-ran` |
| Neither session **disturbs the other's** branch | B | the planner never committed onto the builder's epic branch | `plan-cross-disturb` |
| **Shared records on `main`** stay consistent | B | `git fsck` clean **and** both a built epic and a planned epic are present on `main` | `plan-main-inconsistent` |
| **Project facts** stay consistent | B / A | `project.md` unchanged by the planner (`git diff --quiet`) | `plan-facts-changed` |
| **No session loses in-progress work** | B | builder commits preserved **and** planner's plan on `main` | `plan-lost-work` |
| A **blocked epic** (depends on an unbuilt one) can still be planned | A | at least one parked epic carries a non-empty `dependsOn` *(reads `dependsOn`; it does not read a separate `blocked` status field)* | `plan-blocked-ahead-missing` |
| That epic stays **blocked from merging until its dependency merges** | B | scored **only when a run actually reaches the dependent merge** (`expectBlocked` and `blockedMergeRefused == false`); otherwise not scored | `plan-blocked-until-dep` |

**Behaviours confirmed live only — no deterministic rule id.** Three behaviours from the AC set
have **no assertion in `live-driver.ps1`** and are confirmed by eye during the live run, not by a
`rulesMissed` entry:
- **The story approval firing** — the trace (stories on disk) is `plan-stories-missing`; the
  approval *interaction* itself is a live judgement.
- **The mid-flow redirect actually firing** (running the plan command mid-build yields the
  redirect and creates no worktree) — live-only; the guard's *presence* is a Tier-1 doc check.
- **The parked epic showing distinct in status + dashboard** — already covered deterministically
  in **Tier 1** (`collect-dashboard-data` + the epic-picker legend), so Tier 3 adds nothing here.

**Note on `plan-blocked-until-dep`.** The id is emitted, but in a normal PLAN-B run the gathered
facts hard-set `blockedMergeRefused = $null` (meaning "not exercised"), so it fires only over
synthetic Pester facts, or a future run wired to actually attempt the dependent merge. Its live
coverage today is nil — the row above is honest that it scores "only when a run reaches the merge".

**Where each half runs — the three-tier split for `/plan`.** The deterministic *traces* a
parked epic leaves are asserted in **two** places, and they are the only halves that gate:

- **The non-AI Pester unit suite** (`tier-3-automated/tests/live-driver.Tests.ps1`, run by
  `npm run test:tier3-unit`) proves each pure/real-git assertion function good **and** broken over
  *synthetic* scaffolds (a parked epic vs. one still at BUILD; a clean worktree teardown vs. a
  leftover `plan/<slug>`). (These sit in the Tier-3 directory, not the vitest `tier-1-unit/` suite.)
- **Tier 2** asserts those same traces over the **one real recording** — parked story list
  present (`plan-stories-approved` trace), no `epic/<slug>` branch and no build
  (`plan-no-build-started`), no leftover `plan/<slug>` and on-`main`-via-`docs(plan)`
  (`plan-parked`), `dependsOn` recorded when blocked (`plan-blocked-ahead`). These are
  **pass/fail** Tier-2 invariants, feature-detected off the recording (no parked epic →
  skip, never fail) — see [tier-2.md](tier-2.md).
- **Tier 3** is reserved for the **irreducible live cores** above (the approval firing, the
  mid-flow redirect, the two-session merge-block), which stay **record-only** in the live
  run — they never gate.

So a rule id like `plan-parked` is *record-only* when observed live in Tier 3, but the same
trace is a *gating* invariant when replayed over the golden run in Tier 2. Nothing is
double-counted: Tier 2 gates the traces; Tier 3 confirms only what can't be replayed.
