# Design Digest — FeedbackWall

A single-screen public feedback wall at the site root (`/`): a heading, a list of posted messages (author, body, date — newest first) loaded from a real API, and a form below to post a new message. Backed by a standalone REST API, not stand-in data.

| Field | Value |
|---|---|
| Read from | `documentation/design/design-notes.md`, `documentation/design/mockup.html`, `documentation/design/tokens.css` (design); `documentation/backend/api.yaml` (API, for data shapes) |
| Artifact verdict | design — comprehended one screen, a palette, and the data shapes behind it |
| Interpreter confidence | high — text/markup design, self-consistent across notes, mockup, tokens, and the API spec |
| Last updated | 2026-08-12T08:05:35.303Z |

---

## Your Decisions

- **Date display format** (2026-08-12, at the Feedback Wall stories approval): show the **date only** (e.g. 1 May 2026), not date-time or relative time. Resolves the "Date display format" uncertainty below.
- **Pagination / message count** (2026-08-12, at the Feedback Wall stories approval): **show all messages, newest first (no limit)** — no paging or "load more". Resolves the "Pagination / message count" uncertainty below.

---

## Screens

### Feedback

- **Purpose:** The only screen. Visitors read what people have posted and add their own message. Lives at the site root (`/`).
- **Layout:** Single-column page. Top-to-bottom: heading, then the message list, then the new-message form below the list. Messages render newest-first. Each list item shows the author (emphasised), the message body, and the date (muted). The design shows a lightweight inline layout — re-express with tokens and primitives (see Translate, Don't Copy).
- **Fields:** (new-message form, all required)
  - **Name** — text input, placeholder "Your name"
  - **Message** — multi-line text (textarea), placeholder "Say something nice"
- **Validation:** Both fields required ("all fields required"). **No error-message text is given in the design** — see Uncertainties.
- **Navigation:** None — single screen, single route. Submitting the form posts the message, then shows it at the top of the list and clears the form (stays on the same screen).
- **Copy (verbatim):**
  - Heading: **"What people are saying"**
  - Empty state (no messages): **"No messages yet — be the first."**
  - Submit button: **"Post message"**
  - Field label: **"Name"**; placeholder **"Your name"**
  - Field label: **"Message"**; placeholder **"Say something nice"**

---

## Palette & Typography

| Token | Value | Where found |
|---|---|---|
| Primary | `#2563eb` | `tokens.css` `--color-primary` (the "Post message" button) |
| Primary (hover) | `#1d4ed8` | `tokens.css` `--color-primary-hover` |
| Background | `#f8fafc` | `tokens.css` `--color-bg` |
| Surface | `#ffffff` | `tokens.css` `--color-surface` |
| Text | `#0f172a` | `tokens.css` `--color-text` |
| Muted (date text) | `#64748b` | `tokens.css` `--color-muted` |

- **Font (body & headings):** `"Inter", system-ui, sans-serif` (`tokens.css` `--font-sans`; no separate heading family specified)
- **Theme:** light only (no dark palette in the files)
- **Other tokens:** `--radius: 8px`, `--space: 16px` (`tokens.css`)

---

## Data Shapes

From `documentation/backend/api.yaml` (OpenAPI), confirmed by what the screen displays and collects:

- **Message** — `id` (string), `author` (string), `body` (string), `createdAt` (string, date-time). The list renders `author`, `body`, and the date (from `createdAt`), newest first.
- **NewMessage** (create payload) — `author` (string, required), `body` (string, required). The form's "Name" maps to `author`; "Message" maps to `body`.

API endpoints (exact paths, base URL `http://localhost:4010`):
- **GET `/api/v1/messages`** — list, newest first (returns `Message[]`).
- **POST `/api/v1/messages`** — create; body `{ author, body }`; returns the created `Message` (`201`), or `400` on validation error.

---

## Assets

- None. No logos, images, or icons ship with this design.

---

## Translate, Don't Copy

- **Placeholder / fake data → real data.** The two mockup rows ("Ada — Love this!", "Grace — Very handy.") are canned sample data. Load the list from the real API on page load; do not ship the sample rows or a stand-in data layer.
- **Placeholder handlers → real handlers.** The mockup's inert `<form>` becomes a real submit: post to the API, prepend the created message to the list, and clear the form.
- **Inline styles → design tokens + primitives.** The mockup sets colours via inline `style` attributes referencing CSS vars; re-express visual intent through the project's tokens and Shadcn primitives rather than copying inline styles.
- **CSS-var tokens → the project's token system.** `tokens.css` describes brand intent (colours, font, radius, spacing); carry the values into the project's centralised tokens rather than importing the file as-is.

---

## Uncertainties

- **Pagination / message count is deliberately unspecified.** The design says how many messages to show, or whether to paginate, is not decided. Assumed "show all, newest first" for now — please confirm, or tell us a limit / paging behaviour.
- **Date display format.** The API returns `createdAt` as a full date-time; the mockup shows a plain date (e.g. `2026-05-01`). Should the list show the date only, or a date-time / relative time? Which format?
- **No validation error text.** Both fields are required, but the design gives no error messages for empty/invalid input. What should the required-field errors say? Should the `400` from POST surface a specific message to the user?
- **List item separator.** The mockup renders author and body inline with an em dash ("Ada — Love this!"). Treating this as visual layout rather than literal required copy — confirm the intended per-item presentation (e.g. author on its own line vs. inline).
- **No auth / identity.** Nothing in the design gates posting or ties a message to a signed-in user — the poster types their own name. Confirm the wall is fully public (anyone can read and post).
