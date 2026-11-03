# FeedbackWall standalone API — SQL Server backed

The two endpoints in `api.yaml` (`GET`/`POST /api/v1/messages`) persist to a **SQL Server**
database. The frontend talks only to this API over HTTP — it never connects to SQL Server directly.

## Run it for real

1. **Create the database and schema** (once):
   ```sql
   CREATE DATABASE FeedbackWall;
   ```
   then apply the DDL + seed:
   ```sh
   sqlcmd -S localhost -d FeedbackWall -i schema.sql
   ```
2. **Install the driver** (the server's only dependency):
   ```sh
   npm i mssql
   ```
3. **Start the server** with connection env vars:
   ```sh
   SQLSERVER_HOST=localhost SQLSERVER_PASSWORD=YourStrong!Passw0rd \
   SQLSERVER_DATABASE=FeedbackWall SQLSERVER_ENCRYPT=false \
   node server.mjs
   # Feedback API (SQL Server) on http://localhost:4010
   ```

## Env vars

| Var | Default | Notes |
|---|---|---|
| `SQLSERVER_HOST` | `localhost` | |
| `SQLSERVER_PORT` | `1433` | |
| `SQLSERVER_USER` | `sa` | |
| `SQLSERVER_PASSWORD` | — | **required** |
| `SQLSERVER_DATABASE` | `FeedbackWall` | |
| `SQLSERVER_ENCRYPT` | `true` | set `false` for a local dev box |

A quick local server via Docker:
```sh
docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=YourStrong!Passw0rd' \
  -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```

## Table

`dbo.Messages (id UNIQUEIDENTIFIER PK, author NVARCHAR(200), body NVARCHAR(MAX), createdAt DATETIME2)`
— listed newest first (`ORDER BY createdAt DESC`). See `schema.sql`.
