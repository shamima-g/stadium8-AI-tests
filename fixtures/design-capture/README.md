# Design-capture fixture (build-from-design #14/#15)

Committed artifacts from a **real live run** of the `design-taskboard` benchmark (the build-from-
design Tier-3 scenario), so the deterministic design traces are **replayable and gating** without
re-running an AI. Replayed by [`../../tier-1-unit/design/design-capture-replay.test.ts`], which
runs the real `helpers/design-digest.ts` functions over these files.

- **Captured:** 2026-08-11, model Opus, template = post-v1.2.0 cut (s8-129 test line).
- **Build run:** two epics (sign-in, task-board) then a design-update epic; app built from the
  design in `documentation/design/` (no written spec). These committed digests + diff are the
  gating record; the Tier-2 golden run is a separate `/plan` run (see `../golden-run/`).

## Files

This folder holds three real captures, each with its own replay test:

| Path | Capture | Replay test |
|---|---|---|
| `digest.*.md` + `phase2.changed-paths.txt` | **design-taskboard** (#14/#15): read-back, decisions, scoped update | `tier-1-unit/design/design-capture-replay.test.ts` |
| `contact/` (`digest.md`, `app-routes.txt`) | **contact-form** (AC3 navigability): 1 screen → `/` | `tier-1-unit/design/contact-navigability-replay.test.ts` |
| `feedback/` (`api-spec.yaml`, `endpoints.ts`, `digest.md`) | **feedback-api** (AC4 real backend): exact API paths | `tier-1-unit/design/feedback-api-replay.test.ts` |

### design-taskboard files

| File | What it is |
|---|---|
| `digest.intake.md` | the digest right after Intake read the design (screens + palette + Uncertainties; Your Decisions still empty) — for #14 |
| `digest.before-update.md` | the digest after the task-board epic (7 recorded decisions) — the #15 pre-update baseline |
| `digest.after-update.md` | the digest after the design update was applied (decisions preserved + the blue-over-purple resolution) — the #15 after |
| `phase2.changed-paths.txt` | `git diff --name-only <task-board-merge>..HEAD` — the files the scoped rebuild touched, for #15 |

## Verdicts — all six rule ids PASS

Deterministic (asserted by the replay test):
- `design-digest-written` — `digestReadyForIntake(intake)` ok: 3 real screens, real palette `#2563eb`, all sections.
- `design-uncertainties-surfaced` — intake Uncertainties non-empty, incl. the deliberately-open due-date format.
- `design-update-scoped` — the changed screen routes are Board + Task detail only; **Settings untouched**.
- `design-decisions-preserved` — all 7 prior decisions survive the re-read; digest reconciled in place; a new decision records blue `#2563eb` kept over the update's purple `#7c3aed`.

Live cores (eyeballed in the session — recorded here, not machine-assertable):
- `design-readback-confirmed` — Intake read the design back (screens/fields/colours/copy) and named
  what it couldn't determine (due-date format + 4 more) before building.
- `design-conflict-asks` — the workflow surfaced the purple-vs-blue conflict ("do NOT switch
  silently. Which colour should the app use?") and kept blue; commit `df566ec` "blue reaffirmed
  over update purple"; built `globals.css` stayed `#2563eb`.
