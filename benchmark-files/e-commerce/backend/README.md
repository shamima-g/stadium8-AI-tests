# E-Commerce Backend — Database Scripts

This folder holds the backend BRD and the SQL scripts that stand up the
**AdventureWorks 2019**-based database for the E-commerce Online Store.

| File | Size | Purpose |
|------|------|---------|
| `Backend-API-BRD.md` | ~35 KB | Business Requirements Document (data model, endpoints, rules). |
| `AdventureWorks2019_schema_2026-07-22.sql` | ~232 KB | **Structure only** — every table/view/procedure/function/constraint of the full AdventureWorks2019 database, no rows. Reference / rebuild the whole schema. |
| `AdventureWorks2019_ecommerce-slice_2026-07-22.sql` | ~655 KB | **Runnable slice (lean, no FKs)** — the project's tables only, FKs omitted so it is self-contained. Fastest to stand up. |
| `AdventureWorks2019_ecommerce-slice-fk_2026-07-22.sql` | ~991 KB | **Runnable slice (FK-complete)** — the full 29-table foreign-key closure with **real AdventureWorks schema and enforced FKs**, full reference/catalogue data, and a demo customer + order. Use this when you want referential integrity. |
| `AppSecurity_2026-07-22.sql` | ~4 KB | **Login & RBAC layer** (BRD §7.4) — `AppSecurity.AppRole` / `AppUser` / `Session`, seeded with the Customer + Admin roles and the two benchmark users (password `Test123`). Run **after** a slice. |

> These text scripts replace a 48 MB `.bak` binary backup (removed) — ~99% smaller and diff-able.

---

## Prerequisites

- **SQL Server 2019+** reachable (the scripts were generated against a local SQL Server 2022 instance).
- **`sqlcmd`** (ships with the SQL Server Client Tools / ODBC driver) or SQL Server Management Studio (SSMS) / Azure Data Studio.
- A login with permission to create a database. Examples below use SQL auth
  (`-U <user> -P <password>`); swap in your own credentials — **do not commit real passwords**.

---

## Option A — Run the runnable slice (recommended for this project)

Creates a fresh database and loads the E-commerce slice (catalogue + reference + cart data, plus a demo customer & order).

**Pick one of the two slice variants:**

| Variant | File | Foreign keys | Tables | Use when |
|---------|------|--------------|--------|----------|
| Lean | `..._ecommerce-slice_2026-07-22.sql` | omitted | ~13 | You want the smallest, fastest self-contained setup. |
| FK-complete | `..._ecommerce-slice-fk_2026-07-22.sql` | **enforced** | 29 (full FK closure) | You want real referential integrity / closest to source. |

```bash
# 1. Create an empty database
sqlcmd -S localhost -U <user> -P <password> -Q "CREATE DATABASE [AdventureWorksEcom];"

# 2a. Load the LEAN slice (schema + data, no FKs)
sqlcmd -S localhost -U <user> -P <password> -d AdventureWorksEcom -b ^
  -i "AdventureWorks2019_ecommerce-slice_2026-07-22.sql"

# --- OR ---

# 2b. Load the FK-COMPLETE slice (real schema + enforced FKs)
sqlcmd -S localhost -U <user> -P <password> -d AdventureWorksEcom -b ^
  -i "AdventureWorks2019_ecommerce-slice-fk_2026-07-22.sql"
```

```bash
# 3. Add the AppSecurity login layer (roles + seeded users) — run AFTER either slice
sqlcmd -S localhost -U <user> -P <password> -d AdventureWorksEcom -b ^
  -i "AppSecurity_2026-07-22.sql"
```

(In SSMS/Azure Data Studio: create the database, then open each `.sql` file against it and Execute in order.)

The FK-complete variant keeps the transactional/lookup tables (orders, credit cards, currency rates, sales persons, employees, stores) present with real FKs but **empty** — the demo customer & order populate the customer side; the app creates the rest at runtime.

### Login / seeded users (from `AppSecurity_2026-07-22.sql`)

| Email | Role | Linked customer | Password |
|-------|------|-----------------|----------|
| `customer@adventureworks.com` | Customer | `CustomerID 90000` (demo) | `Test123` |
| `admin@adventureworks.com` | Admin | — | `Test123` |

Passwords are stored as raw SHA-512 (`HASHBYTES('SHA2_512', <password>)`, 64 bytes). The app's login must hash the same way and compare. `AppUser.CustomerID` has a real FK to `Sales.Customer`, so the Customer login resolves to its AdventureWorks identity; the Admin has no linked customer.

**What you get after running:**

| Table | Rows | Source |
|-------|------|--------|
| `Production.ProductCategory` | 4 | full AdventureWorks data |
| `Production.ProductSubcategory` | 37 | full |
| `Production.Product` | 504 | full |
| `Production.ProductInventory` | 1,069 | full |
| `Purchasing.ShipMethod` | 5 | full |
| `Sales.SpecialOffer` | 16 | full |
| `Sales.ShoppingCartItem` | 3 | full |
| `Sales.Customer` | 1 | demo seed |
| `Sales.SalesOrderHeader` | 1 | demo seed (`SO90000`, TotalDue 79.53) |
| `Sales.SalesOrderDetail` | 1 | demo seed |
| `Person.Person` / `EmailAddress` / `Address` / `BusinessEntityAddress` | 1 each | demo seed |

The demo customer's email is `customer@adventureworks.com`, matching the benchmark's seeded Customer user (see BRD §4.2 / §7.5). Orders and customers are otherwise created by the application at runtime.

---

## Option B — Rebuild the full schema (structure only, no data)

Use this when you want the complete AdventureWorks structure (all schemas, incl. areas out of scope for the store) without any rows.

```bash
sqlcmd -S localhost -U <user> -P <password> -Q "CREATE DATABASE [AdventureWorks2019_Schema];"
sqlcmd -S localhost -U <user> -P <password> -d AdventureWorks2019_Schema -b ^
  -i "AdventureWorks2019_schema_2026-07-22.sql"
```

---

## Notes & design decisions

- **Slice = project-scoped subset.** The transactional tables in the slice
  (`Sales.Customer`, `Person.*`, `Sales.SalesOrderHeader/Detail`) are trimmed to the
  columns the BRD (§7) uses — not the full AdventureWorks definitions (which pull in
  XML schema collections, triggers, and extra user-defined types). The catalogue,
  reference, and cart tables **are** the real AdventureWorks schema + full data.
- **Two slice variants:** the **lean** slice omits foreign keys (self-contained,
  load-order-independent, ~13 tables — integrity enforced by the app per the BRD);
  the **FK-complete** slice includes the full 29-table foreign-key closure with real
  AdventureWorks schema and **enforced FKs**. Both were validated by running into a
  throwaway database (schema builds, data loads, demo order joins across all FKs).
- **AppSecurity layer** (`AppSecurity_2026-07-22.sql`) is separate from the slices,
  mirroring the BRD's "added identity layer" framing. It works after either slice
  (its `AppUser.CustomerID` FK links to the demo `Sales.Customer`). Validated on both.
  Login check confirmed: hashing `Test123` with `HASHBYTES('SHA2_512', …)` matches the
  seeded `PasswordHash`.
- **Computed columns** `SalesOrderHeader.TotalDue` and `SalesOrderDetail.LineTotal`
  are defined as computed, matching the BRD; do not insert values into them.
- Both scripts are safe to re-run against a **fresh** database. They are not
  idempotent against an already-populated database (they `CREATE` objects).
- Validation: the slice script was executed against a throwaway database and the row
  counts and computed values above were confirmed before shipping.
