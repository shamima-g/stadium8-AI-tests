# Test Plan — Gaps and New Tests for the AI-tests Suite

Derived from a full inventory of `.claude/` (scripts, hooks, agents, commands,
shared, policies, schemas) cross-referenced against what the AI-tests suite covers
today. Companion to [workflow-tests.md](workflow-tests.md), which owns the strategy;
this file is the actionable backlog.

Three kinds of work appear below: **NEW** (a test that doesn't exist), **FIX** (an
existing test that's wrong against the epic-branch model), and **EXTEND** (add
assertions to an existing test). Where a script already has a co-located `.tests.js`
in `.claude/`, we do **not** duplicate it — we add only a thin AI-tests smoke plus
the cross-repo/drift guards the co-located tests can't give.

> **Status:** ✅ **Priorities 1–3 complete and Priority 4 scaffolded** (P1.1–P1.4,
> P2.1–P2.4, P3.1–P3.2, P4.1 harness). The full suite is at **252 passing, 0 failing,
> 10 skipped** (3 artifact-lint scans + 7 recorded-run invariants awaiting their
> output/fixture). P1.3 surfaced and fixed a real template bug — the shared
> `dirGlobToRegex` in `enforce-generated-doc-names.js` and `validate-generated-doc-names.js`
> never converted the `<slug>` placeholder to a wildcard, so the four epic-scoped
> filename conventions were unenforced on real epic directories. The **only** remaining
> work is capturing the golden run (a manual step — see fixtures/golden-run/README.md);
> the Tier-2 invariants activate automatically once it lands.

---

## Where coverage stands today

| Surface | Covered in AI-tests | Co-located only (`.claude/**/*.tests.js`) | No coverage anywhere |
|---|---|---|---|
| **Scripts** | collect-dashboard-data, generate-dashboard-html, import-prototype, init-preferences, quality-gates, scan-doc | epic-state (CLI + lib), migrate-legacy-state, resolve-state-path, lib/project-root | **mark-epic-complete, run-smoke-test, summarize-playwright, validate-generated-doc-names** |
| **Hooks** | bash-permission-checker, workflow-guard, inject-phase-context, inject-agent-context | enforce-generated-doc-names (co-located only) | **lib/workflow-state.ps1** (shared by 3 hooks) |
| **Consistency** | agents-frontmatter, commands-frontmatter, cross-doc-references, settings-schema, manual-verify ×3 | — | shared/*.md + policies/*.md breadth; doc-name conventions |
| **Schema** | intake-manifest | — | **per-epic `state.json`** |
| **Artifact-lint** | 5 rules (suppressions, shadcn, api-paths, roles, plain-language) | — | scans point at **retired flat paths** (bug) |

---

## Priority 1 — integrity & safety (do first)

### P1.1 — Per-epic `state.json` schema + single-source drift guard  · NEW · effort M · ✅ DONE
- **Target:** `.claude/scripts/lib/epic-state.js` (`EPIC_PHASES`, `STORY_STATUS_VALUES`,
  `E2E_STATUS_VALUES`, `HALT_STAGES`, `VALID_TRANSITIONS`, `defaultEpicState`) and the
  `state.json` it shapes.
- **Risk if untested:** this is the retired `workflow-state` schema's replacement. The
  suite currently **hand-duplicates** the phase/status enums in
  `helpers/state-fixtures.ts` (`EpicPhase`/`StoryStatus`/`E2eStatus`) with only a
  "Mirrors epic-state.js" comment — nothing stops them drifting from the template.
- **Test shape:**
  - New `helpers/schemas/epic-state.schema.ts` whose enums are **imported from**
    `lib/epic-state.js` (single-sourced, never copied) — same pattern the old
    workflow-state schema used.
  - PASS: `defaultEpicState()` output validates; the JSON that `epic-state.js --init`
    writes validates; a hand-seeded `seedEpicState()` validates.
  - PASS (drift guard): `state-fixtures.ts`'s `EpicPhase`/`StoryStatus`/`E2eStatus`
    values equal `EPIC_PHASES` / `STORY_STATUS_VALUES` / `E2E_STATUS_VALUES`.
  - FAIL: a state with a bad `phase`, a bad story `status`, or a missing `epic.slug`
    is rejected.
  - FAIL (transitions): every pair in `VALID_TRANSITIONS` is accepted and a
    not-listed pair (e.g. `PLAN → MANUAL-TEST`) is rejected.
- **Files:** `helpers/schemas/epic-state.schema.ts`, `tier-1-unit/schemas/epic-state.test.ts`.

### P1.2 — `mark-epic-complete.js`  · NEW · effort S · ✅ DONE
- **Target:** the "exact operation" that flips an epic `COMPLETE-ON-BRANCH → COMPLETE`
  after merge (`READY_PHASES = [EPIC-END, MANUAL-TEST, COMPLETE-ON-BRANCH]`).
- **Risk if untested:** a wrong phase flip or a missing `lastUpdated` stamp corrupts
  the merged-epic record the dashboard and `/status` read. No coverage anywhere today.
- **Test shape:**
  - PASS: from a `COMPLETE-ON-BRANCH` state.json, `--slug <slug>` sets `phase: COMPLETE`
    and refreshes `lastUpdated`; running it twice is idempotent (stays COMPLETE).
  - FAIL: refuses (non-zero / error JSON) when the epic is in a non-ready phase (e.g.
    `PLAN`), when `--slug` is missing, or when the state file doesn't exist.
- **File:** `tier-1-unit/scripts/mark-epic-complete.test.ts` (uses `seedEpicState`).

### P1.3 — Generated-doc-name conventions + enforcement hook  · NEW · effort M · ✅ DONE (found+fixed the <slug> glob bug)
- **Target:** `.claude/shared/generated-doc-conventions.json` (6 conventions),
  `scripts/validate-generated-doc-names.js`, and the `enforce-generated-doc-names.js`
  PreToolUse hook. All three have **zero** AI-tests coverage.
- **Risk if untested:** a mis-named/mis-located generated file slips past the write
  gate, or the JSON conventions and the enforcing code disagree silently.
- **Test shape (validator + hook):**
  - PASS: each of the 6 conventions accepts a correct epic-scoped path
    (`generated-docs/epics/<slug>/state.json`, `.../stories/story-<N>-<slug>.md`,
    `.../brief.md`, `.../journal.md`, `project.md`, `web/e2e/epic-<slug>-story-<N>-*.spec.ts`).
  - FAIL: a wrong name or wrong location is flagged by the validator (exit non-zero)
    and blocked by the hook (exit 2) — one good + one broken per convention.
  - PASS (agreement): the conventions the hook enforces are exactly those in
    `generated-doc-conventions.json` (no drift), and `naming-conventions.md` mentions
    each one.
- **Files:** `tier-1-unit/hooks/enforce-generated-doc-names.test.ts`,
  `tier-1-unit/scripts/validate-generated-doc-names.test.ts`,
  `tier-1-unit/consistency/doc-name-conventions.test.ts`.

### P1.4 — Fix artifact-lint regression paths to the epic-branch layout  · FIX · effort S · ✅ DONE
- **Target:** `tier-1-unit/artifact-lint/role-field-in-stories.test.ts` and
  `plain-language-checklists.test.ts`.
- **Risk if untested (actually mis-tested):** the regression scans point at the
  **retired flat paths** (`generated-docs/stories/`, `generated-docs/qa/`). On a real
  epic-branch project the artifacts live under `generated-docs/epics/<slug>/stories/`
  and (for manual tests) in each story file / `manual-tests.html`. So the scans skip
  trivially and never inspect the real output — a false green.
- **Test shape:** repoint the glob to `generated-docs/epics/*/stories/story-*.md` for
  the role check; repoint the plain-language scan to the current checklist home; keep
  the "skip visibly when absent" behaviour. Add a fixture proving a bad artifact under
  the *new* path is caught.

---

## Priority 2 — fill the script gaps

### P2.1 — `resolve-state-path.js` cross-check  · NEW · effort S · ✅ DONE
- **Why:** the single source of truth for "where is the active state file", relied on
  by the dashboard and all three PowerShell hooks. Co-located test exists, but the
  AI-tests suite (which the dashboard/git tests lean on) has no cross-check.
- **Shape:** PASS — `--branch epic/<slug>` → `kind: epic`, path
  `generated-docs/epics/<slug>/state.json`; `--branch main` → `kind: none`. FAIL — an
  invalid (non-kebab) slug → `status: error`/invalid; legacy `workflow-state.json` is
  **not** treated as a valid source.

### P2.2 — `summarize-playwright.js`  · NEW · effort S · ✅ DONE
- **Why:** epic-end reads its output to map failing specs back to stories; no coverage.
- **Shape:** PASS — a sample Playwright JSON report → correct pass/fail/flaky counts
  and failing specs mapped to `epic-<slug>-story-<N>`. FAIL — a malformed/empty report
  doesn't crash; `--json` stays valid JSON.

### P2.3 — `run-smoke-test.js`  · NEW · effort M · ✅ DONE
- **Why:** used by the api-connectivity agent; must keep credentials out of output.
- **Shape:** PASS — given a config, a reachable stub endpoint yields a structured
  result and the auth secret is **redacted** from stdout. FAIL — a connection refusal
  is reported as a clear error (not a crash), and no secret leaks on the error path.
  (Use a localhost stub server or injected fetch — no real network.)

### P2.4 — Extend `agents-frontmatter.test.ts`  · EXTEND · effort S · ✅ DONE
- **Why:** today it only checks `name`+`description`. `model`/`tools`/`color` are
  unvalidated for agents (the `model ∈ {haiku,sonnet,opus}` check exists only for
  commands), and `agents/README.md`'s script references aren't verified.
- **Shape:** PASS — every agent's `model ∈ {haiku,sonnet,opus}`, `tools` is a
  well-formed list, `color` present; every script named in `agents/README.md` exists
  on disk. FAIL — a bad model value / missing tools / a README-referenced script that
  doesn't exist is caught.

---

## Priority 3 — consistency breadth & the git-machinery slice

### P3.1 — `shared/` + `policies/` orphan & reference checks  · NEW · effort S · ✅ DONE
- **Why:** only `orchestrator-rules.md` is validated; the other shared docs and all
  policies are unchecked for existence, orphaning, or broken cross-links.
- **Shape:** PASS — every `.claude/shared/*.md` and `.claude/policies/*.md` is
  referenced from at least one of CLAUDE.md / an agent / a command / another shared
  doc; every policy path referenced anywhere resolves. FAIL — an orphaned policy, or a
  reference to a non-existent shared/policy file, is caught.

### P3.2 — Branch/merge git-machinery slice  · NEW · effort M · ✅ DONE
- **Why:** the ⬜ item in workflow-tests.md. The purely *behavioural* parts (does
  Claude auto-combine vs halt on a real conflict) stay Tier 3 — but the mechanical
  slice is testable with `gitSandbox`.
- **Shape:** PASS — an `epic/<slug>` branch resolves its own state; after a simulated
  merge to `main`, `mark-epic-complete` + `collect-dashboard-data` show the epic as
  merged/COMPLETE (not in-flight). FAIL — a direct commit to `main` bypassing the
  epic branch, or two epics editing the same line, is detectable (surfaced, not
  silently combined). Document what stays Tier 3.
- **File:** `tier-1-unit/git-machinery/branch-merge.test.ts` (create the folder;
  `git-sandbox.ts` already exists).

---

## Priority 4 — milestone

### P4.1 — Recorded-run Tier 2  · NEW · effort L · ✅ SCAFFOLDED (activates when the golden run is captured)
- Build `tier-2-recorded-run/` per workflow-tests.md § Tier 2: record one real
  Team-Task-Manager run (git bundle of the `epic/<slug>` branch + merge, plus the
  `generated-docs/` tree) into `fixtures/golden-run/`, then assert the invariants
  (one branch per epic, one commit per story, stage order, plan coverage, journal /
  registry / please-double-check present, routable-story specs, and the absence
  canaries). Blocked on capturing a run — schedule after P1–P3.

---

## Explicitly NOT adding (and why)

- **Wholesale duplication of co-located `.tests.js`** (`epic-state` CLI,
  `migrate-legacy-state`, `project-root`) — already covered in `.claude/`. We add only
  P1.1's drift guard and P2.1's cross-check, not full re-tests.
- **`lib/workflow-helpers.js`** — legacy, consumed only by `migrate-legacy-state.js`,
  slated for removal. Not worth new tests.
- **`lib/test-harness.js`** — it *is* the co-located test harness; testing it is
  circular.
- **`tone-guide.md`** — not an agent; no structural contract to assert.
- **Behavioural "did Claude halt / delegate / write tests first"** — unpredictable;
  belongs to the Tier 3 human walkthrough, not automated tiers.

---

## Suggested order of execution

1. **P1.1 + P1.4** together — they touch the state model and the lint paths that
   most affect confidence, and P1.1's drift guard hardens `state-fixtures.ts`.
2. **P1.2, P1.3** — the untested state/safety scripts.
3. **P2.1–P2.4** — the remaining script gaps + the frontmatter extension.
4. **P3.1, P3.2** — breadth and the git slice.
5. **P4.1** — once a golden run can be captured.
