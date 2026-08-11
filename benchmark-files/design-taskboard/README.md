# Benchmark: `design-taskboard` (build-from-an-existing-design)

A small task-board app whose requirements come from a **design**, not a written spec. It exercises
the post-v1.2.0 build-from-design flow and backs the Tier-3 scenarios **#14** (design read-back at
Intake) and **#15** (update the design mid-project).

Unlike the spec-driven benchmarks, the screens/fields/colours/copy live in the design under
`frontend/docs/design/` (which the runner drops into `documentation/design/`):

| File | What it is |
|---|---|
| `design-notes.md` | text description of the 3 screens (Board, Task detail, Settings), fields and copy — the dependable core |
| `mockup.html` | an HTML mockup of the same screens |
| `tokens.css` | brand colours + type (primary `#2563eb`, Inter) |
| `answers.json` | gap-fillers (sign-in, data source, compliance) + the read-back confirmation + the Phase-2 update step |

The design deliberately **leaves the due-date format unspecified** so the workflow has a genuine
*Uncertainty* to surface at Intake (that's the #14 trace).

## Two phases

- **Phase 1 — #14 (build from the design).** The runner drops `frontend/docs/*` into
  `documentation/` and `answers.json` to `TIER3-ANSWERS.json`, then drives `/start`. The workflow
  reads the design, writes `generated-docs/design/digest.md`, and **reads it back at Intake** for
  confirmation (including what it couldn't determine). Build one epic to a merge.
- **Phase 2 — #15 (update the design).** After Phase 1 merges, drop the files from
  `update/docs/design/` into `documentation/design/` (replacing the originals), then start ONE
  ordinary piece of work: *"Rebuild the Board and Task detail screens to match my updated design.
  Leave Settings as it is."* The update renames a button, moves the filter, adds a Priority field —
  and its `tokens.css` sets a **purple** primary that **conflicts** with the recorded blue decision,
  so the workflow must **ask which wins** instead of silently switching.

## What to capture

Run it and bring back the artifacts listed in [`../../tier-3-automated/DESIGN-SCENARIO.md`](../../tier-3-automated/DESIGN-SCENARIO.md)
— the deterministic traces are asserted by `tier-1-unit/design/design-traces.test.ts`
(`helpers/design-digest.ts`); the two live cores (read-back shown, conflict asks) are eyeballed and
recorded.
