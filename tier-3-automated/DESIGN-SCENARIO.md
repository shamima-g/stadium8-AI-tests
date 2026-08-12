# Tier-3 build-from-design scenario (#14 / #15) — spec + capture checklist

The build-from-design feature is deliberately AI-driven (the workflow *comprehends* the design
files; it doesn't match a fixed format), so its two behaviours are Tier-3 **live** runs. Each has a
**deterministic trace** (asserted cheaply and repeatably) and an **irreducible live core** (only a
real run can confirm) — the same three-tier split the `/plan` scenarios use (see
`workflow-tests.md` §8).

- Deterministic halves are **already built** and green: `helpers/design-digest.ts` +
  `tier-1-unit/design/design-traces.test.ts` (good/broken over synthetic scaffolds and the real
  digest template).
- What remains is a **live capture**: run the `design-taskboard` benchmark, then bring the
  artifacts back so the deterministic traces run over the real run, and note the two live cores.

Not yet wired: a `-Scenario design` in `Run-QATests.ps1` / `live-driver.ps1`. Until it is, drive
the run manually (or via the existing autonomous driver pointed at this benchmark). The steps below
are the contract that wiring must satisfy.

## Rule ids (record-only, like `/plan`)

| Behaviour | Phase | Deterministic trace (auto) | Live core (eyeball) | Rule id |
|---|:--:|---|---|---|
| Design is the ONLY input (no written spec) (AC1) | 1 | precondition: `documentation/` holds only the design (no hand-written spec) and `generated-docs/specs/` has no author-supplied spec | operator confirms only the design was supplied | `design-only-input` |
| Design read into a digest | 1 | `generated-docs/design/digest.md` exists and `digestReadyForIntake()` is `ok` (real screens + palette + all sections + ≥1 real Uncertainty) | — | `design-digest-written` |
| Uncertainties surfaced (AC5) | 1 | `digestReadyForIntake` requires ≥1 **real** Uncertainties item; `surfacesUncertainty(digest, /due-date/)` — the intake digest names what it couldn't determine, not just an empty heading | — | `design-uncertainties-surfaced` |
| Read-back confirmed at Intake | 1 | — | the workflow **showed** the screens/colours/copy read-back and asked to confirm **before** building | `design-readback-confirmed` |
| No manual intervention (AC2) | 1–2 | — | operator confirms the run reached a running app via **normal approvals only** — no renaming files, fixing mismatches, or hand-writing code | `design-no-manual-intervention` |
| Update rebuilds only named screens | 2 | `changesScopedTo(gitDiffPaths, [Board, Task detail])` is `ok` — Settings untouched | — | `design-update-scoped` |
| Prior decisions survive the re-read | 2 | `decisionsPreserved(digestBefore, digestAfter)` is `ok` (sign-in + blue-primary decisions still present) | — | `design-decisions-preserved` |
| A design conflict asks which wins | 2 | — | the purple-vs-blue conflict **stopped and asked**; it did not silently switch | `design-conflict-asks` |

> `design-only-input` and `design-no-manual-intervention` are record-only (AC1/AC2). `design-only-input`
> could later become a deterministic precondition assert over the captured tree; `design-no-manual-intervention`
> stays an operator eyeball (nothing in the run's traces reveals an out-of-band hand-edit).

## Decisions needed before the run

1. **Template under test** — which template the live build runs against (the current working
   template, or a `-Target`/`-Ref`). The recording must match what's being tested. (The
   `C:\TestsArchives\stadium8-tests\10-08-2026` snapshot is static — it's the deterministic-test
   target via `REPO_ROOT`, not something you build against live.)
2. **Model + budget** — opus vs sonnet; it's a full real build (real tokens/time).

## Run — Phase 1 (#14: build from the design)

1. Scaffold a fresh project (the runner's Setup). The benchmark drop lands
   `benchmark-files/design-taskboard/frontend/docs/*` into `documentation/` (so
   `documentation/design/` holds `mockup.html`, `tokens.css`, `design-notes.md`) and
   `answers.json` → `TIER3-ANSWERS.json`.
2. **Precondition `design-only-input`:** confirm `documentation/` holds only the design (no
   hand-written spec) — the requirements come from the design, not a written doc. Record pass/fail.
3. Run `/start`. For every approval/choice, use `TIER3-ANSWERS.json` (see its `intake` and
   `designReadback` blocks).
4. **Eyeball `design-readback-confirmed`:** did Intake show the design read-back (screens, fields,
   colours, copy) *and* name what it couldn't determine (the due-date format), and ask to confirm
   before building? Record pass/fail + a one-line note.
5. Build one epic through to a merge on `main`.
6. **Eyeball `design-no-manual-intervention`:** confirm you reached a running app via normal
   approvals only — you did **not** rename files, fix a mismatch by hand, or write code. Record
   pass/fail + a note.

## Run — Phase 2 (#15: update the design)

1. **Snapshot** the digest first: copy `generated-docs/design/digest.md` to
   `digest.before.md` (needed for the `design-decisions-preserved` trace).
2. Replace the design: copy `benchmark-files/design-taskboard/update/docs/design/*` over
   `documentation/design/*`.
3. Start ONE ordinary piece of work with the instruction from `answers.json` →
   `designUpdate.instruction`: *"Rebuild the Board and Task detail screens to match my updated
   design. Leave Settings as it is."*
4. **Eyeball `design-conflict-asks`:** the update's `tokens.css` sets a purple primary that
   contradicts the recorded blue decision — did the workflow **stop and ask** which wins (answer:
   keep blue) rather than silently switch? Record pass/fail + a note.
5. Let it plan → build → review → merge the scoped change.

## Bring back (the capture)

Hand these to the QA suite so the deterministic traces run over the real run:

- [ ] `git bundle` of the built repo (all branches + `main`), **or** the whole working tree.
- [ ] `generated-docs/design/digest.md` (final) **and** `digest.before.md` (the Phase-1 snapshot).
- [ ] The list of files changed by the Phase-2 rebuild (`git diff --name-only <phase1-merge>..HEAD`).
- [ ] The four eyeballed/precondition verdicts: `design-only-input`, `design-readback-confirmed`,
      `design-no-manual-intervention`, `design-conflict-asks` (pass/fail + note each).

## Then (QA side)

The deterministic traces are asserted by the already-built functions:
`digestReadyForIntake` / `decisionsPreserved` (over `digest.before.md` vs the final digest) /
`changesScopedTo` (over the Phase-2 diff, allowed = Board + Task-detail paths). Fold the run into
the Tier-2 golden-run fixture so these become replayable, gating invariants — and file the two live
cores as record-only, exactly as the `/plan` scenarios do.
