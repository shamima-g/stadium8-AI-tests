# Tier 3 report — 20260728-0722

A plain-language summary of the automated Tier 3 run for the **e-commerce** app.

## The run

| | |
|---|---|
| Result | ✅ Passed |
| App (benchmark) | e-commerce |
| AI model | opus |
| Template | dev-v1.1.0 |
| Version tested | v1.1.0 |
| Epics created | 3 |
| Epics built | ⚠️ 1 of 3 (33%) |
| Stories created | 4 |
| Run by | User on WINDEV2407EVAL |
| When | 20260728-0722 |
| Active time | 96m 42s |
| Claude's own time | 55m 34s |
| Paused / excluded | 0s |
| Memory the run added | 2.8 GB (whole-machine peak 7.7 GB) |
| Fits in 16 GB? | ✅ yes |
| Total AI tokens | 33,165,220 |
| Tier 3 verdict | ⚠️ incomplete — built 1 of 3 planned epics (recorded, not failed) |
| Build pass-rate | 33% |

## Memory (minimum RAM)

**The run itself added about 2.8 GB of memory.** (Whole-machine use peaked at 7.7 GB, but the machine was already using 4.9 GB before the run started — so the run's own footprint is the difference, ~2.8 GB. Least free at any moment: 2.3 GB, on a machine with 7.5 GB.)

**A 16 GB machine should cope.** Allowing ~4 GB for a lean VM's own operating system plus the ~2.8 GB this run added comes to about **6.8 GB** — comfortably under 16 GB.

> How to read this: the headline is the **added** memory, not the whole-machine peak — the peak is inflated by everything else that happened to be running here. The 16 GB verdict assumes a lean VM uses ~4 GB for its OS. To be 100% certain, run once on an actual 16 GB VM; this is the evidence toward that.

## 2.1 Build attempts

| Attempt | Result | Compiled? | Tokens | Turns | Reason |
|--:|---|:--:|--:|--:|---|
| 1 | incomplete | yes | 33,165,220 | 1172 | incomplete — built 1 of 3 planned epics before the run ended |

## 2.2 Where the time went (estimate vs actual)

| Phase | Estimated | Actual | Difference | Claude time |
|---|--:|--:|--:|--:|
| opus/build | — | 96m 42s | — | 55m 34s |
| opus/build/spec | — | 9m 39s | — | 6m 49s |
| opus/build/save | — | 28m 30s | — | 8m 46s |
| opus/build/green | — | 42m 47s | — | 31m 50s |
| opus/build/red | — | 15m 36s | — | 8m 9s |

## Epics — time to build each one

This run created **3** epics and **4** stories in total. The estimate for each epic is its average build time on past runs of this app + model (a dash means no history yet).

| Epic | Stories | Estimated | Actual | Difference |
|---|--:|--:|--:|--:|
| admin-management | 0 | — | 0s | — |
| customer-shopping | 0 | — | 0s | — |
| foundation-auth-shell | 4 | — | 79m 17s | — |

## Tools on record

- node v24.16.0
- npm 11.13.0
- claude 2.1.195 (Claude Code)
- pwsh 7.6.4

## 3.1 What needs attention, and how to fix it

**Tier 3 rule not met: incomplete-build**

- Possible fix: The build stopped before finishing every planned epic — resume it (Run-QATests.ps1 -Resume -Timestamp <run>) so the remaining epics build, and check why the run ended early (e.g. a stalled epic-end gate).

**Build attempt 1: incomplete**

- Possible fix: The build stopped before finishing every planned epic — resume it (Run-QATests.ps1 -Resume -Timestamp <run>) so the remaining epics build, and check why the run ended early (e.g. a stalled epic-end gate).

