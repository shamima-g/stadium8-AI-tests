# Enquiry and user records with sample data

Epic: Sign-in and App Shell (`sign-in-and-app-shell`)

## Story metadata

```yaml
index: 4
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

