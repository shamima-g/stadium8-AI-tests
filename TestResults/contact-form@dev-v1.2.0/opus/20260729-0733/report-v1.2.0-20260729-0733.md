# Tier 3 report — 20260729-0733

A plain-language summary of the automated Tier 3 run for the **contact-form** app.

## The run

| | |
|---|---|
| Result | ✅ Passed |
| App (benchmark) | contact-form |
| AI model | opus |
| Template | dev-v1.2.0 |
| Version tested | v1.2.0 |
| Epics created | 4 |
| Epics built | ✅ 4 of 4 (100%) |
| Stories created | 14 |
| Run by | User on WINDEV2407EVAL |
| When | 20260729-0733 |
| Active time | 328m 19s |
| Estimated active time | 279m 37s (this run +48m 42s vs estimate) |
| Claude's own time | 182m 26s |
| Estimated Claude time | 145m 22s |
| Paused / excluded | 0s |
| Memory the run added | 9.6 GB (whole-machine peak 14.9 GB) |
| Fits in 16 GB? | ✅ yes |
| Total AI tokens | 327,651,294 |
| Tier 3 verdict | ✅ met the rules |
| Build pass-rate | 100% |

## Memory (minimum RAM)

**The run itself added about 9.6 GB of memory.** (Whole-machine use peaked at 14.9 GB, but the machine was already using 5.3 GB before the run started — so the run's own footprint is the difference, ~9.6 GB. Least free at any moment: 2.4 GB, on a machine with 11.9 GB.)

**A 16 GB machine should cope.** Allowing ~4 GB for a lean VM's own operating system plus the ~9.6 GB this run added comes to about **13.6 GB** — comfortably under 16 GB.

> How to read this: the headline is the **added** memory, not the whole-machine peak — the peak is inflated by everything else that happened to be running here. The 16 GB verdict assumes a lean VM uses ~4 GB for its OS. To be 100% certain, run once on an actual 16 GB VM; this is the evidence toward that.

## 2.1 Build attempts

| Attempt | Result | Compiled? | Tokens | Turns | Reason |
|--:|---|:--:|--:|--:|---|
| 1 | passed | yes | 327,651,294 | 3613 | built and passed all rules |

## 2.2 Where the time went (estimate vs actual)

| Phase | Estimated | Actual | Difference | Claude time |
|---|--:|--:|--:|--:|
| opus/build | 279m 37s | 48m 42s | -230m 56s | 182m 26s |
| opus/build/spec | 8m 36s | 2m 14s | -6m 22s | 2m 20s |
| opus/build/save | 57m 54s | 18m 51s | -39m 4s | 34m 4s |
| opus/build/red | 36m 40s | 13m 13s | -23m 26s | 35m 52s |
| opus/build/green | 176m 14s | 14m 3s | -162m 11s | 110m 9s |

## Epics — time to build each one

This run created **4** epics and **14** stories in total. The estimate for each epic is its average build time on past runs of this app + model (a dash means no history yet).

| Epic | Stories | Estimated | Actual | Difference |
|---|--:|--:|--:|--:|
| admin-delete | 1 | 0s | 32m 42s | +32m 42s |
| auth-foundation | 5 | 99m 4s | 99m 4s | +0s |
| backoffice-triage | 5 | 90m 12s | 179m 41s | +89m 29s |
| visitor-enquiry | 3 | 68m 57s | 68m 57s | +0s |

## Tools on record

- node v24.16.0
- npm 11.13.0
- claude 2.1.195 (Claude Code)
- pwsh 7.6.4

