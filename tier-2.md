# Tier 2 — invariants over a recorded run

> This is one of the three tier files. Everything that is shared across all tiers —
> the rules every test follows, the surface-area map, the good-and-broken discipline,
> the helpers and rollbacks, the fixtures, version handling, the maintenance routine,
> and the coverage picture — stays in the hub: [workflow-tests.md](workflow-tests.md).
> This file covers **Tier 2 only**.

> **Status: active — a golden run is captured and all invariants gate.** The harness
> (`tier-2-recorded-run/recorded-run.test.ts` + `helpers/golden-run.ts`) replays the
> committed `fixtures/golden-run/repo.bundle` (a build-one-park-one `minimal-concurrent`
> run): the artifact, git-topology, **and** `/plan` parked-epic invariants all run —
> 14/14, none skipping. The design remains capture-driven, so with no fixture present the
> invariants **skip visibly** (never a vacuous green): the artifact invariants need a
> `generated-docs/` tree, the git-topology and parked-epic invariants additionally need a
> `repo.bundle`.

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

- **At least one `epic/<slug>` branch, merged not pushed** — the recording carries a
  correctly-named `epic/<slug>` branch, and the finished work reached `main` through a
  **merge commit**, not a direct push. (Tier 2 asserts a branch *exists* and merged; it
  does not assert one-branch-per-epic uniqueness — that cardinality is a Tier-3 judgement.)
- **A commit per story, correctly named** — each story in a built epic has its own commit
  with the subject `feat(<slug>/story-<N>): …` on the epic branch. (Tier 2 asserts that
  per-story subject *and* that the branch's commit count is at least the story count; it does
  not read commit bodies — the decision trail is checked via `journal.md`, below.)
- **The state file is well-formed, with real phases** — `state.json` validates against the
  schema, and every recorded `phase` is a current `EPIC_PHASE` (no retired stage names),
  graded against the recording's *own* `epic-state.js`. (Phase *ordering* over a run — no
  skips/rewinds — has no phase-history to read from a single `state.json`, so it stays a
  Tier-3 judgement.)
- **Every story is complete on paper** — each story file has a non-empty role and an
  **Acceptance Criteria** section (a heading or a checklist), not merely any bullet.
- **The decision trail is real** — each built epic records its decisions: a non-empty
  `journal.md`, or — for a design-driven run — the design digest's "Your Decisions" (a minimal
  design epic keeps its decisions there rather than a per-epic journal; a present-but-empty journal
  still fails). *(The `architecture.md` registry and the pre-merge "please double-check" list are
  checked in Tier 1 / Tier 3, not here — Tier 2 asserts only the decision trail.)*
- **The app tests line up with the stories** — every story in a built epic has a matching
  spec `web/e2e/epic-<slug>-story-<N>-*.spec.ts`, and that spec is real: it carries a live
  `test(...)` or a justified `test.fixme(...)`, never an empty file. (The stricter
  routable→live / non-routable→`test.fixme()` distinction is a Tier-1 rule — §9.)
- **The absence canaries** — none of the retired machinery has crept back: no telemetry
  ledger (`context/telemetry.ndjson`) or `specs/project-brief.md` in the tree; and, when the
  recording carries its `.claude/`, no retired `code-reviewer` agent (superseded by
  `code-review-runner`) and no `.claude/logs/` session-log directory. *(There is no automated
  freshness canary — re-recording after a workflow change is the manual routine below.)*
- **The parked-epic (`/plan`) traces** — an epic planned ahead and parked at
  `READY-TO-BUILD` already carries its **approved story list** (on disk *and* in
  `state.json`), has **no `epic/<slug>` branch** and started **no build** (the whole point
  of parking), left **no `plan/<slug>` branch** behind, is reachable on `main` via a
  `docs(plan)` commit, and — if it records a `dependsOn` — that dependency is well-formed. Only these
  deterministic *traces* live in Tier 2; the `/plan` behaviours with an irreducible live
  core (the story approval firing, the mid-flow redirect, the merge-block across two live
  sessions) stay in Tier 3 — see [tier-3.md](tier-3.md). The block is
  **feature-detected off the recording**: a run with no parked epic (an older version, or a
  capture that skipped `/plan`) **skips visibly**, it never fails.

> **When to re-record.** The recording is a committed fixture. Re-record it after any
> change that alters how the workflow runs (orchestrator rules, agent prompts,
> settings, hooks): run the Tier 3 walkthrough once and copy the fresh bundle and tree
> over the old one.
