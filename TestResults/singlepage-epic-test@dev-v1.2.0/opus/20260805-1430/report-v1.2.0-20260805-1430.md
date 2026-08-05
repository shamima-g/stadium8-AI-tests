# Tier 3 report — 20260805-1430

A plain-language summary of the automated Tier 3 run for the **singlepage-epic-test** app.

## The run

| | |
|---|---|
| Result | ✅ Passed |
| App (benchmark) | singlepage-epic-test |
| AI model | opus |
| Template | dev-v1.2.0 |
| Repository | https://github.com/stadium-software/stadium-8 |
| Branch / ref | v1.2.0 |
| Version tested | v1.2.0 |
| Epics created | 1 |
| Epics built | ✅ 1 of 1 (100%) |
| Stories created | 3 |
| Run by | ShamimaGukhool on SHAMIMA-NB |
| When | 20260805-1430 |
| Command | `./Run-QATests.ps1 -IncludeTier3 -Benchmark singlepage-epic-test -Tier3Model opus -Target dev -Ref v1.2.0` |
| Built at | `C:\temp\tier3-builds\singlepage-epic-test@dev-v1.2.0\opus\20260805-1430` |
| Active time | 60m 59s |
| Claude's own time | 60m 59s |
| Paused / excluded | 0s |
| Memory the run added | 3.1 GB (whole-machine peak 16.9 GB) |
| Fits in 16 GB? | ✅ yes |
| Total AI tokens | 139,054 |
| Tier 3 verdict | ✅ met the rules |
| Build pass-rate | 100% |

## Memory (minimum RAM)

**The run itself added about 3.1 GB of memory.** (Whole-machine use peaked at 16.9 GB, but the machine was already using 13.8 GB before the run started — so the run's own footprint is the difference, ~3.1 GB. Least free at any moment: 14.8 GB, on a machine with 31.7 GB.)

**A 16 GB machine should cope.** Allowing ~4 GB for a lean VM's own operating system plus the ~3.1 GB this run added comes to about **7.1 GB** — comfortably under 16 GB.

> How to read this: the headline is the **added** memory, not the whole-machine peak — the peak is inflated by everything else that happened to be running here. The 16 GB verdict assumes a lean VM uses ~4 GB for its OS. To be 100% certain, run once on an actual 16 GB VM; this is the evidence toward that.

## How each group of tests did

| Group | Tests | Passed | Failed | Skipped | Time | Tokens |
|---|--:|--:|--:|--:|--:|--:|
| Project & workflow checks (Tier 1) | 163 | 89 | 0 | 74 | 2.7s | — |
| Recorded run (Tier 2) | 14 | 2 | 0 | 12 | 0s | — |

## 2.1 Build attempts

| Attempt | Result | Compiled? | Tokens | Turns | Reason |
|--:|---|:--:|--:|--:|---|
| 1 | passed | yes | 139,054 | 451 | built and passed all rules |

## 2.2 Where the time went (estimate vs actual)

| Phase | Estimated | Actual | Difference | Claude time |
|---|--:|--:|--:|--:|
| opus/build | — | 60m 59s | — | 60m 59s |
| opus/build/spec | — | 1m 30s | — | 1m 14s |
| opus/build/save | — | 16m 32s | — | 12m 8s |
| opus/build/green | — | 24m 29s | — | 19m 42s |
| opus/build/red | — | 18m 21s | — | 27m 54s |

## Epics — time to build each one

This run created **1** epic and **3** stories in total. The estimate for each epic is its average build time on past runs of this app + model (a dash means no history yet).

| Epic | Stories | Estimated | Actual | Difference |
|---|--:|--:|--:|--:|
| task-dashboard | 3 | — | 53m 9s | — |

## Tools on record

- node v24.11.0
- npm 11.6.1
- claude 2.0.69 (Claude Code)
- pwsh 7.6.3

