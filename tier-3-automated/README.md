# Tier 3 — automated live test (get started)

This runs the **whole workflow with a real AI**, by itself, against an example app —
then times it, scores it, and writes up a report. No person needs to sit and watch.

New here? The full design is in **[PLAN.md](PLAN.md)**. This page is just the
quick start. For the **whole test-suite** (all three tiers) start at the
[suite README](../README.md).

---

## Before you start

You need the **Claude command-line tool installed and signed in**. Everything else
(Node, PowerShell bits, test tools, browsers) is installed for you the first time you
run — see "What setup installs" below.

---

## Run it

Open PowerShell 7 in this folder and run:

```powershell
# Simplest — default AI model (opus), default example app:
./Run-QATests.ps1 -IncludeTier3

# Choose the AI model:
./Run-QATests.ps1 -IncludeTier3 -Tier3Model sonnet

# Choose which example app to build:
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions

# Build against a specific template channel + version (dev or release):
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions -Target release -Ref v1.1.0

# Exercise /plan (park an epic ahead, then build it) instead of a straight build:
./Run-QATests.ps1 -IncludeTier3 -Scenario plan

# Exercise concurrent build-while-planning (two live sessions at once, shared remote):
./Run-QATests.ps1 -IncludeTier3 -Scenario concurrent
```

**Scenarios.** `-Scenario build` (default) drives the straight `/start` → `/continue`
build. `-Scenario plan` runs **PLAN-A**: it builds the first epic, then uses `/plan` to plan
and **park** the next epics ready to build (one outlined at setup, one brand-new, one that
depends on an unbuilt epic), then builds a parked epic to prove it resumes straight into
BUILD. `-Scenario concurrent` runs **PLAN-B**: it stands up a shared bare remote, bootstraps
the first epic, then runs **two live sessions at the same time** — one building the next epic,
one `/plan`-ning the epic after — and checks they don't disturb each other and that `main`
stays consistent. Each scenario scores its live behaviours into `rulesMissed` — recorded,
never gating, exactly like the build-conformance rules — and is filed in its own results world
(`TestResults/<app>-plan/`, `TestResults/<app>-concurrent/`) so scenario metrics never mix with
a straight build's.

> **PLAN-B is the heavy one.** Two concurrent live sessions plus a bootstrap build ≈ three epic
> builds of AI time, and it needs Git on PATH for the shared remote. Reach for it when you
> specifically want the concurrency + shared-`main` guarantees; PLAN-A covers the rest cheaply.

It runs in the background — you get your machine back while it works. If the PC is
switched off partway, just run the same command again and it carries on from where it
stopped.

---

## Where the results go

Everything is kept **separated per example app**, newest run at the top:

```
TestResults/<app>/
├── index.md              the list of runs (last 10 per AI model)
├── tier3-metrics.html    charts — open in a browser
└── <model>/<time>/       one run: the report, the timing, and a zip of the built app
```

The app the AI built is left on disk **outside the test suite**, under
`C:\temp\tier3-builds\<app>\<model>\<time>\` (overridable with `-BuildRoot`), so you
can open and run it. A zipped snapshot is also kept in the run's results folder above.

**Kept lean automatically.** After each run the raw AI stream log is gzipped (~7 MB →
~1.8 MB; use `-KeepRawLogs` to keep it raw), and the built app's `node_modules`/build
caches are stripped and its git repo compacted (`git gc`, history preserved). For the
smallest footprint, `-Cleanup` removes the working folder entirely — the zipped snapshot
still survives.

**Targeted runs stay separate.** With `-Target`, results are filed under
`TestResults/<app>@<target>-<ref>/` — its own history and charts — so a release build and
a dev build of the same app never mix. To compare how the app builds under each, run it
once per target and read the two report folders side by side:

```powershell
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions -Target release -Ref v1.1.0
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions -Target dev     -Ref v1.1.0
# → TestResults/transactions@release-v1.1.0/  vs  TestResults/transactions@dev-v1.1.0/
```

Then diff the two automatically — result, times, tokens, pass-rate, rules missed, and
peak memory, with the delta for each:

```powershell
./Compare-Tier3-Reports.ps1 -Benchmark transactions -A release -ARef v1.1.0 -B dev -BRef v1.1.0
# → TestResults/compare-tier3-transactions@release-v1.1.0--vs--transactions@dev-v1.1.0.md
```

It reads the latest run from each side's history (pass `-Model` to compare like-for-like)
and writes a markdown table — read-only, no build, no AI.

---

## What the report shows

Each run's `report-<version>-<time>.md` covers, in plain language: the result and verdict,
the AI model and template/version, how long it took (**actual next to an estimate** — both
whole-run and per phase), tokens and memory, and a plain-English fix list for anything flagged.

It also breaks the work down **by epic**:

- **Epics created** and **stories created** — headline counts in the run summary.
- **Time to build each epic** — a per-epic table of **estimated vs actual** time (and the
  difference). Actual comes from the built app's git history (first→last commit for that
  epic); the estimate is that epic's average over past runs (a dash until there's history).

The **charts page** (`tier3-metrics.html`, open in a browser) shows the same epic data as a
**bar chart** — actual time this run vs the average across recorded runs, one bar-pair per
epic — alongside the time-taken, most-flagged-rules, and last-10-per-model charts.

---

## Handy options

| Option | What it does |
|---|---|
| `-IncludeTier3` | Turn the live AI run on (off by default). |
| `-Tier3Model <name>` | Pick the AI model (e.g. `opus`, `sonnet`). Default: `opus`. |
| `-Benchmark <name>` | Pick which example app to build. Default: the only one there. |
| `-Scenario <name>` | `build` (default) — straight build; `plan` — PLAN-A `/plan` park-ahead; `concurrent` — PLAN-B two-session build-while-planning (see above). |
| `-Target <name>` | Build against a template channel from `targets.json` (`dev` or `release`) instead of the local one. Clones it into `.targets/`. |
| `-Ref <tag\|branch>` | The version to build against with `-Target` (e.g. `v1.1.0`). Default: the repo's default branch. |
| `-BuildRoot <path>` | Where the app is built. Default: `C:\temp\tier3-builds` (outside the suite). |
| `-KeepDeps` | Keep the app instantly runnable (don't strip `node_modules`). |
| `-KeepRawLogs` | Keep the raw AI stream log uncompressed. By default it's gzipped after the run (~7 MB → ~1.8 MB). |
| `-NoTeardown` | Clean up nothing — leave everything exactly as it was. |
| `-Cleanup` | Clean up the most — remove the working folder (the zip is still kept). |

Drop a file named **`PAUSE`** into a run's `tier3-live/` folder to freeze its clock;
delete it to carry on.

---

## What setup installs (first run)

Setup checks what's already on your machine and installs only what's missing — the
test tools, the app's parts, the PowerShell test module, and the click-through
browsers. If something essential can't be installed on its own, it stops and tells you
in plain English what to install. It never changes your sign-ins.

---

## The score never fails the run

The AI's work is scored and written into the report and history, but a poor score
**never** turns the run red — it's recorded for you to read, not used as a gate.
