STORIES PROPOSAL
---
epic: Sign-in and App Shell
storyCount: 4
epicIntroducesSharedSurface: true

stories:
  - index: 1
    title: Sign in, land on your page, and sign out
    slug: story-1-sign-in-and-sign-out
    plainSummary: You open the app, sign in with your email and password, and land on your role's page (a Visitor on the Contact form, a Support Agent or Admin on the Inbox). If sign-in fails you see a clear message on the sign-in screen, and you can sign out from any page.
    summary: Replaces the template's public welcome page with a sign-in screen at /login and an (authenticated) route group whose layout guards every app page through a server-side session check (BFF shape per the server-side auth pattern, backed by a simulated in-memory user store holding the three seeded users). Successful sign-in routes by role only (Visitor to /contact, Support Agent/Admin to /inbox); minimal placeholder pages for /contact, /my-messages and /inbox are created for later epics to replace. Failure shows an inline, accessible error (wrong credentials vs connection problem) with the email kept and focus moved to the error summary; sign-out clears the session and returns to sign-in, including on browser Back.
    requirementIds: [R1, R2, R8, R9, BR1, BR2, BR6, NFR1, NFR3]
    roles: [Visitor, Support Agent, Admin]
    route: /login
    targetFile: web/src/app/(authenticated)/layout.tsx
    pageAction: create_new
    isInfrastructureOnly: false
    acceptanceCriteria:
      - id: AC-1
        text: Signing in with a seeded account's correct email and password takes a Visitor to the Contact page and a Support Agent or Admin to the Inbox
        coverage: playwright
      - id: AC-2
        text: Submitting a wrong email or password shows an inline "email or password is incorrect" error on the sign-in screen, keeps the entered email, clears the password and moves focus to the error summary
        coverage: vitest
      - id: AC-3
        text: When sign-in cannot reach the sign-in service, the sign-in screen shows a connection-problem error that is distinct from the wrong-credentials error
        coverage: vitest
      - id: AC-4
        text: While signed out, any app URL typed into the address bar, including the app root, sends the user to the sign-in screen instead of the welcome page or the requested page
        coverage: playwright
      - id: AC-5
        text: After signing out, pressing the browser Back button returns the user to the sign-in screen rather than revealing the previous app page
        coverage: playwright
      - id: AC-6
        text: The sign-in screen has no automated accessibility violations, every field is labelled, and the whole form can be completed with the keyboard alone
        coverage: playwright
    manualTestChecklist:
      - Open the app while signed out → you land on the sign-in page, not a welcome page
      - Sign in as visitor@example.com / Test123 → you land on the Contact page
      - Sign in as agent@example.com (or admin@example.com) / Test123 → you land on the Inbox
      - Sign in with the wrong password → you see a message saying the email or password is incorrect, and your email is still filled in
      - Type the password → it is shown as dots, never as plain text
      - Sign in, click Sign out, then press the browser Back button → you're sent to sign-in, not back into the app
      - Using only the Tab and Enter keys, sign in successfully
    additionalTechnicalChecksCount: 2

  - index: 2
    title: Role-based menu and permission-denied banner
    slug: story-2-role-menu-and-permission-banner
    plainSummary: Once signed in, the top menu shows only what your role can use (a Visitor sees Contact and My messages; a Support Agent or Admin sees Inbox). If you open a page your role can't use from a direct link, the page shows a banner explaining which permission you're missing, with a link back to your own page.
    summary: Adds the role-scoped top navigation to the authenticated shell (items a role is denied are omitted, never disabled) and a reusable permission-denied banner that role-restricted pages render in place of their content when reached by direct link (no 403 page). The banner names the missing permission (new permission names such as "View inbox" / "Submit an enquiry" to be added to project.md with approval), links to the user's role landing page, is announced to assistive technology on load and its link is keyboard reachable. Applied to the placeholder /contact, /my-messages and /inbox pages.
    requirementIds: [R5, R6, R9, BR3, BR4, NFR2]
    roles: [Visitor, Support Agent, Admin]
    route: /inbox
    targetFile: web/src/app/(authenticated)/layout.tsx
    pageAction: modify_existing
    isInfrastructureOnly: false
    acceptanceCriteria:
      - id: AC-1
        text: A signed-in Visitor sees exactly "Contact" and "My messages" in the top menu, with no Inbox item shown in any form
        coverage: vitest
      - id: AC-2
        text: A signed-in Support Agent or Admin sees exactly "Inbox" in the top menu, with no Contact or My messages item shown in any form
        coverage: vitest
      - id: AC-3
        text: A Visitor who opens the Inbox address directly sees a permission-denied banner on the page naming the missing permission, and its link takes them back to the Contact page
        coverage: playwright
      - id: AC-4
        text: A Support Agent or Admin who opens the Contact or My messages address directly sees the permission-denied banner, and its link takes them back to the Inbox
        coverage: playwright
      - id: AC-5
        text: The permission-denied banner is announced to screen readers when the page loads and its back link can be reached and followed with the keyboard
        coverage: vitest
    manualTestChecklist:
      - Sign in as the Visitor → the top menu shows only Contact and My messages
      - Sign in as the Support Agent, then the Admin → the top menu shows only Inbox
      - As the Visitor, type /inbox in the address bar → you see a "you don't have permission" banner on the page (no error page) that names the missing permission
      - Click the banner's link → you're taken back to the Contact page
      - As the Support Agent, type /contact in the address bar → you see the banner, and its link takes you to the Inbox
      - Using only the Tab key, reach the banner's link and press Enter → it takes you to your page
    additionalTechnicalChecksCount: 1

  - index: 3
    title: Session timeouts and account lockout
    slug: story-3-session-timeouts-and-lockout
    plainSummary: Your session ends after 30 minutes without activity, or after 12 hours in total, and you're taken back to the sign-in screen with a message that your session expired. After 5 wrong passwords in a row the account is locked for 15 minutes, and the sign-in screen tells you so.
    summary: Adds simulated (browser-side, per BR6) session policy to the auth layer — a 30-minute idle timer reset by user activity and a 12-hour absolute cap — that ends the session and redirects to /login with a session-expired message. Tracks consecutive failed attempts per account; the 5th failure locks the account for 15 minutes, during which even the correct password is refused and the sign-in screen shows the lockout message with its remaining duration; a successful sign-in resets the failure count. Timings use the values recorded as inferred in project.md NFR-base-6.
    requirementIds: [R3, R4, BR5, BR6]
    roles: [Visitor, Support Agent, Admin]
    route: /login
    targetFile: web/src/app/login/page.tsx
    pageAction: modify_existing
    isInfrastructureOnly: false
    acceptanceCriteria:
      - id: AC-1
        text: On the 5th consecutive failed sign-in for an account, the sign-in screen says the account is locked and for how long (15 minutes)
        coverage: vitest
      - id: AC-2
        text: While an account is locked, signing in with its correct password is refused and the locked message is shown again
        coverage: vitest
      - id: AC-3
        text: Once 15 minutes have passed since the lockout, the account can sign in with the correct password and lands on its role's page
        coverage: playwright
      - id: AC-4
        text: After 30 minutes with no activity, a signed-in user is returned to the sign-in screen with a message that their session expired
        coverage: playwright
      - id: AC-5
        text: A user who keeps working is still signed out with the session-expired message once 12 hours have passed since signing in
        coverage: playwright
    manualTestChecklist:
      - Enter the wrong password for agent@example.com five times → the sign-in screen says the account is locked for 15 minutes
      - While it's locked, enter the correct password → you still can't sign in and see the locked message
      - Sign in as another seeded user while that account is locked → that user signs in normally
    additionalTechnicalChecksCount: 2

  - index: 4
    title: Enquiry and user records with sample data
    slug: story-4-enquiry-data-and-seed
    plainSummary: The app holds enquiries and users in memory, starting with sample enquiries that cover every category and every status, so the later Contact, My messages and Inbox screens have data to show. Changes last until the page is reloaded.
    summary: Delivers the in-memory data layer for Enquiry (fields, Category and Status enums, validation per the brief's Data Model) and the seeded sample set — every Category and every Status present, Resolved enquiries carrying a Reply Note, at least one enquiry submitted by visitor@example.com — alongside the seeded users. Exposes read/create/update/delete operations behind the API client shape that later epics consume; state persists for the session and resets on reload (PI-02).
    requirementIds: [R7, R8]
    roles: [N/A]
    route: null
    targetFile: web/src/lib/data/enquiryStore.ts
    pageAction: create_new
    isInfrastructureOnly: true
    acceptanceCriteria:
      - id: AC-1
        text: The seeded enquiries include at least one of each Category (Feedback, Question, General Enquiry) and each Status (New, In Progress, Resolved)
        coverage: vitest
      - id: AC-2
        text: Every seeded Resolved enquiry carries a Reply Note, and at least one seeded enquiry was submitted by visitor@example.com
        coverage: vitest
      - id: AC-3
        text: Enquiry records accept only the Category and Status values listed in the brief and enforce the brief's field validation rules
        coverage: vitest
      - id: AC-4
        text: A change made to an enquiry is visible on the next read in the same session, and a fresh load starts again from the seeded data
        coverage: vitest
    manualTestChecklist: []
    additionalTechnicalChecksCount: 4

unverifiedAssumptions: []

infrastructureReuseNotes:
  - "API client in web/src/lib/api/client.ts — route the simulated sign-in, session and enquiry calls through it rather than calling fetch directly"
  - "Shadcn primitives already present in web/src/components/ui/ (button, card, input, label) — compose the sign-in form and banner from these; add alert via the Shadcn CLI if needed"
  - "Toast system in web/src/contexts/ToastContext.tsx and web/src/components/toast/ — reuse for any transient confirmation; the permission-denied banner and sign-in errors stay inline on the page"
  - "Zod schemas live in web/src/lib/validation/schemas.ts — add the sign-in and Enquiry schemas there"
  - "Template root web/src/app/page.tsx is a public welcome page — replace it with a redirect into the sign-in / role-landing flow (do not keep it reachable)"
  - "Follow the server-side auth pattern's file shape (lib/auth/authClient.ts, lib/auth/requireSession.ts, app/(authenticated)/layout.tsx, app/login/page.tsx, app/logout/route.ts) with the simulated user store behind it"

designScreens: []

designChoices: []
