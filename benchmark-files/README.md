# Benchmark projects

Each folder here is a **sample spec** that a fresh Stadium-8 project is built from during testing. A project
is the documents in `frontend/docs/` (requirements, OpenAPI specs, design files, sample data), an optional
`backend/` (business requirements + SQL/API), and an `answers.json` (the pre-planned answers the workflow
reads at each approval gate, so a run needs no human).

This page is the at-a-glance catalogue. Epic/story counts that the spec states explicitly are shown plain;
where the spec doesn't pin a number, it's a best estimate from the features and marked **(est.)** — the real
count is decided when the workflow decomposes the spec.

## At a glance

| Project | What it is | Epics | Stories | API | Back-end | Roles | Auth |
|---|---|---|---|---|---|---|---|
| **minimal-concurrent** | Personal Notes & Tasks — two independent features for one stubbed user | **2** | **2** | None (mock) | None — in-memory | User | Stub (no sign-in) |
| **contact-form-design** | Single-page public contact form, built from a design | **1** | **1** | None (mock) | None — front-end only | None | None |
| **feedback-api-design** | Single-page feedback wall, on a **real** API | **1** | **1** | **Real** — `api.yaml`, 1 path (list/post) | `backend/` — `api.yaml` + runnable `server.mjs` (:4010) | None | None |
| **singlepage-epic-test** | Minimal single-page contact form (one `.txt` brief) | **1** | **1** | None (mock) | None — front-end only | None | None |
| **contact-form** | Contact & enquiry triage — public form → role-gated back-office | ~3 (est.) | ~11 (est.) | None (mock) | None — mock-only (in-memory) | Visitor, Support Agent, Admin | BFF (simulated) |
| **design-taskboard** | Team task board built from a design (+ a phase-2 design-update scenario) | ~1–3 (est.) | ~4–5 (est.) | None (mock) | None — mock / stand-in | Team member | Email + password¹ |
| **transactions** | Transaction import & approval (financial, ZAR) | ~6 (est.) | ~12 (est.) | 2 OpenAPI specs — auth (4 paths) + transactions (29 paths) | `backend/` — BRD (Linx + SQL Server) + sample CSV | Importer, Approver | BFF |
| **e-commerce** | AdventureWorks online store — storefront + admin | ~7 (est.) | ~10 (est.) | 2 OpenAPI specs — auth (4 paths) + store (14 paths) | `backend/` — BRD + 4 SQL (AdventureWorks) + README | Customer, Admin | BFF |

¹ design-taskboard's auth is marked *needs-confirmation* in its spec (email + password, no SSO).

**API column** — "None (mock)" = no API spec; the app runs on in-memory / stand-in data. "OpenAPI specs" = REST
contracts are provided; the build mocks from them unless the backend is reachable. "Real" = a served backend the
build actually calls.

**Back-end column** — whether a `backend/` folder ships (BRD / SQL / a runnable server), and the data source:
*in-memory* or *mock-only* (no backend), *mock / stand-in* (none yet), *specs provided* (mock until the API is up),
or *real* (a served API).

## A little more on each

- **minimal-concurrent** — the cheap default for the `/plan` experiment: two features (Notes, Tasks) that must
  decompose into two separate epics. One seeded user, all client-side.
- **contact-form-design** / **feedback-api-design** — the design-driven pair: both build one screen from committed
  design files (`frontend/docs/design/`). `feedback-api-design` adds a **real** API (`server.mjs`) so it's the
  "built against a real backend" counterpart to the mock-only specs.
- **singlepage-epic-test** — the smallest spec in the set: a single plain-text brief, no `answers.json`, no docs
  folder. Used for the single-epic/single-story path.
- **contact-form** — a fuller mock-only app with three roles and a back-office triage flow (New / In Progress /
  Resolved, Admin delete).
- **design-taskboard** — a design-driven board (To do / In progress / Done, task detail, settings) that also
  carries a phase-2 **design update** (`update/`) with a deliberate token conflict and an undecodable brand blob,
  to exercise the "design changed" and "can't read this input" paths.
- **transactions** & **e-commerce** — the two backed-by-real-specs apps: multiple roles, BFF cookie-JWT auth, two
  OpenAPI specs each, a backend BRD, and sample data. The richest, most realistic builds (both are planning/spec
  references rather than quick throwaways).
