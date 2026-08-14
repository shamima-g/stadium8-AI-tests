# Benchmark: `feedback-api-design` (build-from-design + REAL backend — AC4)

A small single-page feedback wall whose requirements come from a **design** *and* whose data comes
from a **standalone API** — the design counterpart to the mock-only runs. It backs acceptance
criterion **AC4**: the design's stand-in data is replaced by **real backend calls** to the spec's
exact paths.

| Path | What it is |
|---|---|
| `frontend/docs/design/` | the design (`design-notes.md`, `mockup.html`, `tokens.css`) → dropped into `documentation/design/` |
| `backend/api.yaml` | the **standalone API** OpenAPI spec (GET/POST `/api/v1/messages`) → dropped into `documentation/backend/` |
| `backend/server.mjs` | a tiny **runnable** standalone server (no deps, `node server.mjs` → `http://localhost:4010`) so the app can run against a real backend |
| `answers.json` | design-driven; `dataSource` = the real API, exact paths, shared client (no mock, no raw fetch) |

## Why it's AC4's benchmark
The mock-only design runs never produce `generated-docs/specs/api-spec.yaml` or
`web/src/lib/api/endpoints.ts`, so the exact-path check (TG-31, `api-path-exactness`) **skips**. This
build produces both, so that check **gates** — proving the design build honoured the real API's
exact paths (`/api/v1/messages`), used the shared client, and invented nothing.

## Run (quick — one epic, one story)
Drop `frontend/docs/*` into `documentation/` and `backend/` into `documentation/backend/`, copy
`answers.json` → `TIER3-ANSWERS.json`, then `/start` and build one story to a merge. Optionally run
the API for real: `node documentation/backend/server.mjs`.

## Capture (AC4)
Bring back `generated-docs/specs/api-spec.yaml` and `web/src/lib/api/endpoints.ts`; the replay test
runs `extractSpecPaths` + `findInventedPaths` over them (see
`tier-1-unit/artifact-lint/api-path-exactness.test.ts`), asserting no invented paths.
