# Tier 2 — invariants over a recorded run

> This is one of the three tier files. Everything that is shared across all tiers —
> the rules every test follows, the surface-area map, the good-and-broken discipline,
> the helpers and rollbacks, the fixtures, version handling, the maintenance routine,
> and the coverage picture — stays in the hub: [workflow-tests.md](workflow-tests.md).
> This file covers **Tier 2 only**.

> **Status: scaffolded; skips until a golden run is captured.** The harness is built
> (`tier-2-recorded-run/recorded-run.test.ts` + `helpers/golden-run.ts`) — its
> invariants **skip visibly** until a real run is recorded into `fixtures/golden-run/`,
> then activate automatically. The artifact invariants run on a `generated-docs/`
> tree; the git-topology invariants additionally need a `repo.bundle`.

This is the bridge between "each script works" (Tier 1) and "needs a live AI"
(Tier 3). It reads the traces one real run leaves behind and checks the things that
only make sense across a whole epic.

**How it works:**

1. **Record once, by hand.** A person runs the workflow end-to-end for the Team Task
   Manager (see [test inputs and fixtures](workflow-tests.md#11-test-inputs-and-fixtures)), building at least one epic
   through to a merge **and planning one more ahead with `/plan`** (parked at
   `READY-TO-BUILD`, never built) so the parked-epic invariants activate. The result — a
   git bundle of the `epic/<slug>` branch, the merge into `main`, and the parked epic's
   `docs(plan)` commit, plus a copy of the `generated-docs/` tree — is saved into
   `fixtures/golden-run/`.
2. **Replay automatically.** The Tier 2 tests load that bundle and tree — no AI is
   needed at test time.
3. **Check the invariants** (all read from git + files, no AI):

- **One branch per epic, correctly named** — the recorded branch is `epic/<slug>`, and
  the finished work reached `main` through a merge, not a direct push.
- **One commit per story** — each story maps to its own commit, subject
  `feat(epic-<N>-story-<M>): <title>`, with a body recording the notable decisions.
- **The state file is well-formed and ordered** — `state.json` validates against the
  schema, and the stages it recorded never skip or go backwards.
- **The plan covers the request** — `epic-plan.md` lists the epics with dependencies
  and a coverage note accounting for every part of the request.
- **Every story is complete on paper** — each story file has a non-empty role and
  testable acceptance criteria.
- **The notebook and registry are real** — each built epic records a decision trail: a non-empty
  `journal.md`, or — for a design-driven run — the design digest's "Your Decisions" (a minimal
  design epic keeps its decisions there rather than a per-epic journal; a present-but-empty journal
  still fails). `architecture.md` registry entries are well-formed; any "please double-check" items
  exist and were floated ahead of the merge.
- **The app tests line up with the stories** — every routable story has a live
  Playwright spec (`web/e2e/epic-<N>-story-<M>-<slug>.spec.ts`); a non-routable one
  has a spec marked `test.fixme()` with a one-line reason (and that marker is **not**
  allowed on a routable one).
- **The absence canaries** — none of the retired machinery has crept back (telemetry
  ledger, session logs, a `project-brief.md`, a `code-reviewer` agent, retired stage
  names). A freshness canary warns if the recording is older than the orchestrator
  rules or `settings.json`.
- **The parked-epic (`/plan`) traces** — an epic planned ahead and parked at
  `READY-TO-BUILD` already carries its **approved story list** (on disk *and* in
  `state.json`), has **no `epic/<slug>` branch** and started **no build** (the whole point
  of parking), left **no `plan/<slug>` worktree** behind, is reachable on `main` via its
  `docs(plan)` commit, and — if blocked — recorded its `dependsOn`. Only these
  deterministic *traces* live in Tier 2; the `/plan` behaviours with an irreducible live
  core (the story approval firing, the mid-flow redirect, the merge-block across two live
  sessions) stay in Tier 3 — see [tier-3.md](tier-3.md). The block is
  **feature-detected off the recording**: a run with no parked epic (an older version, or a
  capture that skipped `/plan`) **skips visibly**, it never fails.

> **When to re-record.** The recording is a committed fixture. Re-record it after any
> change that alters how the workflow runs (orchestrator rules, agent prompts,
> settings, hooks): run the Tier 3 walkthrough once and copy the fresh bundle and tree
> over the old one.
