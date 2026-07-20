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
npm run test:raw     # just the tests, no report
npm run test:tier1   # the fast unit tests only
```

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

## Test a live AI run against an example app

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

```bash
QA_TARGET=dev npm run reconcile          # update the dev contract to match a dev checkout
QA_TARGET=release npm run reconcile      # same, for release
npm run reconcile:check                  # report drift without writing changes
```

## Good to know

- **Safe to run anywhere.** With no template nearby, template-specific checks skip
  (with a notice) instead of failing — you'll never see a fake "all green".
- **Windows + PowerShell tests.** The PowerShell hook tests need Pester 5 once:
  `pwsh -Command "Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.0"`, then `npm run test:pester`.

## Learn more

**[workflow-tests.md](workflow-tests.md) is the full guide** — how the tests are
organised (the three tiers), what each one checks, testing any template/version,
keeping tests current, and how to add one. Start there.

To understand how a given template *version's* workflow behaves, read that template's
own docs: `<template>/.claude/WORKFLOWS.md` and `<template>/.template-docs/`.
