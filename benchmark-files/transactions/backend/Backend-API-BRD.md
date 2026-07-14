# Business Requirements Document (BRD)
## Transaction Management Backend API ("Stadium 8 Training Backend")

| | |
|---|---|
| **Document title** | Business Requirements Document — Transaction Management Backend API |
| **Subject system** | `backend-api` (Stadium 8 benchmark application) |
| **Source analysed** | `stadium-software-stadium-8-benchmark-app-main/backend-api` |
| **Platform** | Linx 6.12.1 low-code engine + Microsoft SQL Server 2022 |
| **Author** | QA / Business Analysis |
| **Date** | 2026-06-29 |
| **Status** | Draft for review |

---

## 1. Executive Summary

The Transaction Management Backend is a server-side application that ingests **bank transaction files**, processes them through a controlled import lifecycle, and exposes the resulting transactions for **review, approval, rejection, and export** by authorised operators. It also provides **authentication, session management, and role-based access control (RBAC)** so that the right users see the right working surfaces.

The system is built on the **Linx** low-code automation platform and persists all data in **SQL Server**. It is delivered as **two HTTP API services** plus a background **directory-watch service** and a **file-import workflow (process)**:

1. **Authentication API** (port `10010`) — login, logout, current-user info, health.
2. **Transaction Management API** (port `10005`, prefix `/transactions-api`) — files, transactions, users, roles, pages, and file-configuration reference data.

The backend is the system of record behind a separate front-end (the `frontend` prototype in the same repository). This BRD describes the **business capabilities, rules, data, and interfaces the backend must satisfy**, derived from the deployed Linx solution, the database build scripts, and the supporting documentation.

> **Deployment requirement (revised):** The application must **not be solely hostable on a Linx Server**. It must be **built into a portable, self-contained runnable artifact** that the user can **deploy and run on any server**, or **launch locally as a test server**, without a dependency on the Linx Server runtime. See §10 (Non-Functional Requirements), the new §13 (Build, Packaging & Hosting), and §11 (Constraints).

---

## 2. Business Context & Objectives

### 2.1 Problem statement
Banks and financial-operations teams receive transaction data as **files** (typically daily CSV extracts). Handling these manually is slow, error-prone, and not auditable. There is a need for a system that reliably ingests these files, validates their content, and routes each transaction through a controlled **approve / reject** decision with an audit trail.

### 2.2 Business goals
| # | Goal |
|---|------|
| BG-1 | Reduce manual handling of bank transaction files by automating ingestion, parsing, and validation. |
| BG-2 | Ensure every imported transaction reaches a **terminal decision** (Approved or Rejected), with a documented reason on rejection. |
| BG-3 | Provide a clear, auditable file-processing lifecycle (upload → validate → import → review). |
| BG-4 | Enforce **separation of duties** between the operator who imports files and the operator who approves transactions. |
| BG-5 | Secure access via authentication, session control, and role-based authorisation. |
| BG-6 | Expose a clean, versioned API surface that a front-end (or other consumers) can integrate against. |

### 2.3 Domain
Financial Services — file-driven bank transaction processing. Sample data uses **ZAR** currency, retail-banking account numbering, and debit/credit conventions.

---

## 3. Scope

### 3.1 In scope
- File ingestion via **upload endpoint** and via **monitored inbox directory** (directory-watch).
- File registration, duplicate detection (file hash), staging, validation, transformation, and bulk import into the transaction store.
- Transaction listing, **approve**, and **reject (with mandatory note)**.
- File log management: list, download original file, download processing/validation errors, download data, retry validation, cancel/delete.
- File-configuration reference data: file settings, sources, types, locations, location types, bulk settings, bulk-setting databases, process definitions, pages.
- **Authentication**: login, logout, current-user info, session token (JWT) creation and validation, health check.
- **User & access management**: users (CRUD), roles (CRUD), role-to-page mappings, user-to-role mappings.
- Audit fields (`LastChangedUser`, `LastChangedDate`) on business records.

### 3.2 Out of scope
- The front-end / user interface (covered by the separate `frontend` prototype).
- Real third-party banking integrations or payment execution.
- Reporting/BI beyond CSV/file export of data already held.
- Infrastructure provisioning, CI/CD, and Linx server administration.
- Data-residency, archival, and retention policies (infrastructure-side).

---

## 4. Stakeholders & User Roles

### 4.1 Business roles (seeded in the system)
| Role (seeded name) | Business persona | Responsibility |
|--------------------|------------------|----------------|
| **File Importer** | Importer | Uploads transaction files, monitors processing state, retries failed files, cancels erroneous files. |
| **Approver** | Approver | Reviews imported transactions and approves or rejects each one; exports filtered data. |

> The database seeds two roles — **"File Importer"** and **"Approver"** — and two corresponding default users (see §7.4). A single `Transactions` page is seeded and granted to both roles.

### 4.2 Default seeded users
| Email | Name | Role | Default password |
|-------|------|------|------------------|
| `fileimporter@digiata.com` | File Importer | File Importer | `Test123` (SHA-512 hashed at rest) |
| `approver@digiata.com` | Approver User | Approver | `Test123` (SHA-512 hashed at rest) |

### 4.3 Other stakeholders
- **System / Operations** — deploys and runs the Linx services and database.
- **Front-end consumers** — integrate against the documented API.
- **Auditors** — rely on audit fields and rejection notes.

---

## 5. Business Process Flows

### 5.1 File ingestion & import lifecycle
The core process is the **FileImportProcess** workflow, orchestrated by Linx and tracked via the process-automation engine. A file moves through the following stages:

```
Upload / Drop file
      │
      ▼
Register File  ── compute MD5 hash, count records, insert File.Log, move to backup
      │            (rejects duplicates by hash)
      ▼
Load           ── load raw rows into Staging.Transaction
      │
      ▼
Validate       ── flag invalid rows (e.g. invalid transaction type); set IsValid / InvalidReason
      │
      ▼
Transform      ── normalise values (e.g. transaction type D/C → Debit/Credit)
      │
      ▼
Import (BCP)   ── bulk-copy validated rows into dbo.Transaction with Status = 'Imported'
      │            (BCP errors captured to an error file)
      ▼
Completed  ◄── or ──►  Failed  (validation errors surfaced; retry available)
```

**Two ingestion triggers:**
1. **API upload** — `POST /v1/files/upload` accepts a file for a chosen File Setting and starts the default file-import workflow.
2. **Directory watch** — the `TransactionDirectoryWatch` service monitors an inbox folder (`C:\DigiataFileProcessing\Test\Input`) and automatically starts the workflow when a matching file is created.

> Operationally, only one ingestion path should run at a time (the README warns to switch the directory-watch service OFF when using the upload endpoint).

### 5.2 File status (derived)
File status is **derived** from the workflow's last executed activity / process state and surfaced as: `Uploaded` → `Processing` → `Completed` | `Failed`. `Completed` and `Failed` are terminal. A `Failed` file exposes validation errors and may be retried.

### 5.3 Transaction decision lifecycle
```
Imported  ──approve──►  Approved   (terminal)
    │
    └────reject (note)─►  Rejected  (terminal)
```
- A transaction is created with status **`Imported`**.
- An **Approver** may **Approve** (→ `Approved`) or **Reject** (→ `Rejected`, requires a non-empty note).
- `Approved` and `Rejected` are terminal — status does not change afterwards.

### 5.4 Authentication flow
```
POST /v1/auth/login (email + password)
   → validate user exists (GetUser)
   → validate password (SHA-512 hash compare)
   → create Session row + JWT token, set as cookie
   → 200 success  |  401 invalid user  |  401 invalid password

Subsequent API calls → OnAuthenticate:
   → assert session token exists
   → fetch session, assert active & not expired
   → update last-access & expiry
   → 200 continue  |  401 reject
```

### 5.5 File cancellation
An Importer may cancel/delete a file (`DELETE /v1/files`): the File Log is deactivated (`IsActive = 0`), the actual file is removed, and associated staging/target transactions are cleaned up so they no longer appear to Approvers.

---

## 6. Functional Requirements

### 6.1 Authentication & session (Authentication API, port 10010)
| ID | Requirement |
|----|-------------|
| FR-A1 | The system shall authenticate a user by **email and password** via `POST /v1/auth/login`. |
| FR-A2 | On successful login, the system shall create a **session** record and a **JWT session token**, and return it as a cookie. |
| FR-A3 | On failed login, the system shall return **401** distinguishing *invalid user* from *invalid password* (internally), without leaking which to the caller beyond the status. |
| FR-A4 | The system shall verify passwords against a stored **SHA-512 password hash** (passwords never stored in plain text). |
| FR-A5 | The system shall provide `POST /v1/auth/logout` to delete the user's session(s) and clear the session token. |
| FR-A6 | The system shall provide `GET /v1/auth/userinfo` to return the authenticated user's profile. |
| FR-A7 | The system shall expose `GET /v1/health` for an unauthenticated health/status probe. |
| FR-A8 | The system shall protect transaction-management endpoints with an **authenticate-on-operation** check that validates the session token's existence, activity, and expiry, and refreshes last-access/expiry on each call. |
| FR-A9 | On login, the system shall remove the user's prior sessions before creating a new one (single active session per user). |

### 6.2 File management (Transaction Management API, port 10005)
| ID | Requirement |
|----|-------------|
| FR-F1 | The system shall accept a file upload (`POST /v1/files/upload`) for a specified File Setting and start the default file-import workflow. |
| FR-F2 | The system shall automatically ingest files dropped into a monitored inbox directory via the directory-watch service. |
| FR-F3 | On registration the system shall compute a **file hash (MD5)**, count records, create a **File Log**, and move the file to a backup folder. |
| FR-F4 | The system shall reject **duplicate files** (identical hash) during registration/validation. |
| FR-F5 | The system shall load file rows into a **staging** table, **validate** them, **transform** them, and **bulk import** valid rows into the transaction store. |
| FR-F6 | The system shall capture **validation errors** per row (`IsValid`, `InvalidReason`) and bulk-import (BCP) errors to an error file. |
| FR-F7 | The system shall list File Logs (`GET /v1/file-logs`, filterable by `IsActive`). |
| FR-F8 | The system shall list file processing logs for a file (`GET /v1/file-process-logs/{LogId}`). |
| FR-F9 | The system shall allow downloading the original file (`GET /v1/files/download`), file data (`GET /v1/file-logs/data`), and bulk-error file (`GET /v1/files/bulk-errors/download`). |
| FR-F10 | The system shall surface validation errors as data (`GET /v1/files/validation-errors`) and their column metadata (`GET /v1/files/validation-errors/columns`). |
| FR-F11 | The system shall allow an Importer to **retry validation** on a failed file (`POST /v1/files/retry-validation`). |
| FR-F12 | The system shall allow an Importer to **cancel/delete** a file (`DELETE /v1/files`): deactivate the File Log, delete the physical file, and remove its staging/target transactions. |
| FR-F13 | The system shall log faults during processing and mark the affected File Log inactive on unrecoverable failure. |

### 6.3 File configuration / reference data
| ID | Requirement |
|----|-------------|
| FR-C1 | The system shall expose read endpoints for **file settings, sources, types, location types, locations, bulk-file-setting databases, bulk-file-settings, process definitions, and pages**. |
| FR-C2 | The system shall allow updating **file settings** (`PUT /v1/file-settings/{SettingId}`), **file locations** (`PUT /v1/file-locations/{LocationId}`), and **bulk-file settings** (`PUT /v1/bulk-file-settings/{BulkFileSettingId}`), each guarded against duplicate-record violations. |
| FR-C3 | A File Setting shall define how a file is parsed and routed (source, type, direction IN/OUT, staging schema/table, target schema/table, process definition). |

### 6.4 Transaction review
| ID | Requirement |
|----|-------------|
| FR-T1 | The system shall list all imported transactions (`GET /v1/transactions`) with their attributes and status. |
| FR-T2 | The system shall allow an Approver to **approve** a transaction (`POST /v1/transactions/approve`), transitioning `Imported` → `Approved`. |
| FR-T3 | The system shall allow an Approver to **reject** a transaction (`POST /v1/transactions/reject`) with a **mandatory note (`UserNote`)**, transitioning `Imported` → `Rejected`. |
| FR-T4 | The system shall record the acting user (`LastChangedUser`) and timestamp (`LastChangedDate`) on each approve/reject. |

### 6.5 User & access management
| ID | Requirement |
|----|-------------|
| FR-U1 | The system shall support **User** CRUD: list (`GET /v1/users`), get-by-id (`GET /v1/users/{Id}`), create (`POST /v1/users`), update (`PUT /v1/users/{Id}`), delete (`DELETE /v1/users/{Id}`). |
| FR-U2 | On user create/update, the system shall **encrypt (hash) the password** and enforce **unique email**. |
| FR-U3 | The system shall support **Role** CRUD: list (`GET /v1/roles`), create (`POST /v1/roles`), update (`PUT /v1/roles/{Id}`), delete (`DELETE /v1/roles/{Id}`). |
| FR-U4 | The system shall manage **user-to-role** and **role-to-page** associations (created/merged with the user/role, deleted with the user/role). |
| FR-U5 | The system shall list **pages** (`GET /v1/pages`) and resolve a user's accessible pages via the user→role→page mapping. |
| FR-U6 | User, role, and page mutations shall run within database transactions to keep associations consistent. |

---

## 7. Data Requirements

The database (SQL Server, default DB name **`Stadium8Training`**) contains three business areas plus the Linx process-automation engine schema.

### 7.1 `File` schema (file-import configuration & logs)
| Table | Purpose | Key fields |
|-------|---------|-----------|
| `File.Source` | File source lookup (e.g. *Bank*). | Id, Name, Description |
| `File.Type` | File type lookup (e.g. *Transaction*). | Id, Name, Description |
| `File.Setting` | How a file is parsed & routed. | Id, Name, SourceId→Source, TypeId→Type, ProcessDefinitionId, Direction (`IN`/`OUT`), StagingSchema/Table, TargetSchema/Table, IsActive |
| `File.LocationType` | Location type lookup (e.g. Inbox/Backup). | Id, Name |
| `File.Location` | Physical folder + filename per setting. | Id, SettingId→Setting, LocationTypeId→LocationType, FileName, Folder |
| `File.BulkSettingDatabase` | Server/DB for bulk operations. | Id, ServerName, DatabaseName |
| `File.BulkSetting` | BCP bulk-load configuration. | Id, SettingId→Setting, BulkSettingDatabaseId, SchemaName, TableName, ErrorFile, FormatFile, FirstRow, RowTerminator, FieldTerminator, QuotedIdentifier |
| `File.Log` | One record per ingested file. | Id, SettingId→Setting, ProcessInstanceId, CurrentFileName, CurrentFolder, FileHash (binary 16 / MD5), RecordCount, IsActive, BulkErrorFile |

All configuration tables carry audit fields `LastChangedUser`, `LastChangedDate`. Unique constraints enforce setting uniqueness (Source+Type+Direction), unique source/type/location-type names, and unique file locations.

### 7.2 Transaction store (`dbo` / `Staging` schemas)
**`dbo.Transaction`** — the target transaction record:
| Field | Type | Notes |
|-------|------|-------|
| Id | int (PK, identity) | |
| FileLogId | int → `File.Log` | Owning file |
| Reference | varchar(50) | Unique; format `TXN-YYYYMMDD-NNNN` (sample) |
| TransactionDate | datetime2 | |
| AccountNumber | varchar(50) | Sample format 4-4-4 hyphenated groups |
| Description | varchar(255) | Optional |
| Amount | decimal(18,2) | |
| TransactionType | varchar(10) | CHECK in (`Debit`, `Credit`) |
| Currency | varchar(3) | Default `ZAR` |
| Status | varchar(10) | CHECK in (`Imported`, `Approved`, `Rejected`); default `Imported` |
| UserNote | varchar(1000) | Captured on rejection |
| LastChangedUser | varchar(100) | Default `System` |
| LastChangedDate | datetime2 | Default `SYSDATETIME()` |

**`Staging.Transaction`** — raw/intermediate rows during import: mirrors the above as free-text (`VARCHAR(MAX)`) columns plus `TransformedTransactionType`, `IsValid` (bit), and `InvalidReason`. FK to `File.Log`.

> Source file transaction types use single-character codes `C` (Credit) / `D` (Debit), normalised during the **Transform** stage to `Credit` / `Debit`.

### 7.3 `UserManagement` schema (identity & RBAC)
| Table | Purpose | Key fields |
|-------|---------|-----------|
| `UserManagement.User` | System users. | Id, Email (unique), FirstName, LastName, PasswordHash (SHA-512) |
| `UserManagement.Role` | Roles. | Id, Name (unique) |
| `UserManagement.UserRole` | User↔Role (many-to-many). | UserId, RoleId (unique pair) |
| `UserManagement.Page` | Application pages/routes. | Id, Name (unique), Route |
| `UserManagement.RolePage` | Role↔Page grants. | RoleId, PageId (unique pair) |
| `UserManagement.Session` | Active login sessions. | Id, UserId, IpAddress, CreatedDate, ExpiryDate, LastAccessDate, Token (JWT) |
| `UserManagement.VwUserRolePage` | View joining user→role→page for access resolution. | UserId, Email, RoleId, RoleName, PageId, PageName |

### 7.4 Seed data
- Roles: **File Importer**, **Approver**.
- Page: **Transactions** (`/transactions`), granted to both roles.
- Users: `fileimporter@digiata.com` (File Importer), `approver@digiata.com` (Approver) — both with hashed password `Test123`.
- File reference data: Source *Bank*, Type *Transaction*, a *Transaction-Import* File Setting, location types, and inbox/backup locations.

### 7.5 Process-automation engine (`linx_processautomation*` schemas)
Linx's embedded workflow engine persists workflow definitions, instances, execution logs, bookmarks, triggers, and reporting views (`ProcessInstancesView`, `ProcessExecutionLogsView`). The **File Status** displayed to users is derived from the workflow instance's status and `LastExecutedActivityName`. This is platform infrastructure, not hand-authored business data, but it underpins the file-status lifecycle.

---

## 8. Business Rules

| ID | Rule |
|----|------|
| BR-01 | A transaction may only be **approved or rejected when its status is `Imported`**; terminal transactions (`Approved`/`Rejected`) cannot change status. |
| BR-02 | **Rejection requires a non-empty note** (`UserNote`). |
| BR-03 | `TransactionType` must be **`Debit` or `Credit`** (enforced by DB CHECK; source `D`/`C` normalised on transform). |
| BR-04 | `Status` must be one of **`Imported`, `Approved`, `Rejected`** (DB CHECK). |
| BR-05 | Transaction **`Reference` is unique**. |
| BR-06 | A **duplicate file** (same MD5 hash) must not be imported again. |
| BR-07 | A File Setting is **unique on Source + Type + Direction**; `Direction` must be `IN` or `OUT`. |
| BR-08 | **User email is unique**; passwords are stored only as **SHA-512 hashes**, never plain text. |
| BR-09 | A **user↔role** pair and a **role↔page** pair must each be unique. |
| BR-10 | Only an authenticated user with a **valid, non-expired session** may call protected endpoints; each call refreshes the session's last-access and expiry. |
| BR-11 | On a new login, the user's **previous sessions are removed** (single active session). |
| BR-12 | Cancelling a file **deactivates** it (`IsActive = 0`) and removes its transactions from the active working set rather than hard-deleting the audit trail of the log where applicable. |
| BR-13 | Every business mutation records **who** (`LastChangedUser`) and **when** (`LastChangedDate`). |
| BR-14 | Create/update operations that could violate uniqueness must return a **duplicate-record error** rather than failing silently. |

> Note: The accompanying front-end requirements additionally specify a strict RBAC split (Importer cannot approve/reject; Approver cannot upload/retry/cancel) and confirmation/step-up rules. The backend enforces authentication and data-level rules above; **role-level authorisation per endpoint is expected to be enforced by the consuming layer and/or extended in the backend** (see §11 Assumptions).

---

## 9. Interface (API) Requirements

Two HTTP services, both documented via Swagger/OpenAPI.

### 9.1 Authentication API — base `http://localhost:10010`
| Method & path | Purpose |
|---------------|---------|
| `POST /v1/auth/login` | Authenticate (email + password); issue session cookie. |
| `POST /v1/auth/logout` | Delete session(s); clear cookie. |
| `GET /v1/auth/userinfo` | Return authenticated user profile. |
| `GET /v1/health` | Health probe (unauthenticated). |

### 9.2 Transaction Management API — base `http://localhost:10005/transactions-api`
**Files**
| Method & path | Purpose |
|---------------|---------|
| `POST /v1/files/upload` | Upload a file for a File Setting and start import. |
| `GET /v1/file-logs` | List file logs (filter `IsActive`). |
| `GET /v1/file-process-logs/{LogId}` | List a file's process logs. |
| `GET /v1/file-logs/data` | Download file data. |
| `GET /v1/files/download` | Download original file. |
| `GET /v1/files/bulk-errors/download` | Download bulk-error file. |
| `GET /v1/files/validation-errors` | Validation errors as data. |
| `GET /v1/files/validation-errors/columns` | Validation-error column metadata. |
| `POST /v1/files/retry-validation` | Retry validation on a failed file. |
| `DELETE /v1/files` | Cancel/delete a file. |

**Reference data**
| Method & path | Purpose |
|---------------|---------|
| `GET /v1/file-settings`, `PUT /v1/file-settings/{SettingId}` | List / update file settings. |
| `GET /v1/file-sources` | List file sources. |
| `GET /v1/file-types` | List file types. |
| `GET /v1/file-location-types` | List location types. |
| `GET /v1/file-locations`, `PUT /v1/file-locations/{LocationId}` | List / update file locations. |
| `GET /v1/bulk-file-setting-databases` | List bulk-setting databases. |
| `GET /v1/bulk-file-settings`, `PUT /v1/bulk-file-settings/{BulkFileSettingId}` | List / update bulk settings. |
| `GET /v1/process-definitions` | List process definitions. |
| `GET /v1/pages` | List pages. |

**Transactions**
| Method & path | Purpose |
|---------------|---------|
| `GET /v1/transactions` | List transactions. |
| `POST /v1/transactions/approve` | Approve a transaction. |
| `POST /v1/transactions/reject` | Reject a transaction (with note). |

**Users & roles**
| Method & path | Purpose |
|---------------|---------|
| `GET /v1/users`, `GET /v1/users/{Id}`, `POST /v1/users`, `PUT /v1/users/{Id}`, `DELETE /v1/users/{Id}` | User CRUD. |
| `GET /v1/roles`, `POST /v1/roles`, `PUT /v1/roles/{Id}`, `DELETE /v1/roles/{Id}` | Role CRUD. |

### 9.3 Interface conventions
- All protected endpoints require a **valid session cookie** (set at login).
- Mutating endpoints accept a **`LastChangedUser`** header for audit attribution.
- Standard HTTP status codes: `200` success, `401` unauthorised/invalid credentials, and structured **duplicate-record / error** payloads on constraint violations.

---

## 10. Non-Functional Requirements

| Area | Requirement |
|------|-------------|
| **Security — auth** | Email/password login; SHA-512 password hashing; JWT session tokens; server-side session validation with expiry and last-access refresh. |
| **Security — data** | Passwords never returned or stored in clear text; account numbers/amounts exposed only to authenticated operators. |
| **Auditability** | `LastChangedUser` + `LastChangedDate` on business records; rejection notes retained; workflow execution logs retained by the engine. |
| **Integrity** | Foreign keys, unique indexes, and CHECK constraints enforce referential and value integrity at the database. |
| **Reliability** | File import wrapped in transactions and try/catch with fault logging; failed files retain validation/error detail and can be retried. |
| **Idempotency** | Duplicate files (by hash) are rejected to avoid double-import. |
| **Performance / volume** | Designed for ~10²–10⁴ transactions per file, daily upload cadence, small operations team (≈1–10 concurrent users). Bulk import uses BCP for throughput. |
| **Compliance** | Financial-services context (ZAR / South-Africa-style accounts) implies POPIA considerations for personal/financial data (policy-side). |
| **Deployability** | The application must be **buildable into a portable, self-contained artifact** (e.g. a standalone executable/service or container image) that runs on **any server** independent of the Linx Server runtime. The build output must be runnable as a **local test server** for verification. SQL Server schema is applied via the Database Updater tool (or an equivalent migration step bundled with the build); processing directories are configurable rather than hard-coded. The legacy Linx 6.12.1 deployment path remains supported but is **no longer the sole hosting option**. See §13. |
| **Portability** | No hard dependency on the Linx Server for hosting/execution of the built application. Environment-specific values (ports, DB connection string, file-processing directories, JWT secret) must be **externally configurable** (config file / environment variables) so the same artifact runs unchanged across servers. |

---

## 11. Assumptions, Constraints & Dependencies

### 11.1 Assumptions
- The backend is consumed by a separate front-end that enforces **role-specific navigation and UI gating**; fine-grained per-endpoint role authorisation is partly delegated to the consumer (the backend ships authentication, session, RBAC data, and the access-resolution view, but endpoint handlers primarily enforce authentication rather than role checks).
- Only one ingestion path (upload **or** directory-watch) is active at a time to avoid double-processing.
- The default seeded users/passwords are for **training/benchmark** use and would be replaced in production.

### 11.2 Constraints
- The application originates as a **Linx 6.12.1** low-code solution — logic is currently expressed as Linx services, events, and functions. To meet the revised deployment requirement, this logic must be **built/compiled or otherwise packaged into a portable runnable artifact** that does not require the Linx Server to host or execute it (see §13).
- Requires **SQL Server** for persistence; the connection must be **configurable** so the artifact can point at any reachable instance.
- Local processing directories (e.g. `C:\DigiataFileProcessing\...`) must be made **configurable** rather than hard-coded so the artifact runs on any server/OS path layout.
- Bulk import depends on **BCP** and format/error-file configuration per bulk setting; the build must bundle or document these dependencies so they are available wherever the artifact runs.

### 11.3 Dependencies
- **Build toolchain** capable of producing a portable runnable artifact from the source (and, where a container target is chosen, a container runtime such as Docker).
- SQL Server instance reachable via a **configurable connection string** (default schema/DB `Stadium8Training`).
- File-system access to **configurable** inbox/backup folders.
- The **Linx process-automation engine schema** is required only where the original Linx-hosted runtime is used; the portable artifact must either bundle an equivalent capability or run without it.
- Python and Node.js are referenced in the setup guide for tooling/front-end, not for the backend runtime itself.

---

## 12. Glossary

| Term | Definition |
|------|-----------|
| **File Log** | A record of one ingested file with its processing state, hash, and record count. |
| **File Status** | Derived lifecycle state of a file: `Uploaded` → `Processing` → `Completed` / `Failed`. |
| **File Setting** | Configuration defining how a file is parsed and routed (source, type, direction, staging/target, process). |
| **Transaction** | An individual financial record extracted from a file (reference, date, account, amount, type, currency, status). |
| **Transaction Status** | `Imported` (initial) → `Approved` / `Rejected` (terminal). |
| **Staging** | Intermediate table holding raw rows during validation/transformation before bulk import. |
| **BCP** | SQL Server Bulk Copy Program used to bulk-load validated rows into the target table. |
| **Session** | A server-side login record with a JWT token, expiry, and last-access timestamp. |
| **RBAC** | Role-Based Access Control via User→Role→Page mappings. |
| **Directory Watch** | Background service that auto-ingests files dropped into a monitored inbox folder. |
| **Process / Workflow** | The Linx `FileImportProcess` orchestrating Register → Load → Validate → Transform → Import. |
| **Linx** | Low-code automation platform on which the backend is built. |

---

## 13. Build, Packaging & Hosting Requirements

> This section captures the **revised deployment requirement**: the application must be buildable and runnable independently of the Linx Server, so it can be tested on any server or via a locally started test server.

### 13.1 Goals
| ID | Requirement |
|----|-------------|
| BH-1 | The application shall be **built** from source into a **portable, self-contained runnable artifact** (e.g. a standalone executable/service, or a container image) — **not** something that can only be deployed into a Linx Server. |
| BH-2 | The built artifact shall be **runnable on any server** that meets the documented prerequisites (a supported OS/runtime and a reachable SQL Server), with **no installation of the Linx Server runtime** required to host or execute it. |
| BH-3 | The build shall produce a way to **start a local test server** with a single, documented command, so the application can be verified end-to-end on a developer machine or CI agent. |
| BH-4 | The two API surfaces (Authentication and Transaction Management) shall remain available from the built artifact at **configurable ports** (defaults `10010` / `10005`), exposing the same endpoints and Swagger/OpenAPI documentation described in §9. |
| BH-5 | All environment-specific settings shall be **externally configurable** — at minimum: HTTP ports, the SQL Server connection string, file-processing directories (inbox/backup), and the JWT signing secret — via a config file and/or environment variables, with sensible documented defaults for the test server. |
| BH-6 | The database schema shall be provisioned by a **repeatable, bundled step** (the existing SQL build scripts / Database Updater, or an equivalent migration runner invoked as part of setup) so a fresh environment can be stood up reproducibly. |
| BH-7 | The build and run procedure shall be **documented** (prerequisites, build command, run/test-server command, configuration reference, and how to point at a SQL Server). |
| BH-8 | Backward compatibility: the original **Linx Server deployment path remains supported** as one option, but it is no longer the only supported hosting model. |

### 13.2 Acceptance criteria
- A clean checkout can be **built** with the documented command and produces the portable artifact.
- The artifact can be **started as a test server** locally; `GET /v1/health` returns success and the Swagger pages load for both services.
- Login with a seeded user (`fileimporter@digiata.com` / `approver@digiata.com`) succeeds and a protected endpoint (e.g. `GET /v1/transactions`) is reachable with the issued session.
- The same artifact, given different configuration (ports, connection string, directories), runs unchanged on a **second/target server** — demonstrating it is not bound to the Linx Server.
- File ingestion (upload and/or directory-watch) and the approve/reject flows operate against the configured SQL Server.

### 13.3 Notes / options (non-prescriptive)
The choice of target technology is an implementation decision. Options include: exporting/compiling the Linx solution to a self-hostable service, re-hosting the equivalent logic in a portable web service (e.g. a .NET/Node service exposing the same endpoints), and/or packaging either as a **container image** for "run anywhere" portability. Whichever is chosen must satisfy BH-1…BH-8 above.

---

## Appendix A — Source artefacts reviewed
- `backend-api/README.md` — purpose, setup, endpoint summary, test instructions.
- `backend-api/Src/Api/TransactionManagement.project/...` — Linx solution (Authentication service, TransactionManagement service, FileImportPattern, directory-watch).
- `backend-api/Src/Db/*.sql` — database build scripts (File module, Transaction/Staging tables, UserManagement schema & seed data, Linx engine schema).
- `backend-api/TestFiles/transactions_2026-04-15.csv` — sample transaction file.
- `frontend/docs/requirements-2c.md`, `PrototypeBriefV2.md`, `*.yaml` — supporting domain & API context.
