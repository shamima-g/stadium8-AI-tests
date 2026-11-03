# Role-based menu and permission-denied banner

Epic: Sign-in and App Shell (`sign-in-and-app-shell`)

## Story metadata

```yaml
index: 2
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

