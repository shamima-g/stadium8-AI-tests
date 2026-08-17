# Testing the Stadium 8 template and its workflow

> **This is the single source of truth for testing the template.** 

## How to read this document

There are **two kinds of fact** in testing this template, and keeping them apart is
the whole trick to not going stale:

1. **Version-independent — lives here.** *How* we test: the tiers, the good-and-broken
   discipline, isolation, the helpers, the maintenance routine. These don't change
   when the template changes.
2. **Version-specific — lives in the template under test, never hard-coded here.**
   *What* the current template does: its stages, its quality gates, its commands, its
   doc-name rules. The suite reads these **live** from the template it's aimed at
   (`epic-state.js`, `.claude/commands/`, `quality-gates.js`, the per-target
   contract). To learn how a given version's workflow behaves, read **that version's
   own docs**: `<template>/.claude/WORKFLOWS.md` and `<template>/.template-docs/`.

That second rule is why this doc no longer prints "the stages are …": the stages are
whatever the version under test defines. When a concrete example helps, this doc uses
the current dev/release template (**v1.2.0**, whose per-epic stages are PLAN →
READY-TO-BUILD → BUILD → EPIC-END → MANUAL-TEST → COMPLETE-ON-BRANCH → COMPLETE — v1.2.0
inserted READY-TO-BUILD, where `/plan` parks an epic planned ahead) — but the *tests*
read those from the template, they don't assume them.

---

## Table of contents

1. [What this is](#1-what-this-is)
2. [The rules every test follows](#2-the-rules-every-test-follows)
3. [What the template promises](#3-what-the-template-promises)
4. [The three tiers](#4-the-three-tiers)
5. [What we test — the surface area](#5-what-we-test--the-surface-area)
6. [Tier 1 — automated unit tests](#6-tier-1--automated-unit-tests)
7. [Tier 2 — invariants over a recorded run](#7-tier-2--invariants-over-a-recorded-run)
8. [Tier 3 — the human walkthrough](#8-tier-3--the-human-walkthrough)
9. [Good case / broken case — the discipline](#9-good-case--broken-case--the-discipline)
10. [Helpers, checkpoints, and rollbacks](#10-helpers-checkpoints-and-rollbacks)
11. [Test inputs and fixtures](#11-test-inputs-and-fixtures)
12. [Testing any template, any version](#12-testing-any-template-any-version)
13. [Keeping the tests in step with the template](#13-keeping-the-tests-in-step-with-the-template)
14. [Coverage today and open work](#14-coverage-today-and-open-work)
15. [What we deliberately don't test](#15-what-we-deliberately-dont-test)
16. [Running the suite](#16-running-the-suite)
17. [Quick reference — what each area protects against](#17-quick-reference--what-each-area-protects-against)

---

## 1. What this is

This is the set of tests for the **Stadium 8 template and the way its workflow
runs** — the scripts, hooks, JSON state files, and the agent/command definitions
under `.claude/` that carry a project from a plain-English brief to a built, tested,
merged app, **one epic at a time, each on its own branch**. It tests the *machinery*
a user relies on, not any feature a user builds with it, and it is **not** the
per-story QA that happens inside the workflow. Think of it as a building inspector:
it never cooks a meal (a feature someone asks for), it only checks that the kitchen,
the tools, and the safety rules are sound before anyone starts cooking.

The suite is a **self-contained npm workspace** — carry the folder anywhere and run
`npm install && npm test`. It reaches the template through one resolved path
(`REPO_ROOT`, via the `target` helper), so the same tests can be aimed at any
checkout of any version (see [section 12](#12-testing-any-template-any-version)).

---

## 2. The rules every test follows

Every test here follows all of these. If a proposed test can't, it doesn't belong.

1. **A "good" case *and* a "broken" case for everything.** For each thing we check
   there's a "works when it's right" test **and** a "fails when it's broken" test. A
   test that can only ever pass can't prove it would catch a mistake — the broken
   case proves the check can tell good from bad.
2. **Each test cleans up after itself.** Set up, do the work, tidy up — no leftover
   files, no stray git branches. Each test names the rollback recipe it used
   (`RB-0` … `RB-7`, see [section 10](#10-helpers-checkpoints-and-rollbacks)).
3. **No test depends on another.** Any test can run on its own, in any order.
4. **Isolated.** Each test works in **its own throwaway folder** (and, where git is
   involved, its own throwaway repo) in the system's temporary area — never in the
   real project, never on a real branch.
5. **Fast.** The plain unit tests aim for under about a tenth of a second each; the
   state-and-schema checks aim for under about a hundredth of a second.
6. **Never touches the real project, never shows a fake green.** The suite reaches
   the template through the single resolved path. It installs nothing into `web/` or
   the repo root. When no template is present, template-dependent tests **skip with a
   visible notice** (via `describeTemplate`) while the rest still run — a standalone
   copy can never show a fake "all green".
7. **Read the version's own values; don't hard-code them.** Wherever a test needs a
   stage list, a status set, a doc-name rule, or a command list, it reads them from
   the template under test — so aiming the suite at a different version judges that
   version by *its* rules, not today's.

---

## 3. What the template promises

The workflow gives a user a handful of things they can rely on. Each is a promise the
suite tests. (The concrete stage/gate/command names come from the template under
test — the promises themselves hold across versions.)

| # | The thing | The promise |
|---|-----------|-------------|
| A | **The stage machine** | Every epic moves through the template's stages **in order**, tracked in the epic's own `state.json`, never skipping a stage whose inputs aren't ready. The valid stages/order are read live from `epic-state.js` (`EPIC_PHASES`). |
| B | **The branch-and-merge machinery** | Each epic is built on its own `epic/<slug>` branch; non-conflicting overlaps combine on their own and real conflicts stop and ask (both proven over the git substrate in Tier 1); the epic reaches `main` **only after you approve** — a running-workflow gate confirmed with a person driving (Tier 3), not by the Tier-1 git sandbox, which merges directly |
| C | **The approvals** | Nothing important happens without you seeing it first — each approval shows the content *before* the question, never a "naked" approval |
| D | **The autonomy tiers** | Small choices are made quietly; notable ones are jotted in the epic's notebook; ones that matter later are filed in the right place; only genuinely risky decisions stop and ask you |
| E | **The quality checks** | The automatic checks run light per story and in full over the whole epic, and report pass/fail **truthfully** — a real failure is never dressed up as a pass |
| F | **The safety hooks and permissions** | Dangerous shell commands are blocked, generated files land at the right name and place, build requests are steered into the workflow, and each helper is told which epic/stage/story it's on |
| G | **The generated code and app tests** | The code follows the standing policies (no error suppressions, exact API paths, Shadcn-only UI, one central place for styling, a role on every story, plain-language checklists), and the test layers cover each behaviour exactly once |

**Why most of this is testable.** A, B, E, and F are predictable — a stage move is
legal or it isn't, two edits combine cleanly or they conflict, a command is
blocked or it isn't. (The *approve-before-merge* half of B is a running-workflow
behaviour, so it's confirmed in Tier 3, not the git sandbox — see §6.) G is predictable to *check* even though the way Claude *writes*
the code isn't — we check the finished code against the rules. C and D are behaviours
of the *running* workflow, so we prove the pieces on their own (Tier 1), prove they
left the right traces in a recorded run (Tier 2), and confirm the whole thing feels
right with a person driving it (Tier 3). The one thing we deliberately **don't** test
is whether the AI writes *good* code — see [section 15](#15-what-we-deliberately-dont-test).

---

## 4. The three tiers

Tests run from fast-and-automated (bottom) to slow-and-human (top). Each tier catches
what the tier below it can't, and each is cheaper to run than the one above — so we
lean on the lower tiers for everyday confidence and save the human walkthrough for
releases.

| Tier | What it is | Runs automatically? | Needs a live AI? | Where it lives |
|------|------------|---------------------|------------------|----------------|
| **1** | Unit tests of the scripts, hooks, schemas, docs, git machinery, and generated-code rules | Yes | No | `tier-1-unit/` |
| **2** | Invariant checks over a **recorded real run** — its branches, commits, and `generated-docs/` output | Yes | No (recorded once by hand) | `tier-2-recorded-run/` |
| **3** | A person runs the real workflow with a real AI and confirms it behaves | No (manual) | Yes | The human walkthrough |

**Each tier has its own file.** The shared rules — the ones in this document — hold for
all three tiers. The detail for each tier lives on its own so you can work on one tier
without loading the rest: [tier-1.md](tier-1.md), [tier-2.md](tier-2.md), and
[tier-3.md](tier-3.md). Sections 6, 7, and 8 below are short signposts into those files.

**Why three tiers and not just unit tests.** A unit test can prove that
`epic-state.js` does the right thing when you call it. It **cannot** prove the AI
advances the stage at the right moment, that a story became exactly one commit, that
the merge waited for your approval, or that a "please double-check" item was floated
to the top of your hands-on check. Those are behaviours of the running workflow. So
Tier 1 proves each piece works on its own; Tier 2 proves the pieces left the right
*traces* in a real run (read from git and the generated files, no AI needed at test
time); Tier 3 proves the whole thing feels right when a human drives it live.

---

## 5. What we test — the surface area

Each area maps to a tier and to the real machinery under `.claude/`.

| # | Area | The real files it covers | Tier |
|---|------|--------------------------|------|
| A | **Epic-state machine** | `epic-state.js` (create/read/advance a stage), `mark-epic-complete.js` (freeze after merge), `resolve-state-path.js` (find the branch's state file) | 1 |
| B | **Legacy migration** | `migrate-legacy-state.js` — upgrades an old-shape project to the epic-branch model | 1 |
| C | **Quality-checks runner** | `quality-gates.js` — runs the automatic checks and reports pass/fail | 1 |
| D | **Dashboard & progress** | `collect-dashboard-data.js`, `generate-dashboard-html.js` (pulls every branch together, auto-refresh, fire-and-forget) | 1 |
| E | **Scan & setup utilities** | `scan-doc.js`, `init-preferences.js`, `run-smoke-test.js`, `summarize-playwright.js` (`import-prototype.js` was **removed** post-v1.2.0 — you now drop design files straight into `documentation/`; the old test feature-detects it and skips when absent) | 1 |
| F | **Permission & doc-name hooks** | `bash-permission-checker.js`, `enforce-generated-doc-names.js` (+ `validate-generated-doc-names.js`) | 1 |
| G | **PowerShell hooks** | `workflow-guard.ps1`, `inject-phase-context.ps1`, `inject-agent-context.ps1` (tested with Pester) | 1 |
| H | **Branch & merge machinery** | Epic branch naming and the auto-combine-vs-halt behaviour, exercised in a throwaway git repo | 1 |
| I | **Doc & config consistency** | Agent/command frontmatter, and cross-references between `CLAUDE.md`, the agents `README.md`, and the real files on disk | 1 |
| J | **JSON schema validation** | `state.json` matches its schema (its stage list is imported from the template, not copied) | 1 |
| K | **Generated-code linting** | Rules over the `web/src/` code the workflow produces (see the rules below) | 1 |
| L | **Recorded-run invariants** | One captured run's branches, commits, and `generated-docs/` output | 2 |
| M | **Live behaviour** | The full workflow with a real AI — the final word | 3 |
| N–U | **Multi-version testing** | Channels, per-version contracts, changelog attribution, version gap/gating — see [section 12](#12-testing-any-template-any-version) | 1 → 3 |

> **Some Tier-1 tests ship next to the code.** Several template scripts carry their
> own co-located tests (`epic-state.tests.js`, `bash-permission-checker.tests.js`,
> `scan-doc.tests.js`, …). The suite here adds the cross-cutting checks those can't
> cover on their own — doc drift, schema, git machinery, generated-code linting, and
> the recorded-run invariants.

### The generated-code rules Tier 1 checks (area K)

Each rule is a small pure function, tested two ways: fed known-good and known-bad
samples (always runs), and run over the real `web/src/` / `generated-docs/` output
when it exists (skips visibly when it doesn't). Each rule ties to a standing policy,
and each has a concrete **detection recipe** used both by the lint and by a human in
the Tier-3 walkthrough:

| Rule | Passes when | How it's detected (broken case) |
|------|-------------|----------------------------------|
| **No error suppressions** | none present | grep `@ts-ignore\|@ts-expect-error\|@ts-nocheck\|eslint-disable` |
| **Shadcn only** | UI primitives imported from `@/components/ui/` | a hand-rolled primitive from raw HTML + Tailwind |
| **Exact API paths** | endpoints use the description's paths, via the shared client | a guessed path (e.g. `/api/tasks` vs `/api/v2/tasks`), or a raw `fetch(` outside the client |
| **One place for styling** | colours/fonts/spacing reference central tokens | a one-off hex colour in a screen |
| **Every story has a role** | each story file has a non-empty role, given as `**Role:**`/`**Roles:**` or a `\| Role \|`/`\| Roles \|` table row | a missing/empty role line |
| **Plain language** | user checklists carry no jargon | grep (case-insensitive) `tsc\|eslint\|gate [0-9]\|isloading\|skeleton` |

---

## 6. Tier 1 — automated unit tests

**The full Tier 1 detail now lives in its own file: [tier-1.md](tier-1.md).** It covers
the fast, automated Vitest and Pester tests of the scripts, hooks, schemas, git
machinery, and generated-code rules. It was moved out so you can work on one tier
without loading the whole document; the shared rules it relies on stay here in this hub.

In short: Tier 1 runs on every change, finishes in seconds, and proves each script,
hook, and schema does the right thing on its own — with extra care for the epic-state
machine, the branch-and-merge git sandbox, the security-critical permission hook, and
doc/config drift.

---

## 7. Tier 2 — invariants over a recorded run

**The full Tier 2 detail now lives in its own file: [tier-2.md](tier-2.md).** It covers
the checks that run over one recorded real run — its branches, commits, and
`generated-docs/` output — with no live AI at test time. It was moved out so you can
work on one tier without loading the whole document; the shared rules it relies on stay
here in this hub.

In short: Tier 2 is the bridge between "each script works" (Tier 1) and "needs a live
AI" (Tier 3). A person records one full run by hand; the tests then replay that
recording and check the things that only make sense across a whole epic — one branch
per epic, one commit per story, a well-formed ordered state file, a real decision
trail, matching app tests, absence canaries, and the parked-epic `/plan` traces.

---

## 8. Tier 3 — the human walkthrough

**The full Tier 3 detail now lives in its own file: [tier-3.md](tier-3.md).** It covers
the manual, live-AI walkthrough — the final word before a release — including the
version-independent behaviours to confirm by hand and the `/plan` plan-ahead scenarios.
It was moved out so you can work on one tier without loading the whole document; the
shared rules it relies on stay here in this hub.

In short: a person runs the real workflow with a real AI and confirms the behaviours no
unit test can judge — the stages happening in order, every approval showing its content
first, building stopping only for genuinely risky choices, the hands-on check being
truly hands-on, and the merge always waiting for you. Tier 3 is **not** an npm command;
it's run before a release, and each clean pass is a good moment to re-record the Tier 2
fixture.

---

## 9. Good case / broken case — the discipline

A sample of the pairs the suite proves both ways — the "broken" case is what makes
each check trustworthy. (The stage/gate names shown are the current v1.2.0 examples;
the tests read them from the template.)

| Check | "Good" case (passes) | "Broken" case (must go red) |
|-------|----------------------|------------------------------|
| Valid stage move | a legal move with its inputs ready → allowed | a skip-ahead move, or BUILD before stories are approved → refused |
| Fresh epic state is repeatable | `epic-state.js` creates the same `state.json` twice → identical | a create that varies run to run → flagged |
| State path resolves per branch | `resolve-state-path.js` finds the current epic's file → correct | points at the wrong branch's file → flagged |
| Merge waits for approval | epic reaches `main` via an approved merge → passes | a direct push to `main` bypassing the merge → flagged |
| Overlaps auto-combine | two epics add different style tokens → combine cleanly | two epics edit the same code conflictingly → stop and show both |
| Quality check reports truthfully | a clean epic → checks pass | inject `const x: number = "nope";` → the "sound" check FAILs and blocks the save |
| Dangerous command blocked | `ls`, `npm test` → allowed | `rm -rf /` and variants → denied |
| Doc name enforced | a file at `generated-docs/epics/<epic>/…` → allowed | a file with the wrong name or location → blocked |
| No error suppressions | clean generated code → passes | `@ts-ignore` / `eslint-disable` added → flagged |
| Exact API paths | endpoints use the description's `/api/v2/tasks` → passes | a guessed `/api/tasks`, or a raw `fetch()` → flagged |
| Story has a role | a non-empty role line present → passes | an empty or missing role → flagged |
| Routable story has a live spec | a live `test()` in its Playwright file → passes | the whole suite `test.fixme()`'d on a routable story → flagged |
| Content before approval | the plan shown above the Approve buttons → passes | a "naked" approval with nothing to review → flagged |
| Absence canary | no telemetry ledger / no `code-reviewer` → passes | either reappears → flagged |

---

## 10. Helpers, checkpoints, and rollbacks

A small set of helpers keeps each test short, and two shared ideas keep them fast.

| Helper | What it does |
|--------|--------------|
| `temp-project` | A throwaway project per test |
| `git-sandbox` | A throwaway git repo with branch/commit/merge helpers — powers the branch-and-merge tests |
| `checkpoint-fixtures` | Start at CP-0 … CP-5 without running the whole workflow |
| `rollback` | The RB-0 … RB-7 cleanup recipes |
| `state-fixtures` | Seed and read an epic `state.json` or a generated artifact |
| `run-script` | Runs a `.claude` script as a real subprocess and captures its output + exit code |
| `snapshot` | Normalises output so snapshot comparisons stay stable |
| `target` | Resolves the one path to the template under test (defaults to the parent repo, overridable with `REPO_ROOT`) |
| `changelog` / `targets` / `template-version` / `template-live` | The multi-version helpers — see [section 12](#12-testing-any-template-any-version) |

### Checkpoints (CP-0 … CP-5)

Named starting states, so a test doesn't have to run the whole workflow to reach the
point it cares about. Loaded from fixtures — a speed trick, not a dependency chain.

- **CP-0** — clean project on `main`, nothing started
- **CP-1** — intake done (`project.md` and `epic-plan.md` approved on `main`)
- **CP-2** — an `epic/<slug>` branch created, PLAN done (story list approved)
- **CP-3** — BUILD in progress (at least one story committed on the branch)
- **CP-4** — end-of-epic checks passed / hands-on check reached
- **CP-5** — epic merged into `main` (COMPLETE)

### Rollback recipes (RB-0 … RB-7)

Standard cleanup steps, each with an ID so a test can say exactly how it reset (they
match `helpers/rollback.ts`). Most are best-effort — each test's own temp-dir cleanup
is the real reset; the ID mainly documents what the test touched.

| ID | What it resets | The gist |
|----|----------------|----------|
| **RB-0** | full clean | remove `generated-docs/` + `documentation/` |
| **RB-1** | epic state | remove `generated-docs/epics/` |
| **RB-2** | one file | `git checkout -- <file>` (or restore from a saved copy) |
| **RB-3** | a test doc | delete the doc file the test wrote |
| **RB-4** | legacy state | remove a stray top-level `workflow-state.json` |
| **RB-5** | write perms (Windows) | restore write access: `icacls <path> /grant "<user>:(OI)(CI)M"` and remove any deny ACE |
| **RB-6** | dependencies | reinstall: `npm ci` |
| **RB-7** | injected fault | revert the last deliberately-injected error |

---

## 11. Test inputs and fixtures

To keep two runs comparable, the suite always uses one imaginary project — the **Team
Task Manager** — a task tool for small teams with two user types (admin and member), a
clear set of data (title, description, due date, assignee, status), no starting
data-service description, a data source still in development, some styling
preferences, and no regulated data. It's picked because it exercises a lot of the
workflow at once: role-based permissions, a real data service to design, a stand-in
data layer to build against, a styling pass, and **two epics** so we see the move from
one epic (and branch) to the next.

**The canonical inputs live as data, not prose** — under `fixtures/scenarios/`, so
tests read them directly and two people can't drift:

| Fixture | What it holds |
|---------|---------------|
| `scenarios/team-task-manager/answers.json` | the exact answers to every setup question (roles, sign-in, data source, compliance, styling) |
| `scenarios/team-task-manager/frs-expected.md` | the expected shape of the captured project facts |
| `scenarios/variant-a-bff/answers.json` | **Variant A** — sign-in handled by your own server (BFF); its auth endpoints |
| `scenarios/variant-b-no-backend/answers.json` | **Variant B** — no data source; stand-in data only |
| `scenarios/variant-c-user-spec/task-api.yaml` | **Variant C** — you already provided a data-service description (OpenAPI using `/api/v2/tasks`); proves the generated code honours the exact paths, never a guessed `/api/tasks` |

Switch a variant in only when a test calls for it. To adjust the canonical run, edit
the fixture — never re-narrate it in prose.

---

## 12. Testing any template, any version

The same tests can be aimed at **any** template at **any** version, and can **compare
two versions** to answer *"is dev safe to promote to release?"* — without editing a
test. It leans on the one path the suite already resolves through (`REPO_ROOT`); the
new machinery is a thin front layer, held to every rule in
[section 2](#2-the-rules-every-test-follows).

**The template carries its own version.** Every template records where it stands in a
`template-version.json` at its root (e.g. `{ "templateRef": "v1.1.0" }`) and documents
how it got there in a root `CHANGELOG.md` ([Keep a
Changelog](https://keepachangelog.com/en/1.1.0/) format). The suite reads both — the
marker to know *which* version it's testing, the changelog to explain *why* two
versions differ. It also reads that version's own workflow docs
(`.claude/WORKFLOWS.md`, `.template-docs/`) as the per-version "how it works".

### Two more promises

| # | The thing | The promise |
|---|-----------|-------------|
| H | **Any template, any version** | Name a template (`dev` / `release` / …) and a version, and the suite tests exactly that — downloading it, aiming itself at it, judging it against *that version's own* recipe, and filing results under its name and version. No test edits. |
| I | **Safe-to-promote comparison** | Lining dev up against release shows exactly what differs. A difference a changelog entry explains is flagged **pending-promotion** (amber — doesn't fail); a difference with **no** changelog entry is **unexplained drift** and fails (red). |

### The machinery (and the real files it leans on)

| Piece | What it is | Leans on |
|-------|-----------|----------|
| `targets.json` | The channel list — each named template → its repo URL and contract. One line to add a template. | — |
| `scripts/run-target.cjs` | The "tune in" step — clones a named target at a ref into throwaway `.targets/`, prints the version-gap banner, aims `REPO_ROOT` + `QA_TARGET`, files results under `<target>-<ref>/`. | `targets`, `template-version` |
| `template-contract.{dev,release}.json` | Two recipes, one per template, so each version is judged against its own shape — never the other's. | `reconcile-template.cjs` |
| `VERSION` | The suite's own baseline — the template version these tests were written for. | — |
| `helpers/changelog.cjs` | Parses a template's `CHANGELOG.md`; returns the entries between two versions and attributes a difference to the entry that introduced it. | `CHANGELOG.md` |
| `scripts/compare-targets.cjs` | The comparison step — diffs two checkouts' live values and gives a green / amber / red verdict. | `changelog`, `template-live` |

### New areas, and their good/broken cases

| # | Area | Good case | Broken case |
|---|------|-----------|-------------|
| N | **Channel resolution** | `dev`/`release` → their repo URL + contract | an unknown name → clear error, **not** a silent default |
| O | **Per-version contract** | release live values match the release contract → green | a stage present live but absent from its contract → red |
| P | **Version marker & gap** | valid `template-version.json` → `templateRef` parsed; equal versions → "in sync" | missing/malformed marker → reports "unknown", never crashes; a gap is **shown**, not swallowed |
| Q | **Changelog & attribution** | real `CHANGELOG.md` → ordered typed entries; a diff matching an entry → **explained** | a malformed heading → skipped, parser doesn't throw; a diff with no entry → **unexplained** |
| R | **Dev-vs-release comparison** | identical → green; differ only by logged work → amber (run not failed) | differ with an unexplained diff → red (exit 1) |
| S | **Version-gated tests** | a check marked "from vX.Y" runs on vX.Y | the same check *fails* instead of skipping on an older version |
| T | **Grade by own rules** | point at an old version → reads *its* rules and grades against them | an old version graded against today's rules → fake failure (prevented) |
| U | **Labelled results** | a run for `dev v1.1.0` writes to `…/dev-v1.1.0/` | two versions' results colliding in one folder → flagged |

> **Where the live download sits.** The *logic* above (parsing, resolving,
> attributing, gap maths, label routing) is Tier 1 — pure, fast, fed fixtures, each
> with a good and a broken case. The *actual clone* of a real ref is network-bound, so
> it's proven once as a recorded checkout in Tier 2 and end-to-end by a person in
> Tier 3.

### Handling the version gap honestly (the four layers)

When the suite is newer than the template it's testing, a check for something that
didn't exist yet must **never** read as a bug:

- **A — Show the gap.** Every run prints and saves three facts: the version the suite
  was written for (`VERSION`), the version under test (`template-version.json` →
  `templateRef`), and the gap — plus, from the changelog, *what* changed across it.
- **B — Gate each test by version.** A check declares the versions it applies to;
  checks for later features **skip as Not-Applicable** on older versions, never fail.
  Green = correct for this version · Skipped = not part of it yet · Red = a real problem.
- **C — Judge by the version's own rules.** Wherever it grades, the suite reads the
  template's *live* values from the version under test — never today's hard-coded ones.
- **D — Match the suite to the version.** The cleanest option: the suite is versioned
  too (its `VERSION` file and git tags), so to test a 3-versions-old template you can
  run the suite *as it was then* — zero gap. Default to **D**; back it with A + B + C so
  a single suite can still stretch across nearby versions honestly.

> **Two versions, two homes.** The **suite's** version is its committed `VERSION`
> file; the **template's** version is its own `template-version.json` (`templateRef`),
> git tag as fallback. The drift banner (Layer A) prints the two side by side.

**Commands:**

```
npm run test:target -- --target dev --ref v1.1.0        # tune in, run, file results
npm run compare:targets -- --a release --a-ref v1.0.0 --b dev --b-ref v1.1.0   # promote check
QA_TARGET=release npm run reconcile                       # reconcile a target's contract
```

---

## 13. Keeping the tests in step with the template

When the template changes, two things can go stale: tests that encode a template
invariant, and this doc where it names a version-specific example. The routine:

**1. Triage before you fix — never silence a failure.** Classify each failure:

- **Test bug** — the template changed legitimately and the test must follow it (e.g. a
  new stage was added on purpose). Update the test.
- **Template regression** — the test caught a real break. Fix the template, not the
  test.
- **Content drift** — a doc/example no longer matches the files. Fix the doc.

Produce that classification *first*, with a one-sentence reason each. **Never loosen an
assertion to make a red go green**, and when two sources contradict each other, stop
and surface it rather than silently picking a winner.

**2. Reconcile the contract.** Run `npm run reconcile` (or
`QA_TARGET=<target> npm run reconcile`). It compares the pinned `template-contract*.json`
against the template's live values and prints, in plain English, exactly what to
update. This automates what used to be a manual audit.

**3. Know what auto-updates vs. what you must audit by hand.**

- **Auto-updates** (single-sourced from the template): the `state.json` schema and its
  drift guard read `epic-state.js` (`EPIC_PHASES` etc.), so phase changes flow through
  automatically once the contract is reconciled.
- **Hard-coded shapes to audit on any change**: `helpers/state-fixtures.ts`,
  `helpers/checkpoint-fixtures.ts`, `helpers/manifest-fixtures.ts`. If the template's
  shapes moved, these need a manual pass.

**4. When something is renamed, grep every place it hides.** An agent/command/script
name appears in more than the obvious file: `agents/README.md`, the root `README.md`,
`commands/*.md`, `CLAUDE.md` / `.template-docs/`, and the tier-1 tests that name it
explicitly. An explicit-name reference in a test is an **invariant**, not a test bug —
if it breaks, a rename wasn't finished.

**5. Re-record the golden run** after any change to how the workflow *runs*
(orchestrator rules, agent prompts, settings, hooks) — see [section 7](#7-tier-2--invariants-over-a-recorded-run).

**6. Adding a test?** Don't duplicate a script's co-located `*.tests.js`. Add only the
cross-repo / drift / smoke checks those can't cover, and always a good **and** a broken
case (rule 1). Use `runScript()` + `createTempProject()`; cover the happy path plus at
least one failure path.

---

## 14. Coverage today and open work

**Where coverage sits**, by surface:

| Surface | AI-tests here | Co-located `*.tests.js` | Notes |
|---------|:---:|:---:|-------|
| Scripts (`.claude/scripts/*.js`) | ✅ cross-checks | ✅ per script | suite adds drift/smoke only |
| Hooks (bash + PowerShell) | ✅ | partial | permission hook fuzzed hard |
| Consistency (frontmatter, cross-refs) | ✅ | — | doc-drift lives only here |
| Schema (`state.json`) | ✅ | — | single-sourced from `epic-state.js` |
| Artifact-lint (generated code) | ✅ | — | samples always; real output when present |
| Multi-version (§12) | ✅ | — | good + broken |
| Report XSS-escaping (dashboard + build-report) | ✅ | partial | `esc()` over real generated HTML |
| Collector project-status agreement | ✅ | — | dashboard ↔ build-report cross-script smoke |
| `/upgrade` deletion-safety (`apply-template.js`) | ✅ | dev only | end-to-end smoke: retired files pruned, user work kept |

**Baselined to v1.3.0 (2026-08-14).** The suite `VERSION` is `v1.3.0` and the release contract is
reconciled to it. Validated against the real released template: `test:target --target release --ref
v1.3.0` → 425 passed / 0 failed / 5 skipped, and `reconcile:check` (QA_TARGET=release) → nothing to
update. v1.3.0 is the post-v1.2.0 cut this branch (S8-129) re-baselined to — the build-from-design
feature, the report split, the removed `import-prototype`, and the doc-name fix. (v1.2.0 added the
READY-TO-BUILD stage for `/plan`, still pinned.)

**Re-baselined for a post-v1.2.0 (`[Unreleased]`) cut (branch `S8-129`).** A template
archive labelled `v1.2.0` but carrying later `[Unreleased]` changelog work was run through
Tier 1 and produced 9 failures — **all suite-lag, no template regression** (triaged per
§13.1). Three `[Unreleased]` changes drove them, and the version-sensitive tests were
realigned to match:
- **Doc-name enforcement fixed.** The epic-scoped `<slug>` defect (below) was fixed, so the
  6 `it.fails()` markers became unexpected-passes and were removed (they now assert the
  drift is blocked/flagged directly). See the resolved-defect note.
- **Build report moved to `generated-docs/reports/`.** The XSS-escaping canary read the old
  root path and ENOENT'd *before* its assertions ran — silently vacuous. It now reads
  `generated-docs/reports/build-report.html`, restoring real coverage.
- **`import-prototype.js` removed.** The two tests for it now `skipIf(!scriptPresent)`
  (feature-detected) instead of hard-erroring on the absent script.

Result against that archive: Tier 1 **365 passed, 5 skipped, 0 failed**. See *Planned
coverage for the post-v1.2.0 changes* below for the new tests these changes call for.

**Testing conventions this suite uses (version-independent):**

- **Skip vs. green vs. red are distinct** (rule 6 + §12 Layer B). A check that a version
  doesn't apply to must **skip**, never quietly pass — use `it.skipIf(...)` /
  `describe.skipIf(...)`, feature-detected (e.g. "is the build-report collector present?"),
  not a bare `return` (which Vitest counts as a pass).
- **Known template defect → `it.fails()`, not a loosened assertion** (§13.1). When the
  suite catches a real template bug it can't fix from here, mark the case `it.fails()`
  (expected-fail) with a comment naming the root cause. The baseline stays honestly green
  on the *known* bug, a real NEW regression is still visible, and the case flips **red**
  (unexpected pass) the instant the template ships the fix — the cue to remove the marker.
  **Worked example (now closed):** the 6 doc-name-enforcement cases carried this marker for
  the epic-scoped `<slug>` defect; the post-v1.2.0 template shipped the fix, they flipped to
  unexpected-passes, and the markers were removed (see the resolved-defect note below). That
  full loop — mark → ship → flip red → remove — is exactly how the convention is meant to end.
- **`test:target` needs a CommonJS marker.** `run-target.cjs` / `compare-targets.cjs`
  clone the template into `.targets/`, which sits inside this suite (`"type":"module"`).
  `helpers/targets.cjs → ensureTargetsDir()` drops `{"type":"commonjs"}` at `.targets/`
  so the template's CommonJS scripts load as CJS, not ESM. Without it every
  script-spawning test breaks with `require is not defined`.

**Resolved template defect (fixed post-v1.2.0):** epic-scoped doc-name enforcement was a
silent no-op — the hook/validator `dirGlobToRegex` translated `*` but not the `<slug>`
placeholder, so `generated-docs/epics/<slug>/` never matched a real epic dir. Present on
both channels since ≤ v1.1.0; the suite pinned it with 6 `it.fails()` cases. The
post-v1.2.0 cut ships the fix (changelog: *"Misnamed workflow documents are now caught"*) —
`dirGlobToRegex` now translates the `<slug>` placeholder, so drift is correctly blocked
(hook exit 2) and flagged (validator exit 1). The 6 `it.fails()` markers were removed on
branch `S8-129`; the cases now assert the corrected behaviour directly. **Caveat for
older targets:** these cases are plain `it` (not feature-detected), so aiming the suite at a
genuine pre-fix archive (exact v1.1.0/v1.2.0) will legitimately turn them red — the defect
really is present there. If cross-version-clean is wanted, gate them on a behaviour probe.

### Planned coverage for the post-v1.2.0 changes

The `[Unreleased]` cut adds and reshapes real surfaces. Each planned test below follows
every rule in [section 2](#2-the-rules-every-test-follows) — a good **and** a broken case,
isolated, and **feature-detected** (`skipIf`/`describe.skipIf` on the surface being present)
so it activates on the versions that have it and skips — never fails — on those that don't.
Nothing here is written yet; this is the spec. Report generation lives in **scripts**
(`generate-build-report-html.js --audience maintainer|stakeholders`, `generate-build-effort.mjs`,
`collect-build-report-data.js`) — there are no `/build-report*` slash commands in this cut,
so the tests target the scripts and their output, not commands.

| # | Change (from the changelog) | Surface under test | Tier | Good case | Broken case (must go red) |
|---|-----------------------------|--------------------|:----:|-----------|----------------------------|
| 1 | **Two reports, one location** | `generate-build-report-html.js` `AUDIENCES` → both write under `REPORTS_DIR_REL` (`generated-docs/reports/`) | 1 | maintainer + stakeholders HTML land in `generated-docs/reports/` | a report written to the old root `generated-docs/` path → flagged |
| 2 | **Old report commands gone** | absence canary over `.claude/commands/` + refs | 1 | no `/build-report`, `/workflow-insights`, or the three older report commands exist | any of them reappears (file or reference) → flagged |
| 3 | **`import-prototype` removed** | absence canary: script absent **and** unreferenced across `.claude/` | 1 | `import-prototype.js` gone and zero references | the script or a caller/command re-appears → flagged |
| 4 | **Stakeholders "Decisions you signed off"** | `generate-build-report-html.js --audience stakeholders` over seeded decision records | 1 | signed-off decisions render in plain language **with dates**, drawn only from the record | a decision not in the record appears (invented) → flagged |
| 5 | **Maintainer decisions summary** | maintainer render over seeded decision records | 1 | leads with #decisions-asked, typical answer time, #no-input phases; then logs each question + chosen option | counts don't move with the input (hard-coded) → flagged |
| 6 | **Effort benchmarks + sizing calculator** | `generate-build-effort.mjs` (has co-located `*.tests.js` — add cross-checks only) | 1 | per-screen-type / per-feature medians computed from real build records; calculator sizes a screen mix | figures fabricated when records are absent → flagged |
| 7 | **Part-built feature excluded** | effort/benchmark aggregation | 1 | a fully-measured feature counts toward the "typical feature" figure | a feature with only some stories finished is **excluded** and marked *partly measured*, not counted → (broken = it drags the average) |
| 8 | **Per-project cost scoping** | `collect-build-report-data.js` over sibling folders `my-app`, `my-app-QA` | 1 | only the project's own git-owned work is counted | a sibling's work folded into the totals → flagged |
| 9 | **Missing figure → no lost page** | `generate-build-report-html.js` fed a partial/corrupt data file | 1 | page still generates end-to-end (exit 0, page written, no `NaN`/`undefined` in rendered text) | one bad figure throws and aborts the whole page → flagged (the `—` dash-rendering itself is covered at the pure `renderEffort()` level co-located, per §13.6) |
| 10 | **Report before `/start` → guidance** | `collect-build-report-data.js` on a no-project tree (extend the existing collector-status test) | 1 | returns a "run `/start`" pointer, not a report | a no-project tree treated as a one-detail-missing report → flagged |
| 11 | **No PR comments from CI** | static check over `.github/workflows/*.ya?ml` | 1 | no concrete PR/issue-comment step (`createComment`/`updateComment`/`createReviewComment`, comment marketplace actions, `gh pr/issue comment`) | a comment step present → flagged (concrete mechanisms only — a bare `issues: write` permission is deliberately not flagged) |
| 12 | **Cross-platform browser open** | whichever script opens the dashboard/approval/report in a browser | 1 | has a darwin/linux branch (`open`/`xdg-open`) alongside Windows | Windows-only open path → flagged |
| 13 | **Build from an existing design** | `scan-doc.js` over design inputs in `documentation/` (tokens.css, an HTML mockup, an OpenAPI yaml); intake-manifest schema accepts a design source | 1 | design files under `documentation/` are recognised/scanned; the manifest validates with a design source | a design source the manifest rejects, or a design file `scan-doc` mis-types → flagged |
| 14 | **Design ingestion read back at Intake** | live behaviour — Claude reads `documentation/` design, states the screens/colours/wording (incl. what it couldn't work out) **before** building, to confirm | 3 | intake read-back names the design-derived facts and asks to confirm | it builds from the design without a confirmable read-back → noted |
| 15 | **Update design mid-project** | live behaviour — "rebuild these screens to match my updated design" changes only the named screens; prior decisions preserved; a contradiction **asks which wins** | 3 | only named screens change; kept decisions survive; conflict prompts | an un-named screen changes, or a prior decision is silently overwritten → noted |

**Implemented so far (branch `S8-129`):** #1–5, #9–13 are built and green against the
post-v1.2.0 archive —
- **#4** → [`tier-1-unit/scripts/stakeholder-decisions.test.ts`] — end-to-end `--audience
  stakeholders`: the "Decisions you signed off" section renders each decision + choice + date
  from the authored record; teeth = the section **vanishes** with no record (so it's data-driven,
  not an always-on block) **and the rendered count equals the record** ("1 decision recorded") —
  an invented or duplicated row moves the count and fails.
- **#5** → [`tier-1-unit/scripts/maintainer-involvement.test.ts`] — end-to-end `--audience
  maintainer`: a populated `build-cost-data.json` surfaces the unattended-phase count, the
  typical answer time, and the verbatim logged question; teeth = an unlogged question never
  appears, **and the count/time VALUES move with the input** — a second fixture renders `3 / 2` /
  `1m 30s` and *not* the first's `2 / 1` / `45s`, so a hard-coded figure fails (proven by a
  mutation that hard-codes the count → red).
- **#1** → [`tier-1-unit/scripts/report-output-location.test.ts`] — maintainer + stakeholders
  both write under `generated-docs/reports/`; teeth = neither leaks to the old root path.
- **#12** → [`tier-1-unit/scripts/open-page-cross-platform.test.ts`] — `open-page.js`
  `openerCandidates()` resolves a real opener for win32 / darwin / linux (macOS `open`, Linux
  `xdg-open`); teeth = no platform returns an empty no-op list.
- **#13** → [`tier-1-unit/consistency/design-digest-contract.test.ts`] — the design feature is
  deliberately AI-driven/schema-free (its *reading* is Tier-3, #14/#15), so the plan's original
  scan-doc/manifest angle didn't fit. What IS deterministic is the **wiring**: `design-interpreter`
  emits `generated-docs/design/digest.md`, a `.claude/templates/design-digest.md` shapes it, and
  downstream agents read that path (cross-doc drift check, not prose). Teeth = a made-up digest
  path is referenced nowhere.
- **#11** → [`tier-1-unit/consistency/ci-no-pr-comments.test.ts`] — scans `.github/workflows/*.ya?ml`
  for **concrete** comment mechanisms (octokit `createComment`/`updateComment`/`createReviewComment`,
  comment marketplace actions, `gh pr/issue comment`) — not `permissions:` grants; teeth over the
  real matcher (a github-script `createComment` step is caught).
- **#9** → [`tier-1-unit/scripts/report-missing-figure-resilience.test.ts`] — end-to-end subprocess
  proof the CLI writes a whole page (exit 0, page written, no `NaN`/`undefined` in rendered text) on
  a partial **and** a corrupt data file. (The `—`-for-an-unreadable-figure rendering is covered at
  the pure `renderEffort()` level by the template's co-located tests, per §13.6.)
- **#2** → [`tier-1-unit/consistency/retired-report-surfaces.test.ts`] — the retired `/build-report`
  command, the `workflow-insights` **skill** (`.claude/skills/workflow-insights/` — the real
  surface; an earlier cut of this canary watched a non-existent command path), and the
  `build-report-all|cost|effort` skills are gone; gated on the maintainer skill (the positive split
  marker), teeth via the replacement skills being present.
- **#3** → [`tier-1-unit/consistency/import-prototype-removed.test.ts`] — clean-removal canary:
  `skipIf` the script is present, else assert zero dangling references under `.claude/`; teeth via
  the same scanner finding a live script's references.
- **#10** → [`tier-1-unit/scripts/report-no-project-guidance.test.ts`] — the collector returns
  `/start` guidance on a no-project tree, and a real report once a project exists (teeth).

**#8 is deliberately NOT added here** — the sibling-scoping rule is already covered by the
template's own co-located `lib/report-core.tests.js` (it drives `discoverTranscriptDirs()`
directly). Duplicating it in this suite would break §13.6 ("don't duplicate a script's
co-located tests; add only the cross-repo/drift/smoke checks those can't cover"), so it's
left where it lives.

**#6 and #7 are deliberately NOT added here** — the effort benchmarks / sizing calculator (#6)
and the part-built-feature exclusion (#7) live in `generate-build-effort.mjs` and `renderEffort()`,
both **heavily covered by the template's co-located `generate-build-effort.tests.js` /
`generate-build-report-html.tests.js`** (medians, one-feature-indicative, partial-epic exclusion,
graceful degradation, the rate reaching every figure). The maintainer subprocess wiring is already
exercised end-to-end by #9. Re-testing them here would duplicate co-located coverage (§13.6), so
they're left where they live.

The remaining rows are the **Tier-3 live** ones (#14–15: design read-back at Intake, and
update-design-mid-project), which need a real AI run.

**#14/#15 — live capture DONE (branch `S8-129`); all six traces PASS.** A real Opus build of the
`design-taskboard` benchmark was run and captured. Deterministic traces are asserted over the
captured artifacts (digests + Phase-2 diff) by [`tier-1-unit/design/design-capture-replay.test.ts`]
(reads `fixtures/design-capture/`). The two live cores (`design-readback-confirmed`,
`design-conflict-asks`) were eyeballed and recorded in `tier-3-automated/DESIGN-CAPTURE-LOG.md`.
**The live run also tightened a check:** `decisionsPreserved` matched decisions verbatim, which
mis-flagged a legitimately *reconciled* decision ("New task" → "Add task") as dropped — now it
matches on the decision's stable topic/label, so reconciled wording passes and only a
genuinely-dropped topic fails.

Following the `/plan` three-tier split (§8), the deterministic traces are done and green:
- **assertion functions** → [`helpers/design-digest.ts`] — `digestReadyForIntake` (a filled digest
  vs the unfilled template), `decisionsPreserved` (a re-read never drops a recorded decision),
  `changesScopedTo` (a design update touches only the named screens).
- **Tier-1 good/broken** → [`tier-1-unit/design/design-traces.test.ts`] — over synthetic scaffolds
  and the REAL `.claude/templates/design-digest.md` as the canonical unfilled case; feature-detected
  on the design-interpreter agent.
- **benchmark fixture** → [`benchmark-files/design-taskboard/`] — a design (mockup + tokens +
  notes) with a deliberate Uncertainty and a Phase-2 update that renames/moves/adds and conflicts
  (purple vs the recorded blue).
- **capture checklist + rule ids** → [`tier-3-automated/DESIGN-SCENARIO.md`].

The live capture (above) exercised those functions over a real run; a `-Scenario design` still isn't
wired into the runner, so re-capturing is manual per the checklist. **All six acceptance criteria are
now covered** (AC1/AC2 record-only rules, AC3 navigability, AC4 real-backend exact-paths, AC5/AC6
hardened checks) — see [`tier-3-automated/DESIGN-COVERAGE.md`](tier-3-automated/DESIGN-COVERAGE.md).
The design **content** traces (digest ready, decisions preserved, navigability, exact API paths, the
AC5 can't-use case) gate via the `fixtures/design-capture/` replays. The Tier-2 golden run is a
separate `/plan` run (see [section 7](#7-tier-2--invariants-over-a-recorded-run) / the golden-run
README) — the design-taskboard run is not the golden run.

> **Coverage map, evidence corrections, and the prioritised gap plan** for the six build-from-design
> acceptance criteria live in [`tier-3-automated/DESIGN-COVERAGE.md`](tier-3-automated/DESIGN-COVERAGE.md)
> — a council audit confirmed all six labels but corrected the evidence behind AC3/AC5/AC6 (checks
> credited with more than they do). Start there to continue the work (AC4 real-backend benchmark is
> the one true hole).

**Tier-2 additions** (activate when the golden run is re-recorded on this cut): the two
reports land under `generated-docs/reports/`; the **absence canaries** grow to include
`import-prototype.js` and the retired report commands; and — if the recorded run carried a
design in `documentation/` — the design-derived intake facts are present.

**Open work:**

- **Golden run — fully captured; all three Tier-2 blocks gate.** A real **build-one-park-one** run
  (`minimal-concurrent`: Notes built + merged, Tasks parked at `READY-TO-BUILD`) is committed at
  `fixtures/golden-run/repo.bundle` (~900 KB, carries `generated-docs/` + git history). The Tier-2
  **artifact**, **git-topology**, *and* **`/plan` parked-epic** invariants all now gate (14/14, none
  skipping). Nothing dormant remains ([section 7](#7-tier-2--invariants-over-a-recorded-run)).
- **`/plan` live behaviours (Tier 3)** — the two deterministic Tier-1 gaps are **closed**
  (the dashboard's *ready-to-build / parked* rendering and the *epic-picker* legend agree with
  the collector's statuses), and **both live scenarios are now built** in
  `tier-3-automated/` with per-criterion, record-only rule ids and good/broken Pester coverage
  for every pure/real-git assertion function: **PLAN-A** (`-Scenario plan`, single-session
  worktree planning → parking on `main` → resume-straight-to-build) and **PLAN-B**
  (`-Scenario concurrent`, a bare remote + two simultaneous sessions → build-while-plan
  non-interference + shared-`main` consistency). Both are specified with their rule ids in
  [section 8's `/plan` subsection](#8-tier-3--the-human-walkthrough). **What remains is live
  validation** — a real run of each (they drive real Claude sessions, so like the rest of
  Tier 3 they're proven by running them, not by the unit suite), and PLAN-B's AC14 merge-block
  is scored only when a run actually reaches a dependent merge. The **deterministic parked-epic
  traces** are now *also* asserted in **Tier 2** as pass/fail invariants over the recording
  (parked story list, no `epic/<slug>` branch / no build, no leftover `plan/<slug>`,
  on-`main`-via-`docs(plan)`, `dependsOn` when blocked) — feature-detected, so they activate
  the moment the golden run above includes a parked epic. Tier 3 keeps only the irreducible
  live cores (see [section 8](#8-tier-3--the-human-walkthrough)).
- **Version-gating (Layer B) as channels diverge** — today both are at v1.2.0, so the
  default is **Layer D** (the suite is tagged per version; test an old template with its
  matching-version suite). When a real divergence appears, gate the affected checks on
  **feature-detection** (is the surface live?), not a version-number compare — dev and
  release can share a version string yet differ.
- **Legacy-migration cross-check** for `migrate-legacy-state.js` (optional; it already
  has a co-located test).

> The run-by-run pass/fail tally is **not** kept here — it drifts. Read it from the
> latest report under `TestResults/` (or `TestResults/<target>-<ref>/`).

---

## 15. What we deliberately don't test

- **Whether the AI writes good code.** You can't reliably unit-test "did the AI make
  the right call?" — that's a job for evaluation harnesses, not this suite.
- **The exact wording of agent prompts.** Too brittle; they change often. We check
  structure (valid frontmatter, allowed tools) instead.
- **A real AI call inside the automated run.** Expensive and flaky — Tier 2 replays a
  recording instead, and until then it's a Tier 3 check.
- **The look and feel of the built app.** How something looks or reads to a screen
  reader is a hands-on judgement — it lives on the hands-on checklist, not here.
- **Template internals with no cross-repo surface** — e.g. `workflow-helpers.js`
  internals, `test-harness.js`, tone-guide *content*. Covered by their own co-located
  tests or out of scope by design.

---

## 16. Running the suite

```
npm install && npm test          # standard run: builds the report, exits non-zero on failure
npm run test:raw                 # Vitest only, no report wrapper
npm run test:tier1               # Tier 1 only
npm run test:pester              # the PowerShell hooks (needs PowerShell 7 + Pester 5)
npm run test:full                # also exercise the web build, the browser specs, and the checks
npm run test:target -- --target dev --ref v1.1.0     # aim at a specific template + version (§12)
npm run compare:targets -- --a release --a-ref v1.0.0 --b dev --b-ref v1.1.0   # promote check (§12)
```

- **Standalone is safe.** With no template present, template-dependent tests skip with
  a visible notice (rule 6); the rest still run.
- **Cross-platform.** Run Tier 1 on both Linux and Windows — path handling is the
  number-one source of flakiness, and this template is used heavily on Windows.
- **The tools:** **Vitest** (JS areas), **Pester** (`.ps1` hooks), **ajv**
  (JSON-against-schema), a **git sandbox** helper (branch-and-merge tests), and Node's
  `child_process` (running scripts where the exit code matters).
- **Tier 3 isn't an npm command** — it's the human walkthrough, run before a release.

---

## 17. Quick reference — what each area protects against

| Area | What breaks if it fails |
|------|--------------------------|
| Epic-state machine | An out-of-order stage move, or advancing with a required input missing |
| Fresh-epic / mark-complete scripts | A new epic's state file, or freezing a merged one, isn't perfectly repeatable |
| Legacy migration | An old-shape project can't be upgraded to the epic-branch model |
| Quality-checks runner | A real failure is reported as a pass |
| Dashboard | The dashboard goes stale, shows work too early, or a dashboard error stops the workflow |
| Scan / setup utilities | A doc isn't scanned, or a preference isn't saved (`import-prototype` retired post-v1.2.0) |
| Report generation & scoping | A report lands outside `generated-docs/reports/`, folds a sibling project's costs in, or a single missing figure loses the whole page |
| CI noise | The automated checks start commenting on PRs again (three emails per PR) |
| Bash permission hook | A dangerous command slips past the filter |
| Doc-name hook | A generated file lands at the wrong name or place |
| `workflow-guard.ps1` | A build request isn't steered into the workflow |
| `inject-phase-context.ps1` | After auto-trimming, the wrong epic/stage context is restored |
| `inject-agent-context.ps1` | A helper is launched without knowing its epic/stage/story |
| Branch & merge machinery | An epic merges without approval, or a real conflict is silently guessed |
| JSON schema | A silent shape change breaks existing `state.json` files |
| Consistency checks | An agent/command drifts from the docs (or a retired one lingers) |
| Artifact lint — suppressions | `@ts-ignore` / `eslint-disable` sneaks into generated code |
| Artifact lint — API paths | Generated endpoints use guessed paths, or a raw `fetch()` |
| Artifact lint — Shadcn / styling | A hand-rolled primitive or a scattered colour code appears |
| Artifact lint — role / plain language | A story loses its role, or jargon leaks into a user checklist |
| Recorded-run — branch & commits | One-branch-per-epic or one-commit-per-story stops holding |
| Recorded-run — plan & stories | The plan stops covering the request, or a story loses its criteria |
| Recorded-run — notebook / registry / double-check | The decision trail or the pre-merge double-check list goes missing |
| Recorded-run — absence canaries | A retired feature (telemetry, code-reviewer, old phases) creeps back |
| Channel resolution | A named template can't be aimed at, or an unknown name silently defaults to the wrong repo |
| Per-version contract | A version is judged against the wrong recipe, so it fails just for being ahead or behind |
| Version marker & gap | The version under test is unknown, or a suite-vs-template gap is hidden |
| Changelog & attribution | A real difference is mistaken for expected work, or expected work is mistaken for drift |
| Dev-vs-release comparison | Unexplained drift slips into release, or documented work needlessly blocks a promotion |
| Version-gated tests | A check for a not-yet-existing feature fails an old version instead of skipping |
| Grade by own rules | An old version is graded against today's rules — a fake failure |
| Labelled results | Two versions' results collide, so the side-by-side promote check can't be trusted |
| Tier 3 — full walkthrough | Anything the automated tiers miss |
