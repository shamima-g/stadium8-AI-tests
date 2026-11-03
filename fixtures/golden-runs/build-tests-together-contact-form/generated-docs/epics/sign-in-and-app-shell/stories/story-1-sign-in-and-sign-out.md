# Sign in, land on your page, and sign out

Epic: Sign-in and App Shell (`sign-in-and-app-shell`)

## Story metadata

```yaml
index: 1
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

```

## Resolved design choices

None.

## Infrastructure reuse notes (epic-wide)

  - "API client in web/src/lib/api/client.ts — route the simulated sign-in, session and enquiry calls through it rather than calling fetch directly"
  - "Shadcn primitives already present in web/src/components/ui/ (button, card, input, label) — compose the sign-in form and banner from these; add alert via the Shadcn CLI if needed"
  - "Toast system in web/src/contexts/ToastContext.tsx and web/src/components/toast/ — reuse for any transient confirmation; the permission-denied banner and sign-in errors stay inline on the page"
  - "Zod schemas live in web/src/lib/validation/schemas.ts — add the sign-in and Enquiry schemas there"
  - "Template root web/src/app/page.tsx is a public welcome page — replace it with a redirect into the sign-in / role-landing flow (do not keep it reachable)"
  - "Follow the server-side auth pattern's file shape (lib/auth/authClient.ts, lib/auth/requireSession.ts, app/(authenticated)/layout.tsx, app/login/page.tsx, app/logout/route.ts) with the simulated user store behind it"

