# Test report — 18 June 2026, 8:38am

A plain-language summary of every check we ran on the project, and how each one did.

## In short

**❌ Some checks need attention**

We ran **190** checks in total: **186 passed**, **3 need attention**, 1 not run this time.

The application and its tests come to **6,930 lines of code** across 63 files.

## The numbers

| | |
|---|---|
| Result | ❌ Needs attention |
| Checks run | 190 |
| Passed | 186 |
| Need attention | 3 |
| Not run this time | 1 |
| Time taken | 7.2s |
| Lines of code (app + tests) | 6,930 |
| AI usage | No AI was used in these checks |
| Run by | shamima-g on SHAMIMA-NB |
| When | 18 June 2026, 8:38am → finished 8:38am |

## How each area did

| Area | Result | Passed | Need attention | Not run |
|---|:--:|--:|--:|--:|
| Project files follow the rules | ✅ | 24 | 0 | 1 |
| Everything lines up and is consistent | ❌ | 55 | 2 | 0 |
| Built-in safety checks | ❌ | 31 | 1 | 0 |
| Saved data has the right shape | ✅ | 14 | 0 | 0 |
| Helper tools work correctly | ✅ | 50 | 0 | 0 |
| Workflow records stay trustworthy | ✅ | 12 | 0 | 0 |
| The app's own tests | — | — | — | — |
| Using the app like a person would | — | — | — | — |
| Final quality gates | — | — | — | — |

> **The app's own tests:** Not run yet — no saved result to show.
> **Using the app like a person would:** Not run yet — no saved result to show.
> **Final quality gates:** Not run yet — no saved result to show.

## Lines of code in the application

This counts the code written to build the app and its tests (it ignores blank lines, notes, data files, and the workflow tooling that ships with the template).

| Part of the project | Files | Lines of code |
|---|--:|--:|
| Application code (web/src) | 39 | 3,787 |
| TDD tests (unit, integration, click-through) | 13 | 2,481 |
| Application setup & configuration | 11 | 662 |
| **Total** | **63** | **6,930** |

## What needs attention

3 checks did not pass. Here is what each one was checking and what went wrong:

### ❌ command frontmatter PASS: /api-go-live has a non-empty description
_Area: Everything lines up and is consistent_

```
AssertionError: expected 'undefined' to be 'string' // Object.is equality
    at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\consistency\commands-frontmatter.test.ts:30:46
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
_Area: Everything lines up and is consistent_

```
AssertionError: expected 'undefined' to be 'string' // Object.is equality
    at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\consistency\commands-frontmatter.test.ts:30:46
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
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\TestsArchives\stadium8-tests\16-06-2026\16-06-2026\QA-TESTS\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
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

## Every check we ran

The full list, in case you want the detail. ✅ passed · ❌ needs attention · ⏭️ not run.

| Check | Area | Result | Time |
|---|---|:--:|--:|
| TG-31 rule — findInventedPaths FAIL: flags a path not in the spec | Project files follow the rules | ✅ | 4ms |
| TG-31 rule — findInventedPaths PASS: accepts an exact spec match | Project files follow the rules | ✅ | 1ms |
| TG-31 rule — findInventedPaths PASS: matches a parameterised path by shape | Project files follow the rules | ✅ | 1ms |
| TG-31 rule — findInventedPaths PASS: ignores strings that are not /api paths | Project files follow the rules | ✅ | 0ms |
| TG-31 regression — real spec + endpoints every code path matches the spec | Project files follow the rules | ✅ | 11ms |
| TG-33 rule — findSuppressions FAIL: flags a @ts-ignore | Project files follow the rules | ✅ | 4ms |
| TG-33 rule — findSuppressions FAIL: flags an eslint-disable-next-line | Project files follow the rules | ✅ | 1ms |
| TG-33 rule — findSuppressions FAIL: flags every directive variant | Project files follow the rules | ✅ | 1ms |
| TG-33 rule — findSuppressions PASS: clean code has no suppressions | Project files follow the rules | ✅ | 0ms |
| TG-33 regression — real web/src/ has no suppression directives in any source file | Project files follow the rules | ✅ | 18ms |
| TG-34 rule — findJargon FAIL: flags engineering jargon | Project files follow the rules | ✅ | 3ms |
| TG-34 rule — findJargon FAIL: flags a gate reference | Project files follow the rules | ✅ | 2ms |
| TG-34 rule — findJargon PASS: allows plain-language phrasing | Project files follow the rules | ✅ | 0ms |
| TG-34 regression — real verification checklists contain no engineering jargon | Project files follow the rules | ⏭️ | — |
| TG-38 rule — extractRole / roleViolation PASS: extracts a standard role and reports no violation | Project files follow the rules | ✅ | 3ms |
| TG-38 rule — extractRole / roleViolation PASS: "All authenticated users" is a valid non-restricted role | Project files follow the rules | ✅ | 0ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags an empty role | Project files follow the rules | ✅ | 0ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags "N/A" as empty/ambiguous | Project files follow the rules | ✅ | 0ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags a story with no Role field at all | Project files follow the rules | ✅ | 0ms |
| TG-38 regression — real story files every story file has a valid Role | Project files follow the rules | ✅ | 3ms |
| TG-32 rule — findNonShadcnUiImports FAIL: flags a hand-crafted Button import | Project files follow the rules | ✅ | 4ms |
| TG-32 rule — findNonShadcnUiImports PASS: accepts a Shadcn Button import | Project files follow the rules | ✅ | 1ms |
| TG-32 rule — findNonShadcnUiImports PASS: ignores non-UI imports | Project files follow the rules | ✅ | 1ms |
| TG-32 rule — findNonShadcnUiImports FAIL: flags one offender even when mixed with a valid import | Project files follow the rules | ✅ | 1ms |
| TG-32 regression — real web/src/ all UI-primitive imports come from @/components/ui/ | Project files follow the rules | ✅ | 15ms |
| agent frontmatter — every agent has required fields PASS: api-connectivity-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — every agent has required fields PASS: code-reviewer.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 2ms |
| agent frontmatter — every agent has required fields PASS: design-api-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — every agent has required fields PASS: design-style-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — every agent has required fields PASS: developer.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — every agent has required fields PASS: feature-planner.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — every agent has required fields PASS: intake-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — every agent has required fields PASS: mock-setup-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — every agent has required fields PASS: playwright-runner.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — every agent has required fields PASS: test-generator.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — every agent has required fields PASS: type-generator-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — name matches filename PASS: name in api-connectivity-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — name matches filename PASS: name in code-reviewer.md matches the filename stem | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — name matches filename PASS: name in design-api-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — name matches filename PASS: name in design-style-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 0ms |
| agent frontmatter — name matches filename PASS: name in developer.md matches the filename stem | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — name matches filename PASS: name in feature-planner.md matches the filename stem | Everything lines up and is consistent | ✅ | 1ms |
| agent frontmatter — name matches filename PASS: name in intake-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 0ms |
| agent frontmatter — name matches filename PASS: name in mock-setup-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 0ms |
| agent frontmatter — name matches filename PASS: name in playwright-runner.md matches the filename stem | Everything lines up and is consistent | ✅ | 0ms |
| agent frontmatter — name matches filename PASS: name in test-generator.md matches the filename stem | Everything lines up and is consistent | ✅ | 0ms |
| agent frontmatter — name matches filename PASS: name in type-generator-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 0ms |
| agent README consistency PASS: every agent file has a matching entry in README.md | Everything lines up and is consistent | ✅ | 2ms |
| agent README consistency FAIL: README does not list phantom agents that don't exist on disk | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter PASS: /api-go-live has a non-empty description | Everything lines up and is consistent | ❌ | 18ms |
| command frontmatter PASS: /api-mock-refresh has a non-empty description | Everything lines up and is consistent | ❌ | 2ms |
| command frontmatter PASS: /api-status has a non-empty description | Everything lines up and is consistent | ✅ | 5ms |
| command frontmatter PASS: /continue has a non-empty description | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter PASS: /dashboard has a non-empty description | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter PASS: /migrate-legacy has a non-empty description | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter PASS: /quality-check has a non-empty description | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter PASS: /start has a non-empty description | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter PASS: /status has a non-empty description | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: api-go-live.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: api-mock-refresh.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: api-status.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: continue.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: dashboard.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: migrate-legacy.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 0ms |
| command frontmatter — model field valid PASS: quality-check.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: start.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: status.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| CLAUDE.md → commands cross-reference PASS: every /command referenced in CLAUDE.md exists under .claude/commands/ | Everything lines up and is consistent | ✅ | 1ms |
| orchestrator-rules.md → agent files PASS: every agent mentioned by name in orchestrator-rules.md exists | Everything lines up and is consistent | ✅ | 5ms |
| agents/README.md agent catalog PASS: .claude/agents/README.md references every real agent at least once | Everything lines up and is consistent | ✅ | 1ms |
| CLAUDE.md → policies/ files PASS: every policy file referenced in CLAUDE.md exists | Everything lines up and is consistent | ✅ | 1ms |
| settings.json structural validity PASS: parses as valid JSON | Everything lines up and is consistent | ✅ | 4ms |
| settings.json structural validity PASS: has expected top-level sections | Everything lines up and is consistent | ✅ | 1ms |
| settings.json structural validity FAIL: deny list is not empty (security invariant) | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/workflow-guard.ps1 | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/telemetry.js | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/inject-phase-context.ps1 | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/inject-agent-context.ps1 | Everything lines up and is consistent | ✅ | 0ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/bash-permission-checker.js | Everything lines up and is consistent | ✅ | 0ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/claude-md-permission-checker.js | Everything lines up and is consistent | ✅ | 0ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/enforce-generated-doc-names.js | Everything lines up and is consistent | ✅ | 0ms |
| settings.json hook timeouts are reasonable PASS: no hook declares a timeout over 60 seconds | Everything lines up and is consistent | ✅ | 2ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf / — deny path | Built-in safety checks | ✅ | 179ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf /* — deny path with wildcard | Built-in safety checks | ✅ | 206ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat ~/.ssh/id_rsa — ssh private key | Built-in safety checks | ✅ | 133ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat /root/.ssh/id_rsa — ssh private key absolute | Built-in safety checks | ✅ | 138ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): type id_rsa.pem — ssh key via Windows type | Built-in safety checks | ✅ | 173ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): Get-Content id_rsa — ssh key via PowerShell Get-Content | Built-in safety checks | ✅ | 149ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat mykey.pem — .pem via cat | Built-in safety checks | ✅ | 206ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): sed -n 1p credentials — credentials via sed | Built-in safety checks | ✅ | 206ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): grep password credentials.json — credentials file | Built-in safety checks | ❌ | 268ms |
| bash-permission-checker — allow matrix PASS: allow node .claude/scripts/transition-phase.js --show — node running a claude script | Built-in safety checks | ✅ | 226ms |
| bash-permission-checker — allow matrix PASS: allow node .claude/scripts/copy-with-header.js --from a --to b — copy-with-header | Built-in safety checks | ✅ | 247ms |
| bash-permission-checker — allow matrix PASS: allow git pull — git pull is always auto-approved | Built-in safety checks | ✅ | 226ms |
| bash-permission-checker — allow matrix PASS: allow git add generated-docs/ — git add scoped to generated-docs | Built-in safety checks | ✅ | 241ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf / outright | Built-in safety checks | ✅ | 240ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm  -rf  / outright | Built-in safety checks | ✅ | 188ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -r -f / outright | Built-in safety checks | ✅ | 296ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm --recursive --force / outright | Built-in safety checks | ✅ | 206ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf ~ outright | Built-in safety checks | ✅ | 236ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf $HOME outright | Built-in safety checks | ✅ | 341ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW /bin/rm -rf / outright | Built-in safety checks | ✅ | 189ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW sudo rm -rf / outright | Built-in safety checks | ✅ | 264ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW bash -c "rm -rf /" outright | Built-in safety checks | ✅ | 293ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW eval "rm -rf /" outright | Built-in safety checks | ✅ | 269ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW  rm -rf / outright | Built-in safety checks | ✅ | 318ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW cat ~/.ssh/id_rsa && true outright | Built-in safety checks | ✅ | 142ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW true \|\| cat /etc/shadow outright | Built-in safety checks | ✅ | 189ms |
| bash-permission-checker — fallthrough for ordinary commands PASS: falls through (no decision) for a benign unrelated command | Built-in safety checks | ✅ | 118ms |
| bash-permission-checker — fallthrough for ordinary commands FAIL: does not crash or exit non-zero for empty input | Built-in safety checks | ✅ | 67ms |
| claude-md-permission-checker — protects CLAUDE.md PASS: falls through silently on a Write to CLAUDE.md when no workflow state exists | Built-in safety checks | ✅ | 194ms |
| claude-md-permission-checker — protects CLAUDE.md FAIL: does NOT interfere with Writes to unrelated files | Built-in safety checks | ✅ | 177ms |
| claude-md-permission-checker — handles malformed input PASS: does not crash on empty payload | Built-in safety checks | ✅ | 229ms |
| claude-md-permission-checker — handles malformed input FAIL: does not accidentally allow a CLAUDE.md write when file_path is missing | Built-in safety checks | ✅ | 150ms |
| intake-manifest.json schema PASS: default manifest (Team Task Manager) validates | Saved data has the right shape | ✅ | 75ms |
| intake-manifest.json schema PASS: BFF variant overlay validates | Saved data has the right shape | ✅ | 61ms |
| intake-manifest.json schema FAIL: invalid dataSource value is rejected | Saved data has the right shape | ✅ | 2ms |
| intake-manifest.json schema FAIL: artifact entry without `generate` boolean is rejected | Saved data has the right shape | ✅ | 0ms |
| intake-manifest.json schema FAIL: invalid authMethod is rejected | Saved data has the right shape | ✅ | 0ms |
| workflow-state.json schema PASS: a fresh default-seeded state validates | Saved data has the right shape | ✅ | 89ms |
| workflow-state.json schema PASS: every phase the producer can emit validates (derived from ALL_PHASES) | Saved data has the right shape | ✅ | 247ms |
| workflow-state.json schema FAIL: a retired legacy phase is rejected | Saved data has the right shape | ✅ | 1ms |
| workflow-state.json schema FAIL: an invalid phase value is rejected | Saved data has the right shape | ✅ | 1ms |
| workflow-state.json schema FAIL: a negative currentEpic is rejected | Saved data has the right shape | ✅ | 0ms |
| workflow-state.json schema FAIL: a missing currentPhase is rejected | Saved data has the right shape | ✅ | 1ms |
| workflow-state.json schema — real producer output conforms PASS: `transition-phase.js --init INTAKE` writes schema-valid state | Saved data has the right shape | ✅ | 227ms |
| workflow-state.json schema — real producer output conforms PASS: `transition-phase.js --init PLAN` writes schema-valid state | Saved data has the right shape | ✅ | 193ms |
| workflow-state.json schema — real producer output conforms PASS: `transition-phase.js --init BUILD` writes schema-valid state | Saved data has the right shape | ✅ | 207ms |
| collect-dashboard-data.js — --format=json PASS: returns "no_state" JSON when no workflow has started | Helper tools work correctly | ✅ | 282ms |
| collect-dashboard-data.js — --format=json FAIL: does not return invalid JSON or crash when state exists mid-phase | Helper tools work correctly | ✅ | 312ms |
| collect-dashboard-data.js — --format=text PASS: text format produces human-readable output referencing the current phase | Helper tools work correctly | ✅ | 258ms |
| collect-dashboard-data.js — --format=text FAIL: text format does not leak raw JSON braces into user-facing output | Helper tools work correctly | ✅ | 377ms |
| copy-with-header.js — copies YAML with default header PASS: copies a user-provided api spec and prepends "# Source: ..." as line 1 | Helper tools work correctly | ✅ | 223ms |
| copy-with-header.js — copies YAML with default header FAIL: refuses when --to is outside generated-docs/ | Helper tools work correctly | ✅ | 193ms |
| copy-with-header.js — missing source file PASS: returns status=error when source does not exist | Helper tools work correctly | ✅ | 226ms |
| copy-with-header.js — missing source file FAIL: does not silently create an empty destination on missing source | Helper tools work correctly | ✅ | 204ms |
| copy-with-header.js — custom header PASS: a CSS file gets a CSS-style custom header | Helper tools work correctly | ✅ | 216ms |
| copy-with-header.js — custom header FAIL: second line of the file is NOT accidentally the header (header must be line 1 only) | Helper tools work correctly | ✅ | 251ms |
| generate-dashboard-html.js PASS: writes generated-docs/dashboard.html with an auto-refresh meta tag | Helper tools work correctly | ✅ | 297ms |
| generate-dashboard-html.js FAIL: does not crash or produce empty output with no state file | Helper tools work correctly | ✅ | 243ms |
| generate-dashboard-html.js — snapshot (stable HTML) PASS: produces deterministic HTML for a fixed state (after normalising timestamps) | Helper tools work correctly | ✅ | 469ms |
| generate-dashboard-html.js — snapshot (stable HTML) FAIL: different states produce different HTML (proves the normaliser isn't stripping signal) | Helper tools work correctly | ✅ | 451ms |
| generate-telemetry-report.js — timing PASS: computes per-phase active time and excludes user-wait windows | Helper tools work correctly | ✅ | 236ms |
| generate-telemetry-report.js — timing FAIL: an empty ledger yields no phases (does not invent data) | Helper tools work correctly | ✅ | 209ms |
| generate-telemetry-report.js — HTML output PASS: --html emits a self-contained HTML page with inline SVG charts and no external CDN | Helper tools work correctly | ✅ | 384ms |
| generate-telemetry-report.js — tokens PASS: reports tokens unavailable (not fabricated) when no transcript exists | Helper tools work correctly | ✅ | 273ms |
| generate-test-report — buildModel PASS: tallies counts, groups by layer, and keeps the failure message | Helper tools work correctly | ✅ | 25ms |
| generate-test-report — buildModel FAIL: does not count a skipped test as passed | Helper tools work correctly | ✅ | 1ms |
| generate-test-report — fmtDuration PASS: formats sub-second, seconds, and minutes | Helper tools work correctly | ✅ | 0ms |
| generate-test-report — fmtDuration FAIL: returns a placeholder for a missing duration rather than NaN | Helper tools work correctly | ✅ | 0ms |
| generate-test-report — render PASS: emits the plain-language sections and a "needs attention" block with the failure detail | Helper tools work correctly | ✅ | 3ms |
| generate-test-report — render FAIL: an all-pass run is not reported as needing attention | Helper tools work correctly | ✅ | 1ms |
| generate-test-report — render PASS: shows a lines-of-code section when that data is supplied | Helper tools work correctly | ✅ | 14ms |
| generate-test-report — friendlyArea PASS: maps a known layer to plain language and tidies an unknown one | Helper tools work correctly | ✅ | 1ms |
| generate-todo-list.js PASS: returns a JSON array suitable for TodoWrite | Helper tools work correctly | ✅ | 171ms |
| generate-todo-list.js FAIL: does not emit a TodoWrite entry with an empty content field | Helper tools work correctly | ✅ | 133ms |
| import-prototype.js — genesis layout PASS: copies genesis marker files into documentation/ when genesis.md is present | Helper tools work correctly | ✅ | 291ms |
| import-prototype.js — genesis layout FAIL: returns status=error when --from path does not exist | Helper tools work correctly | ✅ | 303ms |
| init-preferences.js — initial write PASS: writes .claude/preferences.json with the given flags | Helper tools work correctly | ✅ | 257ms |
| init-preferences.js — initial write FAIL: rejects non-boolean flag values | Helper tools work correctly | ✅ | 219ms |
| init-preferences.js — idempotency PASS: second invocation without --force skips (reports "skipped" or similar) | Helper tools work correctly | ✅ | 402ms |
| init-preferences.js — idempotency FAIL: --force overwrites, proving idempotency can be bypassed deliberately | Helper tools work correctly | ✅ | 460ms |
| quality-gates.js — JSON shape PASS: always outputs a parseable JSON object with a gates array | Helper tools work correctly | ✅ | 306ms |
| quality-gates.js — JSON shape FAIL: does not return a "conditional pass" marker anywhere in its JSON output | Helper tools work correctly | ✅ | 293ms |
| scan-doc.js — plain markdown file PASS: reports correct line count and text type | Helper tools work correctly | ✅ | 226ms |
| scan-doc.js — plain markdown file FAIL: does not claim a text file is binary | Helper tools work correctly | ✅ | 267ms |
| scan-doc.js — binary file detection PASS: flags a buffer with null bytes as binary | Helper tools work correctly | ✅ | 237ms |
| scan-doc.js — binary file detection FAIL: does not attempt to count lines in a binary buffer as if it were text | Helper tools work correctly | ✅ | 231ms |
| scan-doc.js — keyword counting PASS: counts requested keywords case-insensitively | Helper tools work correctly | ✅ | 217ms |
| scan-doc.js — keyword counting FAIL: keywords not present yield zero, not undefined/crash | Helper tools work correctly | ✅ | 280ms |
| transition-phase.js — --show PASS: reports the current phase when state exists | Helper tools work correctly | ✅ | 229ms |
| transition-phase.js — --show FAIL: returns error when no state file exists | Helper tools work correctly | ✅ | 217ms |
| transition-phase.js — INTAKE → PLAN PASS: transitions when the project brief exists | Helper tools work correctly | ✅ | 260ms |
| transition-phase.js — INTAKE → PLAN FAIL: refuses transition with a descriptive error when current phase is COMPLETE and target is PLAN | Helper tools work correctly | ✅ | 214ms |
| transition-phase.js — idempotent behaviour PASS: --show after writing state is deterministic — same value, same output | Helper tools work correctly | ✅ | 461ms |
| transition-phase.js — idempotent behaviour FAIL: advancing to an invalid phase does NOT silently succeed | Helper tools work correctly | ✅ | 285ms |
| transition-phase.js — --repair PASS: reconstructs state when only artifacts exist | Helper tools work correctly | ✅ | 282ms |
| transition-phase.js — --repair FAIL: --repair in an empty project reports low confidence or error, not false ok | Helper tools work correctly | ✅ | 377ms |
| Tier 2 — telemetry-baseline freshness canary PASS: newest telemetry baseline is newer than orchestrator-rules.md and settings.json | Workflow records stay trustworthy | ✅ | 2ms |
| Tier 2 — telemetry ledger shape PASS: timestamps are monotonic non-decreasing | Workflow records stay trustworthy | ✅ | 4ms |
| Tier 2 — telemetry ledger shape PASS: every agent_start has a matching agent_stop | Workflow records stay trustworthy | ✅ | 2ms |
| Tier 2 — telemetry ledger shape PASS: phase_enter / phase_exit events balance (last phase may stay open) | Workflow records stay trustworthy | ✅ | 1ms |
| Tier 2 — telemetry ledger shape FAIL: detector catches an unbalanced agent ledger | Workflow records stay trustworthy | ✅ | 1ms |
| Tier 2 — telemetry report: timing PASS: active time excludes the user-wait window | Workflow records stay trustworthy | ✅ | 212ms |
| Tier 2 — telemetry report: timing PASS: granular agent spans are correct | Workflow records stay trustworthy | ✅ | 137ms |
| Tier 2 — telemetry report: timing FAIL: a non-existent phase is not present in the report | Workflow records stay trustworthy | ✅ | 179ms |
| Tier 2 — telemetry report: tokens PASS: tokens attribute to the phase and agent that own the timestamp | Workflow records stay trustworthy | ✅ | 237ms |
| Tier 2 — telemetry report: estimate/variance vs golden baseline PASS: estimate reads the harvested baseline and reports counts | Workflow records stay trustworthy | ✅ | 232ms |
| Tier 2 — telemetry report: estimate/variance vs golden baseline PASS: final report computes per-story variance against the baseline (zero for the baseline run itself) | Workflow records stay trustworthy | ✅ | 262ms |
| Tier 2 — telemetry report: estimate/variance vs golden baseline FAIL: estimate without a baseline reports baselineAvailable=false | Workflow records stay trustworthy | ✅ | 235ms |

---

<sub>Generated 2026-06-18 08:38:01 · QA suite version 0.1.0 · code version 9610150 on branch main · Node v24.11.0, Vitest 2.1.9. Time taken is the real wall-clock time; checks run side by side, so it is shorter than adding up each one.</sub>
