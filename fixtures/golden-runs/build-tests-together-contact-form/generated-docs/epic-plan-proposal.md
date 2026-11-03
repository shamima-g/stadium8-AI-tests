DECOMPOSITION PROPOSAL
---
requirementInventory:
  - id: R1
    name: Sign in with email and password, landing on your role's page
    text: "F-01 — The system supports email-and-password authentication and routes the user to a role-specific landing surface on success (Visitor → Contact form; Support Agent / Admin → Inbox)."
    epic: sign-in-and-app-shell
  - id: R2
    name: Sign-in failure explains what went wrong
    text: "Authentication flow step 4 — on failure, an inline error distinguishes wrong credentials from a connection problem."
    epic: sign-in-and-app-shell
  - id: R3
    name: Session time limits and lockout after repeated failed sign-ins
    text: "§6.6.1 / NFR-base-6 — 30-minute idle timeout, 12-hour absolute timeout, 5 failed attempts → 15-minute lockout (shown in the UI only; auth is simulated)."
    epic: sign-in-and-app-shell
  - id: R4
    name: Menu shows only what your role can use
    text: "UF-10 — Top-level navigation is role-scoped: Visitor sees Contact + My messages; Support Agent / Admin see Inbox. Denied actions are hidden, not disabled (§6.5 notes)."
    epic: sign-in-and-app-shell
  - id: R5
    name: Opening a page you can't use shows a 'no permission' message on the page
    text: "BR-05 / UF-09 — A user reaching a role-restricted surface via a direct link sees an in-page permission-denied banner naming the missing permission and a path back to their own surface — never a generic 403 page."
    epic: sign-in-and-app-shell
  - id: R6
    name: Role switcher for reviewers
    text: "PI-05 — Every screen accessible to more than one role shows a role switcher in the surrounding prototype chrome listing every role; roles that can't access the screen are shown disabled; switching immediately updates visible components and actions."
    epic: null
  - id: R7
    name: Enquiry record, categories and statuses, with seeded sample enquiries and users
    text: "§2 / §6.3 / §7 / PI-02 — Enquiry fields per §7; Status is exactly New / In Progress / Resolved; Category is exactly Feedback / Question / General Enquiry; in-memory seeded enquiries covering every category and status plus the three seeded users; changes last for the session but not past a reload."
    epic: sign-in-and-app-shell
  - id: R8
    name: Accessibility to WCAG 2.2 AA across the app
    text: "§6.6.3 / NFR-base-1 — WCAG 2.2 AA; keyboard-first operation across all primary flows; status colour always paired with an icon or text."
    epic: sign-in-and-app-shell
  - id: R9
    name: Send an enquiry from the Contact form
    text: "F-02 — A Visitor may submit an Enquiry with Name, Email, Category and Comment (required) and Address (optional); the Enquiry is created in New."
    epic: visitor-enquiries
  - id: R10
    name: Contact form layout
    text: "UF-01 — The Contact form presents Name, Email, Address (optional), Category (select) and Comment (multi-line), with a leading asterisk on required fields and a single legend line; fully keyboard- and screen-reader-operable."
    epic: visitor-enquiries
  - id: R11
    name: Contact form checks email and comment before sending
    text: "BR-06 / §7 — Email must be a valid format; Comment non-empty, min 10 / max 2000 characters; Name max 120; Address max 255. Invalid input shows inline errors and blocks submit."
    epic: visitor-enquiries
  - id: R12
    name: Form errors appear when you leave a field, not while typing
    text: "UF-02 — Validate on blur for single-field rules and on submit for cross-field rules, never on keystroke; on success the form resets and a success toast (auto-dismiss 4–8 s, top-right) confirms."
    epic: visitor-enquiries
  - id: R13
    name: 'Message sent!' confirmation page echoing what you sent
    text: "F-03 / UF-03 — On successful submit, route to a confirmation page with a 'Message sent!' heading echoing Name, Email, Category and Comment read-only, clear the form, and offer a control to send another."
    epic: visitor-enquiries
  - id: R14
    name: Sending an enquiry feels instant
    text: "§6.6.2 — Form submit → confirmation in ≤ 1 s."
    epic: visitor-enquiries
  - id: R15
    name: 'My messages' list of your own enquiries
    text: "F-04 — A Visitor may view a read-only list of the Enquiries they submitted, with category, status and submitted date."
    epic: visitor-enquiries
  - id: R16
    name: Visitors only ever see their own enquiries
    text: "BR-04 / NFR-base-7 (Visitor side) — A Visitor's submissions view shows only Enquiries they submitted; other people's names, emails and addresses are never shown to a Visitor."
    epic: visitor-enquiries
  - id: R17
    name: Empty 'My messages' state with a link to the Contact form
    text: "UF-06 (Visitor) — No submissions → 'You haven't sent any messages yet' with a link to the Contact form."
    epic: visitor-enquiries
  - id: R18
    name: Inbox of all enquiries, sortable and paged
    text: "F-05 / UF-04 — Support Agent / Admin see all Enquiries in a table with Name, Category, Status and Submitted date; row click opens the detail; single-column sort (ascending then descending); page sizes 5 / 10 / 20 / 50 (default 20); pagination control always shown."
    epic: inbox
  - id: R19
    name: Colour-coded status badges with a text or icon label
    text: "UF-05 — New (blue), In Progress (amber), Resolved (green); colour always paired with an icon or text label."
    epic: inbox
  - id: R20
    name: Filter the Inbox by category, status or text
    text: "F-06 / Search & Filter flow — Filter by Category, Status, and free-text search on Name and Comment; active filters show as chips with Clear-all."
    epic: inbox
  - id: R21
    name: Inbox 'No enquiries yet' and 'no results' states
    text: "UF-06 (Inbox) — Zero data → 'No enquiries yet'; zero results after filtering → no-results state with active filter chips and Clear-all, no creation call-to-action."
    epic: inbox
  - id: R22
    name: Inbox loads quickly
    text: "§6.6.2 — Inbox page interactive at p95 ≤ 2 s with 100 rows."
    epic: inbox
  - id: R23
    name: Enquirer contact details visible only to Support Agents and Admins
    text: "§6.6.1 / NFR-base-7 (back-office side) — Name, Email and Address are visible only to authenticated back-office roles; a Visitor cannot reach the Inbox."
    epic: inbox
  - id: R24
    name: Enquiry detail page
    text: "Inbox flow step 3 / §7 — Opening an inbox row shows the Enquiry detail: Name, Email, Address, Category, Comment, Status and Submitted date."
    epic: enquiry-handling
  - id: R25
    name: Mark an enquiry In Progress
    text: "F-07 — A Support Agent or Admin may move a non-terminal Enquiry from New to In Progress; status updates with a toast confirmation; HandledBy is recorded when status first changes."
    epic: enquiry-handling
  - id: R26
    name: Resolve an enquiry with a required Reply Note
    text: "F-08 / BR-02 / UF-07 / §6.3 — Resolving opens a modal with a mandatory multi-line Reply Note (max 1000 characters, with a character counter); the submit control stays disabled until a note is entered; status becomes Resolved with a toast."
    epic: enquiry-handling
  - id: R27
    name: Resolved enquiries can't be changed and show their Reply Note
    text: "BR-01 / F-10 — When an Enquiry is Resolved, status-change actions are hidden and the Reply Note is shown read-only on the detail."
    epic: enquiry-handling
  - id: R28
    name: Admins can delete an enquiry after confirming
    text: "F-09 / BR-03 / Delete flow — Admin-only Delete on an inbox row or the detail; a confirmation modal names the Enquiry, uses a destructive-styled primary button and puts default focus on Cancel; the Enquiry is then removed. Support Agents never see Delete."
    epic: enquiry-handling
  - id: R29
    name: Icon-only buttons have hover labels
    text: "UF-08 — Icon-only row actions carry tooltips on hover and focus plus a matching accessible label; primary destructive actions are never icon-only."
    epic: enquiry-handling

epics:
  - slug: sign-in-and-app-shell
    name: Sign-in and App Shell
    goal: Everyone signs in with email and password, lands on the right page for their role, sees only the menu items their role allows, and gets a clear on-page message if they open a page they can't use.
    requirementIds: [R1, R2, R3, R4, R5, R7, R8]
    dependsOn: []
  - slug: visitor-enquiries
    name: Contact Form and My Messages
    goal: A Visitor sends an enquiry, sees a 'Message sent!' confirmation of what they sent, and can look back over their own messages (and only theirs).
    requirementIds: [R9, R10, R11, R12, R13, R14, R15, R16, R17]
    dependsOn: [sign-in-and-app-shell]
  - slug: inbox
    name: Inbox
    goal: Support Agents and Admins see every enquiry in one sortable, paged table and can narrow it down by category, status or text.
    requirementIds: [R18, R19, R20, R21, R22, R23]
    dependsOn: [sign-in-and-app-shell]
  - slug: enquiry-handling
    name: Working an Enquiry
    goal: Support Agents and Admins open an enquiry, mark it In Progress, and resolve it with a Reply Note; Admins can also delete spam after confirming.
    requirementIds: [R24, R25, R26, R27, R28, R29]
    dependsOn: [inbox]

coverage:
  total: 29
  assigned: 28
  unassigned: []
  droppedByUserDecision: [R6]
  droppedByUserDecisionNotes:
    - "R6 — Role switcher for reviewers (a switcher on every shared screen to flip between Visitor, Support Agent and Admin): left out at the user's decision, because it would let a Visitor switch to Admin and see other people's personal details; reviewers sign in as each seeded user (visitor@, agent@ and admin@example.com) instead (recorded at the epic-plan approval, blocker resolution)."

blockers: []
