# Test Inputs — What to Type at Every Prompt

Use this alongside [TEST-GUIDE.md](TEST-GUIDE.md). It gives you the exact text to
type (or the option to pick) at every prompt during a test run, so two people
running the same test get the same result.

Everything here uses one make-believe project — the **Team Task Manager** —
unless a test tells you to switch in a *variant* answer (see the end).

> **Reminder of the workflow shape.** There are four phases:
> **INTAKE → PLAN → BUILD → COMPLETE.** INTAKE produces one document for you to
> approve (`project-brief.md`). PLAN proposes epics and stories for you to
> approve. BUILD builds each story automatically and only stops to ask you
> something when it hits a decision it isn't allowed to make on its own.

---

## The make-believe project: Team Task Manager

> A task-management tool for small teams. Team members can see the tasks assigned
> to them and mark them complete. Admins can create tasks, assign them to anyone,
> change due dates, and delete tasks. Each task has a title, description, due
> date, an assignee, and a status of *pending* or *complete*. There's no public
> access — everyone has to sign in.

We use this project because it exercises a lot of the workflow at once:

- **Two roles with different powers** (admin vs member) — tests permission handling.
- **A clear set of data** (title, description, due date, assignee, status) — produces a meaningful API.
- **No API spec to start with** — so the workflow has to design one.
- **A backend that isn't ready yet** — so the workflow sets up a mock layer to build against.
- **Styling preferences** — so the styling agent has something to work from.
- **No compliance rules** — keeps that path simple.
- **Two epics** — so we see the workflow move from one epic to the next.

---

## INTAKE — what to type, in order

You start INTAKE by typing `/start`. Claude installs anything missing, then asks
the questions below in roughly this order.

### 1. How do you want to start?

**Claude asks (buttons):** "How would you like to get started?"

**Pick:** **Let's build requirements together**

> The other two options are "I have a prototype repo to import" and "I have
> existing docs to share." We use the from-scratch path so the test doesn't
> depend on extra files.

### 2. The pitch (type this — it's a free-text box)

**Claude asks:** "What are you building? Give me the elevator pitch — who's it
for, what does it do, and what's the core problem it solves."

**Type this exactly:**

```
A task-management tool for small teams. Team members can view the tasks assigned to them and mark them complete. Admins can create tasks, assign them to any team member, change due dates, and delete tasks. Each task has a title, description, due date, an assignee, and a status of pending or complete. Everyone has to sign in — there's no public access.

Styling: clean and professional. Primary colour blue (#2563EB), white background, light grey (#F3F4F6) for table rows and sidebars. Sans-serif font, compact layout, light mode only.
```

> We fold the styling preferences into the pitch because INTAKE no longer asks a
> separate styling question — the styling agent reads them from the brief later.

### 3. Roles (buttons)

**Claude asks:** "Which roles template fits your app?"

**Pick:** **Other**, and type the two roles:

```
Two roles:
- Admin — can create tasks, assign them to members, change due dates, delete tasks, and see all tasks.
- Member — can only see tasks assigned to them, and mark their own tasks complete.
```

> If you'd rather pick a preset, "SaaS Standard" (Owner / Admin / Member /
> Viewer) is the closest, but typing the two roles keeps the brief matching this
> scenario exactly.

### 4. Authentication (buttons)

**Claude asks:** "How will users authenticate?"

**Pick:** **Frontend-only (next-auth)**

> Claude then shows a short trade-off note: API calls won't carry session
> context, so this protects the frontend routes only. Read it and continue.
> (For the BFF path instead, see **Variant A** at the end.)

### 5. Is the backend ready? (buttons)

**Claude asks:** "Is your backend API up and running?"

**Pick:** **No, still in development**

> Because there's no API spec in `documentation/` **and** the backend isn't
> running, the workflow records the data source as `api-in-development` and sets
> up a mock layer so you can build the frontend now. (Whether a spec already
> exists is detected by scanning `documentation/` — it isn't a question.)

### 6. Compliance (buttons, multi-select)

**Claude asks:** "Which of these compliance areas apply?" — with options for
payment data (PCI), personal data (GDPR/POPIA/CCPA), health data (HIPAA), and
multi-tenant SaaS (SOC 2).

**Pick:** **None apply.**

> Claude then double-checks: "Just to confirm — no payment card data, personal
> information, health records, or regulated data?" Confirm **yes, that's correct**.

### 7. Connectivity checks (usually skipped here)

For this scenario the backend isn't running, so Claude **won't** run the API
smoke test or offer the auth probe. If you're testing a running-backend variant
and Claude offers a probe, pick **Skip — verify manually** unless the test says
otherwise.

### 8. Gate 1 — approve the project brief (buttons)

Claude assembles `generated-docs/specs/project-brief.md`, shows you a summary,
and asks you to approve it.

**Before approving, open the file and check it captured:**
- Goal: the Team Task Manager described above.
- Roles: admin and member, with the right powers.
- Auth: frontend-only (next-auth).
- Data source: backend in development, mock layer enabled.
- Compliance: none.
- A handful of functional requirements (view, create, assign, edit due date,
  delete, mark complete) and a few business rules (admin-only create/delete,
  members see only their own tasks, confirm before delete).

**Pick:** **Approve all**

> The other options are "I have small changes," "Let me edit the file directly,"
> and "Start over." Use those only if the brief is genuinely wrong.

INTAKE ends here and Claude chains straight into PLAN.

---

## PLAN — what to approve

### Epic list (Gate 2a)

Claude proposes the epics. Approve if they're close to:

```
Epic 1: Task Browsing — view and filter the task list
Epic 2: Task Actions — create, edit, and delete tasks
```

**Pick:** **Approve all**

> Different names or a slightly different split are fine — approve as long as the
> scope matches the brief. If something's clearly missing, pick "Adjust the list"
> and describe it.

> **Single-epic shortcut:** if the workflow ever proposes only **one** epic, the
> epic gate and the story gate are combined into a single approval. You'll see the
> epic and its stories together — approve them in one step.

### Stories, one epic at a time (Gate 2b)

For each epic, Claude lists its stories and the manual tests you'll run when the
epic is done. Approve if they're close to:

**Epic 1 — Task Browsing**
```
Story 1: View the task list — a signed-in user sees a table of tasks relevant to their role (admin sees all; member sees only their own).
Story 2: Empty state — a member with no tasks sees "No tasks assigned to you yet" instead of an empty table.
```

**Epic 2 — Task Actions**
```
Story 1: Create a task — an admin fills in title and assignee (required), optionally a description and due date, and submits.
Story 2: Delete a task — an admin clicks Delete, confirms in a dialog, and the task is removed.
```

**Pick (for each epic):** **Approve epic**

> "Adjust the stories" lets you describe changes; "Skip this epic" defers it.

---

## BUILD — what you'll see, and the one place you answer

BUILD runs each story on its own, in this order, without stopping for you:

1. **Tests are written first** (they fail on purpose — there's no code yet).
2. **The code is written** to make those tests pass.
3. **The browser tests and a code review run together.**
4. **The story is committed and pushed.**

You only get asked something in two situations:

- **A halt.** If the work hits a decision the workflow isn't allowed to make on
  its own (a new dependency, an API-contract change, an auth change, etc.), it
  stops and asks you, showing you the options. Pick the sensible one for the test
  you're running, or describe a different path.
- **The manual check at the end of each epic.** When an epic finishes, Claude
  shows an Epic Completion Summary and a short checklist of things to try in the
  browser.

### Manual checks at each epic boundary

Start the dev server (`npm --prefix web run dev`) and open
`http://localhost:3000`.

**Epic 1 — Task Browsing**
1. Sign in as an admin → the task list shows **all** tasks, with columns for
   title, due date, assignee, and status.
2. Sign in as a member → you see **only** the tasks assigned to you.
3. Sign in as a member with no tasks → you see "No tasks assigned to you yet,"
   not an empty table.

**Epic 2 — Task Actions**
1. As an admin, a **Create Task** button is visible. Open it, fill in only the
   title, and submit → you get a validation error on the required assignee field.
2. Fill in title **and** assignee, submit → the new task appears without a page
   reload.
3. As a member, there's **no** Create button.
4. As an admin, click **Delete** on a row → a confirmation dialog appears. Cancel
   → the task stays. Delete again and confirm → the task disappears (no full
   reload).
5. As a member, there's **no** Delete button.

When everything checks out, pick the **pass** option on the manual-verification
question (labelled something like "All tests pass"). If something's wrong, pick
**Issues found** and describe it — the workflow will fix it and ask you again.

---

## COMPLETE — what to expect

After the last epic, the workflow marks the feature complete, generates three
telemetry reports (timing, tokens, and a final summary) under
`generated-docs/reports/`, and opens the final report in your browser. There's
nothing to approve — just confirm the reports were written and the completion
message appears.

---

## Variant answers — only when a test tells you to

Switch these in only when a specific test says so. Go back to the main answers
afterwards.

### Variant A — BFF authentication

At the authentication question (step 4), pick **Backend For Frontend (BFF)**
instead of frontend-only. Claude then asks for three URLs (free-text):

| Claude asks for… | Type |
|---|---|
| Login endpoint URL | `/api/auth/login` |
| Userinfo endpoint URL | `/api/auth/userinfo` |
| Logout endpoint URL | `/api/auth/logout` |

> Claude also shows a note that CI can't reach a real BFF, so the performance
> gate runs against mocks. That's expected.

### Variant B — No backend at all

At the backend-readiness question (step 5), pick **N/A — no backend API**. The
data source becomes `mock-only`, and no API spec or mock layer pointing at a real
backend is generated.

### Variant C — You already have an API spec

**Before** running `/start`, create this file at `documentation/task-api.yaml`:

```yaml
openapi: 3.0.3
info:
  title: Task Manager API
  version: 1.0.0
paths:
  /api/v2/tasks:
    get:
      summary: List tasks
      responses:
        '200':
          description: List of tasks
  /api/v2/tasks/{id}:
    delete:
      summary: Delete a task
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '204':
          description: Deleted
```

The workflow detects the spec while scanning `documentation/`, so it won't design
its own. Run the rest of INTAKE normally. After BUILD, confirm the generated API
calls use `/api/v2/tasks` — **not** `/api/tasks` or any other guessed path.

---

## Quick reference — which answers each test needs

| Test in TEST-GUIDE.md | Answers to use | Special variant? |
|---|---|---|
| Setup / `/start` | Main scenario | None |
| Onboarding routing (three paths) | Just the first routing question | None |
| INTAKE checklist questions | Steps 3–6 above | None |
| Authentication — frontend-only warning | Main scenario | None (main already uses frontend-only) |
| Authentication — BFF path | Variant A | Swap the auth answer |
| Two-step approval pattern | Main scenario through Gate 1 | None |
| Project brief (Gate 1) | Main scenario through Gate 1 | None |
| No backend → mock-only | Variant B | Swap the backend answer |
| Existing spec is honoured | Variant C | Add the YAML file first |
| PLAN — epic approval | Epic list above | None |
| PLAN — story approval | Stories above | None |
| BUILD — per-story loop | Main scenario | None |
| Manual check at epic boundary | Browser steps above | None |
| Quality gate failure (e.g. type error) | Main scenario, then inject an error | None |
| Exact API paths | Variant C | YAML uses `/api/v2/tasks` |
| Role declaration in stories | Main scenario | None |
| Everything else | Main scenario | None |
