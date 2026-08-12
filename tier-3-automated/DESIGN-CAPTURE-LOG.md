# Design Tier-3 capture log

A durable record of the build-from-design live runs and their verdicts, so re-runs have a baseline
to compare against and the eyeball live-cores aren't lost with the session. Scenarios and their
pre-planned answers live in `benchmark-files/<name>/answers.json`; the rule ids and checklist are in
`DESIGN-SCENARIO.md`. Build-runs are throwaway local copies under `C:\TestsArchives\stadium8-tests\`
(not committed) — only the captured artifacts under `fixtures/` are.

## Run 1 — `design-taskboard` (#14 read-back + #15 update) · 2026-08-11 · Opus · post-v1.2.0 cut

Two-phase build (build from design → update design + rebuild named screens). **All six rule ids PASS.**

| Rule id | Verdict | Evidence |
|---|:--:|---|
| `design-digest-written` | ✅ | digest has 3 real screens (Board/Task detail/Settings), real palette `#2563eb`, all sections |
| `design-uncertainties-surfaced` | ✅ | 8 real Uncertainties incl. the planted due-date format |
| `design-readback-confirmed` | ✅ (live) | Intake read the design back (screens/fields/colours/copy) and named 5 things it couldn't determine, before building |
| `design-update-scoped` | ✅ | Settings untouched; changes confined to Board + Task detail (+ data/tests); story-1 "New task"→"Add task" + filter right, story-2 Priority field |
| `design-decisions-preserved` | ✅ | all 7 prior Your-Decisions survived the re-read; digest reconciled in place (44→46 items) |
| `design-conflict-asks` | ✅ (live) | surfaced purple-vs-blue ("do NOT switch silently"); kept blue `#2563eb`; commit `df566ec` "blue reaffirmed over update purple"; built `globals.css` has no `#7c3aed` |

Artifacts: `fixtures/design-capture/` (digests + phase2 diff). Promoted to the active Tier-2 golden
run at `fixtures/golden-run/generated-docs/` (docs-only).

## Run 2 — `contact-form-design` (AC3 navigability) · 2026-08-12 · Opus · post-v1.2.0 cut

A small single-page contact form (1 epic, 1 story, 1 screen at `/`), to prove navigability cleanly.

- `design-digest-written` ✅ · `design-uncertainties-surfaced` ✅ (flagged where the message goes — no backend, + 3 more)
- **navigability** ✅ — 1 screen "Contact" → route `/`; `unroutedScreens` empty (replayed in
  `tier-1-unit/design/contact-navigability-replay.test.ts`).
- **Finding:** the single COMPLETE epic produced **no `journal.md`** — a minimal/design-driven epic
  may keep its decisions in the design digest instead. Tier-2's journal invariant assumes every built
  epic writes one; that's why this run wasn't used as the golden run (design-taskboard, which has
  journals, was). Candidate Tier-2 refinement: require the journal only when the epic recorded decisions.

## Run 3 — `feedback-api-design` (AC4 real backend) · PENDING

Design + standalone API (GET/POST `/api/v1/messages`). Expected to produce
`generated-docs/specs/api-spec.yaml` + `web/src/lib/api/endpoints.ts`, so the TG-31 exact-path check
gates. Capture those two files after the run; the AC4 replay asserts no invented paths. *(Verdicts to
be filled in when the run completes.)*
