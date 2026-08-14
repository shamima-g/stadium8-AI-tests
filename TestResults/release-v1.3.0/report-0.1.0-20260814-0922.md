# Test report — 14 August 2026, 9:22am

A plain-language summary of every check we ran on the project, and how each one did.

## In short

**✅ All clear**

We ran **430** checks in total: **425 passed**, 5 not run this time.

## The numbers

| | |
|---|---|
| Result | ✅ All clear |
| Checks run | 430 |
| Passed | 425 |
| Need attention | 0 |
| Not run this time | 5 |
| Time taken | 34s |
| AI usage | No AI was used in these checks |
| Run by | shamima-g on SHAMIMA-NB |
| When | 14 August 2026, 9:23am → finished 9:23am |
| Repository | https://github.com/Digiata/Stadium-Builder |
| Branch / ref | v1.3.0 (commit b85d808) |
| Version tested | v1.3.0 |
| Tested at | `C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\.targets\release-v1.3.0` |
| Command | `node scripts/generate-test-report.cjs --label release-v1.3.0 --target release --ref v1.3.0` |

## How each area did

| Area | Result | Passed | Need attention | Not run |
|---|:--:|--:|--:|--:|
| Project files follow the rules | ✅ | 31 | 0 | 3 |
| Everything lines up and is consistent | ✅ | 123 | 0 | 0 |
| Design | ✅ | 29 | 0 | 0 |
| Flexibility | ✅ | 38 | 0 | 0 |
| Git machinery | ✅ | 3 | 0 | 0 |
| Built-in safety checks | ✅ | 60 | 0 | 0 |
| Saved data has the right shape | ✅ | 19 | 0 | 0 |
| Helper tools work correctly | ✅ | 108 | 0 | 2 |
| Tier 2 recorded run | ✅ | 14 | 0 | 0 |
| The app's own tests | — | — | — | — |
| Using the app like a person would | — | — | — | — |
| Final quality gates | — | — | — | — |

> **The app's own tests:** Not run yet — no saved result to show.
> **Using the app like a person would:** Not run yet — no saved result to show.
> **Final quality gates:** Not run yet — no saved result to show.

## What needs attention

Nothing — every check passed. 🎉

## Every check we ran

The full list, in case you want the detail. ✅ passed · ❌ needs attention · ⏭️ not run.

| Check | Area | Result | Time |
|---|---|:--:|--:|
| TG-31 rule — findInventedPaths FAIL: flags a path not in the spec | Project files follow the rules | ✅ | 5ms |
| TG-31 rule — findInventedPaths PASS: accepts an exact spec match | Project files follow the rules | ✅ | 2ms |
| TG-31 rule — findInventedPaths PASS: matches a parameterised path by shape | Project files follow the rules | ✅ | 1ms |
| TG-31 rule — findInventedPaths PASS: ignores strings that are not /api paths | Project files follow the rules | ✅ | 1ms |
| TG-31 regression — real spec + endpoints every code path matches the spec | Project files follow the rules | ⏭️ | — |
| TG-33 rule — findSuppressions FAIL: flags a @ts-ignore | Project files follow the rules | ✅ | 5ms |
| TG-33 rule — findSuppressions FAIL: flags an eslint-disable-next-line | Project files follow the rules | ✅ | 1ms |
| TG-33 rule — findSuppressions FAIL: flags every directive variant | Project files follow the rules | ✅ | 1ms |
| TG-33 rule — findSuppressions PASS: clean code has no suppressions | Project files follow the rules | ✅ | 1ms |
| TG-33 regression — real web/src/ has no suppression directives in any source file | Project files follow the rules | ✅ | 36ms |
| TG-34 rule — findJargon FAIL: flags engineering jargon | Project files follow the rules | ✅ | 4ms |
| TG-34 rule — findJargon FAIL: flags a gate reference | Project files follow the rules | ✅ | 3ms |
| TG-34 rule — findJargon PASS: allows plain-language phrasing | Project files follow the rules | ✅ | 1ms |
| TG-34 rule — extractManualChecklist PASS: extracts only the manual-test section (not the dev metadata around it) | Project files follow the rules | ✅ | 2ms |
| TG-34 rule — extractManualChecklist FAIL: a jargon-laden manual-test line is caught in the extracted section | Project files follow the rules | ✅ | 0ms |
| TG-34 rule — extractManualChecklist PASS: returns empty string when there is no manual-test section | Project files follow the rules | ✅ | 1ms |
| TG-34 regression — real manual-test checklists (in story files) contain no engineering jargon | Project files follow the rules | ⏭️ | — |
| TG-38 rule — extractRole / roleViolation PASS: extracts a standard role and reports no violation | Project files follow the rules | ✅ | 4ms |
| TG-38 rule — extractRole / roleViolation PASS: "All authenticated users" is a valid non-restricted role | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation PASS: accepts a plain metadata-table row, singular or plural | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation PASS: accepts the bold plural marker | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation PASS: accepts a `## Roles` heading with a bulleted value (dev/main story format) | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation PASS: accepts a `## Role` heading with a plain (unbulleted) value | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation FAIL: an empty `## Roles` section (heading straight into the next heading) is missing | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags an empty table-row role | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags an empty role | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags "N/A" as empty/ambiguous | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags a story with no Role field at all | Project files follow the rules | ✅ | 1ms |
| TG-38 regression — real story files every story file has a valid Role | Project files follow the rules | ⏭️ | — |
| TG-32 rule — findNonShadcnUiImports FAIL: flags a hand-crafted Button import | Project files follow the rules | ✅ | 6ms |
| TG-32 rule — findNonShadcnUiImports PASS: accepts a Shadcn Button import | Project files follow the rules | ✅ | 1ms |
| TG-32 rule — findNonShadcnUiImports PASS: ignores non-UI imports | Project files follow the rules | ✅ | 1ms |
| TG-32 rule — findNonShadcnUiImports FAIL: flags one offender even when mixed with a valid import | Project files follow the rules | ✅ | 1ms |
| TG-32 regression — real web/src/ all UI-primitive imports come from @/components/ui/ | Project files follow the rules | ✅ | 23ms |
| agent frontmatter — every agent has required fields PASS: api-connectivity-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 19ms |
| agent frontmatter — every agent has required fields PASS: code-review-runner.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 15ms |
| agent frontmatter — every agent has required fields PASS: design-api-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 3ms |
| agent frontmatter — every agent has required fields PASS: design-interpreter.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 12ms |
| agent frontmatter — every agent has required fields PASS: design-style-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 8ms |
| agent frontmatter — every agent has required fields PASS: developer.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 21ms |
| agent frontmatter — every agent has required fields PASS: feature-planner.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — every agent has required fields PASS: intake-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 10ms |
| agent frontmatter — every agent has required fields PASS: mock-setup-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — every agent has required fields PASS: playwright-runner.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 8ms |
| agent frontmatter — every agent has required fields PASS: test-generator.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 8ms |
| agent frontmatter — every agent has required fields PASS: type-generator-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 6ms |
| agent frontmatter — name matches filename PASS: name in api-connectivity-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 12ms |
| agent frontmatter — name matches filename PASS: name in code-review-runner.md matches the filename stem | Everything lines up and is consistent | ✅ | 8ms |
| agent frontmatter — name matches filename PASS: name in design-api-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 10ms |
| agent frontmatter — name matches filename PASS: name in design-interpreter.md matches the filename stem | Everything lines up and is consistent | ✅ | 10ms |
| agent frontmatter — name matches filename PASS: name in design-style-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 5ms |
| agent frontmatter — name matches filename PASS: name in developer.md matches the filename stem | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — name matches filename PASS: name in feature-planner.md matches the filename stem | Everything lines up and is consistent | ✅ | 10ms |
| agent frontmatter — name matches filename PASS: name in intake-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 6ms |
| agent frontmatter — name matches filename PASS: name in mock-setup-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 2ms |
| agent frontmatter — name matches filename PASS: name in playwright-runner.md matches the filename stem | Everything lines up and is consistent | ✅ | 5ms |
| agent frontmatter — name matches filename PASS: name in test-generator.md matches the filename stem | Everything lines up and is consistent | ✅ | 3ms |
| agent frontmatter — name matches filename PASS: name in type-generator-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 2ms |
| agent README consistency PASS: every agent file has a matching entry in README.md | Everything lines up and is consistent | ✅ | 5ms |
| agent README consistency FAIL: README does not list phantom agents that don't exist on disk | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — model / tools / color are well-formed PASS: api-connectivity-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 5ms |
| agent frontmatter — model / tools / color are well-formed PASS: code-review-runner.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 8ms |
| agent frontmatter — model / tools / color are well-formed PASS: design-api-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 6ms |
| agent frontmatter — model / tools / color are well-formed PASS: design-interpreter.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 4ms |
| agent frontmatter — model / tools / color are well-formed PASS: design-style-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 15ms |
| agent frontmatter — model / tools / color are well-formed PASS: developer.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 16ms |
| agent frontmatter — model / tools / color are well-formed PASS: feature-planner.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 7ms |
| agent frontmatter — model / tools / color are well-formed PASS: intake-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 6ms |
| agent frontmatter — model / tools / color are well-formed PASS: mock-setup-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 5ms |
| agent frontmatter — model / tools / color are well-formed PASS: playwright-runner.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 4ms |
| agent frontmatter — model / tools / color are well-formed PASS: test-generator.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 8ms |
| agent frontmatter — model / tools / color are well-formed PASS: type-generator-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 4ms |
| agent README — referenced scripts exist on disk PASS: every backticked *.js script named in README.md resolves under .claude/scripts/ | Everything lines up and is consistent | ✅ | 18ms |
| CI does not comment on pull requests (post-v1.2.0) PASS: no workflow posts a PR/issue comment | Everything lines up and is consistent | ✅ | 8ms |
| CI does not comment on pull requests (post-v1.2.0) FAIL (teeth): the matcher catches a real github-script comment step | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /api-go-live has a non-empty description | Everything lines up and is consistent | ✅ | 13ms |
| command frontmatter PASS: /api-mock-refresh has a non-empty description | Everything lines up and is consistent | ✅ | 4ms |
| command frontmatter PASS: /api-status has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /continue has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /dashboard has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /migrate-legacy has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /plan has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /quality-check has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /start has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /status has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /upgrade has a non-empty description | Everything lines up and is consistent | ✅ | 4ms |
| command frontmatter — model field valid PASS: api-go-live.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter — model field valid PASS: api-mock-refresh.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 7ms |
| command frontmatter — model field valid PASS: api-status.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter — model field valid PASS: continue.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter — model field valid PASS: dashboard.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter — model field valid PASS: migrate-legacy.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 10ms |
| command frontmatter — model field valid PASS: plan.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 4ms |
| command frontmatter — model field valid PASS: quality-check.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 11ms |
| command frontmatter — model field valid PASS: start.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 5ms |
| command frontmatter — model field valid PASS: status.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 11ms |
| command frontmatter — model field valid PASS: upgrade.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 12ms |
| CLAUDE.md → commands cross-reference PASS: every /command referenced in CLAUDE.md exists under .claude/commands/ | Everything lines up and is consistent | ✅ | 5ms |
| orchestrator-rules.md → agent files PASS: every agent mentioned by name in orchestrator-rules.md exists | Everything lines up and is consistent | ✅ | 8ms |
| agents/README.md agent catalog PASS: .claude/agents/README.md references every real agent at least once | Everything lines up and is consistent | ✅ | 3ms |
| CLAUDE.md → policies/ files PASS: every policy file referenced in CLAUDE.md exists | Everything lines up and is consistent | ✅ | 4ms |
| build-from-design — the design digest is a wired contract (post-v1.2.0) PASS: design-interpreter emits the digest, a template shapes it, and downstream agents read it | Everything lines up and is consistent | ✅ | 115ms |
| build-from-design — the design digest is a wired contract (post-v1.2.0) PASS (teeth): a non-existent digest path is referenced by nothing | Everything lines up and is consistent | ✅ | 324ms |
| generated-doc-conventions.json — shape PASS: contains exactly the six expected conventions | Everything lines up and is consistent | ✅ | 6ms |
| generated-doc-conventions.json — shape PASS: every convention has the required fields | Everything lines up and is consistent | ✅ | 5ms |
| generated-doc-conventions.json — self-consistency PASS: each convention's example matches its filenamePattern | Everything lines up and is consistent | ✅ | 3ms |
| generated-doc-conventions.json — self-consistency FAIL-shape: each counterexample is drift — matches badPattern but NOT filenamePattern | Everything lines up and is consistent | ✅ | 4ms |
| generated-doc-conventions.json — agreement with consumers + mirror PASS: naming-conventions.md documents every convention (by example filename) | Everything lines up and is consistent | ✅ | 4ms |
| generated-doc-conventions.json — agreement with consumers + mirror PASS: both the hook and the validator read generated-doc-conventions.json | Everything lines up and is consistent | ✅ | 2ms |
| shared/epic-picker.md — legend matches the collector's plan statuses (v1.2.0) PASS: every legend glyph is a real status, and every status has a glyph | Everything lines up and is consistent | ✅ | 3.4s |
| shared/epic-picker.md — legend matches the collector's plan statuses (v1.2.0) PASS: the legend parser has teeth (finds real rows, skips the header) | Everything lines up and is consistent | ✅ | 204ms |
| import-prototype was cleanly removed (post-v1.2.0) PASS: the script is absent and nothing under .claude references it | Everything lines up and is consistent | ✅ | 106ms |
| import-prototype was cleanly removed (post-v1.2.0) PASS (teeth): the reference scanner finds references that really exist | Everything lines up and is consistent | ✅ | 421ms |
| manual-test approval — check-off page is generated PASS: continue.md § B7.1 generates the manual-tests.html check-off page | Everything lines up and is consistent | ✅ | 6ms |
| manual-test approval — check-off page is generated PASS: approval-pattern.md documents the Manual-Test Check-off Page and its results payload | Everything lines up and is consistent | ✅ | 3ms |
| manual-test approval — results are persisted PASS: continue.md persists the handed-back results to state.json.epic.manualTestResults | Everything lines up and is consistent | ✅ | 3ms |
| manual-test approval — results are persisted — failure-path coverage FAIL: a tampered continue.md that never persists results is detected | Everything lines up and is consistent | ✅ | 166ms |
| manual-test approval — fix-cycle re-display PASS: continue.md re-displays the approval carrying previously-passed ticks forward | Everything lines up and is consistent | ✅ | 6ms |
| manual-test approval — fix-cycle re-display PASS: only the affected tests come back unchecked after a fix | Everything lines up and is consistent | ✅ | 3ms |
| manual-test approval — fix-cycle re-display PASS: the manual-test fix loop is capped at 3 cycles | Everything lines up and is consistent | ✅ | 3ms |
| manual-test approval — fix-cycle re-display PASS: the check-off page pre-ticks from prior results (approval-pattern.md) | Everything lines up and is consistent | ✅ | 2ms |
| manual-test approval — fix-cycle re-display — failure-path coverage FAIL: a tampered continue.md that re-asks the whole list from scratch is detected | Everything lines up and is consistent | ✅ | 126ms |
| manual-test approval — free-text issue handling PASS: continue.md captures a free-text failure and classifies it before fixing | Everything lines up and is consistent | ✅ | 5ms |
| manual-test approval — free-text issue handling PASS: continue.md re-presents the manual-test approval after the fix (never advances silently) | Everything lines up and is consistent | ✅ | 3ms |
| manual-test approval — content shown before the question PASS: approval-pattern.md requires the summary/content before calling AskUserQuestion | Everything lines up and is consistent | ✅ | 2ms |
| manual-test approval — free-text handling — failure-path coverage FAIL: a tampered continue.md that never captures/classifies a free-text issue is detected | Everything lines up and is consistent | ✅ | 116ms |
| retired report commands/skills are gone (post-v1.2.0) PASS: none of the retired report surfaces exist | Everything lines up and is consistent | ✅ | 5ms |
| retired report commands/skills are gone (post-v1.2.0) PASS (teeth): the replacement report skills ARE present | Everything lines up and is consistent | ✅ | 2ms |
| settings.json structural validity PASS: parses as valid JSON | Everything lines up and is consistent | ✅ | 5ms |
| settings.json structural validity PASS: has expected top-level sections | Everything lines up and is consistent | ✅ | 1ms |
| settings.json structural validity FAIL: deny list is not empty (security invariant) | Everything lines up and is consistent | ✅ | 2ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/workflow-guard.js | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/inject-phase-context.js | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/inject-agent-context.js | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/bash-permission-checker.js | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/enforce-generated-doc-names.js | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook timeouts are reasonable PASS: no hook declares a timeout over 60 seconds | Everything lines up and is consistent | ✅ | 2ms |
| shared/ + policies/ — no orphans PASS: there are shared and policy docs to check (sanity) | Everything lines up and is consistent | ✅ | 2ms |
| shared/ + policies/ — no orphans PASS: shared/agent-autonomy.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 1ms |
| shared/ + policies/ — no orphans PASS: shared/agent-startup.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/approval-pattern.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/build-report-procedure.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 1ms |
| shared/ + policies/ — no orphans PASS: shared/epic-picker.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 1ms |
| shared/ + policies/ — no orphans PASS: shared/generated-doc-conventions.json is referenced by at least one other file | Everything lines up and is consistent | ✅ | 1ms |
| shared/ + policies/ — no orphans PASS: shared/naming-conventions.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/orchestrator-rules.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/roles-snippets.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/authentication-intake.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/bff-auth-pattern.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/compliance-intake.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/epic-branch-concurrency.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/file-operations.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/styling-centralisation.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/testing-policy.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — every reference resolves PASS: no reference points at a missing shared/policy file | Everything lines up and is consistent | ✅ | 307ms |
| shared/ + policies/ — the detectors work (good/broken) PASS: extractSharedPolicyRefs finds refs with and without a prefix | Everything lines up and is consistent | ✅ | 2ms |
| shared/ + policies/ — the detectors work (good/broken) FAIL: an orphan (unreferenced basename) is detectable in a synthetic corpus | Everything lines up and is consistent | ✅ | 0ms |
| contact-form-design replay — navigability (#14/AC3) design-digest-written: the intake digest is a filled read-back with a real uncertainty | Design | ✅ | 6ms |
| contact-form-design replay — navigability (#14/AC3) design-uncertainties-surfaced: it flagged where the submitted message goes (no backend) | Design | ✅ | 1ms |
| contact-form-design replay — navigability (#14/AC3) navigability: every designed screen has a live route — the user can move through it | Design | ✅ | 3ms |
| contact-form-design replay — navigability (#14/AC3) navigability teeth: the check would catch a designed screen with no route | Design | ✅ | 1ms |
| epicHasDecisionTrail — Tier-2 journal refinement PASS: a non-empty journal.md is a decision trail | Design | ✅ | 4ms |
| epicHasDecisionTrail — Tier-2 journal refinement PASS: no journal, but the design digest records decisions (design-driven run) | Design | ✅ | 2ms |
| epicHasDecisionTrail — Tier-2 journal refinement BROKEN: a present-but-empty journal.md fails (a real bug, kept with teeth) | Design | ✅ | 1ms |
| epicHasDecisionTrail — Tier-2 journal refinement BROKEN: no journal and no recorded decisions anywhere fails | Design | ✅ | 1ms |
| design-capture replay — real run traces (#14/#15) design-digest-written: the intake digest is a filled read-back | Design | ✅ | 7ms |
| design-capture replay — real run traces (#14/#15) design-uncertainties-surfaced: the intake digest surfaces real uncertainties incl. the due-date | Design | ✅ | 1ms |
| design-capture replay — real run traces (#14/#15) design-decisions-preserved: the design update kept every prior decision (reconciled in place) | Design | ✅ | 2ms |
| design-capture replay — real run traces (#14/#15) design-conflict-asks (recorded): the after-digest records blue kept over the update purple | Design | ✅ | 1ms |
| design-capture replay — real run traces (#14/#15) design-update-scoped: only Board + Task detail screen routes changed — Settings untouched | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) PASS: a filled digest is ready for Intake (real screens + palette + all sections) | Design | ✅ | 5ms |
| build-from-design — deterministic digest traces (#14/#15) BROKEN: the unfilled digest template is NOT ready (placeholders only) | Design | ✅ | 2ms |
| build-from-design — deterministic digest traces (#14/#15) BROKEN: a digest missing the Uncertainties section is not ready | Design | ✅ | 2ms |
| build-from-design — deterministic digest traces (#14/#15) BROKEN: an Uncertainties section that is present but EMPTY is not ready | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) PASS: an unusable design element is surfaced under Uncertainties | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) BROKEN: an unusable element dropped from Uncertainties is caught (nothing surfaced) | Design | ✅ | 0ms |
| build-from-design — deterministic digest traces (#14/#15) PASS: a re-read that keeps prior decisions (and adds one) preserves them | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) BROKEN: a re-read that drops a prior decision is caught | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) PASS: a rebuild scoped to the named screens touches nothing else | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) BROKEN: a rebuild that changes an un-named screen is caught | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) PASS: page files map to the right app-router URLs | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) PASS: every designed screen has a route (the user can move through it) | Design | ✅ | 1ms |
| build-from-design — deterministic digest traces (#14/#15) BROKEN: a designed screen with no route is caught | Design | ✅ | 0ms |
| feedback-api-design replay — real backend, exact paths (AC4) AC4: every /api path in the generated client matches the spec exactly (no invented paths) | Design | ✅ | 18ms |
| feedback-api-design replay — real backend, exact paths (AC4) AC4: the client calls through the shared API client, not raw fetch or a stand-in layer | Design | ✅ | 1ms |
| feedback-api-design replay — real backend, exact paths (AC4) AC4 teeth: an invented path would be caught | Design | ✅ | 4ms |
| parseChangelog — good input PASS: returns released versions newest-first, skipping Unreleased | Flexibility | ✅ | 4ms |
| parseChangelog — good input PASS: parses the date and typed entries of a version | Flexibility | ✅ | 2ms |
| parseChangelog — broken/edge input PASS: a malformed/typo heading is ignored, not fatal (parser never throws) | Flexibility | ✅ | 4ms |
| parseChangelog — broken/edge input PASS: empty / null input yields an empty list, not an error | Flexibility | ✅ | 1ms |
| entriesBetween PASS: (1.0.0, 1.2.0] returns only the 1.1.0 and 1.2.0 entries | Flexibility | ✅ | 1ms |
| entriesBetween PASS: tolerates a leading "v" on the bounds | Flexibility | ✅ | 1ms |
| entriesBetween BROKEN-RANGE: a reversed or equal range yields [] (no gap), not an error | Flexibility | ✅ | 5ms |
| findExplaining — attribution PASS: a symbol named in the changelog is explained (incl. kebab/spaced variants) | Flexibility | ✅ | 2ms |
| findExplaining — attribution BROKEN: a symbol NOT in any entry is unexplained (returns null) | Flexibility | ✅ | 2ms |
| compareVersions / normaliseVersion PASS: orders versions numerically and strips a leading v | Flexibility | ✅ | 1ms |
| compareVersions / normaliseVersion PASS: a pre-release sorts before its plain release | Flexibility | ✅ | 0ms |
| diffLive PASS: identical templates produce no differences | Flexibility | ✅ | 4ms |
| diffLive PASS: a value only on one side is reported with the correct side | Flexibility | ✅ | 1ms |
| diffLive PASS: an order-only change on an ordered list is flagged | Flexibility | ✅ | 1ms |
| verdict — the three-way rule GREEN: no differences | Flexibility | ✅ | 1ms |
| verdict — the three-way rule AMBER: differences that are ALL explained by the changelog (pending promotion) | Flexibility | ✅ | 2ms |
| verdict — the three-way rule RED: a difference with NO changelog entry behind it is unexplained | Flexibility | ✅ | 2ms |
| verdict — the three-way rule RED: an order-only change is treated as needing review (unexplained) | Flexibility | ✅ | 0ms |
| renderReport — provenance header PASS: emits the command, generated-at, and each side's repository + version | Flexibility | ✅ | 1ms |
| renderReport — provenance header FAIL-guard: with no meta, the report still renders (no provenance header, no crash) | Flexibility | ✅ | 1ms |
| contract selection — good case PASS: an active target picks its own contract file | Flexibility | ✅ | 4ms |
| contract selection — good case PASS: no target falls back to the single default contract | Flexibility | ✅ | 1ms |
| contract selection — good case BROKEN: a target with no matching contract file falls back to the default (never crashes) | Flexibility | ✅ | 1ms |
| the per-target contracts exist and are well-formed PASS: template-contract.dev.json has every required list | Flexibility | ✅ | 4ms |
| the per-target contracts exist and are well-formed PASS: template-contract.release.json has every required list | Flexibility | ✅ | 3ms |
| the per-target contracts exist and are well-formed PASS: the release contract matches the documented seven-stage order | Flexibility | ✅ | 5ms |
| channel resolution — good case PASS: dev and release resolve to their repo URL + contract | Flexibility | ✅ | 8ms |
| channel resolution — good case PASS: the real targets.json lists dev and release, each with a repo + contract | Flexibility | ✅ | 5ms |
| channel resolution — broken case BROKEN: an unknown target name throws a clear error listing the known ones (no silent default) | Flexibility | ✅ | 7ms |
| channel resolution — broken case PASS: loadTargets rejects a targets file with no targets | Flexibility | ✅ | 1ms |
| suiteVersion PASS: reads the suite baseline from the VERSION file | Flexibility | ✅ | 7ms |
| templateVersion — good case PASS: reads templateRef from a valid template-version.json | Flexibility | ✅ | 6ms |
| templateVersion — broken/absent marker BROKEN: a malformed marker does not crash — reports unknown (no git tag here) | Flexibility | ✅ | 118ms |
| templateVersion — broken/absent marker PASS: a missing marker reports unknown, not an error | Flexibility | ✅ | 279ms |
| versionGap — direction PASS: equal versions read as in-sync | Flexibility | ✅ | 9ms |
| versionGap — direction PASS: an older template reads as template-ahead=false (suite-ahead) | Flexibility | ✅ | 7ms |
| versionGap — direction PASS: a newer template reads as template-ahead | Flexibility | ✅ | 7ms |
| versionGap — direction BROKEN: an unreadable template version reads as unknown gap, never throws | Flexibility | ✅ | 142ms |
| git-machinery — epic lifecycle: branch → merge → complete → merged on the dashboard PASS: after merge + mark-epic-complete, the epic shows as merged (COMPLETE), not in-flight | Git machinery | ✅ | 3.5s |
| git-machinery — auto-combine vs. conflict substrate PASS: two epics adding different tokens combine on their own (clean merge) | Git machinery | ✅ | 3s |
| git-machinery — auto-combine vs. conflict substrate FAIL: two epics changing the SAME token line conflict (the workflow's halt trigger) | Git machinery | ✅ | 4.4s |
| bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf / — deny path | Built-in safety checks | ✅ | 449ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf /* — deny path with wildcard | Built-in safety checks | ✅ | 183ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat ~/.ssh/id_rsa — ssh private key | Built-in safety checks | ✅ | 196ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat /root/.ssh/id_rsa — ssh private key absolute | Built-in safety checks | ✅ | 139ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): type id_rsa.pem — ssh key via Windows type | Built-in safety checks | ✅ | 178ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): Get-Content id_rsa — ssh key via PowerShell Get-Content | Built-in safety checks | ✅ | 142ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat mykey.pem — .pem via cat | Built-in safety checks | ✅ | 164ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): sed -n 1p credentials — credentials via sed | Built-in safety checks | ✅ | 165ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): grep password credentials.json — credentials file | Built-in safety checks | ✅ | 184ms |
| bash-permission-checker — allow matrix PASS: allow node .claude/scripts/transition-phase.js --show — node running a claude script | Built-in safety checks | ✅ | 159ms |
| bash-permission-checker — allow matrix PASS: allow node .claude/scripts/copy-with-header.js --from a --to b — copy-with-header | Built-in safety checks | ✅ | 151ms |
| bash-permission-checker — allow matrix PASS: allow git pull — git pull is always auto-approved | Built-in safety checks | ✅ | 214ms |
| bash-permission-checker — allow matrix PASS: allow git add generated-docs/ — git add scoped to generated-docs | Built-in safety checks | ✅ | 171ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf / outright | Built-in safety checks | ✅ | 135ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm  -rf  / outright | Built-in safety checks | ✅ | 147ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -r -f / outright | Built-in safety checks | ✅ | 184ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm --recursive --force / outright | Built-in safety checks | ✅ | 154ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf ~ outright | Built-in safety checks | ✅ | 176ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf $HOME outright | Built-in safety checks | ✅ | 173ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW /bin/rm -rf / outright | Built-in safety checks | ✅ | 176ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW sudo rm -rf / outright | Built-in safety checks | ✅ | 146ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW bash -c "rm -rf /" outright | Built-in safety checks | ✅ | 123ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW eval "rm -rf /" outright | Built-in safety checks | ✅ | 160ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW  rm -rf / outright | Built-in safety checks | ✅ | 143ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW cat ~/.ssh/id_rsa && true outright | Built-in safety checks | ✅ | 146ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW true \|\| cat /etc/shadow outright | Built-in safety checks | ✅ | 233ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does not deny git worktree add -b main-change/x ../tmp origin/main — worktree add for the main-landing write | Built-in safety checks | ✅ | 193ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does not deny git worktree remove ../tmp — worktree remove (bare path) | Built-in safety checks | ✅ | 210ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does not deny git worktree list — worktree list (read-only) | Built-in safety checks | ✅ | 183ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does not deny git worktree prune — worktree prune (cleanup) | Built-in safety checks | ✅ | 181ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does not deny git push --force-with-lease origin epic/x — force-with-lease scoped to epic/* | Built-in safety checks | ✅ | 219ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does not deny npm run test:e2e:install — multi-segment npm script | Built-in safety checks | ✅ | 155ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does not deny npm run test:e2e:ui — multi-segment npm script | Built-in safety checks | ✅ | 151ms |
| bash-permission-checker — worktree + force-push (v1.2.0) FAIL safely (must deny): git push origin +epic/x — force via +refspec | Built-in safety checks | ✅ | 194ms |
| bash-permission-checker — worktree + force-push (v1.2.0) FAIL safely (must deny): git push -f origin main — force via -f | Built-in safety checks | ✅ | 157ms |
| bash-permission-checker — worktree + force-push (v1.2.0) FAIL safely (must deny): git push origin --force — force via --force | Built-in safety checks | ✅ | 180ms |
| bash-permission-checker — worktree + force-push (v1.2.0) FAIL safely (must deny): git push origin --delete topic — remote branch delete | Built-in safety checks | ✅ | 142ms |
| bash-permission-checker — worktree + force-push (v1.2.0) FAIL safely (must deny): git push --no-verify origin epic/x — bypasses pre-push hooks | Built-in safety checks | ✅ | 180ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does NOT auto-approve git worktree remove --force ../tmp — remove --force must not auto-approve | Built-in safety checks | ✅ | 258ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does NOT auto-approve git worktree add --force ../tmp origin/main — add --force must not auto-approve | Built-in safety checks | ✅ | 193ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does NOT hard-deny git push origin epic/report-f — branch name ends in -f, not the -f flag | Built-in safety checks | ✅ | 218ms |
| bash-permission-checker — worktree + force-push (v1.2.0) PASS: does NOT hard-deny git push origin main && echo "ok" — benign chained command after a safe push | Built-in safety checks | ✅ | 282ms |
| bash-permission-checker — fallthrough for ordinary commands PASS: falls through (no decision) for a benign unrelated command | Built-in safety checks | ✅ | 241ms |
| bash-permission-checker — fallthrough for ordinary commands FAIL: does not crash or exit non-zero for empty input | Built-in safety checks | ✅ | 184ms |
| enforce-generated-doc-names.js — the six conventions PASS: [project-facts] a correctly-named new file is allowed (project.md) | Built-in safety checks | ✅ | 280ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [project-facts] a drift-named new file is blocked (project-facts.md) | Built-in safety checks | ✅ | 236ms |
| enforce-generated-doc-names.js — the six conventions PASS: [epic-brief] a correctly-named new file is allowed (brief.md) | Built-in safety checks | ✅ | 216ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [epic-brief] a drift-named new file is blocked (epic-brief.md) | Built-in safety checks | ✅ | 208ms |
| enforce-generated-doc-names.js — the six conventions PASS: [epic-state] a correctly-named new file is allowed (state.json) | Built-in safety checks | ✅ | 324ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [epic-state] a drift-named new file is blocked (epic-state.json) | Built-in safety checks | ✅ | 283ms |
| enforce-generated-doc-names.js — the six conventions PASS: [epic-journal] a correctly-named new file is allowed (journal.md) | Built-in safety checks | ✅ | 296ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [epic-journal] a drift-named new file is blocked (epic-journal.md) | Built-in safety checks | ✅ | 341ms |
| enforce-generated-doc-names.js — the six conventions PASS: [story-file] a correctly-named new file is allowed (story-3-nav.md) | Built-in safety checks | ✅ | 381ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [story-file] a drift-named new file is blocked (story-3.md) | Built-in safety checks | ✅ | 507ms |
| enforce-generated-doc-names.js — the six conventions PASS: [e2e-spec] a correctly-named new file is allowed (epic-task-browsing-story-3-nav.spec.ts) | Built-in safety checks | ✅ | 494ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [e2e-spec] a drift-named new file is blocked (story-3-nav.spec.ts) | Built-in safety checks | ✅ | 544ms |
| enforce-generated-doc-names.js — fall-through and guards PASS: a non-gated tool (Read) falls through | Built-in safety checks | ✅ | 500ms |
| enforce-generated-doc-names.js — fall-through and guards PASS: an ungoverned filename under a governed dir falls through | Built-in safety checks | ✅ | 595ms |
| enforce-generated-doc-names.js — fall-through and guards PASS: a drift name is grandfathered when the file already exists on disk | Built-in safety checks | ✅ | 498ms |
| enforce-generated-doc-names.js — fall-through and guards FAIL: the write-location guard blocks an artifact path nested under web/ | Built-in safety checks | ✅ | 613ms |
| state.json schema — valid documents PASS: defaultEpicState() output validates | Saved data has the right shape | ✅ | 5ms |
| state.json schema — valid documents PASS: a hand-seeded epic state (BUILD, mixed story statuses) validates | Saved data has the right shape | ✅ | 89ms |
| state.json schema — valid documents PASS: every phase in the enum is a valid state.phase | Saved data has the right shape | ✅ | 1ms |
| state.json schema — valid documents PASS: the state.json written by `epic-state.js --init` validates | Saved data has the right shape | ✅ | 219ms |
| state.json schema — invalid documents are rejected FAIL: a phase not in EPIC_PHASES (e.g. legacy "INTAKE") is rejected | Saved data has the right shape | ✅ | 0ms |
| state.json schema — invalid documents are rejected FAIL: an unknown story status is rejected | Saved data has the right shape | ✅ | 0ms |
| state.json schema — invalid documents are rejected FAIL: a missing epic.slug is rejected | Saved data has the right shape | ✅ | 0ms |
| state.json schema — invalid documents are rejected FAIL: a non-kebab epic.slug is rejected | Saved data has the right shape | ✅ | 0ms |
| state.json — transition graph is well-formed PASS: every transition key and target is a known phase | Saved data has the right shape | ✅ | 3ms |
| state.json — transition graph is well-formed PASS: PLAN → BUILD is allowed | Saved data has the right shape | ✅ | 0ms |
| state.json — transition graph is well-formed FAIL: PLAN → MANUAL-TEST is NOT a valid transition (proves the graph is restrictive) | Saved data has the right shape | ✅ | 0ms |
| state.json — enums match the documented epic-branch contract (drift guard) PASS: EPIC_PHASES equals the documented seven-stage list | Saved data has the right shape | ✅ | 1ms |
| state.json — enums match the documented epic-branch contract (drift guard) PASS: STORY_STATUS_VALUES equals the documented set | Saved data has the right shape | ✅ | 0ms |
| state.json — enums match the documented epic-branch contract (drift guard) PASS: E2E_STATUS_VALUES contains the documented core statuses | Saved data has the right shape | ✅ | 0ms |
| intake-manifest.json schema PASS: default manifest (Team Task Manager) validates | Saved data has the right shape | ✅ | 120ms |
| intake-manifest.json schema PASS: BFF variant overlay validates | Saved data has the right shape | ✅ | 99ms |
| intake-manifest.json schema FAIL: invalid dataSource value is rejected | Saved data has the right shape | ✅ | 1ms |
| intake-manifest.json schema FAIL: artifact entry without `generate` boolean is rejected | Saved data has the right shape | ✅ | 0ms |
| intake-manifest.json schema FAIL: invalid authMethod is rejected | Saved data has the right shape | ✅ | 0ms |
| apply-template — /upgrade deletion safety (v1.2.0) deletes retired template files but never the user's own work | Helper tools work correctly | ✅ | 3.9s |
| collect-dashboard-data.js — status detection PASS: returns "no_project" when nothing has started | Helper tools work correctly | ✅ | 400ms |
| collect-dashboard-data.js — status detection FAIL: does NOT report "ok" or crash when only legacy state exists | Helper tools work correctly | ✅ | 293ms |
| collect-dashboard-data.js — the plan and its readiness PASS: with project.md + epic-plan.md, returns "ok" with the plan and derived readiness | Helper tools work correctly | ✅ | 681ms |
| collect-dashboard-data.js — the plan and its readiness FAIL: does not mark a dependent epic "ready" while its dependency is unmet | Helper tools work correctly | ✅ | 757ms |
| collect-dashboard-data.js — an in-flight epic on its branch PASS: an epic/<slug> branch with a state.json surfaces as in-flight with its phase and story counts | Helper tools work correctly | ✅ | 2.2s |
| collect-dashboard-data.js — an in-flight epic on its branch FAIL: a branch whose slug is not a valid epic/<kebab-slug> is surfaced, not silently dropped | Helper tools work correctly | ✅ | 2.2s |
| collect-dashboard-data.js — a parked (ready-to-build) epic PASS: a READY-TO-BUILD epic surfaces as parked (ready-to-build), not building | Helper tools work correctly | ✅ | 2.7s |
| collect-dashboard-data.js — a parked (ready-to-build) epic FAIL: the collector discriminates parked from building (a BUILD epic → building) | Helper tools work correctly | ✅ | 3.6s |
| collect-dashboard-data.js — --format=text PASS: text format is human-readable and names the project and its plan | Helper tools work correctly | ✅ | 1.3s |
| collect-dashboard-data.js — --format=text FAIL: text format does not leak raw JSON braces into user-facing output | Helper tools work correctly | ✅ | 1.2s |
| collectors — dashboard and build-report agree on project status (v1.2.0) PASS: both collectors classify a no_project tree identically | Helper tools work correctly | ✅ | 2.2s |
| collectors — dashboard and build-report agree on project status (v1.2.0) PASS: both collectors classify a ok tree identically | Helper tools work correctly | ✅ | 3.6s |
| collectors — dashboard and build-report agree on project status (v1.2.0) PASS: both collectors classify a legacy_detected tree identically | Helper tools work correctly | ✅ | 3.1s |
| collectors — dashboard and build-report agree on project status (v1.2.0) FAIL: the classifier discriminates (the three states are NOT all the same status) | Helper tools work correctly | ✅ | 5.5s |
| generate-dashboard-html.js PASS: writes dashboard.html with an auto-refresh meta tag when a project exists | Helper tools work correctly | ✅ | 1s |
| generate-dashboard-html.js FAIL: still writes usable HTML (never a half-written/empty file) with no project at all | Helper tools work correctly | ✅ | 390ms |
| generate-dashboard-html.js — snapshot (stable HTML) PASS: produces deterministic HTML for a fixed state (after normalising timestamps) | Helper tools work correctly | ✅ | 1.9s |
| generate-dashboard-html.js — snapshot (stable HTML) FAIL: different states produce different HTML (proves the normaliser isn't stripping signal) | Helper tools work correctly | ✅ | 4s |
| generate-test-report — buildModel PASS: tallies counts, groups by layer, and keeps the failure message | Helper tools work correctly | ✅ | 16ms |
| generate-test-report — buildModel FAIL: does not count a skipped test as passed | Helper tools work correctly | ✅ | 1ms |
| generate-test-report — fmtDuration PASS: formats sub-second, seconds, and minutes | Helper tools work correctly | ✅ | 0ms |
| generate-test-report — fmtDuration FAIL: returns a placeholder for a missing duration rather than NaN | Helper tools work correctly | ✅ | 0ms |
| generate-test-report — render PASS: emits the plain-language sections and a "needs attention" block with the failure detail | Helper tools work correctly | ✅ | 3ms |
| generate-test-report — render FAIL: an all-pass run is not reported as needing attention | Helper tools work correctly | ✅ | 1ms |
| generate-test-report — render PASS: shows a lines-of-code section when that data is supplied | Helper tools work correctly | ✅ | 15ms |
| generate-test-report — render PASS: renders the provenance rows (command, repository, branch, version tested) when supplied | Helper tools work correctly | ✅ | 1ms |
| generate-test-report — render FAIL-guard: without provenance, no repository/version rows are emitted | Helper tools work correctly | ✅ | 0ms |
| generate-test-report — buildProvenance PASS: a --target run resolves the repo from targets.json and uses the ref as the version | Helper tools work correctly | ✅ | 397ms |
| generate-test-report — buildProvenance FAIL-guard: a local run (no --target) reports "local checkout", never a crash | Helper tools work correctly | ✅ | 726ms |
| generate-test-report — friendlyArea PASS: maps a known layer to plain language and tidies an unknown one | Helper tools work correctly | ✅ | 1ms |
| report generators — HTML-escape data-derived strings (v1.2.0) PASS: the dashboard escapes a markup-bearing epic name / story title | Helper tools work correctly | ✅ | 3.5s |
| report generators — HTML-escape data-derived strings (v1.2.0) PASS: the build report escapes a markup-bearing epic name / story title | Helper tools work correctly | ✅ | 3.6s |
| import-prototype.js — genesis layout PASS: copies genesis marker files into documentation/ when genesis.md is present | Helper tools work correctly | ⏭️ | — |
| import-prototype.js — genesis layout FAIL: returns status=error when --from path does not exist | Helper tools work correctly | ⏭️ | — |
| init-preferences.js — initial write PASS: writes .claude/preferences.json with the given flags | Helper tools work correctly | ✅ | 316ms |
| init-preferences.js — initial write FAIL: rejects non-boolean flag values | Helper tools work correctly | ✅ | 407ms |
| init-preferences.js — idempotency PASS: second invocation without --force skips (reports "skipped" or similar) | Helper tools work correctly | ✅ | 616ms |
| init-preferences.js — idempotency FAIL: --force overwrites, proving idempotency can be bypassed deliberately | Helper tools work correctly | ✅ | 568ms |
| maintainer report — user-involvement summary + decision log (post-v1.2.0) PASS: a populated cost file surfaces the unattended-phase count, answer time, and the logged question | Helper tools work correctly | ✅ | 2.4s |
| maintainer report — user-involvement summary + decision log (post-v1.2.0) PASS (teeth): a question absent from the cost file does not appear | Helper tools work correctly | ✅ | 3.5s |
| mark-epic-complete.js — valid finalisation PASS: flips COMPLETE-ON-BRANCH → COMPLETE and refreshes lastUpdated | Helper tools work correctly | ✅ | 365ms |
| mark-epic-complete.js — valid finalisation PASS: also finalises from EPIC-END and MANUAL-TEST (uncommitted-tip recovery) | Helper tools work correctly | ✅ | 611ms |
| mark-epic-complete.js — valid finalisation PASS: is idempotent — a second run stays COMPLETE and reports "already complete" | Helper tools work correctly | ✅ | 661ms |
| mark-epic-complete.js — refuses invalid input FAIL: refuses a premature phase (BUILD) and leaves the state untouched | Helper tools work correctly | ✅ | 359ms |
| mark-epic-complete.js — refuses invalid input FAIL: errors when the epic has no state.json | Helper tools work correctly | ✅ | 377ms |
| mark-epic-complete.js — refuses invalid input FAIL: rejects a path-traversal slug rather than resolving outside generated-docs/epics | Helper tools work correctly | ✅ | 487ms |
| mark-epic-complete.js — refuses invalid input FAIL: missing --slug prints usage and exits non-zero | Helper tools work correctly | ✅ | 451ms |
| migrate-legacy-state.js — detection detects legacy currentPhase (DESIGN → state-rewrite) | Helper tools work correctly | ✅ | 387ms |
| migrate-legacy-state.js — detection detects legacy story phases (REALIGN/QA) | Helper tools work correctly | ✅ | 283ms |
| migrate-legacy-state.js — detection detects FRS without brief (spec-copy) | Helper tools work correctly | ✅ | 182ms |
| migrate-legacy-state.js — detection reports no_legacy when nothing exists | Helper tools work correctly | ✅ | 219ms |
| migrate-legacy-state.js — detection reports no_migration_needed for an already-migrated state | Helper tools work correctly | ✅ | 199ms |
| migrate-legacy-state.js — fixture-driven migration output run-12: REALIGN currentPhase → BUILD, in-progress story → PENDING | Helper tools work correctly | ✅ | 189ms |
| migrate-legacy-state.js — fixture-driven migration output run-12: completed stories get synthesized e2e/manual fields with warnings | Helper tools work correctly | ✅ | 212ms |
| migrate-legacy-state.js — fixture-driven migration output run-23: QA currentPhase → BUILD, completed stories preserve fields | Helper tools work correctly | ✅ | 265ms |
| migrate-legacy-state.js — fixture-driven migration output run-23: design and designArtifacts blocks are dropped with warnings | Helper tools work correctly | ✅ | 175ms |
| migrate-legacy-state.js — fixture-driven migration output run-23: intake.frsExists renamed to briefExists | Helper tools work correctly | ✅ | 179ms |
| migrate-legacy-state.js — fixture-driven migration output run-23: epic.phase STORIES → PENDING | Helper tools work correctly | ✅ | 179ms |
| migrate-legacy-state.js — fixture-driven migration output run-24-intake: SCOPE currentPhase → PLAN | Helper tools work correctly | ✅ | 183ms |
| migrate-legacy-state.js — fixture-driven migration output run-24-playwright: round-trip apply → restore | Helper tools work correctly | ✅ | 436ms |
| migrate-legacy-state.js — spec copy --apply copies FRS to brief with a migration header | Helper tools work correctly | ✅ | 201ms |
| migrate-legacy-state.js — spec copy --apply skips FRS copy if brief already exists, with a warning | Helper tools work correctly | ✅ | 237ms |
| migrate-legacy-state.js — spec copy --restore removes only a migration-header brief, leaving a user-edited brief | Helper tools work correctly | ✅ | 390ms |
| migrate-legacy-state.js — edge cases --restore with no backup exits 1 | Helper tools work correctly | ✅ | 215ms |
| migrate-legacy-state.js — edge cases warns on an existing backup during a second apply | Helper tools work correctly | ✅ | 360ms |
| migrate-legacy-state.js — edge cases a second apply over an existing backup reports status "skipped", not "applied" | Helper tools work correctly | ✅ | 402ms |
| migrate-legacy-state.js — edge cases integration tests are counted once, not double-counted | Helper tools work correctly | ✅ | 216ms |
| migrate-legacy-state.js — edge cases a present-but-falsy completion field (e2eStatus: "") is preserved, not synthesized over | Helper tools work correctly | ✅ | 204ms |
| migrate-legacy-state.js — edge cases AC count is synthesized from the story file when available | Helper tools work correctly | ✅ | 200ms |
| open-page.js resolves an opener on every OS (post-v1.2.0) PASS: macOS and Linux get a real opener, and Windows still works | Helper tools work correctly | ✅ | 12ms |
| project-root.js — default anchor getProjectRoot() returns the target repo root that contains .claude | Helper tools work correctly | ✅ | 5ms |
| project-root.js — walk-up resolution walks up to the nearest ancestor containing .claude | Helper tools work correctly | ✅ | 10ms |
| project-root.js — walk-up resolution recognises .git as a fallback marker | Helper tools work correctly | ✅ | 8ms |
| project-root.js — walk-up resolution recognises .git when it is a file (git worktree layout) | Helper tools work correctly | ✅ | 6ms |
| project-root.js — walk-up resolution stops at the nearest marker, not a farther one (nested-repo safety) | Helper tools work correctly | ✅ | 10ms |
| project-root.js — walk-up resolution returns the start dir itself when it holds the marker | Helper tools work correctly | ✅ | 4ms |
| quality-gates.js — reports truthfully (pass-when-green / fail-when-red) PASS: a green gate reports pass and exits 0 (no "conditional pass") | Helper tools work correctly | ✅ | 3.8s |
| quality-gates.js — reports truthfully (pass-when-green / fail-when-red) FAIL: a red gate reports fail and exits 1 — a real failure is never dressed up as a pass | Helper tools work correctly | ✅ | 3.5s |
| quality-gates.js — reports truthfully (pass-when-green / fail-when-red) FAIL-guard: the runner discriminates — the same runner passes green and fails red | Helper tools work correctly | ✅ | 7.9s |
| build report degrades on a partial/foreign data file (v1.2.0) PASS: a partial effort/cost data file still produces the whole page (no lost report) | Helper tools work correctly | ✅ | 2.2s |
| build report degrades on a partial/foreign data file (v1.2.0) PASS: a corrupt (non-JSON) data file is ignored, and the page still generates | Helper tools work correctly | ✅ | 3.5s |
| build report points to /start before a project exists (post-v1.2.0) PASS: a no-project tree returns /start guidance, not a report | Helper tools work correctly | ✅ | 1.8s |
| build report points to /start before a project exists (post-v1.2.0) PASS (teeth): a started project returns a real report, not the /start pointer | Helper tools work correctly | ✅ | 2.7s |
| both build reports land under generated-docs/reports/ (post-v1.2.0) PASS: maintainer and stakeholders reports both write under generated-docs/reports/, not the old root | Helper tools work correctly | ✅ | 4.6s |
| resolve-state-path.js — epic branch PASS: epic/<slug> resolves to the per-epic state.json path | Helper tools work correctly | ✅ | 525ms |
| resolve-state-path.js — epic branch PASS: reports exists:true once the state.json is present | Helper tools work correctly | ✅ | 419ms |
| resolve-state-path.js — non-epic and invalid PASS: on main it resolves to kind:none with no path | Helper tools work correctly | ✅ | 436ms |
| resolve-state-path.js — non-epic and invalid FAIL: an invalid (non-kebab) epic slug is an error (exit 1) | Helper tools work correctly | ✅ | 462ms |
| resolve-state-path.js — non-epic and invalid FAIL: legacy workflow-state.json is NOT treated as a valid state source | Helper tools work correctly | ✅ | 398ms |
| run-smoke-test.js — credential safety PASS: reports credentials_missing (without printing the value) when an env var is unset | Helper tools work correctly | ✅ | 403ms |
| run-smoke-test.js — credential safety PASS: the .sh artifact carries an env-var REFERENCE, never the credential value | Helper tools work correctly | ✅ | 350ms |
| run-smoke-test.js — credential safety PASS: a credential echoed back in the response body is redacted | Helper tools work correctly | ✅ | 330ms |
| run-smoke-test.js — error shapes FAIL: a refused connection is categorised (result failure / connection_refused), not a crash | Helper tools work correctly | ✅ | 356ms |
| run-smoke-test.js — error shapes FAIL: a missing --config exits non-zero with a status:error payload | Helper tools work correctly | ✅ | 326ms |
| scan-doc.js — plain markdown file PASS: reports correct line count and text type | Helper tools work correctly | ✅ | 358ms |
| scan-doc.js — plain markdown file FAIL: does not claim a text file is binary | Helper tools work correctly | ✅ | 359ms |
| scan-doc.js — binary file detection PASS: flags a buffer with null bytes as binary | Helper tools work correctly | ✅ | 299ms |
| scan-doc.js — binary file detection FAIL: does not attempt to count lines in a binary buffer as if it were text | Helper tools work correctly | ✅ | 325ms |
| scan-doc.js — keyword counting PASS: counts requested keywords case-insensitively | Helper tools work correctly | ✅ | 312ms |
| scan-doc.js — keyword counting FAIL: keywords not present yield zero, not undefined/crash | Helper tools work correctly | ✅ | 312ms |
| stakeholders report — Decisions you signed off (post-v1.2.0) PASS: signed-off decisions render, dated, from the record — and nothing is invented | Helper tools work correctly | ✅ | 3.5s |
| stakeholders report — Decisions you signed off (post-v1.2.0) PASS (teeth): with no decisions record, the sign-off section is absent | Helper tools work correctly | ✅ | 3.4s |
| summarize-playwright.js PASS: a clean run reports result "pass" (exit 0) | Helper tools work correctly | ✅ | 376ms |
| summarize-playwright.js FAIL: a failing spec is reported and mapped to its story number (exit 1) | Helper tools work correctly | ✅ | 361ms |
| summarize-playwright.js FAIL: a run-level error with zero failing specs is still a fail (broken-run guard) | Helper tools work correctly | ✅ | 299ms |
| summarize-playwright.js FAIL: an unparseable / wrong-shape report exits 2 (treat as a run failure) | Helper tools work correctly | ✅ | 355ms |
| validate-generated-doc-names.js PASS: a correctly-named tree reports "ok" with zero drift (exit 0) | Helper tools work correctly | ✅ | 392ms |
| validate-generated-doc-names.js FAIL: a drift-named epic file is reported (status "drift", exit 1) | Helper tools work correctly | ✅ | 448ms |
| validate-generated-doc-names.js FAIL: a missing conventions schema exits 2 (can't audit without the source of truth) | Helper tools work correctly | ✅ | 312ms |
| recorded-run harness PASS: the loader returns a well-formed status object | Tier 2 recorded run | ✅ | 4ms |
| recorded-run harness PASS: capture instructions exist for whoever records the run | Tier 2 recorded run | ✅ | 2ms |
| recorded run — artifact invariants PASS: every epic state.json validates against the epic-state schema | Tier 2 recorded run | ✅ | 10ms |
| recorded run — artifact invariants PASS: every story declares a role and carries acceptance criteria | Tier 2 recorded run | ✅ | 21ms |
| recorded run — artifact invariants PASS: every built epic records a decision trail (journal.md, or the design digest for a design-driven run) | Tier 2 recorded run | ✅ | 19ms |
| recorded run — artifact invariants PASS: absence canaries — no retired telemetry ledger or project-brief | Tier 2 recorded run | ✅ | 1ms |
| recorded run — git topology PASS: at least one epic/<slug> branch exists in the recording | Tier 2 recorded run | ✅ | 116ms |
| recorded run — git topology PASS: an epic reached main via a merge (not a direct push) | Tier 2 recorded run | ✅ | 255ms |
| recorded run — git topology PASS: an epic branch has at least as many commits as it has stories | Tier 2 recorded run | ✅ | 210ms |
| recorded run — /plan parked-epic invariants (artifacts) PASS: every parked epic carries an approved story list (planned, not just drafted) | Tier 2 recorded run | ✅ | 6ms |
| recorded run — /plan parked-epic invariants (artifacts) PASS: a parked epic that depends on an unbuilt epic records that dependency (blocked-ahead) | Tier 2 recorded run | ✅ | 19ms |
| recorded run — /plan parked-epic invariants (git topology) PASS: a parked epic has NOT started building — no epic/<slug> branch exists for it | Tier 2 recorded run | ✅ | 116ms |
| recorded run — /plan parked-epic invariants (git topology) PASS: no leftover plan/<slug> planning worktree/branch remains | Tier 2 recorded run | ✅ | 106ms |
| recorded run — /plan parked-epic invariants (git topology) PASS: a parked epic is parked on main (its state.json is committed on the default branch) | Tier 2 recorded run | ✅ | 105ms |

---

<sub>Generated 2026-08-14 09:22:56 · QA suite version 0.1.0 · code version n/a on branch n/a · Node v24.11.0, Vitest 2.1.9. Time taken is the real wall-clock time; checks run side by side, so it is shorter than adding up each one.</sub>
