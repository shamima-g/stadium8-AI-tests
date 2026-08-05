# Experiment report — /plan vs no /plan

**Benchmark:** `minimal-concurrent` · **Model:** `opus` · **Template:** dev @ main
**Arms:** build, plan · **Runs/arm:** 2 · **Order:** interleaved (A B B A …) · **Generated:** 20260805-093851
**Repository:** https://github.com/stadium-software/stadium-8 · **Branch/ref:** main · **Version tested:** dev @ main
**Built under:** `C:\temp\tier3-builds`
**Command:** `./Run-Experiment.ps1 -Benchmark minimal-concurrent -Model opus -Target dev -Ref main -Arms build,plan -Runs 2 -SkipRuns`

> Measurement study — record-only, never a pass/fail. Read the two axes separately (cost vs speed)
> and treat `Tokens (proxy)` as a rough figure only (it counts cheap cache-reads at par); see Notes.

## Aggregate — median [min–max] per arm

| Metric | build | plan |
|---|--:|--:|
| Tokens (proxy) (lower better) | 95,632 | 191,445 [180,263–202,627] |
| Claude's own time (lower better) | 58m 56s | 106m 45s [92m 20s–121m 10s] |
| Wall-clock (lower better) | 58m 57s | 106m 45s [92m 20s–121m 10s] |
| Peak memory (lower better) | 16,0 GB | 14,8 GB [14,7 GB–15,0 GB] |
| Pass-rate (higher better) | 0% | 0% [0%–0%] |
| Epics built | 2 | 4 [3–4] |

## Δ vs baseline (`build`) — median difference

| Metric | Δ plan |
|---|--:|
| Tokens (proxy) | +95,813 |
| Claude's own time | +47m 49s |
| Wall-clock | +47m 48s |
| Peak memory | -1,2 GB |
| Pass-rate | +0pp |

## Peak memory (resource axis)

Peak whole-system RAM while the run worked (the harness's memory sampler). A `concurrent`
arm runs **two Claude sessions at once**, so expect its peak to sit *above* the single-session arms —
this answers "does planning-while-building blow the RAM budget?".

| Arm | Peak memory (median [min–max]) | Fits 16 GB? (runs) |
|---|--:|:--:|
| build | 16,0 GB | 1 / 1 |
| plan | 14,8 GB [14,7 GB–15,0 GB] | 2 / 2 |

## Raw runs (this batch)

### build
| Timestamp | epicsBuilt | passRate | tokens | Claude time | wall-clock | peak mem | fits 16 GB |
|---|--:|--:|--:|--:|--:|--:|:--:|
| 20260804-095721 | 2 | 0% | 95,632 | 58m 56s | 58m 57s | 16,0 GB | yes |

### plan
| Timestamp | epicsBuilt | passRate | tokens | Claude time | wall-clock | peak mem | fits 16 GB |
|---|--:|--:|--:|--:|--:|--:|:--:|
| 20260804-105807 | 3 | 0% | 202,627 | 92m 20s | 92m 20s | 14,7 GB | yes |
| 20260804-123157 | 4 | 0% | 180,263 | 121m 10s | 121m 10s | 15,0 GB | yes |

## Notes / guardrails

- **Cost ≠ Tokens (proxy).** `tokensTotal` sums cache-reads at par with fresh input, so it overstates
  /plan's cost. For a real cost figure use USD / the cache-split from the `workflow-insights` skill.
- **Same-deliverable only.** Compare arms only when `epicsBuilt` matches (a 2-epic benchmark makes
  `plan` build the same app as `build`). Different epic counts ⇒ the token/time delta is meaningless.
- **`concurrent` double-counts tokens** (two sessions re-read context) and its wall-clock is the *union*
  of two overlapping sessions — read its `overlapSeconds` from the run's tier3 block, don't sum it in.
- **Small n.** With a few runs the spread often swamps the difference; treat a delta inside the
  [min–max] band as "no measurable difference", not a result.
