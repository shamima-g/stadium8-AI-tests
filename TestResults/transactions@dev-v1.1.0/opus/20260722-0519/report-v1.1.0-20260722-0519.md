# Tier 3 report — 20260722-0519

A plain-language summary of the automated Tier 3 run for the **transactions** app.

## The run

| | |
|---|---|
| Result | ✅ Passed |
| App (benchmark) | transactions |
| AI model | opus |
| Template | dev-v1.1.0 |
| Version tested | v1.1.0 |
| Epics created | 7 |
| Stories created | 18 |
| Run by | User on WINDEV2407EVAL |
| When | 20260722-0519 |
| Active time | 385m 25s |
| Estimated active time | 183m 25s (this run +201m 60s vs estimate) |
| Claude's own time | 385m 24s |
| Estimated Claude time | 132m 2s |
| Paused / excluded | 0s |
| Memory the run added | 3 GB (whole-machine peak 9.7 GB) |
| Fits in 16 GB? | ✅ yes |
| Total AI tokens | 842,165 |
| Tier 3 verdict | ⚠️ fell short (recorded, not failed) |
| Build pass-rate | 0% |

## Memory (minimum RAM)

**The run itself added about 3 GB of memory.** (Whole-machine use peaked at 9.7 GB, but the machine was already using 6.7 GB before the run started — so the run's own footprint is the difference, ~3 GB. Least free at any moment: 3.5 GB, on a machine with 10.8 GB.)

**A 16 GB machine should cope.** Allowing ~4 GB for a lean VM's own operating system plus the ~3 GB this run added comes to about **7 GB** — comfortably under 16 GB.

> How to read this: the headline is the **added** memory, not the whole-machine peak — the peak is inflated by everything else that happened to be running here. The 16 GB verdict assumes a lean VM uses ~4 GB for its OS. To be 100% certain, run once on an actual 16 GB VM; this is the evidence toward that.

## How each group of tests did

| Group | Tests | Passed | Failed | Skipped | Time | Tokens |
|---|--:|--:|--:|--:|--:|--:|
| Project & workflow checks (Tier 1) | 145 | 77 | 0 | 68 | 0.4s | — |
| Recorded run (Tier 2) | 9 | 2 | 0 | 7 | 0s | — |

## 2.1 Build attempts

| Attempt | Result | Compiled? | Tokens | Turns | Reason |
|--:|---|:--:|--:|--:|---|
| 1 | non-conforming | yes | 842,165 | 5084 | built, but missed: role-per-story |

## 2.2 Where the time went (estimate vs actual)

| Phase | Estimated | Actual | Difference | Claude time |
|---|--:|--:|--:|--:|
| opus/build | 183m 25s | 385m 24s | +201m 60s | 385m 24s |
| opus/build/spec | 9m 48s | 9m 6s | -41.9s | 5m 46s |
| opus/build/save | 60m 16s | 125m 40s | +65m 24s | 66m 41s |
| opus/build/green | 94m 59s | 196m 41s | +101m 43s | 262m 43s |
| opus/build/red | 18m 14s | 53m 45s | +35m 31s | 50m 14s |

## Epics — time to build each one

This run created **7** epics and **18** stories in total. The estimate for each epic is its average build time on past runs of this app + model (a dash means no history yet).

| Epic | Stories | Estimated | Actual | Difference |
|---|--:|--:|--:|--:|
| file-log-dashboard | 3 | 47m 24s | 50m 1s | +2m 37s |
| file-upload-lifecycle | 3 | 0s | 51m 33s | +51m 33s |
| foundation-auth-shell | 5 | — | 130m 32s | — |
| transaction-actions | 2 | — | 47m 58s | — |
| transaction-export | 1 | — | 24m 13s | — |
| transactions-search-filter | 2 | — | 30m 49s | — |
| transactions-table | 2 | — | 31m 38s | — |

## Tools on record

- node v24.16.0
- npm 11.13.0
- claude 2.1.195 (Claude Code)
- pwsh 7.6.3

## 3.1 What needs attention, and how to fix it

**Tier 3 rule not met: role-per-story**

- Possible fix: Add a non-empty role line to the story file.

**Build attempt 1: non-conforming**

- Possible fix: built, but missed: role-per-story

