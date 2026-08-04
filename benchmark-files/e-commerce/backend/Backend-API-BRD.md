# Business Requirements Document (BRD)
## E-Commerce Online Store Backend API ("AdventureWorks Online Store — Training Backend")

| | |
|---|---|
| **Document title** | Business Requirements Document — E-Commerce Online Store Backend API |
| **Subject system** | `store-api` (Stadium 8 benchmark application) |
| **Source analysed** | `AdventureWorks2019` sample database (Microsoft SQL Server) |
| **Platform** | Microsoft SQL Server 2019 (AdventureWorks2019) + portable HTTP API service |
| **Author** | QA / Business Analysis |
| **Date** | 2026-07-22 |
| **Status** | Draft for review (planning only — no build) |

---

## 1. Executive Summary

The E-Commerce Online Store Backend is a server-side application that exposes an **online retail catalogue**, a per-customer **shopping cart**, and an **order placement and fulfilment** workflow, backed by the Microsoft **AdventureWorks 2019** sample database. It serves two audiences through one API surface: **Customers** who browse products, build a cart, and place orders; and **Administrators** who manage the product catalogue, process orders, and manage customer records.

The system persists all data in **SQL Server (AdventureWorks2019)**, reusing its existing `Production`, `Sales`, and `Person` schemas for products, orders, carts, and people, plus a small **application identity layer** (`AppSecurity` schema) introduced to provide authentication and role-based access control (Customer vs Admin), which the stock AdventureWorks schema does not model on its own.

It is delivered as **two logical HTTP API services**:

1. **Authentication API** (port `10020`) — login, logout, current-user info, health.
2. **Store Management API** (port `10015`, prefix `/store-api`) — catalogue, cart, checkout, orders, products (admin), customers (admin), and reference data.

The backend is the system of record behind a separate front-end (the storefront + admin prototype in the same repository). This BRD describes the **business capabilities, rules, data, and interfaces the backend must satisfy**, derived from the AdventureWorks 2019 schema and the accompanying front-end planning documents.

> **Scope note:** This project is deliberately scoped to **four storefront pages** (Catalog, Cart, Checkout, My Orders) and **three admin pages** (Product Management, Order Management, Customer Management). The backend exposes only the endpoints those seven pages require, plus authentication. The full breadth of AdventureWorks (manufacturing, purchasing, HR, sales-territory analytics) is **out of scope**.

---

## 2. Business Context & Objectives

### 2.1 Problem statement
A retailer holds its product, customer, and order data in an operational database (AdventureWorks 2019) but has no customer-facing online store against it. Customers cannot self-serve — browsing, building a basket, and placing orders — and staff have no focused back-office surface to keep the catalogue current and move orders through fulfilment. There is a need for an API that turns the existing database into a working online store with a clear separation between the **shopping** experience and the **administration** experience.

### 2.2 Business goals
| # | Goal |
|---|------|
| BG-1 | Let customers browse and search a live product catalogue drawn from `Production.Product`. |
| BG-2 | Let a customer assemble a **shopping cart** and carry it to a **checkout** that creates a real sales order. |
| BG-3 | Ensure every placed order is captured with correct line items, priced at time of sale, and reduces available stock. |
| BG-4 | Give administrators a back-office to **manage products & stock**, **process orders through their lifecycle**, and **manage customers**. |
| BG-5 | Enforce a clean split of duties: Customers shop; Admins administer. Neither sees the other's surfaces. |
| BG-6 | Secure access via authentication, session control, and role-based authorisation. |
| BG-7 | Expose a clean, versioned API surface that the storefront and admin front-ends integrate against. |

### 2.3 Domain
Retail / E-commerce — cycle-sports retailer (bikes, components, clothing, accessories) as modelled by AdventureWorks 2019. Sample data uses **USD** currency and North-American address conventions.

---

## 3. Scope

### 3.1 In scope
- **Catalogue browsing**: list/search/filter products by category, subcategory, text, and price; product detail; category/subcategory reference data.
- **Shopping cart**: view current cart, add item, change quantity, remove item, clear cart (per authenticated customer).
- **Checkout / order placement**: convert a cart into a `Sales.SalesOrderHeader` + `Sales.SalesOrderDetail`, capture shipping address and ship method, price lines at time of sale, decrement inventory.
- **Order history**: a customer views their own orders; an admin views all orders and one order's detail.
- **Product management (admin)**: create, update, and deactivate (discontinue) products; adjust inventory quantity.
- **Order management (admin)**: list orders, view an order, advance/change order **Status** through its lifecycle, set ship date.
- **Customer management (admin)**: list customers, view a customer (with their orders), update a customer's contact details.
- **Authentication**: login, logout, current-user info, session token (JWT) creation and validation, health check.
- **Access control**: Customer vs Admin roles gating the relevant endpoints; a customer may only act on their own cart and orders.
- Audit fields (`LastChangedUser`, `ModifiedDate`) on business mutations.

### 3.2 Out of scope
- The front-end / user interface (covered by the separate storefront + admin prototype).
- Real payment capture / card processing (checkout records order intent only; `CreditCardID` is out of scope or stubbed).
- Manufacturing, purchasing, work orders, HR/employee, and sales-territory/BI analytics areas of AdventureWorks.
- Shipping-carrier integration, tax-engine integration, and email/notification delivery (visual/stub only on the front-end).
- Product reviews, wish-lists, promotions/special-offer authoring (special offers are read-only if referenced at all).
- Infrastructure provisioning, CI/CD, and database administration.

---

## 4. Stakeholders & User Roles

### 4.1 Business roles (seeded in the system)
| Role (seeded name) | Business persona | Responsibility |
|--------------------|------------------|----------------|
| **Customer** | Shopper | Browses the catalogue, manages a cart, places orders, and views their own order history. |
| **Admin** | Store administrator | Manages the product catalogue and stock, processes orders through fulfilment, and manages customer records. |

> The application identity layer seeds two roles — **"Customer"** and **"Admin"** — and two corresponding default users (see §7.5). Customers are linked to an AdventureWorks `Sales.Customer` / `Person.Person`; the Admin is an application-only operator account.

### 4.2 Default seeded users
| Email | Name | Role | Default password |
|-------|------|------|------------------|
| `customer@adventureworks.com` | Alex Customer | Customer | `Test123` (SHA-512 hashed at rest) |
| `admin@adventureworks.com` | Sam Admin | Admin | `Test123` (SHA-512 hashed at rest) |

### 4.3 Other stakeholders
- **System / Operations** — deploys and runs the API service and database.
- **Front-end consumers** — the storefront and admin SPAs integrating against the documented API.
- **Auditors / merchandisers** — rely on audit fields, order status history, and accurate stock.

---

## 5. Business Process Flows

### 5.1 Browse → cart → checkout (Customer)
```
Browse Catalog ── filter by category/subcategory, search text, price range
      │
      ▼
View Product Detail ── price, description, availability (in-stock?)
      │
      ▼
Add to Cart ── upsert Sales.ShoppingCartItem (ProductID, Quantity) for the customer's cart
      │
      ▼
Review Cart ── adjust quantities / remove lines; see running subtotal
      │
      ▼
Checkout ── choose ship-to address + ship method; confirm order summary
      │
      ▼
Place Order ── create SalesOrderHeader (Status = 1 In process) + SalesOrderDetail lines
      │           price each line at current ListPrice; compute SubTotal/Tax/Freight/TotalDue;
      │           decrement Production.ProductInventory; clear the cart
      ▼
Order Confirmed ── customer sees the new order in their history
```

### 5.2 Order status lifecycle (AdventureWorks `Sales.SalesOrderHeader.Status`)
```
1 In process ──approve──► 2 Approved ──ship──► 5 Shipped   (terminal)
     │                         │
     │                         └──backorder──► 3 Backordered ──► 2 Approved …
     ├──reject───────────────► 4 Rejected     (terminal)
     └──cancel───────────────► 6 Cancelled    (terminal)
```
- Orders are created by checkout with **Status = 1 (In process)**.
- An **Admin** advances the order: `In process → Approved`, `Approved → Shipped` (sets `ShipDate`), or moves to `Backordered`.
- **Rejected (4)** and **Cancelled (6)** and **Shipped (5)** are terminal — status does not advance further.
- Customers **cannot** change order status; they can view only.

### 5.3 Authentication flow
```
POST /v1/auth/login (email + password)
   → validate app user exists
   → validate password (SHA-512 hash compare against AppSecurity.AppUser)
   → create Session row + JWT token, set as cookie
   → resolve role (Customer | Admin) and (for Customer) the linked CustomerID
   → 200 success  |  401 invalid credentials

Subsequent API calls → OnAuthenticate:
   → assert session token exists, active, not expired
   → refresh last-access & expiry
   → 200 continue  |  401 reject
```

### 5.4 Product & stock maintenance (Admin)
```
Create Product ── insert Production.Product (SellStartDate = today, SellEndDate = null)
Update Product ── edit name, price, category/subcategory, colour/size, etc.
Discontinue    ── set SellEndDate / DiscontinuedDate → product leaves the sellable catalogue
Adjust Stock   ── set/adjust Production.ProductInventory.Quantity for a location
```

### 5.5 Customer maintenance (Admin)
An Admin lists customers, opens a customer to see their profile and order history, and may update the linked `Person.Person` contact details (name, email address). Deleting customers is out of scope (deactivation/edit only).

---

## 6. Functional Requirements

### 6.1 Authentication & session (Authentication API, port 10020)
| ID | Requirement |
|----|-------------|
| FR-A1 | The system shall authenticate a user by **email and password** via `POST /v1/auth/login`. |
| FR-A2 | On successful login, the system shall create a **session** record and a **JWT session token**, returned as a cookie. |
| FR-A3 | On failed login, the system shall return **401** without disclosing whether the email or the password was wrong. |
| FR-A4 | The system shall verify passwords against a stored **SHA-512 password hash** (passwords never stored in plain text). |
| FR-A5 | The system shall provide `POST /v1/auth/logout` to delete the user's session(s) and clear the session token. |
| FR-A6 | The system shall provide `GET /v1/auth/userinfo` returning the authenticated user's profile, **role**, and (for a Customer) the linked `CustomerID`. |
| FR-A7 | The system shall expose `GET /v1/health` for an unauthenticated health/status probe. |
| FR-A8 | The system shall protect all store-management endpoints with an authenticate-on-operation check validating the session token's existence, activity, and expiry, refreshing last-access/expiry each call. |
| FR-A9 | On login the system shall remove the user's prior sessions before creating a new one (single active session per user). |

### 6.2 Catalogue (Store Management API, port 10015)
| ID | Requirement |
|----|-------------|
| FR-P1 | The system shall list **sellable products** (`GET /v1/products`) — those with `SellEndDate` null (or in the future) and `SellStartDate` reached — with paging, single-column sort, and total count. |
| FR-P2 | The system shall support filtering the product list by **ProductCategoryId**, **ProductSubcategoryId**, **free-text search** (Name / ProductNumber), and **price range** (min/max `ListPrice`). |
| FR-P3 | The system shall return a single product's detail (`GET /v1/products/{ProductID}`) including name, number, colour, size, list price, subcategory/category, description, and an **available-quantity** figure summed from `Production.ProductInventory`. |
| FR-P4 | The system shall list **product categories** (`GET /v1/categories`) and **subcategories** for a category (`GET /v1/subcategories?CategoryId=`). |
| FR-P5 | The product list shall expose an **in-stock indicator** (available quantity > 0) so the storefront can badge availability. |

### 6.3 Shopping cart
| ID | Requirement |
|----|-------------|
| FR-C1 | The system shall return the authenticated customer's **current cart** (`GET /v1/cart`) as a set of line items (ProductID, Name, UnitPrice, Quantity, LineTotal) plus a cart subtotal. |
| FR-C2 | The system shall **add an item** to the cart (`POST /v1/cart/items`); adding an existing product increments its quantity (upsert on `Sales.ShoppingCartItem`). |
| FR-C3 | The system shall **update a cart line's quantity** (`PUT /v1/cart/items/{ShoppingCartItemID}`); a quantity of zero is rejected (use delete instead). |
| FR-C4 | The system shall **remove a cart line** (`DELETE /v1/cart/items/{ShoppingCartItemID}`) and **clear the whole cart** (`DELETE /v1/cart`). |
| FR-C5 | The cart shall be **owned by the authenticated customer**; a customer cannot read or mutate another customer's cart. |
| FR-C6 | Adding/updating a cart line shall validate that the requested quantity does not exceed the product's **available inventory**; over-requests are rejected with a clear error. |

### 6.4 Checkout & orders
| ID | Requirement |
|----|-------------|
| FR-O1 | The system shall place an order from the customer's cart (`POST /v1/orders`), creating one `Sales.SalesOrderHeader` (Status = 1 In process, `OnlineOrderFlag = 1`) and one `Sales.SalesOrderDetail` per cart line. |
| FR-O2 | Each order line's **UnitPrice shall be captured from the product's current `ListPrice`** at checkout time (price snapshot); `LineTotal` is derived. |
| FR-O3 | The system shall compute order **SubTotal**, **TaxAmt**, **Freight**, and **TotalDue** on placement (tax/freight may use simple documented rules — see BR-12). |
| FR-O4 | Placing an order shall **decrement `Production.ProductInventory`** for each line and **clear the customer's cart**, within a single database transaction. |
| FR-O5 | The system shall reject checkout when the cart is **empty** or when any line exceeds **available inventory** at placement time. |
| FR-O6 | The system shall list orders (`GET /v1/orders`): a **Customer** sees only their own orders; an **Admin** sees all, filterable by Status, customer, and order-date range. |
| FR-O7 | The system shall return one order's detail (`GET /v1/orders/{SalesOrderID}`) including header, line items, ship-to address, and ship method; a Customer may only read their own order. |
| FR-O8 | An **Admin** shall change an order's **Status** (`PUT /v1/orders/{SalesOrderID}/status`) following the lifecycle in §5.2; advancing to **Shipped** sets `ShipDate`. |
| FR-O9 | The system shall provide ship-method reference data (`GET /v1/ship-methods`) from `Purchasing.ShipMethod`. |

### 6.5 Product management (Admin)
| ID | Requirement |
|----|-------------|
| FR-M1 | An Admin shall **create a product** (`POST /v1/products`) with name, product number (unique), list price, standard cost, subcategory, and optional colour/size/weight; `SellStartDate` defaults to today, `SellEndDate` null. |
| FR-M2 | An Admin shall **update a product** (`PUT /v1/products/{ProductID}`), guarded against duplicate `ProductNumber`. |
| FR-M3 | An Admin shall **discontinue a product** (`DELETE /v1/products/{ProductID}`) by setting `SellEndDate`/`DiscontinuedDate`; discontinued products leave the sellable catalogue but remain referenced by historical orders (no hard delete). |
| FR-M4 | An Admin shall **adjust inventory** (`PUT /v1/products/{ProductID}/inventory`) setting the quantity for a location. |
| FR-M5 | The admin product list (`GET /v1/products?includeInactive=true`) shall optionally include discontinued products, distinguished by a status/active flag. |

### 6.6 Customer management (Admin)
| ID | Requirement |
|----|-------------|
| FR-U1 | An Admin shall **list customers** (`GET /v1/customers`) with name, email, account number, and order count, with paging, search, and sort. |
| FR-U2 | An Admin shall **view a customer** (`GET /v1/customers/{CustomerID}`) including profile and their order history summary. |
| FR-U3 | An Admin shall **update a customer's contact details** (`PUT /v1/customers/{CustomerID}`) — first/last name and primary email — writing to `Person.Person` / `Person.EmailAddress`. |
| FR-U4 | Customer records shall **not be hard-deleted** (referential integrity with orders); deletion is out of scope. |

### 6.7 Cross-cutting
| ID | Requirement |
|----|-------------|
| FR-X1 | All list endpoints shall support **paging** (page / pageSize), a **total count**, and **single-column sort** (field + direction). |
| FR-X2 | All mutating endpoints shall accept a **`LastChangedUser`** header for audit attribution and stamp `ModifiedDate`. |
| FR-X3 | Constraint violations (e.g. duplicate `ProductNumber`) shall return a structured **duplicate/validation error**, not a raw 500. |

---

## 7. Data Requirements

The database is the SQL Server **`AdventureWorks2019`** sample database. The application reuses its `Production`, `Sales`, `Person`, and `Purchasing` schemas, and adds a small **`AppSecurity`** schema for identity/RBAC.

### 7.1 `Production` schema (catalogue & stock)
| Table | Purpose | Key fields (used) |
|-------|---------|-------------------|
| `Production.Product` | The sellable product. | ProductID (PK), Name, ProductNumber (unique), Color, StandardCost, ListPrice, Size, Weight, ProductSubcategoryID→ProductSubcategory, ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate, ModifiedDate |
| `Production.ProductCategory` | Top-level category. | ProductCategoryID (PK), Name (*Bikes, Components, Clothing, Accessories*) |
| `Production.ProductSubcategory` | Subcategory under a category. | ProductSubcategoryID (PK), ProductCategoryID→ProductCategory, Name |
| `Production.ProductInventory` | Stock on hand per location. | ProductID→Product, LocationID, Shelf, Bin, Quantity |
| `Production.ProductDescription` / `ProductModelProductDescriptionCulture` | Marketing description (optional, for detail page). | ProductDescriptionID, Description |
| `Production.ProductPhoto` / `ProductProductPhoto` | Product image (optional). | ProductPhotoID, LargePhoto, ThumbNailPhoto |

> **Available quantity** for a product = `SUM(Production.ProductInventory.Quantity)` across locations. **Sellable** = `SellStartDate <= today AND (SellEndDate IS NULL OR SellEndDate > today) AND DiscontinuedDate IS NULL`.

### 7.2 `Sales` schema (cart & orders)
**`Sales.ShoppingCartItem`** — the cart line (one cart per customer, keyed by a `ShoppingCartID` string; this app uses the customer's identifier as the cart id):
| Field | Type | Notes |
|-------|------|-------|
| ShoppingCartItemID | int (PK, identity) | |
| ShoppingCartID | nvarchar(50) | Cart owner key (customer-scoped) |
| Quantity | int | > 0 |
| ProductID | int → Production.Product | |
| DateCreated | datetime | |
| ModifiedDate | datetime | |

**`Sales.SalesOrderHeader`** — the order:
| Field | Type | Notes |
|-------|------|-------|
| SalesOrderID | int (PK, identity) | |
| SalesOrderNumber | (computed) | Display reference, e.g. `SO43659` |
| OrderDate | datetime | Default now |
| DueDate | datetime | |
| ShipDate | datetime (nullable) | Set when Status → Shipped |
| Status | tinyint | 1 In process · 2 Approved · 3 Backordered · 4 Rejected · 5 Shipped · 6 Cancelled |
| OnlineOrderFlag | bit | 1 for storefront orders |
| CustomerID | int → Sales.Customer | |
| ShipToAddressID / BillToAddressID | int → Person.Address | |
| ShipMethodID | int → Purchasing.ShipMethod | |
| SubTotal / TaxAmt / Freight | money | |
| TotalDue | (computed) | SubTotal + TaxAmt + Freight |
| Comment | nvarchar(128) (nullable) | |
| ModifiedDate | datetime | |

**`Sales.SalesOrderDetail`** — the order line:
| Field | Type | Notes |
|-------|------|-------|
| SalesOrderDetailID | int (PK, identity) | |
| SalesOrderID | int → SalesOrderHeader | |
| ProductID | int → Production.Product | |
| OrderQty | smallint | |
| UnitPrice | money | **Price snapshot at checkout** |
| UnitPriceDiscount | money | Default 0 |
| LineTotal | (computed) | (UnitPrice · (1 − discount)) · OrderQty |
| SpecialOfferID | int → Sales.SpecialOffer | Default 1 (No Discount) |

### 7.3 `Person` schema (people & addresses)
| Table | Purpose | Key fields (used) |
|-------|---------|-------------------|
| `Sales.Customer` | The buyer. | CustomerID (PK), PersonID→Person.Person, StoreID, TerritoryID, AccountNumber |
| `Person.Person` | Name/profile. | BusinessEntityID (PK), PersonType, FirstName, MiddleName, LastName |
| `Person.EmailAddress` | Email(s) for a person. | BusinessEntityID, EmailAddressID, EmailAddress |
| `Person.Address` | Postal addresses. | AddressID (PK), AddressLine1, AddressLine2, City, StateProvinceID, PostalCode |
| `Person.BusinessEntityAddress` | Person↔Address with type. | BusinessEntityID, AddressID, AddressTypeID |
| `Purchasing.ShipMethod` | Shipping methods. | ShipMethodID (PK), Name, ShipBase, ShipRate |

### 7.4 `AppSecurity` schema (application identity & RBAC — new)
> AdventureWorks does not model application login roles for an online store, so a thin identity layer is added. `Person.Password` (hash+salt) exists in AdventureWorks but is not wired to roles; this app manages its own credential + role table for clarity.

| Table | Purpose | Key fields |
|-------|---------|-----------|
| `AppSecurity.AppUser` | Login account. | Id (PK), Email (unique), FirstName, LastName, PasswordHash (SHA-512), RoleId→AppRole, CustomerID→Sales.Customer (nullable; set for Customer role) |
| `AppSecurity.AppRole` | Role. | Id (PK), Name (unique) — *Customer*, *Admin* |
| `AppSecurity.Session` | Active login sessions. | Id (PK), AppUserId→AppUser, IpAddress, CreatedDate, ExpiryDate, LastAccessDate, Token (JWT) |

### 7.5 Seed data
- Roles: **Customer**, **Admin**.
- Users: `customer@adventureworks.com` (Customer, linked to an existing `Sales.Customer`), `admin@adventureworks.com` (Admin) — both hashed password `Test123`.
- Catalogue, inventory, addresses, ship methods, and existing customers/orders come from the stock **AdventureWorks 2019** data.

---

## 8. Business Rules

| ID | Rule |
|----|------|
| BR-01 | A product is **sellable** only when `SellStartDate <= today`, `SellEndDate` is null or future, and `DiscontinuedDate` is null. Non-sellable products do not appear in the storefront catalogue. |
| BR-02 | A cart-line or order-line **quantity must be a positive integer** and **must not exceed the product's available inventory** at the time of the action. |
| BR-03 | **Checkout requires a non-empty cart**; an empty cart cannot create an order. |
| BR-04 | Each order line's **UnitPrice is snapshotted** from the product's current `ListPrice` at checkout; later price changes do not alter historical orders. |
| BR-05 | Placing an order **decrements inventory** and **clears the cart** atomically; if any line fails validation, the whole order is rolled back. |
| BR-06 | Order **Status transitions** follow §5.2; `Rejected (4)`, `Cancelled (6)`, and `Shipped (5)` are terminal. Advancing to `Shipped` sets `ShipDate`. |
| BR-07 | Only an **Admin** may change order status, manage products/inventory, or manage customers. A **Customer** may only browse, manage their own cart, and place/view their own orders. |
| BR-08 | A Customer may **read and mutate only their own cart and orders** (ownership enforced by the authenticated `CustomerID`). |
| BR-09 | **`ProductNumber` is unique**; create/update violating this returns a duplicate-record error. |
| BR-10 | Products and customers referenced by historical orders are **never hard-deleted** — products are discontinued (soft), customers are edit-only. |
| BR-11 | **Email is unique** per app user; passwords are stored only as **SHA-512 hashes**, never plain text. |
| BR-12 | Order monetary fields use documented simple rules for the training scope: `TaxAmt = round(SubTotal × 0.08, 2)`, `Freight = ShipMethod.ShipBase + (cart weight × ShipMethod.ShipRate)` (or a flat documented default when weight is absent), `TotalDue = SubTotal + TaxAmt + Freight`. |
| BR-13 | Only an authenticated user with a **valid, non-expired session** may call protected endpoints; each call refreshes the session's last-access and expiry. |
| BR-14 | On a new login, the user's **previous sessions are removed** (single active session). |
| BR-15 | Every business mutation records **who** (`LastChangedUser`) and **when** (`ModifiedDate`). |

---

## 9. Interface (API) Requirements

Two HTTP services, both documented via Swagger/OpenAPI (see `frontend/docs/store-api.yaml`, `frontend/docs/auth-api.yaml`).

### 9.1 Authentication API — base `http://localhost:10020`
| Method & path | Purpose |
|---------------|---------|
| `POST /v1/auth/login` | Authenticate (email + password); issue session cookie. |
| `POST /v1/auth/logout` | Delete session(s); clear cookie. |
| `GET /v1/auth/userinfo` | Return authenticated user profile, role, and CustomerID. |
| `GET /v1/health` | Health probe (unauthenticated). |

### 9.2 Store Management API — base `http://localhost:10015/store-api`
**Catalogue (Customer + Admin read)**
| Method & path | Purpose |
|---------------|---------|
| `GET /v1/products` | List/search/filter products (category, subcategory, q, minPrice, maxPrice, paging, sort). |
| `GET /v1/products/{ProductID}` | Product detail with available quantity. |
| `GET /v1/categories` | List product categories. |
| `GET /v1/subcategories?CategoryId=` | List subcategories for a category. |
| `GET /v1/ship-methods` | List shipping methods. |

**Cart (Customer)**
| Method & path | Purpose |
|---------------|---------|
| `GET /v1/cart` | Get current customer's cart. |
| `POST /v1/cart/items` | Add item (upsert quantity). |
| `PUT /v1/cart/items/{ShoppingCartItemID}` | Update line quantity. |
| `DELETE /v1/cart/items/{ShoppingCartItemID}` | Remove a line. |
| `DELETE /v1/cart` | Clear the cart. |

**Orders (Customer place/view own; Admin view all + status)**
| Method & path | Purpose |
|---------------|---------|
| `POST /v1/orders` | Place order from cart. |
| `GET /v1/orders` | List orders (own for Customer; all for Admin, filterable). |
| `GET /v1/orders/{SalesOrderID}` | Order detail. |
| `PUT /v1/orders/{SalesOrderID}/status` | **Admin** — change order status. |

**Products (Admin)**
| Method & path | Purpose |
|---------------|---------|
| `POST /v1/products` | Create product. |
| `PUT /v1/products/{ProductID}` | Update product. |
| `DELETE /v1/products/{ProductID}` | Discontinue product (soft). |
| `PUT /v1/products/{ProductID}/inventory` | Adjust inventory quantity. |

**Customers (Admin)**
| Method & path | Purpose |
|---------------|---------|
| `GET /v1/customers` | List customers. |
| `GET /v1/customers/{CustomerID}` | Customer detail + order history. |
| `PUT /v1/customers/{CustomerID}` | Update customer contact details. |

### 9.3 Interface conventions
- All protected endpoints require a **valid session cookie** (set at login).
- Mutating endpoints accept a **`LastChangedUser`** header for audit attribution.
- Standard HTTP status codes: `200` success, `400` validation error, `401` unauthorised, `403` role-forbidden, `404` not found, and structured **duplicate/validation** payloads on constraint violations.
- List responses carry `{ items: [...], totalCount, page, pageSize }`.

---

## 10. Non-Functional Requirements

| Area | Requirement |
|------|-------------|
| **Security — auth** | Email/password login; SHA-512 password hashing; JWT session tokens; server-side session validation with expiry and last-access refresh; role-based authorisation (Customer/Admin). |
| **Security — data** | Passwords never returned or stored in clear text; a customer's cart/orders are isolated to that customer; admin-only endpoints reject Customer sessions with 403. |
| **Auditability** | `LastChangedUser` + `ModifiedDate` on business mutations; order status changes and ship dates retained. |
| **Integrity** | Foreign keys, unique indexes (`ProductNumber`, app-user email), and quantity/price checks enforce referential and value integrity; checkout runs in a transaction. |
| **Reliability** | Order placement wrapped in a transaction with rollback on any line failure; inventory never goes negative. |
| **Performance / volume** | Designed for AdventureWorks-scale catalogue (~500 products, ~20 subcategories) and low-thousands of orders; list endpoints paged; storefront read p95 ≤ 2 s. |
| **Deployability** | The application must be **buildable into a portable, self-contained runnable artifact** (standalone service or container image) runnable on **any server** with a reachable SQL Server, and startable as a **local test server** with a single documented command. |
| **Portability** | Environment-specific values (ports, DB connection string, JWT secret, tax/freight constants) must be **externally configurable** via config file / environment variables so the same artifact runs unchanged across servers. |

---

## 11. Assumptions, Constraints & Dependencies

### 11.1 Assumptions
- The storefront and admin front-ends enforce **role-specific navigation and UI gating**; the backend independently enforces authentication, session, ownership, and role checks on protected endpoints.
- The stock **AdventureWorks 2019** data is present and used as the catalogue, customer, address, and historical-order seed; the app adds only the `AppSecurity` layer and app seed users.
- A single cart per customer is sufficient (no saved/named carts); the cart is identified by the customer's key.
- Payment is **not captured** — checkout records order intent (Status = In process); card fields are stubbed/omitted.

### 11.2 Constraints
- Persistence is **SQL Server / AdventureWorks 2019**; the connection string must be **configurable**.
- Several AdventureWorks columns are **required/NOT NULL** (e.g. `SalesOrderHeader` addresses, `rowguid`, `ModifiedDate`); order placement must populate them with sensible documented defaults (e.g. reuse the customer's default address, `DueDate = OrderDate + 7 days`).
- `SalesOrderNumber`, `TotalDue`, and `LineTotal` are **computed columns** — the app writes the inputs, not these.
- Tax and freight use **documented simplified rules** (BR-12), not a real tax/shipping engine.

### 11.3 Dependencies
- A reachable **SQL Server 2019** instance with the **AdventureWorks2019** database restored.
- A **build toolchain** capable of producing a portable runnable artifact (and, if a container target is chosen, a container runtime).
- A migration/seed step that creates the `AppSecurity` schema and seeds roles + app users.

---

## 12. Glossary

| Term | Definition |
|------|-----------|
| **Product** | A sellable catalogue item (`Production.Product`). |
| **Category / Subcategory** | Two-level product classification (Bikes/Components/Clothing/Accessories → subcategories). |
| **Available quantity** | Sum of `Production.ProductInventory.Quantity` across locations for a product. |
| **Sellable** | A product currently offered for sale (see BR-01). |
| **Cart** | A customer's set of `Sales.ShoppingCartItem` lines prior to checkout. |
| **Order** | A `Sales.SalesOrderHeader` plus its `Sales.SalesOrderDetail` lines. |
| **Order Status** | `In process (1)` → `Approved (2)` / `Backordered (3)` → `Shipped (5)`; or `Rejected (4)` / `Cancelled (6)`. |
| **Price snapshot** | The product's `ListPrice` copied to the order line's `UnitPrice` at checkout. |
| **Customer** | A buyer (`Sales.Customer` + `Person.Person`); also an app role. |
| **Admin** | A store operator app role with back-office access. |
| **Session** | A server-side login record with a JWT token, expiry, and last-access timestamp. |
| **RBAC** | Role-Based Access Control (Customer vs Admin). |

---

## 13. Build, Packaging & Hosting Requirements

### 13.1 Goals
| ID | Requirement |
|----|-------------|
| BH-1 | The application shall be **built** from source into a **portable, self-contained runnable artifact** (standalone service/executable or container image). |
| BH-2 | The artifact shall be **runnable on any server** meeting the prerequisites (a supported runtime + a reachable SQL Server with AdventureWorks2019). |
| BH-3 | The build shall provide a way to **start a local test server** with a single documented command for end-to-end verification. |
| BH-4 | Both API surfaces (Authentication and Store Management) shall be available from the artifact at **configurable ports** (defaults `10020` / `10015`), exposing the endpoints and Swagger/OpenAPI docs in §9. |
| BH-5 | All environment-specific settings shall be **externally configurable** — HTTP ports, SQL Server connection string, JWT signing secret, and tax/freight constants — via config file and/or environment variables, with documented defaults. |
| BH-6 | The database shall be provisioned by a **repeatable, bundled step**: restore AdventureWorks2019, then run a migration/seed that creates `AppSecurity` and seeds roles + app users. |
| BH-7 | The build and run procedure shall be **documented** (prerequisites, build command, run/test-server command, configuration reference, DB setup). |

### 13.2 Acceptance criteria
- A clean checkout **builds** with the documented command and produces the portable artifact.
- The artifact **starts as a local test server**; `GET /v1/health` returns success and both Swagger pages load.
- Login with a seeded user (`customer@adventureworks.com` / `admin@adventureworks.com`) succeeds and a protected endpoint (e.g. `GET /v1/products`) is reachable with the issued session.
- A Customer can browse, add to cart, and place an order; inventory decrements and the cart clears.
- An Admin can create/update/discontinue a product, adjust inventory, advance an order's status, and edit a customer.
- A Customer session is **403-forbidden** from admin endpoints, and cannot read another customer's cart/orders.

---

## Appendix A — Source artefacts reviewed
- **AdventureWorks 2019** SQL Server sample database — `Production`, `Sales`, `Person`, `Purchasing` schemas (products, categories, inventory, shopping-cart, orders, customers, addresses, ship methods).
- `frontend/docs/PrototypeBrief.md` — storefront + admin prototype brief (six pages).
- `frontend/docs/requirements.md` — front-end requirements, domain model, RBAC, data entities.
- `frontend/docs/store-api.yaml`, `frontend/docs/auth-api.yaml` — OpenAPI specs for the two services.
- `answers.json` — benchmark intake facts (pitch, roles, data source, styling).
