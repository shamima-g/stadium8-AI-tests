# Prototype Brief: AdventureWorks Online Store

## 1. Objective

Design a prototype for a dual-experience e-commerce system, backed by the **AdventureWorks 2019** database, that enables:

- **Customers** to browse a product catalogue, build a shopping cart, and check out to place an order.
- **Admins** to manage the product catalogue and stock, process orders through their lifecycle, and manage customer records.

The prototype must reflect:

- A live, filterable catalogue drawn from `Production.Product`
- A cart → checkout → order lifecycle with a price snapshot and stock decrement
- Role-based interaction constraints (Customer vs Admin)

**Page budget:** **4 storefront pages** + **3 admin pages** (see §8).

---

## 2. Core Domain Model (from AdventureWorks 2019 + API)

The system revolves around these primary objects:

### 1. Product
Represents a sellable catalogue item. Key attributes:
- `ProductID`
- `Name`
- `ProductNumber`
- `ListPrice`
- `Color`, `Size`
- `ProductCategory` / `ProductSubcategory`
- `AvailableQuantity` (derived from `Production.ProductInventory`)
- `IsSellable` (derived from SellStartDate / SellEndDate / DiscontinuedDate)

### 2. Cart Item
Represents one line in a customer's cart (`Sales.ShoppingCartItem`). Key attributes:
- `ShoppingCartItemID`
- `ProductID`
- `Quantity`
- `UnitPrice` (current ListPrice)
- `LineTotal`

### 3. Order
Represents a placed order (`Sales.SalesOrderHeader` + `Sales.SalesOrderDetail`). Key attributes:
- `SalesOrderID`, `SalesOrderNumber`
- `OrderDate`, `ShipDate`
- `Status` (In process / Approved / Backordered / Rejected / Shipped / Cancelled)
- `CustomerID`
- `SubTotal`, `TaxAmt`, `Freight`, `TotalDue`
- Order lines (Product, OrderQty, UnitPrice, LineTotal)

### 4. Customer
The buyer (`Sales.Customer` + `Person.Person`). Authenticated via `POST /v1/auth/login`. Key attributes:
- `CustomerID`
- `FirstName`, `LastName`
- `EmailAddress`
- `AccountNumber`

---

## 3. Key System Relationships

- One **Category → many Subcategories → many Products**
- One **Customer → one Cart → many Cart Items**
- One **Customer → many Orders**; one **Order → many Order Lines**
- **Cart Item → Product** and **Order Line → Product**
- Checkout **converts** Cart Items into Order Lines (with a price snapshot), then empties the cart

---

## 4. Roles & Permissions

### Customer
- Browse / search / filter the catalogue
- View product detail
- Add to cart, edit cart, remove from cart
- Checkout & place order
- View **own** order history
- ❌ Cannot manage products, orders (status), or other customers

### Admin
- Manage products (create / update / discontinue) and stock
- View **all** orders and advance order status
- Manage customers (view / edit contact details)
- ❌ Cannot shop (no cart/checkout surface)

---

## 5. Key User Flows

### 5.1 Authentication
**Endpoint:** `POST /v1/auth/login`
**Flow**
1. User enters email + password.
2. On success → route to role landing (Customer → Catalog; Admin → Product Management).
3. On failure → inline error state.

### 5.2 Browse Catalog (Customer — Page 1)
**Endpoint:** `GET /v1/products`, `GET /v1/categories`, `GET /v1/subcategories`
**Flow**
1. Land on the catalog grid.
2. Filter by category / subcategory, search text, and price range; sort and page.
3. Each card shows name, price, and an in-stock badge; "Add to Cart" adds one unit.
4. Clicking a card opens product detail (modal or side panel — kept within the Catalog page to honour the 3-page budget).

**Prototype screens:** product grid, filter rail, product-detail panel, add-to-cart toast.

### 5.3 Shopping Cart (Customer — Page 2)
**Endpoint:** `GET /v1/cart`, `PUT /v1/cart/items/{id}`, `DELETE /v1/cart/items/{id}`, `DELETE /v1/cart`
**Flow**
1. View cart lines (product, unit price, quantity, line total).
2. Change a line's quantity (validated against available stock) or remove it.
3. See a running subtotal; proceed to checkout, or continue shopping.

**Prototype screens:** cart line list, quantity stepper, empty-cart state, subtotal summary.

### 5.4 Checkout (Customer — Page 3)
**Endpoint:** `GET /v1/ship-methods`, `POST /v1/orders`
**Flow**
1. Review order summary (lines + subtotal).
2. Choose ship-to address and ship method.
3. See computed Tax, Freight, and Total Due.
4. Place order → success confirmation showing the new `SalesOrderNumber`; cart is cleared.

**Prototype screens:** order summary, address/ship-method selectors, totals breakdown, order-confirmation state.

### 5.5 My Orders (Customer — Page 4)
**Endpoint:** `GET /v1/orders` (own orders), `GET /v1/orders/{id}`
**Flow**
1. View a table of the customer's own orders (number, date, total, status), most recent first; filter by status and date range.
2. Open an order to see its lines, ship-to address, ship method, and totals breakdown.
3. Status is read-only for the Customer (only Admin advances status).

**Prototype screens:** own-orders table with status chips, order-detail panel, empty state ("No orders yet" with a Browse-catalog CTA). Reached from the Checkout confirmation ("View my orders") and from the customer nav.

### 5.6 Product Management (Admin — Page 1)
**Endpoint:** `GET /v1/products?includeInactive=true`, `POST /v1/products`, `PUT /v1/products/{id}`, `DELETE /v1/products/{id}`, `PUT /v1/products/{id}/inventory`
**Flow**
1. View product table (name, number, category, price, stock, active status).
2. Create a new product; edit an existing one; discontinue one.
3. Adjust inventory quantity from a row action.

**Prototype screens:** product table, create/edit form, discontinue confirmation, inventory-adjust modal.

### 5.7 Order Management (Admin — Page 2)
**Endpoint:** `GET /v1/orders`, `GET /v1/orders/{id}`, `PUT /v1/orders/{id}/status`
**Flow**
1. View all orders (number, date, customer, total, status), filterable by status / customer / date range.
2. Open an order to see its lines, ship-to, and totals.
3. Advance status per the lifecycle (In process → Approved → Shipped; or Reject / Cancel).

**Prototype screens:** orders table with status chips, order-detail panel, status-change control with confirmation.

### 5.8 Customer Management (Admin — Page 3)
**Endpoint:** `GET /v1/customers`, `GET /v1/customers/{id}`, `PUT /v1/customers/{id}`
**Flow**
1. View customer table (name, email, account number, order count).
2. Open a customer to see profile + order history.
3. Edit contact details (name, email).

**Prototype screens:** customer table, customer-detail panel with order list, edit form.

---

## 6. Critical States (Do NOT skip this)

### Product states
- Sellable (in catalogue) / Discontinued (admin-only, historical)
- In stock / Out of stock (available quantity 0)

### Order states
- In process → Approved → Shipped (terminal)
- Backordered (transient)
- Rejected / Cancelled (terminal)

### UI implications
- Disable "Add to Cart" and quantity increases beyond available stock.
- Disable checkout on an empty cart.
- Admin status control offers only **valid next transitions**; terminal orders show no status action.
- Reflect stock/status changes immediately after an action.

---

## 7. Information Architecture

**Customer navigation:** Catalog · Cart (with item-count badge) · My Orders · (Checkout reached from Cart)
**Admin navigation:** Products · Orders · Customers

The active navigation set is chosen by role at login. A prototype **role switcher** (outside the app chrome) lets reviewers inspect each role without re-authenticating.

---

## 8. Key Screens to Prototype

**Storefront (Customer)**
1. Product Catalog (grid + filters + product-detail panel)
2. Shopping Cart
3. Checkout / Order Confirmation
4. My Orders (own order history + detail)

**Admin**
5. Product Management
6. Order Management (list + detail)
7. Customer Management (list + detail)

Plus: Login screen (shared, chrome-level).
