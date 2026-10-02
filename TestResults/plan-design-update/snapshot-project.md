# TaskBoard

A small team task board application for organising work across To do, In progress, and Done columns with task management and user settings.

| Field | Value |
|---|---|
| Project slug | `taskboard` |
| Created | 2026-10-02T00:00:00Z |
| Intake source | design |
| Backend connectivity | mock-only |

---

## Roles & Permissions

**Template:** `custom`

| Permission | Team Member |
|---|---|
| View main dashboard | ✓ |

> Permissions extend during BUILD as new stories surface new actions. Additions are recorded here as they come up, with your approval. Removing a permission, or changing who the roles are, stops for you to review.

---

## Authentication

| Field | Value |
|---|---|
| Method | `custom` |
| Custom auth notes | Simple email + password authentication, no SSO for launch |

> Auth method is never inferred — the user must confirm explicitly per [authentication-intake.md](.claude/policies/authentication-intake.md).

---

## Data Source & Backend Integration

| Field | Value |
|---|---|
| Data source | `mock-only` |
| Backend status | N/A |
| Mock layer required | yes |

### API specs

No API specs provided — mock layer will be generated during BUILD.

---

## Compliance

**Applicable domains:** None
**Region (if Personal data applies):** N/A

### Compliance Requirements

No compliance domains were identified during intake screening.

---

## Styling & Branding

| Field | Value |
|---|---|
| Primary brand color | `#2563eb` |
| Primary hover | `#1d4ed8` |
| Accent / secondary | `#16a34a` |
| Background (light) | `#f8fafc` |
| Surface | `#ffffff` |
| Text | `#0f172a` |
| Muted | `#64748b` |
| Font family (headings) | Inter |
| Font family (body) | Inter |
| Theme | light only |
| Source | design digest palette (tokens.css) |

> Component-specific styling (button radii, card shadows, etc.) emerges during BUILD. This section captures only palette intent and typography per [styling-centralisation.md](.claude/policies/styling-centralisation.md).

---

## Baseline NFRs

- **NFR-base-1:** Accessibility — WCAG 2.1 Level AA baseline
- **NFR-base-2:** Performance — First Contentful Paint < 2.5s on a mid-tier mobile network
- **NFR-base-3:** Responsive design — mobile (>=360px) / tablet (>=768px) / desktop (>=1280px) breakpoints
- **NFR-base-4:** Browser support — latest two versions of Chrome / Edge / Firefox / Safari
- **NFR-base-5:** Error UX — user-visible error states with retry affordance for all async operations

---

## Design Source

| Field | Value |
|---|---|
| Digest | `generated-docs/design/digest.md` |
| Palette source | `tokens.css` `:root` block |
| Read from | `documentation/design/mockup.html`, `documentation/design/tokens.css`, `documentation/design/design-notes.md` |
| Attached files | `documentation/design/brand-export.bin` (binary, unreadable) |

### Screens

| Screen | Key details |
|---|---|
| Board | Landing kanban view with To do / In progress / Done columns, filter dropdown, New task button |
| Task detail | Form for viewing/editing tasks (title, assignee, status, due date, priority) with save and delete actions |
| Settings | User display name configuration with save button |

### Data Model

| Entity | Fields |
|---|---|
| Task | title, assignee, status (To do / In progress / Done), due date, priority (Low / Medium / High) |

> The app is **rebuilt in our stack** (Shadcn + design tokens) to match the design as described in the digest — not copied from any source markup. Prototype constructs that must NOT carry forward to production — placeholder/fake data, remote CDN icons, placeholder handlers, inline styles — are listed in the digest's "Translate, Don't Copy" section and flagged in the per-epic brief.md "Notes & Caveats" when an epic touches that screen.
