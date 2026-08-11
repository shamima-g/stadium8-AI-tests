# Staged golden run — build-from-design (#14/#15)

A real captured run of the `design-taskboard` benchmark (3 epics: sign-in, task-board,
design-update-board-detail), **staged** here for a later merge into the active Tier-2 golden run.

Kept as **docs-only** to stay small: the `git bundle` was omitted (it was ~1 MB, dominated by
`web/package-lock.json`, and nothing reads it yet). The design-specific traces don't need it, and
this run isn't Tier-2-clean anyway (see below), so a bundle is best **re-captured at promotion**.

- `generated-docs/` — the run's generated-docs tree (design digest, epic state, plan, stories,
  reports). This is the loader's docs-only fallback form (artifact invariants only; no git topology).
- `meta.json` — provenance (incl. the Phase-2 baseline commit, so a bundle can be regenerated).

## Why this is staged, not active

`helpers/golden-run.ts` loads the active run from `fixtures/golden-run/generated-docs/` (or
`repo.bundle`) at the **folder root**. This capture is one level down, so the loader ignores it and
**Tier-2 keeps skipping** — deliberately. This run is also **not yet Tier-2-clean**: its commit
subjects are `feat(<slug>/story-N)`, but the Tier-2 "one commit per story" invariant expects
`feat(epic-N-story-M)`.

## To promote it (later)

1. Reconcile the per-story-commit invariant in `tier-2-recorded-run/` against this run's real
   subject format (or re-capture with the expected format).
2. If git-topology checks are wanted, re-capture a `repo.bundle` from the build run (its baseline
   commit is in `meta.json`) and drop it — plus `generated-docs/` — at `fixtures/golden-run/` root.
3. Run Tier 2 and confirm the invariants pass; feature-detected checks (parked-epic) skip since
   this run has no `/plan`.

The **design-specific** traces are already gating without promotion — see
`fixtures/design-capture/` + `tier-1-unit/design/design-capture-replay.test.ts`.
