# Golden run — the recorded workflow run for Tier 2

Tier 2 (`tier-2-recorded-run/`) replays **one real end-to-end workflow run** and asserts
invariants over it — no live AI at test time. This directory holds that recording.

> **Active golden run (captured 2026-08-12).** A real **build-one-park-one** run (`minimal-concurrent`:
> Notes built + merged, Tasks planned + parked at `READY-TO-BUILD`) is committed here as
> **`repo.bundle`** (~900 KB — carries the `generated-docs/` tree + git history) — see `meta.json`.
> **All three Tier-2 blocks now gate:** the **artifact** invariants (state schema, role+AC per story,
> decision trail, absence canaries), the **git-topology** invariants (`epic/<slug>` branch,
> merge-into-main, commit count ≥ stories), **and the `/plan` parked-epic** invariants (parked story
> list, no `epic/tasks` branch, no `plan/tasks` worktree, on-`main`-via-`docs(plan)`, `dependsOn`).
> It replaced the earlier design-taskboard golden run; the design-specific *content* traces gate
> separately via `fixtures/design-capture/` + the `tier-1-unit/design/*replay*.test.ts` files.

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

`capturedAt` records when the run was captured, so a reviewer can tell at a glance whether
the recording predates a workflow change and should be re-recorded (the "When to re-capture"
routine below). It is metadata only — there is no automated freshness assertion.

## What Tier 2 checks (once this exists)

- At least one `epic/<slug>` branch exists; the epic reached `main` via a **merge commit**,
  not a direct push.
- Each story in a built epic has its own `feat(<slug>/story-<N>): …` commit, and the epic
  branch's commit count is at least the story count.
- Every `state.json` validates against the epic-state schema; every recorded phase is a real
  `EPIC_PHASE` (graded against the recording's own `epic-state.js` — catches retired stage names).
- Every story has a non-empty role and an **Acceptance Criteria** section; each built epic has a
  decision trail (non-empty `journal.md`, or the design digest's "Your Decisions").
- Each story in a built epic has a matching `web/e2e/epic-<slug>-story-<N>-*.spec.ts` that
  carries a live `test(...)` or a justified `test.fixme(...)`.
- **Absence canaries:** no `context/telemetry.ndjson`, no `specs/project-brief.md`; and — when
  the recording carries `.claude/` — no retired `code-reviewer` agent and no `.claude/logs/`.
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

> **Note.** The active run above is a **`repo.bundle`**, so it carries full git topology and the
> git-topology invariants run (not skip). The real per-story commit subject is `feat(<slug>/story-<N>)`
> (e.g. `feat(notes/story-1)`), and the Tier-2 invariants assert exactly that subject, a merge-into-main,
> and commit **count ≥ stories**. The design-specific *content* traces (digest ready, decisions
> preserved, navigability) gate separately via `fixtures/design-capture/` + `tier-1-unit/design/*replay*.test.ts`.
