# Proof — Phase-3 Tier-2 `/plan` parked design-update (#200, #201)

**Captured:** 2026-10-02 · **Benchmark:** `design-taskboard` · **Template:** release-shaped checkout
**Golden slot:** `fixtures/golden-runs/plan-design-update/` · **Tests:** `tier-2-recorded-run/plan-scope/plan-design-update.test.ts`

Live capture = intake + `/plan` (no build, no merge, no GitHub — `/plan` ran on a bare local remote).
Scenario: add a **Priority** field (the saved fact), rebuild the Board/Task-detail screens to a **pink**
design (`#ec4899`), **pink wins** over the recorded blue (`#2563eb`) as a held decision.

## Result: 4 / 4 passed

See [`vitest-output.txt`](vitest-output.txt) (full run). The four invariants:

| Check | What it proves | Evidence |
|---|---|---|
| HEAD = main | the capture is read from the integration branch | `vitest-output.txt` |
| **#200 (AC2)** | the approved **Priority** fact landed on `main` at plan time | [`snapshot-project.md`](snapshot-project.md) — Task model + Task-detail now list `priority (Low / Medium / High)`; [`snapshot-main-commits.txt`](snapshot-main-commits.txt) — `chore(project): add Priority field …` |
| **#201 (AC5) state** | the parked epic carries `parkedDesignUpdate:true` + a fingerprint + a held decision | [`snapshot-parked-state.json`](snapshot-parked-state.json) — decision: *"Primary colour is pink #ec4899 (the new design wins over the earlier blue #2563eb decision)"* |
| **#201 (AC5) design off main** | no design files were staged to `main` at plan time | checked over the `docs(plan)` commit's file list |

## Snapshots in this folder
- `vitest-output.txt` — the passing test run (regenerate with `npx vitest run tier-2-recorded-run/plan-scope`).
- `snapshot-main-commits.txt` — `main` history (the `chore(project)` fact commit + the `docs(plan)` park commit).
- `snapshot-parked-state.json` — the parked epic's `state.json` (the three fields + the held pink decision).
- `snapshot-project.md` — `project.md` on `main` (shows the Priority fact landed).

## Reproduce
`pwsh -File tier-3-automated/capture-plan-design-update.ps1 -TemplateRoot <checkout> -Phase setup|intake|plan|freeze`
(intake and plan are live; each prints a sign-in/cost notice first). The freeze phase refuses to bundle
unless the fact reached `main` and a held decision exists — so this proof cannot come from a broken run.
