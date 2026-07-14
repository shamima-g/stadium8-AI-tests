# Golden run — the recorded workflow run for Tier 2

Tier 2 (`tier-2-recorded-run/`) replays **one real end-to-end workflow run** and asserts
invariants over it — no live AI at test time. This directory holds that recording. Until
it's captured, the Tier-2 invariants **skip visibly** (a notice prints; they never show a
vacuous green).

## What to capture

Drive the make-believe **Team Task Manager** scenario through the real workflow once, on a
faithful target (prefer the release repo `Digiata/Stadium-8`, or a `dry_run` publish — not
the dev arrangement), building **at least one epic through to a merge into `main`**
(INTAKE → PLAN → BUILD → EPIC-END → MANUAL-TEST → COMPLETE-ON-BRANCH → COMPLETE). Then drop
the result here in **one** of these two forms.

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

## When to re-capture

Re-record after any change that alters how the workflow runs (orchestrator rules, agent
prompts, settings, hooks). Run the Tier 3 walkthrough once and refresh the bundle here.

> **Git-ignored by default.** A real bundle can be large; this directory's contents (except
> this README) are git-ignored — the recording is a local/CI artifact, not committed source.
> Remove the ignore entry if your team decides to commit a small golden bundle.
