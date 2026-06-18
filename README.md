# QA — Test Suite for the Claude Code Workflow Template

> **Naming note:** This folder is named `QA/` because it contains the quality-assurance test suite for the template infrastructure itself. **Do not confuse** this with the workflow's per-story **QA phase** (§ 9 of `CLAUDE.md`) — that phase runs inside the TDD workflow and is owned by the `code-reviewer` agent. These tests exist outside the workflow entirely; they verify the scripts, hooks, schemas, and agents that make the workflow work.

Tests the **template itself** (scripts, hooks, schemas, agent/command definitions), not a feature built on top of it. Implements the three-tier strategy in `/TEST-STRATEGY.md`.

## Template compatibility

This suite is pinned to a **specific generation of the template** and breaks loudly
when run against a different one. It currently targets:

- **Workflow model:** 4 phases — **INTAKE → PLAN → BUILD → COMPLETE**. There is no
  `DESIGN`/`SCOPE` phase and no `FRS` (feature-requirements) artifact; INTAKE's single
  Gate-1 artifact is `generated-docs/specs/project-brief.md`.
- **Scripts under test:** only those present in `.claude/scripts/` (e.g.
  `transition-phase.js`, `import-prototype.js`). Removed scripts —
  `validate-phase-output.js`, `generate-traceability-matrix.js`,
  `detect-workflow-state.js`, `generate-progress-index.js` — are no longer tested.
- **Removed features (not tested):** Gate 6 / the `spec-compliance-watchdog` agent,
  and the S8-80 manual-verification checklist flow.
- **Verified against:** `stadium-software/stadium-8` `main` as of 2026-06-16.

### Tier 2 is telemetry-based (not log-replay)

The current template emits **no `.claude/logs/*.md` session logs**, so Tier 2's old
log-replay mechanism was retired. Tier 2 now asserts over the **telemetry ledger**
(`generated-docs/context/telemetry.ndjson`) produced by the capture layer:

- `.claude/scripts/lib/telemetry.js` — append-only NDJSON event writer.
- `.claude/scripts/lib/transcript-tokens.js` — token extraction from the transcript.
- `.claude/scripts/transition-phase.js` — emits `phase_enter`/`phase_exit`.
- `.claude/hooks/telemetry.js` — emits `agent_start`/`agent_stop`/`turn_end`/`user_input`
  (**must be registered in `.claude/settings.json`** for granular/token capture).
- `.claude/scripts/generate-telemetry-report.js` — the four reports
  (`--estimate` / `--timing` / `--tokens` / `--final`) + `--write-baseline`.

If a large number of tests fail at once after a template bump, suspect a model/version
mismatch before treating them as regressions — compare against the bullets above.

## Tiers

| Tier | Folder | Runs in CI? | Needs Claude? | Purpose |
|---|---|---|---|---|
| 1 | `tier-1-unit/` | Yes | No | Pure automation — scripts, hooks, schemas, doc-lint, artifact-lint |
| 2 | `tier-2-log-replay/` | Yes | No (harvest once) | Parses `.claude/logs/*.md` and asserts tool-call order / timing invariants |
| 3 | `tier-3-pointer.md` | No (manual) | Yes | Points to `/TEST-GUIDE.md` — the authoritative live behavioural suite |

## Running

```bash
# From repository root
cd QA
npm install

# All Tier 1 + Tier 2 tests
npm test

# Watch mode
npm run test:watch

# Specific tier
npm run test:tier1
npm run test:tier2

# Run the suite AND write a Markdown run-report to TestResults/, then open it
npm run test:report
#   report-<version>-<timestamp>.md — never overwrites; keeps a history of runs.
#   Add --no-open to skip auto-opening; auto-skipped under CI.
#   Add --telemetry-root <dir> to include token + cost totals from a live workflow run.

# Specific tag
npx vitest --testNamePattern "@unit"

# PowerShell hooks (Windows only — requires Pester v5, see below)
npm run test:pester
```

### Running it standalone / against another repo

This folder is **self-contained** — its own `package.json`, `node_modules`,
`vitest.config.ts`, and `tsconfig.json`. You can carry it anywhere and run it on
its own; it installs nothing into `web/` or the repo root.

What it *tests* is a Stadium-8 **template** (`.claude/`). By default it tests the
repo it sits inside (`QA-TESTS/` at the repo root). To point it at a different
checkout, set `REPO_ROOT`:

```bash
# Test a Stadium-8 template that lives elsewhere
REPO_ROOT=/path/to/some-stadium8-repo npm test
```

If no `.claude/` template is found at the target, the suite **does not fail** —
the template-dependent suites (scripts, hooks, consistency, the workflow-state
schema) are **skipped** with a one-time notice, while the template-independent
tests still run (the artifact-lint rules, telemetry report math, the intake
manifest schema). So a carried/standalone copy always runs *something* and never
shows a vacuous green.

### Pester v5 prerequisite (one-time, Windows only)

The PowerShell hook tests require Pester v5. Windows ships with Pester v3.4, which does not understand the v5 syntax these tests use (`BeforeAll` at script scope, `Should -Match`, etc.). Install v5 side-by-side under the current user:

```powershell
pwsh -Command "Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck -MinimumVersion 5.0"
```

Verify:

```powershell
pwsh -Command "Get-Module -ListAvailable Pester | Select-Object Name,Version"
```

`npm run test:pester` forces the v5 import so the bundled v3.4 does not take precedence.

## Conventions

Every test follows `TEST-GUIDE.md` conventions:

- **PASS path AND FAIL path** — every `describe` block has both an `it('works when ...')` and an `it('fails when ...')` case, proving the test distinguishes them.
- **Independent** — each test owns its setup and teardown. No shared state. No dependency on order.
- **Isolated** — uses `os.tmpdir()` per test (never git branches).
- **Fast** — Tier 1 tests target < 100 ms each. State-machine tests aim for < 10 ms.
- **Cited rollback** — `afterEach` calls `rollback(root, 'RB-N')` where N is the rollback ID from `TEST-GUIDE.md`.

## Folder Map

```
QA/
├── helpers/                  Reusable helpers (12 files)
│   ├── temp-project.ts       createTempProject() — per-test tmpdir
│   ├── checkpoint-fixtures.ts  loadCheckpoint() — CP-0..CP-6 starting states
│   ├── rollback.ts           RB-0..RB-7 cleanup recipes
│   ├── state-fixtures.ts     seedState()
│   ├── manifest-fixtures.ts  seedManifest()
│   ├── run-script.ts         spawn wrapper returning { exitCode, parsedJson }
│   ├── git-sandbox.ts        git init + commit helpers
│   ├── snapshot.ts           dashboard snapshot helper
│   ├── index.ts              barrel export
│   └── schemas/              State-file schemas (workflow-state derives its phases from the template)
├── fixtures/                 Test inputs
│   ├── scenarios/            Team Task Manager + Variants A..F
│   ├── checkpoints/          CP-N tarballs (generated; see README there)
│   └── golden-telemetry/     Synthetic + harvested telemetry runs for Tier 2
├── tier-1-unit/              Pure-automation tests
│   ├── scripts/              One file per .claude/scripts/*.js
│   ├── hooks/                Node hooks + PowerShell hooks (Pester)
│   ├── consistency/          Static doc-lint — frontmatter, cross-file refs
│   ├── schemas/              JSON schema validation (fixtures + real script output)
│   └── artifact-lint/        Rule checks for generated code (fixture-tested; linters.ts + a skipped real-output scan)
├── tier-2-log-replay/        Telemetry-ledger invariants (formerly log-replay)
│   ├── verify-session-behavior.ts   Telemetry run loader + report runner + freshness canary
│   └── invariants/                   Ledger-shape, report-math, freshness
├── tier-3-pointer.md         Pointer to TEST-GUIDE.md
├── vitest.config.ts
├── tsconfig.json
├── package.json
└── README.md
```

## How It Runs Without Installing Into the Repo

`QA-TESTS/` is a **self-contained npm workspace** — its own `package.json` and `node_modules`. It reaches the template under test through a single resolved path (`helpers/target.ts` → the target repo's `.claude/`), which defaults to the parent repo and is overridable with `REPO_ROOT` (see "Running it standalone" above). You never install anything into `/web` or `/` for the test suite to work, and when no template is present the template-dependent suites skip rather than fail.

## Current Status

This is a **scaffolded skeleton** with representative tests wired up. See each folder's header comment for which tests are fully implemented vs stubbed with TODO markers. Tier 1 coverage focuses on:

- State machine (transition-phase.js) — full
- Script utilities (copy-with-header, scan-doc, init-preferences) — full
- Permission hooks (bash-permission-checker) — substantial
- Consistency (agents frontmatter, cross-doc refs) — full
- Schemas (workflow-state, intake-manifest) — full
- Artifact lint — all 5 TEST-GUIDE categories implemented as fixture-based tests

Tier 2 includes the parser and two fully implemented invariants (`logs-saved-marker`, `dashboard-timing`). The remaining invariants are stubbed showing the expected shape.

Tier 3 is a pointer to `/TEST-GUIDE.md` — no new work needed.

## Contributing

To add a test:

1. Pick the right tier folder.
2. Create `<script-name>.test.ts` (one file per thing under test).
3. Write both a PASS and a FAIL path for every behaviour.
4. Use `createTempProject()` from `helpers/` — never write to the repo.
5. Cite the rollback ID (`rollback(root, 'RB-N')`) in `afterEach`.
6. Add a row to the regression table in `/TEST-STRATEGY.md` § 16.
