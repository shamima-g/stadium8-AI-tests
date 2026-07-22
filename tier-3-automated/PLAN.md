# Plan: Making Tier 3 run by itself

This is the plan for turning **Tier 3** — the test where a person runs the whole
workflow with a real AI and checks it behaves — into something that **runs on its
own**, with no person sitting at the keyboard.

Written in plain English on purpose. No code here — this is the blueprint to read
and agree on first.

---

## What we're trying to do, in one sentence

Right now a person has to run Tier 3 by hand. We want the computer to run the whole
thing by itself — start the AI, let it build a real app from a set of documents,
time how long everything takes, score how well it did, and write it all up — so we
can run it often instead of only at release time.

---

## The example projects (you choose which one)

Tier 3 works by handing the AI a set of documents describing an app, and letting it
build that app. We want the test to be **flexible**: it should be able to run against
**more than one** set of documents, and **you choose which set** to run each time.

**Today there is one set**, already in the `benchmark-files/` folder: a **Transaction
Import & Approval System**, where one kind of user (an *Importer*) uploads files of
transactions, and another (an *Approver*) reviews and approves or rejects them. It
comes with a brief, requirements, a design look-and-feel, two API descriptions, and a
sample spreadsheet. These documents become the **instructions we hand to the AI** — it
reads them and builds the app, exactly as if a real customer had handed them over.

**You plan to add two more sets in future.** So we build the test to handle *any
number* of sets from day one — with just the one there now, and room to drop in more
whenever you like.

### How the sets are organised

Each set lives in its own folder under `benchmark-files/`, and they all have the same
shape, so the test can pick up any of them the same way:

```
benchmark-files/
└── transactions/        the Transaction Import & Approval System (the one we have)
    ├── frontend/docs/…
    └── backend/…
        (future sets will sit here as sibling folders, e.g. benchmark-files/<second-app>/)
```

> Note: the files currently sit directly under `benchmark-files/` (as
> `frontend/…` and `backend/…`). Part of this work is a tiny, safe tidy-up — moving
> them into a `benchmark-files/transactions/` folder so every set, present and future,
> has the same tidy shape. Nothing is lost; it's just moved.

### You pick which one to run

When you start a run you say **which set to use**. If you don't say, it uses a sensible
default (the Transaction set — and while it's the only one, it's simply always used).
Full option details are in "How you start it" below; the short version is a
`-Benchmark` choice:

```powershell
./Run-QATests.ps1 -IncludeTier3                            # default set
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions   # name the set explicitly
```

### Built to stay flexible

The list of choices isn't hard-wired. The test simply looks at which folders exist
under `benchmark-files/` and offers each as a choice. So when you're ready to **add a
second or third app, it's just dropping in a new folder** (plus its answers file — see
next) — no code change needed. If you name a set that doesn't exist, the run stops and
lists the ones that do.

### Each set carries its own answers

Different apps need different answers at the four approval moments (a banking app and a
to-do app won't have the same sign-in choice or the same hands-on checks). So **each
set keeps its own answers file** next to its documents. Picking a set automatically
uses that set's answers.

### Results stay separated per app

Each app's results live in **its own folder and nowhere else** — its own reports,
timing logs, history, charts, and master list. Nothing is mixed across apps. Every run
records which **model** and which **benchmark set** it used, and lands under
`TestResults/<benchmark>/…`. That keeps results honestly comparable — a run of one app
is never averaged in with a different one. In particular, the **time estimates**
(estimated vs actual, from earlier) compare like with like: same model **and** same
app. (Full folder layout is in "Everything separated per benchmark" further down.)

We treat all these input files as **read-only**. Every run makes its own working copy
to build in, so the originals are never touched. (That working copy — the app the AI
builds — is *kept*, not thrown away; see "Where the built app is kept" in Part 2.)

---

## The decisions we've already made

| Question | What we chose |
|---|---|
| How the AI is started | The normal **Claude command-line tool**, in a mode where it doesn't stop to ask a human. |
| How the AI's questions get answered | A small file of **ready-made answers** we prepare in advance. |
| What it's built with | **PowerShell** (the scripting language your original spec used). |
| How far it runs | **All the way** — from reading the documents to the finished app merged in. |
| How we score the AI | We **write the score down**, but a poor score **never** makes the test "fail". |

---

## The one big risk (worth knowing up front)

Normally, four times during a run, the workflow **stops and asks a person** to approve
something ("Is this plan OK?"). For the computer to run alone, those four moments have
to be answered **without a person** — from our ready-made answers file.

We don't yet know for certain that the command-line tool lets us answer those moments
automatically. **If it doesn't, the run gets stuck.** This is the main unknown.

That's why we build things in the order below: we build **everything that doesn't need
the live AI first**, prove it works, and only then tackle the risky part. If the risky
part turns out to be a wall, everything else we built still works and isn't wasted.

---

## Setup and teardown wrap the whole suite (all tiers)

The whole run is wrapped by a **setup** step at the start and a **teardown** step at
the end, and both cover **all three tiers**, not just Tier 3. The master runner
(`Run-QATests.ps1`) does them in this order:

**setup → Tier 1 → Tier 2 → Tier 3 → teardown**

### Setup — install everything needed before any tier starts

Before a single test runs, setup makes sure the machine has everything the tiers need.
**Every prerequisite is mandatory — there are no optional items.** Setup **checks
what's already there and only installs what's missing** (so it's safe to run every
time), then **re-verifies each install actually landed**, and writes a short setup log
into the results so you can see what it did. The prerequisites it covers:

| Prerequisite | Needed for | How setup handles it |
|---|---|---|
| **Node.js (v20+) and npm** | Tiers 1 & 2 (Vitest), building the app | Check the version; if missing/old, install it (or, if it can't be installed automatically, stop with a clear "please install Node 20+" message) |
| **AI-tests dependencies** | All tiers (the test tools) | `npm install` inside `AI-tests/` if not already installed |
| **web/ dependencies** | Building and checking the app | `npm install` inside `web/` when a build is needed |
| **PowerShell 7** | The runner and the PowerShell hook tests | Check it's present; guide install if not |
| **Pester 5** | Tier 1 PowerShell hook tests | Install the module if missing, then confirm it loads |
| **Playwright browser (Chromium)** | The click-through (end-to-end) gate | Install the pinned browser (`npx playwright install chromium`) if it isn't cached, then confirm the cache; **the run does not start unless it's present** |
| **Claude command-line tool** | Tier 3 live runs | Check it's installed **and** signed in; if not, stop with a clear message (we never store logins) |
| **Git** | Tier 2 and the build's history | Check it's present |

**The guiding rule: setup installs anything required to run the tests in the suite, and
every item is a must-have.** The table above is the current list, but the principle is
what matters — if a test needs a tool, setup is responsible for making sure it's there
**and working**. So the rules setup follows are: **only install what's missing**;
**re-verify every install** so an install that "ran" but didn't actually land is caught;
and **never silently work around, warn-and-skip, or start on a missing prerequisite** —
if any essential item can't be installed and verified automatically, setup stops, tells
you exactly what to do in plain English, records everything it checked or installed, and
**the tests do not run**. If you're only running the cheap tiers, it skips the
Tier-3-only prerequisites (the Claude tool and the Playwright browser) — but everything
that *does* apply is still mandatory.

### Teardown — clean up across all tiers at the end

When everything has finished, one teardown tidies up after **all** the tiers. Like the
Tier 3 teardown described later, it **always runs after the reports are written** (even
if a tier failed), and it **keeps what matters, removes what's not necessary**:

- **Keeps:** every report, timing log, history, charts page, and the saved app zips —
  all of `TestResults/`.
- **Removes (not necessary — rebuildable or temporary):** the throwaway working folders
  each tier makes, leftover `node_modules`/build caches, any temp git branches or
  worktrees the tests created, and any stray processes (like a dev server left
  running).

The same switches apply to the whole suite: **`-NoTeardown`** (remove nothing),
**`-KeepDeps`** (leave `node_modules` in place), and **`-Cleanup`** (the most
thorough clean). Teardown is best-effort — a cleanup hiccup is reported but never fails
the run, and each tier's own temp folder is the real safety net.

## Two principles carried through every part below

1. **Lean on Tier 3 behaviour** for confidence — it drives the real workflow, so it barely
   breaks when the template changes. We keep the brittle exact-wording checks to a minimum.
2. **One-command re-baselining.** Anything that compares against a saved example — the
   report format, the history, any snapshot, and the Tier 2 golden run — can be refreshed
   with a **single `-Update` flag**, never hand-edited. When behaviour changes on purpose,
   we *re-record*, we don't rewrite. (This is the same "minutes, not hours" goal as the
   `npm run reconcile` helper, applied to outputs instead of the template's shape.)

## What we'll build, and in what order

### Part 0 — Setup and teardown for the whole suite (build alongside Part 1) ✅ Built

The setup and teardown steps above. They don't need the live AI, so they're built and
tested early with the rest of the safe parts — proven by pointing them at a machine
that's missing a prerequisite (setup installs it) and a folder full of throwaway junk
(teardown clears it, keeps the results).

### Part 1 — Everything except the live AI (build this first)

None of this needs the AI, so it's cheap, quick, and can't be flaky. We test it against
a **saved recording** of a run instead of a live one.

**1a. The stopwatch.** ✅ **Built** — `timing.ps1`, with good-and-broken tests in
`tests/timing.Tests.ps1` (run with `npm run test:tier3-unit`; 15 tests passing).
A timer that records how long the AI's work takes, at every level of detail — from
"the whole run" right down to "one single turn". It records these nested layers:

- **Whole run** — start to finish.
- **Model** — which AI was used (for example *opus* or *sonnet*).
- **Phase** — a step we drive (build, compile, check the code, a retry, and so on).
- **Workflow phase (a best guess)** — writing the spec / writing the failing test /
  writing the code / saving the work.
- **Turn** — one single back-and-forth from the AI.

Two clocks are shown side by side: the **AI's own time** (what the AI says it spent —
this is the number to trust) and the **active time** (what our stopwatch counted).

**The clock is honest about gaps.** It only counts the moments work was actually
happening. It never just does "end time minus start time", because that would wrongly
count time the machine spent asleep or paused. There are two ways to pause:

- Drop a file named **`PAUSE`** into the run's live folder to freeze the clock; delete
  it to carry on.
- If the machine goes to sleep, the clock notices and doesn't count that time.

Any time set aside like this is **reported separately**, so you can see it, but it's
never mixed into the totals.

**The "workflow phase" is only a guess** — the workflow doesn't announce which phase
it's in, so we guess from what the AI just did (editing the API description ⇒ "spec";
writing a test file ⇒ "failing test"; writing app code ⇒ "code"; saving to version
control ⇒ "save"; nothing obvious ⇒ stays on the previous phase). The per-turn and
per-phase times themselves are exact — only the phase *label* is a guess.

**Nothing is lost on a shutdown.** Every finished slice of time is written to a running
log the moment it ends. If the machine is switched off mid-run, everything finished so
far is safe — only the one slice that was still in progress is lost.

**1a-plus. Running in the background, and carrying on after a shutdown.**

Two related things, so they're clear and separate:

- **Runs in the background.** The whole Tier 3 run happens as a background job — you
  start it and get your machine back; you don't have to sit and watch it. It writes
  everything to files as it goes, so you can check in on it whenever you like.
- **Carries on after a shutdown.** If the PC is switched off (or crashes) partway
  through, the run doesn't have to start over. When the machine comes back, we
  **pick up where we left off** rather than rebuilding from scratch. This works
  because the workflow is already designed to be resumed — it remembers which stage
  the app is up to, and `/continue` carries on from there. So on restart we check the
  run back out and let it continue the remaining stages, and the stopwatch resumes on
  the same run (the offline time is excluded, exactly as above).

One thing worth a quick decision (not now — when we build Part 2): whether the run
should **restart itself automatically** the moment the PC boots up, or whether you'd
rather **restart it yourself** with one command. Auto-restart is a little more setup;
restart-yourself is simpler and safer. I'd suggest starting with restart-yourself and
adding auto-restart later only if you want it.

**1b. The written report.** ✅ **Built** — `Generate-Report.ps1` (+ tests).
After a run, one plain-English summary (a Markdown file) so anyone can see what was
tested, by whom, how long it took, and what it cost — without reading the console.

The report includes:
- A run summary: date, who ran it, what version, the result, how long, how many AI
  tokens were used, the AI's time, active and paused time, and which AI model.
- A breakdown per group of tests (how many passed, failed, skipped, time, tokens).
- An **attempts table** — one row per build the AI tried: did it pass, did it compile,
  how many tokens, how many turns, and a short reason.
- A **timing table with an estimate next to the actual time** (see below).
- **Epic counts + per-epic build time**: how many epics and stories were created, and a
  per-epic table of estimated vs actual build time (with a matching bar chart on the
  charts page). Per-epic time comes from the app's git history (first→last commit for
  that epic); the estimate is that epic's average over past runs.
- A **per-test detail table**.
- The **list of tools installed**, so the setup is on record.
- A **failure explanation section**: for every failure, a plain reason and a
  "possible solutions" list — and for the AI's work, each rule it broke is expanded
  into how to fix it.

**1b-plus. Estimated time vs actual time, per phase (granular) and whole-run (macro).**
✅ **Built** — the per-phase estimate-vs-actual is in the report's §2.2; the whole-run
(macro) estimate — estimated total time to build the app, next to the actual, with the
difference — is in the "The run" summary table (`Get-Tier3RunEstimate` in `history.ps1`).

**1b-memory. Peak memory (minimum RAM).** ✅ **Built** — `memory.ps1` (+ tests). While the
run works — and especially while the app compiles — it samples whole-system memory every
second and records the **peak used**. The report shows a "Memory (minimum RAM)" section
and a **Fits in 16 GB?** verdict, and the history records `peakMemoryUsedMB` /
`totalMemoryMB` / `memoryFits16GB`. This answers "what's the minimum RAM for Stadium 8?".
Honest caveat, stated in the report: it's whole-system memory (includes everything else
running), so it over-states a lean VM's need — the definitive check is one run on a real
16 GB VM, and this figure is the evidence either way.

The report shows, for **each phase** (build, compile, check the code, save, and so
on), an **estimate of how long it should take** right next to the **actual time it
took** — plus the difference, so you can see at a glance whether this run was faster
or slower than expected.

Where the estimate comes from: we already keep a history of every past run. The
estimate for a phase is simply **how long that phase usually takes** on past runs with
the same model (its average). So the more runs we do, the smarter the estimate gets.

- On the **very first run** there's no history yet, so the estimate shows a dash and
  only the actual time is filled in. From the second run on, the estimate appears.
- The table reads like: **Phase · Estimated · Actual · Difference** (for example,
  "Build · ~8m · 9m 20s · +1m 20s slower").

This same estimate-vs-actual idea also feeds the per-phase timing card on the charts
page, so the comparison shows up both in the written report and on the charts.

**1c. The history and the charts.** ✅ **Built** — `history.ps1` + `Generate-Tier3-Html.ps1` (+ tests).

> **Everything below is kept per benchmark — never mixed.** Each example app has its
> own reports, timing logs, history file, charts page, and master list, all inside
> that app's own folder. A run of one app never lands in another app's files, and its
> numbers are never averaged together. See "Everything separated per benchmark" just
> below for the exact folder layout.

- A running history file (one **per benchmark**) that gets **one new line added per
  run** and is never rewritten — so we can see trends over time for that app (times,
  tokens, cost, turns, rules missed, pass-rate, and so on). Older lines that lack newer
  details just show a dash.
- A **charts page** (one **per benchmark** — a self-contained web page, no internet
  needed) built from that app's history. It shows:
  - **The last 10 runs for each model** (see below) — the headline view.
  - A chart of **time taken** — overall time next to the AI's own time.
  - A **summary per version** of the template.
  - The **most-often-broken rules** — the "what to make clearer in the
    instructions" list.
  - A **timing card** breaking the time down by phase.
  - A table of the **raw records**, including the pass-rate.

**1d. Showing the last 10 runs per model.**

This is the main thing we want to see at a glance, so it gets its own treatment.

Every run is done with **one AI model** (for example *opus* or *sonnet*). We keep the
runs **grouped by model**, and for each model we show the **10 most recent runs**,
newest first. So if you've run *opus* twelve times and *sonnet* three times, you see
the last **10 opus** runs in one block and all **3 sonnet** runs in another — never
one big mixed list where the models blur together.

For each of those 10 rows you can see, at a glance: **when** it ran, the **result**,
how **long** it took (overall and the AI's own time), the **tokens** and rough
**cost**, the number of **turns**, the **pass-rate**, and the **rules it missed** —
with a link straight into that run's own folder for the full report.

This is done **within each benchmark** — so it's really "the last 10 runs per model,
for this app". The Transaction app's charts show the Transaction app's last-10-per-model;
a future app's charts show its own. The two views are:

- The app's **charts page** (`tier3-metrics.html`, inside that app's folder) — the
  visual version, with the charts.
- The app's **master list** (`index.md`, inside that app's folder) — the plain-text
  version, one row per run, newest first, grouped by model, each linking into its run
  folder.

Older runs aren't deleted — they stay in that app's history file and their folders
remain. "Last 10 per model" is just the window we *show*, so the page stays readable no
matter how many hundreds of runs pile up. (If you'd rather show a different number than
10, that's a one-line change — tell me and I'll set it.)

**1e. Everything separated per benchmark (nothing mixed).**

The results tree splits by **app first, then model, then run**. Each app is a
self-contained world — its own reports, timing, history, charts, and master list:

```
TestResults/
├── transactions/                  everything for the Transaction app
│   ├── index.md                   this app's master list (last 10 per model)
│   ├── tier3-history.jsonl        this app's history (one line per run)
│   ├── tier3-metrics.html         this app's charts page
│   └── <model>/<timestamp>/       one folder per run
│       ├── report-<version>-<timestamp>.md
│       ├── Fail/<timestamp>.md     (only if something failed)
│       ├── tier3-live/<run>.jsonl  this run's timing log
│       └── <model>-<timestamp>.zip the app this run built
└── <future-app>/                  a future app gets its own identical world
    └── …
```

So there is **no shared history, no shared charts, no shared master list** across
apps. If you later want a single top-level page that links out to each app's world, we
can add one — but by default nothing is combined.

### Part 2 — Starting the live AI (the risky part) ✅ Working (first live run passed)

> **The core risk is resolved and a full live run has succeeded.** The reference harness
> (C:\AI\Linx8-QATests-DO-NOT-DELETE\QATests) showed the approvals aren't fed
> interactively — one autonomous `claude -p "<prompt>" --output-format stream-json
> --verbose --dangerously-skip-permissions` call, with the prompt telling Claude to
> proceed through all gates itself. `live-driver.ps1` ports this: scaffold a throwaway
> template copy → drop the benchmark docs in → compose the autonomous prompt (embedding
> `answers.json`) → spawn Claude via **cmd.exe with `> file` redirect and prompt via
> stdin** (the only reliable capture on Windows — `Start-Process -RedirectStandardOutput`
> does NOT work) → tail the stream live into the stopwatch → build-check → run-result.
>
> **First live run (20260710-0907, opus, transactions):** ~19 min, 183 turns, ~13M
> tokens. Claude built a real multi-epic app (BFF auth, Shadcn UI, MSW mocks, Zod, 3
> epics) that **compiles** (`npm install` + `npm run build` → Next.js build ✓). The full
> report, history line, and charts were produced. 57 Pester unit tests cover the no-AI
> pieces.
>
> **Also built:** the memory sampler (peak + added memory, "fits 16 GB?" — `memory.ps1`);
> the **app zip** (`Compress-Tier3App` — a lightweight snapshot into the run folder,
> excluding node_modules/.next, written before teardown); and **per-phase Claude-time
> distribution** (`Get-DistributedPhaseTiming` — total Claude time split across the
> workflow-phase spans by output tokens, so §2.2 shows real per-phase time).
>
> **Also built:** **background-run + resume** — the run persists Claude's session id to
> `tier3-live/session.id`; if a run is interrupted, `Run-QATests.ps1 -Resume` finds the
> newest started-but-unfinished run and continues the same session with `/continue`
> (`Find-IncompleteRun` + `--resume`). And **maximum fidelity** — the entry prompt now
> drives the REAL workflow commands (`/start` then `/continue`) and points Claude at the
> pre-planned answers file dropped into the scaffold root (`TIER3-ANSWERS.json`) for every
> approval gate, so the genuine command-driven workflow runs unattended. (The prose-only
> prompt is retired.)
>
> **Headless background-task ceiling (must-set):** the workflow builds each story through
> **background subagents** (per-story "developer" and "test-gen" agents) that the
> orchestrator spawns and then *awaits*. Headless Claude Code terminates the process when
> background tasks are still running after its default 600-second ceiling — which truncates
> the build mid-epic (the stream shows the orchestrator repeatedly yielding "I'll await the
> Story N developer", then the process is killed). The driver therefore sets
> **`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0`** (wait indefinitely) before launching Claude,
> so those awaited agents finish; the driver's own `$TimeoutSeconds` (`Stop-ProcessTree`)
> stays the real overall ceiling. Note: **`-Resume` of a session killed mid-epic does not
> reliably re-enter the epic loop** — prefer a fresh full run over resume for a truncated
> build.
>
> **Part 3 — conformance scoring: ✅ Built.** After the build, the run judges the app with
> the **real tier-1 artifact-lint rules** (no-suppressions, Shadcn-only, exact API paths,
> centralised styling, role-per-story, plain-language) by running them with `REPO_ROOT`
> pointed at the scaffold (`Get-Tier3Conformance` + `ConvertFrom-VitestArtifactJson`) —
> single source of truth, not a re-implementation. Rules the app misses land in
> `rulesMissed`, the §2.1 reason, and §3.1 with fixes. Still **record-only** — a missed
> rule never fails the run; conforming = built AND no rules missed.
>
> **Also built:** the runner now runs **Tier 1 + Tier 2** and reports their group results
> (`Get-Tier3LowerTierGroups`), so one run covers the whole suite (setup → Tier 1 → Tier 2
> → Tier 3 → teardown); and it rebuilds a top-level **`TestResults/index.md`** master list
> of every run across all benchmarks (`Update-Tier3Index`).
>
> **Status: the automated Tier 3 is feature-complete** per this plan. 78 Pester unit tests.

A script that:
1. Works out **which benchmark set** to use (from `-Benchmark`, or the default) and
   **which template** to build against — the local one by default, or a channel@version
   (`-Target dev|release -Ref <tag>`, cloned from `targets.json` into `.targets/`, the
   live-build counterpart to `test:target`). Targeted runs are filed under their own
   `TestResults/<benchmark>@<target>-<ref>/` world so release and dev builds never mix.
2. Sets up a fresh **working folder** for this run (its own folder — see "Where the
   built app is kept" below).
3. Copies **that set's** documents into it as the instructions.
4. Starts the Claude command-line tool with no human present, running the workflow
   from start to finish.
5. Answers the four approval moments from **that set's** ready-made answers file.
6. Captures everything the AI does and feeds it into the stopwatch and report from
   Part 1, tagging the results with the model **and** the benchmark set used.

Each run gets its **own results folder inside that benchmark's world**
(`TestResults/<benchmark>/<model>/<timestamp>/`), holding: the raw results, the report,
the failure file (only if something failed), the timing logs, and a **zipped copy of
the app the AI built** (best-effort — if a file is locked it's skipped, and a zip
problem never fails the test).

**Where the built app is kept.**

The app the AI builds is **kept on disk — it is never deleted** — so you can open it,
run it, and look at exactly what was produced. There are **two copies**:

- **The live app on disk** — the working folder the run built in stays put in its own
  per-app, per-run location:
  `C:\temp\tier3-builds\<benchmark>\<model>\<timestamp>\` (outside the test suite;
  overridable with `-BuildRoot`). This is the real,
  runnable project (its `web/` app, its `generated-docs/`, its git history — the lot).
- **A zipped copy in the results folder** —
  `TestResults/<benchmark>/<model>/<timestamp>/<model>-<timestamp>.zip` — so each run's
  output is captured alongside its report even if the live copy is later moved or
  removed by hand.

**Teardown — keep what matters, remove what's not necessary.**

After every run we tidy up, but carefully. Teardown always runs **after** the report
and the zip are written, so results can never be lost. It **keeps** the things you'd
actually want and **removes** only the heavy, throwaway bits that can always be
rebuilt:

| Kept (the things that matter) | Removed (not necessary — big and rebuildable) |
|---|---|
| The app's **source code** and `generated-docs/` | `node_modules/` (re-installable with one command) |
| The **git history** of the build | Build caches / output (e.g. `.next/`, coverage) |
| The **report**, **timing logs**, **history**, **charts** | Package-manager download caches |
| The **zip** of the app in the results folder | Temporary scratch files |
| | Any leftover dev-server processes and temp git branches |

So the runnable app stays on disk — just slimmed down. To run it again you'd reinstall
its parts with one command (or unzip the saved copy); the source, history, and results
are all still there.

**Options:**

- **`-KeepDeps`** — skip removing `node_modules`, leaving the app **instantly**
  runnable with nothing to reinstall (uses more disk).
- **`-NoTeardown`** — remove nothing at all; keep the whole working folder exactly as
  the AI left it, for close inspection.
- **`-Cleanup`** — the opposite extreme: remove the **entire** live working folder.
  Even then, the zip in the results folder is kept, so the run's output survives.

Everything above stays separated per benchmark, exactly like the rest.

### Part 3 — Finishing touches

- **Scoring** the finished app against rules the suite already checks (no code
  shortcuts, correct data addresses, standard building blocks, colours kept in one
  place, a role on every screen, plain-language checklists). The score is **written
  down** in the report and history but **never turns the run red**.
- Adding each Tier 3 run to **that benchmark's own master list** (`index.md` inside the
  app's folder), newest first — not to a shared, mixed list.

---

## How you start it (the options)

Yes — **you choose which AI model runs Tier 3.** You pass it as an option when you
start the run. (In your original spec this was `-L6Model`; here it's `-Tier3Model`,
to match the Tier 3 naming everywhere else.)

```powershell
# Default model (opus), score recorded but not graded, one build:
./Run-QATests.ps1 -IncludeTier3

# Pick the model yourself (no fallback):
./Run-QATests.ps1 -IncludeTier3 -Tier3Model sonnet

# Pick which example app to build (the benchmark set):
./Run-QATests.ps1 -IncludeTier3 -Benchmark transactions

# Combine them freely:
./Run-QATests.ps1 -IncludeTier3 -Tier3Model sonnet -Benchmark transactions
```

What these mean in plain English:

- **`-IncludeTier3`** — turn the live Tier 3 run on. Without it, the suite runs the
  cheaper tiers only and doesn't start the AI.
- **`-Tier3Model <name>`** — which model to use, for example `opus` or `sonnet`. Leave
  it off and it uses **opus** by default.
- **`-Benchmark <name>`** — which example app to build, by folder name (for example
  `transactions`). Leave it off and it uses the default set. Name one that doesn't
  exist and the run stops and lists the sets that do.
- **No fallback** — if you name a model and it isn't available, the run **stops and
  tells you**. It will **not** quietly switch to a different model behind your back,
  because that would make the results misleading (you'd think you tested one model but
  really tested another).
- **Recorded, not graded** — as agreed, the score is written into the report and
  history, but it never turns the run red.
- **One build** — by default the AI builds the app once. (If later you want it to try
  more than once, we can add an option for that — say the word.)

Because each run's folder and the history are already **grouped by model**, choosing
`sonnet` one day and `opus` the next keeps their results cleanly separated — and the
"last 10 per model" view shows each model's recent runs in its own block.

## What I'll need from you later

When we reach Part 2, I'll need the **exact answers** to the four approval moments for
the Transaction project. The brief already covers the pitch and the two roles, but two
answers are your call:

- Which **sign-in method** to use.
- What **hands-on checks** to tick off for each part of the app.

We'll capture those together when we get there.

---

## Where the files will live

```
AI-tests/
├── tier-3-automated/
│   ├── PLAN.md                    (this file)
│   ├── Run-QATests.ps1            master runner: setup → tiers → teardown
│   ├── Setup.ps1                  checks & installs all prerequisites
│   ├── Teardown.ps1               cleans up across all tiers (keeps results)
│   ├── timing.ps1                 the stopwatch
│   ├── Generate-Report.ps1        writes the run report
│   ├── Generate-Tier3-Html.ps1    builds the charts page
│   └── README.md
   (built apps are kept OUTSIDE the suite, under C:\temp\tier3-builds\<benchmark>\<model>\<timestamp>\
    — overridable with -BuildRoot; never auto-deleted)
├── benchmark-files/               the example apps — one folder per set (you pick which)
│   └── transactions/              set 1 (the one we have)
│       ├── frontend/docs/…        the documents handed to the AI
│       ├── backend/…
│       └── answers.json           this set's ready-made approval answers
│       (future sets sit here as sibling folders, each with its own answers.json)
└── TestResults/                   results split by app — nothing mixed
    └── transactions/              this app's own world
        ├── index.md               this app's master list (last 10 per model)
        ├── tier3-history.jsonl     this app's history
        ├── tier3-metrics.html      this app's charts page
        └── <model>/<timestamp>/    one folder per run (report, timing, zip, …)
```

---

## In short

We build the safe, cheap parts first (the stopwatch, the report, the history, the
charts) and prove them against a saved recording. Then we try the risky part — running
the AI with no person — knowing that if it doesn't work, nothing we already built is
wasted. Each app's results stay in its own folder, never mixed. The built app is kept
on disk (with a zipped copy in the results), and teardown removes only the heavy,
rebuildable junk. The AI's score is always written down, never used to fail the run.
