# How the Stadium 8 Workflow Works

A plain-English reference for how this template drives Claude Code: the phases,
the commands, the helpers, the safety checks, and the machinery underneath. If
you want to *test* the template, see the test guide, the inputs list, and the
strategy document that sit alongside this one. This document explains *what* you
are testing.

> **One thing to get straight up front.** The unit of work is the **epic** — one
> meaningful chunk of the app. Each epic is built on its own branch (its own
> separate copy of the project) and runs through a fixed set of stages:
> **INTAKE → PLAN → BUILD → EPIC-END → MANUAL-TEST → COMPLETE-ON-BRANCH →
> COMPLETE**. The facts that stay the same across the whole project live in one
> shared file called `project.md`; each epic gets its own short requirements file
> called `brief.md`. If you read older notes that mention four phases, a single
> "project brief", a "code-reviewer", a spec-compliance watchdog, usage/telemetry
> reports, or `/clear` boundaries — that's a previous version and it's gone.

---

## Table of contents

1. [What this repository is](#1-what-this-repository-is)
2. [The big picture — the epic-branch workflow](#2-the-big-picture--the-epic-branch-workflow)
3. [Slash commands](#3-slash-commands)
4. [The phases in detail](#4-the-phases-in-detail)
5. [Agents — who does what](#5-agents--who-does-what)
6. [How decisions get made — the four autonomy tiers](#6-how-decisions-get-made--the-four-autonomy-tiers)
7. [The four approvals](#7-the-four-approvals)
8. [The questions INTAKE asks](#8-the-questions-intake-asks)
9. [Quality gates](#9-quality-gates)
10. [Policies the workflow won't break](#10-policies-the-workflow-wont-break)
11. [Hooks — what runs automatically](#11-hooks--what-runs-automatically)
12. [The permission system](#12-the-permission-system)
13. [State tracking and recovery](#13-state-tracking-and-recovery)
14. [Working on more than one epic at once](#14-working-on-more-than-one-epic-at-once)
15. [How the app is tested](#15-how-the-app-is-tested)
16. [The dashboard](#16-the-dashboard)
17. [Key files and directories](#17-key-files-and-directories)
18. [Technical stack](#18-technical-stack)
19. [Glossary](#19-glossary)

---

## 1. What this repository is

A **template** — a starter kit — for building production-ready web apps. You make
a copy of it and use Claude Code to build your app one epic at a time, through a
guided, test-first process. You describe what you want in plain language; Claude
plans it, builds it, tests it, and checks it, without expecting you to read or
write any code.

**The layout of a project built from this template:**

- `documentation/` — what *you* provide: specs, requirements, wireframes, data
  descriptions.
- `generated-docs/` — what the workflow *produces*: the shared project facts, each
  epic's folder, the plan, the dashboard.
- `web/` — the actual Next.js application being built.
- `.claude/` — Claude's own instructions and settings that make the workflow run.

---

## 2. The big picture — the epic-branch workflow

The work is split into **epics**. An epic is one meaningful piece of the app —
for example, "let people sign in" or "show the task list". A whole project is
just several epics built one after another (and sometimes side by side).

Each epic is built on its own **branch**. A branch is a separate copy of the
project where work happens without disturbing the finished, trusted version (which
lives on the branch called `main`). When an epic is finished and you're happy with
it, its work is merged into `main` and the branch is deleted.

Two files carry the requirements:

- **`project.md`** — the shared project facts that every epic inherits: who the
  users are, how people sign in, where the app's data comes from, any rules the
  app must follow, and the look and feel. It lives on `main`.
- **`brief.md`** — a short description of what one particular epic needs to
  deliver. Each epic has its own.

**Every epic goes through these stages, in order:**

| Stage | What happens | Are you asked anything? |
|---|---|---|
| **INTAKE** | Runs once at the very start of the project (before any branch). Gathers the project facts and splits your request into epics. | Yes — approve the project facts and the epic plan |
| **PLAN** | Breaks one epic into a handful of small pieces of work ("stories"). | Yes — approve the story list |
| **BUILD** | Builds each story, test-first, and saves it. | No — unless a risky decision comes up |
| **EPIC-END** | Runs the full set of automatic checks, an automatic code review, and the browser tests over the whole epic. | No |
| **MANUAL-TEST** | You try the finished epic yourself using a checklist. | Yes — confirm it works |
| **COMPLETE-ON-BRANCH** | Opens a request to merge the epic into `main`, waits for automated checks, and merges once you approve. | Yes — approve the merge |
| **COMPLETE** | The epic's record is frozen on `main`. | No |

**The core ideas:**

- Stories are planned and built **one epic at a time**, not all up front — so what
  you learn early can shape what comes next.
- Tests are written **just before** the code for each story — genuine test-first
  building.
- Building runs on its own. It stops only for genuinely risky decisions, or to have
  you try a finished epic yourself.

---

## 3. Slash commands

You steer the workflow by typing these into the Claude Code chat.

| Command | What it does |
|---|---|
| `/start` | Begins a new epic. The first time, it sets up the project, gathers the facts, and plans all the epics; after that, it starts the next epic. It then hands over to `/continue`. Run it from `main`. |
| `/continue` | Carries the current epic forward through planning, building, checking, your review, and the merge. Also picks up wherever you left off. Run it on the epic's branch. |
| `/status` | Shows where things stand — epics in progress and finished ones — without changing anything. |
| `/quality-check` | Runs the automatic safety checks on demand. |
| `/dashboard` | Opens a simple visual overview in your browser. |
| `/migrate-legacy` | Upgrades a project built with an older version of this kit to the current epic-branch way of working. |
| `/api-status` | Shows where each piece of the app's data comes from, whether stand-in data is in use, and whether the real data source has been reached. |
| `/api-mock-refresh` | Rebuilds the stand-in data after the data-source description changes, keeping any hand-tuned examples. |
| `/api-go-live` | Switches the app from stand-in data over to the real data source, after checking the real source can be reached. |

Commands are instruction files, not scripts — when you type one, Claude follows
the instructions it contains.

---

## 4. The phases in detail

### 4.1 INTAKE

**Goal:** understand the project, capture its facts, and plan the epics. INTAKE
runs once, before any epic branch exists, driven by `/start`. There are two ways
it can go.

**The first time (a brand-new project):**

1. **Setup.** If needed, Claude installs the app's dependencies in the background
   and asks a one-time question: should it auto-approve saving and publishing work,
   or ask you each time? Your answer is remembered and honored from then on.
2. **How to begin.** Claude asks how you'd like to start: bring in a prototype you
   built elsewhere, share your own documents, or describe the project together and
   answer a few questions.
3. **Setup questions.** A short checklist about who uses the app, how people sign
   in, whether your data source is ready, and any rules you must follow (see
   [section 8](#8-the-questions-intake-asks)).
4. **Connection check.** If your app talks to a real data source, Claude runs a
   quick test to confirm it can actually be reached, before any time is spent on it.
5. **Project facts written.** Claude writes `project.md` — the shared facts sheet.
6. **The epic plan.** Claude looks at your whole request and splits it into a list
   of epics, showing which ones depend on others and confirming that every part of
   your request is covered by some epic. If anything can't be placed (a conflict, a
   missing detail, a rule that blocks it), Claude raises it with you first and
   won't show a plan with an unresolved snag in it.
7. **You approve** the project facts and the epic plan together. Claude also opens
   an editable review page in your browser so you can adjust before approving.
8. **Getting started.** Once approved, Claude writes a short requirements file for
   every epic, saves the plan to `main`, then starts the first epic that's ready to
   go (one with nothing it depends on) on its own branch, and hands over to
   `/continue`. The other epics wait as drafts you can pick up later.

**Every later epic (the project already exists):**

1. Claude notices `project.md` is already there.
2. It shows you the plan and asks which epic to do next — a ready draft, or
   something new.
3. It confirms the project facts still hold (a quick checklist; ticking anything
   that changed re-runs just that part).
4. If it's a new epic, it asks what the epic should deliver and whether it builds
   on any other epic.
5. It writes that epic's short requirements file.
6. **You approve** the epic's requirements.
7. Claude opens a fresh branch for the epic and hands over to `/continue`.

### 4.2 PLAN

**Goal:** turn one epic's requirements into a buildable list of small pieces of
work, driven by `/continue`.

Claude proposes 2–8 **stories**. A story is a single thing a user can see or do,
small enough to build and test in one go. Each story comes with a plain
description, who it's for, and a short checklist of things you'll be able to try by
hand later.

**You approve the story list.** Claude shows it as plain text and opens an editable
review page, including a "what this epic is *not* building" note so the boundaries
are clear. Once approved, Claude writes a file for each story and moves on to
building.

### 4.3 BUILD

**Goal:** build each story, test-first, and save it. Driven by `/continue`.

Before the per-story work begins, Claude does some one-time setup for the epic:
it prepares realistic **stand-in data** (pretend data the app can use while the
real data source isn't ready), and — if the project needs it — it designs a
description of the data service, generates the matching data types, and sets up
the stand-in data layer. It also writes all the stories' **tests up front, in one
batch** — the tests describe what each finished story should do, and they fail at
first because the code doesn't exist yet.

Then, for each story in turn:

1. A helper writes the code to make that story's tests pass.
2. Claude runs a quick check (formatting, basic code hygiene, and test quality).
3. The work is saved.

If the quick check fails, Claude sends the code back for a fix and checks again —
up to three tries before it stops and asks you what to do. The heavier checks (a
full build, all the tests, security, the browser tests, the code review) are *not*
run per story — they run once over the whole epic at the end, which is faster.

Along the way, Claude makes many small decisions on its own and only stops for
genuinely risky ones (see [section 6](#6-how-decisions-get-made--the-four-autonomy-tiers)).

### 4.4 EPIC-END

**Goal:** check the epic as a whole. This runs three sweeps, in order:

1. **The full safety checks** — security, code quality, and all the tests (see
   [section 9](#9-quality-gates)). This also produces a real, production version of
   the app for the browser tests to run against.
2. **An automatic code review**, which also fixes what it finds. It's careful not
   to "fix" things that are deliberate, and it re-runs the safety checks afterward
   to confirm everything is still green.
3. **The browser tests** — the "click-through" tests that act like a real person
   using the app, run against that production version of the app.

If anything fails, Claude traces it to the story responsible, fixes it, and runs
the affected sweep again — up to three tries before it stops and asks you.

### 4.5 MANUAL-TEST

**Goal:** your hands-on check. Claude opens a checklist page in your browser (with
any "please double-check this" items floated to the top, and one-click sign-ins for
each type of user) and asks you to try the epic yourself. You tell it whether
everything worked.

- **All good** → the epic moves toward merging.
- **Found a problem** → you describe it, Claude fixes it, re-runs the end-of-epic
  checks, and shows you the checklist again (only the affected items un-ticked).
- **Skip for now** → the epic moves toward merging, with a note recorded.

### 4.6 COMPLETE-ON-BRANCH

**Goal:** merge the finished epic into `main`. Claude opens a merge request,
waits for the automated checks to pass, and asks for your go-ahead to merge. It
**never merges on its own.** Once you approve, it merges, tidies away the branch,
and updates the record.

### 4.7 COMPLETE

**Goal:** wrap up. The epic's record is now frozen on `main` — its requirements,
its story files, its decision notebook, and its final status. No reports are
generated at this stage. To build the next epic, you run `/start` again.

---

## 5. Agents — who does what

Claude doesn't do everything as one big task. It hands specific jobs to
specialised **helpers** (called agents). Each is good at one thing. **Helpers don't
talk to you directly** — they report back to the main Claude (the "orchestrator"),
and the orchestrator is the one who shows you results and asks you questions.

| Helper | Stage | What it does |
|---|---|---|
| Intake helper | INTAKE | Reads your documents and writes the project facts sheet and each epic's requirements file |
| Connection checker | INTAKE | Confirms the real data source can be reached, and records the result |
| Planner | INTAKE and PLAN | Splits the project into epics, and later breaks each epic into stories |
| API designer | BUILD (when needed) | Writes a description of the data service when you didn't provide one |
| Style designer | BUILD (when needed) | Turns your branding into the app's colours, fonts, and look |
| Type generator | BUILD (when needed) | Creates the app's data types from the data-service description |
| Stand-in data helper | BUILD (when needed) | Sets up realistic pretend data for when the real service isn't ready |
| Test writer | BUILD | Writes the tests for every story first, before any code |
| Developer | BUILD | Writes the code to make each story's tests pass |
| Browser-test runner | EPIC-END | Runs the click-through browser tests over the whole epic |

There is also a shared **tone guide** — not a helper that does work, just a
reference the others follow so they all speak to you the same clear way.

There is **no** separate "reviewer" helper anymore — the code review at the end of
an epic is done by a built-in review step, not a helper.

> **Why helpers don't ask you questions directly.** The tool that pops up a
> question doesn't work properly inside a helper (it answers itself silently). So
> only the main Claude asks you things. When a helper needs a decision, it hands
> the question back to the main Claude, which shows you the details and asks. That's
> why every approval comes from the main Claude, never from a helper.

---

## 6. How decisions get made — the four autonomy tiers

While building, Claude makes a lot of small choices. To keep that safe and open,
every choice falls into one of four levels. The rule of thumb: when unsure, choose
the more cautious level. The reason for this design is that stopping to ask you is
by far the most time-consuming thing that can happen — so Claude saves your
attention for the moments that genuinely need it, and lets you review the rest at
natural pauses.

- **Level 1 — Decide quietly.** For small, low-risk, easily-undone choices — naming
  things, picking a standard building block, everyday code patterns, sensible
  defaults. Claude just does it and mentions it briefly with the saved work.
- **Level 2 — Decide and jot it down.** For choices worth knowing about afterwards.
  Claude proceeds and writes a short, plain-English note in the epic's **notebook**
  (`journal.md`). The important ones are read back to you when the epic finishes.
- **Level 3 — Decide and record it for the right audience.** For things that matter
  later. Claude proceeds and files a record where it belongs:
  - A reusable piece of code or a project-wide convention → a shared **registry**
    (`architecture.md`) that future work reads.
  - Something about the outside world Claude couldn't verify (the exact shape of
    the data source, a brand value, a rule) → a **"please double-check"** list that
    is floated to the top of your hands-on check *before* the epic is merged.
  - A problem with the template itself → a **feedback file** for the template's
    maintainers. (Claude works around template problems; it never stops for them.)
- **Level 4 — Stop and ask.** For genuinely risky ground only.

**Claude stops and asks you (Level 4)** for things like: changing who is allowed to
do what; changing the agreed shape of the data or using data the plan didn't
describe; adding a new outside tool or service; switching a core piece of the app's
plumbing; changing how sign-in works; a big structural change; something that
contradicts what you agreed; or something that would break a stated rule.

When a risky decision would change the *project-level* facts (in `project.md`),
Claude handles it in a single, streamlined step on `main` rather than asking you
twice — you see one approval, then building resumes.

---

## 7. The four approvals

Everything else runs on its own, but there are exactly four points where Claude
stops for your say-so. Every approval follows the same simple rule: **Claude shows
you the thing to approve as plain text first, then asks.** It never asks you to
approve something you can't see.

1. **The intake approval** — you approve the project facts and the epic plan (first
   time), or a single epic's requirements (every later epic).
2. **The story approval** — you approve the list of stories for an epic before any
   building starts.
3. **The hands-on approval** — you confirm the finished epic works after trying it
   yourself.
4. **The merge approval** — you approve folding the epic into `main` after the
   automated checks pass.

Saving and publishing work is handled separately, according to the preference you
set at the start (auto-approve, or ask each time).

---

## 8. The questions INTAKE asks

Right after you start a new project, Claude asks how you'd like to begin — bring in
a prototype, share your own documents, or describe it together. Then it asks a
short set of setup questions. Your answers are saved in the project facts sheet and
inherited by every epic.

- **Who uses the app?** You pick from common ready-made sets of user types — a
  standard software product (owner / admin / member / viewer), an internal tool
  (admin / user), a marketplace (moderator / seller / buyer), or a publishing setup
  (editor / author / contributor / reader) — or you describe your own. This shapes
  what different people are allowed to do.
- **How do people sign in?** **Always asked openly, never guessed.** The choices
  are: sign-in handled by your own server (the most secure option, where the app
  never handles the login secrets itself), sign-in handled inside the app, or a
  custom approach you describe. Claude explains the trade-offs, and asks the
  necessary follow-up details for whichever you choose.
- **Is your data source ready?** Whether the service the app gets its data from is
  running, still being built, or not needed. Combined with whether you've provided a
  description of that data, this decides whether the app talks to a real source or
  uses realistic stand-in data for now.
- **Any rules to follow?** Whether the app handles regulated things — payment card
  data, personal data, health information, or shared-tenant business data. This is a
  required question. If personal data is involved, Claude also asks which region's
  rules apply. If you pick nothing, Claude double-checks with you before accepting
  that no rules apply. (Basic accessibility is always applied regardless.)

---

## 9. Quality gates

Before work is accepted it has to pass some checks. Each check is simply **pass or
fail** — there's no "good enough" and no "expected failure". Claude always reports
the true result and never waves a failure through.

There are four checks in all:

| Check | How it runs | Passes when |
|---|---|---|
| **Does it work?** | You try it yourself in the browser at the end of each epic | You confirm it works |
| **Is it safe?** | Automatic — scans for security problems and for secrets left in the code | No serious security problems; no secrets |
| **Is the code sound?** | Automatic — checks formatting, correctness, and that the app builds | Everything is clean and the app builds |
| **Do the tests pass?** | Automatic — runs all the tests and checks they're good tests | Every test passes and meets the quality bar |

The three automatic checks run in a light form during building (per story) and in
full over the whole epic at the end. You can also run them any time with
`/quality-check`. When a check fails, Claude tells you plainly what failed and
either fixes it or asks you what to do — it never rationalises a failure as
acceptable.

---

## 10. Policies the workflow won't break

A few promises hold throughout:

- **What you agreed comes first.** The starter kit ships with some ready-made code.
  If what you asked for is different, Claude replaces that code rather than piling
  new behaviour on top of it.
- **No hiding problems.** Claude fixes errors rather than silencing them.
- **Sign-in is always discussed openly.** Even when the answer seems obvious, Claude
  asks how people should sign in, because it affects everything.
- **Nothing is approved on your behalf.** If something needs your say-so, Claude
  stops and asks.
- **The data source is the authority.** Before using any of the app's data, Claude
  follows the agreed description exactly. If a data request fails, it reports the
  real problem instead of guessing.
- **Consistent, ready-made building blocks.** Buttons, dialogs, form fields and the
  like come from a trusted set, not hand-made lookalikes.
- **One place for the look and feel.** All the app's colours, fonts, and spacing are
  defined in one central place and referenced by name — never scattered as one-off
  colour codes in individual screens.
- **Plain language for anything you read.** Messages to you avoid technical jargon.
- **Claude speaks as itself.** When it shares a helper's findings, it says "I" or
  "we", not "the helper did this".

---

## 11. Hooks — what runs automatically

Hooks are small commands Claude Code runs by itself at certain moments, without
being asked. This template uses five:

| When it runs | What it does |
|---|---|
| Every time you send a message | Checks where the workflow stands and nudges you to the right command if you're trying to build something outside the workflow |
| After Claude's memory is auto-trimmed in a long session | Restores its bearings — which epic, which stage, what's next |
| When a helper starts | Tells the helper which epic, stage, and story it's working on |
| Before any command line runs | Approves safe commands and blocks dangerous ones |
| Before any generated file is written | Makes sure the file has the correct, expected name and location |

---

## 12. The permission system

Claude Code asks your permission before doing anything risky. This template
pre-sets some of those answers so you're not interrupted for obviously safe things,
and blocks some outright.

**Allowed without asking:** the trusted set of interface building blocks; reading
and writing inside the project's own folders (`documentation/`, `generated-docs/`,
`web/`); and a specific set of safe test and build commands.

**Blocked outright:** the most destructive delete commands, and reading or printing
sensitive secret files (private keys, credentials).

**Everything else** asks for your approval when it comes up. The "before any command
runs" hook (section 11) is what enforces this, and the test suite tests it hard —
one dangerous command slipping through is the failure we most want to catch.

---

## 13. State tracking and recovery

The workflow keeps track of where things stand in a small status file for each
epic, stored on that epic's branch (`state.json`). It records the current stage,
each story's progress, and any point where Claude stopped to ask you.

You don't advance stages by hand and neither does a script — the main Claude moves
the stage forward itself as work completes, following the fixed order of stages.
Two small, exact operations are handled by dedicated helper scripts because they
must be perfectly reliable every time: creating a fresh epic's status file, and
marking an epic finished after it's merged.

**Recovery is simple.** Because the epic's branch name plus its status file tell
the whole story, there's nothing fragile to lose. If you close and come back, check
out the epic's branch and type `/continue` — Claude reads the status and carries on
from the right spot. If its memory gets auto-trimmed mid-session, a hook quietly
restores its bearings from the same status file. There's no special "repair" step
to run.

---

## 14. Working on more than one epic at once

Because each epic is built on its own branch, two people can work on two different
epics at the same time without clashing — there's no shared status file to fight
over.

When it's time to merge, most overlaps are simple to combine automatically — for
example, two epics adding different colours to the central style file, or different
pieces of stand-in data. Claude combines those on its own. But if two epics change
the *same* code in conflicting ways, or want different versions of the same outside
tool, Claude stops and shows you both versions so you can decide.

If one epic depends on another, that dependency is recorded, and the dependent epic
is marked as waiting until the one it needs is merged.

---

## 15. How the app is tested

Tests check **what a real person would see and do**, not hidden internal details.
There are three layers, and each behaviour is covered by exactly one of them:

- **Quick tests** — for things visible in a single screen: which buttons show for
  which users, form behaviour, loading and empty and error states.
- **Browser tests** — for things that only make sense across a real browser session:
  moving between pages, signing in, redirects, filtering and sorting, and a real
  accessibility scan.
- **Hands-on only** — for things a machine can't fairly judge: how something looks,
  screen-reader wording, how it feels. These become items on your hands-on
  checklist.

A behaviour is never tested twice across layers — that would just recreate the blind
spot the layering exists to avoid.

A few habits worth knowing:

- **Tests are written before the code** and must fail first, then pass once the code
  is written.
- **The browser tests always run against stand-in data**, never a live service — the
  real end-to-end check is the hands-on one you do yourself.
- Every part of the app that has its own screen gets a real browser test. Parts that
  don't have their own screen still get a test file, but with the tests marked as
  "to be filled in later" and a one-line reason.
- Tests are kept representative, not exhaustive, and there's a firm ceiling on how
  many go in one file, so a story that needs more is a sign it should be split.

---

## 16. The dashboard

The dashboard is a simple web page that gives you a bird's-eye view of your
progress — the epics in progress (one per branch) and the finished ones, and how
far along each is. It pulls together every branch at once, so it shows the whole
picture no matter which branch you're on.

- It **refreshes itself every ten seconds**, so it stays current if you leave it
  open.
- Claude **regenerates it at natural moments** — after approvals, after each piece
  of work is saved, and at the end of each epic.
- It's **fire-and-forget** — if it ever fails to update, that never stops the actual
  work.
- You can open it any time with `/dashboard`.

---

## 17. Key files and directories

| Where | What it is |
|---|---|
| `documentation/` | What you provide: specs, requirements, wireframes, data descriptions |
| `generated-docs/project.md` | The shared project facts, inherited by every epic |
| `generated-docs/epic-plan.md` | The plan: the list of epics, what depends on what, and coverage of your request |
| `generated-docs/epics/<epic>/brief.md` | One epic's requirements |
| `generated-docs/epics/<epic>/state.json` | One epic's live status (stage and per-story progress) |
| `generated-docs/epics/<epic>/stories/` | One file per story in that epic |
| `generated-docs/epics/<epic>/journal.md` | The epic's plain-English decision notebook |
| `generated-docs/architecture.md` | A shared registry of reusable code and project-wide conventions |
| `generated-docs/dashboard.html` | The visual progress overview |
| `generated-docs/specs/` | Generated pieces: the data-service description, the app's colours and style, stand-in-data notes |
| `web/` | The actual application |
| `.claude/` | Claude's own instructions, helpers, and settings |

---

## 18. Technical stack

The app is built with a modern, well-supported set of web-building tools, chosen
for reliability:

- **Next.js and React** — the framework and the interface library.
- **TypeScript** in strict mode — for catching mistakes early; hiding errors is not
  allowed.
- **Tailwind CSS** with a trusted set of interface components — for a consistent
  look built from ready-made pieces.
- **Vitest** for the quick tests and **Playwright** for the browser tests.
- **Stand-in data** that steps in when the real data source isn't ready.

A couple of conventions run throughout: all of the app's data requests go through
one shared, tidy channel and follow the agreed data-service description exactly
(never a guess); and the app's colours, fonts, and spacing all come from one central
place.

---

## 19. Glossary

| Term | Meaning |
|---|---|
| **Epic** | One meaningful chunk of the app, built as a unit. A project is several epics. |
| **Branch** | A separate copy of the project where one epic is built, kept apart from the finished version until it's merged. |
| **Main** | The finished, trusted version of the project that epics are merged into. |
| **Merge** | Folding a finished epic's work into `main`. |
| **`project.md`** | The shared note of facts that stay the same across the whole project (users, sign-in, data source, rules, look and feel). |
| **`brief.md`** | The short requirements note for one epic. |
| **Story** | A single thing a user can see or do, small enough to build and test in one go. |
| **Acceptance criteria** | The testable statements in a story that say when it's done. |
| **Checklist** | The plain-language list of things you check by hand when you try an epic yourself. |
| **Gate (check)** | A pass-or-fail safety check. There are four: does it work, is it safe, is the code sound, do the tests pass. |
| **Notebook (`journal.md`)** | The plain-English record of the decisions Claude made during an epic; the important ones are read back to you at the end. |
| **Registry (`architecture.md`)** | A shared list of reusable code and project-wide conventions that future work reads. |
| **Please-double-check list** | Things Claude couldn't verify about the outside world, floated to the top of your hands-on check before an epic is merged. |
| **Stand-in data** | Realistic pretend data the app uses while the real data source isn't ready. |
| **Agent (helper)** | A specialised assistant Claude launches for one job; helpers report back to the main Claude and never talk to you directly. |
| **Orchestrator** | The main Claude that runs the commands, coordinates the helpers, and handles all approvals. |
| **Hook** | A small command Claude Code runs automatically at certain moments. |
| **State file (`state.json`)** | The small file that records an epic's current stage and progress. |
| **Halt** | A point where Claude stops and asks you about a genuinely risky decision. |

---

*This guide describes the current epic-based workflow, where the app is built one
epic at a time — each on its own branch, planned and built test-first, checked, and
merged into the finished project once you're happy with it.*
