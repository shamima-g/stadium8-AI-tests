# Epic Brief: Sign-in and App Shell

*Inherits roles, auth, data source, compliance, and styling from project.md.*

---

## Goal

Everyone signs in with email and password, lands on the right page for their role, sees only the menu items their role allows, and gets a clear on-page message if they open a page they can't use.

This epic delivers the shared foundation the rest of the app builds on: the sign-in screen and its failure handling, the session rules (idle and absolute timeouts, lockout after repeated failures), the role-scoped app shell and top-level navigation, the in-page permission-denied banner, and the in-memory data layer (the Enquiry and User records with seeded sample data) that later epics read from and write to (`requirements.md` §5 Flow: Authentication, G-06, F-01, UF-09, UF-10, BR-05, §6.6.1, §7, PI-01, PI-02).

---

## Data Model

Source: `documentation/requirements.md` §2 and §7. No OpenAPI spec or design was provided.

### Enquiry

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| Id | integer | yes | system-assigned | Internal identifier |
| Name | string | yes | non-empty; max 120 chars | Primary identifier in the inbox |
| Email | string | yes | RFC-5322 email format | Reply-to |
| Address | string | no | max 255 chars | Optional |
| Category | enum | yes | exactly one of `Feedback`, `Question`, `General Enquiry` | |
| Comment | string | yes | non-empty; min 10, max 2000 chars | Enquiry body |
| Status | enum | yes | exactly one of `New`, `In Progress`, `Resolved` | `Resolved` is terminal |
| ReplyNote | string | no | required when Status is `Resolved`; max 1000 chars | Read-only after resolution |
| SubmittedAt | datetime | yes | system-assigned (ISO-8601) | |
| SubmittedByEmail | string | yes | mirrors the submitting Visitor | Scopes "My messages" |
| HandledBy | string | no | mirrors the acting back-office user | Set when status first changes |

### User

| Field | Type | Required | Validation | Notes |
|---|---|---|---|---|
| Id | integer | yes | system-assigned | Internal identifier |
| Email | string | yes | RFC-5322 email format | Sign-in identifier |
| FirstName | string | yes | non-empty; max 64 chars | |
| LastName | string | yes | non-empty; max 64 chars | |
| Password | string | yes | min complexity per policy | Write-only; never displayed |
| Role | enum | yes | exactly one of `Visitor`, `Support Agent`, `Admin` | Drives landing page, navigation and access |

### Seeded data

- **Users:** `visitor@example.com` / `Test123` (Visitor), `agent@example.com` / `Test123` (Support Agent), `admin@example.com` / `Test123` (Admin) (project.md §Authentication).
- **Enquiries:** a small set that together covers every Category (Feedback, Question, General Enquiry) and every Status (New, In Progress, Resolved). Resolved enquiries carry a Reply Note. At least one enquiry is submitted by the seeded Visitor so "My messages" has content.
- **Persistence:** changes last for the browser session and are lost on reload (PI-02).

---

## Functional Requirements

- **R1:** A user can sign in with an email and password; on success a Visitor lands on the Contact form and a Support Agent or Admin lands on the Inbox.
- **R2:** When sign-in fails, an inline error on the sign-in screen tells the user whether the email/password was wrong or whether there was a connection problem.
- **R3:** A signed-in session ends after 30 minutes of inactivity or 12 hours in total, whichever comes first, and the user is returned to the sign-in screen.
- **R4:** After 5 failed sign-in attempts for an account, that account is locked for 15 minutes and the sign-in screen says it is locked and for how long.
- **R5:** The top-level navigation shows a Visitor only "Contact" and "My messages", and shows a Support Agent or Admin only "Inbox"; menu items a role can't use are hidden, not shown disabled.
- **R6:** A signed-in user who opens a page their role can't use through a direct link sees an in-page permission-denied banner that names the missing permission and gives a link back to their own landing page, never a generic 403 page.
- **R7:** The app holds Enquiry records with the fields listed in the Data Model, where Status is exactly New / In Progress / Resolved and Category is exactly Feedback / Question / General Enquiry.
- **R8:** The app starts with seeded sample enquiries covering every category and every status, plus the three seeded users; changes made during a session persist until the page is reloaded.
- **R9:** Every screen this epic delivers meets WCAG 2.2 AA, can be operated with the keyboard alone, and never uses status colour without an accompanying icon or text label.

---

## Business Rules

- **BR1:** A user who is not signed in and opens any app page is sent to the sign-in screen.
- **BR2:** After sign-in, routing is decided only by the user's role: Visitor → Contact form; Support Agent or Admin → Inbox.
- **BR3:** Actions and menu items a role is denied are hidden, never rendered disabled (`requirements.md` §6.5 notes).
- **BR4:** Reaching a role-restricted page by direct link shows the permission-denied banner in the page, not a 403 page (`requirements.md` BR-05).
- **BR5:** A locked account cannot sign in, even with the correct password, until the 15-minute lockout has passed.
- **BR6:** Session timeouts and lockout are simulated in the browser (PI-01); there is no server-side enforcement.

---

## Key Workflows

### Sign in

1. An unauthenticated user opens the app and is shown the sign-in screen.
2. They enter their email and password and submit.
3. On success they land on their role's page: Visitor → Contact form; Support Agent / Admin → Inbox.
4. On failure an inline error explains whether the credentials were wrong or the connection failed; the entered email is kept.
5. On the 5th consecutive failure the account is locked for 15 minutes and the screen says so.

### Navigate the app shell

1. A signed-in user sees a top navigation with only the items their role allows (Visitor: Contact, My messages; Support Agent / Admin: Inbox).
2. They can sign out from the shell and return to the sign-in screen.

### Open a page you can't use

1. A signed-in user follows a direct link to a page outside their role (for example, a Visitor opens the Inbox).
2. The page shows a permission-denied banner naming the missing permission.
3. The banner offers a link back to their own landing page.

### Session expiry

1. A signed-in user is inactive for 30 minutes, or has been signed in for 12 hours.
2. The session ends and they are returned to the sign-in screen with a message that their session expired.

---

## Feature NFRs

- **NFR1:** The sign-in form is fully keyboard- and screen-reader-operable: labelled fields, errors announced to assistive technology and linked to their fields, focus moved to the error summary on a failed submit.
- **NFR2:** The permission-denied banner is announced to assistive technology when the page loads and its "back" link is reachable by keyboard.
- **NFR3:** Password field input is masked and the password is never shown or logged.

---

## Out of Scope

- The Contact form, confirmation page, My messages list, Inbox table, enquiry detail, status changes and delete. Later epics deliver these; this epic only routes to their pages and guards access to them.
- The reviewer role switcher (`requirements.md` PI-05), dropped by user decision. Reviewers sign in as each seeded user instead.
- Real authentication, password reset, registration, and account management.

---

## Notes & Caveats

- **Landing pages before their epics exist:** the Contact form, My messages and Inbox are built in later epics. This epic needs a minimal destination for each so that sign-in routing, navigation and the permission-denied banner can be tested. Later epics replace these placeholders.
- **"Connection problem" under simulated auth:** auth is simulated in the browser (PI-01), so there is no real network failure. The way BUILD triggers and tests the connection-problem error (for example, a stub failure mode) still needs deciding.
- **Session and lockout values are inferred:** `requirements.md` §6.6.1 marks the 30-minute idle timeout, 12-hour absolute timeout and 5-failure / 15-minute lockout as inferred defaults (project.md NFR-base-6). Confirm before BUILD if they matter.
- **Server-side auth vs. simulated auth:** project.md records the method as `server-side` (BFF), but every auth endpoint is N/A because auth is simulated client-side. Confirm the stub follows the server-side auth pattern's shape (for example, session handling behind a route) rather than a purely client-side flag.
- **Wording of the "missing permission":** the banner must name the missing permission (UF-09), but project.md's permissions matrix only has "View main dashboard" so far. Permission names such as "View inbox" or "Submit an enquiry" will be added to project.md during BUILD, with your approval.
- **Seed data is defined here, used later:** the seeded enquiries are only displayed in later epics. This epic delivers the data layer and seed. Its tests can check the seed's shape (every category and status present) but not how it is shown on screen.
