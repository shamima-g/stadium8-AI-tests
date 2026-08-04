# E-Commerce Online Store — Planning Set

**Status:** Planning only — no application code is built here.
**Database:** Microsoft **AdventureWorks 2019** (SQL Server).
**Roles:** Customer + Admin.

An e-commerce benchmark modelled on the `transactions` set. A Customer browses a
catalogue, builds a cart, and checks out; an Admin manages products/stock, orders,
and customers. Backed by the existing AdventureWorks 2019 schemas (`Production`,
`Sales`, `Person`, `Purchasing`) plus a small added `AppSecurity` schema for login/RBAC.

## Page budget (4 + 3)
| Storefront (Customer) | Admin |
|-----------------------|-------|
| 1. Product Catalog (browse / filter / detail) | 1. Product Management (CRUD + stock) |
| 2. Shopping Cart | 2. Order Management (list + detail + status) |
| 3. Checkout / Order Confirmation | 3. Customer Management (list + detail + edit) |
| 4. My Orders (own order history + detail) | |

Shared: a Login screen (chrome-level).

## Documents
| File | What it is |
|------|-----------|
| [backend/Backend-API-BRD.md](backend/Backend-API-BRD.md) | **The backend BRD** — the primary deliverable. Business context, scope, process flows, functional requirements, AdventureWorks data model, business rules, API surface, NFRs, build/packaging. |
| [backend/README.md](backend/README.md) | How to run the database scripts (create DB → run slice / schema). |
| [backend/AdventureWorks2019_ecommerce-slice_2026-07-22.sql](backend/AdventureWorks2019_ecommerce-slice_2026-07-22.sql) | Runnable DB slice (**lean, no FKs**) — schema + data for the tables the BRD uses (catalogue/reference/cart full data + demo customer & order). |
| [backend/AdventureWorks2019_ecommerce-slice-fk_2026-07-22.sql](backend/AdventureWorks2019_ecommerce-slice-fk_2026-07-22.sql) | Runnable DB slice (**FK-complete**) — full 29-table FK closure, real AdventureWorks schema + enforced foreign keys, reference/catalogue data + demo customer & order. |
| [backend/AdventureWorks2019_schema_2026-07-22.sql](backend/AdventureWorks2019_schema_2026-07-22.sql) | Full AdventureWorks2019 structure only (no data). |
| [backend/AppSecurity_2026-07-22.sql](backend/AppSecurity_2026-07-22.sql) | Login & RBAC layer (AppRole/AppUser/Session) seeded with the Customer + Admin users; run after a slice. |
| [frontend/docs/PrototypeBrief.md](frontend/docs/PrototypeBrief.md) | Front-end prototype brief for the six pages: objective, domain model, roles, flows, states, IA, screens. |
| [frontend/docs/requirements.md](frontend/docs/requirements.md) | Detailed front-end requirements: domain model, functional reqs, RBAC matrix, data entities, prototype invariants. |
| [frontend/docs/store-api.yaml](frontend/docs/store-api.yaml) | OpenAPI 3.0 spec — Store Management API (catalogue, cart, orders, admin products/customers). |
| [frontend/docs/auth-api.yaml](frontend/docs/auth-api.yaml) | OpenAPI 3.0 spec — Authentication API (login/logout/userinfo/health). |
| [frontend/docs/design-system-generic-retail.md](frontend/docs/design-system-generic-retail.md) | Design tokens (colours, type, effects) + universal component/interaction/accessibility standards. |
| [frontend/docs/products_2026-07-22.csv](frontend/docs/products_2026-07-22.csv) | Sample product data (AdventureWorks-style) for fixtures/mock data — 26 rows across all four categories. |
| [answers.json](answers.json) | Benchmark intake facts (pitch, roles, page budget, data source, styling). |

## Key API surfaces
- **Auth API** — `http://localhost:10020`
- **Store API** — `http://localhost:10015/store-api`
- **Seeded users** — `customer@adventureworks.com` / `admin@adventureworks.com` (password `Test123`)

## Open items to confirm before any build
- Compliance/PII regime (assumed none; payment capture out of scope — order intent only). A mock/simulated payment step can be added on request.
- Styling / design system (a generic-retail design-system doc to be authored if approved).
