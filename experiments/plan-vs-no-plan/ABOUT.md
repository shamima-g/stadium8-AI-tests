# The `/plan` experiment and its tests

*This document explains **only** this experiment: what it measures, the tests it runs, and what
each can and cannot prove. For how to run it, see [README.md](README.md). For how experiments fit
the wider suite, see [../README.md](../README.md).*

---

## 1. What `/plan` is, and why measure it

`/plan` is the workflow's **plan-ahead** command. Instead of planning an epic just-in-time inside a
build, it breaks the *next* epic down, gets it approved, and **parks it ready to build** — and it's
designed to run in a **separate session, concurrently with a build in progress**.

That raises a fair question from anyone paying for the tokens and waiting on the clock: **does
using `/plan` cost more, and does it buy anything back?** This experiment answers that with numbers
instead of intuition.

It measures on **three axes**, kept separate on purpose because a path can win on one and lose on
another:

| Axis | What it captures | Headline metric |
|---|---|---|
| **Cost** | how much AI work it takes | billed **USD** (tokens as a rough proxy) |
| **Speed** | how long you wait | **wall-clock** + Claude's own time |
| **Resource** | how much RAM it needs at once | **peak memory** (and "fits 16 GB?") |

The resource axis matters specifically because of `/plan`'s concurrency: running **two Claude
sessions at once** (one building, one planning) can push peak RAM above what a single session ever
touches — so "does planning-while-building blow the memory budget?" is a real question this
experiment is set up to answer, reusing the harness's existing memory sampler.

---

## 2. The one design decision everything rests on

`/plan`'s scenario **builds fewer epics on purpose** (it parks the rest). So comparing its *totals*
against a full build measures *"did less work"*, not *"cost of `/plan`"*. The fix is the
**benchmark, not the math**: run on a **2-epic benchmark** (the `minimal-concurrent` set) where the
plan arm builds **both** epics — so every arm produces the **same finished app**, and the deltas
isolate `/plan` itself. Running this on a big benchmark (transactions, contact-form) makes the arms
build different work and every number becomes apples-to-oranges.

---

## 3. The tests it carries out

The experiment runs up to three **arms** — each is a named test that drives the real Tier-3 harness
(`Run-QATests.ps1 -Scenario …`) against the *same* benchmark, model, and template, and lands in its
own results world.

### Test 1 — Baseline build (no `/plan`)
- **Runs:** `-Scenario build` — straight `/start` → `/continue`; planning happens just-in-time inside the build.
- **Proves:** the reference cost/time/peak-memory to produce the app *without* the command.
- **World:** `TestResults/<benchmark>/`.

### Test 2 — Plan-ahead, single session
- **Runs:** `-Scenario plan` — build the first epic, then `/plan` the next epics to **park** them ready-to-build, then build a parked one.
- **Proves:** the **token/USD overhead** of the park-ahead pattern versus building inline — same app, so the delta is the cost of `/plan`. Single-session, so it should **not** shorten wall-clock (its speed payoff is amortised onto a later build).
- **World:** `TestResults/<benchmark>-plan/`.

### Test 3 — Concurrent build ∥ plan
- **Runs:** `-Scenario concurrent` — a shared git remote, then **two live sessions at once**: one builds an epic while the other `/plan`s the next.
- **Proves:** whether concurrent planning **buys back wall-clock** (via its `overlapSeconds`), and what it does to **peak memory** (two sessions at once ⇒ expected to be the highest-RAM arm).
- **World:** `TestResults/<benchmark>-concurrent/`.
- **Read on its own:** its two sessions double-count tokens and overlap in wall-clock, so it is **never** summed into Test 1/2's token comparison — see the guardrails.

You choose which arms to run (`-Arms build,plan` by default; add `concurrent` when you want the speed/RAM question too).

---

## 4. Metrics (all already recorded per run by the harness)

Read from each world's `tier3-history.jsonl`:

| Metric | Field | Axis | Note |
|---|---|---|---|
| Tokens | `tokensTotal` | cost (proxy) | Sums cache-reads at par with fresh input → **overstates** cost; a proxy only. |
| Billed USD | — | cost (true) | Not in the history line; read from the run report or the `workflow-insights` skill (cache-correct). |
| Claude's own time | `claudeSeconds` | speed | The trusted time figure. |
| Wall-clock | `activeSeconds` | speed | Stopwatch, excludes machine sleep/PAUSE. |
| **Peak memory** | `peakMemoryUsedMB` | **resource** | Peak whole-system RAM while the run worked. |
| **Fits 16 GB?** | `memoryFits16GB` | **resource** | The harness's 16 GB verdict, per run. |
| Total RAM | `totalMemoryMB` | resource | The machine's RAM, for context. |
| Epics built | `epicsBuilt` | control | Must match across arms, or the comparison is invalid. |
| Pass-rate | `passRate` | control | Only compare runs of equal quality. |

The experiment reports each metric as **median [min–max]** across the arm's runs — never a single
number, because one live-AI run is dominated by variance and prompt-cache warmth.

---

## 5. What we expect (hypotheses)

- **Cost:** `plan` ≈ `build`, or slightly higher (a separate session re-reads context, does worktree git). A big gap = real overhead.
- **Speed:** `plan` (single session) ≈ `build` for *this* run; only **`concurrent`** should lower wall-clock, and only to the extent its `overlapSeconds` hid planning behind the build.
- **Peak memory:** `build` ≈ `plan` (one session each); **`concurrent` highest** (two sessions + possibly two builds overlapping) — the arm most likely to threaten a 16 GB budget. That specific finding is a key deliverable.

A result that contradicts these is the interesting outcome — the design is what makes it trustworthy.

---

## 6. Controls (held fixed, or the numbers are noise)

Same **model**, **template ref**, **benchmark**, and **prompt-cache warmth** across all runs; arms
**interleaved** (A B B A …) so calendar drift doesn't align with an arm; only runs of **equal
`epicsBuilt`/`passRate`** compared. All are parameters of the runner (§ README).

---

## 7. What this experiment can and cannot prove

**Can:**
- What `/plan` costs in tokens/USD to reach the *same* app (Test 1 vs Test 2 on the 2-epic bench).
- Whether concurrent planning buys back wall-clock (Test 3's overlap).
- Whether concurrency raises peak RAM past the 16 GB budget (peak-memory axis across arms).

**Cannot / must not conclude:**
- *"`/plan` saves/costs X tokens"* from **totals across arms that built different work**.
- Anything from **summed `concurrent` tokens or wall-clock** (its sessions overlap and re-read context).
- Any effect from **n = 1** (that's cache warmth and luck).
- That `/plan` is "not worth it" because tokens rose — its real value (a fresh plan on `main`,
  planning without blocking a build, parked epics ready) largely **does not live in tokens**.

---

## 8. How the result is produced

`Run-Experiment.ps1` runs the chosen arms N times each (interleaved), then **reuses the Tier-3
result tracking**: it reads the same `tier3-history.jsonl` the harness writes, aggregates
median+spread per arm (including peak memory), and writes one **comparison report** to
[results/](results/). It also drops the harness's own `New-Tier3Comparison` latest-run quick-diff
for baseline-vs-each-arm, saved alongside. Nothing new gates; the report is the deliverable.

The runner's pure pieces (results-key routing, median, batch selection, aggregation, report
rendering, the interleave schedule) each carry **good + broken Pester tests** in
[tests/Run-Experiment.Tests.ps1](tests/Run-Experiment.Tests.ps1) — the same discipline as the rest
of the suite.

---

## 9. Optional: isolating *planning* cost precisely

Today the harness timer only guesses `spec / red / green / save` phases — there is **no `plan`
phase**, so planning turns fold into build phases and can't be billed on their own. If you later
want to quote *planning overhead* separately from build cost, the enabling change is a
**command-scoped `plan` workflow-phase** in the timer (tag turns by the command in flight — `/plan`
vs `/start`/`/continue`). Not needed for the headline answer; add it only if this becomes routine.
