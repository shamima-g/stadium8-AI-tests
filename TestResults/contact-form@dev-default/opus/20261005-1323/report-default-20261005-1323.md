# Tier 3 report — 20261005-1323

A plain-language summary of the automated Tier 3 run for the **contact-form** app.

## The run

| | |
|---|---|
| Result | ✅ Passed |
| App (benchmark) | contact-form |
| AI model | opus |
| Template | dev-default |
| Repository | https://github.com/stadium-software/stadium-8 |
| Branch / ref | default branch |
| Version tested | default |
| Epics created | 4 |
| Epics built | ✅ 4 of 4 (100%) |
| Stories created | 13 |
| Run by | ShamimaGukhool on SHAMIMA-NB |
| When | 20261005-1323 |
| Command | `./Run-QATests.ps1 -IncludeTier3 -Benchmark contact-form -Tier3Model opus -Target dev -Resume` |
| Built at | `C:\temp\tier3-builds\contact-form@dev-default\opus\20261005-1323` |
| Active time | 273m 34s |
| Claude's own time | 172m 48s |
| Paused / excluded | 0s |
| Memory the run added | 5.5 GB (whole-machine peak 17.6 GB) |
| Fits in 16 GB? | ✅ yes |
| Total AI tokens | 39,689,817 |
| Tier 3 verdict | ✅ met the rules |
| Build pass-rate | 100% |

## Memory (minimum RAM)

**The run itself added about 5.5 GB of memory.** (Whole-machine use peaked at 17.6 GB, but the machine was already using 12.1 GB before the run started — so the run's own footprint is the difference, ~5.5 GB. Least free at any moment: 14.1 GB, on a machine with 31.7 GB.)

**A 16 GB machine should cope.** Allowing ~4 GB for a lean VM's own operating system plus the ~5.5 GB this run added comes to about **9.5 GB** — comfortably under 16 GB.

> How to read this: the headline is the **added** memory, not the whole-machine peak — the peak is inflated by everything else that happened to be running here. The 16 GB verdict assumes a lean VM uses ~4 GB for its OS. To be 100% certain, run once on an actual 16 GB VM; this is the evidence toward that.

## How each group of tests did

| Group | Tests | Passed | Failed | Skipped | Time | Tokens |
|---|--:|--:|--:|--:|--:|--:|
| Project & workflow checks (Tier 1) | 486 | 357 | 0 | 129 | 2.6s | — |
| Recorded run (Tier 2) | 86 | 79 | 0 | 7 | 8.3s | — |

## 2.1 Build attempts

| Attempt | Result | Compiled? | Tokens | Turns | Reason |
|--:|---|:--:|--:|--:|---|
| 1 | passed | yes | 39,689,817 | 2073 | built and passed all rules |

## 2.2 Where the time went (estimate vs actual)

| Phase | Estimated | Actual | Difference | Claude time |
|---|--:|--:|--:|--:|
| opus/build | — | 172m 53s | — | 172m 48s |
| opus/build/spec | — | 37.4s | — | 3m 38s |
| opus/build/red | — | 78m 56s | — | 65m 21s |
| opus/build/green | — | 62m 10s | — | 83m 23s |
| opus/build/save | — | 31m 1s | — | 20m 25s |

## Epics — time to build each one

This run created **4** epics and **13** stories in total. The estimate for each epic is its average build time on past runs of this app + model (a dash means no history yet).

| Epic | Stories | Estimated | Actual | Difference |
|---|--:|--:|--:|--:|
| auth-and-app-shell | 4 | — | 148m 52s | — |
| inbox-and-triage | 5 | — | 98m 46s | — |
| visitor-contact-form | 2 | — | 14m 2s | — |
| visitor-my-submissions | 2 | — | 11m 13s | — |

## Tools on record

- node v24.11.0
- npm 11.6.1
- claude 2.0.69 (Claude Code)
- pwsh 7.6.6

