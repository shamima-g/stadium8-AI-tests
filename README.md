# AI-tests — tests for the Stadium 8 workflow template

This suite checks the **template itself** — the scripts, hooks, state files, and
agent/command definitions under `.claude/` that make the workflow run. It does *not*
test an app someone builds with the template. Think of it as a safety net around the
workflow's own plumbing.

## Quick start

```bash
npm install
npm test          # runs the checks, writes a report to TestResults/, opens it
```

That's it. `npm test` exits non-zero if anything needs attention.

Handy variations:

```bash
npm run test:raw        # just the tests, no report
npm run test:watch      # re-run tests as files change
npm run test:tier1      # the fast unit tests only (tier-1-unit)
npm run test:tier2      # invariants over the recorded run (tier-2-recorded-run)
npm run test:pester     # the PowerShell hook tests (tier-1-unit/hooks/powershell)
npm run test:tier3-unit # the Tier 3 runner's own unit tests (see Tier 3 below)
npm run test:report     # generate the report only
npm run compare         # diff the latest report against the previous one
```

### All the commands at a glance

| Command | What it runs |
|---|---|
| `npm test` | Template checks → report (exits non-zero on failure). |
| `npm run test:raw` | Just the tests (vitest), no report. |
| `npm run test:watch` | Tests in watch mode. |
| `npm run test:tier1` | Tier 1 — fast unit tests. |
| `npm run test:tier2` | Tier 2 — invariants over a recorded run. |
| `npm run test:pester` | Tier 1 — PowerShell hook tests (Pester 5). |
| `npm run test:tier3-unit` | Tier 3 — the runner's own unit tests (Pester 5). |
| `npm run test:full` | Everything (template + web + e2e + gates). |
| `npm run test:report` | Generate the report only. |
| `npm run compare` | Diff the latest report vs the previous one. |
| `npm run project-report` | Generate the report, then compare. |
| `npm run test:target` | Aim the suite at a specific template/version (see below). |
| `npm run compare:targets` | Static template-shape diff between two versions. |
| `Run-QATests.ps1 -IncludeTier3` | Tier 3 — the live AI build (from `tier-3-automated/`). |
| `Compare-Tier3-Reports.ps1` | Diff two Tier 3 live runs (from `tier-3-automated/`). |

## Heavier checks

By default `npm test` runs only the template checks and reuses the last saved
result for the slower surfaces (the report says how old each one is). To actually
re-run those surfaces, use `test:full` or the individual flags:

```bash
npm run test:full    # everything below, in one go
```

`test:full` is shorthand for these flags on `generate-test-report.cjs`:

| Flag | What it runs |
|---|---|
| `--with-web` | the app's own unit + integration tests in `web/` |
| `--with-e2e` | the Playwright click-through tests in `web/` |
| `--with-gates` | the final quality gates (security, code style & build, tests, speed) |

Other flags the report script accepts: `--exit-code` (exit non-zero on failure — on
by default in `npm test`), `--no-open` (don't pop the report open), and `--out <path>`
(write to a specific file).

## Tier 3

Tier 3 has two parts:

- **Unit tests** for the Tier 3 runner's own scripts (fast, no AI). Run them with:

  ```bash
  npm run test:tier3-unit
  ```

  Equivalent raw command (needs Pester 5 — see "Good to know"):

  ```powershell
  pwsh -NoProfile -Command "Import-Module Pester -MinimumVersion 5.0 -Force; Invoke-Pester tier-3-automated/tests -Output Detailed"
  ```

- **The live AI build** — the whole workflow driven by a real AI (below).

### Test a live AI run against an example app

Tier 3 runs the **whole workflow with a real AI** against an example app under
`benchmark-files/`, then times and scores it. You choose which app (benchmark set)
to build with `-Benchmark`:

```powershell
# From tier-3-automated/ (PowerShell 7):
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions
```

`-Benchmark <name>` is the folder name under `benchmark-files/` (today the only set is
`transactions`). The choices aren't hard-wired — the runner offers each folder it
finds, so adding a new app is just dropping in a new folder (plus its `answers.json`).
Name one that doesn't exist and the run stops and lists the valid options. Results land
in that set's own folder under `TestResults/<benchmark>/`, never mixed across apps.

By default the run drives a straight build. Add `-Scenario` to exercise the `/plan`
park-ahead command instead — `plan` (PLAN-A) plans and parks epics in a single session,
`concurrent` (PLAN-B) runs two live sessions at once (one building, one planning) against a
shared remote. Each files its results separately (`TestResults/<benchmark>-plan/`,
`…-concurrent/`). See [tier-3-automated/README.md](tier-3-automated/README.md) for the full
scenario details.

### Compare release vs dev builds

By default Tier 3 builds against the template the suite is nested in. To build against a
specific channel and version instead, add `-Target` (`dev` or `release`, from
`targets.json`) and `-Ref` (a tag/branch). Each target's results are kept in their own
`TestResults/<benchmark>@<target>-<ref>/` folder, so you can build the same app under
both and compare the two reports:

```powershell
# release = Digiata/Stadium-Builder
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions -Target release -Ref v1.1.0

# dev = stadium-software/stadium-8
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions -Target dev     -Ref v1.1.0
```

Then diff the two runs automatically (result, times, tokens, pass-rate, rules missed,
peak memory):

```powershell
./Compare-Tier3-Reports.ps1 -Benchmark transactions -A release -ARef v1.1.0 -B dev -BRef v1.1.0
```

(This is the live-build counterpart to `test:target`; for a static template-shape diff
without building, use `compare:targets` above.)

See [tier-3-automated/README.md](tier-3-automated/README.md) for the model picker and
the other options.

## Test a specific template and version

By default the suite tests the template in the parent folder. To point it at a
specific one (dev or release) at a specific version, it downloads that version and
aims itself at it:

```bash
npm run test:target -- --target dev --ref v1.1.0
```

Results are filed under `TestResults/dev-v1.1.0/`, so you can compare versions side by
side. To check whether dev is safe to promote to release:

```bash
npm run compare:targets -- --a release --a-ref v1.0.0 --b dev --b-ref v1.1.0
```

### Keeping a target's contract current (`reconcile`)

Each target is judged against its **own** recipe — `template-contract.dev.json` for
dev, `template-contract.release.json` for release. Both start pinned to the same
baseline (currently `v1.1.0`). When one template moves ahead — e.g. dev's `main`
advances past its last tag — its contract needs updating so it's judged against its
own shape, not the old baseline. Point `reconcile` at that target to see (and apply)
what changed:


## Good to know

- **Safe to run anywhere.** With no template nearby, template-specific checks skip
  (with a notice) instead of failing — you'll never see a fake "all green".
- **Windows + PowerShell tests.** The PowerShell hook tests need Pester 5 once:
  `pwsh -Command "Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.0"`, then `npm run test:pester`.

## Experiments

Separate from the pass/fail tiers, [experiments/](experiments/) holds **measurement
studies** — open-ended runs that *measure and compare* how the workflow behaves (token
cost, wall-clock time, peak memory, the value of one path vs another). They're
record-only: they never gate a run or turn it red. See
[experiments/README.md](experiments/README.md) for the index and conventions.

Today's experiment is [`plan-vs-no-plan`](experiments/plan-vs-no-plan/) — the token,
time & peak-memory cost of using `/plan`. From its folder (`experiments/plan-vs-no-plan/`,
PowerShell 7):

```powershell
# Pilot: 3 runs each of build vs plan, default model (opus), local template
./Run-Experiment.ps1

# Flexible — benchmark, model, template channel+version, arms, runs/arm:
./Run-Experiment.ps1 -Benchmark transactions -Model sonnet -Target dev -Ref v1.2.0 `
  -Arms build,plan,concurrent -Runs 5

# Re-generate the report from runs already recorded, without launching anything:
./Run-Experiment.ps1 -SkipRuns -Runs 5
```

Run the experiment runner's own unit tests (from `AI-tests/`, PowerShell 7 + Pester 5):

```powershell
Invoke-Pester experiments/plan-vs-no-plan/tests
```

## Learn more

**[workflow-tests.md](workflow-tests.md) is the full guide** — how the tests are
organised (the three tiers), what each one checks, testing any template/version,
keeping tests current, and how to add one. Start there.

To understand how a given template *version's* workflow behaves, read that template's
own docs: `<template>/.claude/WORKFLOWS.md` and `<template>/.template-docs/`.
