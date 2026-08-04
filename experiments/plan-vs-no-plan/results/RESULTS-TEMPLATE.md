# Results — `/plan` vs no `/plan` (run batch: <YYYY-MM-DD>)

> Copy this file per run-batch (e.g. `2026-08-10-pilot.md`). Record raw runs, medians, and the
> finding. This is record-only — see [../README.md](../README.md).

## Setup (controls — fill in, must match across all runs)

| Control | Value |
|---|---|
| Benchmark | `minimal-concurrent` |
| Model | `opus` |
| Template ref | <local checkout SHA / target@ref> |
| Cache warmth | <cold / warm — note per run below> |
| Arm order | <e.g. A B B A B A — interleaved> |
| Runs per arm | <n> |

## Raw runs

One row per run; timestamp links to `TestResults/<world>/<model>/<timestamp>/`.

| Arm | Timestamp | epicsBuilt | passRate | tokensTotal | USD | claudeSeconds | activeSeconds | peakMemMB | fits16GB | Cache warm? |
|---|---|--:|--:|--:|--:|--:|--:|--:|:--:|:--:|
| A build | | | | | | | | | | |
| B plan  | | | | | | | | | | |
| … | | | | | | | | | | |

> Include a run **only** if it built the same epics (`epicsBuilt` equal) at equal `passRate`.
> Note excluded/errored runs and why — don't silently drop them.

## Medians (the answer — median + min/max over the arm's runs)

| Metric | A build (median [min–max]) | B plan (median [min–max]) | Δ (B − A) |
|---|--:|--:|--:|
| **USD** *(headline cost)* | | | |
| claudeSeconds *(headline time)* | | | |
| activeSeconds (wall-clock) | | | |
| **peakMemoryUsedMB** *(resource)* | | | |
| tokensTotal *(rough proxy only)* | | | |

*Built-in quick diff (latest run each side):* `results/compare-build-vs-plan.md` (from
`New-Tier3Comparison`).

## Concurrent (arm C — separate question)

| Metric | Value |
|---|--:|
| overlapSeconds | |
| plannerActiveSeconds | |
| **overlap ratio** (overlap / planner active) | |

## Finding

- **Cost:** <e.g. "/plan cost ~X% more USD / roughly equal; token proxy said Y but cache-corrected USD said Z">
- **Speed (concurrent):** <e.g. "overlap ratio ~0.7 — planning was mostly hidden behind the build">
- **Peak memory:** <e.g. "build/plan ~18 GB; concurrent peaked ~24 GB — did NOT fit 16 GB in 2/3 runs">
- **n / confidence:** <pilot n=…; difference was inside/outside the run-to-run spread>
- **Verdict:** <what this batch legitimately shows — and what it does not>
- **Caveats hit:** <cache warmth, variance, any control that slipped>
