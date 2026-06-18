# How the Stadium 8 Workflow Works

A plain-English reference for how this template drives Claude Code: the phases,
the agents, the gates, the hooks, and the machinery underneath. If you want to
*test* the template, see [TEST-GUIDE.md](TEST-GUIDE.md), [TEST-INPUTS.md](TEST-INPUTS.md),
and [TEST-STRATEGY.md](TEST-STRATEGY.md). This document explains *what* you're
testing.

> **One thing to get straight up front.** The workflow has **four phases** —
> **INTAKE → PLAN → BUILD → COMPLETE**. If you read anything here (or anywhere)
> that mentions DESIGN, SCOPE, STORIES, REALIGN, TEST-DESIGN, WRITE-TESTS,
> IMPLEMENT, a "QA phase", an "FRS", a "spec-compliance watchdog", "Gate 6",
> `/clear` boundaries, or a `[Logs saved]` marker — that's the old model and it's
> gone.

---

## Table of contents

1. [What this repository is](#1-what-this-repository-is)
2. [The big picture — the four-phase workflow](#2-the-big-picture--the-four-phase-workflow)
3. [Slash commands](#3-slash-commands)
4. [The phases in detail](#4-the-phases-in-detail)
5. [Agents — who does what](#5-agents--who-does-what)
6. [How decisions get made — autonomy tiers and the journal](#6-how-decisions-get-made--autonomy-tiers-and-the-journal)
7. [Context management](#7-context-management)
8. [The questions INTAKE asks, and how the answers are used](#8-the-questions-intake-asks-and-how-the-answers-are-used)
9. [Quality gates](#9-quality-gates)
10. [Policies the workflow won't break](#10-policies-the-workflow-wont-break)
11. [Hooks — what runs automatically](#11-hooks--what-runs-automatically)
12. [The permission system](#12-the-permission-system)
13. [How the orchestrator works](#13-how-the-orchestrator-works)
14. [State tracking and recovery](#14-state-tracking-and-recovery)
15. [Telemetry](#15-telemetry)
16. [The dashboard](#16-the-dashboard)
17. [Key files and directories](#17-key-files-and-directories)
18. [Technical stack](#18-technical-stack)
19. [Glossary](#19-glossary)

---

## 1. What this repository is

A **template** for building production-ready frontend applications. You clone it
and use Claude Code to build features through a guided, test-first workflow.

**Tech stack:**
- Next.js 16 (App Router) + React 19 + TypeScript 5 (strict)
- Tailwind CSS 4 + Shadcn UI
- Vitest + React Testing Library, Playwright for end-to-end tests
- An OpenAPI-driven API client

**Layout:**
```
project-root/
├── .claude/         Claude config: agents, hooks, scripts, commands, policies
├── web/             The Next.js application
├── documentation/   What you provide: specs, API docs, wireframes
└── generated-docs/  What the workflow produces: the brief, stories, dashboard, reports
```

---

## 2. The big picture — the four-phase workflow

Each feature runs through four phases. The first one is hands-on; the rest are
mostly automatic.

```
INTAKE  →  PLAN  →  BUILD  →  COMPLETE
```

| Phase | How often | What happens | You're asked to… |
|---|---|---|---|
| **INTAKE** | Once per feature | Gather requirements into a single project brief | Approve the brief (Gate 1) |
| **PLAN** | Once per feature (loops per epic) | Break the work into epics, then stories for one epic at a time | Approve the epics, then the stories (Gate 2) |
| **BUILD** | Per story | Write tests, write code, review, commit — one story at a time | Nothing, unless it hits a decision it can't make alone, or you reach an epic's manual check |
| **COMPLETE** | Once at the end | Mark the feature done, produce reports | Nothing |

**The core ideas:**
- Stories are planned and built **one epic at a time**, not all upfront — so what
  you learn early can shape what comes next.
- Tests are written **just before** the code for each story — real test-first
  development.
- BUILD runs on its own. It only stops to ask you about genuinely risky decisions
  (a new dependency, an auth change, an undocumented API call) or to have you try
  a finished epic in the browser.

---

## 3. Slash commands

Type these in the Claude Code chat.

| Command | What it does |
|---|---|
| `/start` | Begins the workflow — installs anything missing, runs INTAKE through Gate 1, then chains into `/continue` |
| `/continue` | Drives PLAN and BUILD; resumes from wherever the workflow left off |
| `/status` | Shows progress (phase, epic, story, recent commits) without changing anything |
| `/quality-check` | Runs the automated quality gates on demand |
| `/dashboard` | Generates the HTML dashboard and opens it in the browser |
| `/api-status` | Shows where each API endpoint came from, mock status, and handler coverage |
| `/api-mock-refresh` | Rebuilds the mock handlers after the API spec changes |
| `/api-go-live` | Switches the app from mocks to the real backend |
| `/migrate-legacy` | Upgrades an old workflow-state file to the current format |

Commands are markdown files in `.claude/commands/`. When you type one, Claude Code
expands it into a set of instructions Claude follows — they're instruction sets,
not shell scripts. (There is no separate `/setup` command; `/start` handles setup.)

---

## 4. The phases in detail

### 4.1 INTAKE

**Goal:** understand what to build, and capture it in one document.

**Started by:** `/start`.

**How you can begin** (the first question after `/start`):

| Option | What happens |
|---|---|
| **Share existing docs** | You drop files into `documentation/`; the workflow scans and extracts requirements |
| **Import a prototype repo** | `import-prototype.js` pulls in docs, design tokens, and React source from a prototyping tool |
| **Build requirements together** | You describe the project in free text and answer a few questions |

**What runs:** the `intake-agent` scans `documentation/`, the orchestrator asks a
short set of checklist questions (roles, authentication, backend readiness,
compliance — see §8), and an optional `api-connectivity-agent` runs a quick
connectivity check when there's a reachable backend.

**The one output that matters:** `generated-docs/specs/project-brief.md` — the
**project brief**, the single source of truth for everything that follows. It
lists the goal, the roles, the chosen auth method, the data source, compliance
needs, and the functional requirements and business rules.

**Gate 1:** you approve the brief. Approving it is what lets the workflow move on
to PLAN. INTAKE also writes `generated-docs/context/intake-manifest.json`, which
records the captured configuration for later phases.

### 4.2 PLAN

**Goal:** turn the brief into a buildable plan.

**Driven by:** `/continue` (which `/start` chains into automatically).

**How it works** (the `feature-planner` agent does the proposing):
1. **Epics first.** The planner proposes a list of epics covering the brief's
   requirements. You approve the list (**Gate 2a**).
2. **Then stories, one epic at a time.** For the current epic, the planner
   proposes its stories, each with acceptance criteria, a role, and a short
   manual-test checklist. You approve them (**Gate 2b**).

**Single-epic shortcut:** if there's only one epic, the two approvals collapse
into one combined gate — you approve the epic and its stories together.

**Outputs:** `generated-docs/stories/_feature-overview.md`, a per-epic overview,
and one `story-*.md` file per story.

PLAN is revisited at each epic boundary: after BUILD finishes an epic, the
workflow loops back to PLAN for the next epic's stories.

### 4.3 BUILD

**Goal:** build each story, test-first, and commit it.

**Driven by:** `/continue`.

**The per-story loop:**
```
test-generator (Vitest ∥ Playwright)  →  developer  →  (playwright-runner ∥ code-reviewer)  →  commit
```
1. **`test-generator`** writes the tests first — unit/integration tests (Vitest)
   and an end-to-end spec (Playwright). They fail at this point, because the
   feature doesn't exist yet. That's the point.
2. **`developer`** writes the code to make those tests pass. All API calls go
   through the API client; UI is built from Shadcn primitives.
3. **`playwright-runner`** (runs the browser tests) and **`code-reviewer`** (runs
   the automated quality gates and reviews the code) run **in parallel**.
4. If either comes back with failures, the `developer` is sent back in to fix
   them — up to **three attempts** per story. After the third, BUILD stops and
   asks you what to do rather than looping forever.
5. When the story passes, it's **committed and pushed**, and BUILD moves to the
   next story.

**Halts:** for genuinely risky decisions (see §6), BUILD stops and asks you,
showing the options. Everything else it decides on its own and records.

**Epic boundary:** when an epic's stories are all built, the workflow shows an
**Epic Completion Summary** (commits made, decisions taken, anything worth a
glance) and runs **Gate 1** — the manual check, where you try the epic in the
browser and report back. Then it loops to PLAN for the next epic, or to COMPLETE
if that was the last one.

### 4.4 COMPLETE

**Goal:** wrap up.

When the last epic is done, the workflow marks the feature complete, generates
three telemetry reports (timing, tokens, and a final summary) under
`generated-docs/reports/`, opens the final report, and prints a short completion
message. If you later want to extend a completed feature, `/continue` reopens it
and routes new requirements back through PLAN.

---

## 5. Agents — who does what

Each agent is a markdown file in `.claude/agents/` with a frontmatter header
(name, model, tools) and instructions. The orchestrator launches them; they don't
talk to you directly (see §13 for why).

| Agent | Phase | What it produces |
|---|---|---|
| `intake-agent` | INTAKE | The project brief and the intake manifest |
| `api-connectivity-agent` | INTAKE | A real connectivity check (parses the spec's auth, runs a smoke test) |
| `feature-planner` | PLAN | The epic list and the per-epic story files |
| `design-api-agent` | BUILD (on demand) | An OpenAPI spec, when the brief needs one and you didn't provide it |
| `design-style-agent` | BUILD (on demand) | CSS design tokens and a style reference from the brief's styling |
| `type-generator-agent` | BUILD (on demand) | TypeScript types and typed endpoint functions from the API spec |
| `mock-setup-agent` | BUILD (on demand) | MSW mock handlers from the API spec |
| `test-generator` | BUILD | Failing Vitest tests and Playwright specs (before the code) |
| `developer` | BUILD | The implementation that makes the tests pass |
| `playwright-runner` | BUILD | Runs the Playwright specs and returns a structured result |
| `code-reviewer` | BUILD | Runs the quality gates, reviews the code, and commits |

`tone-guide` is also in the folder, but it's a voice/style reference the others
follow, not a workflow step.

> **Why agents don't ask you questions.** `AskUserQuestion` silently auto-resolves
> inside a subagent without waiting for you. So only the parent orchestrator uses
> it. When an agent needs a decision, it returns the question to the orchestrator,
> which shows you the content and asks. This is a Claude Code platform constraint,
> and it's why approvals always come from the orchestrator, never an agent.

---

## 6. How decisions get made — autonomy tiers and the journal

BUILD agents make a lot of small calls on their own. To keep that safe and
transparent, every decision falls into one of four tiers, defined in
`.claude/shared/agent-autonomy.md`. The rule of thumb: when in doubt, pick the
**more conservative** tier.

| Tier | What it covers | What the agent does | Where you can see it |
|---|---|---|---|
| **1 — Autonomous** | Low-risk, easily reverted (file naming, common React patterns, which Shadcn component, ARIA labels) | Decide and proceed | One line in the commit body |
| **2 — Journal as you go** | Worth knowing afterwards (naming/shape reconciliations, factual additions to the brief) | Decide, write a journal entry, proceed | The journal + the epic summary |
| **3 — Surface at epic boundary** | Interpretations you might want to know *before the next epic plans against them* | Decide, journal with a `[review]` or `[affects-downstream]` tag, proceed | Called out in the Epic Completion Summary |
| **4 — Halt** | Genuinely unsafe ground | Stop and ask you | An `AskUserQuestion` with options |

**The "always-halt" (Tier 4) categories** include: a new external dependency, an
API-contract change, calling an endpoint not in the spec, an auth-flow change, a
state-management/data-fetching library switch, a cross-cutting architecture
change, and a *structural* contradiction with the brief (not a naming or wording
clarification — those are Tier 2/3).

**The journal** (`generated-docs/context/journal.md`) is the running record of
Tier 2 and Tier 3 decisions. It's written by `journal.js` (the orchestrator calls
it before committing a story), kept in plain, conversational English, and
organised by epic. The Epic Completion Summary reads the flagged (`[review]` /
`[affects-downstream]`) entries back to you; the rest stay in the journal for
reference. Tier 1 decisions don't go in the journal — they live in the commit
body only.

This replaces the old "discovered impacts → REALIGN" mechanism entirely.

---

## 7. Context management

The workflow **chains continuously** from INTAKE through COMPLETE. There are **no
mandatory `/clear` boundaries** — you don't need to reset context between phases.
The single source of truth for where things stand is
`generated-docs/context/workflow-state.json`, and `/continue` re-enters at
whatever phase that file shows.

**If auto-compaction fires** mid-workflow, the `inject-phase-context.ps1` hook
restores the workflow state automatically: it reads `workflow-state.json` and the
matching `.claude/hooks/phase-context/<phase>.md` file (`intake.md`, `plan.md`,
or `build.md`) and injects them back into context. You don't have to do anything.

**If state is lost** (the file is deleted), `/continue` runs
`transition-phase.js --repair`, which reconstructs the phase from the artifacts on
disk and tells you how confident it is (see §14).

---

## 8. The questions INTAKE asks, and how the answers are used

### Onboarding (right after `/start`)

**"How would you like to get started?"** → share existing docs / import a
prototype repo / build requirements together. The "build together" path then asks
for a free-text **elevator pitch** (a plain-text prompt, not buttons — because the
answer is open-ended).

### Checklist questions (asked by the orchestrator)

**1. Roles.** "Which roles template fits your app?" — presets (SaaS Standard,
Internal Tool, Marketplace, Editorial) plus the option to describe your own.
Recorded as the roles in the brief; drives permission handling.

**2. Authentication.** "How will users authenticate?" — **always asked
explicitly**, never inferred:
- **Backend For Frontend (BFF)** — the backend handles OIDC and sets cookies.
  Follow-up (free text): login, userinfo, and logout URLs. A note explains that
  CI can't reach a real BFF, so the performance gate runs against mocks.
- **Frontend-only (next-auth)** — Next.js handles auth. A note explains the
  trade-off: API calls won't carry session context, so it protects frontend
  routes only.
- **Custom** — follow-up: describe your approach.

**3. Backend readiness.** "Is your backend API up and running?" — Yes / No, still
in development / N/A, no backend. This, combined with whether a spec was found in
`documentation/`, sets the **data source**:

| Spec found? | Backend? | Data source | Mock layer? |
|---|---|---|---|
| Yes | Running | `existing-api` | No |
| Yes | In development | `api-in-development` | Yes |
| No | Running | `new-api` | No |
| No | In development | `api-in-development` | Yes |
| (any) | N/A | `mock-only` | No |

**4. Compliance.** A multi-select of regulated areas (payment/PCI, personal
data/GDPR-POPIA-CCPA, health/HIPAA, multi-tenant/SOC 2), or "none." Picking
personal data adds a region follow-up. Recorded as the compliance domains in the
brief.

### Approval questions

- After the brief: **Gate 1** — approve the project brief.
- During PLAN: **Gate 2** — approve the epics, then the stories per epic.
- At each epic boundary: the manual verification check.

### The two-step approval rule

Every approval follows the same shape: **show the content as normal text first,
then ask.** The orchestrator never pops an approval question without the thing to
approve sitting right above it.

---

## 9. Quality gates

Gates are **binary** — pass or fail. No "expected failures count as passes," no
conditional passes. There are **five** gates; there is no Gate 6.

| Gate | Type | Checks | Passes when |
|---|---|---|---|
| **Gate 1 — Functional** | Manual | You confirm the feature works (at each epic boundary) | You say it works |
| **Gate 2 — Security** | Automated | `npm audit`, secret scan | No high/critical vulnerabilities; no hardcoded secrets |
| **Gate 3 — Code quality** | Automated | Prettier, TypeScript (`tsc --noEmit`), ESLint, build | Zero type/lint errors; build succeeds |
| **Gate 4 — Testing** | Automated | Vitest, test-quality checks | All tests pass (and meet the quality bar) |
| **Gate 5 — Performance** | Automated | Lighthouse (when configured) | Within budget, or reported as not-configured |

Gates 2–5 run automatically inside BUILD (the `code-reviewer` runs them per
story), and you can run them on demand with `/quality-check`. Gate 1 is the manual
browser check at each epic boundary.

**When a gate fails:** the workflow reports the real result — what failed and why
— and either fixes it (inside BUILD's fix cycle) or, on `/quality-check`, presents
the failure for you to decide. It never rationalises a failure as acceptable.

---

## 10. Policies the workflow won't break

These come from `CLAUDE.md` and the files under `.claude/policies/` and
`.claude/shared/`.

- **The brief overrides template code.** The template ships with starter code
  (e.g. NextAuth wiring). If the brief specifies something different, the workflow
  **replaces** the template code rather than wrapping new behaviour around it.
- **No error suppressions.** Never `@ts-ignore`, `@ts-expect-error`,
  `@ts-nocheck`, or `eslint-disable`. Errors get fixed, not hidden.
- **Authentication is always asked explicitly.** Even if the docs make the answer
  obvious, all three auth options are presented during INTAKE. Auth touches every
  layer — no assumptions.
- **Never auto-approve.** If something needs your approval, the workflow stops and
  asks. It never proceeds on your behalf.
- **The API spec is authoritative.** Before writing any API call, the workflow
  checks `documentation/` and `generated-docs/specs/` for a spec, and uses its
  exact paths, methods, and types. If a call fails, it reports the real error and
  references the spec — it never guesses.
- **Shadcn for UI primitives.** Buttons, dialogs, inputs, cards, etc. are Shadcn
  components (installed via the Shadcn MCP). No hand-rolled "Shadcn-style"
  components.
- **Plain language for anything you read.** User-facing text avoids jargon — "the
  app builds correctly," not "TypeScript compiled with zero diagnostics."
- **First person.** When relaying an agent's findings, the workflow speaks as
  "I"/"we," not "the intake-agent did X."

---

## 11. Hooks — what runs automatically

Hooks are commands Claude Code runs on certain events. They're defined in
`.claude/settings.json`.

| Event | What runs | Purpose |
|---|---|---|
| `UserPromptSubmit` | `workflow-guard.ps1` | Nudges development requests into the workflow |
| `UserPromptSubmit` | `telemetry.js` | Records a user-input event |
| `SessionStart` (compact) | `inject-phase-context.ps1` | Restores workflow state after auto-compaction |
| `SubagentStart` (named agents) | `inject-agent-context.ps1` | Injects the current phase/epic/story into the agent |
| `SubagentStart` (named agents) | `telemetry.js` | Records an agent-start event |
| `SubagentStop` | `telemetry.js` | Records an agent-stop event |
| `Stop` | `telemetry.js` | Records the end of a response turn |
| `PreToolUse` (Bash) | `bash-permission-checker.js` | Validates Bash commands before they run |
| `PreToolUse` (Write/Edit) | `claude-md-permission-checker.js` | Guards edits to `CLAUDE.md` |
| `PreToolUse` (Write/Edit) | `enforce-generated-doc-names.js` | Enforces the naming rules for generated docs |

The named-agent matcher covers `developer`, `test-generator`, `code-reviewer`,
`feature-planner`, `design-api-agent`, `design-style-agent`, `intake-agent`,
`api-connectivity-agent`, `playwright-runner`, `mock-setup-agent`, and
`type-generator-agent`.

> There is **no** session-logging hook and **no** `capture-context.ps1` — the old
> `.claude/logs/*.md` logging was replaced by telemetry (§15).

---

## 12. The permission system

Defined in `.claude/settings.json` under `permissions`.

**Always allowed (no prompt):**
- All Shadcn MCP operations (`mcp__shadcn-ui__*`)
- Reading/writing/editing under `documentation/**`, `generated-docs/**`, `web/**`
- Globbing those folders and `.claude/**`
- A specific set of test/build commands: Playwright (`npx playwright …`,
  `npm run test:e2e`), Vitest (`npx vitest …`, `npm --prefix web test …`), and
  `node .claude/scripts/*.js`

**Always denied (blocked outright):**
- `rm -rf /` and `rm -rf /*`
- Reading SSH keys and secrets (`*.ssh/*`, `id_rsa`, `*.pem`, `credentials`)
- Shell ways of reading those same secret files (`cat` / `type` / `Get-Content` /
  `sed` on the sensitive patterns)

**Everything else** prompts for approval when used. The `bash-permission-checker.js`
hook validates each Bash command against these rules before it runs (and the QA
suite fuzzes it hard — see TEST-GUIDE §32).

---

## 13. How the orchestrator works

The **orchestrator** is the parent Claude instance running `/start` or
`/continue`. It's the conductor: it launches agents, manages the conversation,
asks you for approvals, and tracks phase transitions. The agents do the heavy
lifting; the orchestrator coordinates.

A few principles keep it reliable:

- **Keep parent tool calls light.** The orchestrator aims for about three tool
  calls per response outside natural turn boundaries, and delegates heavy work
  (long bash sequences, file-by-file work) to subagents. Answering an
  `AskUserQuestion` starts a fresh turn, which resets that budget. (`playwright-runner`,
  for example, exists partly so the E2E run happens inside a subagent rather than
  in the parent.)
- **Approvals come from the parent.** Because `AskUserQuestion` doesn't work inside
  subagents (§5), any decision an agent needs is returned to the orchestrator,
  which shows you the content and asks.
- **BUILD is synchronous from the orchestrator's view**, so halts surface
  immediately and in order — no race conditions.
- **The brief is authoritative**, and the agents already know it, so the
  orchestrator doesn't need to repeat "the brief wins" on every call.

---

## 14. State tracking and recovery

### The state file

`generated-docs/context/workflow-state.json` tracks the current phase (INTAKE /
PLAN / BUILD / COMPLETE), the current epic and story, per-story status, and
history.

### The scripts behind it

| Script | Purpose |
|---|---|
| `transition-phase.js` | Moves between phases with validation; also `--show`, `--init`, `--repair` |
| `collect-dashboard-data.js` | Gathers the full workflow state (powers `/status` and the dashboard) |
| `generate-dashboard-html.js` | Regenerates the HTML dashboard |
| `generate-todo-list.js` | Produces the in-chat progress checklist |
| `generate-telemetry-report.js` | Builds the timing / tokens / final reports from telemetry |
| `quality-gates.js` | Runs Gates 2–5 and reports pass/fail as JSON |
| `journal.js` | Appends and reads the decision journal |
| `import-prototype.js` | Imports a prototype repo into `documentation/` |
| `scan-doc.js` | Scans `documentation/` for content and keywords |
| `migrate-legacy-state.js` | Upgrades an old state file to the current format |

All scripts output JSON with a `status` of `ok` (proceed), `error` (stop and
report), or `warning` (proceed with care).

### Recovery

If the state file is missing or unclear, `transition-phase.js --repair`
reconstructs the phase from the artifacts on disk and reports a confidence level:
**high** (proceed), **medium** (show detected vs assumed, confirm with you), or
**low** (require your verification).

### Files agents use to talk to each other

| File | Written by | Read by |
|---|---|---|
| `project-brief.md` | `intake-agent` | everyone — it's the source of truth |
| `intake-manifest.json` | `intake-agent` | PLAN and BUILD |
| `workflow-state.json` | the transition scripts | all agents |
| `journal.md` | `developer` / orchestrator (via `journal.js`) | the Epic Completion Summary |
| `telemetry.ndjson` | the telemetry hooks | the telemetry reports |

---

## 15. Telemetry

Instead of writing session logs, the template records a stream of events to a
**telemetry ledger** and derives reports from it.

- **The ledger** — `generated-docs/context/telemetry.ndjson`, an append-only list
  of events (phase entered/exited, agent started/stopped, turn ended). It's
  written by `.claude/hooks/telemetry.js` and the small library under
  `.claude/scripts/lib/` (`telemetry.js`, `transcript-tokens.js`).
- **The reports** — `generate-telemetry-report.js` turns the ledger (plus token
  data pulled from the transcript) into four views: `--estimate` (a forecast),
  `--timing` (time per phase/agent, excluding time spent waiting on you),
  `--tokens` (token usage), and `--final` (estimate-vs-actual per story). COMPLETE
  generates the timing, tokens, and final reports as HTML under
  `generated-docs/reports/`.

There is **no** `[Logs saved]` marker and **no** `.claude/logs/` folder — those
belonged to the old logging system.

---

## 16. The dashboard

`generated-docs/dashboard.html` is a visual overview — phases, epics, stories, and
status.

- **Auto-refreshes every 10 seconds** via a `<meta http-equiv="refresh">` tag, so
  it updates itself if you leave the tab open.
- **Regenerated at milestones** — end of INTAKE, after each PLAN approval, after
  each BUILD agent returns, after each commit, at each epic summary, and at
  completion.
- **Fire-and-forget** — if regenerating it ever fails, the workflow keeps going.
- **You can open it any time** with `/dashboard`.

---

## 17. Key files and directories

| Path | Purpose |
|---|---|
| `CLAUDE.md` | The primary instruction file, read at the start of every conversation |
| `.claude/settings.json` | Hooks and permissions |
| `.claude/WORKFLOWS.md` | The workflow design overview |
| `.claude/shared/orchestrator-rules.md` | Rules both `/start` and `/continue` must follow |
| `.claude/shared/agent-autonomy.md` | The four-tier decision framework (§6) |
| `.claude/policies/authentication-intake.md` | The "always ask auth explicitly" policy |
| `.claude/policies/compliance-intake.md` | Compliance question triggers |
| `.claude/policies/quality-gates.md` | Gate definitions and the binary pass/fail rule |
| `.claude/agents/` | One file per agent |
| `.claude/commands/` | One file per slash command |
| `.claude/hooks/phase-context/` | Per-phase context restored after compaction (`intake.md`, `plan.md`, `build.md`) |
| `documentation/` | What you provide: specs, API docs, wireframes |
| `generated-docs/specs/` | The project brief, and any generated API spec / design tokens |
| `generated-docs/context/` | State, manifest, journal, telemetry |
| `generated-docs/stories/` | Epic and story files |
| `generated-docs/qa/` | Manual verification checklists |
| `generated-docs/reports/` | Telemetry reports |
| `web/src/lib/api/client.ts` | The API client — every API call goes through this |
| `web/src/types/api-generated.ts` | Types generated from the OpenAPI spec |
| `web/src/lib/api/endpoints.ts` | Typed endpoint functions generated from the spec |
| `web/e2e/` | Playwright specs |

---

## 18. Technical stack

### Frontend (in `web/`)

| Technology | Role |
|---|---|
| Next.js 16 (App Router) | Framework — pages in `app/`, server components by default |
| React 19 | UI |
| TypeScript 5 (strict) | Type safety — suppressions forbidden |
| Tailwind CSS 4 | Styling |
| Shadcn UI | Component primitives, always via MCP |
| Vitest + React Testing Library | Unit/integration tests |
| Playwright | End-to-end tests |
| MSW (Mock Service Worker) | API mocking when the backend isn't ready |

### Conventions

- **Path alias:** `@/` resolves to `web/src/`.
- **API calls:** never `fetch()` directly in a component — always the API client
  (`get` / `post` / `put` / `del`). The OpenAPI spec is the source of truth for
  paths, methods, and types.
- **Tests:** focus on user-observable behaviour, not implementation. Query
  priority `getByRole` > `getByLabelText` > `getByText` > `getByTestId`. Every
  routable story gets a live Playwright spec; non-routable stories get a
  `test.fixme()` spec with a one-line reason.

---

## 19. Glossary

| Term | Meaning |
|---|---|
| **Project brief** | `project-brief.md` — the single document INTAKE produces; the source of truth for the whole feature |
| **Intake manifest** | `intake-manifest.json` — the captured configuration (roles, auth, data source, compliance) used by later phases |
| **Epic** | A group of related stories that together deliver a major piece of functionality |
| **Story** | A single user-facing behaviour, small enough to build and test in one cycle |
| **Acceptance criteria (AC)** | Testable statements in a story file that define when it's done |
| **Role** | Who a story is for; declared in the story file and used for permission-aware behaviour |
| **Gate** | A quality check; all gates are binary pass/fail |
| **Autonomy tiers** | The four-tier framework (§6) deciding whether an agent proceeds, journals, surfaces, or halts |
| **Journal** | `journal.md` — the plain-English record of Tier 2/3 decisions, surfaced at epic boundaries |
| **Orchestrator** | The parent Claude running `/start` or `/continue`; coordinates agents and handles approvals |
| **Telemetry ledger** | `telemetry.ndjson` — the append-only event stream the reports are built from |
| **Data source** | How the app gets data: `existing-api`, `new-api`, `api-in-development`, or `mock-only` |
| **BFF** | Backend For Frontend — an auth pattern where the backend handles OIDC and sets HTTP-only cookies |
| **MSW** | Mock Service Worker — intercepts API calls in the browser when the backend isn't ready |
| **Halt** | A Tier-4 stop where BUILD asks you about an unsafe decision before proceeding |

---

*This document describes the four-phase template (INTAKE → PLAN → BUILD →
COMPLETE) as of 2026-06-16.*
