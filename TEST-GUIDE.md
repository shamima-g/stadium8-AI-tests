# Test Guide — Running the Workflow by Hand

This is the **human walkthrough**. A person runs the real Stadium 8 workflow with
a real AI and checks that it behaves. It's the final word on whether the template
works — the automated tests (`tier-1-unit/`, `tier-2-log-replay/`) exist to catch
most problems without a person, but this guide catches what they can't.

Every test below gives you: what to do to make it **pass**, what a **failure**
looks like, the commands to **check** the result, and how to **roll back** before
the next test.

**Symbols:** ✅ expected to pass · ❌ a deliberate or watched-for failure ·
⚠️ needs the dev server running.

> **The workflow has four phases:** INTAKE → PLAN → BUILD → COMPLETE.
> INTAKE produces one document to approve (`project-brief.md`). PLAN proposes
> epics and stories to approve. BUILD builds each story automatically. COMPLETE
> wraps up with reports. There is no DESIGN, SCOPE, STORIES, REALIGN, TEST-DESIGN,
> or QA phase — if you see those names anywhere, the doc is out of date.

For the exact answers to type at each prompt, see [TEST-INPUTS.md](TEST-INPUTS.md).

---

## Two kinds of test in this guide

- **Artifact tests** — "after this phase, does the right file exist with the right
  content?" These could be automated today (and many are, in Tier 1).
- **Behaviour tests** — "did the AI do things in the right order?" (e.g. it
  delegated to an agent instead of editing files itself; it showed something to
  review *before* asking you to approve it). These need the AI to have run.

Where a behaviour can be checked from the recorded run, the Tier 2 telemetry
tests cover it automatically. Until you've recorded a run, use the manual steps
here.

---

## Rollback reference

Each test's **Rollback** section names one of these by ID.

### RB-0 — Full clean reset
```bash
git checkout -- .
git clean -fd generated-docs/ documentation/
```

### RB-1 — Reset workflow state only
```bash
rm -f generated-docs/context/workflow-state.json
```

### RB-2 — Revert a single file
```bash
git checkout -- <file-path>
# Example: git checkout -- web/src/app/tasks/page.tsx
```

### RB-3 — Remove a test documentation file
```bash
rm -f documentation/task-api.yaml
```

### RB-4 — Reset telemetry ledger
```bash
rm -f generated-docs/context/telemetry.ndjson generated-docs/context/telemetry-meta.json
```

### RB-5 — Restore write permissions on generated-docs (Windows)
```bash
icacls "generated-docs" /grant %USERNAME%:"(OI)(CI)F" /t
```

### RB-6 — Reinstall dependencies
```bash
npm --prefix web install
```

### RB-7 — Revert the most recently injected error
```bash
git diff --name-only
git checkout -- <that-file>
```

---

## Starting states (checkpoints)

Named points in the workflow, so a test doesn't have to start from scratch. Each
test's **Setup** says which one it needs.

| ID | Description | Files that exist by now |
|---|---|---|
| **CP-0** | Clean repo, nothing started | `web/` exists; `node_modules/` may be absent |
| **CP-1** | INTAKE done — brief approved | `generated-docs/context/intake-manifest.json`, `generated-docs/specs/project-brief.md` |
| **CP-2** | PLAN done — epics and stories approved | `generated-docs/stories/_feature-overview.md`, per-epic overviews and story files |
| **CP-3** | BUILD in progress — at least one story committed | story commits in `git log`; files under `web/src/` |
| **CP-4** | Feature COMPLETE | telemetry reports under `generated-docs/reports/` |

**Fastest path to CP-1:** run `/start`, give the main-scenario INTAKE answers
from `TEST-INPUTS.md`, approve the project brief at Gate 1.

**CP-1 → CP-2:** the workflow chains into PLAN automatically; approve the epic
list, then approve the stories for each epic.

**CP-2 → CP-3:** let BUILD run; the first story commits on its own.

**CP-3 → CP-4:** let BUILD finish every epic; COMPLETE runs automatically.

---

## Table of contents

**Setup & infrastructure**
1. [Setup runs and flows straight into INTAKE](#1-setup-runs-and-flows-straight-into-intake)
2. [Telemetry is recorded during a run](#2-telemetry-is-recorded-during-a-run)
3. [The dashboard updates as the workflow progresses](#3-the-dashboard-updates-as-the-workflow-progresses)

**INTAKE**
4. [Onboarding offers three starting paths](#4-onboarding-offers-three-starting-paths)
5. [INTAKE asks the checklist questions](#5-intake-asks-the-checklist-questions)
6. [INTAKE presents authentication options and warnings](#6-intake-presents-authentication-options-and-warnings)
7. [Approvals show the content before the question](#7-approvals-show-the-content-before-the-question)
8. [INTAKE writes the intake manifest](#8-intake-writes-the-intake-manifest)
9. [Gate 1 — the project brief is produced and approved](#9-gate-1--the-project-brief-is-produced-and-approved)

**PLAN**
10. [PLAN proposes epics for approval (Gate 2a)](#10-plan-proposes-epics-for-approval-gate-2a)
11. [PLAN proposes stories per epic (Gate 2b)](#11-plan-proposes-stories-per-epic-gate-2b)
12. [Every story declares a role](#12-every-story-declares-a-role)

**BUILD**
13. [BUILD writes failing tests first](#13-build-writes-failing-tests-first)
14. [Every routable story gets a Playwright spec](#14-every-routable-story-gets-a-playwright-spec)
15. [BUILD writes code that makes the tests pass](#15-build-writes-code-that-makes-the-tests-pass)
16. [The per-story fix cycle stops after three tries](#16-the-per-story-fix-cycle-stops-after-three-tries)
17. [BUILD runs the automated quality gates](#17-build-runs-the-automated-quality-gates)
18. [Each story is committed and pushed](#18-each-story-is-committed-and-pushed)
19. [BUILD halts on decisions it isn't allowed to make](#19-build-halts-on-decisions-it-isnt-allowed-to-make)
20. [Each epic ends with a summary and a manual check (Gate 1)](#20-each-epic-ends-with-a-summary-and-a-manual-check-gate-1)
21. [The API spec is honoured exactly](#21-the-api-spec-is-honoured-exactly)
22. [UI primitives come from Shadcn](#22-ui-primitives-come-from-shadcn)
23. [No error suppressions in generated code](#23-no-error-suppressions-in-generated-code)
24. [User-facing checklists stay in plain language](#24-user-facing-checklists-stay-in-plain-language)
25. [The project brief overrides template code](#25-the-project-brief-overrides-template-code)

**COMPLETE**
26. [COMPLETE writes telemetry reports and a completion message](#26-complete-writes-telemetry-reports-and-a-completion-message)

**Commands & system**
27. [The status command](#27-the-status-command)
28. [The quality-check command on its own](#28-the-quality-check-command-on-its-own)
29. [Continue recovers a lost state](#29-continue-recovers-a-lost-state)
30. [The orchestrator delegates instead of doing the work itself](#30-the-orchestrator-delegates-instead-of-doing-the-work-itself)
31. [Each quality gate fails when it should](#31-each-quality-gate-fails-when-it-should)
32. [The permission system blocks dangerous commands](#32-the-permission-system-blocks-dangerous-commands)

---

## 1. Setup runs and flows straight into INTAKE

**Phase:** pre-workflow · **Depends on:** CP-0

### Setup
```bash
# Remove dependencies so setup has to run
rm -rf web/node_modules/
```

### a. What we're checking
When you type `/start` and dependencies are missing, the workflow should install
them and then **keep going into the welcome and the first question in the same
response** — no pause, no "Setup complete!" that leaves you waiting.

**To pass:**
1. Make sure `web/node_modules/` is gone (run Setup above).
2. Type `/start`.
3. Watch the response: after the install output, Claude should go straight into
   the welcome and the first onboarding question, all in one go.

**What failure looks like:**
- ❌ The response ends with "Setup complete" (or similar) and stops, leaving you
  waiting before the first question appears.

### b. Expected result
✅ **Pass:** install output, then immediately the welcome and the routing
question — one continuous response.
❌ **Fail:** a "done installing" message that ends the turn.

### c. How to check
```bash
# Dependencies were reinstalled
ls web/node_modules/ | head -5

# Workflow state was created (check after the first question appears)
cat generated-docs/context/workflow-state.json 2>/dev/null || echo "State not yet created"
```

### Rollback
RB-6 (reinstall dependencies if they're still missing).

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 2. Telemetry is recorded during a run

**Phase:** any · **Depends on:** CP-0

### a. What we're checking
The template records what happens to a telemetry ledger as the workflow runs. It
does **not** write `.claude/logs/*.md` session logs, and there is **no**
`[Logs saved]` marker at the end of responses.

**To pass:**
1. Run `/start` and answer at least the first few INTAKE questions.
2. Confirm the ledger file exists and is growing.

**What failure looks like:**
- ❌ No `telemetry.ndjson` appears after several turns.
- ❌ Responses end with a `[Logs saved]` marker, or `.claude/logs/` fills with
  `*.md` files (both are signs of the old, removed logging system).

### b. Expected result
✅ **Pass:** `generated-docs/context/telemetry.ndjson` exists and gains lines as
the workflow runs; no `[Logs saved]` marker anywhere.
❌ **Fail:** ledger missing, or old-style logs / markers present.

### c. How to check
```bash
# The ledger exists and has events
wc -l generated-docs/context/telemetry.ndjson

# Each line is a JSON event (phase_enter, agent_start, etc.)
tail -3 generated-docs/context/telemetry.ndjson

# The old logging system is NOT present
ls .claude/logs/*.md 2>/dev/null && echo "UNEXPECTED — old logs present" || echo "OK — no old logs"
```

### Rollback
RB-4 (reset the telemetry ledger).

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 3. The dashboard updates as the workflow progresses

**Phase:** all · **Depends on:** varies (noted per sub-test)

The dashboard is regenerated at many points (after INTAKE, after each PLAN
approval, after each agent in BUILD, after each commit). The key behaviours: it
auto-refreshes, it reflects the current phase, and if it ever fails to generate
it must **not** stop the workflow.

**Common setup for 3a–3e:**
1. Type `/dashboard`.
2. Confirm `generated-docs/dashboard.html` is created and opens in the browser.
3. Confirm it auto-refreshes every 10 seconds:
   ```bash
   grep -c 'http-equiv="refresh"' generated-docs/dashboard.html   # expect 1
   ```
4. Leave the tab open for the sub-tests.

### 3a. Dashboard is created and auto-refreshes
- **To pass:** `/dashboard` creates the file, opens it, and the refresh tag is
  present (the `grep -c` above returns `1`).
- **Fail:** file not created, doesn't open, or no refresh tag.

### 3b. Dashboard reflects INTAKE completion — **Depends on:** CP-0
- **To pass:** run INTAKE to Gate 1 approval; within ~10s the dashboard shows
  INTAKE complete and PLAN as the next phase.
  ```bash
  grep -i "intake" generated-docs/dashboard.html | head -5
  ```
- **Fail:** dashboard still blank after INTAKE.

### 3c. Dashboard reflects PLAN (epics and stories) — **Depends on:** CP-1
- **To pass:** approve the epic list, then the stories. The dashboard shows the
  epics, then the individual stories under each epic, with pending counts.
  ```bash
  test -f generated-docs/stories/_feature-overview.md && echo OK
  grep -i "epic" generated-docs/dashboard.html | head -5
  ```
- **Fail:** epics or stories never appear in the dashboard.

### 3d. Dashboard reflects BUILD progress — **Depends on:** CP-2
- **To pass:** as BUILD runs, the dashboard moves each story through to complete
  and shows the commit. Updates appear *after* the work is done (e.g. after the
  story commits), not before.
- **Fail:** dashboard shows a story complete before its code/commit exists.

### 3e. A dashboard failure does not block the workflow
- **To pass:** make the dashboard step fail (e.g. temporarily remove write
  permission on `generated-docs/` — RB-5 restores it) and confirm the workflow
  keeps going. Dashboard generation is fire-and-forget.
  ```bash
  # Windows example to remove then restore permission:
  icacls "generated-docs" /deny %USERNAME%:W
  # ...run a step that would refresh the dashboard, confirm the workflow continues...
  icacls "generated-docs" /remove:d %USERNAME%   # restore (or RB-5)
  ```
- **Fail:** the workflow stops or errors out because the dashboard couldn't be
  written.

### Rollback
RB-0 for a full reset, or RB-5 to restore permissions after 3e.

### Result
```
3a [ ] Pass [ ] Fail   3b [ ] Pass [ ] Fail   3c [ ] Pass [ ] Fail
3d [ ] Pass [ ] Fail   3e [ ] Pass [ ] Fail
Date: ___________
Notes:
```

---

## 4. Onboarding offers three starting paths

**Phase:** INTAKE · **Depends on:** CP-0

### a. What we're checking
The first question after `/start` offers three ways in: import a prototype repo,
share existing docs, or build requirements from scratch.

**To pass:**
1. Type `/start`.
2. Confirm the routing question offers all three options.
3. Pick **Let's build requirements together** and confirm it then asks for the
   pitch (a free-text box, not buttons).

**What failure looks like:**
- ❌ Fewer than three options, or the wrong options.
- ❌ The pitch is forced into a multiple-choice question instead of free text.

### b. Expected result
✅ **Pass:** three routing options; the "from scratch" path leads to a free-text
pitch prompt.
❌ **Fail:** missing options, or the pitch is buttoned.

### Rollback
RB-1, then RB-0 if needed.

### c. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 5. INTAKE asks the checklist questions

**Phase:** INTAKE · **Depends on:** CP-0

### a. What we're checking
INTAKE asks a short set of checklist questions — **roles, authentication, backend
readiness, and compliance** — using button choices, with the right options each
time. (Styling is not a separate question; it comes from the brief.)

**To pass:**
1. Run `/start` and give the pitch from `TEST-INPUTS.md`.
2. Answer each checklist question using the main-scenario answers:
   - Roles → "Other" + the two roles.
   - Authentication → "Frontend-only (next-auth)".
   - Backend ready? → "No, still in development".
   - Compliance → "None apply", then confirm.
3. Confirm each question appeared as buttons with sensible options.

**What failure looks like:**
- ❌ A question is skipped, or its options are wrong (e.g. compliance never asked).
- ❌ The backend/spec answers don't translate into the right data source (this
  scenario should land on `api-in-development`).

### b. Expected result
✅ **Pass:** all four checklist questions appear with correct options; the
manifest records `dataSource: api-in-development`.
❌ **Fail:** a question missing or mis-optioned, or the wrong data source recorded.

### c. How to check
```bash
# After Gate 1, the manifest captures the answers
grep -i "dataSource" generated-docs/context/intake-manifest.json
grep -i "authMethod" generated-docs/context/intake-manifest.json
```

### Rollback
RB-1, then RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 6. INTAKE presents authentication options and warnings

**Phase:** INTAKE · **Depends on:** CP-0

### a. What we're checking
The authentication question always presents the choices explicitly — **BFF**,
**Frontend-only (next-auth)**, and **Custom** — and shows the right trade-off
note for the one you pick. Auth is never silently inferred.

**To pass (frontend-only path — main scenario):**
1. At the auth question, pick **Frontend-only (next-auth)**.
2. Confirm Claude shows the note that API calls won't carry session context (it
   protects frontend routes only), then continues.

**To pass (BFF path — Variant A):**
1. Pick **Backend For Frontend (BFF)**.
2. Confirm Claude asks for the login, userinfo, and logout URLs (free text) and
   shows the note that CI can't reach a real BFF, so the performance gate runs
   against mocks.

**What failure looks like:**
- ❌ Auth is chosen for you without the three options being shown.
- ❌ No trade-off note for the selected method.
- ❌ BFF selected but the three URLs are never requested.

### b. Expected result
✅ **Pass:** three options shown; correct warning; BFF collects the three URLs.
❌ **Fail:** options or warning missing; BFF URLs not collected.

### Rollback
RB-1, then RB-0.

### c. Result
```
frontend-only [ ] Pass [ ] Fail    BFF (Variant A) [ ] Pass [ ] Fail
Date: ___________
Notes:
```

---

## 7. Approvals show the content before the question

**Phase:** INTAKE (and every gate) · **Depends on:** CP-0

### a. What we're checking
Whenever the workflow asks you to approve something, it must show you the thing
**first**, in the same response, before the approval buttons. No "naked" approval
questions with nothing to review.

**To pass:**
1. Run INTAKE to Gate 1.
2. Confirm the brief summary appears as text **above** the "Approve all / I have
   small changes / …" question.

**What failure looks like:**
- ❌ An approval question appears with no preceding summary or content to review.

### b. Expected result
✅ **Pass:** content/summary, then the approval question, in one response.
❌ **Fail:** the question appears alone.

### Rollback
RB-1.

### c. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 8. INTAKE writes the intake manifest

**Phase:** INTAKE · **Depends on:** CP-0

### a. What we're checking
INTAKE records the captured configuration in
`generated-docs/context/intake-manifest.json` — roles, auth, data source,
compliance, and backend connectivity.

**To pass:**
1. Run INTAKE to Gate 1 approval.
2. Confirm the manifest exists and is valid JSON with the expected fields.

**What failure looks like:**
- ❌ Manifest missing, malformed, or missing the captured answers.

### b. Expected result
✅ **Pass:** a valid manifest reflecting the main-scenario answers.
❌ **Fail:** missing/invalid/incomplete manifest.

### c. How to check
```bash
test -f generated-docs/context/intake-manifest.json && echo OK
node -e "JSON.parse(require('fs').readFileSync('generated-docs/context/intake-manifest.json','utf8')); console.log('valid JSON')"
```

### Rollback
RB-1, then RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 9. Gate 1 — the project brief is produced and approved

**Phase:** INTAKE · **Depends on:** CP-0

### a. What we're checking
INTAKE produces **one** document for you to approve:
`generated-docs/specs/project-brief.md`. (There is no FRS / feature-requirements
file — that's the old model.) Approving it (Gate 1) is what lets the workflow
move into PLAN.

**To pass:**
1. Run INTAKE; at Gate 1, open `project-brief.md` and confirm it captured the
   goal, the two roles, frontend-only auth, the in-development backend, no
   compliance, and a handful of requirements and business rules.
2. Pick **Approve all**.
3. Confirm the workflow then chains into PLAN.

**What failure looks like:**
- ❌ No `project-brief.md` (or a `feature-requirements.md` appears instead).
- ❌ The brief is missing the captured decisions.
- ❌ The workflow advances to PLAN without you approving.

### b. Expected result
✅ **Pass:** `project-brief.md` exists, reflects the answers, and PLAN starts only
after you approve.
❌ **Fail:** wrong/missing artifact, or PLAN starts without approval.

### c. How to check
```bash
test -f generated-docs/specs/project-brief.md && echo OK
test ! -f generated-docs/specs/feature-requirements.md && echo "OK — no old FRS file"
node .claude/scripts/transition-phase.js --show
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 10. PLAN proposes epics for approval (Gate 2a)

**Phase:** PLAN · **Depends on:** CP-1

### a. What we're checking
PLAN proposes a list of epics and waits for your approval before breaking any of
them into stories. The epics should appear as text first, then the approval
question.

**To pass:**
1. From CP-1, let the workflow run into PLAN (or type `/continue`).
2. Confirm the epic list appears (for this scenario, roughly "Task Browsing" and
   "Task Actions") with each epic's requirement coverage.
3. Pick **Approve all**.

**What failure looks like:**
- ❌ The workflow jumps to stories or BUILD without showing/approving epics.
- ❌ The epic list is empty or doesn't match the brief.

> **Single-epic shortcut:** if only one epic is proposed, this gate and the story
> gate (§11) are combined into a single approval. That's expected behaviour, not
> a failure.

### b. Expected result
✅ **Pass:** epic list shown, then approved before stories begin.
❌ **Fail:** epics skipped, empty, or off-brief.

### c. How to check
```bash
test -f generated-docs/stories/_feature-overview.md && echo OK
grep -i "epic" generated-docs/stories/_feature-overview.md | head
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 11. PLAN proposes stories per epic (Gate 2b)

**Phase:** PLAN · **Depends on:** CP-1 (after epics approved)

### a. What we're checking
For each epic, PLAN lists its stories and the manual tests you'll run when the
epic is done, then waits for approval. Stories for a later epic shouldn't appear
until you reach that epic.

**To pass:**
1. After approving the epic list, confirm Epic 1's stories appear (roughly "View
   the task list" and "Empty state") with a manual-test checklist.
2. Pick **Approve epic**.
3. Confirm story files exist for Epic 1 and that Epic 2's stories aren't created
   yet.

**What failure looks like:**
- ❌ Only an epic-level entry, no individual stories.
- ❌ Epic 2's stories created before you reach Epic 2.

### b. Expected result
✅ **Pass:** stories shown and approved one epic at a time.
❌ **Fail:** stories missing, or a later epic's stories created early.

### c. How to check
```bash
ls generated-docs/stories/epic-1-*/ 2>/dev/null
ls generated-docs/stories/epic-2-*/ 2>/dev/null && echo "Epic 2 stories exist — only OK if you've reached Epic 2"
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 12. Every story declares a role

**Phase:** PLAN · **Depends on:** CP-2

### a. What we're checking
Each story file carries a non-empty `**Role:**` line saying who the story is for.
This drives role-aware behaviour later.

**To pass:**
1. From CP-2, open any `story-*.md` file.
2. Confirm it has a `**Role:**` line with a real value (e.g. "Admin" or "Member"),
   not blank.

**What failure looks like:**
- ❌ A story file with a missing or empty `**Role:**` field.

### b. Expected result
✅ **Pass:** every story has a non-empty role.
❌ **Fail:** any story missing its role.

### c. How to check
```bash
grep -rL "\*\*Role:\*\*" generated-docs/stories/**/story-*.md 2>/dev/null && echo "Files above are MISSING a role" || echo "All stories have a role"
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 13. BUILD writes failing tests first

**Phase:** BUILD · **Depends on:** CP-2

### a. What we're checking
For each story, BUILD writes the tests **before** the code. Those tests should
fail at first, because the feature doesn't exist yet — that's the point.

**To pass:**
1. From CP-2, let BUILD start the first story.
2. Confirm the test files appear (Vitest under `web/src/__tests__/`, Playwright
   under `web/e2e/`) before any implementation.
3. If you run them at this moment, they fail.

**What failure looks like:**
- ❌ Implementation code appears before the tests.
- ❌ The first test run passes with no implementation (the tests aren't really
  asserting the behaviour).

### b. Expected result
✅ **Pass:** tests exist first and fail before the code is written.
❌ **Fail:** code first, or tests that pass with nothing implemented.

### c. How to check
```bash
ls web/src/__tests__/ 2>/dev/null
ls web/e2e/ 2>/dev/null
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 14. Every routable story gets a Playwright spec

**Phase:** BUILD · **Depends on:** CP-2

### a. What we're checking
Per Critical Rule §9, every story that maps to a page has a Playwright spec at
`web/e2e/epic-<N>-story-<M>-<slug>.spec.ts` with at least one real `test()`.
Stories that aren't routable still get a spec file, but the suite is wrapped in
`test.fixme()` with a one-line reason — and `test.fixme()` is **not allowed** on a
routable story.

**To pass:**
1. After BUILD generates tests for a routable story, confirm its spec file exists
   and contains a live `test(` block (not `test.fixme(`).
2. For a non-routable story, confirm the spec exists and uses `test.fixme()` with
   a reason comment.

**What failure looks like:**
- ❌ A routable story with no spec, or with the whole suite under `test.fixme()`.

### b. Expected result
✅ **Pass:** routable stories have a live spec; non-routable ones have a
`test.fixme()` spec with a reason.
❌ **Fail:** missing spec, or `test.fixme()` on a routable story.

### c. How to check
```bash
ls web/e2e/epic-*-story-*.spec.ts
# A routable spec should contain a live test( and no whole-suite test.fixme(
grep -L "test.fixme(" web/e2e/epic-1-story-1-*.spec.ts
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 15. BUILD writes code that makes the tests pass

**Phase:** BUILD · **Depends on:** CP-2 (tests written)

### a. What we're checking
After the failing tests, BUILD writes the implementation, and the previously
failing tests now pass.

**To pass:**
1. Let BUILD write the code for the first story.
2. Confirm the implementation files appear under `web/src/app/` or
   `web/src/components/`, that all API calls go through the API client
   (`@/lib/api/client`) — never raw `fetch()` — and that the tests now pass.

**What failure looks like:**
- ❌ Tests still fail after the code is written (and BUILD moves on anyway).
- ❌ A component calls `fetch()` directly instead of the API client.

### b. Expected result
✅ **Pass:** implementation exists, tests pass, API calls go through the client.
❌ **Fail:** tests still failing, or raw `fetch()` in a component.

### c. How to check
```bash
ls web/src/app/ web/src/components/ 2>/dev/null
grep -rn "fetch(" web/src/components web/src/app 2>/dev/null && echo "Check these — raw fetch not allowed" || echo "No raw fetch"
npm --prefix web test
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 16. The per-story fix cycle stops after three tries

**Phase:** BUILD · **Depends on:** CP-2

### a. What we're checking
Per story, BUILD runs: write tests → write code → (browser tests ∥ code review).
If either the browser tests or the review fail, BUILD asks the developer step to
fix it and tries again — up to **three** attempts. After the third, it stops and
asks you what to do rather than looping forever.

**To pass:**
1. Watch a story that needs a fix: the developer step is invoked a second time
   with the failures from the first attempt.
2. Confirm that if it can't pass after three attempts, the workflow halts and
   asks you (defer the story / stop / discuss) instead of trying a fourth time.

**What failure looks like:**
- ❌ A failing review or browser test is ignored and the story commits anyway.
- ❌ The fix cycle loops more than three times without asking you.

### b. Expected result
✅ **Pass:** at most three developer attempts per story; a halt-and-ask after the
third.
❌ **Fail:** failures ignored, or unlimited retries.

### Rollback
RB-0.

### c. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 17. BUILD runs the automated quality gates

**Phase:** BUILD · **Depends on:** CP-2

### a. What we're checking
Inside BUILD, the code review step runs the automated quality gates on each
story: **Gate 2 (security), Gate 3 (code quality — types, lint, build), Gate 4
(testing), Gate 5 (performance)**. There is **no Gate 6**. A real failure must
send the story back into the fix cycle, not pass.

**To pass:**
1. Let a clean story go through; confirm Gates 2–5 run and pass, and the story
   then commits.
2. (Optional) Inject a fault (see §31) and confirm the relevant gate fails and the
   story does **not** commit until it's fixed.

**What failure looks like:**
- ❌ A gate failure is reported as a pass.
- ❌ A sixth gate / spec-compliance step appears (that feature was removed).

### b. Expected result
✅ **Pass:** Gates 2–5 run per story; failures block the commit; no Gate 6.
❌ **Fail:** false pass, or an unexpected sixth gate.

### c. How to check
```bash
node .claude/scripts/quality-gates.js --help 2>/dev/null | head
# Gates 2–5 only; Gate 1 is the manual epic-boundary check
```

### Rollback
RB-7 if you injected a fault, then RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 18. Each story is committed and pushed

**Phase:** BUILD · **Depends on:** CP-2

### a. What we're checking
When a story passes its gates, BUILD commits it and pushes. The commit message
follows `feat(epic-<N>-story-<M>): <title>`, and the commit body records the
notable decisions the developer made on its own.

**To pass:**
1. Let a story complete.
2. Confirm a commit appears with the right subject, a body that notes key
   decisions, and that it was pushed.

**What failure looks like:**
- ❌ No commit per story, or a commit with no decision record in the body.
- ❌ Several stories squashed into one commit.

### b. Expected result
✅ **Pass:** one commit per story with a descriptive subject and a decision-note
body; pushed after committing.
❌ **Fail:** missing/lumped commits or empty bodies.

### c. How to check
```bash
git log --oneline -5
git log -1 --format="%B"   # inspect the latest commit body
```

### Rollback
None (commits are the expected output). RB-0 only if resetting the whole test.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 19. BUILD halts on decisions it isn't allowed to make

**Phase:** BUILD · **Depends on:** CP-2

### a. What we're checking
Agents proceed on their own for ordinary choices (file naming, common React
patterns, which Shadcn component, ARIA labels). But for "always-halt" decisions —
a new dependency, an API-contract change, calling an endpoint not in the spec, an
auth change, a cross-cutting architecture change, or a contradiction with the
brief — BUILD stops and asks you, showing the options.

**To pass:**
1. Trigger an always-halt situation. The easiest is the undocumented-endpoint
   case: use **Variant C** (a spec with only `/api/v2/tasks`) but pick a story
   that needs an operation the spec doesn't document.
2. Confirm BUILD halts and asks you (with options like add-to-spec / use an
   alternative / defer) instead of guessing.

**What failure looks like:**
- ❌ BUILD silently invents an endpoint, adds a dependency, or changes the auth
  flow without asking.

### b. Expected result
✅ **Pass:** an always-halt decision stops BUILD and surfaces a question with
options.
❌ **Fail:** the workflow proceeds without asking.

### Rollback
RB-3 (remove the spec file), then RB-0.

### c. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 20. Each epic ends with a summary and a manual check (Gate 1)

**Phase:** BUILD → epic boundary · **Depends on:** CP-3 ⚠️

### a. What we're checking
When an epic's stories are all built, the workflow shows an **Epic Completion
Summary** (commits made, autonomous decisions, anything worth a glance) and then
runs **Gate 1** — the manual check, where you try the epic in the browser and
report back.

**To pass:** ⚠️ needs the dev server (`npm --prefix web run dev`).
1. Finish an epic.
2. Confirm the Epic Completion Summary appears (commit list + decisions).
3. Confirm the manual-test checklist appears and you're asked whether it passes.
4. Walk the browser steps from `TEST-INPUTS.md` for that epic; if all good, pick
   the **pass** option. If you pick **Issues found** and describe a problem, the
   workflow fixes it and asks again.

**What failure looks like:**
- ❌ The epic ends with no summary, or BUILD moves to the next epic without the
  manual check.
- ❌ "Issues found" doesn't lead to a fix and a re-ask.

### b. Expected result
✅ **Pass:** summary shown; manual check offered; "Issues found" triggers a fix
and re-ask; passing advances to the next epic (or COMPLETE).
❌ **Fail:** no summary, no manual check, or issues ignored.

### Rollback
RB-2 if a fix changed a file you want to revert, then RB-0.

### c. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 21. The API spec is honoured exactly

**Phase:** BUILD · **Depends on:** CP-0 (start with Variant C) ⚠️

### a. What we're checking
The generated API calls use the **exact** paths from the API spec — never a
guessed path. With Variant C the spec uses `/api/v2/tasks`, so the code must too.

**To pass:**
1. Add the Variant C spec file (`documentation/task-api.yaml`) before `/start`.
2. Run through to BUILD for a story that lists or deletes tasks.
3. Confirm the generated endpoints use `/api/v2/tasks`, not `/api/tasks` or
   anything invented.

**What failure looks like:**
- ❌ A generated call uses a path that isn't in the spec.

### b. Expected result
✅ **Pass:** every generated path matches a path in the spec.
❌ **Fail:** any guessed/extra path.

### c. How to check
```bash
grep -rn "/api/v2/tasks" web/src/lib/api/ | head
grep -rn "/api/tasks\b" web/src/lib/api/ && echo "FAIL — guessed path" || echo "OK"
```

### Rollback
RB-3, then RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 22. UI primitives come from Shadcn

**Phase:** BUILD · **Depends on:** CP-3

### a. What we're checking
Per Critical Rule §1, buttons, dialogs, inputs, cards, and the like are built by
composing Shadcn primitives imported from `@/components/ui/` — not hand-rolled
from raw HTML and Tailwind.

**To pass:**
1. After a story with UI is built, confirm its components import primitives from
   `@/components/ui/`.

**What failure looks like:**
- ❌ A hand-rolled `<button className="...">` standing in for a Shadcn `Button`.

### b. Expected result
✅ **Pass:** UI primitives imported from `@/components/ui/`.
❌ **Fail:** hand-rolled equivalents of primitives.

### c. How to check
```bash
grep -rn "@/components/ui/" web/src | head
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 23. No error suppressions in generated code

**Phase:** BUILD · **Depends on:** CP-3

### a. What we're checking
Per Critical Rule §4, generated code never uses suppression directives —
`@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, or `eslint-disable`.

**To pass:**
1. After BUILD, scan `web/src/` for any of those directives.

**What failure looks like:**
- ❌ Any suppression directive anywhere in generated code.

### b. Expected result
✅ **Pass:** no suppressions found.
❌ **Fail:** any suppression present.

### c. How to check
```bash
grep -rnE "@ts-ignore|@ts-expect-error|@ts-nocheck|eslint-disable" web/src && echo "FAIL" || echo "OK — none found"
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 24. User-facing checklists stay in plain language

**Phase:** BUILD → epic boundary · **Depends on:** CP-3

### a. What we're checking
The manual-test checklists you read at an epic boundary (stored under
`generated-docs/qa/`) are written for a non-developer — no engineering jargon
like `tsc`, `ESLint`, `Gate 3`, `isLoading`, or `Skeleton`.

**To pass:**
1. Open a generated verification checklist.
2. Confirm it describes what to click and see, not how the code works.

**What failure looks like:**
- ❌ A checklist that mentions build tools, gate numbers, or component/state names.

### b. Expected result
✅ **Pass:** plain, action-oriented language.
❌ **Fail:** engineering jargon present.

### c. How to check
```bash
grep -rniE "tsc|eslint|gate [0-9]|isloading|skeleton" generated-docs/qa/ && echo "Check these for jargon" || echo "OK"
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 25. The project brief overrides template code

**Phase:** BUILD · **Depends on:** CP-2

### a. What we're checking
Per Critical Rule §6, the project brief is the source of truth — not the starter
template this repo was scaffolded from. When they conflict, BUILD **replaces** the
template code rather than wrapping the new behaviour around it. The clearest case
is auth: if the brief specifies BFF, any starter NextAuth wiring should be removed,
not nested inside.

**To pass:**
1. Run with **Variant A** (BFF) from the start.
2. During the auth-related work, confirm BUILD removes the template's NextAuth
   credential provider and replaces it with BFF redirect logic.
3. Confirm no `next-auth` credential provider remains.

**What failure looks like:**
- ❌ BFF logic wrapped around leftover NextAuth wiring instead of replacing it.

### b. Expected result
✅ **Pass:** template auth replaced to match the brief.
❌ **Fail:** template code left in place and wrapped.

### c. How to check
```bash
grep -rn "next-auth" web/src && echo "Check — should be gone for BFF" || echo "OK — no next-auth"
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 26. COMPLETE writes telemetry reports and a completion message

**Phase:** COMPLETE · **Depends on:** CP-3 (last epic finishing)

### a. What we're checking
After the last epic, the workflow marks the feature complete, generates three
telemetry reports (final, timing, tokens) under `generated-docs/reports/`, opens
the final report, and prints a short completion message. There is no
`[Logs saved]` marker.

**To pass:**
1. Finish the last epic.
2. Confirm the three report files exist and a completion message appears (commit
   count, epics, where the reports are).

**What failure looks like:**
- ❌ Reports missing, or a `[Logs saved]` marker appears instead.

### b. Expected result
✅ **Pass:** three reports written, final one opens, completion message shown.
❌ **Fail:** reports missing or old-style marker present.

### c. How to check
```bash
ls generated-docs/reports/telemetry-final.html generated-docs/reports/telemetry-timing.html generated-docs/reports/telemetry-tokens.html
node .claude/scripts/transition-phase.js --show   # should report COMPLETE
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 27. The status command

**Phase:** any · **Depends on:** CP-1 or later

### a. What we're checking
`/status` reports the current phase, epic, story, and recent commits — accurately.

**To pass:**
1. At any point past INTAKE, type `/status`.
2. Confirm it shows the real current phase and progress.

**What failure looks like:**
- ❌ Wrong phase, stale progress, or an error.

### b. Expected result
✅ **Pass:** accurate phase/epic/story and recent commits.
❌ **Fail:** wrong or stale information.

### c. How to check
```bash
node .claude/scripts/transition-phase.js --show
git log --oneline -5
```

### Rollback
None.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 28. The quality-check command on its own

**Phase:** any · **Depends on:** CP-3

### a. What we're checking
`/quality-check` runs the automated gates (2–5) on demand, outside BUILD, and
reports each gate's real pass/fail.

**To pass:**
1. With some code in place, type `/quality-check`.
2. Confirm each gate runs and the result reflects reality.

**What failure looks like:**
- ❌ A gate reported as passing when it's actually failing.

### b. Expected result
✅ **Pass:** gates run and report truthfully.
❌ **Fail:** a false pass/fail.

### c. How to check
```bash
node .claude/scripts/quality-gates.js --auto-fix
echo "Exit code: $?"   # non-zero means a gate failed
```

### Rollback
None (unless `--auto-fix` changed files; then RB-2/RB-0).

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 29. Continue recovers a lost state

**Phase:** any · **Depends on:** CP-2 or later

### a. What we're checking
If the state file is missing, `/continue` reconstructs the phase from the
artifacts on disk (`transition-phase.js --repair`) rather than getting lost.

**To pass:**
1. From CP-2 or later, delete `generated-docs/context/workflow-state.json` (RB-1).
2. Type `/continue`.
3. Confirm it rebuilds the state, reports the detected phase, and (for medium/low
   confidence) asks you to confirm before proceeding.

**What failure looks like:**
- ❌ `/continue` errors out, or guesses a clearly wrong phase and proceeds without
  confirming.

### b. Expected result
✅ **Pass:** state rebuilt from artifacts; correct phase; confirmation when unsure.
❌ **Fail:** crash or confident wrong guess.

### c. How to check
```bash
rm -f generated-docs/context/workflow-state.json
node .claude/scripts/transition-phase.js --repair
node .claude/scripts/transition-phase.js --show
```

### Rollback
RB-0.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 30. The orchestrator delegates instead of doing the work itself

**Phase:** BUILD · **Depends on:** CP-2

### a. What we're checking
The top-level orchestrator should make only a few tool calls before handing work
to the right agent (test-generator, developer, code-reviewer, etc.). It shouldn't
edit files directly when it has an agent for the job — especially when fixing
issues found at the manual check.

**To pass:**
1. Watch a story being built, or an "Issues found" fix.
2. Confirm the orchestrator launches the appropriate agent rather than running
   `Edit`/`Write` on the code itself.

**What failure looks like:**
- ❌ The orchestrator edits source files directly instead of delegating to the
  developer agent.

### b. Expected result
✅ **Pass:** work is delegated to agents; the orchestrator coordinates.
❌ **Fail:** the orchestrator does the implementation itself.

### Rollback
RB-0.

### c. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 31. Each quality gate fails when it should

**Phase:** any · **Depends on:** CP-3

### a. What we're checking
Each automated gate actually catches its kind of problem — a false pass is the
dangerous case. The easiest to demonstrate is Gate 3 (code quality): a type error
must make it fail.

**To pass:**
1. After a story is built, add a deliberate type error to a page file, e.g.:
   ```typescript
   const x: number = "this is not a number";
   ```
2. Run `/quality-check` (or `node .claude/scripts/quality-gates.js`).
3. Confirm Gate 3 reports **FAIL**.
4. Remove the line (RB-7) and confirm it passes again.

**What failure looks like:**
- ❌ The gate reports a pass with the type error present.

### b. Expected result
✅ **Pass:** the injected error makes the right gate fail; removing it restores a
pass.
❌ **Fail:** the error is reported as passing.

### c. How to check
```bash
node .claude/scripts/quality-gates.js
echo "Exit code: $?"   # expect non-zero with the error present
```

### Rollback
RB-7.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## 32. The permission system blocks dangerous commands

**Phase:** any · **Depends on:** CP-0

### a. What we're checking
The bash permission hook denies dangerous commands (e.g. `rm -rf /` variants)
while allowing ordinary ones. This is security-critical — one dangerous command
slipping through is the worst failure.

**To pass:**
1. Ask Claude to run an obviously dangerous command (e.g. a recursive force-delete
   of a system path).
2. Confirm it's denied/blocked, not executed.
3. Confirm an ordinary command (e.g. `ls`, `npm test`) is allowed.

**What failure looks like:**
- ❌ A dangerous command runs, or an ordinary safe command is wrongly blocked.

### b. Expected result
✅ **Pass:** dangerous commands denied, safe commands allowed.
❌ **Fail:** a dangerous command runs (or routine work is over-blocked).

### c. How to check
The Tier 1 suite covers this exhaustively:
```bash
npx vitest run tier-1-unit/hooks/bash-permission-checker.test.ts
```

### Rollback
None.

### d. Result
```
[ ] Pass  [ ] Fail
Date: ___________
Notes:
```

---

## Quick reference — what each test catches

| Test | What breaks if it fails |
|---|---|
| 1 Setup flows into INTAKE | `/start` stalls after install instead of continuing |
| 2 Telemetry recorded | The recording (used by Tier 2) isn't produced; or old logging crept back |
| 3 Dashboard updates | The dashboard goes stale, shows work too early, or a dashboard error stops the workflow |
| 4 Onboarding paths | A starting path is missing, or the pitch is forced into buttons |
| 5 Checklist questions | A required INTAKE question is skipped or mis-optioned |
| 6 Auth options & warnings | Auth is inferred silently, or a trade-off warning is missing |
| 7 Content before approval | An approval question appears with nothing to review |
| 8 Manifest output | The captured config isn't recorded for later phases |
| 9 Project brief (Gate 1) | The wrong/missing artifact, or PLAN starts without approval |
| 10 Epic approval | Epics are skipped or don't match the brief |
| 11 Story approval | Stories are skipped, or a later epic's stories are created early |
| 12 Story role | A story is missing its role declaration |
| 13 Failing tests first | Code is written before tests, or tests don't really assert |
| 14 Playwright per story | A routable story has no live E2E spec |
| 15 Code makes tests pass | Tests still fail, or a component bypasses the API client |
| 16 Fix cycle ≤ 3 | Failures are ignored, or the loop never stops |
| 17 Quality gates in BUILD | A failure is reported as a pass (or a removed gate reappears) |
| 18 Commit & push per story | Stories aren't committed individually, or decisions aren't recorded |
| 19 Halt on big decisions | The workflow guesses on a dependency/contract/auth change |
| 20 Epic summary & manual check | An epic ends with no summary or no manual verification |
| 21 Exact API paths | Generated calls use guessed paths |
| 22 Shadcn primitives | Hand-rolled components replace Shadcn ones |
| 23 No suppressions | `@ts-ignore` / `eslint-disable` sneaks into the code |
| 24 Plain language | Engineering jargon leaks into a user-facing checklist |
| 25 Brief overrides template | Template code is wrapped instead of replaced |
| 26 COMPLETE reports | Telemetry reports aren't produced at the end |
| 27 Status command | `/status` reports the wrong phase/progress |
| 28 Quality-check command | Ad-hoc gate run reports the wrong result |
| 29 Continue recovery | Lost state can't be rebuilt from artifacts |
| 30 Orchestrator delegates | The orchestrator does implementation work itself |
| 31 Gate fails when it should | A real defect is reported as passing |
| 32 Permission system | A dangerous command isn't blocked |
