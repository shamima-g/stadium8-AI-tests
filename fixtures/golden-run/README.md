# Golden run — the recorded workflow run for Tier 2

Tier 2 (`tier-2-recorded-run/`) replays **one real end-to-end workflow run** and asserts
invariants over it — no live AI at test time. This directory holds that recording.

> **Active golden run (captured 2026-08-11).** A real build-from-design run (`design-taskboard`,
> 3 epics) is committed here as **`repo.bundle`** (~1 MB — carries both the `generated-docs/` tree
> and the git history) — see `meta.json`. So Tier-2's **artifact invariants** (state schema, role+AC
> per story, decision trail, absence canaries) **and its git-topology invariants** (`epic/<slug>`
> branches, merge-into-main, commit count ≥ stories) **both gate**. Only the **`/plan` parked-epic**
> invariants still skip: this run has no `/plan`-parked epic — capture a `/plan` run (e.g.
> `minimal-concurrent`) to activate them. A skipped block **skips visibly** — never a vacuous green.

## What to capture

Drive the make-believe **Team Task Manager** scenario through the real workflow once, on a
faithful target (prefer the release repo `Digiata/Stadium-8`, or a `dry_run` publish — not
the dev arrangement), building **at least one epic through to a merge into `main`**
(INTAKE → PLAN → BUILD → EPIC-END → MANUAL-TEST → COMPLETE-ON-BRANCH → COMPLETE), **and
planning one more epic ahead with `/plan`** — parked at `READY-TO-BUILD` and left unbuilt.
The parked epic activates the Tier-2 parked-epic invariants (below); without one they skip.
Then drop the result here in **one** of these two forms.

### Preferred — a git bundle (carries branch topology + history)

From the repo root of the captured run, after the epic has merged to `main`:

```bash
git bundle create /path/to/AI-tests/fixtures/golden-run/repo.bundle --all
```

The bundle must contain `main` (with the merged epic under `generated-docs/epics/<slug>/`)
and, ideally, the `epic/<slug>` branch and its per-story commits.

### Fallback — a plain generated-docs tree (artifact checks only)

Copy the run's `generated-docs/` tree into `fixtures/golden-run/generated-docs/`. The
artifact invariants run; the git-topology checks (one-branch-per-epic, one-commit-per-story,
merge-not-direct-push) skip because there's no history.

### Optional — meta.json

```json
{
  "epicSlug": "task-browsing",
  "capturedAt": "2026-07-09T00:00:00.000Z",
  "templateVersion": "…",
  "scenario": "Team Task Manager"
}
```

`capturedAt` powers the freshness canary (warns if the recording is older than the
orchestrator rules / settings it should reflect).

## What Tier 2 checks (once this exists)

- One branch per epic named `epic/<slug>`; the epic reached `main` via a **merge**, not a
  direct push.
- One commit per story, each with a descriptive subject.
- Every `state.json` validates against the epic-state schema; recorded phases are all real
  `EPIC_PHASES` (no retired four-phase names).
- The epic plan covers the request; every story has a role and acceptance criteria; the
  journal has entries.
- Routable stories have a live Playwright spec; non-routable ones use `test.fixme()` with a
  reason.
- **Absence canaries:** no `telemetry.ndjson`, no `.claude/logs/`, no `project-brief.md`, no
  performance gate, no `code-reviewer`.
- **Parked epics (`/plan`):** an epic parked at `READY-TO-BUILD` carries its approved story
  list (on disk + in `state.json`), has **no `epic/<slug>` branch** and started no build,
  left **no `plan/<slug>` worktree**, is reachable on `main` via its `docs(plan)` commit, and
  records `dependsOn` when blocked. Feature-detected — with no parked epic in the recording,
  these skip. (The live-only halves — approval firing, mid-flow redirect, two-session
  merge-block — stay in Tier 3.)

## When to re-capture

Re-record after any change that alters how the workflow runs (orchestrator rules, agent
prompts, settings, hooks). Run the Tier 3 walkthrough once and refresh the bundle here.

> **Bundles are git-ignored by default.** A real `repo.bundle` can be large; only the small
> docs-only `generated-docs/` (+ `meta.json`) is committed here, via a scoped `.gitignore`
> exception. Drop a `repo.bundle` to activate the git-topology invariants — it stays local unless
> you add an exception for it too.

> **Note.** The active run above (docs-only) does not carry git topology. When the §7 doc mentions
> `feat(epic-<N>-story-<M>)` commit subjects, that's descriptive — the Tier-2 git-topology invariants
> assert commit **count ≥ stories** and a merge-into-main, not a subject format. The
> design-specific *content* traces (digest ready, decisions preserved, navigability) gate separately
> via `fixtures/design-capture/` + `tier-1-unit/design/*replay*.test.ts`.
