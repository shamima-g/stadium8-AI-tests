# Experiments — measurement studies (not pass/fail tests)

This folder holds **experiments**: open-ended studies that *measure and compare* how the
template and its workflow behave — token cost, wall-clock time, quality trade-offs, the
value of one workflow path versus another. They answer *"how much / how does it compare?"*,
not *"is it correct?"*.

They are deliberately kept **separate from the test suite**. The three tiers and
[../workflow-tests.md](../workflow-tests.md) are **pass/fail correctness gates** — they go red
when the template is broken. Experiments are different in kind:

- **Record-only.** An experiment never gates CI, never blocks a commit, never turns a run red.
  Its output is a finding you read, not a check that passes.
- **Exploratory.** Each has its own hypothesis, method, and result. There will be **many** of
  them, added over time, and they don't all share one document.
- **Self-contained.** Each experiment is one folder with its own instructions and its own
  results, so studies never entangle.

> If what you're writing has a right answer the template must satisfy, it's a **test** — put it
> in a tier and follow [../workflow-tests.md](../workflow-tests.md). If it's a question whose
> answer is a *number or a comparison* you want to learn, it's an **experiment** — it goes here.

---

## Folder convention (every experiment follows this)

```
experiments/
├── README.md                 ← this hub: conventions + the index below
└── <experiment-slug>/        ← one folder per experiment
    ├── README.md             ← how to RUN it (params, outputs, how to read)
    ├── ABOUT.md              ← what it measures and the tests it carries out (the explainer)
    ├── Run-*.ps1             ← the runner + report generator (drives the harness, aggregates history)
    ├── results/              ← THIS experiment's outputs (comparison reports, findings log)
    │   └── RESULTS-TEMPLATE.md   ← copy per run-batch; where findings are recorded
    └── tests/                ← Pester good/broken tests for the runner's pure functions
```

(A tiny experiment may be README + results only; a runnable one adds the script, its ABOUT, and tests.)

Two kinds of "results", kept apart on purpose:

- **Raw runs** land where the harness already puts them — `TestResults/<world>/` — one *world*
  per scenario/target (e.g. `TestResults/minimal-concurrent`, `…-plan`). The experiment
  **reads** those; it doesn't own them.
- **The experiment's own analysis** — the comparison table and the written finding — lands in
  that experiment's `results/` folder. That's the "separate results" per experiment.

An experiment **drives the existing Tier-3 harness** (`tier-3-automated/Run-QATests.ps1` and its
`-Scenario` switch) and **reads the recorded history** (`tier3-history.jsonl`). It adds no new
gating machinery.

---

## Ground rules shared by every experiment

These come from hard-won measurement lessons; each experiment's README restates the ones that
bite it:

1. **Compare like-for-like or not at all.** Same model, same template ref, same benchmark, same
   prompt-cache warmth on both arms. Never compare totals across arms that did *different amounts
   of work*.
2. **Repeat; report a distribution.** A single live-AI run is dominated by run-to-run variance
   and cache warmth. Report **median + min/max** over ≥3 runs, never one number.
3. **Separate the axes.** Token/USD **cost**, wall-clock **speed**, and **peak memory** (resource)
   move independently — a path can cost more tokens, finish sooner, yet need more RAM at once. Keep
   them on separate lines.
4. **Cost ≠ `tokensTotal`.** Raw token totals sum cheap cache-reads at par with fresh input. For a
   true cost figure use **USD** or the four-way token split / cache-hit ratio (the
   `workflow-insights` skill reads these from the logs).
5. **Record-only.** Findings are written down; they never fail a run.

---

## Index of experiments

| Experiment | Question | Status |
|---|---|---|
| [plan-vs-no-plan/](plan-vs-no-plan/) | What does using `/plan` cost in tokens/USD, does it buy back wall-clock, and what does it do to peak memory, versus building without it? | Runner + docs built; awaiting live runs |

*(Add a row here when you add an experiment folder.)*

---

## Adding a new experiment

1. Create `experiments/<slug>/` with a `README.md` (how to run) and an empty `results/`.
2. Write an `ABOUT.md` explaining what it measures and the tests it carries out — the question, the
   arms, the metrics (name the axes), the controls, the guardrails (what it can and cannot prove).
   Copy the shape of [plan-vs-no-plan/](plan-vs-no-plan/) (README = run it, ABOUT = explain it).
3. If it's runnable, add a `Run-*.ps1` that drives `tier-3-automated/Run-QATests.ps1`, reuses the
   recorded history + `New-Tier3Comparison`, and writes a saved report to `results/`; give its pure
   functions good/broken Pester tests under `tests/`.
4. Drop a `results/RESULTS-TEMPLATE.md` for recording each run-batch's findings.
5. Add a row to the index above.
