# Tier 3 report — 20260814-1000

A plain-language summary of the automated Tier 3 run for the **feedback-api-design** app.

## The run

| | |
|---|---|
| Result | ✅ Passed |
| App (benchmark) | feedback-api-design |
| AI model | opus |
| Template | release-v1.3.0 |
| Repository | https://github.com/Digiata/Stadium-Builder |
| Branch / ref | v1.3.0 |
| Version tested | v1.3.0 |
| Epics created | 1 |
| Epics built | ✅ 1 of 1 (100%) |
| Stories created | 1 |
| Run by | ShamimaGukhool on SHAMIMA-NB |
| When | 20260814-1000 |
| Command | `./Run-QATests.ps1 -IncludeTier3 -Benchmark feedback-api-design -Tier3Model opus -Target release -Ref v1.3.0` |
| Built at | `C:\temp\tier3-builds\feedback-api-design@release-v1.3.0\opus\20260814-1000` |
| Active time | 46m 14s |
| Claude's own time | 46m 14s |
| Paused / excluded | 0s |
| Memory the run added | 2.7 GB (whole-machine peak 16.7 GB) |
| Fits in 16 GB? | ✅ yes |
| Total AI tokens | 103,535 |
| Tier 3 verdict | ✅ met the rules |
| Build pass-rate | 100% |

## Memory (minimum RAM)

**The run itself added about 2.7 GB of memory.** (Whole-machine use peaked at 16.7 GB, but the machine was already using 14 GB before the run started — so the run's own footprint is the difference, ~2.7 GB. Least free at any moment: 15 GB, on a machine with 31.7 GB.)

**A 16 GB machine should cope.** Allowing ~4 GB for a lean VM's own operating system plus the ~2.7 GB this run added comes to about **6.7 GB** — comfortably under 16 GB.

> How to read this: the headline is the **added** memory, not the whole-machine peak — the peak is inflated by everything else that happened to be running here. The 16 GB verdict assumes a lean VM uses ~4 GB for its OS. To be 100% certain, run once on an actual 16 GB VM; this is the evidence toward that.

## How each group of tests did

| Group | Tests | Passed | Failed | Skipped | Time | Tokens |
|---|--:|--:|--:|--:|--:|--:|
| Project & workflow checks (Tier 1) | 190 | 105 | 0 | 85 | 1.7s | — |
| Recorded run (Tier 2) | 14 | 14 | 0 | 0 | 1.3s | — |

## 2.1 Build attempts

| Attempt | Result | Compiled? | Tokens | Turns | Reason |
|--:|---|:--:|--:|--:|---|
| 1 | passed | yes | 103,535 | 276 | built and passed all rules |

## 2.2 Where the time went (estimate vs actual)

| Phase | Estimated | Actual | Difference | Claude time |
|---|--:|--:|--:|--:|
| opus/build | — | 46m 14s | — | 46m 14s |
| opus/build/spec | — | 10m 43s | — | 12m 33s |
| opus/build/save | — | 13m 25s | — | 7m 9s |
| opus/build/green | — | 13m 22s | — | 17m 0s |
| opus/build/red | — | 8m 33s | — | 9m 31s |

## Epics — time to build each one

This run created **1** epic and **1** story in total. The estimate for each epic is its average build time on past runs of this app + model (a dash means no history yet).

| Epic | Stories | Estimated | Actual | Difference |
|---|--:|--:|--:|--:|
| feedback-wall | 1 | — | 34m 7s | — |

## Tools on record

- node v24.11.0
- npm 11.6.1
- claude 2.0.69 (Claude Code)
- pwsh 7.6.3

