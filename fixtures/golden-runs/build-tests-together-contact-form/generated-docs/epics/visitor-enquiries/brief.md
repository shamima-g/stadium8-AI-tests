# Contact Form and My Messages

*Inherits roles, auth, data source, compliance, and styling from project.md.*

| Field | Value |
|---|---|
| Epic slug | `visitor-enquiries` |
| Depends on | `sign-in-and-app-shell` (sign-in, role-scoped navigation, permission-denied banner, Enquiry fixtures) |
| Source | `documentation/requirements.md` (F-02, F-03, F-04, BR-04, BR-06, UF-01, UF-02, UF-03, UF-06, §6.6.2, §7) |

---

## Goal

A Visitor sends an enquiry, sees a 'Message sent!' confirmation of what they sent, and can look back over their own messages (and only theirs).

This covers the Visitor's two surfaces from the role-scoped navigation: **Contact** (the enquiry form and its confirmation page) and **My messages** (a read-only list of the Visitor's own enquiries). Sign-in, navigation, the permission-denied banner and the seeded fixtures come from the `sign-in-and-app-shell` epic; the back-office Inbox and enquiry handling come from later epics.

---

## Data Model

No OpenAPI spec exists. The entity comes from `requirements.md` §7. The Enquiry record and its fixtures are set up by `sign-in-and-app-shell`. This epic **creates** Enquiry records and **reads** the signed-in Visitor's own records.

### Enquiry (fields this epic writes or reads)

| Field | Type | Required | Validation | Used here |
|---|---|---|---|---|
| Id | integer | yes | system-assigned | Assigned on create |
| Name | string | yes | non-empty; max 120 chars | Form input; echoed on the confirmation page |
| Email | string | yes | valid email format (RFC-5322) | Form input; echoed on the confirmation page |
| Address | string | no | max 255 chars | Optional form input |
| Category | enum | yes | one of `Feedback`, `Question`, `General Enquiry` | Form select; echoed on the confirmation page; a column in My messages |
| Comment | string | yes | non-empty; min 10, max 2000 chars | Form input (multi-line); echoed on the confirmation page |
| Status | enum | yes | one of `New`, `In Progress`, `Resolved` | Set to `New` on create; shown in My messages |
| SubmittedAt | datetime | yes | system-assigned (ISO-8601) | Set on create; shown as the submitted date in My messages |
| SubmittedByEmail | string | yes | the signed-in Visitor's account email | Set on create; scopes My messages |

Fields not used by this epic: `ReplyNote` and `HandledBy` (handled in `enquiry-handling`).

---

## Functional Requirements

- **R1:** A Visitor may submit an Enquiry with Name, Email, Category and Comment (required) and Address (optional); the Enquiry is created with Status `New`. (F-02)
- **R2:** The Contact form presents Name, Email, Address (optional), Category (select) and Comment (multi-line), with a leading asterisk on required fields and a single legend line explaining it, and is fully keyboard- and screen-reader-operable. (UF-01)
- **R3:** The Contact form requires a valid email format; a non-empty Comment of 10 to 2000 characters; a Name of at most 120 characters; and an Address of at most 255 characters. Invalid input shows inline errors and blocks submission. (BR-06 / §7)
- **R4:** Form errors appear when the user leaves a field (single-field rules) or on submit (cross-field rules), never while typing. On success the form resets and a success toast appears top-right and dismisses itself after 4 to 8 seconds. (UF-02)
- **R5:** On a successful submit, the Visitor is taken to a confirmation page headed "Message sent!" that shows the submitted Name, Email, Category and Comment read-only, the form is cleared, and a control lets the Visitor send another enquiry. (F-03 / UF-03)
- **R6:** Submitting an enquiry reaches the confirmation page within 1 second. (§6.6.2)
- **R7:** A Visitor may view a read-only "My messages" list of the Enquiries they submitted, showing category, status and submitted date for each. (F-04)
- **R8:** A Visitor's "My messages" list shows only Enquiries they submitted; other people's names, emails and addresses are never shown to a Visitor. (BR-04 / NFR-base-7, Visitor side)
- **R9:** When a Visitor has no submissions, "My messages" shows "You haven't sent any messages yet" with a link to the Contact form. (UF-06, Visitor)

---

## Business Rules

- **BR1:** A new Enquiry always starts in Status `New`. (F-02)
- **BR2:** Submission is blocked while any field fails validation: Email format invalid; Comment empty, under 10 or over 2000 characters; Name empty or over 120 characters; Address over 255 characters; Category not chosen. (BR-06 / §7)
- **BR3:** Validation runs on blur and on submit, never on keystroke. (UF-02)
- **BR4:** "My messages" lists only Enquiries whose `SubmittedByEmail` matches the signed-in Visitor. (BR-04)
- **BR5:** "My messages" is read-only: a Visitor cannot edit, change status of, or delete an Enquiry. Those actions are hidden, not disabled. (§6.5)
- **BR6:** Only Visitors can reach the Contact form and My messages. A Support Agent or Admin opening either through a direct link sees the in-page permission-denied banner from `sign-in-and-app-shell`. (§5 Submit Enquiry / My Submissions role notes; §6.5; BR-05)
- **BR7:** Enquiries submitted in this session appear in My messages (and in the back-office Inbox) for the rest of the session but do not survive a page reload. (PI-02)

---

## Key Workflows

### Submit an enquiry

1. The Visitor signs in and lands on the Contact form (or opens Contact from the navigation).
2. The Visitor enters Name, Email, optional Address, chooses a Category and enters a Comment.
3. Leaving a field with invalid input shows an inline error for that field.
4. The Visitor submits. If any field is invalid, inline errors show and nothing is sent.
5. If all fields are valid, an Enquiry is created in `New`, the form is cleared, a success toast appears, and the Visitor is taken to the "Message sent!" confirmation page showing Name, Email, Category and Comment.
6. The Visitor can choose "send another" to return to an empty Contact form.

### Review my messages

1. The Visitor opens "My messages" from the navigation.
2. A read-only list of their own enquiries shows category, status and submitted date.
3. If they have none, the page shows "You haven't sent any messages yet" with a link to the Contact form.

---

## Feature NFRs

- **NFR1:** Form submit to confirmation page in 1 second or less. (§6.6.2)
- **NFR2:** The Contact form is fully keyboard- and screen-reader-operable: every field has a programmatic label, required fields are announced as required, and inline errors are linked to their fields and announced. (UF-01 / §6.6.3; WCAG 2.2 AA per NFR-base-1)
- **NFR3:** The status shown in My messages pairs colour with a text or icon label, never colour alone. (UF-05 / NFR-base-1)

---

## Out of Scope

- Signing in, role-scoped navigation, the permission-denied banner and the seeded fixtures (`sign-in-and-app-shell`).
- The back-office Inbox, filtering and status badges as an Inbox feature (`inbox`).
- Viewing an enquiry's detail, changing status, Reply Notes and deleting (`enquiry-handling`).
- Editing or withdrawing an enquiry after it is sent. The requirements describe My messages as read-only only.
- Real email delivery or notifications on submit. Any such confirmation is a UI message only (PI-04).
- Server-side validation; validation is visual only (PI-03).
- The reviewer role switcher (R6 in the epic plan), dropped at the user's decision.

---

## Notes & Caveats

- **Toast and confirmation page together.** UF-02 asks for a success toast and a form reset on success, while F-03 / UF-03 ask for a move to a "Message sent!" confirmation page. Both are carried as written: the toast shows over the confirmation page. Confirm during BUILD that both are wanted.
- **Which email scopes My messages.** The form has its own Email field, but `requirements.md` §7 scopes My submissions by `SubmittedByEmail`, the signed-in Visitor's account. This brief assumes My messages matches on the **account email**, not the email typed into the form, so an enquiry sent with a different contact email still appears for the sender. [INFERRED] from the §7 field notes.
- **Email prefill not specified.** The requirements do not say whether Name or Email are prefilled from the signed-in account. This brief assumes empty fields. [INFERRED]
- **Address is not echoed.** UF-03 lists Name, Email, Category and Comment for the confirmation page and leaves out Address. This brief follows UF-03 exactly.
- **No cross-field rules exist on this form.** UF-02 mentions cross-field rules on submit, but none of the Contact form fields depend on each other. On submit, every field is re-checked and all errors are shown together.
- **My messages sort order not specified.** This brief assumes newest first by submitted date. [INFERRED]
- **Fixtures needed for the empty state.** To show both a populated and an empty My messages list, the seeded data from `sign-in-and-app-shell` must give `visitor@example.com` some enquiries and also allow the empty state to be reached. Today there is only one seeded Visitor, so the empty-state test needs a Visitor with no enquiries (for example, a test fixture override). Settle this during BUILD.
