# Epic Plan — Contact & Enquiry Management

Every epic in this project, what it delivers, and what it builds on. Live status
(not started / in flight / done) is shown by `/status` and the dashboard.

> Plan only — edited during planning on `main`, never on an epic branch.

## Epics

| # | Epic | Delivers | Builds on |
|---|---|---|---|
| 1 | Sign-in and App Shell (`sign-in-and-app-shell`) | Everyone signs in with email and password, lands on the right page for their role, sees only the menu items their role allows, and gets a clear on-page message if they open a page they can't use. | — |
| 2 | Contact Form and My Messages (`visitor-enquiries`) | A Visitor sends an enquiry, sees a 'Message sent!' confirmation of what they sent, and can look back over their own messages (and only theirs). | Sign-in and App Shell (`sign-in-and-app-shell`) |
| 3 | Inbox (`inbox`) | Support Agents and Admins see every enquiry in one sortable, paged table and can narrow it down by category, status or text. | Sign-in and App Shell (`sign-in-and-app-shell`) |
| 4 | Working an Enquiry (`enquiry-handling`) | Support Agents and Admins open an enquiry, mark it In Progress, and resolve it with a Reply Note; Admins can also delete spam after confirming. | Inbox (`inbox`) |

## Coverage

Everything in the spec is assigned to an epic, except one requirement dropped by your decision:

| What you asked for | Epic |
|---|---|
| Sign in with email and password, landing on your role's page (R1) | Sign-in and App Shell (`sign-in-and-app-shell`) |
| Sign-in failure explains what went wrong (R2) | Sign-in and App Shell (`sign-in-and-app-shell`) |
| Session time limits and lockout after repeated failed sign-ins (R3) | Sign-in and App Shell (`sign-in-and-app-shell`) |
| Menu shows only what your role can use (R4) | Sign-in and App Shell (`sign-in-and-app-shell`) |
| Opening a page you can't use shows a 'no permission' message on the page (R5) | Sign-in and App Shell (`sign-in-and-app-shell`) |
| Role switcher for reviewers (R6) | Dropped — reviewers sign in as each seeded user instead, so a Visitor can never switch to Admin and see other people's details |
| Enquiry record, categories and statuses, with seeded sample enquiries and users (R7) | Sign-in and App Shell (`sign-in-and-app-shell`) |
| Accessibility to WCAG 2.2 AA across the app (R8) | Sign-in and App Shell (`sign-in-and-app-shell`) |
| Send an enquiry from the Contact form (R9) | Contact Form and My Messages (`visitor-enquiries`) |
| Contact form layout (R10) | Contact Form and My Messages (`visitor-enquiries`) |
| Contact form checks email and comment before sending (R11) | Contact Form and My Messages (`visitor-enquiries`) |
| Form errors appear when you leave a field, not while typing (R12) | Contact Form and My Messages (`visitor-enquiries`) |
| 'Message sent!' confirmation page echoing what you sent (R13) | Contact Form and My Messages (`visitor-enquiries`) |
| Sending an enquiry feels instant (R14) | Contact Form and My Messages (`visitor-enquiries`) |
| 'My messages' list of your own enquiries (R15) | Contact Form and My Messages (`visitor-enquiries`) |
| Visitors only ever see their own enquiries (R16) | Contact Form and My Messages (`visitor-enquiries`) |
| Empty 'My messages' state with a link to the Contact form (R17) | Contact Form and My Messages (`visitor-enquiries`) |
| Inbox of all enquiries, sortable and paged (R18) | Inbox (`inbox`) |
| Colour-coded status badges with a text or icon label (R19) | Inbox (`inbox`) |
| Filter the Inbox by category, status or text (R20) | Inbox (`inbox`) |
| Inbox 'No enquiries yet' and 'no results' states (R21) | Inbox (`inbox`) |
| Inbox loads quickly (R22) | Inbox (`inbox`) |
| Enquirer contact details visible only to Support Agents and Admins (R23) | Inbox (`inbox`) |
| Enquiry detail page (R24) | Working an Enquiry (`enquiry-handling`) |
| Mark an enquiry In Progress (R25) | Working an Enquiry (`enquiry-handling`) |
| Resolve an enquiry with a required Reply Note (R26) | Working an Enquiry (`enquiry-handling`) |
| Resolved enquiries can't be changed and show their Reply Note (R27) | Working an Enquiry (`enquiry-handling`) |
| Admins can delete an enquiry after confirming (R28) | Working an Enquiry (`enquiry-handling`) |
| Icon-only buttons have hover labels (R29) | Working an Enquiry (`enquiry-handling`) |

_29 requirements: 28 assigned, 1 dropped by your decision._
