# Contact & Enquiry Management

A contact-and-enquiry app where a Visitor sends an enquiry (name, email, optional address, a category, and a comment) and gets confirmation straight away. Back-office staff work through the enquiries: a Support Agent moves each one through New, In Progress and Resolved, and an Admin can also delete enquiries. Enquiries are scoped by role, so a Visitor sees only their own.

| Field | Value |
|---|---|
| Project slug | `contact-form` |
| Created | 2026-11-03T07:17:19Z |
| Intake source | docs (`documentation/requirements.md`) |
| Backend connectivity | mock-only |

---

## Roles & Permissions

**Template:** `custom`

| Permission | Visitor | Support Agent | Admin |
|---|---|---|---|
| View main dashboard | ✓ | ✓ | ✓ |

**Role definitions** (from intake and `requirements.md` §3 / §6.5):

- **Visitor:** can sign in, submit an enquiry and view their own submissions (read-only). Lands on the Contact form. Cannot see the Inbox or other people's enquiries, and cannot change status or delete.
- **Support Agent:** can view all enquiries, search and filter them, move status from New to In Progress to Resolved, and resolve an enquiry with a mandatory reply note. Lands on the Inbox. Cannot submit through the public form or delete.
- **Admin:** has every Support Agent permission and can also delete an enquiry (behind a confirmation). Lands on the Inbox. Cannot submit through the public form.

Denied actions are **hidden** in the UI, not shown as disabled. Opening a role-restricted page through a direct link shows a permission-denied banner on the page, not a generic 403 page (`requirements.md` BR-05 / UF-09).

> Permissions extend during BUILD as new stories surface new actions. Additions are recorded here as they come up, with your approval. Removing a permission, or changing who the roles are, stops for you to review.

---

## Authentication

| Field | Value |
|---|---|
| Method | `server-side` (BFF: your own server) |
| Auth login endpoint (if server-side) | N/A. Auth is simulated by client-side stubs (`requirements.md` PI-01); no real backend endpoint |
| Auth userinfo endpoint (if server-side) | N/A. Simulated (PI-01) |
| Auth logout endpoint (if server-side) | N/A. Simulated (PI-01) |
| Custom auth notes | Auth is simulated client-side, as the prototype invariants require. The BFF shape follows the template's server-side auth policy. Sign-in uses email and password, then sends each role to its landing page (Visitor to the Contact form; Support Agent and Admin to the Inbox). Seeded users: `visitor@example.com` / `Test123` (Visitor), `agent@example.com` / `Test123` (Support Agent), `admin@example.com` / `Test123` (Admin). |

> Auth method is never inferred — the user must confirm explicitly per [authentication-intake.md](.claude/policies/authentication-intake.md).

---

## Data Source & Backend Integration

| Field | Value |
|---|---|
| Data source | `mock-only` |
| Backend status | `N/A` (none) |
| Mock layer required | yes. In-memory fixtures built from `requirements.md`: a few seeded enquiries covering all three categories (Feedback / Question / General Enquiry) and all three statuses (New / In Progress / Resolved), plus the three seeded users. Changes last for the session but not past a reload (PI-02). Emails and notifications show only as UI confirmations (PI-04). |

### API specs

No OpenAPI spec was provided. The domain entities (Enquiry, User) are defined in `documentation/requirements.md` §7.

---

## Compliance

**Applicable domains:** None (the user confirmed the project is not regulated)
**Region (if Personal data applies):** N/A

### Compliance Requirements

No compliance domains were identified during intake screening.

- Note: the app does collect personal data (name, email, optional address). Only authenticated back-office roles (Support Agent, Admin) can see enquiries. Visitors never see anyone else's (`requirements.md` §6.6.1, BR-04).

---

## Styling & Branding

| Field | Value |
|---|---|
| Primary brand color | `#2563eb` [INFERRED] the user asked for template defaults with no bespoke design system, so this is the styling-centralisation Pattern A default (Tailwind blue-600) |
| Accent / secondary | `#64748b` [INFERRED] a neutral accent from Tailwind `slate`, per the Pattern A default |
| Background (light) | `#ffffff` [INFERRED] the default for a neutral light palette |
| Background (dark, if applicable) | N/A |
| Font family (headings) | [INFERRED] system UI stack (Pattern A default; no font named in the sources) |
| Font family (body) | [INFERRED] system UI stack (Pattern A default; no font named in the sources) |
| Theme | [INFERRED] light only (Pattern A default; dark mode can be added later) |
| Source | defaulted (user: "template Shadcn defaults with a clean, neutral palette and centralised styling tokens") |

> Component-specific styling (button radii, card shadows, etc.) emerges during BUILD. This section captures only palette intent and typography per [styling-centralisation.md](.claude/policies/styling-centralisation.md).

---

## Baseline NFRs

- **NFR-base-1:** Accessibility: WCAG 2.2 Level AA (`requirements.md` §6.6.3 raises this above the 2.1 AA baseline). Primary flows are keyboard-first, status colour is always paired with an icon or text, and icon-only controls have a tooltip and an `aria-label`
- **NFR-base-2:** Performance: First Contentful Paint < 2.5s on a mid-tier mobile network
- **NFR-base-3:** Responsive design: mobile (≥360px) / tablet (≥768px) / desktop (≥1280px) breakpoints
- **NFR-base-4:** Browser support: latest two versions of Chrome / Edge / Firefox / Safari
- **NFR-base-5:** Error UX: every async operation shows a visible error state with a way to retry
- **NFR-base-6:** [INFERRED] Session policy: 30-minute idle timeout, 12-hour absolute timeout, and lockout for 15 minutes after 5 failed sign-in attempts. Carried over from `requirements.md` §6.6.1, which marks these values as inferred. Auth is simulated (PI-01), so this behaviour is shown in the UI only
- **NFR-base-7:** Personal-data visibility: an enquirer's name, email and address are shown only to authenticated back-office roles and never to other Visitors (`requirements.md` §6.6.1, confirmed at intake)
