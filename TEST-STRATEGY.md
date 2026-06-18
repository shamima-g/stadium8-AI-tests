# Test Strategy — How We Test the Stadium 8 Template

This document explains **how the template itself is tested**, and why the tests
are organised the way they are.

> **What "the template" means here.** This suite tests the *machinery* that makes
> the workflow run — the scripts, hooks, JSON schemas, and agent/command
> definitions under `.claude/`. It does **not** test a feature an end user builds
> with the template, and it is **not** the per-story QA that happens inside the
> workflow. It is the safety net around the workflow's own plumbing.

If you want the exact commands to run the suite, see [README.md](README.md).
If you want the click-by-click live test script, see [TEST-GUIDE.md](TEST-GUIDE.md).

---

## The one-paragraph summary

We test in **three tiers**. Tier 1 is fast, fully automated unit tests of the
scripts and hooks — it runs on every change and needs no AI. Tier 2 replays a
recorded run of the workflow and checks that the right things happened in the
right order — also automated, also no AI, but it depends on a recording we
capture by hand once in a while. Tier 3 is the human walkthrough in
`TEST-GUIDE.md`: a person runs the real workflow with a real AI and confirms it
behaves. Each tier catches what the tier below it can't.

| Tier | What it is | Runs in CI? | Needs a live AI? | Where it lives |
|---|---|---|---|---|
| **1** | Unit tests of scripts, hooks, schemas, and docs | Yes | No | `tier-1-unit/` |
| **2** | Checks over a recorded workflow run (telemetry) | Yes | No (record once) | `tier-2-log-replay/` |
| **3** | A person runs the real workflow and observes | No (manual) | Yes | `TEST-GUIDE.md` |

---

## What this suite is pinned to

These tests describe **one specific version of the template** and will fail
loudly against a different one. They currently expect:

- **Four phases:** INTAKE → PLAN → BUILD → COMPLETE. There is no DESIGN, SCOPE,
  STORIES, REALIGN, TEST-DESIGN, WRITE-TESTS, IMPLEMENT, or QA phase.
- **One INTAKE artifact:** `generated-docs/specs/project-brief.md`. There is no
  "FRS" / feature-requirements document.
- **Five quality gates:** Gate 1 (manual, at each epic boundary) plus Gates 2–5
  (security, code quality, testing, performance) which run automatically inside
  BUILD. There is no Gate 6 and no spec-compliance-watchdog.
- **Telemetry, not session logs.** The template records events to
  `generated-docs/context/telemetry.ndjson`. It does **not** write
  `.claude/logs/*.md` files, and there is no `[Logs saved]` marker.

If a whole batch of tests starts failing after a template update, suspect a
version mismatch against this list before assuming the template is broken.

---

## Why three tiers (and not just unit tests)

A plain unit-test suite can prove that `transition-phase.js` does the right thing
when you call it. It **cannot** prove that the AI actually calls it at the right
moment, or that the dashboard refreshes before the next phase starts, or that an
approval question is never shown without something to approve. Those are
behaviours of the *running workflow*, not of any single script.

So we split the problem:

- **Tier 1** proves each piece works on its own.
- **Tier 2** proves the pieces fire in the right order, by reading a recording of
  a real run — without needing the AI again.
- **Tier 3** proves the whole thing feels right when a human drives it live.

Each tier is cheaper and faster than the one above it, so we lean on the lower
tiers for everyday confidence and reserve the human walkthrough for releases.

---

## The three documents, and how they fit together

| Document | What it is | Tier it serves |
|---|---|---|
| [TEST-GUIDE.md](TEST-GUIDE.md) | The human walkthrough — every live test with setup, pass steps, fail steps, and rollback | Tier 3 |
| [TEST-INPUTS.md](TEST-INPUTS.md) | The exact answers to type at each prompt, so every run is identical | Shared by Tiers 2 and 3 |
| **TEST-STRATEGY.md** (this file) | The plan: what we test, how it's organised, the conventions everything follows | Tiers 1 and 2 |

`TEST-GUIDE.md` is not redundant with the automated tests. It is the **source of
truth for how the workflow should behave**. The automated tiers exist to catch
most regressions without a person, but the guide is the final word.

---

## Conventions every test follows

These rules come from `TEST-GUIDE.md` and apply across all tiers. They are worth
keeping because they are what make the suite trustworthy.

- **A passing case AND a failing case for every behaviour.** Every `describe`
  block has both an `it('works when …')` and an `it('fails when …')`. A test that
  only ever passes can't prove it would catch a regression — the failing case
  proves the test actually distinguishes good from bad.
- **Each test cleans up after itself.** Setup, teardown, and no leftover state.
- **No test depends on another.** Any test can run on its own, in any order.
- **Isolated.** Each test works in its own throwaway folder under the OS temp
  directory — never in the real repo, never on a git branch.
- **Fast.** Tier 1 tests aim for under 100 ms each; state-machine tests under
  10 ms.
- **Cited cleanup.** Each test's `afterEach` calls `rollback(root, 'RB-N')`,
  naming the cleanup recipe it used (the recipes are listed in `TEST-GUIDE.md`).

---

## Shared building blocks

These two ideas are reused by both the live guide and the automated tests:

- **Checkpoints (CP-0 … CP-4)** — named starting states, so a test doesn't have
  to run the whole workflow to reach the point it cares about:
  - **CP-0** — clean project, nothing started
  - **CP-1** — INTAKE complete (`project-brief.md` approved)
  - **CP-2** — PLAN complete (epics and stories approved)
  - **CP-3** — BUILD in progress (one or more stories committed)
  - **CP-4** — feature COMPLETE
- **Rollback recipes (RB-0 … RB-7)** — standard cleanup steps, each with an ID so
  tests can say exactly how they reset.

In automated tests these are loaded from fixtures, not produced by running the
real workflow — they're a speed trick, not a dependency chain.

---

## What we actually test (the surface area)

The testable surface splits into these areas. Each maps to a tier.

| # | Area | What's in it | Tier |
|---|---|---|---|
| A | **State machine** | `transition-phase.js` — the phase transitions and `--init` / `--show` / `--repair` flags | 1 |
| B | **Quality gates runner** | `quality-gates.js` — runs Gates 2–5 and reports pass/fail | 1 |
| C | **Dashboard & progress generators** | `collect-dashboard-data.js`, `generate-dashboard-html.js`, `generate-todo-list.js` | 1 |
| D | **Import & copy utilities** | `import-prototype.js`, `copy-with-header.js`, `init-preferences.js`, `scan-doc.js` | 1 |
| E | **Permission & safety hooks** | `bash-permission-checker.js`, `claude-md-permission-checker.js`, `enforce-generated-doc-names.js` | 1 |
| F | **PowerShell hooks** | `workflow-guard.ps1`, `inject-phase-context.ps1`, `inject-agent-context.ps1` (tested with Pester) | 1 |
| G | **Doc & config consistency** | Agent/command frontmatter, cross-references between `CLAUDE.md`, `README.md`, and the files on disk | 1 |
| H | **JSON schema validation** | `workflow-state.json`, `intake-manifest.json` match their schemas | 1 |
| I | **Generated-code linting** | Checks over the `web/src/` code the workflow produces (no suppressions, exact API paths, Shadcn-only imports, plain-language checklists, role fields in stories) | 1 |
| J | **Telemetry invariants** | The recorded run is well-formed and the derived reports add up | 2 |
| K | **Live behaviour** | Everything in `TEST-GUIDE.md` — the final arbiter | 3 |

---

## Tools we use

- **Vitest** — the JavaScript test runner for areas A–E, G, H, I, and J.
- **Pester** — the PowerShell test runner for the `.ps1` hooks (area F).
- **ajv** — validates JSON against a schema (area H).
- **Node `child_process`** — runs scripts as real subprocesses where the exit
  code matters (area B).

The suite is a self-contained npm workspace in `QA-TESTS/` with its own
`package.json` — carry it anywhere and run `npm install && npm test`. It reaches
the template under test through a single resolved path (`helpers/target.ts`),
defaulting to the parent repo and overridable with `REPO_ROOT=/path/to/repo`. It
installs nothing into `web/` or the repo root. When no template is found, the
template-dependent suites **skip** (a visible notice) while the
template-independent ones still run — so a standalone copy never shows a vacuous
green.

---

## How the suite is laid out

One test file per thing under test — scripts are the natural unit, and a failing
file points straight at the script that broke.

```
QA-TESTS/
├── helpers/                     Reusable test plumbing
│   ├── temp-project.ts          createTempProject() — a throwaway project per test
│   ├── checkpoint-fixtures.ts   loadCheckpoint() — start at CP-0 … CP-4
│   ├── rollback.ts              rollback() — the RB-0 … RB-7 cleanup recipes
│   ├── state-fixtures.ts        seedState() / readState() / seedArtifact()
│   ├── manifest-fixtures.ts     seedManifest() / readManifest()
│   ├── run-script.ts            runScript() — runs a .claude script, captures output + exit code
│   ├── git-sandbox.ts           gitSandbox() — git init + commit helpers
│   ├── snapshot.ts              normalise() — for stable snapshot comparisons
│   ├── index.ts                 barrel export
│   └── schemas/                 State-file schemas (workflow-state derives its phase enum from the template)
├── fixtures/                    Test inputs
│   ├── scenarios/               Team Task Manager + variants (see TEST-INPUTS.md)
│   ├── checkpoints/             CP-N tarballs (optional; synthesised if absent)
│   └── golden-telemetry/        A recorded run for Tier 2
├── tier-1-unit/
│   ├── scripts/                 One file per .claude/scripts/*.js
│   ├── hooks/                   Node hooks + PowerShell hooks (Pester)
│   ├── consistency/             Frontmatter and cross-reference checks
│   ├── schemas/                 JSON schema validation
│   └── artifact-lint/           Checks over generated web/src/ code
├── tier-2-log-replay/           Telemetry checks (folder name is historical)
│   ├── verify-session-behavior.ts   Loads the recorded run + report runner
│   └── invariants/              Ledger shape, report math, freshness canary
├── tier-3-pointer.md            Points to TEST-GUIDE.md
├── vitest.config.ts
├── package.json
└── README.md
```

> **Note on the `tier-2-log-replay/` name.** Tier 2 used to replay `.claude/logs/*.md`
> session logs. The current template doesn't write those, so Tier 2 was switched
> to read the telemetry ledger instead. The folder kept its old name to avoid
> churn — but it is a **telemetry** tier now, not a log-replay tier.

---

## Tier 1 — automated unit tests

Standard Vitest/Pester tests. They run on every change and finish in seconds. A
few areas deserve special care:

- **Permission-hook fuzzing.** `bash-permission-checker.js` decides which shell
  commands are allowed. It is security-critical, so it's tested against a large
  table of real commands plus adversarial inputs (`rm -rf /` variants, encoded
  strings, whitespace tricks). One dangerous command slipping through is the
  failure we most want to catch.
- **Doc and config drift.** The biggest rot in a template is documentation that
  no longer matches the files. So we check: every agent file has valid
  frontmatter and appears in the agents README; every `/command` mentioned in
  `CLAUDE.md` exists; every hook command in `settings.json` points at a real
  file; the agent list in the root README matches what's on disk.
- **State-machine rules.** `transition-phase.js` only accepts valid phase moves
  (INTAKE → PLAN → BUILD → COMPLETE, plus BUILD → PLAN to start the next epic),
  refuses to advance when a prerequisite artifact is missing, and `--repair`
  produces the same state if run twice.
- **JSON schema checks.** `workflow-state.json` and `intake-manifest.json` are
  validated against formal schemas, so silent shape changes are caught. The
  workflow-state schema is **single-sourced** — its set of valid phases is
  imported from the template's own `workflow-helpers.ALL_PHASES`, not copied, so
  it can't drift from the producer; the suite also validates the real JSON that
  `transition-phase.js --init` writes, not just fixtures.
- **Generated-code linting** — each rule lives as a pure function in
  `tier-1-unit/artifact-lint/linters.ts` and is tested two ways: **rule tests**
  feed it known-good and known-bad samples (deterministic, always run), and a
  **regression scan** runs the *same* rule over the real `web/src/` /
  `generated-docs/` output. The scan is **skipped (visibly)** when no generated
  output exists yet — so a clean template can't show a vacuous green. The rules:
  - No `@ts-ignore` / `@ts-expect-error` / `@ts-nocheck` / `eslint-disable`
    anywhere (matches Critical Rule §4).
  - Every UI primitive is imported from `@/components/ui/` (Shadcn), not
    hand-rolled (Rule §1).
  - API paths in the generated endpoints exactly match the OpenAPI spec — no
    guessed paths (Rule §3).
  - Every `story-*.md` has a non-empty `**Role:**` field.
  - The user-facing QA checklists contain no engineering jargon (no `tsc`,
    `ESLint`, `Gate 3`, `isLoading`, etc.) — Rule §10 / the plain-language policy.

---

## Tier 2 — telemetry invariants

This is the bridge between "each script works" and "needs a live AI." It reads a
**recorded run** of the workflow and checks the things that only make sense
across a whole session.

### How it works

1. **Record once.** A person runs the workflow end-to-end with the Team Task
   Manager answers from `TEST-INPUTS.md`. The telemetry layer writes
   `generated-docs/context/telemetry.ndjson` — an append-only list of events
   (phase entered/exited, agent started/stopped, turn ended). That file (plus a
   small metadata file) is copied into `fixtures/golden-telemetry/` as the
   committed recording.
2. **Replay automatically.** `verify-session-behavior.ts` loads the recording.
   No AI is needed at test time.
3. **Check.** Each test asserts something about the recording — that events are
   well-ordered, that every span closes, that the derived reports add up.

### What we check

- **The ledger is well-formed** — timestamps never go backwards, every
  `phase_enter` has a matching `phase_exit`, every `agent_start` has an
  `agent_stop`.
- **The reports add up** — the timing report excludes time spent waiting on the
  user; tokens are attributed to the right phase/story; the per-story rollups and
  the estimate-vs-actual variance are consistent with the events.
- **The recording isn't stale** — a canary test warns if the committed recording
  is older than the orchestrator rules or `settings.json`, which is a sign it
  needs re-recording.

### When to re-record

The recording is a committed fixture. Re-record it after any change that alters
how the workflow runs (orchestrator rules, agent prompts, settings, telemetry
hooks). Run the Tier 3 guide once and copy the fresh ledger over the old one.

---

## Tier 3 — the human walkthrough

`TEST-GUIDE.md` is the authoritative live test. A person runs the real workflow
with a real AI and confirms each behaviour. It's run before a release, and each
clean pass is a good moment to re-record the Tier 2 fixture.

`tier-3-pointer.md` in the test tree just says: see `TEST-GUIDE.md` and
`TEST-INPUTS.md`; run the suite before a release; re-record
`fixtures/golden-telemetry/` after a full pass.

---

## Useful extras worth keeping

- **Cross-platform CI.** Run Tier 1 on both Linux and Windows — path handling is
  the number-one source of flakiness.
- **Performance budgets.** Time `quality-gates.js` on a fixed project and fail if
  it runs much slower than its baseline, to catch accidental slow walks.
- **Golden-file tests.** For `import-prototype.js`, keep a canned input and assert
  the output tree matches a known-good snapshot.
- **A deliberate canary.** Keep one test that is expected to fail (and is
  skipped) — if CI ever goes green without running it, the harness is broken.
- **Test mode for hooks.** Point `CLAUDE_PROJECT_DIR` at the throwaway project so
  any hook output lands there and is cleaned up with the rest.

---

## What we deliberately don't test

- **Whether the AI writes good code.** You can't reliably unit-test "did the AI
  make the right call?" — that's a job for evaluation harnesses, not this suite.
- **The exact wording of agent prompts.** Too brittle; they change often. We
  check structure (valid frontmatter, allowed tools) instead.
- **A real AI call inside CI.** Expensive and flaky. Tier 2 replays a recording
  instead.
- **The manual Pass/Fail/Notes boxes** from `TEST-GUIDE.md` — those stay in the
  human guide. Vitest reports pass/fail for Tiers 1 and 2.

---

## What each test protects against (quick reference)

A one-line reason for each test, so a reviewer can see why it earns its place.

| Test area | What breaks if it fails |
|---|---|
| `transition-phase.js` — valid move | The state machine silently accepts an invalid phase change |
| `transition-phase.js` — missing artifact | The workflow advances even though a required artifact is missing |
| `transition-phase.js` — repair is repeatable | Re-running repair changes the state file |
| `quality-gates.js` — all pass | A passing report is reported when something actually failed |
| `quality-gates.js` — each failure | A real failure is reported as a pass |
| `bash-permission-checker.js` — deny list | A dangerous command slips past the filter |
| `bash-permission-checker.js` — fuzz | A novel adversarial command bypasses the filter |
| `claude-md-permission-checker.js` | `CLAUDE.md` is edited without the user approving it |
| `workflow-guard.ps1` | A development request isn't redirected into the workflow |
| `inject-phase-context.ps1` | After auto-compaction, the wrong phase context is restored |
| JSON schema — workflow-state | A silent shape change breaks existing state files |
| JSON schema — intake-manifest | A silent shape change breaks existing manifests |
| Consistency — agent frontmatter | An agent is added without valid frontmatter |
| Consistency — README matches disk | An agent is removed but still listed in the docs |
| Consistency — CLAUDE.md commands | A `/command` referenced in `CLAUDE.md` doesn't exist |
| Artifact lint — no suppressions | `@ts-ignore` / `eslint-disable` sneaks into generated code |
| Artifact lint — exact API paths | Generated endpoints use guessed paths instead of the spec's |
| Artifact lint — Shadcn imports | A hand-rolled component is used instead of a Shadcn primitive |
| Artifact lint — plain language | Engineering jargon leaks into a user-facing checklist |
| Artifact lint — role field | A story file is missing its `**Role:**` declaration |
| Dashboard generator — snapshot | The dashboard template changed by accident |
| `import-prototype.js` | A prototype layout stops being detected |
| `copy-with-header.js` | A file is copied without its source-traceability header |
| `init-preferences.js` | Git commit/push preferences aren't saved |
| Telemetry — ledger shape | The recording is malformed (gaps, unclosed spans, time going backwards) |
| Telemetry — report math | A derived report (timing/tokens/variance) is computed wrong |
| Telemetry — freshness canary | The committed recording is older than the rules it should reflect |
| Tier 3 — full guide | Anything the automated tiers miss |
