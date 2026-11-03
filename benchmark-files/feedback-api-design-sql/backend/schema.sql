-- FeedbackWall — SQL Server schema + seed for the standalone API.
-- The API (server.mjs) reads/writes this table; the frontend never touches it directly.
-- Apply with sqlcmd / Azure Data Studio against your target database, e.g.:
--   sqlcmd -S localhost -d FeedbackWall -i schema.sql
-- (create the database first:  CREATE DATABASE FeedbackWall;)

IF OBJECT_ID('dbo.Messages', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.Messages (
    id        UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Messages_id DEFAULT NEWID(),
    author    NVARCHAR(200)    NOT NULL,
    body      NVARCHAR(MAX)    NOT NULL,
    createdAt DATETIME2(3)     NOT NULL CONSTRAINT DF_Messages_createdAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Messages PRIMARY KEY (id)
  );
  CREATE INDEX IX_Messages_createdAt ON dbo.Messages (createdAt DESC);
END;
GO

-- Seed a couple of rows if the table is empty (matches the mock-only fixtures).
IF NOT EXISTS (SELECT 1 FROM dbo.Messages)
BEGIN
  INSERT INTO dbo.Messages (id, author, body, createdAt) VALUES
    (NEWID(), N'Ada',   N'Love this!',  '2026-05-01T09:00:00.000'),
    (NEWID(), N'Grace', N'Very handy.', '2026-04-30T14:30:00.000');
END;
GO
