# Epic Brief: Working an Enquiry

*Inherits roles, auth, data source, compliance, and styling from project.md.*

| Field | Value |
|---|---|
| Epic slug | `enquiry-handling` |
| Depends on | `inbox` (the Inbox table and row-click navigation this epic opens from) |
| Source | `documentation/requirements.md` (no design provided) |

---

## Goal

Support Agents and Admins open an enquiry, mark it In Progress, and resolve it with a Reply Note; Admins can also delete spam after confirming.

This epic delivers the Enquiry detail page reached from an Inbox row, the status lifecycle actions on it (`New` → `In Progress` → `Resolved`), the Resolve modal with its mandatory Reply Note, the read-only view of a Resolved enquiry, and the Admin-only Delete with its confirmation gate (on both the Inbox row and the detail). It serves goals G-03 (triage and drive each enquiry to resolution) and G-05 (keep the inbox clean) from `requirements.md` §4.1.

---

## Data Model

This epic modifies the existing **Enquiry** entity (introduced by `sign-in-and-app-shell`, `requirements.md` §7). No new entities.

| Field | Type | Role in this epic |
|---|---|---|
| Id | integer | Identifies the enquiry in the detail route and the delete action |
| Name | string (max 120) | Shown on detail; named in the Delete confirmation modal |
| Email | string (RFC-5322) | Shown on detail |
| Address | string (optional, max 255) | Shown on detail |
| Category | enum `Feedback` / `Question` / `General Enquiry` | Shown on detail |
| Comment | string (10-2000) | Shown on detail |
| Status | enum `New` / `In Progress` / `Resolved` | Shown on detail as a status badge; **updated** by Mark In Progress and Resolve; `Resolved` is terminal |
| ReplyNote | string (max 1000) | **Written** by the Resolve modal; required when Status is `Resolved`; read-only afterwards |
| SubmittedAt | datetime (ISO-8601) | Shown on detail as the Submitted date |
| HandledBy | string | **Written** with the acting back-office user when status first changes; audit |

**Operations introduced (mock layer, session-only per PI-02):**

- Get one enquiry by Id
- Change status `New` → `In Progress` (sets HandledBy if not yet set)
- Resolve with Reply Note (non-terminal → `Resolved`; sets HandledBy if not yet set)
- Delete enquiry by Id (Admin only)

---

## Functional Requirements

- **R1:** Opening an Inbox row shows the Enquiry detail with the enquiry's Name, Email, Address, Category, Comment, Status and Submitted date.
- **R2:** A Support Agent or Admin can move a non-terminal Enquiry from `New` to `In Progress`. The status updates, a toast confirms the change, and HandledBy is recorded when the status first changes.
- **R3:** Resolving an enquiry opens a modal with a required multi-line Reply Note (max 1000 characters, with a character counter). The submit control stays disabled until a note is entered. On submit the status becomes `Resolved` and a toast confirms.
- **R4:** When an Enquiry is `Resolved`, the status-change actions are hidden and the Reply Note is shown read-only on the detail.
- **R5:** An Admin can delete an Enquiry from an Inbox row or from the detail. A confirmation modal names the Enquiry, uses a destructive-styled primary button and puts default focus on Cancel. Confirming removes the Enquiry. Support Agents never see Delete.
- **R6:** Icon-only row actions show a tooltip on hover and on keyboard focus, plus an accessible label that matches the tooltip. Primary destructive actions are never icon-only.

---

## Business Rules

- **BR1:** Status-change actions (Mark In Progress, Resolve) are available only while the Enquiry is non-terminal (`New` or `In Progress`). When the Enquiry is `Resolved`, they are hidden, not disabled (`requirements.md` BR-01, §6.5 notes).
- **BR2:** Moving an Enquiry to `Resolved` requires a non-empty Reply Note of at most 1000 characters. The Resolve modal's submit control is disabled until a note is entered (`requirements.md` BR-02, §6.3).
- **BR3:** Delete is preceded by a confirmation modal that names the Enquiry, with a destructive-styled primary button and default focus on Cancel. Nothing is removed until the user confirms (`requirements.md` BR-03).
- **BR4:** Only Admins see the Delete action. It is hidden for Support Agents, not shown disabled (`requirements.md` §6.5, F-09).
- **BR5:** HandledBy is set to the acting back-office user the first time the Enquiry's status changes and is not overwritten by later changes (`requirements.md` §7).
- **BR6:** Status moves forward only (`New` → `In Progress` → `Resolved`). `Resolved` is terminal and its Reply Note cannot be edited (`requirements.md` §2.3).
- **BR7:** A Visitor cannot reach the Enquiry detail. Opening it through a direct link shows the in-page permission-denied banner from `sign-in-and-app-shell` (`requirements.md` BR-05 / UF-09).

---

## Key Workflows

### W1: Open an enquiry

1. A Support Agent or Admin is on the Inbox.
2. They click (or activate with the keyboard) an enquiry row.
3. The Enquiry detail opens, showing Name, Email, Address, Category, Comment, a Status badge and the Submitted date.
4. Actions on the detail reflect the role and status: Mark In Progress (only when `New`), Resolve (when `New` or `In Progress`), and Delete (Admin only).

### W2: Mark In Progress

1. On a `New` enquiry's detail, the user selects Mark In Progress.
2. The status badge changes to `In Progress`, and a toast confirms the change.
3. HandledBy is recorded if this is the first status change.
4. Mark In Progress is no longer offered. Resolve remains.

### W3: Resolve with a Reply Note

1. On a non-terminal enquiry's detail, the user selects Resolve.
2. A modal opens with a multi-line Reply Note field, a character counter showing the 1000-character limit, and a disabled submit button.
3. The user types a note, and the submit button becomes enabled.
4. The user submits. The modal closes, the status badge changes to `Resolved`, and a toast confirms.
5. The status-change actions disappear, and the Reply Note is shown read-only on the detail.
6. Cancelling the modal leaves the enquiry unchanged.

### W4: Delete (Admin only)

1. An Admin selects Delete on an Inbox row or on the enquiry detail.
2. A confirmation modal opens, naming the enquiry. Focus starts on Cancel, and the primary button uses destructive styling.
3. Cancel (or Escape) closes the modal, and nothing changes.
4. Confirming removes the enquiry. It no longer appears in the Inbox.

---

## Feature NFRs

- **NFR1:** Every action in this epic can be done with the keyboard alone: opening a row, the status actions, the Resolve modal (focus moves into the modal and returns to the trigger when it closes), and the Delete confirmation (focus starts on Cancel). This applies NFR-base-1 to this epic.
- **NFR2:** The Reply Note character counter is announced to assistive technology, and the reason the submit button is disabled is clear without relying on colour.
- **NFR3:** The status badge on the detail pairs colour with a text or icon label (UF-05, shared with the `inbox` epic's badge component).

---

## Out of Scope

- Reassigning enquiries. `requirements.md` §1 mentions it as an Admin duty, but no functional requirement, flow or RBAC entry defines it.
- Editing an enquiry's contact details, category or comment. Back-office changes are limited to Status and Reply Note (§6.5 notes).
- Moving a status backwards, or reopening a Resolved enquiry.
- Sending a real email or notification when an enquiry is resolved. Confirmation appears in the UI only (PI-04).
- The Inbox table itself, plus sorting, filtering and pagination (`inbox` epic).

---

## Notes & Caveats

- **Resolve directly from `New`:** the Change Status flow ("Move New → In Progress, or → Resolved") and F-08 ("resolve a non-terminal Enquiry") both allow Resolve from `New` as well as from `In Progress`. This brief offers Resolve in both states. Please confirm that you don't require `In Progress` first.
- **[INFERRED] What happens after deleting from the detail:** the spec only says "Enquiry is removed." This brief assumes the user is returned to the Inbox with a toast confirming the deletion. Deleting from an Inbox row keeps the user on the Inbox.
- **[INFERRED] A whitespace-only Reply Note counts as empty:** "non-empty" is read as non-blank after trimming, so a note containing only spaces keeps submit disabled.
- **[INFERRED] Enquiry not found:** the spec doesn't cover opening the detail for an enquiry that no longer exists (for example, a link to an enquiry deleted in this session). This brief assumes a "not found" message on the page with a link back to the Inbox.
- **HandledBy display:** §7 says to record HandledBy for audit, but no requirement says where to show it. It is stored but not shown on the detail unless you want it shown.
- **Delete row action is shared with the `inbox` epic:** UF-04 places the Admin-only Delete action in the Inbox table, but the delete behaviour belongs to this epic. This epic adds the row action to the existing table. The row Delete can be icon-only (with tooltip and accessible label, R6), but the confirmation modal's destructive button must have a text label.
- **Session-only changes:** status changes, Reply Notes and deletions persist only for the session and are lost on reload (PI-02). Tests should not expect them to survive a page reload.
