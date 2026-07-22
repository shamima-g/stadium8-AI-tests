# Tier 3 report — 20260722-0311

A plain-language summary of the automated Tier 3 run for the **transactions** app.

## The run

| | |
|---|---|
| Result | ✅ Passed |
| App (benchmark) | transactions |
| AI model | opus |
| Template | dev-v1.1.0 |
| Version tested | v1.1.0 |
| Epics created | 5 |
| Stories created | 5 |
| Run by | User on WINDEV2407EVAL |
| When | 20260722-0311 |
| Active time | 55m 38s |
| Estimated active time | 247m 18s (this run -191m 39s vs estimate) |
| Claude's own time | 22m 37s |
| Estimated Claude time | 186m 44s |
| Paused / excluded | 0s |
| Memory the run added | 1.6 GB (whole-machine peak 7.9 GB) |
| Fits in 16 GB? | ✅ yes |
| Total AI tokens | 17,360,877 |
| Tier 3 verdict | ⚠️ fell short (recorded, not failed) |
| Build pass-rate | 0% |

## Memory (minimum RAM)

**The run itself added about 1.6 GB of memory.** (Whole-machine use peaked at 7.9 GB, but the machine was already using 6.3 GB before the run started — so the run's own footprint is the difference, ~1.6 GB. Least free at any moment: 3.3 GB, on a machine with 10.5 GB.)

**A 16 GB machine should cope.** Allowing ~4 GB for a lean VM's own operating system plus the ~1.6 GB this run added comes to about **5.6 GB** — comfortably under 16 GB.

> How to read this: the headline is the **added** memory, not the whole-machine peak — the peak is inflated by everything else that happened to be running here. The 16 GB verdict assumes a lean VM uses ~4 GB for its OS. To be 100% certain, run once on an actual 16 GB VM; this is the evidence toward that.

## How each group of tests did

| Group | Tests | Passed | Failed | Skipped | Time | Tokens |
|---|--:|--:|--:|--:|--:|--:|
| Project & workflow checks (Tier 1) | 145 | 77 | 0 | 68 | 0.5s | — |
| Recorded run (Tier 2) | 9 | 2 | 0 | 7 | 0s | — |

## 2.1 Build attempts

| Attempt | Result | Compiled? | Tokens | Turns | Reason |
|--:|---|:--:|--:|--:|---|
| 1 | non-conforming | yes | 17,360,877 | 938 | built, but missed: role-per-story |

## 2.2 Where the time went (estimate vs actual)

| Phase | Estimated | Actual | Difference | Claude time |
|---|--:|--:|--:|--:|
| opus/build | 247m 18s | 55m 38s | -191m 39s | 22m 37s |
| opus/build/spec | 9m 59s | 9m 26s | -33.5s | 4m 45s |
| opus/build/save | 87m 10s | 6m 28s | -80m 42s | 1m 15s |
| opus/build/green | 126m 48s | 31m 19s | -95m 29s | 12m 8s |
| opus/build/red | 23m 11s | 8m 18s | -14m 53s | 4m 29s |

## Epics — time to build each one

This run created **5** epics and **5** stories in total. The estimate for each epic is its average build time on past runs of this app + model (a dash means no history yet).

| Epic | Stories | Estimated | Actual | Difference |
|---|--:|--:|--:|--:|
| approve-reject-export | 0 | — | 0s | — |
| auth-and-app-shell | 5 | 153m 56s | 32m 46s | -121m 10s |
| file-logs-dashboard | 0 | — | 0s | — |
| file-upload-lifecycle | 0 | — | 0s | — |
| transactions-review | 0 | — | 0s | — |

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

