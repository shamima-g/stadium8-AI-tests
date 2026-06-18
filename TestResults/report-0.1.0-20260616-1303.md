# QA Test Report — v0.1.0

_Generated 2026-06-16 13:03:43_

## 1. Run summary

| Field | Value |
|---|---|
| Date / time | Started `2026-06-16 13:03:44`, ended `13:03:56` |
| Run by | `shamima-g` on machine `SHAMIMA-NB` |
| Environment | Node `v24.11.0`; Vitest `2.1.9`; template commit `291ae24` (branch `main`); OS `win32 10.0.26100` |
| Overall result | ❌ Fail — 176 passed, 3 failed, 0 skipped |
| Total duration | `11.9s` |
| Total tokens | n/a (no LLM calls) |
| Total cost | n/a |

## 2. Per-layer breakdown

| Layer | Tests | Passed | Failed | Skipped | Duration | Tokens |
|---|--:|--:|--:|--:|--:|--:|
| tier-1-unit › artifact-lint | 20 | 20 | 0 | 0 | 1.7s | — |
| tier-1-unit › consistency | 57 | 55 | 2 | 0 | 186ms | — |
| tier-1-unit › hooks | 32 | 31 | 1 | 0 | 12.7s | — |
| tier-1-unit › schemas | 10 | 10 | 0 | 0 | 1.7s | — |
| tier-1-unit › scripts | 48 | 48 | 0 | 0 | 22.2s | — |
| tier-2-log-replay › invariants | 12 | 12 | 0 | 0 | 3.2s | — |
| **Total** | **179** | **176** | **3** | **0** | **41.7s** | — |

> Layer durations are **summed test time** (they total `41.7s`); the run's **wall-clock** duration is `11.9s` (section 1) — test files run in parallel. Token columns are `—` per layer (the automated tiers make no LLM calls); the macro total is sourced from the telemetry ledger when a live workflow run is present.

## 3. Per-test detail

| Test | Layer | Result | Duration | Tokens | Notes |
|---|---|:--:|--:|--:|---|
| artifact-lint — API path exactness PASS: every path in web/src matches the api-spec | tier-1-unit › artifact-lint | ✅ | 2ms | — |  |
| artifact-lint — API path matcher correctness FAIL: matcher correctly flags an invented path | tier-1-unit › artifact-lint | ✅ | 133ms | — |  |
| artifact-lint — API path matcher correctness PASS: matcher accepts an exact spec match | tier-1-unit › artifact-lint | ✅ | 81ms | — |  |
| artifact-lint — API path matcher correctness PASS: matcher treats parameterised paths correctly | tier-1-unit › artifact-lint | ✅ | 102ms | — |  |
| artifact-lint — no suppression directives in web/src PASS: real web/src/ has no suppression directives | tier-1-unit › artifact-lint | ✅ | 19ms | — |  |
| artifact-lint — scanner catches injected suppressions FAIL: scanner correctly flags a @ts-ignore in a fixture | tier-1-unit › artifact-lint | ✅ | 99ms | — |  |
| artifact-lint — scanner catches injected suppressions FAIL: scanner correctly flags a // eslint-disable-next-line | tier-1-unit › artifact-lint | ✅ | 114ms | — |  |
| artifact-lint — scanner catches injected suppressions PASS: clean code passes the scanner | tier-1-unit › artifact-lint | ✅ | 112ms | — |  |
| artifact-lint — plain-language verification checklists PASS: no jargon in any verification-checklist.md | tier-1-unit › artifact-lint | ✅ | 3ms | — |  |
| artifact-lint — plain-language verification checklists FAIL: detector correctly flags jargon in a synthetic string | tier-1-unit › artifact-lint | ✅ | 3ms | — |  |
| artifact-lint — plain-language verification checklists PASS: detector allows plain-language phrasing | tier-1-unit › artifact-lint | ✅ | 3ms | — |  |
| artifact-lint — role field in real story files PASS: every story file has a non-empty **Role:** field | tier-1-unit › artifact-lint | ✅ | 3ms | — |  |
| artifact-lint — role extractor correctness PASS: extracts a standard role | tier-1-unit › artifact-lint | ✅ | 162ms | — |  |
| artifact-lint — role extractor correctness PASS: accepts "All authenticated users" as a valid non-restricted marker | tier-1-unit › artifact-lint | ✅ | 160ms | — |  |
| artifact-lint — role extractor correctness FAIL: flags an empty role | tier-1-unit › artifact-lint | ✅ | 157ms | — |  |
| artifact-lint — role extractor correctness FAIL: flags "N/A" as empty | tier-1-unit › artifact-lint | ✅ | 162ms | — |  |
| artifact-lint — role extractor correctness FAIL: returns null when no Role field at all | tier-1-unit › artifact-lint | ✅ | 170ms | — |  |
| artifact-lint — Shadcn imports in real repo PASS: UI component imports use @/components/ui/ in web/src | tier-1-unit › artifact-lint | ✅ | 17ms | — |  |
| artifact-lint — Shadcn detector correctness FAIL: detects a hand-crafted Button import | tier-1-unit › artifact-lint | ✅ | 134ms | — |  |
| artifact-lint — Shadcn detector correctness PASS: accepts an @/components/ui/ Button import | tier-1-unit › artifact-lint | ✅ | 102ms | — |  |
| agent frontmatter — every agent has required fields PASS: api-connectivity-agent.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 14ms | — |  |
| agent frontmatter — every agent has required fields PASS: code-reviewer.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: design-api-agent.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: design-style-agent.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: developer.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: feature-planner.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: intake-agent.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: mock-setup-agent.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: playwright-runner.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: test-generator.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — every agent has required fields PASS: type-generator-agent.md has valid frontmatter with name + description | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in api-connectivity-agent.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in code-reviewer.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in design-api-agent.md matches the filename stem | tier-1-unit › consistency | ✅ | 2ms | — |  |
| agent frontmatter — name matches filename PASS: name in design-style-agent.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in developer.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in feature-planner.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in intake-agent.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in mock-setup-agent.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in playwright-runner.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in test-generator.md matches the filename stem | tier-1-unit › consistency | ✅ | 1ms | — |  |
| agent frontmatter — name matches filename PASS: name in type-generator-agent.md matches the filename stem | tier-1-unit › consistency | ✅ | 6ms | — |  |
| agent README consistency PASS: every agent file has a matching entry in README.md | tier-1-unit › consistency | ✅ | 3ms | — |  |
| agent README consistency FAIL: README does not list phantom agents that don't exist on disk | tier-1-unit › consistency | ✅ | 2ms | — |  |
| command frontmatter PASS: /api-go-live has a non-empty description | tier-1-unit › consistency | ❌ | 27ms | — | AssertionError: expected 'undefined' to be 'string' // Object.is equality     at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\consistency\commands-frontmatter.test.ts:29:46     at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vites |
| command frontmatter PASS: /api-mock-refresh has a non-empty description | tier-1-unit › consistency | ❌ | 3ms | — | AssertionError: expected 'undefined' to be 'string' // Object.is equality     at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\consistency\commands-frontmatter.test.ts:29:46     at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vites |
| command frontmatter PASS: /api-status has a non-empty description | tier-1-unit › consistency | ✅ | 20ms | — |  |
| command frontmatter PASS: /continue has a non-empty description | tier-1-unit › consistency | ✅ | 3ms | — |  |
| command frontmatter PASS: /dashboard has a non-empty description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| command frontmatter PASS: /migrate-legacy has a non-empty description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| command frontmatter PASS: /quality-check has a non-empty description | tier-1-unit › consistency | ✅ | 3ms | — |  |
| command frontmatter PASS: /start has a non-empty description | tier-1-unit › consistency | ✅ | 2ms | — |  |
| command frontmatter PASS: /status has a non-empty description | tier-1-unit › consistency | ✅ | 1ms | — |  |
| command frontmatter — model field valid PASS: api-go-live.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 1ms | — |  |
| command frontmatter — model field valid PASS: api-mock-refresh.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 1ms | — |  |
| command frontmatter — model field valid PASS: api-status.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 1ms | — |  |
| command frontmatter — model field valid PASS: continue.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 1ms | — |  |
| command frontmatter — model field valid PASS: dashboard.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 1ms | — |  |
| command frontmatter — model field valid PASS: migrate-legacy.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 1ms | — |  |
| command frontmatter — model field valid PASS: quality-check.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 2ms | — |  |
| command frontmatter — model field valid PASS: start.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 1ms | — |  |
| command frontmatter — model field valid PASS: status.md either omits model or uses a known value | tier-1-unit › consistency | ✅ | 1ms | — |  |
| CLAUDE.md → commands cross-reference PASS: every /command referenced in CLAUDE.md exists under .claude/commands/ | tier-1-unit › consistency | ✅ | 26ms | — |  |
| orchestrator-rules.md → agent files PASS: every agent mentioned by name in orchestrator-rules.md exists | tier-1-unit › consistency | ✅ | 10ms | — |  |
| agents/README.md agent catalog PASS: .claude/agents/README.md references every real agent at least once | tier-1-unit › consistency | ✅ | 3ms | — |  |
| CLAUDE.md → policies/ files PASS: every policy file referenced in CLAUDE.md exists | tier-1-unit › consistency | ✅ | 1ms | — |  |
| settings.json structural validity PASS: parses as valid JSON | tier-1-unit › consistency | ✅ | 7ms | — |  |
| settings.json structural validity PASS: has expected top-level sections | tier-1-unit › consistency | ✅ | 1ms | — |  |
| settings.json structural validity FAIL: deny list is not empty (security invariant) | tier-1-unit › consistency | ✅ | 2ms | — |  |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/workflow-guard.ps1 | tier-1-unit › consistency | ✅ | 2ms | — |  |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/telemetry.js | tier-1-unit › consistency | ✅ | 1ms | — |  |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/inject-phase-context.ps1 | tier-1-unit › consistency | ✅ | 1ms | — |  |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/inject-agent-context.ps1 | tier-1-unit › consistency | ✅ | 1ms | — |  |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/bash-permission-checker.js | tier-1-unit › consistency | ✅ | 1ms | — |  |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/claude-md-permission-checker.js | tier-1-unit › consistency | ✅ | 1ms | — |  |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/enforce-generated-doc-names.js | tier-1-unit › consistency | ✅ | 1ms | — |  |
| settings.json hook timeouts are reasonable PASS: no hook declares a timeout over 60 seconds | tier-1-unit › consistency | ✅ | 3ms | — |  |
| intake-manifest.json schema PASS: default manifest (Team Task Manager) validates | tier-1-unit › schemas | ✅ | 117ms | — |  |
| intake-manifest.json schema PASS: BFF variant overlay validates | tier-1-unit › schemas | ✅ | 87ms | — |  |
| intake-manifest.json schema FAIL: invalid dataSource value is rejected | tier-1-unit › schemas | ✅ | 1ms | — |  |
| intake-manifest.json schema FAIL: artifact entry without `generate` boolean is rejected | tier-1-unit › schemas | ✅ | 1ms | — |  |
| intake-manifest.json schema FAIL: invalid authMethod is rejected | tier-1-unit › schemas | ✅ | 0ms | — |  |
| workflow-state.json schema PASS: a fresh default-seeded state validates | tier-1-unit › schemas | ✅ | 149ms | — |  |
| workflow-state.json schema PASS: states across every phase value validate | tier-1-unit › schemas | ✅ | 1.3s | — |  |
| workflow-state.json schema FAIL: an invalid phase value is rejected | tier-1-unit › schemas | ✅ | 5ms | — |  |
| workflow-state.json schema FAIL: a negative currentEpic is rejected | tier-1-unit › schemas | ✅ | 1ms | — |  |
| workflow-state.json schema FAIL: a missing currentPhase is rejected | tier-1-unit › schemas | ✅ | 5ms | — |  |
| collect-dashboard-data.js — --format=json PASS: returns "no_state" JSON when no workflow has started | tier-1-unit › scripts | ✅ | 490ms | — |  |
| collect-dashboard-data.js — --format=json FAIL: does not return invalid JSON or crash when state exists mid-phase | tier-1-unit › scripts | ✅ | 517ms | — |  |
| collect-dashboard-data.js — --format=text PASS: text format produces human-readable output referencing the current phase | tier-1-unit › scripts | ✅ | 414ms | — |  |
| collect-dashboard-data.js — --format=text FAIL: text format does not leak raw JSON braces into user-facing output | tier-1-unit › scripts | ✅ | 550ms | — |  |
| copy-with-header.js — copies YAML with default header PASS: copies a user-provided api spec and prepends "# Source: ..." as line 1 | tier-1-unit › scripts | ✅ | 320ms | — |  |
| copy-with-header.js — copies YAML with default header FAIL: refuses when --to is outside generated-docs/ | tier-1-unit › scripts | ✅ | 452ms | — |  |
| copy-with-header.js — missing source file PASS: returns status=error when source does not exist | tier-1-unit › scripts | ✅ | 737ms | — |  |
| copy-with-header.js — missing source file FAIL: does not silently create an empty destination on missing source | tier-1-unit › scripts | ✅ | 641ms | — |  |
| copy-with-header.js — custom header PASS: a CSS file gets a CSS-style custom header | tier-1-unit › scripts | ✅ | 380ms | — |  |
| copy-with-header.js — custom header FAIL: second line of the file is NOT accidentally the header (header must be line 1 only) | tier-1-unit › scripts | ✅ | 419ms | — |  |
| generate-dashboard-html.js PASS: writes generated-docs/dashboard.html with an auto-refresh meta tag | tier-1-unit › scripts | ✅ | 507ms | — |  |
| generate-dashboard-html.js FAIL: does not crash or produce empty output with no state file | tier-1-unit › scripts | ✅ | 486ms | — |  |
| generate-dashboard-html.js — snapshot (stable HTML) PASS: produces deterministic HTML for a fixed state (after normalising timestamps) | tier-1-unit › scripts | ✅ | 765ms | — |  |
| generate-dashboard-html.js — snapshot (stable HTML) FAIL: different states produce different HTML (proves the normaliser isn't stripping signal) | tier-1-unit › scripts | ✅ | 819ms | — |  |
| generate-telemetry-report.js — timing PASS: computes per-phase active time and excludes user-wait windows | tier-1-unit › scripts | ✅ | 352ms | — |  |
| generate-telemetry-report.js — timing FAIL: an empty ledger yields no phases (does not invent data) | tier-1-unit › scripts | ✅ | 595ms | — |  |
| generate-telemetry-report.js — HTML output PASS: --html emits a self-contained HTML page with inline SVG charts and no external CDN | tier-1-unit › scripts | ✅ | 906ms | — |  |
| generate-telemetry-report.js — tokens PASS: reports tokens unavailable (not fabricated) when no transcript exists | tier-1-unit › scripts | ✅ | 477ms | — |  |
| generate-test-report — buildModel PASS: tallies counts, groups by layer, and keeps the failure message | tier-1-unit › scripts | ✅ | 26ms | — |  |
| generate-test-report — buildModel FAIL: does not count a skipped test as passed | tier-1-unit › scripts | ✅ | 1ms | — |  |
| generate-test-report — fmtDuration PASS: formats sub-second, seconds, and minutes | tier-1-unit › scripts | ✅ | 1ms | — |  |
| generate-test-report — fmtDuration FAIL: returns a placeholder for a missing duration rather than NaN | tier-1-unit › scripts | ✅ | 0ms | — |  |
| generate-test-report — render PASS: emits the three sections and a failed-tests block with the assertion message | tier-1-unit › scripts | ✅ | 3ms | — |  |
| generate-test-report — render FAIL: an all-pass run is not reported as a failure | tier-1-unit › scripts | ✅ | 1ms | — |  |
| generate-todo-list.js PASS: returns a JSON array suitable for TodoWrite | tier-1-unit › scripts | ✅ | 433ms | — |  |
| generate-todo-list.js FAIL: does not emit a TodoWrite entry with an empty content field | tier-1-unit › scripts | ✅ | 280ms | — |  |
| import-prototype.js — genesis layout PASS: copies genesis marker files into documentation/ when genesis.md is present | tier-1-unit › scripts | ✅ | 640ms | — |  |
| import-prototype.js — genesis layout FAIL: returns status=error when --from path does not exist | tier-1-unit › scripts | ✅ | 496ms | — |  |
| init-preferences.js — initial write PASS: writes .claude/preferences.json with the given flags | tier-1-unit › scripts | ✅ | 427ms | — |  |
| init-preferences.js — initial write FAIL: rejects non-boolean flag values | tier-1-unit › scripts | ✅ | 446ms | — |  |
| init-preferences.js — idempotency PASS: second invocation without --force skips (reports "skipped" or similar) | tier-1-unit › scripts | ✅ | 757ms | — |  |
| init-preferences.js — idempotency FAIL: --force overwrites, proving idempotency can be bypassed deliberately | tier-1-unit › scripts | ✅ | 834ms | — |  |
| quality-gates.js — JSON shape PASS: always outputs a parseable JSON object with a gates array | tier-1-unit › scripts | ✅ | 479ms | — |  |
| quality-gates.js — JSON shape FAIL: does not return a "conditional pass" marker anywhere in its JSON output | tier-1-unit › scripts | ✅ | 335ms | — |  |
| scan-doc.js — plain markdown file PASS: reports correct line count and text type | tier-1-unit › scripts | ✅ | 768ms | — |  |
| scan-doc.js — plain markdown file FAIL: does not claim a text file is binary | tier-1-unit › scripts | ✅ | 377ms | — |  |
| scan-doc.js — binary file detection PASS: flags a buffer with null bytes as binary | tier-1-unit › scripts | ✅ | 382ms | — |  |
| scan-doc.js — binary file detection FAIL: does not attempt to count lines in a binary buffer as if it were text | tier-1-unit › scripts | ✅ | 450ms | — |  |
| scan-doc.js — keyword counting PASS: counts requested keywords case-insensitively | tier-1-unit › scripts | ✅ | 485ms | — |  |
| scan-doc.js — keyword counting FAIL: keywords not present yield zero, not undefined/crash | tier-1-unit › scripts | ✅ | 324ms | — |  |
| transition-phase.js — --show PASS: reports the current phase when state exists | tier-1-unit › scripts | ✅ | 391ms | — |  |
| transition-phase.js — --show FAIL: returns error when no state file exists | tier-1-unit › scripts | ✅ | 537ms | — |  |
| transition-phase.js — INTAKE → PLAN PASS: transitions when the project brief exists | tier-1-unit › scripts | ✅ | 864ms | — |  |
| transition-phase.js — INTAKE → PLAN FAIL: refuses transition with a descriptive error when current phase is COMPLETE and target is PLAN | tier-1-unit › scripts | ✅ | 507ms | — |  |
| transition-phase.js — idempotent behaviour PASS: --show after writing state is deterministic — same value, same output | tier-1-unit › scripts | ✅ | 730ms | — |  |
| transition-phase.js — idempotent behaviour FAIL: advancing to an invalid phase does NOT silently succeed | tier-1-unit › scripts | ✅ | 576ms | — |  |
| transition-phase.js — --repair PASS: reconstructs state when only artifacts exist | tier-1-unit › scripts | ✅ | 477ms | — |  |
| transition-phase.js — --repair FAIL: --repair in an empty project reports low confidence or error, not false ok | tier-1-unit › scripts | ✅ | 342ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf / — deny path | tier-1-unit › hooks | ✅ | 288ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf /* — deny path with wildcard | tier-1-unit › hooks | ✅ | 272ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat ~/.ssh/id_rsa — ssh private key | tier-1-unit › hooks | ✅ | 392ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat /root/.ssh/id_rsa — ssh private key absolute | tier-1-unit › hooks | ✅ | 545ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): type id_rsa.pem — ssh key via Windows type | tier-1-unit › hooks | ✅ | 573ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): Get-Content id_rsa — ssh key via PowerShell Get-Content | tier-1-unit › hooks | ✅ | 255ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat mykey.pem — .pem via cat | tier-1-unit › hooks | ✅ | 257ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): sed -n 1p credentials — credentials via sed | tier-1-unit › hooks | ✅ | 309ms | — |  |
| bash-permission-checker — deny matrix FAIL safely (must deny): grep password credentials.json — credentials file | tier-1-unit › hooks | ❌ | 428ms | — | AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality     at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\hooks\bash-permission-checker.test.ts:62:20     at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/r |
| bash-permission-checker — allow matrix PASS: allow node .claude/scripts/transition-phase.js --show — node running a claude script | tier-1-unit › hooks | ✅ | 344ms | — |  |
| bash-permission-checker — allow matrix PASS: allow node .claude/scripts/copy-with-header.js --from a --to b — copy-with-header | tier-1-unit › hooks | ✅ | 331ms | — |  |
| bash-permission-checker — allow matrix PASS: allow git pull — git pull is always auto-approved | tier-1-unit › hooks | ✅ | 416ms | — |  |
| bash-permission-checker — allow matrix PASS: allow git add generated-docs/ — git add scoped to generated-docs | tier-1-unit › hooks | ✅ | 400ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf / outright | tier-1-unit › hooks | ✅ | 337ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm  -rf  / outright | tier-1-unit › hooks | ✅ | 323ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -r -f / outright | tier-1-unit › hooks | ✅ | 518ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm --recursive --force / outright | tier-1-unit › hooks | ✅ | 545ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf ~ outright | tier-1-unit › hooks | ✅ | 596ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf $HOME outright | tier-1-unit › hooks | ✅ | 757ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW /bin/rm -rf / outright | tier-1-unit › hooks | ✅ | 348ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW sudo rm -rf / outright | tier-1-unit › hooks | ✅ | 438ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW bash -c "rm -rf /" outright | tier-1-unit › hooks | ✅ | 238ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW eval "rm -rf /" outright | tier-1-unit › hooks | ✅ | 357ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW  rm -rf / outright | tier-1-unit › hooks | ✅ | 282ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW cat ~/.ssh/id_rsa && true outright | tier-1-unit › hooks | ✅ | 371ms | — |  |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW true \|\| cat /etc/shadow outright | tier-1-unit › hooks | ✅ | 462ms | — |  |
| bash-permission-checker — fallthrough for ordinary commands PASS: falls through (no decision) for a benign unrelated command | tier-1-unit › hooks | ✅ | 313ms | — |  |
| bash-permission-checker — fallthrough for ordinary commands FAIL: does not crash or exit non-zero for empty input | tier-1-unit › hooks | ✅ | 151ms | — |  |
| claude-md-permission-checker — protects CLAUDE.md PASS: falls through silently on a Write to CLAUDE.md when no workflow state exists | tier-1-unit › hooks | ✅ | 686ms | — |  |
| claude-md-permission-checker — protects CLAUDE.md FAIL: does NOT interfere with Writes to unrelated files | tier-1-unit › hooks | ✅ | 539ms | — |  |
| claude-md-permission-checker — handles malformed input PASS: does not crash on empty payload | tier-1-unit › hooks | ✅ | 302ms | — |  |
| claude-md-permission-checker — handles malformed input FAIL: does not accidentally allow a CLAUDE.md write when file_path is missing | tier-1-unit › hooks | ✅ | 371ms | — |  |
| Tier 2 — telemetry-baseline freshness canary PASS: newest telemetry baseline is newer than orchestrator-rules.md and settings.json | tier-2-log-replay › invariants | ✅ | 2ms | — |  |
| Tier 2 — telemetry ledger shape PASS: timestamps are monotonic non-decreasing | tier-2-log-replay › invariants | ✅ | 6ms | — |  |
| Tier 2 — telemetry ledger shape PASS: every agent_start has a matching agent_stop | tier-2-log-replay › invariants | ✅ | 2ms | — |  |
| Tier 2 — telemetry ledger shape PASS: phase_enter / phase_exit events balance (last phase may stay open) | tier-2-log-replay › invariants | ✅ | 1ms | — |  |
| Tier 2 — telemetry ledger shape FAIL: detector catches an unbalanced agent ledger | tier-2-log-replay › invariants | ✅ | 1ms | — |  |
| Tier 2 — telemetry report: timing PASS: active time excludes the user-wait window | tier-2-log-replay › invariants | ✅ | 317ms | — |  |
| Tier 2 — telemetry report: timing PASS: granular agent spans are correct | tier-2-log-replay › invariants | ✅ | 493ms | — |  |
| Tier 2 — telemetry report: timing FAIL: a non-existent phase is not present in the report | tier-2-log-replay › invariants | ✅ | 540ms | — |  |
| Tier 2 — telemetry report: tokens PASS: tokens attribute to the phase and agent that own the timestamp | tier-2-log-replay › invariants | ✅ | 696ms | — |  |
| Tier 2 — telemetry report: estimate/variance vs golden baseline PASS: estimate reads the harvested baseline and reports counts | tier-2-log-replay › invariants | ✅ | 292ms | — |  |
| Tier 2 — telemetry report: estimate/variance vs golden baseline PASS: final report computes per-story variance against the baseline (zero for the baseline run itself) | tier-2-log-replay › invariants | ✅ | 366ms | — |  |
| Tier 2 — telemetry report: estimate/variance vs golden baseline FAIL: estimate without a baseline reports baselineAvailable=false | tier-2-log-replay › invariants | ✅ | 438ms | — |  |

## Failed tests — assertion messages

### ❌ command frontmatter PASS: /api-go-live has a non-empty description
_Layer: tier-1-unit › consistency_

```
AssertionError: expected 'undefined' to be 'string' // Object.is equality
    at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\consistency\commands-frontmatter.test.ts:29:46
    at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ command frontmatter PASS: /api-mock-refresh has a non-empty description
_Layer: tier-1-unit › consistency_

```
AssertionError: expected 'undefined' to be 'string' // Object.is equality
    at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\consistency\commands-frontmatter.test.ts:29:46
    at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): grep password credentials.json — credentials file
_Layer: tier-1-unit › hooks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\hooks\bash-permission-checker.test.ts:62:20
    at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/TestsArchives/stadium8-tests/16-06-2026/16-06-2026/QA-TESTS/node_modules/@vitest/runner/dist/index.js:1262:5)
```
