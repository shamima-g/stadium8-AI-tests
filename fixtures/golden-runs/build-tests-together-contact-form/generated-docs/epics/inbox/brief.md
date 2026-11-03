# Epic Brief: Inbox

*Inherits roles, auth, data source, compliance, and styling from project.md.*

| Field | Value |
|---|---|
| Epic slug | `inbox` |
| Epic name | Inbox |
| Depends on | `sign-in-and-app-shell` (sign-in, role-scoped navigation, permission-denied banner, Enquiry fixtures) |
| Sources | `documentation/requirements.md` §4 (G-03, G-04), §5 (Inbox, Search & Filter flows), §6.1 F-05 / F-06, §6.4 UF-04 / UF-05 / UF-06, §6.6.1, §6.6.2 |

---

## Goal

Support Agents and Admins see every enquiry in one sortable, paged table and can narrow it down by category, status or text.

The Inbox is the landing page for both back-office roles (project.md §Authentication) and is where they triage incoming enquiries (`requirements.md` G-03, G-04). This epic delivers the table, its status badges, sorting, paging, filtering and its empty and no-results states. Opening an enquiry's detail, changing its status, resolving it and deleting it belong to the next epic (`enquiry-handling`).

---

## Data Model

No new entities. This epic reads the **Enquiry** entity that `sign-in-and-app-shell` sets up as in-memory fixtures (`requirements.md` §7; no OpenAPI spec exists).

| Field | Type | Used by this epic |
|---|---|---|
| Id | integer | Row identity; the target of the row click |
| Name | string (max 120) | Table column; free-text search |
| Category | enum: `Feedback` / `Question` / `General Enquiry` | Table column; Category filter |
| Comment | string (10 to 2000) | Free-text search only (not a column) |
| Status | enum: `New` / `In Progress` / `Resolved` | Table column shown as a badge; Status filter |
| SubmittedAt | datetime (ISO-8601) | "Submitted" column; sortable |
| Email, Address | string | Not shown in the table. Personal data that back-office roles only can see (R6) |

Derived view state (not persisted): sort column and direction, page size, current page, active Category / Status filters, search text.

---

## Functional Requirements

- **R1:** A Support Agent or Admin sees all Enquiries in a table with Name, Category, Status and Submitted date columns.
- **R2:** Clicking a row in the Inbox opens that Enquiry's detail.
- **R3:** The table supports single-column sort: choosing a column sorts it ascending, choosing it again sorts it descending.
- **R4:** The table is paged with page sizes 5, 10, 20 and 50, defaulting to 20, and the pagination control is always shown, even when the results fit on one page.
- **R5:** Each Status is shown as a colour-coded badge: New is blue, In Progress is amber, Resolved is green, and the colour is always paired with an icon or text label.
- **R6:** A Support Agent or Admin can filter the Inbox by Category.
- **R7:** A Support Agent or Admin can filter the Inbox by Status.
- **R8:** A Support Agent or Admin can search the Inbox by free text, matching an Enquiry's Name or Comment.
- **R9:** Each active filter and search is shown as a chip, and a Clear-all action removes them all and restores the full list.
- **R10:** When there are no Enquiries at all, the Inbox shows a "No enquiries yet" empty state.
- **R11:** When filters or search return no Enquiries, the Inbox shows a no-results state that keeps the active filter chips and Clear-all, with no call-to-action to create an enquiry.
- **R12:** Enquirers' contact details (Name, Email, Address) are visible only to signed-in Support Agents and Admins, and a Visitor cannot reach the Inbox.

---

## Business Rules

- **BR1:** Only Support Agent and Admin can open the Inbox. A Visitor who opens it from a direct link sees the in-page permission-denied banner from `sign-in-and-app-shell`, never the table or a generic 403 page (`requirements.md` §6.5, BR-05).
- **BR2:** The Inbox lists every Enquiry, whoever submitted it. It is not scoped to the signed-in user (`requirements.md` F-05).
- **BR3:** Filters and search apply together: an Enquiry is shown only if it matches every active filter (`[INFERRED]` the sources list the filters but don't say how they combine; combining with AND is the usual inbox behaviour).
- **BR4:** Changing a filter, the search text or the page size returns the table to page 1 (`[INFERRED]` standard paging behaviour; not stated in the sources).
- **BR5:** Status colour is never the only signal: every badge carries the status name or an icon (`requirements.md` UF-05, NFR-base-1).
- **BR6:** Support Agents and Admins see the same table, filters and search (`requirements.md` Search & Filter flow). The Admin-only Delete row action is added by `enquiry-handling`, not here.

---

## Key Workflows

### Work the Inbox
1. A Support Agent or Admin signs in and lands on the Inbox.
2. The table shows all Enquiries, 20 per page, with a status badge on each row.
3. They choose a column header to sort it ascending, then again for descending.
4. They change the page size (5 / 10 / 20 / 50) or move between pages.
5. They click a row to open that Enquiry's detail.

### Find an enquiry
1. On the Inbox, they open the filter controls.
2. They choose a Category and/or a Status and/or type search text.
3. The table narrows to matching Enquiries, and each active filter shows as a chip.
4. They remove one chip, or choose Clear-all to restore the full list.
5. If nothing matches, the no-results state shows, keeping the chips and Clear-all.

### Visitor blocked from the Inbox
1. A signed-in Visitor opens the Inbox address directly.
2. The in-page permission-denied banner shows, with a path back to the Contact form; no enquiry data is shown.

---

## Feature NFRs

- **NFR1:** The Inbox page is interactive at p95 ≤ 2 s with 100 rows (`requirements.md` §6.6.2; marked inferred in the source).
- **NFR2:** Sorting, paging, filtering, search, chip removal and row opening all work from the keyboard, and sorted columns announce their sort direction to screen readers (NFR-base-1).
- **NFR3:** The table stays usable at the mobile breakpoint (≥360px) (NFR-base-3).

---

## Out of Scope

- The Enquiry detail page, moving an Enquiry to In Progress, resolving with a Reply Note, and deleting an Enquiry (including the Admin-only Delete row action and icon-only action tooltips) are delivered by `enquiry-handling`.
- Sign-in, role-scoped navigation, the permission-denied banner and the Enquiry fixtures are delivered by `sign-in-and-app-shell`.
- Sorting by more than one column at a time.
- A role switcher for reviewers (left out at the epic-plan approval; reviewers sign in as each seeded user).

---

## Notes & Caveats

- **Row click target:** R2 needs the detail page, which `enquiry-handling` builds. Until then the row click needs a destination, such as a route that `enquiry-handling` fills in. Confirm how this epic should treat it.
- **Default sort order:** the sources don't give an initial sort. `[INFERRED]` Submitted date, newest first, so new enquiries appear at the top.
- **Category and Status filters: one value or several?** The sources don't say whether a user can pick more than one Category or Status at once. `[INFERRED]` one value per filter.
- **Free-text search matching:** the sources don't specify. `[INFERRED]` case-insensitive "contains" matching on Name and Comment.
- **Mock data:** the table reads in-memory fixtures (PI-02). To check NFR1 with 100 rows, a larger fixture set than the few seeded enquiries is needed for the performance check.
