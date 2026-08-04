# Experiment: `/plan` vs no `/plan` — token, time & peak-memory cost

**Question.** When you use `/plan` to plan an epic ahead, what does it cost in tokens/USD, does it
buy back any wall-clock time, and what does it do to **peak memory** — versus building the same app
without it?

This is a **measurement study, not a test** ([../README.md](../README.md)) — record-only, never a
pass/fail. **Read [ABOUT.md](ABOUT.md) for the full explanation of the experiment and the tests it
carries out.** This page is how to *run* it.

---

## Prerequisites

- **A benchmark that decomposes into ≥ 2 epics** so the `plan` arm builds the *same* app as `build`
  (the deliberately minimal `minimal-concurrent` set — 2 tiny epics — is the intended default).
  Don't use a big benchmark: the arms would build different work and every number is meaningless.
- **PowerShell 7**, the **Claude CLI signed in** (live runs), and **Git** on PATH (the `concurrent`
  arm needs a shared remote). Same setup as the Tier-3 harness.

---

## How to run it

From this folder:

```powershell
# Pilot: 3 runs each of build vs plan, default model (opus), local template
./Run-Experiment.ps1

# Everything is flexible — benchmark, model, template channel+version, arms, runs/arm:
./Run-Experiment.ps1 -Benchmark transactions -Model sonnet -Target dev -Ref v1.2.0 `
  -Arms build,plan,concurrent -Runs 5

# Re-generate the report from runs already recorded, without launching anything:
./Run-Experiment.ps1 -SkipRuns -Runs 5
```

### Parameters

| Parameter | Default | What it does |
|---|---|---|
| `-Benchmark <name>` | `minimal-concurrent` | Which example app to build (folder under `benchmark-files/`). |
| `-Model <name>` | `opus` | The AI model, held constant across all arms. |
| `-Target <dev\|release>` | — | Build against a template channel from `targets.json` instead of the local checkout. |
| `-Ref <tag\|branch>` | — | The template version to use with `-Target` (e.g. `v1.2.0`). |
| `-Arms build,plan[,concurrent]` | `build,plan` | Which scenarios to compare. The **first** arm is the baseline for deltas. |
| `-Runs <n>` | `3` | Pilot runs **per arm**. Reported as median [min–max]; raise it if the delta sits inside the spread. |
| `-SkipRuns` | off | Don't launch runs — just aggregate history already recorded and (re)write the report. |
| `-NoInterleave` | off | Run all of one arm then the next, instead of interleaving (A B B A …). Interleaving is the default and counterbalances calendar drift. |
| `-RunLowerTiers` | off | Also run Tier 1 + Tier 2 each run. Off by default — the study is about the Tier-3 scenario cost. |

Every live run is a full Tier-3 build, so a batch of `-Runs 3 -Arms build,plan` is **6 real AI
builds** — use the cheap `minimal-concurrent` bench to keep it affordable.

---

## Outputs

- **Raw runs** land in the harness's own worlds (unchanged): `TestResults/<benchmark>` (build),
  `TestResults/<benchmark>-plan`, `TestResults/<benchmark>-concurrent` — each with its
  `tier3-history.jsonl`, per-run report, and app zip.
- **This experiment's report** lands in [results/](results/):
  - `plan-experiment-<benchmark>-<timestamp>.md` — the aggregate comparison: median [min–max] per
    arm for tokens, Claude time, wall-clock, **peak memory / fits-16 GB**, plus baseline→arm deltas
    and the raw per-run rows.
  - `quickdiff-<baseline>-vs-<arm>-<timestamp>.md` — the harness's own `New-Tier3Comparison`
    latest-run diff, for cross-check.
  - Record your written finding in a copy of [results/RESULTS-TEMPLATE.md](results/RESULTS-TEMPLATE.md).

---

## How to read the report

- **Two axes, separately:** cost (tokens/USD) vs speed (wall-clock). `/plan` may raise tokens while
  lowering wall-clock — don't collapse them.
- **`Tokens (proxy)` is rough** — it counts cheap cache-reads at par with fresh input, so it
  *overstates* `/plan`. For the true cost figure use USD / the `workflow-insights` cache-split.
- **Peak memory:** watch whether `concurrent` (two live sessions) pushes peak RAM up and whether it
  still fits 16 GB — that's the resource question this experiment adds.
- **Small n:** a delta inside the [min–max] band means "no measurable difference", not a result.
- Full interpretation rules and what the numbers can/can't prove: **[ABOUT.md](ABOUT.md) §7**.

---

## Files in this folder

| Path | What it is |
|---|---|
| [ABOUT.md](ABOUT.md) | The experiment and its tests, explained in full. |
| `README.md` | This page — how to run it. |
| `Run-Experiment.ps1` | The flexible runner + comparison-report generator. |
| [results/](results/) | This experiment's reports + findings (raw runs stay in `TestResults/`). |
| [tests/Run-Experiment.Tests.ps1](tests/Run-Experiment.Tests.ps1) | Pester good/broken tests for the runner's pure functions. |

Run the unit tests: `Invoke-Pester experiments/plan-vs-no-plan/tests` (from `AI-tests/`, PowerShell 7 + Pester 5).
