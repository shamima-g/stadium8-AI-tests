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
- **Finding (RESOLVED):** the single COMPLETE epic produced **no `journal.md`** — a minimal/design-driven
  epic keeps its decisions in the design digest instead. Tier-2's journal invariant assumed every built
  epic writes one. **Refined:** the invariant now accepts a decision trail in *either* a non-empty
  `journal.md` *or* the design digest's "Your Decisions" (design-driven runs), while still failing an
  empty journal or an epic with no trail at all — see `helpers/design-digest.ts` `epicHasDecisionTrail`,
  `tier-1-unit/design/decision-trail.test.ts` (good/broken), and the updated invariant in
  `tier-2-recorded-run/recorded-run.test.ts`.

## Run 3 — `feedback-api-design` (AC4 real backend) · 2026-08-12 · Opus · post-v1.2.0 cut · **PASS**

Design + standalone API (single-page feedback wall, GET/POST `/api/v1/messages`), one epic
(`feedback-wall`), one story. The build produced the real-backend artifacts, so TG-31 gates.

| Rule id | Verdict | Evidence |
|---|:--:|---|
| `design-digest-written` / `-uncertainties-surfaced` | ✅ | digest is a filled read-back; flagged pagination as unspecified |
| **`exact-api-paths` (TG-31, AC4)** | ✅ | `generated-docs/specs/api-spec.yaml` (`/api/v1/messages`) + `web/src/lib/api/endpoints.ts` both produced; `findInventedPaths` = 0 — every client path matches the spec exactly |
| real-backend, shared client | ✅ | `endpoints.ts` (auto-generated from the spec) calls `get`/`post` from `@/lib/api/client` at `/api/v1/messages`; **no raw `fetch`** outside the shared client; not a stand-in data layer |

Note: a `web/src/mocks/` dir exists (MSW test doubles of the *real* endpoints — the app's data path
still goes through `endpoints.ts` → the shared client → `/api/v1/messages`, so it's real backend
calls, mocked only at test time). Artifacts: `fixtures/design-capture/feedback/` (spec + endpoints);
replay: `tier-1-unit/design/feedback-api-replay.test.ts`.

---

**All AC coverage complete.** AC1/AC2 (record-only rules), AC3 (navigability + golden run), AC4
(this run), AC5/AC6 (hardened checks) are done. See `DESIGN-COVERAGE.md`.

## Future — AC5 "truly unusable" live case

The `design-taskboard` benchmark now ships `frontend/docs/design/brand-export.bin` — a garbled
binary blob the design-interpreter **cannot** decode — referenced from `design-notes.md` as the
brand logo. On the **next** design-taskboard re-run, a correct workflow must **surface** it under
Uncertainties (e.g. "couldn't read brand-export.bin — re-supply in a readable format"), not silently
ignore it. That exercises AC5's genuinely-unusable path live (the synthetic good/broken already
covers it deterministically via `surfacesUncertainty` in `tier-1-unit/design/design-traces.test.ts`).
Record the verdict here when that re-run happens.
