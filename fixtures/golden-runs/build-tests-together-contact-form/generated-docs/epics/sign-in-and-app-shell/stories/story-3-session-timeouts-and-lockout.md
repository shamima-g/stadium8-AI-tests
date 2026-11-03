# Session timeouts and account lockout

Epic: Sign-in and App Shell (`sign-in-and-app-shell`)

## Story metadata

```yaml
index: 3
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

