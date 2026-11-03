# Benchmark: `feedback-api-design-sql` (build-from-design + REAL backend on SQL Server — AC4)

The **SQL Server** variant of [`feedback-api-design`](../feedback-api-design/). Same single-page
feedback wall, same design, same two API paths — the only difference is that the standalone API
persists its data in a **SQL Server** database instead of an in-memory store. It backs acceptance
criterion **AC4**: the design's stand-in data is replaced by **real backend calls** to the spec's
exact paths.

| Path | What it is |
|---|---|
| `frontend/docs/design/` | the design (`design-notes.md`, `mockup.html`, `tokens.css`) → dropped into `documentation/design/` |
| `backend/api.yaml` | the **standalone API** OpenAPI spec (GET/POST `/api/v1/messages`) → dropped into `documentation/backend/` |
| `backend/schema.sql` | the **SQL Server** DDL + seed for `dbo.Messages` |
| `backend/server.mjs` | a **runnable** standalone server that reads/writes `dbo.Messages` (`npm i mssql`, then `node server.mjs` → `http://localhost:4010`) |
| `backend/README.md` | how to create the DB, apply the schema, and set the `SQLSERVER_*` env vars |
| `answers.json` | design-driven; `dataSource` = the real API (SQL Server behind it), exact paths, shared client (no mock, no raw fetch, frontend never touches SQL Server) |

## Why it's AC4's benchmark
The mock-only design runs never produce `generated-docs/specs/api-spec.yaml` or
`web/src/lib/api/endpoints.ts`, so the exact-path check (TG-31, `api-path-exactness`) **skips**. This
build produces both, so that check **gates** — proving the design build honoured the real API's
exact paths (`/api/v1/messages`), used the shared client, and invented nothing. The SQL Server
persistence is the API's concern; the frontend contract (the exact paths) is unchanged, so the AC4
check is identical to the in-memory variant.

## Run (quick — one epic, one story)
Drop `frontend/docs/*` into `documentation/` and `backend/` into `documentation/backend/`, copy
`answers.json` → `TIER3-ANSWERS.json`, then `/start` and build one story to a merge. To run the API
for real: create a `FeedbackWall` database, apply `documentation/backend/schema.sql`, `npm i mssql`,
and start the server with the `SQLSERVER_*` env vars set (see `backend/README.md`).

## Capture (AC4)
Bring back `generated-docs/specs/api-spec.yaml` and `web/src/lib/api/endpoints.ts`; the replay test
runs `extractSpecPaths` + `findInventedPaths` over them (see
`tier-1-unit/artifact-lint/api-path-exactness.test.ts`), asserting no invented paths.
