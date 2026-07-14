# AI-tests — Test Suite for the Stadium 8 Workflow Template

Tests the **template itself** — the scripts, hooks, JSON state, and agent/command
definitions under `.claude/` that make the epic-branch workflow run. It does **not**
test a feature someone builds with the template, and it is **not** the per-story QA
that happens *inside* the workflow. It's the safety net around the workflow's own
plumbing.

For the full strategy, layout, and reconciliation notes, see
[workflow-tests.md](workflow-tests.md). For what the workflow actually does, see
[HOW-IT-WORKS.md](HOW-IT-WORKS.md).

> **Historical docs.** `TEST-GUIDE.md`, `TEST-INPUTS.md`, and `TEST-STRATEGY.md`
> describe the retired 4-phase workflow and are obsolete — kept only for reference.
> `workflow-tests.md` is the current source of truth.

## Template compatibility

This suite is pinned to the **epic-branch** generation of the template and breaks
loudly against a different one. It currently targets:

- **Workflow model:** the unit of work is the **epic**, built on its own
  `epic/<slug>` branch, through **INTAKE → PLAN → BUILD → EPIC-END → MANUAL-TEST →
  COMPLETE-ON-BRANCH → COMPLETE**.
- **Requirements files:** shared `generated-docs/project.md` (on `main`) + a per-epic
  `generated-docs/epics/<slug>/brief.md`. There is no single `project-brief.md`.
- **State:** per-epic `generated-docs/epics/<slug>/state.json` (schema single-sourced
  from `epic-state.js` → `EPIC_PHASES`). There is no repo-wide `workflow-state.json`
  in the current model (only legacy projects have one, which triggers
  `/migrate-legacy`).
- **Quality checks:** four — does-it-work (manual) + safe, sound, tests (automatic).
  No performance gate, no Gate 6, no spec-compliance watchdog.
- **Removed (not tested):** the telemetry ledger and `.claude/logs/*.md`, the
  `code-reviewer` agent, `transition-phase.js`/`detect-workflow-state.js`/
  `validate-phase-output.js`, and the 4-phase `workflow-state` schema.

If a large batch of tests fails at once after a template bump, suspect a
model/version mismatch before treating it as a regression.

## Tiers

| Tier | Folder | Runs in CI? | Needs a live AI? | Purpose |
|---|---|---|---|---|
| 1 | `tier-1-unit/` | Yes | No | Pure automation — scripts, hooks, schemas, doc-lint, artifact-lint, git machinery |
| 2 | `tier-2-recorded-run/` | Yes | No (record once) | **Planned** — invariants over a recorded run's git history + `generated-docs/` (replaces the retired telemetry tier) |
| 3 | `tier-3-pointer.md` | No (manual) | Yes | Pointer to the human walkthrough — the final word |

## Running

```bash
cd AI-tests
npm install

npm test            # standard run — builds the Markdown report, exits non-zero on failure
npm run test:raw    # Vitest only (Tier 1 today), no report wrapper
npm run test:tier1  # Tier 1 only
npm run test:pester # PowerShell hook tests (Windows — requires Pester v5, see below)
npm run test:report # run + write a report to TestResults/ and open it
npm run test:full   # also exercise the web build, the browser specs, and the checks
```

There is **no `test:tier2`** — the recorded-run tier isn't built yet.

### Running standalone / against another checkout

This folder is self-contained (its own `package.json`, `node_modules`,
`vitest.config.ts`, `tsconfig.json`). It reaches the template under test through a
single resolved path (`helpers/target.ts`), defaulting to the parent repo and
overridable with `REPO_ROOT`:

```bash
REPO_ROOT=/path/to/some-stadium8-repo npm test
```

If no `.claude/` template is found at the target, the template-dependent suites
**skip** with a one-time notice while the template-independent ones still run — so a
carried copy never shows a vacuous green.

### Pester v5 prerequisite (one-time, Windows only)

The PowerShell hook tests require Pester v5 (Windows ships v3.4, which doesn't
understand v5 syntax). Install side-by-side under the current user:

```powershell
pwsh -Command "Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.0"
```

`npm run test:pester` forces the v5 import so the bundled v3.4 doesn't take precedence.

## Conventions

- **PASS path AND FAIL path** — every `describe` has both an `it('PASS: …')` and an
  `it('FAIL: …')`, proving the check distinguishes good from bad.
- **Independent** — each test owns its setup/teardown; no shared state, no order
  dependence.
- **Isolated** — each test works in its own `os.tmpdir()` project
  (`createTempProject()`); tests that exercise branch/merge behaviour wrap it with
  `gitSandbox()`. Never the real repo, never a real branch.
- **Fast** — Tier 1 targets < 100 ms/test; schema/state checks < 10 ms.
- **Cited cleanup** — `afterEach` names the rollback recipe used
  (`rollback(root, 'RB-N')`).

## Folder map

```
AI-tests/
├── helpers/                  Reusable helpers
│   ├── temp-project.ts       createTempProject() — per-test tmpdir
│   ├── git-sandbox.ts        gitSandbox() — git init + branch/commit/merge helpers
│   ├── state-fixtures.ts     seedEpicState / seedProjectMd / seedEpicPlan / seedStoryFile / seedLegacyState
│   ├── checkpoint-fixtures.ts loadCheckpoint() — CP-0..CP-5 epic-branch starting states
│   ├── manifest-fixtures.ts  seedManifest() — intake-manifest.json
│   ├── rollback.ts           RB-0..RB-7 cleanup recipes
│   ├── run-script.ts         runScript() — spawn a .claude script, capture output + exit code
│   ├── snapshot.ts           normalise() — stable snapshot comparisons
│   ├── target.ts             resolves the .claude/ template under test (REPO_ROOT-aware)
│   └── schemas/              intake-manifest schema
├── fixtures/
│   ├── scenarios/            Team Task Manager + variants
│   └── checkpoints/          CP-N tarballs (optional; synthesised if absent)
├── tier-1-unit/
│   ├── scripts/              one file per .claude/scripts/*.js
│   ├── hooks/                Node hooks + PowerShell hooks (Pester)
│   ├── consistency/          frontmatter + cross-file references
│   ├── schemas/              JSON schema validation
│   └── artifact-lint/        rule checks for generated web/src/ code
├── tier-3-pointer.md
├── vitest.config.ts
├── package.json
└── README.md
```

## Adding a test

1. Pick the right tier folder.
2. Create `<thing-under-test>.test.ts` (one file per thing under test).
3. Write both a PASS and a FAIL path for every behaviour.
4. Use `createTempProject()` (and `gitSandbox()` for branch/merge behaviour) — never
   write to the real repo.
5. Cite the rollback ID (`rollback(root, 'RB-N')`) in `afterEach`.
