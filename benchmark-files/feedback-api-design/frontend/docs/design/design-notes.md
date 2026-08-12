# FeedbackWall — design notes

A single-page feedback wall. **One screen, one route (`/`).** Build to match this design plus
`mockup.html` and `tokens.css`. Unlike a mock-only build, the data is **real**: the list and the
new-message post go to the standalone API described in `documentation/backend/api.yaml` — do **not**
invent a stand-in/mock data layer, and do **not** guess endpoint paths (use the spec's exactly).

## Screens

### Feedback
The only screen, at the site root (`/`).

- Heading: **What people are saying**
- A **list of messages** loaded from the API on page load. Each item shows the **author**, the
  **message body**, and the **date**. Newest first.
- Empty state (no messages): **No messages yet — be the first.**
- Below the list, a **form** to add a message, all fields required:
  - **Name** (text) — placeholder "Your name"
  - **Message** (multi-line) — placeholder "Say something nice"
- A primary button: **Post message**. On submit, send it to the API, then show it at the top of the
  list and clear the form.

## Data — from the API, not a stand-in
The screen is backed by the API in `documentation/backend/api.yaml`:
- **GET `/api/v1/messages`** — the list (newest first).
- **POST `/api/v1/messages`** — create one (`{ author, body }`).

Call these through the app's shared API client using the spec's **exact paths** — no raw `fetch`
scattered in components, no invented paths.

## Palette & type
Brand colours in `tokens.css` (primary `#2563eb`, Inter).

## Deliberately not specified
How many messages to show / whether to paginate is **not** decided — assume "show all, newest
first" for now and flag it.
