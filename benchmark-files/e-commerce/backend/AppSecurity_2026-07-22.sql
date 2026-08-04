/* =====================================================================
   AppSecurity - application identity & RBAC layer
   For the E-commerce Online Store benchmark (see Backend-API-BRD.md §7.4-§7.5, §4.2).

   AdventureWorks 2019 does not model online-store login roles, so this thin
   schema is added on top of it: AppRole, AppUser, Session.

   RUN ORDER: run AFTER one of the slice scripts
     - AdventureWorks2019_ecommerce-slice_2026-07-22.sql        (lean), or
     - AdventureWorks2019_ecommerce-slice-fk_2026-07-22.sql     (FK-complete)
   because AppUser.CustomerID references Sales.Customer, and the seed links the
   Customer login to the demo customer (CustomerID 90000) created by the slice.

   Password hashing (benchmark convention):
     PasswordHash = HASHBYTES('SHA2_512', <password>)   -- raw 64-byte SHA-512
   The application's login must hash the supplied password the same way
   (SHA-512 over the ASCII/varchar bytes) and compare against PasswordHash.
   Seeded password for both users is 'Test123'.
   ===================================================================== */
SET NOCOUNT ON;
GO
IF SCHEMA_ID('AppSecurity') IS NULL EXEC('CREATE SCHEMA [AppSecurity]');
GO

/* ---- Roles ---- */
CREATE TABLE [AppSecurity].[AppRole](
    [Id]              int IDENTITY(1,1) NOT NULL CONSTRAINT [PK_AppRole] PRIMARY KEY,
    [Name]            nvarchar(50) NOT NULL CONSTRAINT [UQ_AppRole_Name] UNIQUE,
    [LastChangedUser] nvarchar(100) NOT NULL CONSTRAINT [DF_AppRole_LCU] DEFAULT (SUSER_SNAME()),
    [ModifiedDate]    datetime NOT NULL CONSTRAINT [DF_AppRole_MD] DEFAULT (SYSDATETIME())
);
GO

/* ---- Users (email unique; password stored only as SHA-512 hash; optional link to a Customer) ---- */
CREATE TABLE [AppSecurity].[AppUser](
    [Id]              int IDENTITY(1,1) NOT NULL CONSTRAINT [PK_AppUser] PRIMARY KEY,
    [Email]           nvarchar(256) NOT NULL CONSTRAINT [UQ_AppUser_Email] UNIQUE,
    [FirstName]       nvarchar(64) NOT NULL,
    [LastName]        nvarchar(64) NOT NULL,
    [PasswordHash]    varbinary(64) NOT NULL,                 -- SHA-512 = 64 bytes
    [RoleId]          int NOT NULL,
    [CustomerID]      int NULL,                               -- set for Customer role; NULL for Admin
    [IsActive]        bit NOT NULL CONSTRAINT [DF_AppUser_IsActive] DEFAULT (1),
    [LastChangedUser] nvarchar(100) NOT NULL CONSTRAINT [DF_AppUser_LCU] DEFAULT (SUSER_SNAME()),
    [ModifiedDate]    datetime NOT NULL CONSTRAINT [DF_AppUser_MD] DEFAULT (SYSDATETIME()),
    CONSTRAINT [FK_AppUser_AppRole]  FOREIGN KEY ([RoleId])     REFERENCES [AppSecurity].[AppRole]([Id]),
    CONSTRAINT [FK_AppUser_Customer] FOREIGN KEY ([CustomerID]) REFERENCES [Sales].[Customer]([CustomerID])
);
GO

/* ---- Sessions (single active session per user is enforced by the app: BR-14) ---- */
CREATE TABLE [AppSecurity].[Session](
    [Id]             uniqueidentifier NOT NULL CONSTRAINT [DF_Session_Id] DEFAULT (NEWID())
                                      CONSTRAINT [PK_Session] PRIMARY KEY,
    [AppUserId]      int NOT NULL,
    [IpAddress]      nvarchar(45) NULL,                       -- IPv4/IPv6
    [Token]          nvarchar(max) NOT NULL,                  -- JWT
    [CreatedDate]    datetime NOT NULL CONSTRAINT [DF_Session_Created] DEFAULT (SYSDATETIME()),
    [ExpiryDate]     datetime NOT NULL,
    [LastAccessDate] datetime NOT NULL CONSTRAINT [DF_Session_LastAccess] DEFAULT (SYSDATETIME()),
    CONSTRAINT [FK_Session_AppUser] FOREIGN KEY ([AppUserId]) REFERENCES [AppSecurity].[AppUser]([Id])
);
GO
CREATE INDEX [IX_Session_AppUserId] ON [AppSecurity].[Session]([AppUserId]);
GO

/* ---- Seed: roles + the two benchmark users (password 'Test123') ---- */
INSERT INTO [AppSecurity].[AppRole] ([Name]) VALUES (N'Customer'), (N'Admin');
GO
INSERT INTO [AppSecurity].[AppUser] ([Email],[FirstName],[LastName],[PasswordHash],[RoleId],[CustomerID])
VALUES
 (N'customer@adventureworks.com', N'Alex', N'Customer',
    HASHBYTES('SHA2_512','Test123'),
    (SELECT Id FROM [AppSecurity].[AppRole] WHERE Name = N'Customer'),
    90000),                                                  -- demo customer from the slice
 (N'admin@adventureworks.com', N'Sam', N'Admin',
    HASHBYTES('SHA2_512','Test123'),
    (SELECT Id FROM [AppSecurity].[AppRole] WHERE Name = N'Admin'),
    NULL);
GO
