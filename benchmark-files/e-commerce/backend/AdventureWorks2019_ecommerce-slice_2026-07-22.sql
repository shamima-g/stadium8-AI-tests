/* =====================================================================
   AdventureWorks2019 - E-COMMERCE SLICE (schema + seed data)
   Generated 2026-07-22 for the E-commerce Online Store benchmark.

   Contents
   - User-defined types + schemas used by the slice
   - FULL real data: Production.ProductCategory / ProductSubcategory /
     Product / ProductInventory, Purchasing.ShipMethod, Sales.SpecialOffer,
     Sales.ShoppingCartItem  (the storefront catalogue + reference + cart)
   - Project-scoped table definitions + a small demo customer & order for
     Sales.Customer, Person.Person/EmailAddress/Address/BusinessEntityAddress,
     Sales.SalesOrderHeader / SalesOrderDetail  (populated at runtime by the app)

   NOTE: Foreign keys are intentionally omitted so the slice is self-contained
   and load-order-independent. The big transactional tables are project-scoped
   subsets (per BRD s7), not the full AdventureWorks definitions.
   Run against a fresh, empty database.
   ===================================================================== */
SET NOCOUNT ON;
GO
IF SCHEMA_ID('Production') IS NULL EXEC('CREATE SCHEMA [Production]');
IF SCHEMA_ID('Sales')      IS NULL EXEC('CREATE SCHEMA [Sales]');
IF SCHEMA_ID('Purchasing') IS NULL EXEC('CREATE SCHEMA [Purchasing]');
IF SCHEMA_ID('Person')     IS NULL EXEC('CREATE SCHEMA [Person]');
GO
IF TYPE_ID('[dbo].[Name]')          IS NULL CREATE TYPE [dbo].[Name] FROM nvarchar(50) NULL;
IF TYPE_ID('[dbo].[Flag]')          IS NULL CREATE TYPE [dbo].[Flag] FROM bit NOT NULL;
IF TYPE_ID('[dbo].[NameStyle]')     IS NULL CREATE TYPE [dbo].[NameStyle] FROM bit NOT NULL;
IF TYPE_ID('[dbo].[AccountNumber]') IS NULL CREATE TYPE [dbo].[AccountNumber] FROM nvarchar(15) NULL;
IF TYPE_ID('[dbo].[OrderNumber]')   IS NULL CREATE TYPE [dbo].[OrderNumber] FROM nvarchar(25) NULL;
IF TYPE_ID('[dbo].[Phone]')         IS NULL CREATE TYPE [dbo].[Phone] FROM nvarchar(25) NULL;
GO
/* ---- Catalogue / reference / cart : real AdventureWorks schema + full data ---- */
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Production].[ProductCategory](
	[ProductCategoryID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [dbo].[Name] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ProductCategory_ProductCategoryID] PRIMARY KEY CLUSTERED 
(
	[ProductCategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Production].[ProductSubcategory](
	[ProductSubcategoryID] [int] IDENTITY(1,1) NOT NULL,
	[ProductCategoryID] [int] NOT NULL,
	[Name] [dbo].[Name] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ProductSubcategory_ProductSubcategoryID] PRIMARY KEY CLUSTERED 
(
	[ProductSubcategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Production].[Product](
	[ProductID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [dbo].[Name] NOT NULL,
	[ProductNumber] [nvarchar](25) NOT NULL,
	[MakeFlag] [dbo].[Flag] NOT NULL,
	[FinishedGoodsFlag] [dbo].[Flag] NOT NULL,
	[Color] [nvarchar](15) NULL,
	[SafetyStockLevel] [smallint] NOT NULL,
	[ReorderPoint] [smallint] NOT NULL,
	[StandardCost] [money] NOT NULL,
	[ListPrice] [money] NOT NULL,
	[Size] [nvarchar](5) NULL,
	[SizeUnitMeasureCode] [nchar](3) NULL,
	[WeightUnitMeasureCode] [nchar](3) NULL,
	[Weight] [decimal](8, 2) NULL,
	[DaysToManufacture] [int] NOT NULL,
	[ProductLine] [nchar](2) NULL,
	[Class] [nchar](2) NULL,
	[Style] [nchar](2) NULL,
	[ProductSubcategoryID] [int] NULL,
	[ProductModelID] [int] NULL,
	[SellStartDate] [datetime] NOT NULL,
	[SellEndDate] [datetime] NULL,
	[DiscontinuedDate] [datetime] NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Product_ProductID] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Production].[ProductInventory](
	[ProductID] [int] NOT NULL,
	[LocationID] [smallint] NOT NULL,
	[Shelf] [nvarchar](10) NOT NULL,
	[Bin] [tinyint] NOT NULL,
	[Quantity] [smallint] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ProductInventory_ProductID_LocationID] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC,
	[LocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Purchasing].[ShipMethod](
	[ShipMethodID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [dbo].[Name] NOT NULL,
	[ShipBase] [money] NOT NULL,
	[ShipRate] [money] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ShipMethod_ShipMethodID] PRIMARY KEY CLUSTERED 
(
	[ShipMethodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Sales].[SpecialOffer](
	[SpecialOfferID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[DiscountPct] [smallmoney] NOT NULL,
	[Type] [nvarchar](50) NOT NULL,
	[Category] [nvarchar](50) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[MinQty] [int] NOT NULL,
	[MaxQty] [int] NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_SpecialOffer_SpecialOfferID] PRIMARY KEY CLUSTERED 
(
	[SpecialOfferID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Sales].[ShoppingCartItem](
	[ShoppingCartItemID] [int] IDENTITY(1,1) NOT NULL,
	[ShoppingCartID] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[DateCreated] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ShoppingCartItem_ShoppingCartItemID] PRIMARY KEY CLUSTERED 
(
	[ShoppingCartItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET IDENTITY_INSERT [Production].[ProductCategory] ON 

GO
INSERT [Production].[ProductCategory] ([ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (1, N'Bikes', N'cfbda25c-df71-47a7-b81b-64ee161aa37c', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductCategory] ([ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (2, N'Components', N'c657828d-d808-4aba-91a3-af2ce02300e9', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductCategory] ([ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (3, N'Clothing', N'10a7c342-ca82-48d4-8a38-46a2eb089b74', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductCategory] ([ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (4, N'Accessories', N'2be3be36-d9a2-4eee-b593-ed895d97c2a6', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
SET IDENTITY_INSERT [Production].[ProductCategory] OFF
GO
SET IDENTITY_INSERT [Production].[ProductSubcategory] ON 

GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (1, 1, N'Mountain Bikes', N'2d364ade-264a-433c-b092-4fcbf3804e01', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (2, 1, N'Road Bikes', N'000310c0-bcc8-42c4-b0c3-45ae611af06b', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (3, 1, N'Touring Bikes', N'02c5061d-ecdc-4274-b5f1-e91d76bc3f37', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (4, 2, N'Handlebars', N'3ef2c725-7135-4c85-9ae6-ae9a3bdd9283', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (5, 2, N'Bottom Brackets', N'a9e54089-8a1e-4cf5-8646-e3801f685934', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (6, 2, N'Brakes', N'd43ba4a3-ef0d-426b-90eb-4be4547dd30c', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (7, 2, N'Chains', N'e93a7231-f16c-4b0f-8c41-c73fdec62da0', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (8, 2, N'Cranksets', N'4f644521-422b-4f19-974a-e3df6102567e', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (9, 2, N'Derailleurs', N'1830d70c-aa2a-40c0-a271-5ba86f38f8bf', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (10, 2, N'Forks', N'b5f9ba42-b69b-4fdd-b2ec-57fb7b42e3cf', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (11, 2, N'Headsets', N'7c782bbe-5a16-495a-aa50-10afe5a84af2', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (12, 2, N'Mountain Frames', N'61b21b65-e16a-4be7-9300-4d8e9db861be', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (13, 2, N'Pedals', N'6d24ac07-7a84-4849-864a-865a14125bc9', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (14, 2, N'Road Frames', N'5515f857-075b-4f9a-87b7-43b4997077b3', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (15, 2, N'Saddles', N'049fffa3-9d30-46df-82f7-f20730ec02b3', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (16, 2, N'Touring Frames', N'd2e3f1a8-56c4-4f36-b29d-5659fc0d2789', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (17, 2, N'Wheels', N'43521287-4b0b-438e-b80e-d82d9ad7c9f0', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (18, 3, N'Bib-Shorts', N'67b58d2b-5798-4a90-8c6c-5ddacf057171', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (19, 3, N'Caps', N'430dd6a8-a755-4b23-bb05-52520107da5f', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (20, 3, N'Gloves', N'92d5657b-0032-4e49-bad5-41a441a70942', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (21, 3, N'Jerseys', N'09e91437-ba4f-4b1a-8215-74184fd95db8', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (22, 3, N'Shorts', N'1a5ba5b3-03c3-457c-b11e-4fa85ede87da', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (23, 3, N'Socks', N'701019c3-09fe-4949-8386-c6ce686474e5', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (24, 3, N'Tights', N'5deb3e55-9897-4416-b18a-515e970bc2d1', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (25, 3, N'Vests', N'9ad7fe93-5ba0-4736-b578-ff80a2071297', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (26, 4, N'Bike Racks', N'4624b5ce-66d6-496b-9201-c053df3556cc', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (27, 4, N'Bike Stands', N'43b445c8-b820-424e-a1d5-90d81da0b46f', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (28, 4, N'Bottles and Cages', N'9b7dff41-9fa3-4776-8def-2c9a48c8b779', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (29, 4, N'Cleaners', N'9ad3bcf0-244d-4ec4-a6a0-fb701351c6a3', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (30, 4, N'Fenders', N'1697f8a2-0a08-4883-b7dd-d19117b4e9a7', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (31, 4, N'Helmets', N'f5e07a33-c9e0-439c-b5f3-9f25fb65becc', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (32, 4, N'Hydration Packs', N'646a8906-fc87-4267-a443-9c6d791e6693', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (33, 4, N'Lights', N'954178ba-624f-42db-95f6-ca035f36d130', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (34, 4, N'Locks', N'19646983-3fa0-4773-9a0c-f34c49df9bc8', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (35, 4, N'Panniers', N'3002a5d5-fec3-464b-bef3-e0f81d35f431', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (36, 4, N'Pumps', N'fe4d46f2-c87c-48c5-a4a1-3f55712d80b1', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductSubcategory] ([ProductSubcategoryID], [ProductCategoryID], [Name], [rowguid], [ModifiedDate]) VALUES (37, 4, N'Tires and Tubes', N'3c17c9ae-e906-48b4-bdd3-60e28d47dcdf', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
SET IDENTITY_INSERT [Production].[ProductSubcategory] OFF
GO
SET IDENTITY_INSERT [Production].[Product] ON 

GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (1, N'Adjustable Race', N'AR-5381', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'694215b7-08f7-4c0d-acb1-d734ba44c0c8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (2, N'Bearing Ball', N'BA-8327', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'58ae3c20-4f3a-4749-a7d4-d568806cc537', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (3, N'BB Ball Bearing', N'BE-2349', 1, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9c21aed2-5bfa-4f18-bcb8-f11638dc2e4e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (4, N'Headset Ball Bearings', N'BE-2908', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ecfed6cb-51ff-49b5-b06c-7d8ac834db8b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (316, N'Blade', N'BL-2036', 1, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'e73e9750-603b-4131-89f5-3dd15ed5ff80', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (317, N'LL Crankarm', N'CA-5965', 0, 0, N'Black', 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'3c9d10b7-a6b2-4774-9963-c19dcee72fea', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (318, N'ML Crankarm', N'CA-6738', 0, 0, N'Black', 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, N'M ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'eabb9a92-fa07-4eab-8955-f0517b4a4ca7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (319, N'HL Crankarm', N'CA-7457', 0, 0, N'Black', 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7d3fd384-4f29-484b-86fa-4206e276fe58', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (320, N'Chainring Bolts', N'CB-2903', 0, 0, N'Silver', 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7be38e48-b7d6-4486-888e-f53c26735101', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (321, N'Chainring Nut', N'CN-6137', 0, 0, N'Silver', 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'3314b1d7-ef69-4431-b6dd-dc75268bd5df', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (322, N'Chainring', N'CR-7833', 0, 0, N'Black', 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'f0ac2c4d-1a1f-4e3c-b4d9-68aea0ec1ce4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (323, N'Crown Race', N'CR-9981', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'51a32ca6-65a1-4c31-af2b-d9e4f5d631d4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (324, N'Chain Stays', N'CS-2812', 1, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'fe0678ed-aef2-4c58-a450-8151cc24ddd8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (325, N'Decal 1', N'DC-8732', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'05ce123c-a402-478e-ae9b-75d7727aeaad', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (326, N'Decal 2', N'DC-9824', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a56851f9-1cd7-4e2f-8779-2e773e1b5209', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (327, N'Down Tube', N'DT-2377', 1, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1dad47dd-e259-42b8-b8b4-15a0b7d21b2f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (328, N'Mountain End Caps', N'EC-M092', 1, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'6070b1ea-59b7-4f8b-950f-2be07d00449d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (329, N'Road End Caps', N'EC-R098', 1, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'88399d13-719e-4545-81d6-f0650f372fa2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (330, N'Touring End Caps', N'EC-T209', 1, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'6903ce24-d0ce-4191-9198-4231de37a929', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (331, N'Fork End', N'FE-3760', 1, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'c91d602e-da52-43d2-bd7e-eb110a9392b9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (332, N'Freewheel', N'FH-2981', 0, 0, N'Silver', 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'd864879a-e8b1-4f7b-bafa-1f136089c2c8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (341, N'Flat Washer 1', N'FW-1000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a3f2fa3a-22e1-43d8-a131-a9b89c32d8ea', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (342, N'Flat Washer 6', N'FW-1200', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'331addec-e9b9-4a7e-9324-42069c2dcdc4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (343, N'Flat Washer 2', N'FW-1400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'84a3473e-ae26-4a21-81b9-60bb418a79b2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (344, N'Flat Washer 9', N'FW-3400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'0ae4ce60-5242-48f5-ada1-3013ff45f969', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (345, N'Flat Washer 4', N'FW-3800', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'2c1c58b4-234c-4b3a-8c8e-84524ac05eea', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (346, N'Flat Washer 3', N'FW-5160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'590c2c3f-a8b6-42b5-9412-d655e37f0eae', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (347, N'Flat Washer 8', N'FW-5800', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1b73f5fe-ab85-49fc-99ad-0500cebda91d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (348, N'Flat Washer 5', N'FW-7160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'd182cf18-4ddf-429b-a0df-de1cfc92622d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (349, N'Flat Washer 7', N'FW-9160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7e55f64d-ea3c-45ff-be72-f7f7b9d61a79', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (350, N'Fork Crown', N'FC-3654', 1, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1cbfa85b-5c9b-4b58-9c17-95238215d926', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (351, N'Front Derailleur Cage', N'FC-3982', 0, 0, N'Silver', 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'01c901e3-4323-48ed-ab9e-9bfda28bdef6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (352, N'Front Derailleur Linkage', N'FL-2301', 0, 0, N'Silver', 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'88ed2e08-e775-4915-b506-831600b773fd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (355, N'Guide Pulley', N'GP-0982', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'6a89205b-90c3-4997-8c63-bc6a5ebc752d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (356, N'LL Grip Tape', N'GT-0820', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'32c82181-1969-4660-ae04-a02d51994ec1', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (357, N'ML Grip Tape', N'GT-1209', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, N'M ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'09343e22-2494-4279-9f32-5d961a0fbfea', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (358, N'HL Grip Tape', N'GT-2908', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'8e5b2bf7-81dd-4454-b75e-d9ae2a6fbd26', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (359, N'Thin-Jam Hex Nut 9', N'HJ-1213', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a63aff3c-4143-4016-bc99-d3f80ec1ade5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (360, N'Thin-Jam Hex Nut 10', N'HJ-1220', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a1ae0c6d-92a5-4fda-b33b-1301e83efe5b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (361, N'Thin-Jam Hex Nut 1', N'HJ-1420', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'e33e8c4c-282a-4d1f-91e7-e9969cf7134f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (362, N'Thin-Jam Hex Nut 2', N'HJ-1428', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a992684f-4642-4856-a817-2c0740ae8c55', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (363, N'Thin-Jam Hex Nut 15', N'HJ-3410', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'b9d9a30d-cb07-422d-a312-f0535575337e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (364, N'Thin-Jam Hex Nut 16', N'HJ-3416', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'0ec8f653-24c9-41b6-86f5-39c1789db580', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (365, N'Thin-Jam Hex Nut 5', N'HJ-3816', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'94506c9d-5991-46a7-82ea-00e05d8d9b9c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (366, N'Thin-Jam Hex Nut 6', N'HJ-3824', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'71e984c6-1d11-4cf2-baee-6c8df494bdad', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (367, N'Thin-Jam Hex Nut 3', N'HJ-5161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'efc09cdb-ecd5-4db5-9e27-277dda6d7f50', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (368, N'Thin-Jam Hex Nut 4', N'HJ-5162', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'0a0c93aa-d06c-48aa-99eb-20f2c8a6d6c4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (369, N'Thin-Jam Hex Nut 13', N'HJ-5811', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a2728648-9517-4dec-8606-d7d98ecd1e91', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (370, N'Thin-Jam Hex Nut 14', N'HJ-5818', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'0a7ad37c-3696-4844-8633-9fddcd5fcefc', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (371, N'Thin-Jam Hex Nut 7', N'HJ-7161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'acbb1de1-680c-4034-a8c5-3c6b01e57aa7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (372, N'Thin-Jam Hex Nut 8', N'HJ-7162', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a0da8f8f-45fb-4e62-ab14-aa229087de1e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (373, N'Thin-Jam Hex Nut 12', N'HJ-9080', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'db99cbcd-f18d-4979-8dcf-1012f3b1cb15', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (374, N'Thin-Jam Hex Nut 11', N'HJ-9161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ec2e54f5-9d07-4c26-b969-40f835395be3', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (375, N'Hex Nut 5', N'HN-1024', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'f2f3a14c-df15-4957-966d-55e5fcad1161', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (376, N'Hex Nut 6', N'HN-1032', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'e73e44dd-f0b7-45d4-9066-e49f1b1fe7d0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (377, N'Hex Nut 16', N'HN-1213', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'2b2a5641-bffe-4079-b9f0-8bf355bc3996', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (378, N'Hex Nut 17', N'HN-1220', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'f70bbecd-5be7-4ee9-a9e7-15786e622ba9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (379, N'Hex Nut 7', N'HN-1224', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ba3631d1-33d6-4a2f-8413-758bfda6f9c2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (380, N'Hex Nut 8', N'HN-1420', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'b478b33a-1fd5-4db6-b99a-eb3b2a7c1623', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (381, N'Hex Nut 9', N'HN-1428', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'da46d979-59df-456d-b5ae-e7e89fc589df', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (382, N'Hex Nut 22', N'HN-3410', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'2f457404-197d-4ddf-9868-a3aad1b32d6b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (383, N'Hex Nut 23', N'HN-3416', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'5f02449e-96e5-4fc8-ade0-8a9a7f533624', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (384, N'Hex Nut 12', N'HN-3816', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'32c97696-7c3d-4793-a54b-3d73200badbc', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (385, N'Hex Nut 13', N'HN-3824', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'8f0902d0-274d-4a4b-8fde-e37f53b2ab29', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (386, N'Hex Nut 1', N'HN-4402', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'57456f8c-cb78-45ec-b9b8-21a9be5c12f5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (387, N'Hex Nut 10', N'HN-5161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'955811b4-2f17-48f0-a8b4-0c96cba4aa6d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (388, N'Hex Nut 11', N'HN-5162', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7d4bad17-374f-4281-9ae5-49abc3fe585d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (389, N'Hex Nut 2', N'HN-5400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'17c4b7ba-8574-4ec7-bd3b-7a51aba61f69', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (390, N'Hex Nut 20', N'HN-5811', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'b4e990b7-b3f7-4f97-8f98-ce373833adb4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (391, N'Hex Nut 21', N'HN-5818', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'433ee702-e028-4630-895c-8cdbd0f1fd89', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (392, N'Hex Nut 3', N'HN-6320', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ee76fae0-161e-409c-a6f5-837b5b8b344d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (393, N'Hex Nut 14', N'HN-7161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'eb10b88c-5351-4c06-af51-116baa48a2c8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (394, N'Hex Nut 15', N'HN-7162', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'35e28755-e8f0-47be-a8be-a20836dbe28d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (395, N'Hex Nut 4', N'HN-8320', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'69ab8d5e-6101-4203-81b1-794e923782ea', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (396, N'Hex Nut 18', N'HN-9161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'39d42384-66f6-4ccd-b471-0589fc3fc576', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (397, N'Hex Nut 19', N'HN-9168', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'b63f827e-9055-4678-9e90-4ffd8d06d4d4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (398, N'Handlebar Tube', N'HT-2981', 1, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9f88c58e-5cfa-46c9-8994-da4f3ffe92ed', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (399, N'Head Tube', N'HT-8019', 1, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'b047c048-b4fb-4f80-94bc-c5fc00a6f77f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (400, N'LL Hub', N'HU-6280', 1, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ab332dda-dda5-44ad-8c50-34ffaceffa8e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (401, N'HL Hub', N'HU-8998', 1, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'd59403a3-d19e-4803-bda2-b436a6416fda', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (402, N'Keyed Washer', N'KW-4091', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'43024784-2741-4cab-a6dc-8050ce507f2e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (403, N'External Lock Washer 3', N'LE-1000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'763412f0-6d53-43e2-b371-dcbed69f5e98', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (404, N'External Lock Washer 4', N'LE-1200', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'89b6e84f-5c08-4cd9-b803-01f2ce24e417', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (405, N'External Lock Washer 9', N'LE-1201', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'3330a721-e8cb-4e67-8d27-300db68c2395', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (406, N'External Lock Washer 5', N'LE-1400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'39314098-768b-49f9-a777-af2e3bb06b17', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (407, N'External Lock Washer 7', N'LE-3800', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'93f7bc73-bd22-45a0-9f2e-a11932342e6b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (408, N'External Lock Washer 6', N'LE-5160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'dc5f4cb0-a599-42cd-a96f-e9f01bc1dacc', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (409, N'External Lock Washer 1', N'LE-6000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'802b7687-bc74-43f8-98ae-2112166faca7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (410, N'External Lock Washer 8', N'LE-7160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'02c48826-21ad-41f3-85a6-bc9a85a4dce4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (411, N'External Lock Washer 2', N'LE-8000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'502a2a3d-cd72-43ad-8fb6-77505187edf4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (412, N'Internal Lock Washer 3', N'LI-1000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'f1168c45-e4d2-4c37-adad-b76eaf402b71', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (413, N'Internal Lock Washer 4', N'LI-1200', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7f7413bb-bad2-47e4-9bc4-d98b194be35d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (414, N'Internal Lock Washer 9', N'LI-1201', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'4f040109-8332-4fcf-8084-57e6d8c49283', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (415, N'Internal Lock Washer 5', N'LI-1400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'0c02f2cc-bdb4-4794-a4f9-0eb33f7545c2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (416, N'Internal Lock Washer 7', N'LI-3800', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'3c2ac5bc-3f49-4fa4-8340-bc4cda983f46', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (417, N'Internal Lock Washer 6', N'LI-5160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7f175dfe-1669-4ee9-8eeb-7b55fce9961c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (418, N'Internal Lock Washer 10', N'LI-5800', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'c8323eec-bdb2-4933-b3c6-24287638ad56', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (419, N'Internal Lock Washer 1', N'LI-6000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'71f8232d-2b59-41ac-99a1-f5ea197671b5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (420, N'Internal Lock Washer 8', N'LI-7160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'e2f03586-02e8-4cd9-a342-1a8d65d393bd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (421, N'Internal Lock Washer 2', N'LI-8000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'97741a88-92a1-4e72-b0aa-bcb198a1c378', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (422, N'Thin-Jam Lock Nut 9', N'LJ-1213', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7da2613b-3347-4072-a1dc-943ada161d7f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (423, N'Thin-Jam Lock Nut 10', N'LJ-1220', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a88f15be-2719-4741-93a4-2d96ef3712eb', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (424, N'Thin-Jam Lock Nut 1', N'LJ-1420', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'48461e5d-d58a-47e5-8ba3-ce4430fca611', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (425, N'Thin-Jam Lock Nut 2', N'LJ-1428', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'36187eb6-ad84-47b7-a55e-2941d3435fe2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (426, N'Thin-Jam Lock Nut 15', N'LJ-3410', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'99215648-afe8-4556-bc80-b6c62ae74fc8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (427, N'Thin-Jam Lock Nut 16', N'LJ-3416', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'b4fc4c32-049c-417f-bbb0-f19cdfd64252', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (428, N'Thin-Jam Lock Nut 5', N'LJ-3816', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a57b7915-2e65-49de-87ba-acd007c55adb', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (429, N'Thin-Jam Lock Nut 6', N'LJ-3824', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'5abd940c-d61f-4108-8312-0ea97e469613', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (430, N'Thin-Jam Lock Nut 3', N'LJ-5161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9883496f-4785-4bfc-8af3-c357347b9f89', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (431, N'Thin-Jam Lock Nut 4', N'LJ-5162', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'8c5ee683-d93c-4f25-9454-22faa4c31365', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (432, N'Thin-Jam Lock Nut 13', N'LJ-5811', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'38e4a447-3d3c-4087-abad-97f006525b52', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (433, N'Thin-Jam Lock Nut 14', N'LJ-5818', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'dce24b6c-76d8-4934-a4f6-c934364943ea', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (434, N'Thin-Jam Lock Nut 7', N'LJ-7161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'344ad07c-cca5-4374-a3f3-8a7e0a1d9916', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (435, N'Thin-Jam Lock Nut 8', N'LJ-7162', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'b2508cf2-c64f-493d-9db4-0d6601af1f73', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (436, N'Thin-Jam Lock Nut 12', N'LJ-9080', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'5d3e589f-4584-406b-b9cc-3c8c060cb9a5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (437, N'Thin-Jam Lock Nut 11', N'LJ-9161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'64169a28-161c-4737-b724-f42ffd99de80', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (438, N'Lock Nut 5', N'LN-1024', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'eb4c1d34-4816-4130-bb30-07b4de4072b6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (439, N'Lock Nut 6', N'LN-1032', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'98ccbb38-4683-486e-bbfe-cbbe4ea63c03', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (440, N'Lock Nut 16', N'LN-1213', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'bbfd88f8-28c5-44ee-b625-52e882393dfc', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (441, N'Lock Nut 17', N'LN-1220', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'92dc4ba8-a052-45df-83ec-226f050f876b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (442, N'Lock Nut 7', N'LN-1224', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'd583d825-c707-4529-b6f2-abffa21b81ec', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (443, N'Lock Nut 8', N'LN-1420', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'e91c3dc2-c99b-4d01-8108-5dde3c87830a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (444, N'Lock Nut 9', N'LN-1428', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'06534a20-4c00-4824-8bba-b4e3a5724d93', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (445, N'Lock Nut 22', N'LN-3410', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1e4fa4ec-367e-4d8d-88b4-6cd34d1cfb89', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (446, N'Lock Nut 23', N'LN-3416', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'afa814c8-8ec8-49db-9fee-a291197a8fe9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (447, N'Lock Nut 12', N'LN-3816', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9a751f85-7130-4562-9f22-db9cab6e5bbc', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (448, N'Lock Nut 13', N'LN-3824', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'06be8347-45c1-4c40-afcb-6ab34ad135fb', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (449, N'Lock Nut 1', N'LN-4400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1dc29704-e0e0-4ef5-b581-4a524730c448', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (450, N'Lock Nut 10', N'LN-5161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'612c26c7-6018-4050-b628-8b2d2e6841fa', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (451, N'Lock Nut 11', N'LN-5162', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'5bcc4558-6c16-48f1-92f0-fd2eefb17306', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (452, N'Lock Nut 2', N'LN-5400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'53ad147d-c16d-4a8c-b086-625a31405574', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (453, N'Lock Nut 20', N'LN-5811', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'2749030e-49b7-4b24-8d47-fbcf194aba38', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (454, N'Lock Nut 21', N'LN-5818', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'e10a7b34-87f5-42cd-88b3-27a3d8e16b18', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (455, N'Lock Nut 3', N'LN-6320', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'aa5071eb-2145-4d08-9d33-b9d2ba9e1493', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (456, N'Lock Nut 14', N'LN-7161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1e96b03d-dc07-4a98-bc24-bf5b24c393e5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (457, N'Lock Nut 15', N'LN-7162', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ce04de2b-4eca-4203-a108-b7d92ff0e96e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (458, N'Lock Nut 4', N'LN-8320', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'41bd9389-8b22-4a35-9a2c-233d39ada7ea', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (459, N'Lock Nut 19', N'LN-9080', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'5986504b-22a0-4e74-a137-c7cf99a8216f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (460, N'Lock Nut 18', N'LN-9161', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a420963f-92fd-4cd4-8531-6926e4162c41', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (461, N'Lock Ring', N'LR-2398', 0, 0, N'Silver', 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'aeca59da-b61c-4976-8316-97e14cd4eff1', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (462, N'Lower Head Race', N'LR-8520', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'dbb962bf-0603-4095-959b-5ba9c74fbd32', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (463, N'Lock Washer 4', N'LW-1000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a3ee3bc5-73c5-45f3-a952-9991d038dd9c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (464, N'Lock Washer 5', N'LW-1200', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ecaed08d-2cf5-4d81-a4ed-8369e25af227', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (465, N'Lock Washer 10', N'LW-1201', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a2212bab-af58-41a5-a659-a6141c8967ca', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (466, N'Lock Washer 6', N'LW-1400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9092f2e1-3637-4669-8565-55404a55750e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (467, N'Lock Washer 13', N'LW-3400', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'3cb31f4a-c61c-408c-be1e-48bee412e511', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (468, N'Lock Washer 8', N'LW-3800', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'900d26e6-21a0-427d-b43c-173f6dcb2045', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (469, N'Lock Washer 1', N'LW-4000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'5402ea37-29df-47ff-9fc7-867d60594c48', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (470, N'Lock Washer 7', N'LW-5160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'99357255-e66b-458c-ab2e-6f68ef5452d2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (471, N'Lock Washer 12', N'LW-5800', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7bc9d58e-3e62-481f-8343-beb0883b3ecf', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (472, N'Lock Washer 2', N'LW-6000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'5f201424-9e6a-4f8d-9c2c-30777e27d64f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (473, N'Lock Washer 9', N'LW-7160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'f9426fb2-1e68-464e-bf32-615026e0249e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (474, N'Lock Washer 3', N'LW-8000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ac007b7f-73b7-4623-8150-02444c5ec023', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (475, N'Lock Washer 11', N'LW-9160', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'639d8448-b427-47b1-9e5b-0e5090a27632', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (476, N'Metal Angle', N'MA-7075', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'e876e239-7ec2-45c8-ba4b-b9ceacb379a6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (477, N'Metal Bar 1', N'MB-2024', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'8b5429ce-7876-44b3-9332-baf78a238b36', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (478, N'Metal Bar 2', N'MB-6061', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'2a14f60e-3827-49ba-af13-466dbc30c5ba', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (479, N'Metal Plate 2', N'MP-2066', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'0773a2c9-f47f-429e-814a-25b2e08c128a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (480, N'Metal Plate 1', N'MP-2503', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'242389be-dde0-42a1-85d9-f99fdc981336', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (481, N'Metal Plate 3', N'MP-4960', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'8b7e90e5-7785-455e-bc7c-e962f18c6848', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (482, N'Metal Sheet 2', N'MS-0253', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'8bb96dfb-23aa-4877-9c5e-866bb18facc7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (483, N'Metal Sheet 3', N'MS-1256', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9074e00d-005b-450e-9c92-6667782e8108', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (484, N'Metal Sheet 7', N'MS-1981', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'a9539885-0cee-4aa0-9072-8db1d34a16db', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (485, N'Metal Sheet 4', N'MS-2259', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'3cb3cf7d-ab8e-44a3-b7e9-73149f5ec29f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (486, N'Metal Sheet 5', N'MS-2341', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'2a2c555d-328d-4299-bd83-591d0762df62', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (487, N'Metal Sheet 6', N'MS-2348', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'64844011-a1c3-4f8f-9caa-9c8d214ecc12', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (488, N'Metal Sheet 1', N'MS-6061', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'3b2febc6-c76c-4a56-9cf7-8af5b76e24ee', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (489, N'Metal Tread Plate', N'MT-1000', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'd2177b6c-3352-43f0-9a41-719754dd280c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (490, N'LL Nipple', N'NI-4127', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'88310f73-ab0a-41a2-8597-936f192b7d12', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (491, N'HL Nipple', N'NI-9522', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'88a7b897-6ff5-4ca2-b68a-6ea0e86f92b9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (492, N'Paint - Black', N'PA-187B', 0, 0, NULL, 60, 45, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'df20e514-3d47-491b-9454-0911ec3f7d29', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (493, N'Paint - Red', N'PA-361R', 0, 0, NULL, 60, 45, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'4c568357-5d21-4ad4-bb85-bb5519b3b50c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (494, N'Paint - Silver', N'PA-529S', 0, 0, NULL, 60, 45, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'fa81e47d-7333-49c2-809b-308171ca2fb1', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (495, N'Paint - Blue', N'PA-632U', 0, 0, NULL, 60, 45, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'25a73761-ae90-49d3-8d1d-dd7858db4704', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (496, N'Paint - Yellow', N'PA-823Y', 0, 0, NULL, 60, 45, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1c8adb43-9fe8-44a6-b949-8af33ce9486e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (497, N'Pinch Bolt', N'PB-6109', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'f1694c24-dfab-4c92-bc66-6e717db24ea8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (504, N'Cup-Shaped Race', N'RA-2345', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'874c800e-334d-4a3c-8d3a-1e872d5b2a1b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (505, N'Cone-Shaped Race', N'RA-7490', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'35ce3995-9dd2-40e2-98b8-275931ac2d76', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (506, N'Reflector', N'RF-9198', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1c850499-38ed-4c2d-8665-7edb6a7ce93d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (507, N'LL Mountain Rim', N'RM-M464', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, N'G  ', CAST(435.00 AS Decimal(8, 2)), 0, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'b2cc7dfb-783d-4587-88c0-2712a538a5b2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (508, N'ML Mountain Rim', N'RM-M692', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, N'G  ', CAST(450.00 AS Decimal(8, 2)), 0, NULL, N'M ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'733fd04d-322f-44f5-beec-f326189d1ce6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (509, N'HL Mountain Rim', N'RM-M823', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, N'G  ', CAST(400.00 AS Decimal(8, 2)), 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9fa4a3b5-d396-48d4-adfc-b573bc4a800a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (510, N'LL Road Rim', N'RM-R436', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, N'G  ', CAST(445.00 AS Decimal(8, 2)), 0, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'c2770757-b258-4eec-a811-6856faf87437', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (511, N'ML Road Rim', N'RM-R600', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, N'G  ', CAST(450.00 AS Decimal(8, 2)), 0, NULL, N'M ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'80108059-0002-4253-a805-53a2324c33a4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (512, N'HL Road Rim', N'RM-R800', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, N'G  ', CAST(400.00 AS Decimal(8, 2)), 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'cd9b5c44-fb31-4e0f-9905-3b2086966cc5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (513, N'Touring Rim', N'RM-T801', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, N'G  ', CAST(460.00 AS Decimal(8, 2)), 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'4852db13-308a-4893-aafa-390a0dfe9f12', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (514, N'LL Mountain Seat Assembly', N'SA-M198', 1, 0, NULL, 500, 375, 98.7700, 133.3400, NULL, NULL, NULL, NULL, 1, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'fcfc0a4f-4563-4e0b-bff4-5ddcfe3a9273', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (515, N'ML Mountain Seat Assembly', N'SA-M237', 1, 0, NULL, 500, 375, 108.9900, 147.1400, NULL, NULL, NULL, NULL, 1, NULL, N'M ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'd3c8ae4c-a1be-448d-bf58-6ecbf36afa0b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (516, N'HL Mountain Seat Assembly', N'SA-M687', 1, 0, NULL, 500, 375, 145.8700, 196.9200, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9e18adab-b9c7-45b1-bd95-1805ec4f297d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (517, N'LL Road Seat Assembly', N'SA-R127', 1, 0, NULL, 500, 375, 98.7700, 133.3400, NULL, NULL, NULL, NULL, 1, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'f5a30b8d-f35b-43f2-83a0-f7f6b51f6241', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (518, N'ML Road Seat Assembly', N'SA-R430', 1, 0, NULL, 500, 375, 108.9900, 147.1400, NULL, NULL, NULL, NULL, 1, NULL, N'M ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ad109395-fda9-4c2a-96f1-515ccde3d9f4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (519, N'HL Road Seat Assembly', N'SA-R522', 1, 0, NULL, 500, 375, 145.8700, 196.9200, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'7b52ee2a-7100-4a39-a0af-c89012da6ef8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (520, N'LL Touring Seat Assembly', N'SA-T467', 1, 0, NULL, 500, 375, 98.7700, 133.3400, NULL, NULL, NULL, NULL, 1, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'af3d83ba-4b8e-4072-817f-e6b095a1c879', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (521, N'ML Touring Seat Assembly', N'SA-T612', 1, 0, NULL, 500, 375, 108.9900, 147.1400, NULL, NULL, NULL, NULL, 1, NULL, N'M ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'85b9a3de-000c-4351-9494-05796689c216', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (522, N'HL Touring Seat Assembly', N'SA-T872', 1, 0, NULL, 500, 375, 145.8700, 196.9200, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'8c471bca-a735-4087-ad50-90ede0ac1a1b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (523, N'LL Spindle/Axle', N'SD-2342', 0, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'd2bd1f55-2cd4-4998-89fa-28ff2e28de2c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (524, N'HL Spindle/Axle', N'SD-9872', 0, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'6ce0661d-ba1f-4012-b785-55165b3b241a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (525, N'LL Shell', N'SH-4562', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, N'L ', NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'ae7bcda7-e836-4f68-9e61-745f27f9aa3e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (526, N'HL Shell', N'SH-9312', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'd215a3ae-aaf2-4cb0-9d20-3758aad078e2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (527, N'Spokes', N'SK-9283', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'5aabb729-343b-4084-a235-ccb3da9f29e7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (528, N'Seat Lug', N'SL-0931', 0, 0, NULL, 1000, 750, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'4a898b1e-9a3b-4beb-9873-a7465934051a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (529, N'Stem', N'SM-9087', 1, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'1173306e-b616-4c4a-b715-4e0a483ba2b5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (530, N'Seat Post', N'SP-2981', 0, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9b4ceb84-4e84-43f3-b326-9b7f22905363', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (531, N'Steerer', N'SR-2098', 1, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'f3b140a1-b139-4bb5-b144-1b7cbbee6c9a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (532, N'Seat Stays', N'SS-2985', 1, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'20c2c611-dffc-49b5-99cf-d89bdd3a91ce', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (533, N'Seat Tube', N'ST-9828', 1, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'41f5388b-7253-4002-bcc6-b2a50920d11f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (534, N'Top Tube', N'TO-2301', 1, 0, NULL, 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'4c0bad8e-066b-46b8-bfe9-da61539606e8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (535, N'Tension Pulley', N'TP-0923', 0, 0, NULL, 800, 600, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'13df62b2-8a7b-47d5-9084-f1172c4779e4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (679, N'Rear Derailleur Cage', N'RC-0291', 0, 0, N'Silver', 500, 375, 0.0000, 0.0000, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'912b03ea-4447-48c8-85da-09b80ab26340', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (680, N'HL Road Frame - Black, 58', N'FR-R92B-58', 1, 1, N'Black', 500, 375, 1059.3100, 1431.5000, N'58', N'CM ', N'LB ', CAST(2.24 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'43dd68d6-14a4-461f-9069-55309d90ea7e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (706, N'HL Road Frame - Red, 58', N'FR-R92R-58', 1, 1, N'Red', 500, 375, 1059.3100, 1431.5000, N'58', N'CM ', N'LB ', CAST(2.24 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2008-04-30T00:00:00.000' AS DateTime), NULL, NULL, N'9540ff17-2712-4c90-a3d1-8ce5568b2462', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (707, N'Sport-100 Helmet, Red', N'HL-U509-R', 0, 1, N'Red', 4, 3, 13.0863, 34.9900, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 31, 33, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'2e1ef41a-c08a-4ff6-8ada-bde58b64a712', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (708, N'Sport-100 Helmet, Black', N'HL-U509', 0, 1, N'Black', 4, 3, 13.0863, 34.9900, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 31, 33, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'a25a44fb-c2de-4268-958f-110b8d7621e2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (709, N'Mountain Bike Socks, M', N'SO-B909-M', 0, 1, N'White', 4, 3, 3.3963, 9.5000, N'M', NULL, NULL, NULL, 0, N'M ', NULL, N'U ', 23, 18, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'18f95f47-1540-4e02-8f1f-cc1bcb6828d0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (710, N'Mountain Bike Socks, L', N'SO-B909-L', 0, 1, N'White', 4, 3, 3.3963, 9.5000, N'L', NULL, NULL, NULL, 0, N'M ', NULL, N'U ', 23, 18, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'161c035e-21b3-4e14-8e44-af508f35d80a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (711, N'Sport-100 Helmet, Blue', N'HL-U509-B', 0, 1, N'Blue', 4, 3, 13.0863, 34.9900, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 31, 33, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'fd7c0858-4179-48c2-865b-abd5dfc7bc1d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (712, N'AWC Logo Cap', N'CA-1098', 0, 1, N'Multi', 4, 3, 6.9223, 8.9900, NULL, NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 19, 2, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'b9ede243-a6f4-4629-b1d4-ffe1aedc6de7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (713, N'Long-Sleeve Logo Jersey, S', N'LJ-0192-S', 0, 1, N'Multi', 4, 3, 38.4923, 49.9900, N'S', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 21, 11, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'fd449c82-a259-4fae-8584-6ca0255faf68', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (714, N'Long-Sleeve Logo Jersey, M', N'LJ-0192-M', 0, 1, N'Multi', 4, 3, 38.4923, 49.9900, N'M', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 21, 11, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'6a290063-a0cf-432a-8110-2ea0fda14308', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (715, N'Long-Sleeve Logo Jersey, L', N'LJ-0192-L', 0, 1, N'Multi', 4, 3, 38.4923, 49.9900, N'L', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 21, 11, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'34cf5ef5-c077-4ea0-914a-084814d5cbd5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (716, N'Long-Sleeve Logo Jersey, XL', N'LJ-0192-X', 0, 1, N'Multi', 4, 3, 38.4923, 49.9900, N'XL', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 21, 11, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'6ec47ec9-c041-4dda-b686-2125d539ce9b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (717, N'HL Road Frame - Red, 62', N'FR-R92R-62', 1, 1, N'Red', 500, 375, 868.6342, 1431.5000, N'62', N'CM ', N'LB ', CAST(2.30 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'052e4f8b-0a2a-46b2-9f42-10febcfae416', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (718, N'HL Road Frame - Red, 44', N'FR-R92R-44', 1, 1, N'Red', 500, 375, 868.6342, 1431.5000, N'44', N'CM ', N'LB ', CAST(2.12 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'a88d3b54-2cae-43f2-8c6e-ea1d97b46a7c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (719, N'HL Road Frame - Red, 48', N'FR-R92R-48', 1, 1, N'Red', 500, 375, 868.6342, 1431.5000, N'48', N'CM ', N'LB ', CAST(2.16 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'07befc9a-7634-402b-b234-d7797733baaf', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (720, N'HL Road Frame - Red, 52', N'FR-R92R-52', 1, 1, N'Red', 500, 375, 868.6342, 1431.5000, N'52', N'CM ', N'LB ', CAST(2.20 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'fcfea68f-310e-4e6e-9f99-bb17d011ebae', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (721, N'HL Road Frame - Red, 56', N'FR-R92R-56', 1, 1, N'Red', 500, 375, 868.6342, 1431.5000, N'56', N'CM ', N'LB ', CAST(2.24 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'56c85873-4993-41b4-8096-1067cfd7e4bd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (722, N'LL Road Frame - Black, 58', N'FR-R38B-58', 1, 1, N'Black', 500, 375, 204.6251, 337.2200, N'58', N'CM ', N'LB ', CAST(2.46 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'2140f256-f705-4d67-975d-32de03265838', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (723, N'LL Road Frame - Black, 60', N'FR-R38B-60', 1, 1, N'Black', 500, 375, 204.6251, 337.2200, N'60', N'CM ', N'LB ', CAST(2.48 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'aa95e2a5-e7c4-4b74-b1ea-b52ee3b51537', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (724, N'LL Road Frame - Black, 62', N'FR-R38B-62', 1, 1, N'Black', 500, 375, 204.6251, 337.2200, N'62', N'CM ', N'LB ', CAST(2.50 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'5247be33-50bf-4527-8a30-a39aae500a8e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (725, N'LL Road Frame - Red, 44', N'FR-R38R-44', 1, 1, N'Red', 500, 375, 187.1571, 337.2200, N'44', N'CM ', N'LB ', CAST(2.32 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'137d319d-44ad-42b2-ab61-60b9ce52b5f2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (726, N'LL Road Frame - Red, 48', N'FR-R38R-48', 1, 1, N'Red', 500, 375, 187.1571, 337.2200, N'48', N'CM ', N'LB ', CAST(2.36 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'35213547-275f-4767-805d-c8a4b8e13745', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (727, N'LL Road Frame - Red, 52', N'FR-R38R-52', 1, 1, N'Red', 500, 375, 187.1571, 337.2200, N'52', N'CM ', N'LB ', CAST(2.40 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'c455e0b3-d716-419d-abf0-7e03efdd2e26', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (728, N'LL Road Frame - Red, 58', N'FR-R38R-58', 1, 1, N'Red', 500, 375, 187.1571, 337.2200, N'58', N'CM ', N'LB ', CAST(2.46 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'799a56ff-5ad2-41b3-bfac-528b477ad129', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (729, N'LL Road Frame - Red, 60', N'FR-R38R-60', 1, 1, N'Red', 500, 375, 187.1571, 337.2200, N'60', N'CM ', N'LB ', CAST(2.48 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'1784bb14-d1f5-4b24-92da-9127ad179302', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (730, N'LL Road Frame - Red, 62', N'FR-R38R-62', 1, 1, N'Red', 500, 375, 187.1571, 337.2200, N'62', N'CM ', N'LB ', CAST(2.50 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'7e73aa1f-8569-4d87-9f80-ac2e513e0803', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (731, N'ML Road Frame - Red, 44', N'FR-R72R-44', 1, 1, N'Red', 500, 375, 352.1394, 594.8300, N'44', N'CM ', N'LB ', CAST(2.22 AS Decimal(8, 2)), 1, N'R ', N'M ', N'U ', 14, 16, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'459e041c-3234-409e-b4cd-81728f8a2398', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (732, N'ML Road Frame - Red, 48', N'FR-R72R-48', 1, 1, N'Red', 500, 375, 352.1394, 594.8300, N'48', N'CM ', N'LB ', CAST(2.26 AS Decimal(8, 2)), 1, N'R ', N'M ', N'U ', 14, 16, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'b673189c-c042-413b-8194-73bc44b0492c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (733, N'ML Road Frame - Red, 52', N'FR-R72R-52', 1, 1, N'Red', 500, 375, 352.1394, 594.8300, N'52', N'CM ', N'LB ', CAST(2.30 AS Decimal(8, 2)), 1, N'R ', N'M ', N'U ', 14, 16, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'55ea276b-82d8-4ccb-9ab1-9b1b75b15a83', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (734, N'ML Road Frame - Red, 58', N'FR-R72R-58', 1, 1, N'Red', 500, 375, 352.1394, 594.8300, N'58', N'CM ', N'LB ', CAST(2.36 AS Decimal(8, 2)), 1, N'R ', N'M ', N'U ', 14, 16, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'df4ce1e2-ba9a-4657-b999-ccfa6c55d9c1', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (735, N'ML Road Frame - Red, 60', N'FR-R72R-60', 1, 1, N'Red', 500, 375, 352.1394, 594.8300, N'60', N'CM ', N'LB ', CAST(2.38 AS Decimal(8, 2)), 1, N'R ', N'M ', N'U ', 14, 16, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'b2e48e8c-63a5-469a-ba4c-4f5ebb1104a4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (736, N'LL Road Frame - Black, 44', N'FR-R38B-44', 1, 1, N'Black', 500, 375, 204.6251, 337.2200, N'44', N'CM ', N'LB ', CAST(2.32 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'c9967889-f490-4a66-943a-bce432e938d8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (737, N'LL Road Frame - Black, 48', N'FR-R38B-48', 1, 1, N'Black', 500, 375, 204.6251, 337.2200, N'48', N'CM ', N'LB ', CAST(2.36 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'3b5f29b6-a441-4ff7-a0fa-fad10e2ceb4c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (738, N'LL Road Frame - Black, 52', N'FR-R38B-52', 1, 1, N'Black', 500, 375, 204.6251, 337.2200, N'52', N'CM ', N'LB ', CAST(2.40 AS Decimal(8, 2)), 1, N'R ', N'L ', N'U ', 14, 9, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'18fc5d72-a012-4dc7-bb35-0d01a84d0219', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (739, N'HL Mountain Frame - Silver, 42', N'FR-M94S-42', 1, 1, N'Silver', 500, 375, 747.2002, 1364.5000, N'42', N'CM ', N'LB ', CAST(2.72 AS Decimal(8, 2)), 1, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'8ae32663-8d6f-457d-8343-5b181fec43a7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (740, N'HL Mountain Frame - Silver, 44', N'FR-M94S-44', 1, 1, N'Silver', 500, 375, 706.8110, 1364.5000, N'44', N'CM ', N'LB ', CAST(2.76 AS Decimal(8, 2)), 1, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'1909c60c-c490-411d-b3e6-12ddd7832482', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (741, N'HL Mountain Frame - Silver, 48', N'FR-M94S-52', 1, 1, N'Silver', 500, 375, 706.8110, 1364.5000, N'48', N'CM ', N'LB ', CAST(2.80 AS Decimal(8, 2)), 1, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'b181ec1f-ca20-4724-b2eb-15f3e455142e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (742, N'HL Mountain Frame - Silver, 46', N'FR-M94S-46', 1, 1, N'Silver', 500, 375, 747.2002, 1364.5000, N'46', N'CM ', N'LB ', CAST(2.84 AS Decimal(8, 2)), 1, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'a189d86e-d923-4336-b13d-a5db6f426540', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (743, N'HL Mountain Frame - Black, 42', N'FR-M94B-42', 1, 1, N'Black', 500, 375, 739.0410, 1349.6000, N'42', N'CM ', N'LB ', CAST(2.72 AS Decimal(8, 2)), 1, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'27db28f8-5ab8-4091-b94e-6f1b2d8e7ab0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (744, N'HL Mountain Frame - Black, 44', N'FR-M94B-44', 1, 1, N'Black', 500, 375, 699.0928, 1349.6000, N'44', N'CM ', N'LB ', CAST(2.76 AS Decimal(8, 2)), 1, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'cb443286-6b25-409f-a10b-1ad4eeb4bd4e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (745, N'HL Mountain Frame - Black, 48', N'FR-M94B-48', 1, 1, N'Black', 500, 375, 699.0928, 1349.6000, N'48', N'CM ', N'LB ', CAST(2.80 AS Decimal(8, 2)), 1, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'1fee0573-6676-432d-8d6d-41ba9faa5865', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (746, N'HL Mountain Frame - Black, 46', N'FR-M94B-46', 1, 1, N'Black', 500, 375, 739.0410, 1349.6000, N'46', N'CM ', N'LB ', CAST(2.84 AS Decimal(8, 2)), 1, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'50abebcb-451e-42b9-8dbb-e5c4a34470e9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (747, N'HL Mountain Frame - Black, 38', N'FR-M94B-38', 1, 1, N'Black', 500, 375, 739.0410, 1349.6000, N'38', N'CM ', N'LB ', CAST(2.68 AS Decimal(8, 2)), 2, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'0c548577-3171-4ce2-b9a0-1ed526849de8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (748, N'HL Mountain Frame - Silver, 38', N'FR-M94S-38', 1, 1, N'Silver', 500, 375, 747.2002, 1364.5000, N'38', N'CM ', N'LB ', CAST(2.68 AS Decimal(8, 2)), 2, N'M ', N'H ', N'U ', 12, 5, CAST(N'2011-05-31T00:00:00.000' AS DateTime), NULL, NULL, N'f246acaa-a80b-40ec-9208-02edef885129', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (749, N'Road-150 Red, 62', N'BK-R93R-62', 1, 1, N'Red', 100, 75, 2171.2942, 3578.2700, N'62', N'CM ', N'LB ', CAST(15.00 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 25, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'bc621e1f-2553-4fdc-b22e-5e44a9003569', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (750, N'Road-150 Red, 44', N'BK-R93R-44', 1, 1, N'Red', 100, 75, 2171.2942, 3578.2700, N'44', N'CM ', N'LB ', CAST(13.77 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 25, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'c19e1136-5da4-4b40-8758-54a85d7ea494', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (751, N'Road-150 Red, 48', N'BK-R93R-48', 1, 1, N'Red', 100, 75, 2171.2942, 3578.2700, N'48', N'CM ', N'LB ', CAST(14.13 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 25, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'd10b7cc1-455e-435b-a08f-ec5b1c5776e9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (752, N'Road-150 Red, 52', N'BK-R93R-52', 1, 1, N'Red', 100, 75, 2171.2942, 3578.2700, N'52', N'CM ', N'LB ', CAST(14.42 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 25, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'5e085ba0-3cd5-487f-85bb-79ed1c701f23', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (753, N'Road-150 Red, 56', N'BK-R93R-56', 1, 1, N'Red', 100, 75, 2171.2942, 3578.2700, N'56', N'CM ', N'LB ', CAST(14.68 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 25, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'30819b88-f0d3-4e7a-8105-19f6fac2cefb', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (754, N'Road-450 Red, 58', N'BK-R68R-58', 1, 1, N'Red', 100, 75, 884.7083, 1457.9900, N'58', N'CM ', N'LB ', CAST(17.79 AS Decimal(8, 2)), 4, N'R ', N'M ', N'U ', 2, 28, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'40d5effa-c0c4-479f-af66-5f1bf8ed3bfb', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (755, N'Road-450 Red, 60', N'BK-R68R-60', 1, 1, N'Red', 100, 75, 884.7083, 1457.9900, N'60', N'CM ', N'LB ', CAST(17.90 AS Decimal(8, 2)), 4, N'R ', N'M ', N'U ', 2, 28, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'181a90cb-3678-490e-8418-78f73fb5343d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (756, N'Road-450 Red, 44', N'BK-R68R-44', 1, 1, N'Red', 100, 75, 884.7083, 1457.9900, N'44', N'CM ', N'LB ', CAST(16.77 AS Decimal(8, 2)), 4, N'R ', N'M ', N'U ', 2, 28, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'f8b5e26a-3d33-4e39-b500-cc21a133062e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (757, N'Road-450 Red, 48', N'BK-R68R-48', 1, 1, N'Red', 100, 75, 884.7083, 1457.9900, N'48', N'CM ', N'LB ', CAST(17.13 AS Decimal(8, 2)), 4, N'R ', N'M ', N'U ', 2, 28, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'c72c9978-0b04-46b3-9de6-948feca1c86e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (758, N'Road-450 Red, 52', N'BK-R68R-52', 1, 1, N'Red', 100, 75, 884.7083, 1457.9900, N'52', N'CM ', N'LB ', CAST(17.42 AS Decimal(8, 2)), 4, N'R ', N'M ', N'U ', 2, 28, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'040a4b7d-4060-4507-aa92-7508b434797e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (759, N'Road-650 Red, 58', N'BK-R50R-58', 1, 1, N'Red', 100, 75, 486.7066, 782.9900, N'58', N'CM ', N'LB ', CAST(19.79 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'6711d6bc-664f-4890-9f69-af1de321d055', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (760, N'Road-650 Red, 60', N'BK-R50R-60', 1, 1, N'Red', 100, 75, 486.7066, 782.9900, N'60', N'CM ', N'LB ', CAST(19.90 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'664867e5-4ab3-4783-96f9-42efde92f49b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (761, N'Road-650 Red, 62', N'BK-R50R-62', 1, 1, N'Red', 100, 75, 486.7066, 782.9900, N'62', N'CM ', N'LB ', CAST(20.00 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'1da14e09-6d71-4e2a-9ee9-1bdfdfd8a109', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (762, N'Road-650 Red, 44', N'BK-R50R-44', 1, 1, N'Red', 100, 75, 486.7066, 782.9900, N'44', N'CM ', N'LB ', CAST(18.77 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'f247aaae-12e3-4048-a37b-cce4a8999e81', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (763, N'Road-650 Red, 48', N'BK-R50R-48', 1, 1, N'Red', 100, 75, 486.7066, 782.9900, N'48', N'CM ', N'LB ', CAST(19.13 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'3da5fa6e-9e0f-4896-ac10-948c27f4eb79', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (764, N'Road-650 Red, 52', N'BK-R50R-52', 1, 1, N'Red', 100, 75, 486.7066, 782.9900, N'52', N'CM ', N'LB ', CAST(19.42 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'07cfe1ea-8a37-4d2a-835f-bc8d37e564af', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (765, N'Road-650 Black, 58', N'BK-R50B-58', 1, 1, N'Black', 100, 75, 486.7066, 782.9900, N'58', N'CM ', N'LB ', CAST(19.79 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'74645b12-3ce9-49a6-bd96-2cd814b37420', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (766, N'Road-650 Black, 60', N'BK-R50B-60', 1, 1, N'Black', 100, 75, 486.7066, 782.9900, N'60', N'CM ', N'LB ', CAST(19.90 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'a2db196d-6640-49ea-a84f-2e87ca6f50c6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (767, N'Road-650 Black, 62', N'BK-R50B-62', 1, 1, N'Black', 100, 75, 486.7066, 782.9900, N'62', N'CM ', N'LB ', CAST(20.00 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'c82a8309-63d3-4c0c-ad71-e91272397095', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (768, N'Road-650 Black, 44', N'BK-R50B-44', 1, 1, N'Black', 100, 75, 486.7066, 782.9900, N'44', N'CM ', N'LB ', CAST(18.77 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'11d563ac-115c-4f0d-a1e5-e946eee8b38b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (769, N'Road-650 Black, 48', N'BK-R50B-48', 1, 1, N'Black', 100, 75, 486.7066, 782.9900, N'48', N'CM ', N'LB ', CAST(19.13 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'a7e2179e-137c-497e-a5e6-c9ea64935fb0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (770, N'Road-650 Black, 52', N'BK-R50B-52', 1, 1, N'Black', 100, 75, 486.7066, 782.9900, N'52', N'CM ', N'LB ', CAST(19.42 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 30, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'136e2865-e0da-4624-963a-31349279ab1a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (771, N'Mountain-100 Silver, 38', N'BK-M82S-38', 1, 1, N'Silver', 100, 75, 1912.1544, 3399.9900, N'38', N'CM ', N'LB ', CAST(20.35 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 19, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'ca74b54e-fc30-4464-8b83-019bfd1b2dbb', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (772, N'Mountain-100 Silver, 42', N'BK-M82S-42', 1, 1, N'Silver', 100, 75, 1912.1544, 3399.9900, N'42', N'CM ', N'LB ', CAST(20.77 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 19, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'bbfff5a5-4bdc-49a9-a5ad-7584adffe808', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (773, N'Mountain-100 Silver, 44', N'BK-M82S-44', 1, 1, N'Silver', 100, 75, 1912.1544, 3399.9900, N'44', N'CM ', N'LB ', CAST(21.13 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 19, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'155fd77e-d6d6-43f0-8a5b-4a8305eb45cd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (774, N'Mountain-100 Silver, 48', N'BK-M82S-48', 1, 1, N'Silver', 100, 75, 1912.1544, 3399.9900, N'48', N'CM ', N'LB ', CAST(21.42 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 19, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'ba5551df-c9ee-4b43-b3ca-8c19d0f9384d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (775, N'Mountain-100 Black, 38', N'BK-M82B-38', 1, 1, N'Black', 100, 75, 1898.0944, 3374.9900, N'38', N'CM ', N'LB ', CAST(20.35 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 19, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'dea33347-fcd3-4346-aa0f-068cd6b3ad06', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (776, N'Mountain-100 Black, 42', N'BK-M82B-42', 1, 1, N'Black', 100, 75, 1898.0944, 3374.9900, N'42', N'CM ', N'LB ', CAST(20.77 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 19, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'02935111-a546-4c6d-941f-be12d42c158e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (777, N'Mountain-100 Black, 44', N'BK-M82B-44', 1, 1, N'Black', 100, 75, 1898.0944, 3374.9900, N'44', N'CM ', N'LB ', CAST(21.13 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 19, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'7920bc3b-8fd4-4610-93d2-e693a66b6474', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (778, N'Mountain-100 Black, 48', N'BK-M82B-48', 1, 1, N'Black', 100, 75, 1898.0944, 3374.9900, N'48', N'CM ', N'LB ', CAST(21.42 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 19, CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), NULL, N'1b486300-7e64-4c5d-a9ba-a8368e20c5a0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (779, N'Mountain-200 Silver, 38', N'BK-M68S-38', 1, 1, N'Silver', 100, 75, 1265.6195, 2319.9900, N'38', N'CM ', N'LB ', CAST(23.35 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 20, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'3a45d835-abae-4806-ac03-c53abcd3b974', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (780, N'Mountain-200 Silver, 42', N'BK-M68S-42', 1, 1, N'Silver', 100, 75, 1265.6195, 2319.9900, N'42', N'CM ', N'LB ', CAST(23.77 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 20, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'ce4849b4-56e6-4b50-808b-9bde67cc4704', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (781, N'Mountain-200 Silver, 46', N'BK-M68S-46', 1, 1, N'Silver', 100, 75, 1265.6195, 2319.9900, N'46', N'CM ', N'LB ', CAST(24.13 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 20, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'20799030-420c-496a-9922-09189c2b457e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (782, N'Mountain-200 Black, 38', N'BK-M68B-38', 1, 1, N'Black', 100, 75, 1251.9813, 2294.9900, N'38', N'CM ', N'LB ', CAST(23.35 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 20, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'82cb8f9b-b8bb-4841-98d3-bcdb807c4dd8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (783, N'Mountain-200 Black, 42', N'BK-M68B-42', 1, 1, N'Black', 100, 75, 1251.9813, 2294.9900, N'42', N'CM ', N'LB ', CAST(23.77 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 20, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'2b0af5b9-7571-4621-b760-47df599f9650', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (784, N'Mountain-200 Black, 46', N'BK-M68B-46', 1, 1, N'Black', 100, 75, 1251.9813, 2294.9900, N'46', N'CM ', N'LB ', CAST(24.13 AS Decimal(8, 2)), 4, N'M ', N'H ', N'U ', 1, 20, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'33f42284-e216-4b98-ba48-b4ee18a01fa0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (785, N'Mountain-300 Black, 38', N'BK-M47B-38', 1, 1, N'Black', 100, 75, 598.4354, 1079.9900, N'38', N'CM ', N'LB ', CAST(25.35 AS Decimal(8, 2)), 4, N'M ', N'M ', N'U ', 1, 21, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'f06c2cbf-0901-4c08-80ed-fb4e87171b3b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (786, N'Mountain-300 Black, 40', N'BK-M47B-40', 1, 1, N'Black', 100, 75, 598.4354, 1079.9900, N'40', N'CM ', N'LB ', CAST(25.77 AS Decimal(8, 2)), 4, N'M ', N'M ', N'U ', 1, 21, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'580d4322-be03-4c91-83d2-ee33ec6008ab', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (787, N'Mountain-300 Black, 44', N'BK-M47B-44', 1, 1, N'Black', 100, 75, 598.4354, 1079.9900, N'44', N'CM ', N'LB ', CAST(26.13 AS Decimal(8, 2)), 4, N'M ', N'M ', N'U ', 1, 21, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'07c2a548-0452-47b4-9dce-6edb0a30c85e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (788, N'Mountain-300 Black, 48', N'BK-M47B-48', 1, 1, N'Black', 100, 75, 598.4354, 1079.9900, N'48', N'CM ', N'LB ', CAST(26.42 AS Decimal(8, 2)), 4, N'M ', N'M ', N'U ', 1, 21, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'16078dbe-388d-4c18-aa8f-0c8f48035468', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (789, N'Road-250 Red, 44', N'BK-R89R-44', 1, 1, N'Red', 100, 75, 1518.7864, 2443.3500, N'44', N'CM ', N'LB ', CAST(14.77 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 26, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'0aa71ad6-afaf-43c6-9745-35d815b50a5b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (790, N'Road-250 Red, 48', N'BK-R89R-48', 1, 1, N'Red', 100, 75, 1518.7864, 2443.3500, N'48', N'CM ', N'LB ', CAST(15.13 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 26, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'115ddade-70e3-43f9-80dc-638daea271c4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (791, N'Road-250 Red, 52', N'BK-R89R-52', 1, 1, N'Red', 100, 75, 1518.7864, 2443.3500, N'52', N'CM ', N'LB ', CAST(15.42 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 26, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'c9fd1df4-9512-420a-b379-067108033b75', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (792, N'Road-250 Red, 58', N'BK-R89R-58', 1, 1, N'Red', 100, 75, 1554.9479, 2443.3500, N'58', N'CM ', N'LB ', CAST(15.79 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 26, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'df629c11-8d8b-4774-9d52-ecb64dc95212', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (793, N'Road-250 Black, 44', N'BK-R89B-44', 1, 1, N'Black', 100, 75, 1554.9479, 2443.3500, N'44', N'CM ', N'LB ', CAST(14.77 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 26, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'1ff419b5-52af-4f7e-aeae-4fec5e99de35', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (794, N'Road-250 Black, 48', N'BK-R89B-48', 1, 1, N'Black', 100, 75, 1554.9479, 2443.3500, N'48', N'CM ', N'LB ', CAST(15.13 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 26, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'9d165ddf-8f5d-41c7-9bb8-13f41a3d1f62', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (795, N'Road-250 Black, 52', N'BK-R89B-52', 1, 1, N'Black', 100, 75, 1554.9479, 2443.3500, N'52', N'CM ', N'LB ', CAST(15.42 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 26, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'74fe3957-cbc3-450a-ab92-849bd13530e2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (796, N'Road-250 Black, 58', N'BK-R89B-58', 1, 1, N'Black', 100, 75, 1554.9479, 2443.3500, N'58', N'CM ', N'LB ', CAST(15.68 AS Decimal(8, 2)), 4, N'R ', N'H ', N'U ', 2, 26, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'1c530fe8-a169-4adc-b3dc-b11a48245e63', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (797, N'Road-550-W Yellow, 38', N'BK-R64Y-38', 1, 1, N'Yellow', 100, 75, 713.0798, 1120.4900, N'38', N'CM ', N'LB ', CAST(17.35 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 29, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'aad81532-a572-49a5-83c3-dfa9e3b4fea6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (798, N'Road-550-W Yellow, 40', N'BK-R64Y-40', 1, 1, N'Yellow', 100, 75, 713.0798, 1120.4900, N'40', N'CM ', N'LB ', CAST(17.77 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 29, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a35a1c35-c128-4697-951e-4199062e78f3', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (799, N'Road-550-W Yellow, 42', N'BK-R64Y-42', 1, 1, N'Yellow', 100, 75, 713.0798, 1120.4900, N'42', N'CM ', N'LB ', CAST(18.13 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 29, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a359ab09-16f2-4726-a60f-0dfdb1c9527e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (800, N'Road-550-W Yellow, 44', N'BK-R64Y-44', 1, 1, N'Yellow', 100, 75, 713.0798, 1120.4900, N'44', N'CM ', N'LB ', CAST(18.42 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 29, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'0a7028fb-ff06-4d38-aaa1-b64816278165', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (801, N'Road-550-W Yellow, 48', N'BK-R64Y-48', 1, 1, N'Yellow', 100, 75, 713.0798, 1120.4900, N'48', N'CM ', N'LB ', CAST(18.68 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 29, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c90cc877-804c-4ce7-afc3-4c8791a13dfb', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (802, N'LL Fork', N'FK-1639', 1, 1, NULL, 500, 375, 65.8097, 148.2200, NULL, NULL, NULL, NULL, 1, NULL, N'L ', NULL, 10, 104, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'fb8502be-07eb-4134-ab06-c3a9959a52ae', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (803, N'ML Fork', N'FK-5136', 1, 1, NULL, 500, 375, 77.9176, 175.4900, NULL, NULL, NULL, NULL, 1, NULL, N'M ', NULL, 10, 105, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'f5fa4e2f-b976-48a4-bf79-85632f697d2e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (804, N'HL Fork', N'FK-9939', 1, 1, NULL, 500, 375, 101.8936, 229.4900, NULL, NULL, NULL, NULL, 1, NULL, N'H ', NULL, 10, 106, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'553229b3-1ad9-4a71-a21c-2af4332cfce9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (805, N'LL Headset', N'HS-0296', 1, 1, NULL, 500, 375, 15.1848, 34.2000, NULL, NULL, NULL, NULL, 1, NULL, N'L ', NULL, 11, 59, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'bb6bd7b3-a34d-4d64-822e-781fa6838e19', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (806, N'ML Headset', N'HS-2451', 1, 1, NULL, 500, 375, 45.4168, 102.2900, NULL, NULL, NULL, NULL, 1, NULL, N'M ', NULL, 11, 60, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'23b5d52b-8c29-4059-b899-75c53b5ee2e6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (807, N'HL Headset', N'HS-3479', 1, 1, NULL, 500, 375, 55.3801, 124.7300, NULL, NULL, NULL, NULL, 1, NULL, N'H ', NULL, 11, 61, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'12e4d5e8-79ed-4bcb-a532-6275d1a93417', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (808, N'LL Mountain Handlebars', N'HB-M243', 1, 1, NULL, 500, 375, 19.7758, 44.5400, NULL, NULL, NULL, NULL, 1, N'M ', N'L ', NULL, 4, 52, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'b59b7bf2-7afc-4a74-b063-f942f1e0da19', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (809, N'ML Mountain Handlebars', N'HB-M763', 1, 1, NULL, 500, 375, 27.4925, 61.9200, NULL, NULL, NULL, NULL, 1, N'M ', N'M ', NULL, 4, 54, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'ae6020df-d9c9-4d34-9795-1f80e6bbf5a5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (810, N'HL Mountain Handlebars', N'HB-M918', 1, 1, NULL, 500, 375, 53.3999, 120.2700, NULL, NULL, NULL, NULL, 1, N'M ', N'H ', NULL, 4, 55, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'6aa0f921-0f09-4f99-8d3c-335946873553', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (811, N'LL Road Handlebars', N'HB-R504', 1, 1, NULL, 500, 375, 19.7758, 44.5400, NULL, NULL, NULL, NULL, 1, N'R ', N'L ', NULL, 4, 56, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'acdae407-b40e-435e-8e84-1bfc33013e81', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (812, N'ML Road Handlebars', N'HB-R720', 1, 1, NULL, 500, 375, 27.4925, 61.9200, NULL, NULL, NULL, NULL, 1, N'R ', N'M ', NULL, 4, 57, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'33fa1a03-38d6-405e-be9b-eea92f3d204f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (813, N'HL Road Handlebars', N'HB-R956', 1, 1, NULL, 500, 375, 53.3999, 120.2700, NULL, NULL, NULL, NULL, 1, N'R ', N'H ', NULL, 4, 58, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'5c5327b9-ad2e-4c33-8d74-edf49e0c2dd8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (814, N'ML Mountain Frame - Black, 38', N'FR-M63B-38', 1, 1, N'Black', 500, 375, 185.8193, 348.7600, N'38', N'CM ', N'LB ', CAST(2.73 AS Decimal(8, 2)), 2, N'M ', N'M ', N'U ', 12, 15, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'0d879312-a7d3-441d-9d23-b6550bab3814', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (815, N'LL Mountain Front Wheel', N'FW-M423', 1, 1, N'Black', 500, 375, 26.9708, 60.7450, NULL, NULL, NULL, NULL, 1, N'M ', N'L ', NULL, 17, 42, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'd7b1d161-182e-44f6-a9ff-9c1eba76613b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (816, N'ML Mountain Front Wheel', N'FW-M762', 1, 1, N'Black', 500, 375, 92.8071, 209.0250, NULL, NULL, NULL, NULL, 1, N'M ', N'M ', NULL, 17, 45, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'5e3e5033-9a77-4dca-8b7f-dfed78efa08a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (817, N'HL Mountain Front Wheel', N'FW-M928', 1, 1, N'Black', 500, 375, 133.2955, 300.2150, NULL, NULL, NULL, NULL, 1, N'M ', N'H ', NULL, 17, 46, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'3c8ffff6-a8dc-45a3-963b-a6284ced7596', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (818, N'LL Road Front Wheel', N'FW-R623', 1, 1, N'Black', 500, 375, 37.9909, 85.5650, NULL, NULL, N'G  ', CAST(900.00 AS Decimal(8, 2)), 1, N'R ', N'L ', NULL, 17, 49, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'9e66de78-decb-438a-b9a9-023c773c60a2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (819, N'ML Road Front Wheel', N'FW-R762', 1, 1, N'Black', 500, 375, 110.2829, 248.3850, NULL, NULL, N'G  ', CAST(850.00 AS Decimal(8, 2)), 1, N'R ', N'M ', NULL, 17, 50, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'6ea94fbf-b9aa-43fc-84e8-91d508dde751', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (820, N'HL Road Front Wheel', N'FW-R820', 1, 1, N'Black', 500, 375, 146.5466, 330.0600, NULL, NULL, N'G  ', CAST(650.00 AS Decimal(8, 2)), 1, N'R ', N'H ', NULL, 17, 51, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'727a3cd5-8d40-4884-a7e4-dfd3ffdeb164', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (821, N'Touring Front Wheel', N'FW-T905', 1, 1, N'Black', 500, 375, 96.7964, 218.0100, NULL, NULL, NULL, NULL, 1, N'T ', NULL, NULL, 17, 44, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'8d1cdb07-4fa1-4ac1-840f-a16c3dca5009', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (822, N'ML Road Frame-W - Yellow, 38', N'FR-R72Y-38', 1, 1, N'Yellow', 500, 375, 360.9428, 594.8300, N'38', N'CM ', N'LB ', CAST(2.18 AS Decimal(8, 2)), 2, N'R ', N'M ', N'W ', 14, 17, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'22976fa7-0ad0-40f9-b4f9-ba10279ea1a3', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (823, N'LL Mountain Rear Wheel', N'RW-M423', 1, 1, N'Black', 500, 375, 38.9588, 87.7450, NULL, NULL, NULL, NULL, 1, N'M ', N'L ', NULL, 17, 123, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'e6c39f58-995f-4786-a309-df3812d8b30f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (824, N'ML Mountain Rear Wheel', N'RW-M762', 1, 1, N'Black', 500, 375, 104.7951, 236.0250, NULL, NULL, NULL, NULL, 1, N'M ', N'M ', NULL, 17, 124, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'b2f7cf9b-a7bf-49ab-9cca-9f6e791cd693', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (825, N'HL Mountain Rear Wheel', N'RW-M928', 1, 1, N'Black', 500, 375, 145.2835, 327.2150, NULL, NULL, NULL, NULL, 1, N'M ', N'H ', NULL, 17, 125, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'35d02edc-1120-41fb-b5df-8655a93b3353', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (826, N'LL Road Rear Wheel', N'RW-R623', 1, 1, N'Black', 500, 375, 49.9789, 112.5650, NULL, NULL, N'G  ', CAST(1050.00 AS Decimal(8, 2)), 1, N'R ', N'L ', NULL, 17, 126, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'78d01117-8dcd-465f-9dc7-94a2cdc35582', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (827, N'ML Road Rear Wheel', N'RW-R762', 1, 1, N'Black', 500, 375, 122.2709, 275.3850, NULL, NULL, N'G  ', CAST(1000.00 AS Decimal(8, 2)), 1, N'R ', N'M ', NULL, 17, 77, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'cf739f9a-0af0-4810-b229-c431a31d7779', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (828, N'HL Road Rear Wheel', N'RW-R820', 1, 1, N'Black', 500, 375, 158.5346, 357.0600, NULL, NULL, N'G  ', CAST(890.00 AS Decimal(8, 2)), 1, N'R ', N'H ', NULL, 17, 78, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'8f262a37-43aa-4ad5-ae1f-8bd6967d8e9b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (829, N'Touring Rear Wheel', N'RW-T905', 1, 1, N'Black', 500, 375, 108.7844, 245.0100, NULL, NULL, NULL, NULL, 1, N'T ', NULL, NULL, 17, 43, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'30d2254d-e26d-4586-b4c5-e8ccb8a059b8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (830, N'ML Mountain Frame - Black, 40', N'FR-M63B-40', 1, 1, N'Black', 500, 375, 185.8193, 348.7600, N'40', N'CM ', N'LB ', CAST(2.77 AS Decimal(8, 2)), 1, N'M ', N'M ', N'U ', 12, 14, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'aed1c9c4-c139-45d2-b38e-0a0a9f518665', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (831, N'ML Mountain Frame - Black, 44', N'FR-M63B-44', 1, 1, N'Black', 500, 375, 185.8193, 348.7600, N'44', N'CM ', N'LB ', CAST(2.81 AS Decimal(8, 2)), 1, N'M ', N'M ', N'U ', 12, 14, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'3f2135d4-ec5f-4e30-bde8-5444518f0637', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (832, N'ML Mountain Frame - Black, 48', N'FR-M63B-48', 1, 1, N'Black', 500, 375, 185.8193, 348.7600, N'48', N'CM ', N'LB ', CAST(2.85 AS Decimal(8, 2)), 1, N'M ', N'M ', N'U ', 12, 14, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'c2009b69-f15a-47ec-b710-1809d299318a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (833, N'ML Road Frame-W - Yellow, 40', N'FR-R72Y-40', 1, 1, N'Yellow', 500, 375, 360.9428, 594.8300, N'40', N'CM ', N'LB ', CAST(2.22 AS Decimal(8, 2)), 1, N'R ', N'M ', N'W ', 14, 17, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'22df26f2-60bc-493e-a14a-5500633e9f7e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (834, N'ML Road Frame-W - Yellow, 42', N'FR-R72Y-42', 1, 1, N'Yellow', 500, 375, 360.9428, 594.8300, N'42', N'CM ', N'LB ', CAST(2.26 AS Decimal(8, 2)), 1, N'R ', N'M ', N'W ', 14, 17, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'207b54da-5404-415d-8578-9a45082e3bf1', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (835, N'ML Road Frame-W - Yellow, 44', N'FR-R72Y-44', 1, 1, N'Yellow', 500, 375, 360.9428, 594.8300, N'44', N'CM ', N'LB ', CAST(2.30 AS Decimal(8, 2)), 1, N'R ', N'M ', N'W ', 14, 17, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a0fad492-ac24-4fcf-8d2a-d21d06386ae1', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (836, N'ML Road Frame-W - Yellow, 48', N'FR-R72Y-48', 1, 1, N'Yellow', 500, 375, 360.9428, 594.8300, N'48', N'CM ', N'LB ', CAST(2.34 AS Decimal(8, 2)), 1, N'R ', N'M ', N'W ', 14, 17, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'8487bfe0-2138-471e-9c6d-fdb3a67e7d86', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (837, N'HL Road Frame - Black, 62', N'FR-R92B-62', 1, 1, N'Black', 500, 375, 868.6342, 1431.5000, N'62', N'CM ', N'LB ', CAST(2.30 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'5dce9c8c-fb94-46f8-b826-11658f6a3682', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (838, N'HL Road Frame - Black, 44', N'FR-R92B-44', 1, 1, N'Black', 500, 375, 868.6342, 1431.5000, N'44', N'CM ', N'LB ', CAST(2.12 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'e4902656-a4bc-4b08-9d47-4f3da0fd76c3', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (839, N'HL Road Frame - Black, 48', N'FR-R92B-48', 1, 1, N'Black', 500, 375, 868.6342, 1431.5000, N'48', N'CM ', N'LB ', CAST(2.16 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'557b603b-407b-41a4-ae34-4f7747866dba', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (840, N'HL Road Frame - Black, 52', N'FR-R92B-52', 1, 1, N'Black', 500, 375, 868.6342, 1431.5000, N'52', N'CM ', N'LB ', CAST(2.20 AS Decimal(8, 2)), 1, N'R ', N'H ', N'U ', 14, 6, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'0ed082b3-fbba-43af-9149-8741b9fc78c8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (841, N'Men''s Sports Shorts, S', N'SH-M897-S', 0, 1, N'Black', 4, 3, 24.7459, 59.9900, N'S', NULL, NULL, NULL, 0, N'S ', NULL, N'M ', 22, 13, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'34b08c1f-99d1-43c4-8ef7-2cd754b6665d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (842, N'Touring-Panniers, Large', N'PA-T100', 0, 1, N'Grey', 4, 3, 51.5625, 125.0000, NULL, NULL, NULL, NULL, 0, N'T ', NULL, NULL, 35, 120, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'56334fff-91d4-495e-bf98-933bc1010f23', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (843, N'Cable Lock', N'LO-C100', 0, 1, NULL, 4, 3, 10.3125, 25.0000, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 34, 115, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'56ffd7b9-1014-4640-b1bd-b2649589b4d7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (844, N'Minipump', N'PU-0452', 0, 1, NULL, 4, 3, 8.2459, 19.9900, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 36, 116, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'aaf7a076-9ee3-46bf-a69f-414d847e858b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (845, N'Mountain Pump', N'PU-M044', 0, 1, NULL, 4, 3, 10.3084, 24.9900, NULL, NULL, NULL, NULL, 0, N'M ', NULL, NULL, 36, 117, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'57169f80-fafb-4678-8f51-fe1f131d0c83', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (846, N'Taillights - Battery-Powered', N'LT-T990', 0, 1, NULL, 4, 3, 5.7709, 13.9900, NULL, NULL, NULL, NULL, 0, N'R ', NULL, NULL, 33, 108, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'3c617b87-50a5-434c-a0d3-22314b7027ee', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (847, N'Headlights - Dual-Beam', N'LT-H902', 0, 1, NULL, 4, 3, 14.4334, 34.9900, NULL, NULL, NULL, NULL, 0, N'R ', NULL, NULL, 33, 109, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'417db6cb-f38f-4b0d-87e7-e1ebf7456c3a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (848, N'Headlights - Weatherproof', N'LT-H903', 0, 1, NULL, 4, 3, 18.5584, 44.9900, NULL, NULL, NULL, NULL, 0, N'R ', NULL, NULL, 33, 110, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'fc362c1a-4b9c-4d5f-a6d3-0775846c61f0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (849, N'Men''s Sports Shorts, M', N'SH-M897-M', 0, 1, N'Black', 4, 3, 24.7459, 59.9900, N'M', NULL, NULL, NULL, 0, N'S ', NULL, N'M ', 22, 13, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'db37b435-74b9-43d3-b363-abbead107bc4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (850, N'Men''s Sports Shorts, L', N'SH-M897-L', 0, 1, N'Black', 4, 3, 24.7459, 59.9900, N'L', NULL, NULL, NULL, 0, N'S ', NULL, N'M ', 22, 13, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'714184c5-669b-4cf1-a802-30e7b1ea7722', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (851, N'Men''s Sports Shorts, XL', N'SH-M897-X', 0, 1, N'Black', 4, 3, 24.7459, 59.9900, N'XL', NULL, NULL, NULL, 0, N'S ', NULL, N'M ', 22, 13, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'bd3ffe40-fe2e-44cb-a4e0-81786c3a751f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (852, N'Women''s Tights, S', N'TG-W091-S', 0, 1, N'Black', 4, 3, 30.9334, 74.9900, N'S', NULL, NULL, NULL, 0, N'S ', NULL, N'W ', 24, 38, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'7de86c98-4f5b-4155-8572-c977f14ebaeb', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (853, N'Women''s Tights, M', N'TG-W091-M', 0, 1, N'Black', 4, 3, 30.9334, 74.9900, N'M', NULL, NULL, NULL, 0, N'S ', NULL, N'W ', 24, 38, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'4d8e186c-b8c9-4c64-b411-4995dd87e316', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (854, N'Women''s Tights, L', N'TG-W091-L', 0, 1, N'Black', 4, 3, 30.9334, 74.9900, N'L', NULL, NULL, NULL, 0, N'S ', NULL, N'W ', 24, 38, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'e378c2f3-54f6-4ea9-b049-e8bb32b5bdfd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (855, N'Men''s Bib-Shorts, S', N'SB-M891-S', 0, 1, N'Multi', 4, 3, 37.1209, 89.9900, N'S', NULL, NULL, NULL, 0, N'S ', NULL, N'M ', 18, 12, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'9f60af1e-4c11-4e90-baea-48e834e8b4c2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (856, N'Men''s Bib-Shorts, M', N'SB-M891-M', 0, 1, N'Multi', 4, 3, 37.1209, 89.9900, N'M', NULL, NULL, NULL, 0, N'S ', NULL, N'M ', 18, 12, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'e0cbec04-f4fc-450f-9780-f8ea7691febd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (857, N'Men''s Bib-Shorts, L', N'SB-M891-L', 0, 1, N'Multi', 4, 3, 37.1209, 89.9900, N'L', NULL, NULL, NULL, 0, N'S ', NULL, N'M ', 18, 12, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'e1df75a4-9986-489e-a5de-ad3da824eb5e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (858, N'Half-Finger Gloves, S', N'GL-H102-S', 0, 1, N'Black', 4, 3, 9.1593, 24.4900, N'S', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 20, 4, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'9e1db5c3-539d-4061-9433-d762dc195cd8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (859, N'Half-Finger Gloves, M', N'GL-H102-M', 0, 1, N'Black', 4, 3, 9.1593, 24.4900, N'M', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 20, 4, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'9d458fd5-392d-4ab1-afef-6a5548e48858', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (860, N'Half-Finger Gloves, L', N'GL-H102-L', 0, 1, N'Black', 4, 3, 9.1593, 24.4900, N'L', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 20, 4, CAST(N'2012-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'fa710215-925f-4959-81df-538e72a6a255', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (861, N'Full-Finger Gloves, S', N'GL-F110-S', 0, 1, N'Black', 4, 3, 15.6709, 37.9900, N'S', NULL, NULL, NULL, 0, N'M ', NULL, N'U ', 20, 3, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'76fac097-1fb3-456b-8fb9-2c7a613771b4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (862, N'Full-Finger Gloves, M', N'GL-F110-M', 0, 1, N'Black', 4, 3, 15.6709, 37.9900, N'M', NULL, NULL, NULL, 0, N'M ', NULL, N'U ', 20, 3, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'1084221e-1890-443e-9d87-afcad6358355', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (863, N'Full-Finger Gloves, L', N'GL-F110-L', 0, 1, N'Black', 4, 3, 15.6709, 37.9900, N'L', NULL, NULL, NULL, 0, N'M ', NULL, N'U ', 20, 3, CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2013-05-29T00:00:00.000' AS DateTime), NULL, N'6116f9d4-8a1d-4022-a642-9c445c197203', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (864, N'Classic Vest, S', N'VE-C304-S', 0, 1, N'Blue', 4, 3, 23.7490, 63.5000, N'S', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 25, 1, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'eb423ef3-409d-46fe-b35b-d69970820314', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (865, N'Classic Vest, M', N'VE-C304-M', 0, 1, N'Blue', 4, 3, 23.7490, 63.5000, N'M', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 25, 1, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'2e52f96e-64a1-4069-911c-e3fd6e094a1e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (866, N'Classic Vest, L', N'VE-C304-L', 0, 1, N'Blue', 4, 3, 23.7490, 63.5000, N'L', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 25, 1, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'3211f5a8-b6c4-48bd-9aa4-d69cb40d97dd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (867, N'Women''s Mountain Shorts, S', N'SH-W890-S', 0, 1, N'Black', 4, 3, 26.1763, 69.9900, N'S', NULL, NULL, NULL, 0, N'M ', NULL, N'W ', 22, 37, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'22616fd2-b99f-4f7d-acf6-33dff66d42d2', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (868, N'Women''s Mountain Shorts, M', N'SH-W890-M', 0, 1, N'Black', 4, 3, 26.1763, 69.9900, N'M', NULL, NULL, NULL, 0, N'M ', NULL, N'W ', 22, 37, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'968e3610-e583-42e8-8ab6-484a799b1774', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (869, N'Women''s Mountain Shorts, L', N'SH-W890-L', 0, 1, N'Black', 4, 3, 26.1763, 69.9900, N'L', NULL, NULL, NULL, 0, N'M ', NULL, N'W ', 22, 37, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'1a66b244-5ca0-4153-b539-ae048d14faec', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (870, N'Water Bottle - 30 oz.', N'WB-H098', 0, 1, NULL, 4, 3, 1.8663, 4.9900, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 28, 111, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'834e8d1a-69a7-4c42-8b68-fa08d9ec9e5b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (871, N'Mountain Bottle Cage', N'BC-M005', 0, 1, NULL, 4, 3, 3.7363, 9.9900, NULL, NULL, NULL, NULL, 0, N'M ', NULL, NULL, 28, 112, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'684491de-63f8-4632-90e3-36773c4e63bd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (872, N'Road Bottle Cage', N'BC-R205', 0, 1, NULL, 4, 3, 3.3623, 8.9900, NULL, NULL, NULL, NULL, 0, N'R ', NULL, NULL, 28, 113, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'601b1fe8-d4d0-4cfb-9379-29481cc05291', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (873, N'Patch Kit/8 Patches', N'PK-7098', 0, 1, NULL, 4, 3, 0.8565, 2.2900, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 37, 114, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'36e638e4-68df-411b-930a-daad57221aa6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (874, N'Racing Socks, M', N'SO-R809-M', 0, 1, N'White', 4, 3, 3.3623, 8.9900, N'M', NULL, NULL, NULL, 0, N'R ', NULL, N'U ', 23, 24, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'b9c7eb0a-1dd1-4a1d-b4c3-1dad83a8ea7e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (875, N'Racing Socks, L', N'SO-R809-L', 0, 1, N'White', 4, 3, 3.3623, 8.9900, N'L', NULL, NULL, NULL, 0, N'R ', NULL, N'U ', 23, 24, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c0a16305-74b7-4fae-b5c9-3e8bd0e44762', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (876, N'Hitch Rack - 4-Bike', N'RA-H123', 0, 1, NULL, 4, 3, 44.8800, 120.0000, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 26, 118, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'7a0c4bbd-9679-4f59-9ebc-9daf3439a38a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (877, N'Bike Wash - Dissolver', N'CL-9009', 0, 1, NULL, 4, 3, 2.9733, 7.9500, NULL, NULL, NULL, NULL, 0, N'S ', NULL, NULL, 29, 119, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'3c40b5ad-e328-4715-88a7-ec3220f02acf', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (878, N'Fender Set - Mountain', N'FE-6654', 0, 1, NULL, 4, 3, 8.2205, 21.9800, NULL, NULL, NULL, NULL, 0, N'M ', NULL, NULL, 30, 121, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'e6e76c7f-c145-4cad-a9e8-b1e4e845a2c0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (879, N'All-Purpose Bike Stand', N'ST-1401', 0, 1, NULL, 4, 3, 59.4660, 159.0000, NULL, NULL, NULL, NULL, 0, N'M ', NULL, NULL, 27, 122, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c7bb564b-a637-40f5-b21b-cbf7e4f713be', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (880, N'Hydration Pack - 70 oz.', N'HY-1023-70', 0, 1, N'Silver', 4, 3, 20.5663, 54.9900, N'70', NULL, NULL, NULL, 0, N'S ', NULL, NULL, 32, 107, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a99d90c0-05e2-4e44-ad90-c55c9f0784de', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (881, N'Short-Sleeve Classic Jersey, S', N'SJ-0194-S', 0, 1, N'Yellow', 4, 3, 41.5723, 53.9900, N'S', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 21, 32, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'05b2e20f-2399-4cb3-9b49-b28d6649c104', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (882, N'Short-Sleeve Classic Jersey, M', N'SJ-0194-M', 0, 1, N'Yellow', 4, 3, 41.5723, 53.9900, N'M', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 21, 32, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'bbbf003b-367d-4d71-af71-10f50b6234a0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (883, N'Short-Sleeve Classic Jersey, L', N'SJ-0194-L', 0, 1, N'Yellow', 4, 3, 41.5723, 53.9900, N'L', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 21, 32, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'2d9f59b8-9f24-46eb-98ad-553e48bb9db9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (884, N'Short-Sleeve Classic Jersey, XL', N'SJ-0194-X', 0, 1, N'Yellow', 4, 3, 41.5723, 53.9900, N'XL', NULL, NULL, NULL, 0, N'S ', NULL, N'U ', 21, 32, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'906d42f6-c21f-4d20-b528-02ffdb55fd1e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (885, N'HL Touring Frame - Yellow, 60', N'FR-T98Y-60', 1, 1, N'Yellow', 500, 375, 601.7437, 1003.9100, N'60', N'CM ', N'LB ', CAST(3.08 AS Decimal(8, 2)), 1, N'T ', N'H ', N'U ', 16, 7, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c49679bd-96a9-4176-a7ed-5bc6d6444647', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (886, N'LL Touring Frame - Yellow, 62', N'FR-T67Y-62', 1, 1, N'Yellow', 500, 375, 199.8519, 333.4200, N'62', N'CM ', N'LB ', CAST(3.20 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'8d4d52a6-8abc-4c05-be4d-c067faf1a64e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (887, N'HL Touring Frame - Yellow, 46', N'FR-T98Y-46', 1, 1, N'Yellow', 500, 375, 601.7437, 1003.9100, N'46', N'CM ', N'LB ', CAST(2.96 AS Decimal(8, 2)), 1, N'T ', N'H ', N'U ', 16, 7, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'137675a7-34cd-4b7a-abe1-4e0eeb79b65d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (888, N'HL Touring Frame - Yellow, 50', N'FR-T98Y-50', 1, 1, N'Yellow', 500, 375, 601.7437, 1003.9100, N'50', N'CM ', N'LB ', CAST(3.00 AS Decimal(8, 2)), 1, N'T ', N'H ', N'U ', 16, 7, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'105ec6e5-30c5-4fe3-a08b-cb324c85323d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (889, N'HL Touring Frame - Yellow, 54', N'FR-T98Y-54', 1, 1, N'Yellow', 500, 375, 601.7437, 1003.9100, N'54', N'CM ', N'LB ', CAST(3.04 AS Decimal(8, 2)), 1, N'T ', N'H ', N'U ', 16, 7, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'12b1f317-c39b-48d0-b1a7-8018c60aea53', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (890, N'HL Touring Frame - Blue, 46', N'FR-T98U-46', 1, 1, N'Blue', 500, 375, 601.7437, 1003.9100, N'46', N'CM ', N'LB ', CAST(2.96 AS Decimal(8, 2)), 1, N'T ', N'H ', N'U ', 16, 7, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'8bbd3437-a58b-41a0-9503-fc14b23e7678', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (891, N'HL Touring Frame - Blue, 50', N'FR-T98U-50', 1, 1, N'Blue', 500, 375, 601.7437, 1003.9100, N'50', N'CM ', N'LB ', CAST(3.00 AS Decimal(8, 2)), 1, N'T ', N'H ', N'U ', 16, 7, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c4244f0c-abce-451b-a895-83c0e6d1f448', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (892, N'HL Touring Frame - Blue, 54', N'FR-T98U-54', 1, 1, N'Blue', 500, 375, 601.7437, 1003.9100, N'54', N'CM ', N'LB ', CAST(3.04 AS Decimal(8, 2)), 1, N'T ', N'H ', N'U ', 16, 7, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'e9aae947-6bc3-4909-8937-3e1cdcec8a8f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (893, N'HL Touring Frame - Blue, 60', N'FR-T98U-60', 1, 1, N'Blue', 500, 375, 601.7437, 1003.9100, N'60', N'CM ', N'LB ', CAST(3.08 AS Decimal(8, 2)), 1, N'T ', N'H ', N'U ', 16, 7, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'b01951a4-a581-4d10-9dc2-515da180f1b8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (894, N'Rear Derailleur', N'RD-2308', 1, 1, N'Silver', 500, 375, 53.9282, 121.4600, NULL, NULL, N'G  ', CAST(215.00 AS Decimal(8, 2)), 1, NULL, NULL, NULL, 9, 127, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'5ebfcf02-4e3e-443a-ad60-5aeef28dac76', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (895, N'LL Touring Frame - Blue, 50', N'FR-T67U-50', 1, 1, N'Blue', 500, 375, 199.8519, 333.4200, N'50', N'CM ', N'LB ', CAST(3.10 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'b78eccca-fa88-4071-9110-410585127e46', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (896, N'LL Touring Frame - Blue, 54', N'FR-T67U-54', 1, 1, N'Blue', 500, 375, 199.8519, 333.4200, N'54', N'CM ', N'LB ', CAST(3.14 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'0ff799c9-dd11-4b81-aaf7-65410017405b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (897, N'LL Touring Frame - Blue, 58', N'FR-T67U-58', 1, 1, N'Blue', 500, 375, 199.8519, 333.4200, N'58', N'CM ', N'LB ', CAST(3.16 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'ccd4fa47-7194-4bd0-909b-1fa4bd7916a7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (898, N'LL Touring Frame - Blue, 62', N'FR-T67U-62', 1, 1, N'Blue', 500, 375, 199.8519, 333.4200, N'62', N'CM ', N'LB ', CAST(3.20 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'08a211a5-dcd2-42d0-9276-64d92d4890a6', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (899, N'LL Touring Frame - Yellow, 44', N'FR-T67Y-44', 1, 1, N'Yellow', 500, 375, 199.8519, 333.4200, N'44', N'CM ', N'LB ', CAST(3.02 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'109cb7bc-6ec6-4a36-85c8-55b843b2ab12', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (900, N'LL Touring Frame - Yellow, 50', N'FR-T67Y-50', 1, 1, N'Yellow', 500, 375, 199.8519, 333.4200, N'50', N'CM ', N'LB ', CAST(3.10 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'285fd682-c647-49d1-b8f3-368a43c9cda0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (901, N'LL Touring Frame - Yellow, 54', N'FR-T67Y-54', 1, 1, N'Yellow', 500, 375, 199.8519, 333.4200, N'54', N'CM ', N'LB ', CAST(3.14 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'2536e3b2-d4da-49e6-965a-f612c2c8914f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (902, N'LL Touring Frame - Yellow, 58', N'FR-T67Y-58', 1, 1, N'Yellow', 500, 375, 199.8519, 333.4200, N'58', N'CM ', N'LB ', CAST(3.16 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'5d17ff1c-f50e-438f-a4e9-7c400fb762e7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (903, N'LL Touring Frame - Blue, 44', N'FR-T67U-44', 1, 1, N'Blue', 500, 375, 199.8519, 333.4200, N'44', N'CM ', N'LB ', CAST(3.02 AS Decimal(8, 2)), 1, N'T ', N'L ', N'U ', 16, 10, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'e9c17be7-f4dc-465e-ab73-c0198f37bfdd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (904, N'ML Mountain Frame-W - Silver, 40', N'FR-M63S-40', 1, 1, N'Silver', 500, 375, 199.3757, 364.0900, N'40', N'CM ', N'LB ', CAST(2.77 AS Decimal(8, 2)), 1, N'M ', N'M ', N'W ', 12, 15, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a7dde43e-f7d5-4075-a0c1-c866ad7aa154', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (905, N'ML Mountain Frame-W - Silver, 42', N'FR-M63S-42', 1, 1, N'Silver', 500, 375, 199.3757, 364.0900, N'42', N'CM ', N'LB ', CAST(2.81 AS Decimal(8, 2)), 1, N'M ', N'M ', N'W ', 12, 15, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'd4a2fcad-1e63-4ebd-863c-5a7c48d5b8d9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (906, N'ML Mountain Frame-W - Silver, 46', N'FR-M63S-46', 1, 1, N'Silver', 500, 375, 199.3757, 364.0900, N'46', N'CM ', N'LB ', CAST(2.85 AS Decimal(8, 2)), 1, N'M ', N'M ', N'W ', 12, 15, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'82025c63-7b28-412d-92c1-408e0e6ae646', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (907, N'Rear Brakes', N'RB-9231', 0, 1, N'Silver', 500, 375, 47.2860, 106.5000, NULL, NULL, N'G  ', CAST(317.00 AS Decimal(8, 2)), 1, NULL, NULL, NULL, 6, 128, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'5946f163-93f0-4141-b17e-55d9778cc274', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (908, N'LL Mountain Seat/Saddle', N'SE-M236', 0, 1, NULL, 500, 375, 12.0413, 27.1200, NULL, NULL, NULL, NULL, 1, N'M ', N'L ', NULL, 15, 79, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'4dab53c5-31e7-47d6-a5a0-940f8d4dad22', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (909, N'ML Mountain Seat/Saddle', N'SE-M798', 0, 1, NULL, 500, 375, 17.3782, 39.1400, NULL, NULL, NULL, NULL, 1, N'M ', N'M ', NULL, 15, 80, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'30222244-0fd8-4d28-8448-f2e658bf52bd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (910, N'HL Mountain Seat/Saddle', N'SE-M940', 0, 1, NULL, 500, 375, 23.3722, 52.6400, NULL, NULL, NULL, NULL, 1, N'M ', N'H ', NULL, 15, 81, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a96a5024-87de-488a-bf81-bc0c81f6cd18', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (911, N'LL Road Seat/Saddle', N'SE-R581', 0, 1, NULL, 500, 375, 12.0413, 27.1200, NULL, NULL, NULL, NULL, 1, N'R ', N'L ', NULL, 15, 82, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'31b9bc62-792b-4e7a-a24d-411dc76e0271', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (912, N'ML Road Seat/Saddle', N'SE-R908', 0, 1, NULL, 500, 375, 17.3782, 39.1400, NULL, NULL, NULL, NULL, 1, N'T ', N'M ', NULL, 15, 83, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'49845afe-a8cc-4354-a5d4-09d35bf7fb9e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (913, N'HL Road Seat/Saddle', N'SE-R995', 0, 1, NULL, 500, 375, 23.3722, 52.6400, NULL, NULL, NULL, NULL, 1, N'R ', N'H ', NULL, 15, 84, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'2befe629-4b2a-41a1-a009-df13ead69105', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (914, N'LL Touring Seat/Saddle', N'SE-T312', 0, 1, NULL, 500, 375, 12.0413, 27.1200, NULL, NULL, NULL, NULL, 1, N'T ', N'L ', NULL, 15, 66, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'7874a1d6-7a5b-412f-a2eb-c2f457b9603d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (915, N'ML Touring Seat/Saddle', N'SE-T762', 0, 1, NULL, 500, 375, 17.3782, 39.1400, NULL, NULL, NULL, NULL, 1, N'T ', N'M ', NULL, 15, 65, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'072acb72-7796-4bd0-9bbb-6efc29ac336c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (916, N'HL Touring Seat/Saddle', N'SE-T924', 0, 1, NULL, 500, 375, 23.3722, 52.6400, NULL, NULL, NULL, NULL, 1, N'T ', N'H ', NULL, 15, 67, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'0e158724-934d-4a64-991f-94fec00bdea8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (917, N'LL Mountain Frame - Silver, 42', N'FR-M21S-42', 1, 1, N'Silver', 500, 375, 144.5938, 264.0500, N'42', N'CM ', N'LB ', CAST(2.92 AS Decimal(8, 2)), 1, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'37bd4d2b-346b-4c6b-8f3f-85c084282529', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (918, N'LL Mountain Frame - Silver, 44', N'FR-M21S-44', 1, 1, N'Silver', 500, 375, 144.5938, 264.0500, N'44', N'CM ', N'LB ', CAST(2.96 AS Decimal(8, 2)), 1, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'393a4d00-7428-41f0-a48a-af26b00e9a9c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (919, N'LL Mountain Frame - Silver, 48', N'FR-M21S-48', 1, 1, N'Silver', 500, 375, 144.5938, 264.0500, N'48', N'CM ', N'LB ', CAST(3.00 AS Decimal(8, 2)), 1, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'8dfef6f2-91a8-4884-8949-b2551218b37a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (920, N'LL Mountain Frame - Silver, 52', N'FR-M21S-52', 1, 1, N'Silver', 500, 375, 144.5938, 264.0500, N'52', N'CM ', N'LB ', CAST(3.04 AS Decimal(8, 2)), 1, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'f230baac-5951-4eb1-b1e8-94c2ca2b37fa', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (921, N'Mountain Tire Tube', N'TT-M928', 0, 1, NULL, 500, 375, 1.8663, 4.9900, NULL, NULL, NULL, NULL, 0, N'M ', NULL, NULL, 37, 92, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'01a8c3fc-ed52-458e-a634-d5b6e2accfed', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (922, N'Road Tire Tube', N'TT-R982', 0, 1, NULL, 500, 375, 1.4923, 3.9900, NULL, NULL, NULL, NULL, 0, N'R ', NULL, NULL, 37, 93, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'ea442bd7-f69b-42d9-aa71-95e10b648f52', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (923, N'Touring Tire Tube', N'TT-T092', 0, 1, NULL, 500, 375, 1.8663, 4.9900, NULL, NULL, NULL, NULL, 0, N'T ', NULL, NULL, 37, 94, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'179fec38-cab5-4a47-bcff-31cfc9e43a3c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (924, N'LL Mountain Frame - Black, 42', N'FR-M21B-42', 1, 1, N'Black', 500, 375, 136.7850, 249.7900, N'42', N'CM ', N'LB ', CAST(2.92 AS Decimal(8, 2)), 1, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'faabd7fb-cb35-4bad-8857-ec71468686ad', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (925, N'LL Mountain Frame - Black, 44', N'FR-M21B-44', 1, 1, N'Black', 500, 375, 136.7850, 249.7900, N'44', N'CM ', N'LB ', CAST(2.96 AS Decimal(8, 2)), 1, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'47ab0300-7b55-4d35-a786-80190976b9b5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (926, N'LL Mountain Frame - Black, 48', N'FR-M21B-48', 1, 1, N'Black', 500, 375, 136.7850, 249.7900, N'48', N'CM ', N'LB ', CAST(3.00 AS Decimal(8, 2)), 1, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'408435aa-15c0-41e5-981f-32a8226af15f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (927, N'LL Mountain Frame - Black, 52', N'FR-M21B-52', 1, 1, N'Black', 500, 375, 136.7850, 249.7900, N'52', N'CM ', N'LB ', CAST(3.04 AS Decimal(8, 2)), 1, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'4800f4e6-99ea-4afd-a392-2cb05265d0d4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (928, N'LL Mountain Tire', N'TI-M267', 0, 1, NULL, 500, 375, 9.3463, 24.9900, NULL, NULL, NULL, NULL, 0, N'M ', N'L ', NULL, 37, 85, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'76060a93-949c-48ea-9b31-a593d6c14983', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (929, N'ML Mountain Tire', N'TI-M602', 0, 1, NULL, 500, 375, 11.2163, 29.9900, NULL, NULL, NULL, NULL, 0, N'M ', N'M ', NULL, 37, 86, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'daff9e11-6254-432d-8c4f-f06e52687184', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (930, N'HL Mountain Tire', N'TI-M823', 0, 1, NULL, 500, 375, 13.0900, 35.0000, NULL, NULL, NULL, NULL, 0, N'M ', N'H ', NULL, 37, 87, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'ddad25f5-0445-4b5c-8466-6446930ad8b8', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (931, N'LL Road Tire', N'TI-R092', 0, 1, NULL, 500, 375, 8.0373, 21.4900, NULL, NULL, NULL, NULL, 0, N'R ', N'L ', NULL, 37, 88, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'15b569a6-d172-42c2-a420-62ab5946cc80', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (932, N'ML Road Tire', N'TI-R628', 0, 1, NULL, 500, 375, 9.3463, 24.9900, NULL, NULL, NULL, NULL, 0, N'R ', N'M ', NULL, 37, 89, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'd1016cc5-c12b-4f05-915c-70fa062e4a64', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (933, N'HL Road Tire', N'TI-R982', 0, 1, NULL, 500, 375, 12.1924, 32.6000, NULL, NULL, NULL, NULL, 0, N'R ', N'H ', NULL, 37, 90, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c86de56a-5048-4b89-b7c7-56bc75c9bcee', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (934, N'Touring Tire', N'TI-T723', 0, 1, NULL, 500, 375, 10.8423, 28.9900, NULL, NULL, NULL, NULL, 0, N'T ', NULL, NULL, 37, 91, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'9d5ca300-5302-41e1-bca5-8ce5b93f26a5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (935, N'LL Mountain Pedal', N'PD-M282', 0, 1, N'Silver/Black', 500, 375, 17.9776, 40.4900, NULL, NULL, N'G  ', CAST(218.00 AS Decimal(8, 2)), 1, N'M ', N'L ', NULL, 13, 62, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'9fdd0c65-b2b0-4c6c-8704-3a9747be5174', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (936, N'ML Mountain Pedal', N'PD-M340', 0, 1, N'Silver/Black', 500, 375, 27.5680, 62.0900, NULL, NULL, N'G  ', CAST(215.00 AS Decimal(8, 2)), 1, N'M ', N'M ', NULL, 13, 63, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'274c86dc-439e-4469-9de8-7e9bd6455d0d', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (937, N'HL Mountain Pedal', N'PD-M562', 0, 1, N'Silver/Black', 500, 375, 35.9596, 80.9900, NULL, NULL, N'G  ', CAST(185.00 AS Decimal(8, 2)), 1, N'M ', N'H ', NULL, 13, 64, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a05464e8-6b4d-42b3-a4d6-8683136f4b66', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (938, N'LL Road Pedal', N'PD-R347', 0, 1, N'Silver/Black', 500, 375, 17.9776, 40.4900, NULL, NULL, N'G  ', CAST(189.00 AS Decimal(8, 2)), 1, N'R ', N'L ', NULL, 13, 68, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'2c7dd8c3-4c55-475f-ba58-f4baca520d72', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (939, N'ML Road Pedal', N'PD-R563', 0, 1, N'Silver/Black', 500, 375, 27.5680, 62.0900, NULL, NULL, N'G  ', CAST(168.00 AS Decimal(8, 2)), 1, N'R ', N'M ', NULL, 13, 69, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'216ad46f-bc3f-4862-b0e9-2e261e5a6059', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (940, N'HL Road Pedal', N'PD-R853', 0, 1, N'Silver/Black', 500, 375, 35.9596, 80.9900, NULL, NULL, N'G  ', CAST(149.00 AS Decimal(8, 2)), 1, N'R ', N'H ', NULL, 13, 70, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'44e96967-ab99-41ed-8b41-5bc70a5ca1a9', CAST(N'2014-02-08T10:03:55.510' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (941, N'Touring Pedal', N'PD-T852', 0, 1, N'Silver/Black', 500, 375, 35.9596, 80.9900, NULL, NULL, NULL, NULL, 1, N'T ', NULL, NULL, 13, 53, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'6967c816-3ebb-45fa-8547-cef00e08573e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (942, N'ML Mountain Frame-W - Silver, 38', N'FR-M63S-38', 1, 1, N'Silver', 500, 375, 199.3757, 364.0900, N'38', N'CM ', N'LB ', CAST(2.73 AS Decimal(8, 2)), 2, N'M ', N'M ', N'W ', 12, 15, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'ba3646b0-1487-426e-ab4e-57d42e6f9233', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (943, N'LL Mountain Frame - Black, 40', N'FR-M21B-40', 1, 1, N'Black', 500, 375, 136.7850, 249.7900, N'40', N'CM ', N'LB ', CAST(2.88 AS Decimal(8, 2)), 2, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'3050e4df-2bba-4c2b-bdcc-b4c89972db1c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (944, N'LL Mountain Frame - Silver, 40', N'FR-M21S-40', 1, 1, N'Silver', 500, 375, 144.5938, 264.0500, N'40', N'CM ', N'LB ', CAST(2.88 AS Decimal(8, 2)), 2, N'M ', N'L ', N'U ', 12, 8, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'756f862e-40cc-4dfc-b189-716d0dda5ff9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (945, N'Front Derailleur', N'FD-2342', 1, 1, N'Silver', 500, 375, 40.6216, 91.4900, NULL, NULL, N'G  ', CAST(88.00 AS Decimal(8, 2)), 1, NULL, NULL, NULL, 9, 103, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'448e9e7b-9548-4a4c-abb3-853686aa7517', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (946, N'LL Touring Handlebars', N'HB-T721', 1, 1, NULL, 500, 375, 20.4640, 46.0900, NULL, NULL, NULL, NULL, 1, N'T ', N'L ', NULL, 4, 47, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a2f1352e-45d0-42c4-aef3-60033073bb66', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (947, N'HL Touring Handlebars', N'HB-T928', 1, 1, NULL, 500, 375, 40.6571, 91.5700, NULL, NULL, NULL, NULL, 1, N'T ', N'H ', NULL, 4, 48, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'cb524e92-4fa8-4f6c-9993-60796856c654', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (948, N'Front Brakes', N'FB-9873', 0, 1, N'Silver', 500, 375, 47.2860, 106.5000, NULL, NULL, N'G  ', CAST(317.00 AS Decimal(8, 2)), 1, NULL, NULL, NULL, 6, 102, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c1813164-1b4b-42d1-9007-4e5f9aee0e19', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (949, N'LL Crankset', N'CS-4759', 1, 1, N'Black', 500, 375, 77.9176, 175.4900, NULL, NULL, N'G  ', CAST(600.00 AS Decimal(8, 2)), 1, NULL, N'L ', NULL, 8, 99, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'41d47371-4374-46d3-8d61-b07616ec54f0', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (950, N'ML Crankset', N'CS-6583', 1, 1, N'Black', 500, 375, 113.8816, 256.4900, NULL, NULL, N'G  ', CAST(635.00 AS Decimal(8, 2)), 1, NULL, N'M ', NULL, 8, 100, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'd3a7a02c-a3d5-4a04-9454-0c4e43772b78', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (951, N'HL Crankset', N'CS-9183', 1, 1, N'Black', 500, 375, 179.8156, 404.9900, NULL, NULL, N'G  ', CAST(575.00 AS Decimal(8, 2)), 1, NULL, N'H ', NULL, 8, 101, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'2c4a8956-7b72-48fe-b028-699e117b1daa', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (952, N'Chain', N'CH-0234', 0, 1, N'Silver', 500, 375, 8.9866, 20.2400, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 7, 98, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'5d27e2a5-27ec-4ccb-ba2c-fc980ffe6708', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (953, N'Touring-2000 Blue, 60', N'BK-T44U-60', 1, 1, N'Blue', 100, 75, 755.1508, 1214.8500, N'60', N'CM ', N'LB ', CAST(27.90 AS Decimal(8, 2)), 4, N'T ', N'M ', N'U ', 3, 35, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'f1bb3957-8d27-47f3-91ec-c71822d11436', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (954, N'Touring-1000 Yellow, 46', N'BK-T79Y-46', 1, 1, N'Yellow', 100, 75, 1481.9379, 2384.0700, N'46', N'CM ', N'LB ', CAST(25.13 AS Decimal(8, 2)), 4, N'T ', N'H ', N'U ', 3, 34, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'83b77413-8c8a-4af1-93e4-136edb7ff15f', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (955, N'Touring-1000 Yellow, 50', N'BK-T79Y-50', 1, 1, N'Yellow', 100, 75, 1481.9379, 2384.0700, N'50', N'CM ', N'LB ', CAST(25.42 AS Decimal(8, 2)), 4, N'T ', N'H ', N'U ', 3, 34, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'5ec991ad-8761-4a61-a318-312df3a78604', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (956, N'Touring-1000 Yellow, 54', N'BK-T79Y-54', 1, 1, N'Yellow', 100, 75, 1481.9379, 2384.0700, N'54', N'CM ', N'LB ', CAST(25.68 AS Decimal(8, 2)), 4, N'T ', N'H ', N'U ', 3, 34, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'1220b0f0-064d-46b7-8507-1fa758b77b9c', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (957, N'Touring-1000 Yellow, 60', N'BK-T79Y-60', 1, 1, N'Yellow', 100, 75, 1481.9379, 2384.0700, N'60', N'CM ', N'LB ', CAST(25.90 AS Decimal(8, 2)), 4, N'T ', N'H ', N'U ', 3, 34, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'bcd1a5a9-6140-4dc9-9620-689dc7e4c155', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (958, N'Touring-3000 Blue, 54', N'BK-T18U-54', 1, 1, N'Blue', 100, 75, 461.4448, 742.3500, N'54', N'CM ', N'LB ', CAST(29.68 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'a3ee6897-52fe-42e4-92ec-7a91e7bb905a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (959, N'Touring-3000 Blue, 58', N'BK-T18U-58', 1, 1, N'Blue', 100, 75, 461.4448, 742.3500, N'58', N'CM ', N'LB ', CAST(29.90 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'23d89cee-9f44-4f3e-b289-63de6ba2b737', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (960, N'Touring-3000 Blue, 62', N'BK-T18U-62', 1, 1, N'Blue', 100, 75, 461.4448, 742.3500, N'62', N'CM ', N'LB ', CAST(30.00 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'060192c9-bcd9-4260-b729-d6bcfadfb08e', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (961, N'Touring-3000 Yellow, 44', N'BK-T18Y-44', 1, 1, N'Yellow', 100, 75, 461.4448, 742.3500, N'44', N'CM ', N'LB ', CAST(28.77 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'5646c15a-68ad-4234-b328-254706cbccc5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (962, N'Touring-3000 Yellow, 50', N'BK-T18Y-50', 1, 1, N'Yellow', 100, 75, 461.4448, 742.3500, N'50', N'CM ', N'LB ', CAST(29.13 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'df85e805-af87-4fab-a668-c80f2a5b8a69', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (963, N'Touring-3000 Yellow, 54', N'BK-T18Y-54', 1, 1, N'Yellow', 100, 75, 461.4448, 742.3500, N'54', N'CM ', N'LB ', CAST(29.42 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'192becd1-f465-4194-88a2-ee57fed3a3c5', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (964, N'Touring-3000 Yellow, 58', N'BK-T18Y-58', 1, 1, N'Yellow', 100, 75, 461.4448, 742.3500, N'58', N'CM ', N'LB ', CAST(29.79 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'bed79f64-a53d-44a3-ace8-2baa425a5a54', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (965, N'Touring-3000 Yellow, 62', N'BK-T18Y-62', 1, 1, N'Yellow', 100, 75, 461.4448, 742.3500, N'62', N'CM ', N'LB ', CAST(30.00 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'd28b3872-5173-40a4-b12f-655524386cc7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (966, N'Touring-1000 Blue, 46', N'BK-T79U-46', 1, 1, N'Blue', 100, 75, 1481.9379, 2384.0700, N'46', N'CM ', N'LB ', CAST(25.13 AS Decimal(8, 2)), 4, N'T ', N'H ', N'U ', 3, 34, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'86990d54-6efb-4c53-9974-6c3b0297e222', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (967, N'Touring-1000 Blue, 50', N'BK-T79U-50', 1, 1, N'Blue', 100, 75, 1481.9379, 2384.0700, N'50', N'CM ', N'LB ', CAST(25.42 AS Decimal(8, 2)), 4, N'T ', N'H ', N'U ', 3, 34, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'68c0a818-2985-46eb-8255-0fb70919fa24', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (968, N'Touring-1000 Blue, 54', N'BK-T79U-54', 1, 1, N'Blue', 100, 75, 1481.9379, 2384.0700, N'54', N'CM ', N'LB ', CAST(25.68 AS Decimal(8, 2)), 4, N'T ', N'H ', N'U ', 3, 34, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'12280a8c-7578-4367-ba71-214bcc1e4792', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (969, N'Touring-1000 Blue, 60', N'BK-T79U-60', 1, 1, N'Blue', 100, 75, 1481.9379, 2384.0700, N'60', N'CM ', N'LB ', CAST(25.90 AS Decimal(8, 2)), 4, N'T ', N'H ', N'U ', 3, 34, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'dd70cf36-449a-43fd-839d-a84ee14c849a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (970, N'Touring-2000 Blue, 46', N'BK-T44U-46', 1, 1, N'Blue', 100, 75, 755.1508, 1214.8500, N'46', N'CM ', N'LB ', CAST(27.13 AS Decimal(8, 2)), 4, N'T ', N'M ', N'U ', 3, 35, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c0009006-715f-4b76-a05a-1a0d3adfb49a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (971, N'Touring-2000 Blue, 50', N'BK-T44U-50', 1, 1, N'Blue', 100, 75, 755.1508, 1214.8500, N'50', N'CM ', N'LB ', CAST(27.42 AS Decimal(8, 2)), 4, N'T ', N'M ', N'U ', 3, 35, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'84abda8f-0007-4bca-9a61-b2dea58866c3', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (972, N'Touring-2000 Blue, 54', N'BK-T44U-54', 1, 1, N'Blue', 100, 75, 755.1508, 1214.8500, N'54', N'CM ', N'LB ', CAST(27.68 AS Decimal(8, 2)), 4, N'T ', N'M ', N'U ', 3, 35, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'6dcfe2a3-3555-44e4-9116-6f6dbe448b8b', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (973, N'Road-350-W Yellow, 40', N'BK-R79Y-40', 1, 1, N'Yellow', 100, 75, 1082.5100, 1700.9900, N'40', N'CM ', N'LB ', CAST(15.35 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 27, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'237b16d9-53f2-4fd4-befe-48209e57aec3', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (974, N'Road-350-W Yellow, 42', N'BK-R79Y-42', 1, 1, N'Yellow', 100, 75, 1082.5100, 1700.9900, N'42', N'CM ', N'LB ', CAST(15.77 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 27, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'80bd3f8b-42c7-43d8-91f5-9fb6175287af', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (975, N'Road-350-W Yellow, 44', N'BK-R79Y-44', 1, 1, N'Yellow', 100, 75, 1082.5100, 1700.9900, N'44', N'CM ', N'LB ', CAST(16.13 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 27, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'0c61e8af-003d-4e4b-b5b7-02f01a26be26', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (976, N'Road-350-W Yellow, 48', N'BK-R79Y-48', 1, 1, N'Yellow', 100, 75, 1082.5100, 1700.9900, N'48', N'CM ', N'LB ', CAST(16.42 AS Decimal(8, 2)), 4, N'R ', N'M ', N'W ', 2, 27, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'ec4284dc-85fa-44a8-89ec-77fc9b71720a', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (977, N'Road-750 Black, 58', N'BK-R19B-58', 1, 1, N'Black', 100, 75, 343.6496, 539.9900, N'58', N'CM ', N'LB ', CAST(20.79 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 31, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'87b81a1a-a5b5-43d2-a20d-0230800490b9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (978, N'Touring-3000 Blue, 44', N'BK-T18U-44', 1, 1, N'Blue', 100, 75, 461.4448, 742.3500, N'44', N'CM ', N'LB ', CAST(28.77 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'4f638e15-2ed0-4193-90ce-47da580e01dd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (979, N'Touring-3000 Blue, 50', N'BK-T18U-50', 1, 1, N'Blue', 100, 75, 461.4448, 742.3500, N'50', N'CM ', N'LB ', CAST(29.13 AS Decimal(8, 2)), 4, N'T ', N'L ', N'U ', 3, 36, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'de305b62-88fc-465b-b23d-d8c0f7e6d361', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (980, N'Mountain-400-W Silver, 38', N'BK-M38S-38', 1, 1, N'Silver', 100, 75, 419.7784, 769.4900, N'38', N'CM ', N'LB ', CAST(26.35 AS Decimal(8, 2)), 4, N'M ', N'M ', N'W ', 1, 22, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'7a927632-99a4-4f24-adce-0062d2d113d9', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (981, N'Mountain-400-W Silver, 40', N'BK-M38S-40', 1, 1, N'Silver', 100, 75, 419.7784, 769.4900, N'40', N'CM ', N'LB ', CAST(26.77 AS Decimal(8, 2)), 4, N'M ', N'M ', N'W ', 1, 22, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'0a72791c-a984-4733-ae4e-2b4373cfd7cd', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (982, N'Mountain-400-W Silver, 42', N'BK-M38S-42', 1, 1, N'Silver', 100, 75, 419.7784, 769.4900, N'42', N'CM ', N'LB ', CAST(27.13 AS Decimal(8, 2)), 4, N'M ', N'M ', N'W ', 1, 22, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'4ea4fe06-aaea-42d4-a9d9-69f6a9a4a042', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (983, N'Mountain-400-W Silver, 46', N'BK-M38S-46', 1, 1, N'Silver', 100, 75, 419.7784, 769.4900, N'46', N'CM ', N'LB ', CAST(27.42 AS Decimal(8, 2)), 4, N'M ', N'M ', N'W ', 1, 22, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'0b0c8ee4-ff2d-438e-9cac-464783b86191', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (984, N'Mountain-500 Silver, 40', N'BK-M18S-40', 1, 1, N'Silver', 100, 75, 308.2179, 564.9900, N'40', N'CM ', N'LB ', CAST(27.35 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'b96c057b-6416-4851-8d59-bcb37c8e6e51', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (985, N'Mountain-500 Silver, 42', N'BK-M18S-42', 1, 1, N'Silver', 100, 75, 308.2179, 564.9900, N'42', N'CM ', N'LB ', CAST(27.77 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'b8d1b5d9-8a39-4097-a04a-56e95559b534', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (986, N'Mountain-500 Silver, 44', N'BK-M18S-44', 1, 1, N'Silver', 100, 75, 308.2179, 564.9900, N'44', N'CM ', N'LB ', CAST(28.13 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'e8cec794-e8e2-4312-96a7-4832e573d3fc', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (987, N'Mountain-500 Silver, 48', N'BK-M18S-48', 1, 1, N'Silver', 100, 75, 308.2179, 564.9900, N'48', N'CM ', N'LB ', CAST(28.42 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'77ef419f-481f-40b9-bdb9-7e6678e550e3', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (988, N'Mountain-500 Silver, 52', N'BK-M18S-52', 1, 1, N'Silver', 100, 75, 308.2179, 564.9900, N'52', N'CM ', N'LB ', CAST(28.68 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'cad60945-183e-4ab3-a70c-3f5bac6bf134', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (989, N'Mountain-500 Black, 40', N'BK-M18B-40', 1, 1, N'Black', 100, 75, 294.5797, 539.9900, N'40', N'CM ', N'LB ', CAST(27.35 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'28287157-3f06-487b-8531-bee8a37329e4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (990, N'Mountain-500 Black, 42', N'BK-M18B-42', 1, 1, N'Black', 100, 75, 294.5797, 539.9900, N'42', N'CM ', N'LB ', CAST(27.77 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'f5752c9c-56ba-41a7-83fd-139da28c15fa', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (991, N'Mountain-500 Black, 44', N'BK-M18B-44', 1, 1, N'Black', 100, 75, 294.5797, 539.9900, N'44', N'CM ', N'LB ', CAST(28.13 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'c7852127-2fb8-4959-b5a3-de5a8d6445e4', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (992, N'Mountain-500 Black, 48', N'BK-M18B-48', 1, 1, N'Black', 100, 75, 294.5797, 539.9900, N'48', N'CM ', N'LB ', CAST(28.42 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'75752e26-a3b6-4264-9b06-f23a4fbdc5a7', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (993, N'Mountain-500 Black, 52', N'BK-M18B-52', 1, 1, N'Black', 100, 75, 294.5797, 539.9900, N'52', N'CM ', N'LB ', CAST(28.68 AS Decimal(8, 2)), 4, N'M ', N'L ', N'U ', 1, 23, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'69ee3b55-e142-4e4f-aed8-af02978fbe87', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (994, N'LL Bottom Bracket', N'BB-7421', 1, 1, NULL, 500, 375, 23.9716, 53.9900, NULL, NULL, N'G  ', CAST(223.00 AS Decimal(8, 2)), 1, NULL, N'L ', NULL, 5, 95, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'fa3c65cd-0a22-47e3-bdf6-53f1dc138c43', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (995, N'ML Bottom Bracket', N'BB-8107', 1, 1, NULL, 500, 375, 44.9506, 101.2400, NULL, NULL, N'G  ', CAST(168.00 AS Decimal(8, 2)), 1, NULL, N'M ', NULL, 5, 96, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'71ab847f-d091-42d6-b735-7b0c2d82fc84', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (996, N'HL Bottom Bracket', N'BB-9108', 1, 1, NULL, 500, 375, 53.9416, 121.4900, NULL, NULL, N'G  ', CAST(170.00 AS Decimal(8, 2)), 1, NULL, N'H ', NULL, 5, 97, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'230c47c5-08b2-4ce3-b706-69c0bdd62965', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (997, N'Road-750 Black, 44', N'BK-R19B-44', 1, 1, N'Black', 100, 75, 343.6496, 539.9900, N'44', N'CM ', N'LB ', CAST(19.77 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 31, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'44ce4802-409f-43ab-9b27-ca53421805be', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (998, N'Road-750 Black, 48', N'BK-R19B-48', 1, 1, N'Black', 100, 75, 343.6496, 539.9900, N'48', N'CM ', N'LB ', CAST(20.13 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 31, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'3de9a212-1d49-40b6-b10a-f564d981dbde', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
INSERT [Production].[Product] ([ProductID], [Name], [ProductNumber], [MakeFlag], [FinishedGoodsFlag], [Color], [SafetyStockLevel], [ReorderPoint], [StandardCost], [ListPrice], [Size], [SizeUnitMeasureCode], [WeightUnitMeasureCode], [Weight], [DaysToManufacture], [ProductLine], [Class], [Style], [ProductSubcategoryID], [ProductModelID], [SellStartDate], [SellEndDate], [DiscontinuedDate], [rowguid], [ModifiedDate]) VALUES (999, N'Road-750 Black, 52', N'BK-R19B-52', 1, 1, N'Black', 100, 75, 343.6496, 539.9900, N'52', N'CM ', N'LB ', CAST(20.42 AS Decimal(8, 2)), 4, N'R ', N'L ', N'U ', 2, 31, CAST(N'2013-05-30T00:00:00.000' AS DateTime), NULL, NULL, N'ae638923-2b67-4679-b90e-abbab17dca31', CAST(N'2014-02-08T10:01:36.827' AS DateTime))
GO
SET IDENTITY_INSERT [Production].[Product] OFF
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (1, 1, N'A', 1, 408, N'47a24246-6c43-48eb-968f-025738a8a410', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (1, 6, N'B', 5, 324, N'd4544d7d-caf5-46b3-ab22-5718dcc26b5e', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (1, 50, N'A', 5, 353, N'bff7dc60-96a8-43ca-81a7-d6d2ed3000a8', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (2, 1, N'A', 2, 427, N'f407c07a-ca14-4684-a02c-608bd00c2233', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (2, 6, N'B', 1, 318, N'ca1ff2f4-48fb-4960-8d92-3940b633e4c1', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (2, 50, N'A', 6, 364, N'd38cfbee-6347-47b1-b033-0e278cca03e2', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (3, 1, N'A', 7, 585, N'e18a519b-fb5e-4051-874c-58cd58436c95', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (3, 6, N'B', 9, 443, N'3c860c96-15ff-4df4-91d7-b237ff64480f', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (3, 50, N'A', 10, 324, N'1339e5e3-1f8e-4b82-a447-a8666a264f0c', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (4, 1, N'A', 6, 512, N'6beaf0a0-971a-4ce1-96fe-692807d5dc00', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (4, 6, N'B', 10, 422, N'2c82427a-63f1-4877-a1f6-a27b4d201eb6', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (4, 50, N'A', 11, 388, N'fd912e69-efa2-4ab7-82a4-03f5101af11c', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (316, 5, N'A', 11, 532, N'1ee3dbd3-2a7e-47dc-af99-1b585575efb9', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (316, 10, N'B', 1, 388, N'cb2a24d7-9b70-4140-8836-9eb7592621d3', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (316, 50, N'B', 8, 441, N'36b375a3-022a-45bf-b425-dbffaac3145a', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (317, 1, N'C', 1, 283, N'c04fc1cf-1d2b-4480-ba13-64c6ef780f4b', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (317, 5, N'A', 1, 158, N'83332a73-48a9-401d-95f4-385c944d716f', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (317, 50, N'A', 21, 152, N'4072c90c-a867-4f64-882f-ec45ada1b79c', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (318, 1, N'C', 2, 136, N'f287efd3-ccc5-4344-9f4a-e588bbf29801', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (318, 5, N'A', 2, 171, N'b62232e8-90b5-4da1-bfe1-453aa1917efc', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (318, 50, N'A', 22, 132, N'd758c516-d9bf-4aa6-8e57-f5bd6d568f97', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (319, 1, N'C', 3, 308, N'7367821f-bb8b-4102-86ed-a7fb7054f8e1', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (319, 5, N'A', 3, 184, N'bfb760ac-0767-4f76-8670-49488d0f731d', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (319, 50, N'A', 23, 305, N'febbcc76-2764-48a3-a086-77d1e883137c', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (320, 1, N'C', 4, 481, N'bd134ecd-d4da-406c-a7ce-7ec40f9bcf34', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (320, 5, N'A', 4, 372, N'deedba07-171b-4038-88a5-a57166e8f446', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (320, 50, N'A', 24, 283, N'4fef28b3-6652-4d3a-999b-00784d401e42', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (321, 1, N'C', 6, 569, N'afdbcf09-10f8-4f3c-86e1-379310ffbfe3', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (321, 5, N'A', 6, 540, N'65fc4167-6a09-46c9-a262-632b945b2fbb', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (321, 50, N'A', 26, 641, N'b291ee86-cb6e-4d74-b47d-b8b0794ca9c4', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (322, 1, N'C', 7, 622, N'7726d791-a784-4754-b144-bb25c9e2f38a', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (322, 5, N'A', 7, 587, N'04da1bb9-9625-4e71-b861-93f64a3a53dc', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (322, 50, N'A', 27, 475, N'02d51ed0-af15-44e9-a355-86433710b0c0', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (323, 1, N'C', 35, 603, N'f7863985-c001-44d5-a939-554c67df203a', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (323, 5, N'A', 12, 568, N'bd637bc5-eb67-4424-8f92-dca208276e6f', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (323, 50, N'A', 28, 513, N'968dae62-ea98-49fe-b190-d1ec7b9e9f0c', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (324, 1, N'C', 36, 585, N'c6e3bcde-5f39-40ef-b253-ad2b018ab1cc', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (324, 5, N'A', 13, 568, N'aec9bf74-0e06-4181-b6c7-c8fa41126a4e', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (324, 50, N'A', 29, 476, N'cee69fd4-22ec-4d83-b9ec-c0af63967839', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (325, 1, N'H', 1, 569, N'624ac935-868e-40e0-8668-950451746f90', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (325, 6, N'G', 1, 540, N'cf93bbfb-a391-4313-814d-82d62fbe1afb', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (325, 60, N'A', 1, 641, N'd42750b2-2c8a-4457-9dda-4b43cbdc4594', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (326, 1, N'H', 2, 622, N'71a75809-8b9e-4f87-8687-8bdd367f2f72', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (326, 6, N'G', 2, 587, N'67777062-a86a-4fed-bf8f-f7641edf9444', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (326, 60, N'A', 2, 475, N'eadaa7f8-e962-46c4-977f-05538c494bcd', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (327, 5, N'K', 1, 408, N'61add309-16ef-40d4-9853-548f4efdc40c', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (327, 10, N'F', 1, 443, N'553c89bb-2063-48e3-966f-b557efd1f4e9', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (327, 50, N'B', 9, 513, N'a3aad1f8-ba38-4f6c-99d3-dbc5e2bc9774', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (328, 5, N'A', 8, 568, N'bf52885d-74a3-422b-8c75-8a46350d9a6d', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (328, 10, N'D', 1, 585, N'c6c865b4-0db2-44b7-9d5f-12d43b75f803', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (328, 50, N'A', 14, 476, N'ea52800f-a344-4c4a-9e37-d48a67fbbb6c', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (329, 5, N'A', 9, 558, N'7a1417a3-21ea-4da1-b3d1-e85bab7d8a9e', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (329, 10, N'D', 2, 576, N'ad6db38a-997b-4ad8-a03b-7f38f8c3b7e1', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (329, 50, N'A', 15, 467, N'6cb842cb-7b2f-4d89-9187-3c81630fb907', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (330, 5, N'A', 10, 548, N'ad971345-bf63-47d4-975d-c56a6081ff0a', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (330, 10, N'D', 3, 566, N'ff9889d7-e242-4761-ace0-eb0d95147fa8', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (330, 50, N'A', 16, 457, N'e6d96af6-7e4c-46f7-9a2c-5e94cf403888', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (331, 5, N'J', 5, 574, N'd52d418a-c295-4cb9-a410-8ee245fc61a7', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (331, 10, N'C', 6, 441, N'1d251426-738f-4b5a-96c2-3c9226e18905', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (331, 50, N'A', 12, 390, N'85990921-d43f-41f9-9095-5863d687bb43', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (332, 5, N'J', 6, 344, N'171a680f-7a90-45df-980d-48757f4b4eb4', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (332, 10, N'C', 7, 233, N'7a23dc3c-9bdc-4aa5-ba41-0c4e9f4b6e18', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (332, 50, N'A', 13, 267, N'c08f7632-254c-43ea-bf10-8ec79bbb4374', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (341, 1, N'E', 4, 372, N'00eed5ca-525c-4174-885d-846deefc223e', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (341, 50, N'G', 10, 392, N'afb7ca1e-6f91-459b-b508-31d773564ac8', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (341, 60, N'S', 1, 339, N'a07991c9-ce2f-4081-a5f3-ac4de98ba485', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (342, 1, N'E', 5, 369, N'fea262c8-d498-4b77-b8fe-82258aff6ad6', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (342, 50, N'G', 12, 388, N'ec6c3097-17f6-4108-a55b-3c239a965360', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (342, 60, N'G', 11, 336, N'7542fce0-b9f7-42ec-9671-a4809c568743', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (343, 1, N'E', 6, 568, N'a82c0072-9a18-4318-a62a-92304eeb0443', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (343, 50, N'S', 3, 606, N'656a9a1f-6f1e-4d75-9ca5-fcd0fe3cc27b', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (343, 60, N'S', 2, 499, N'0f5d6037-a8c6-49b4-92b8-a50dc5880372', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (344, 1, N'E', 7, 358, N'000c77ab-c1d6-4f8e-a66d-ed8068140d8c', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (344, 50, N'G', 14, 332, N'6ad6b192-073e-49fe-97b0-1567c4f40778', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (344, 60, N'G', 13, 382, N'0a5ec50b-6c5d-4e08-b126-516eba2006d3', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (345, 1, N'E', 8, 321, N'05e0ee89-8462-4b52-bc3c-7c7735214c05', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (345, 50, N'G', 15, 315, N'd4a2cfda-f3a3-4a65-80b5-ccc70b046d4c', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (345, 60, N'S', 4, 300, N'331a2238-a0e4-4685-adfd-f5b4f1af9a5f', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (346, 1, N'E', 9, 585, N'11bc6f46-10dc-4771-ac9a-e2179f1b2461', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (346, 50, N'S', 6, 476, N'38f17071-fe89-4cb2-ace2-ccb8f0cf0f7e', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (346, 60, N'S', 5, 641, N'24a6f94a-da92-4566-91c8-59218a6cb9d9', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (347, 1, N'E', 10, 318, N'7295a247-2228-44b0-8218-0cb9908a5ac4', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (347, 50, N'G', 17, 246, N'87dd4e3b-4a78-47a4-9d45-685a43c91b8e', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (347, 60, N'G', 16, 332, N'206aafb1-15f7-4dc4-b8ee-b3eb772eeb4d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (348, 1, N'E', 11, 323, N'cdab8141-2896-4b9d-a332-5f726ee6cb23', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (348, 50, N'S', 8, 251, N'0d8fe9aa-d64a-4842-9856-42aad33de485', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (348, 60, N'S', 7, 337, N'3e598d72-9120-42ea-9fa7-a0e2929e2538', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (349, 1, N'E', 12, 328, N'7109150f-14a3-4eac-b72f-e128b3044abf', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (349, 50, N'G', 18, 256, N'604c83fd-5918-4951-b8a2-2d047c0768ab', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (349, 60, N'S', 9, 342, N'332c44e7-f145-4bb2-bb36-fe8f9bd93596', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (350, 5, N'J', 2, 622, N'50be1fe4-c767-41d9-bd46-748a31a0768d', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (350, 10, N'C', 3, 406, N'2e276e50-efa2-4c02-b1c1-4999e16a1799', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (350, 50, N'A', 2, 313, N'9a23c432-ba8b-4f05-b7b4-94e451f01c24', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (351, 5, N'J', 3, 179, N'd1f587a6-a29f-47a6-88e5-30e9eca52ab3', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (351, 10, N'C', 4, 281, N'8727068f-3b49-4031-ae74-31de17693d6b', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (351, 50, N'A', 3, 145, N'a1962b7f-ec0e-43ac-80bb-a04e7cf0e31d', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (352, 5, N'J', 10, 300, N'f8bef986-c583-4428-a515-358cebeff3b9', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (352, 10, N'C', 1, 278, N'71ea95cb-6490-4db9-beb3-38e565f45630', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (352, 50, N'A', 20, 195, N'1e6baff0-75fc-4c17-9b8f-164db2531564', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (355, 1, N'D', 16, 276, N'8ad0c765-f104-4435-afeb-0bbd74d6b08c', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (355, 6, N'H', 16, 257, N'2d1d737d-8877-4b9e-baec-da6fe962e19c', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (355, 50, N'C', 1, 289, N'983c8fb4-b5a3-4de8-97c0-c1d050e5848a', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (356, 1, N'D', 17, 262, N'6de6fdd4-8de6-478a-a7cb-312e68edd8c6', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (356, 6, N'H', 17, 243, N'a03019e1-cd99-43ed-a1c7-6ff207ad3ce0', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (356, 50, N'C', 2, 275, N'd604707d-b5c2-49cf-a983-8934523e186d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (357, 1, N'D', 18, 248, N'a492ec7b-d2a7-48f0-9bc6-66c779afead3', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (357, 6, N'H', 18, 228, N'866ac631-6597-4b06-b019-8f040f552e49', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (357, 50, N'C', 3, 260, N'e879cfeb-5115-421b-bfe2-7376b72afb4c', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (358, 1, N'D', 19, 233, N'ddab150a-235c-432a-83d2-0822db1b057d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (358, 6, N'H', 19, 214, N'536b55d9-5dcf-4af1-bc64-f19dd5022086', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (358, 50, N'C', 4, 246, N'0511f131-8a69-4975-aa97-54f366d8b211', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (359, 1, N'C', 8, 369, N'46bc0376-ad5c-4bdc-99d4-55a959f32163', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (359, 6, N'R', 1, 360, N'2d7484f7-f157-43e1-b33f-87ce2f94b360', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (359, 50, N'E', 1, 374, N'52b0910c-93b1-47a6-b2b7-d78f14ebb914', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (360, 1, N'C', 9, 363, N'b16bdad8-4778-41ab-984d-d2de2927e3b8', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (360, 6, N'R', 2, 353, N'73de1d45-d603-4c5c-bd6a-78a49943b502', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (360, 50, N'E', 2, 368, N'01add3d7-e329-4167-9b7c-f3a2c31a25e1', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (361, 1, N'C', 10, 499, N'55b9556b-a6bf-4be1-8c4b-94510d875d60', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (361, 6, N'R', 3, 601, N'4351724c-18c7-4e48-8e69-f0158e60e823', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (361, 50, N'E', 3, 531, N'f340eb47-1825-4e24-a2f8-c3daaac9d1bc', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (362, 1, N'C', 11, 377, N'2d215f50-e878-41ff-be20-c30a74a4502a', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (362, 6, N'R', 4, 315, N'd0ea3625-0c56-4380-8363-bf79b3df9870', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (362, 50, N'E', 4, 334, N'9ead4efe-86a5-4787-94f3-045d1636ef3d', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (363, 1, N'C', 12, 499, N'2e2bc76c-4ee0-47a1-9a60-ea46e3659e4a', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (363, 6, N'R', 5, 643, N'7322a3fa-0786-4be6-a232-6e9613b4ccd0', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (363, 50, N'E', 5, 619, N'ba60b595-1709-4bb1-a224-d9d56dc7c70a', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (364, 1, N'C', 13, 368, N'0336df16-7e36-4c21-bd6e-059123a74698', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (364, 6, N'R', 6, 358, N'015f9608-e327-446f-b9a1-9b35386ca195', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (364, 50, N'E', 6, 326, N'85014570-7bc6-4553-b8f5-40009658e395', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (365, 1, N'C', 14, 411, N'517e8517-442e-4498-bffe-6ed02467eece', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (365, 6, N'R', 7, 691, N'f7e2000a-42bc-4763-b78e-b8deb7aee3af', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (365, 50, N'E', 7, 619, N'84066d8c-dece-401e-8e3b-8513db83ba0e', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (366, 1, N'C', 15, 318, N'9cfe6d84-71ed-4032-88b4-1b0920740597', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (366, 6, N'R', 8, 299, N'09eb5c91-f9c3-4c08-9dd4-7b1b5e8b54bb', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (366, 50, N'E', 8, 412, N'df23c794-808e-417d-953b-4499f97a8768', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (367, 1, N'C', 16, 643, N'5f1c3630-0c24-433a-8cf3-40f4b40606db', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (367, 6, N'R', 9, 689, N'70153711-7aaf-4da3-993d-9fce9cf137cb', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (367, 50, N'E', 9, 569, N'2cd85f13-0b80-4312-afbe-750362c45f34', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (368, 1, N'C', 17, 369, N'abf23795-41ab-4e61-9697-725825f2c0e3', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (368, 6, N'R', 10, 360, N'a693aa01-3638-452c-abf8-f50552be92d9', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (368, 50, N'E', 10, 374, N'35cc6156-ae35-4251-9856-bf15db9ed147', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (369, 1, N'C', 18, 363, N'952f0127-cb2a-4ffb-90cb-e92eb69e7498', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (369, 6, N'R', 11, 353, N'79a3d625-139b-4a85-bf48-5c5405e5cac6', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (369, 50, N'E', 11, 368, N'46ca8287-b665-444d-80b1-2d4afca5c039', CAST(N'2014-07-28T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (370, 1, N'C', 19, 252, N'6a2188af-2b6f-4d9b-917e-86c78968a293', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (370, 6, N'R', 12, 155, N'd9fe0218-5528-4001-b11d-aa39001c3297', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (370, 50, N'E', 12, 476, N'a4937ba2-ac13-4bdf-bf6f-75a94b3408aa', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (371, 1, N'C', 20, 585, N'acbb836b-9ccb-4a59-887b-394899fba961', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (371, 6, N'R', 13, 649, N'da646c40-bef6-4855-bdf3-ba1c29907b99', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (371, 50, N'E', 13, 547, N'fc7e0e74-3314-4f38-89b1-e809c2e518c7', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (372, 1, N'C', 21, 281, N'44970271-6e78-4913-96fb-c000ca9be1f7', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (372, 6, N'R', 14, 344, N'68466df2-9832-4a64-9645-6fa5783a1f97', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (372, 50, N'E', 14, 272, N'4679584b-36e7-4292-b2d4-540eb0baa4ff', CAST(N'2014-08-03T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (373, 1, N'C', 22, 284, N'e95fdb19-5e04-4f6f-b4ac-bec51f93004c', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (373, 6, N'R', 15, 347, N'f888a98f-2614-4ac6-af4c-0bc0b0e87661', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (373, 50, N'E', 15, 275, N'4eff169f-6b4d-4d55-bc97-90a5fcf3c9d6', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (374, 1, N'C', 23, 288, N'7e32714a-875c-4446-a94e-26ca13f33b58', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (374, 6, N'R', 16, 350, N'8a8f612f-a214-4aa0-ae77-f0ab1518c29d', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (374, 50, N'E', 16, 278, N'5926bfe2-bf96-469e-bbdd-7217faae18c5', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (375, 1, N'C', 24, 291, N'4bd22b4e-4b98-499d-b3a2-a5d848a93b9f', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (375, 6, N'R', 17, 353, N'708e8581-b834-4122-b095-dcada0a33139', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (375, 50, N'E', 17, 281, N'29695d30-491f-4125-86de-acf27267c6fd', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (376, 1, N'C', 25, 585, N'9117d3dd-c5fc-4274-826b-6a1e018592e7', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (376, 6, N'R', 18, 649, N'59b30ee5-aa05-4069-914a-01a4860daccc', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (376, 50, N'E', 18, 547, N'cfd04477-1d95-4065-ad38-7261f8267d24', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (377, 1, N'C', 26, 249, N'64451b09-a02d-4a97-97e7-3fd1f603656c', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (377, 6, N'R', 19, 299, N'ae60c83a-108b-439e-87cc-f209f0f734f1', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (377, 50, N'E', 19, 393, N'd4f21a3b-f52f-4c25-a3db-07450393a97e', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (378, 1, N'C', 27, 244, N'7f9de9ea-c846-4941-8d0b-67bf96cf3ecf', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (378, 6, N'R', 20, 294, N'ba32e523-8a33-4721-8eda-f8b7fbb66f84', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (378, 50, N'E', 20, 388, N'403788ea-0fb8-4a35-95a5-6fad3ba02b5f', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (379, 1, N'C', 28, 323, N'426d1c6b-0c59-42d4-8d48-8d62bbd19532', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (379, 6, N'R', 21, 897, N'78120df1-86f2-4b14-b0d4-782fa1fdf229', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (379, 50, N'E', 21, 691, N'd94aba0d-56f0-4fbd-bc2c-1917c8bec2dd', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (380, 1, N'C', 29, 156, N'7aae8563-add3-47a3-8d6d-d20a9ec019b5', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (380, 6, N'R', 22, 264, N'9fde5eba-17e5-4a45-a8e7-ba45aac01314', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (380, 50, N'E', 22, 350, N'2940c078-3e2b-4151-a6d5-61713f51672c', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (381, 1, N'C', 30, 163, N'87b51434-9d2d-4491-bd93-5d7c38c2305e', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (381, 6, N'R', 23, 270, N'f7583df4-5c0c-4db3-bd31-1bb00fe8d6c2', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (381, 50, N'E', 23, 356, N'9acdb34c-5342-472f-a185-904eae6d9113', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (382, 1, N'C', 31, 169, N'2d6d664e-2220-49e2-a263-4c53be5c2065', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (382, 6, N'R', 24, 276, N'9e0934f9-7ba9-4def-b901-dfba82c75c5d', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (382, 50, N'E', 24, 363, N'288103e3-3b2c-437c-b350-98f3126cdf6d', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (383, 1, N'C', 32, 587, N'8ff37375-bdd1-44b8-8085-8fbcbf59b061', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (383, 6, N'R', 25, 676, N'1bf6a76b-16c5-44d6-8c8f-ba0458fbeec0', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (383, 50, N'E', 25, 638, N'f21e0ced-ebb8-4298-a5d2-b4c86019fd3d', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (384, 1, N'C', 33, 299, N'17080020-ed82-44d6-bc22-70d48fcb8010', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (384, 6, N'R', 26, 217, N'd70c97ea-ba23-4b1d-9b94-cb8da7420b08', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (384, 50, N'E', 26, 304, N'8ef1bd2a-dbaa-4a4d-82e6-8ca69a67f2c1', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (385, 1, N'C', 34, 619, N'b2e01d6b-62f3-4731-b05c-b3c726300ad0', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (385, 6, N'R', 27, 526, N'63c7faf1-9573-4a7f-b9bb-ce0d5999abbd', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (385, 50, N'E', 27, 633, N'2af00b07-8f20-41b4-9141-facc338d46ea', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (386, 1, N'D', 1, 148, N'2bb4d4d9-b826-4a68-8a81-cbddf6dd8847', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (386, 6, N'R', 28, 192, N'c5bcd527-544a-4c25-9091-d71ce3b6f481', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (386, 50, N'E', 28, 385, N'52a0bc53-3db4-4d59-937e-d27b88eae7ed', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (387, 1, N'D', 2, 524, N'c3f68247-c17d-4c33-b932-51845ce15b41', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (387, 6, N'R', 29, 710, N'6b8a8f43-0ea9-419a-bb6a-1880f396f8ba', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (387, 50, N'E', 29, 654, N'0c6d6619-80df-414e-90cf-d16cf513762a', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (388, 1, N'D', 3, 292, N'5cd35680-ea12-4299-b8a5-c2c34a1c1b2d', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (388, 6, N'R', 30, 140, N'adb0e9a5-3e3b-4d32-84a4-dcabb4800b99', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (388, 50, N'E', 30, 366, N'fb84c5fb-1f0a-430a-b0a7-60b5a6039459', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (389, 1, N'D', 4, 657, N'1bc79480-0bd2-406f-a8bc-0044b056bff1', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (389, 6, N'R', 31, 691, N'53e256e6-3196-4632-a449-265998c40575', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (389, 50, N'E', 31, 460, N'e7bff7c6-0c4e-4739-81dc-b1343fcf0ae6', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (390, 1, N'D', 5, 292, N'a9b93fbd-bcde-4ed6-bfb3-1e2f9a970f29', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (390, 6, N'R', 32, 140, N'f8867b2b-1a45-40e5-ae45-e7179b1cf0b6', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (390, 50, N'E', 32, 366, N'9983eea3-d2e9-466b-8a45-9dcba1505cd0', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (391, 1, N'D', 6, 296, N'214cd58d-24f1-4937-b06a-855c53e17511', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (391, 6, N'R', 33, 144, N'aaad4a7d-9a70-4d16-9de2-46d82415b7ef', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (391, 50, N'E', 33, 369, N'e3f44ca3-8527-45f9-91f8-1d863e1ae757', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (392, 1, N'D', 7, 299, N'e6726b0d-1f11-40f9-890b-4bea7c2384f6', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (392, 6, N'R', 34, 147, N'8a1608d2-8c67-44bc-81a2-41fa849af519', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (392, 50, N'E', 34, 372, N'01545f11-5822-43e1-821c-bbe6c3d3f0c9', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (393, 1, N'D', 8, 603, N'ce7edf53-f13d-45e7-8bcd-707c4b53e1c5', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (393, 6, N'R', 35, 780, N'cfd67534-3382-43d6-9de3-5a275d809ea3', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (393, 50, N'E', 35, 497, N'aef7ac8c-d595-4dfb-b41e-9536fed7a993', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (394, 1, N'D', 9, 302, N'72090dae-c90e-4b90-b752-e7518c177bb2', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (394, 6, N'R', 36, 150, N'd77fdae7-048d-4ee9-be37-42eb722c8117', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (394, 50, N'E', 36, 459, N'3a5be20f-ecb6-45b2-a948-98c47bece24c', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (395, 1, N'D', 10, 281, N'abf6b89a-1931-4179-b851-39a49cd83fff', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (395, 6, N'R', 37, 355, N'72d6c080-9f91-4dac-8e7a-ee4161947a65', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (395, 50, N'E', 37, 148, N'f0ab1a66-42ba-4b10-9e75-61e0e6fd8463', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (396, 1, N'D', 11, 636, N'290ef0f5-e1bb-417a-a8d8-1d5e25e791fc', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (396, 6, N'R', 38, 585, N'f7225878-8a03-4467-8184-c81a8f9bc451', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (396, 50, N'E', 38, 603, N'7b36c058-dc0c-4404-94a2-700e6eeb7de9', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (397, 1, N'D', 12, 339, N'f38a392f-df6e-4b83-aaaf-44fca31f2443', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (397, 6, N'R', 39, 550, N'c5c52bc6-895c-4900-a4d6-9699db354c9d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (397, 50, N'E', 39, 763, N'de7cf261-ed7a-4b59-b06e-5aaa930120fc', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (398, 5, N'B', 1, 372, N'5c40b94f-9012-4610-a30e-614e09b73790', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (398, 10, N'B', 4, 404, N'1d6c48d5-8351-49c1-988c-5b54c8fc19f2', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (398, 20, N'A', 3, 550, N'be99281e-ba29-4e3b-8ceb-40eab801e74e', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (399, 5, N'B', 2, 366, N'41f877c5-b77c-4f3e-9de1-e0065248ff2e', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (399, 10, N'B', 5, 398, N'a36caeb3-7e04-467e-a884-58a076a04844', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (399, 20, N'A', 4, 544, N'2519471e-47b8-40b0-ad78-1d9fa2e1922e', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (400, 5, N'B', 3, 260, N'0f2050d4-f337-49e1-af12-1183e9ecaf68', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (400, 10, N'B', 2, 246, N'7dc91844-6c3c-4542-9781-78c256e14f40', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (400, 20, N'A', 1, 284, N'dcca4742-7bbb-4308-8129-c1324f1c7da3', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (401, 5, N'B', 4, 283, N'01700343-1c46-4765-845f-9196dafe6b24', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (401, 10, N'B', 3, 212, N'15c1e385-25c0-480d-9b5e-d295483e1027', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (401, 20, N'A', 2, 302, N'1b7b59ff-cac1-4abd-9a54-c912ba36c5b8', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (402, 1, N'F', 1, 316, N'4a28a4c6-b3e2-47fa-867e-0aa76682ec90', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (402, 6, N'G', 3, 353, N'0d8ab28e-40b9-4097-8686-97d9d4e182f7', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (402, 50, N'T', 1, 321, N'2f9d3973-e6e5-47dc-bc73-1e1b914141d4', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (403, 1, N'F', 2, 313, N'7b91307f-1f98-4514-bf52-f5cfa41128a3', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (403, 6, N'G', 4, 350, N'641bbe33-c957-40d1-b4ec-22a940fc9487', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (403, 50, N'T', 2, 318, N'446d7922-61ca-4fec-8584-0c8339abf855', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (404, 1, N'F', 3, 310, N'0f610bfa-cec6-4e2e-99ef-61a91042f6a1', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (404, 6, N'G', 5, 347, N'c27d3114-c6dc-4d6f-814e-cb704b152f9d', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (404, 50, N'T', 3, 315, N'f511cf72-5b77-4a7b-b777-7f943eb95b1d', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (405, 1, N'F', 4, 307, N'6cbf468f-fc5c-4ce0-8e43-bf761624b7e2', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (405, 6, N'G', 6, 344, N'9030ea68-2f28-43fc-ae2c-fdd57444fc2b', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (405, 50, N'T', 4, 312, N'a172a0d0-e4d2-40ff-828a-394edc93cec0', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (406, 1, N'F', 5, 304, N'5ae120bf-9489-4d02-9569-0ad129fb5611', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (406, 6, N'G', 7, 340, N'977516d5-833c-426e-adba-6a4ea45e60a0', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (406, 50, N'T', 5, 308, N'ab0ed5c3-6a8d-4d65-8189-482345c0dd8e', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (407, 1, N'F', 6, 460, N'76523859-c463-4470-95e7-121c6349d07f', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (407, 6, N'G', 8, 587, N'83ff6efa-ebe6-4566-accb-732b98c89554', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (407, 50, N'T', 6, 625, N'223515b8-0201-45e3-8b14-0f73f2e84df0', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (408, 1, N'F', 7, 417, N'aebcff82-ad40-492a-ad72-e7a68bb20ef1', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (408, 6, N'G', 9, 344, N'6c83a526-e9fb-4ada-84a3-c2085d12c29e', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (408, 50, N'T', 7, 296, N'1c4a5ee5-55b2-45f6-8f4b-a9a55b8375e2', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (409, 1, N'F', 8, 414, N'02272bf0-1f64-4ea9-b73d-8e2c6a1f05e2', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (409, 6, N'G', 10, 340, N'9ffe546f-343f-4cf1-a165-c43bbf1fc0d8', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (409, 50, N'T', 8, 292, N'5bdd9df8-3286-4f69-bd79-b731c7d13111', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (410, 1, N'F', 9, 411, N'59311c05-9bc0-4ff4-8810-97416188cf9b', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (410, 6, N'G', 11, 337, N'c0b2029a-f0d6-4efb-97fd-96428834a46b', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (410, 50, N'T', 9, 289, N'9cab72da-293c-499d-8612-5ec854f4b021', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (411, 1, N'F', 10, 603, N'9872c93f-c4aa-49bc-adde-81230134cd8d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (411, 6, N'G', 12, 552, N'9cb6e6af-c5f7-48d6-afcd-fddc14aec26c', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (411, 50, N'T', 10, 459, N'0f2194fc-d2ea-4dbb-819f-ca2c24122a01', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (412, 1, N'F', 11, 299, N'10ee3c79-2238-4ff6-8dc8-974d7fa5557d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (412, 6, N'G', 13, 321, N'f1f92cf8-627a-48e5-82bc-2ea3b58d991d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (412, 50, N'T', 11, 156, N'c6ddfd7c-6b86-46e6-849c-63e5a84b8e06', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (413, 1, N'F', 12, 641, N'bc6df6cd-aa94-45c9-aa74-110d339a4711', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (413, 6, N'G', 14, 603, N'0eb6d655-fbd8-4565-b7e1-d069062fe50a', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (413, 50, N'T', 12, 459, N'a5c4352d-1103-433c-b801-1e49c53a5e8e', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (414, 1, N'F', 13, 427, N'24a9d4af-ec4d-411c-982e-49a7db4517ab', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (414, 6, N'G', 15, 321, N'c9c50b9d-81f5-48c6-8c92-3aec825dcc27', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (414, 50, N'T', 13, 371, N'333f9ecd-4933-4f5f-a820-4bcfbf657825', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (415, 1, N'F', 14, 422, N'6807ed12-c75d-4ae7-b031-13d7de3be0fe', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (415, 6, N'G', 16, 316, N'd523afaf-1a7b-4f2c-b9e7-2c6ead6e3035', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (415, 50, N'T', 14, 366, N'61712e05-6ee1-4511-8c4d-ec89265250f5', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (416, 1, N'F', 15, 417, N'9c9d0459-5ac6-4d54-82b4-6775d283210c', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (416, 6, N'G', 17, 312, N'b0b1f1e0-a2ef-4be0-a63f-e1bf2bda3362', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (416, 50, N'T', 15, 361, N'253db65c-4833-4766-bc10-265984f6f9cb', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (417, 1, N'F', 16, 572, N'8bdee515-541e-41a6-a6f7-bf40d2173ac4', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (417, 6, N'G', 18, 627, N'029b2a2e-2d6a-4c38-b38b-a986a4df2452', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (417, 50, N'T', 16, 516, N'84d6a6a6-1b31-48e6-a5ef-8515b8212cf6', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (418, 1, N'F', 17, 248, N'065fb4a3-a7ef-4ac5-9510-ce89317719b1', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (418, 6, N'G', 19, 283, N'3a260d71-dd89-4d5e-9271-7a1ceab13395', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (418, 50, N'T', 17, 388, N'3a9618d7-4f46-47a6-a224-78a4240cf165', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (419, 1, N'F', 18, 246, N'b81b94b3-9e2f-4675-ae20-ac358b46a455', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (419, 6, N'G', 20, 281, N'91663a44-ea3b-4c72-955d-daccc2cb74aa', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (419, 50, N'T', 18, 387, N'86e5e622-e1fb-4308-8ddf-2c6ee02e45e7', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (420, 1, N'F', 19, 244, N'166b592e-b6be-44b1-aa69-41f2d31dca73', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (420, 6, N'G', 21, 280, N'eaf15bae-fba9-42d6-b37c-b512f5e78c7e', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (420, 50, N'T', 19, 385, N'a81d45ea-b957-4835-a47d-09b57a8d2fde', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (421, 1, N'F', 20, 243, N'54cc5882-b786-4e61-bdf5-808011295001', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (421, 6, N'G', 22, 278, N'dcc01697-ee43-4f64-bc08-edca25eb8f16', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (421, 50, N'T', 20, 384, N'77e0026b-f62a-4e23-b8d9-d088f5321e9d', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (422, 1, N'K', 1, 620, N'b1a6ee01-fb3c-45a5-b5b1-46274213ba5b', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (422, 6, N'G', 23, 515, N'4f5216d1-7ee9-4a1e-afbc-2477d7d6ef45', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (422, 50, N'T', 21, 497, N'309003bd-8c77-42f1-8489-b22ac60ac940', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (423, 1, N'K', 2, 619, N'0a3219bb-74b2-4c85-8474-f6a4a5096a40', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (423, 6, N'G', 24, 513, N'0b685703-951b-42a0-930a-705f7497e430', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (423, 50, N'U', 1, 496, N'65a0613e-ffe1-4857-9bd6-76bfcbda05c9', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (424, 1, N'K', 3, 617, N'cfe9b367-934e-4adb-a58f-06dbb4fc02e6', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (424, 6, N'G', 25, 512, N'70f516ff-5f50-4628-adb3-79ec23d339bf', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (424, 50, N'U', 2, 494, N'3a8cb523-d799-46eb-8eae-ba7562610615', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (425, 1, N'K', 4, 616, N'4f52c183-b4a9-4a5e-852d-3bac4fe10364', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (425, 6, N'G', 26, 510, N'2e55d18c-5ed1-4bce-9f4d-182c03a9114b', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (425, 50, N'U', 3, 492, N'165a33b3-ac7f-4717-a451-9e2c96250799', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (426, 1, N'K', 5, 614, N'5a0b316a-a2ee-4e00-8ff9-99a1d3181e6d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (426, 6, N'G', 27, 508, N'806f5772-158d-4442-8be6-2a9e35eb288b', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (426, 50, N'U', 4, 491, N'ca1fed88-1bc8-487e-af6b-bd156612b780', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (427, 1, N'K', 6, 612, N'ee3a9b1e-8ce3-4ad3-8731-9b0ff331d22d', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (427, 6, N'G', 28, 507, N'abfe1a52-43fb-409e-a76a-df8642dfcc59', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (427, 50, N'U', 5, 489, N'90a7e004-8bdb-40ae-98a0-6b756dcf7e32', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (428, 1, N'K', 7, 611, N'02d98068-7a9f-4d08-b8bc-a135495a8c42', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (428, 6, N'G', 29, 505, N'66c31f3d-1470-4d19-bee3-7b56b1841731', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (428, 50, N'U', 6, 488, N'746a5cfa-178e-4045-b870-b1a8d5afe693', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (429, 1, N'K', 8, 609, N'1da04543-2c1d-4e32-8309-f122af94d599', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (429, 6, N'G', 30, 504, N'45f36d5d-9959-4601-9174-6db78ecb24b5', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (429, 50, N'U', 7, 486, N'615e3ae7-3a4c-4a8f-b6c4-310d19471f1f', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (430, 1, N'K', 9, 608, N'fa52e937-c81e-4b9b-8aaf-9b17b1e9e221', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (430, 6, N'G', 31, 502, N'e4c5cf3a-dacf-41f2-aeab-6aba23f6fbcd', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (430, 50, N'U', 8, 484, N'3c97af79-e74c-47d8-b037-f0551018ee1c', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (431, 1, N'K', 10, 611, N'ef83378a-74b7-427c-a920-06580c15625a', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (431, 6, N'G', 32, 505, N'8d949e7f-113b-4c9b-910e-07d20f8343e4', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (431, 50, N'U', 9, 488, N'a59c4676-9d41-4736-a5fa-2d5d59777325', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (432, 1, N'K', 11, 614, N'8e88e613-7a21-4f85-911a-6c4561a80e16', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (432, 6, N'G', 33, 508, N'12cc3875-07a1-4c8b-abbf-8e62a6f6056f', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (432, 50, N'U', 10, 491, N'3263d2c9-a9f5-4cf4-b5e3-b81bdc698c26', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (433, 1, N'L', 1, 617, N'2c79989b-6065-44f7-a5b7-658516bb0670', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (433, 6, N'G', 34, 512, N'f0beaabf-3da2-4a6f-b6f7-80aeeaf86b72', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (433, 50, N'U', 11, 494, N'45bac6b1-de5d-4ccc-a8ed-0af8a5222403', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (434, 1, N'L', 2, 620, N'730ffa60-7617-4b4a-a157-96dec935d340', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (434, 6, N'G', 35, 515, N'c76ea25c-7d83-4d0e-a0c1-a4a61105673f', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (434, 50, N'U', 12, 497, N'2ce641a9-6bbf-459c-965e-79a5673ec082', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (435, 1, N'L', 3, 624, N'a111baee-2267-4926-8287-51889a4a3244', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (435, 6, N'G', 36, 518, N'79378e6b-713e-4470-a2d2-7f47816b51c8', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (435, 50, N'U', 13, 500, N'bbb56309-e9ec-4cc8-972b-631b4da70ac0', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (436, 1, N'L', 4, 627, N'e8d235a9-57e3-4539-902a-d1587fa70d79', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (436, 6, N'G', 37, 521, N'37538d3d-1754-47f3-a843-435a6751cd59', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (436, 50, N'U', 14, 504, N'e0da77f8-eda7-4308-a459-97f71fa0e845', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (437, 1, N'L', 5, 630, N'310726d7-9203-4cf8-a664-9f8055db5bf7', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (437, 6, N'G', 38, 524, N'28030a94-323c-440a-b516-db48db308e93', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (437, 50, N'U', 15, 507, N'c2bdd324-5764-4dd6-aa17-743141089e3f', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (438, 1, N'L', 6, 633, N'e7aa0b5b-e281-4236-8451-4f2be7c94092', CAST(N'2014-07-24T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (438, 6, N'G', 39, 528, N'f16e555c-0de6-402e-a030-782267ed81c9', CAST(N'2014-07-24T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (438, 50, N'U', 16, 510, N'a0a4a2ef-bcc4-4790-87e7-90d7764f24d1', CAST(N'2014-07-24T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (439, 1, N'L', 7, 636, N'7bced1b1-d4fc-4e22-888e-d683f01a6aa3', CAST(N'2014-07-24T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (439, 6, N'G', 40, 531, N'a893bfee-a048-49ac-a4e5-e83738defca6', CAST(N'2014-07-24T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (439, 50, N'U', 17, 513, N'b9b38c6e-76bf-4570-8869-c36bd7a3d167', CAST(N'2014-07-24T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (440, 1, N'L', 8, 640, N'21f25c10-15d8-4a35-8622-70f1a609f94b', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (440, 6, N'G', 41, 534, N'2e3b8f70-5823-4002-85e8-8934aff487e2', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (440, 50, N'U', 18, 516, N'c2ec33e5-3dc5-41ab-ad97-399d385d6cb3', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (441, 1, N'L', 9, 635, N'03cfad0f-c227-4579-99be-e8f31e753103', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (441, 6, N'G', 42, 529, N'02525804-006e-4cc2-a644-a66c826914b4', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (441, 50, N'U', 19, 512, N'3ace5fee-309d-4374-8ac4-9b1053bb2130', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (442, 1, N'L', 10, 630, N'9d45b955-0c3e-4a5b-8dac-b449a70f46d5', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (442, 6, N'G', 43, 524, N'01b17f75-48ba-4f6e-b266-664734b7b924', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (442, 50, N'U', 20, 507, N'1d595c46-49ff-439a-b8d4-f86113ed5eaf', CAST(N'2014-07-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (443, 1, N'L', 11, 625, N'53dd8159-9863-446e-9352-0fbabf08898d', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (443, 6, N'G', 44, 520, N'276f7119-7483-459e-a6c3-2df6b8801c84', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (443, 50, N'U', 21, 502, N'1fff7f27-7a93-4364-af4b-5f761857352a', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (444, 1, N'L', 12, 620, N'd736e942-d015-42d8-a3ad-8595d93fd92f', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (444, 6, N'G', 45, 515, N'4de6a1eb-06be-4d01-ac35-894404d282f0', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (444, 50, N'U', 22, 497, N'fb6c4585-0563-4c15-b021-8039be938a8c', CAST(N'2014-08-04T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (445, 1, N'H', 3, 616, N'eb4f2a7b-bf1a-417e-ad5f-bc996fbf2725', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (445, 6, N'G', 46, 510, N'953370d9-f166-486c-9455-a1eeef84218c', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (445, 50, N'U', 23, 492, N'cf3adfa8-f900-42b7-a660-37b30c87aae6', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (446, 1, N'H', 4, 611, N'd4cfb8e1-4651-4673-8dcc-362f442606c5', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (446, 6, N'G', 47, 505, N'f58f510e-90e2-486f-b3d4-0c017c6eb2ec', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (446, 50, N'U', 24, 488, N'1d51f20b-b4e3-44bf-83a4-e8bcaf6a0eeb', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (447, 1, N'H', 5, 606, N'ecc8a876-cb00-4079-a1f5-849199c1ede9', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (447, 6, N'G', 48, 500, N'ae2d642c-ab0d-4ce1-881e-ce2cd5fff797', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (447, 50, N'U', 25, 483, N'fd36b8aa-28e6-4b1e-9e87-469fc427ff4d', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (448, 1, N'H', 6, 601, N'2d045980-7e93-42ef-9f51-29513f4859ad', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (448, 6, N'G', 49, 496, N'56ad65e1-04d4-4248-89fb-6027c28844fd', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (448, 50, N'U', 26, 478, N'0824ca20-ca01-4320-9d08-6dccd75040c3', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (449, 1, N'H', 7, 596, N'1fab07d7-a1b8-44cb-b815-820c649b5a1a', CAST(N'2014-07-27T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (449, 6, N'G', 50, 491, N'7f8631bb-e073-40d4-a228-44192956bc03', CAST(N'2014-07-27T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (449, 50, N'U', 27, 473, N'cc26b5ef-f6ce-4a1c-bc88-60d6d00ca778', CAST(N'2014-07-27T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (450, 1, N'H', 8, 592, N'becbb6f8-9e74-47fb-88f9-fe1047c1a9ca', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (450, 6, N'G', 51, 486, N'60b176fc-9041-4c31-bd87-db8ceb1431b4', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (450, 50, N'U', 28, 468, N'94547166-8beb-4ab6-bbfe-21aeba2ae77e', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (451, 1, N'H', 9, 595, N'8d54e1a6-2e2a-4bb9-86ef-fc1b80b2cc7b', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (451, 6, N'G', 52, 489, N'8207b94f-7bc7-408f-b27f-a5abd4dc5a3a', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (451, 50, N'U', 29, 472, N'd4efb693-cf65-4ea4-9eff-b731af88d13c', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (452, 1, N'H', 10, 598, N'5ac3fa47-4da3-480e-8f8c-9c9c50acae47', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (452, 6, N'G', 53, 492, N'ffdf35c4-3bed-460b-9821-26d51a95baf6', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (452, 50, N'U', 30, 475, N'a13cca2d-03b3-474e-86fa-db2a1c27d231', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (453, 1, N'H', 11, 601, N'f3fac1d4-7609-44a0-ba12-b0a8f3025410', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (453, 6, N'G', 54, 496, N'cab945f5-dd54-43ad-88fd-a25c200e8acc', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (453, 50, N'U', 31, 478, N'7311df42-8339-425e-9589-6bd31e1e971f', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (454, 1, N'H', 12, 604, N'a57d34f7-25b7-432a-988c-fadad614ce89', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (454, 6, N'G', 55, 499, N'1bb8ff62-7587-4686-a863-bd55fe20cb5e', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (454, 50, N'U', 32, 481, N'4cde0cc3-3428-460b-8111-987ab4df6ef8', CAST(N'2014-08-02T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (455, 1, N'H', 13, 608, N'8aebebe3-b29d-4376-be79-c5095831b02e', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (455, 6, N'G', 56, 502, N'b4ec8722-a9cb-4f5f-b233-5530a9760a3d', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (455, 50, N'U', 33, 484, N'8d384b50-cbba-4eb0-99d3-5448d8698106', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (456, 1, N'H', 14, 611, N'2e56d990-74a7-4129-9846-e5f806b6de85', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (456, 6, N'G', 57, 505, N'4c335b51-c1d0-476e-9eea-6bb03a3eb43c', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (456, 50, N'U', 34, 488, N'4dd252b2-8337-4268-9b89-cac0d2236daf', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (457, 1, N'H', 15, 614, N'1370408d-13b4-4c6c-850f-63a6163b2b3d', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (457, 6, N'G', 58, 508, N'9ec6eff6-bc45-4442-94e2-632c289d0d1b', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (457, 50, N'U', 35, 491, N'13fad7bf-527e-4429-921a-529474f0a179', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (458, 1, N'H', 16, 617, N'c6e8524f-b6b3-4eb6-b25e-2f604e79ae3d', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (458, 6, N'G', 59, 512, N'bbde3406-8255-449e-899e-bdb32ad2eba3', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (458, 50, N'U', 36, 494, N'ce01779c-632f-48ac-897a-7214de4e3389', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (459, 1, N'H', 17, 620, N'557a3ed2-69f7-4601-868d-34f465b8c904', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (459, 6, N'G', 60, 515, N'ed7edce2-86dd-4241-965a-1af5e4cf18fd', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (459, 50, N'U', 37, 497, N'6961f234-056a-4abf-a1cc-674110152992', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (460, 1, N'H', 18, 624, N'46547c0b-79fb-41a6-8d11-a1591d44ff84', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (460, 6, N'G', 61, 518, N'c7e472d5-a7f6-4a22-95ee-09ec93dee0b1', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (460, 50, N'U', 38, 500, N'b7f5a6b7-3763-4a3b-9e41-ba063b256778', CAST(N'2014-08-07T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (461, 1, N'G', 19, 627, N'eda01cef-3b81-4d75-8670-40db0e8aa961', CAST(N'2014-07-18T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (461, 6, N'H', 1, 521, N'20e1c2cc-4fd4-4ec1-a159-929042ec47f6', CAST(N'2014-07-18T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (461, 50, N'K', 1, 504, N'2d2984bc-582a-40c4-bb95-d9936a33d36e', CAST(N'2014-07-18T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (462, 1, N'G', 2, 310, N'c3b6216e-6d48-4ab3-ad2f-eed611c2395b', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (462, 6, N'H', 2, 204, N'ba32112a-8f7e-4f19-8c15-da0690a9cb40', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (462, 50, N'K', 2, 187, N'b72dccac-5fde-41dd-bd6f-6f05fdd053c1', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (463, 1, N'G', 3, 499, N'e294536d-7f5a-4024-8466-353b39048c6c', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (463, 6, N'H', 3, 566, N'4aeb951e-8c65-4c28-a5ab-e53b0d8cc9d5', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (463, 50, N'K', 3, 620, N'7ca89d43-f69e-4cd3-a8e7-53a418bff63c', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (464, 1, N'G', 4, 500, N'01abd22d-700d-4459-baaa-ca7503372755', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (464, 6, N'H', 4, 568, N'd49aa8d2-4fec-4fc4-b343-f2c8e2d8f988', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (464, 50, N'K', 4, 622, N'1eca084d-c032-47ff-9fa4-204f34ef3e72', CAST(N'2014-08-06T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (465, 1, N'G', 5, 502, N'ee6ae42c-2c83-4cc2-9309-505213bb9208', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (465, 6, N'H', 5, 569, N'0679645a-45a0-4b7c-8816-ea95e8c033b8', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (465, 50, N'K', 5, 624, N'd886564a-8a3a-41cf-8cd7-83902095e53b', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (466, 1, N'G', 8, 504, N'6294ecb8-195a-40c7-8199-e2cfcf5a0c92', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (466, 6, N'H', 6, 571, N'7cc8444b-55dd-46f4-bfa1-797597508e7b', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (466, 50, N'K', 6, 625, N'0d85905e-6003-46db-937f-9eee681d8314', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (467, 1, N'G', 7, 505, N'02929f08-040b-48e8-b859-e351476b2773', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (467, 6, N'H', 7, 572, N'49c9c319-356b-4d73-952b-f0d59dda9355', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (467, 50, N'K', 7, 627, N'ebefd4d6-f12a-4eeb-9584-2a6289f2cb51', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (468, 1, N'G', 3, 507, N'fda6b140-92b3-4e53-bac5-8a4b2e848fdb', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (468, 6, N'H', 8, 574, N'e1d4b9b3-e9a0-4b0e-ba76-587336907407', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (468, 50, N'K', 8, 628, N'0326587f-9a2e-4bfb-8017-2b006b61a963', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (469, 1, N'J', 4, 508, N'cf285ff3-9881-4836-a3bf-6ff502199e7e', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (469, 6, N'H', 9, 576, N'd4f4af2d-5215-45e8-8c6a-4d1c3b27edc8', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (469, 50, N'K', 9, 630, N'd7bba80a-dfbd-4929-9e30-673f94f735d4', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (470, 1, N'J', 5, 510, N'accba237-3706-42c4-afe8-0fb6bb8fd37c', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (470, 6, N'H', 10, 577, N'f3fc1c07-317b-47b5-85d5-d57dae2aa709', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (470, 50, N'K', 10, 632, N'85454fd3-9f47-4f6f-b38a-89258e127154', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (471, 1, N'J', 6, 512, N'6203d596-5106-4997-9b9f-a40de5d62b80', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (471, 6, N'H', 11, 579, N'43489450-d406-4486-b34d-2700c4dd13b4', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (471, 50, N'K', 11, 633, N'c659b805-fee3-45a8-befe-14dc52e1c25c', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (472, 1, N'J', 7, 513, N'4475b9f1-8fe0-4c38-a05c-f15b0216fea8', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (472, 6, N'H', 12, 580, N'2adac0c5-91bf-4b1d-b154-1896b42beb4e', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (472, 50, N'K', 12, 635, N'453994cb-4b54-4131-8cc6-ddc48f85908a', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (473, 1, N'J', 8, 515, N'2a2bccf9-eb66-4667-ade7-3ea56bfa7240', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (473, 6, N'H', 13, 582, N'eeeb74f6-dc41-4b85-8258-9905dbc4e837', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (473, 50, N'K', 13, 636, N'd5dfe757-4edc-4bbf-91ec-79eae89b44ac', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (474, 1, N'J', 9, 516, N'479b1bc1-f815-44ae-a696-91a2a3375706', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (474, 6, N'H', 14, 584, N'fd82f153-b473-4cef-8f91-8a33600eb904', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (474, 50, N'K', 14, 638, N'9a5778bd-ee98-4366-a40c-3b0b35388c4b', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (475, 1, N'J', 10, 518, N'cdb7b866-0fec-4cd0-b93d-7ea2edc291ec', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (475, 6, N'H', 15, 585, N'173b2a0e-0fca-4d75-a25e-887ab7523c6a', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (475, 50, N'K', 15, 640, N'2acb4d37-de06-4050-a6d9-6c6bb4465417', CAST(N'2014-08-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (476, 5, N'D', 0, 324, N'436f1d08-3a45-42bd-8dd1-b6fa551b0bf3', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (476, 10, N'A', 0, 404, N'a592f45b-9da4-4875-a75f-ceffe443a6cc', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (476, 20, N'B', 0, 355, N'3a134806-6a8e-4e17-b471-365515f2153e', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (477, 2, N'B', 0, 403, N'56adde61-b9f7-4558-900f-1ef3dcac50f2', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (477, 5, N'D', 0, 323, N'3200aab0-0da9-4f7d-809a-f5a0ade43569', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (477, 10, N'A', 0, 353, N'1e085ebc-8780-434d-ac03-8c98c230449b', CAST(N'2014-07-19T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (478, 2, N'B', 0, 497, N'939ec4e8-7c4d-40cb-b663-0c98cf85163f', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (478, 5, N'D', 0, 568, N'5c1065c6-ded6-4569-892f-455fe0a920ac', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (478, 10, N'A', 0, 622, N'b3dc38ec-98d7-4f0e-99c9-9b45e0fb2e0a', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (479, 2, N'C', 0, 441, N'507b5e1e-3fcb-487d-bf9b-705556c228ed', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (479, 5, N'E', 0, 390, N'0be6dfb1-9845-4106-ab26-962fd5f80872', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (479, 10, N'C', 0, 198, N'712165a2-789d-4848-8d60-8153ab5f27f5', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (480, 2, N'C', 0, 689, N'4fa134c6-6049-4a9a-8a30-f2f1e8159d63', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (480, 5, N'E', 0, 515, N'd327c8e5-8e39-4ea2-b81e-43423f1fd068', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (480, 10, N'C', 0, 457, N'e3a857df-eed7-4760-8e91-70a7bcf28937', CAST(N'2014-07-25T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (481, 2, N'C', 0, 427, N'1ef33b99-f9aa-445f-9355-ddb2d6201712', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (481, 5, N'E', 0, 374, N'5d341ae1-d5c5-4b4f-aca1-4520e5b87bb9', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (481, 10, N'C', 0, 196, N'1fd00477-eb28-4c02-80e3-c4cb70cdf107', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (482, 2, N'D', 0, 321, N'9eaf665b-08c1-4456-aa2a-536c607bacfc', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (482, 5, N'R', 10, 427, N'3e33c96a-4001-4312-9e27-767676334a6b', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (482, 10, N'L', 0, 176, N'45a769b5-15be-4405-9c1f-42dbef34fd71', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (483, 2, N'D', 0, 691, N'53431b4e-2948-4d8f-a9d1-b2a9dcda30d8', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (483, 5, N'R', 0, 531, N'e83dd8e1-26f1-41e6-98a5-c88004be7a00', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (483, 10, N'L', 0, 459, N'c9400641-1b3a-4a84-baf0-16b110a5d4b2', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (484, 2, N'D', 0, 427, N'0a8cd779-6c31-448a-8f48-d86430ac93f9', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (484, 5, N'R', 0, 374, N'89e015f9-84d7-4200-ab8b-fc6b86b9bd5d', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (484, 10, N'L', 0, 196, N'1ceb98a2-4ef9-493b-ad32-5c9c530d064d', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (485, 2, N'D', 0, 321, N'96758939-c6b3-444b-821c-519d6917d89c', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (485, 5, N'R', 0, 427, N'500f898b-8f62-420f-ab9b-2f20c24ba319', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (485, 10, N'L', 0, 176, N'7781927b-bb91-4e18-8ee2-88e7761f1d5a', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (486, 2, N'D', 0, 689, N'39ae00fa-4be0-4686-bac2-e21941266a72', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (486, 5, N'R', 0, 515, N'50f68020-73a0-4c92-89fd-3a6cda2ce599', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (486, 10, N'L', 0, 457, N'437e0279-1e93-4e7d-8510-ef7dfcbf0146', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (487, 2, N'D', 0, 331, N'99793199-1e85-40df-b211-5b3139811a07', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (487, 5, N'R', 0, 337, N'fde61861-1afc-41c3-a3fc-1c41719450eb', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (487, 10, N'L', 0, 324, N'c298805f-0aed-4f20-81a3-c41abd3f0ef2', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (488, 2, N'D', 0, 312, N'309bd92c-69f8-4a82-a89e-7e48985bcb99', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (488, 5, N'R', 0, 318, N'9553fc57-b940-434a-ac64-f4654222c876', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (488, 10, N'L', 0, 305, N'1f7e6f83-8b80-410b-9724-0eab0cf40d1e', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (489, 1, N'J', 1, 612, N'facfe28e-6c9f-4a85-8034-2e1e74d3ec00', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (489, 6, N'F', 9, 619, N'5583abf0-8fac-4a04-83f5-4f48659b6388', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (489, 50, N'N', 1, 606, N'fce97d84-91a8-4f37-a422-6d147c16f2b4', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (490, 1, N'J', 2, 593, N'fc3e02e8-8e40-4aeb-ac8a-00acc2a868c8', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (490, 6, N'F', 2, 600, N'd567b258-a47d-4784-8ced-36d2471fb9ad', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (490, 50, N'N', 2, 587, N'2371ace1-6f18-4ba6-b886-379d4538347f', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (491, 1, N'J', 3, 254, N'59adc11b-ca32-44e3-a8c3-743795b10295', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (491, 6, N'F', 3, 420, N'ec4cf840-8c82-4ea8-8d50-7fad3088d549', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (491, 50, N'N', 3, 248, N'924e73ef-b333-4594-8e99-a0adc10a969c', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (492, 3, N'A', 3, 17, N'f3b4712f-44b3-4a53-b245-63c39476bd53', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (492, 4, N'A', 6, 14, N'87ac9f46-e5c5-4c75-9d14-43340ed0aa50', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (492, 40, N'B', 2, 16, N'a0cf23bf-264d-411d-89f8-edc6fb5dee8f', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (493, 3, N'A', 2, 41, N'318e5d8b-83ca-416c-80d7-c77854b0b612', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (493, 4, N'A', 8, 24, N'4927f190-22cc-486a-93c8-57a7fd3124be', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (493, 40, N'B', 1, 28, N'0ea862e3-72b9-4528-ab80-594183c83d8a', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (494, 3, N'A', 1, 49, N'6df644a4-3d8b-4536-b012-7454bc2bb72b', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (494, 4, N'A', 7, 12, N'fd0ad7c7-6338-47e2-b682-979cf5c68804', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (494, 40, N'B', 3, 4, N'23e5680f-324e-40d9-a7c4-d29c6f78e51f', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (495, 3, N'A', 5, 49, N'15894a4c-a7f7-417f-b293-99b75ca3d396', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (495, 4, N'A', 9, 35, N'104606e8-072c-4290-a461-17791e14cd1c', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (495, 40, N'B', 6, 25, N'025f4f97-0086-4757-8ff2-94617dea03cf', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (496, 3, N'A', 4, 30, N'3aab2ea0-bb00-4faa-bec7-751ee97d9f8f', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (496, 4, N'A', 10, 25, N'5b66cd4c-aaab-4072-9b1c-2141463606ab', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (496, 40, N'B', 7, 44, N'5084d0ce-167f-4c6b-b8f9-ff5df6bfde15', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (497, 1, N'E', 26, 336, N'6c02a51d-c18d-407a-869e-a6f092e6d66f', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (497, 6, N'M', 8, 364, N'c9ba4c67-b045-4463-bbff-369e0d1ea62e', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (497, 50, N'W', 6, 273, N'3d0e1102-8bfd-4b0e-a369-287fe8cb94e4', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (504, 1, N'E', 15, 392, N'0b8bee49-6297-4619-947e-2399b68ccff1', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (504, 6, N'M', 6, 372, N'2b033bbc-4817-4919-8506-ac92ee8a864e', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (504, 50, N'W', 4, 320, N'1cae3640-2c47-46e2-8ac3-84ca3f0d6937', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (505, 1, N'E', 18, 388, N'8b147e39-57ec-47b3-a16c-618b7b294d56', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (505, 6, N'M', 11, 299, N'f95af4ae-4e74-4e45-9fd7-7356b25dd660', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (505, 50, N'W', 11, 283, N'f47d8120-fd77-4dee-8d08-76d462f24142', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (506, 1, N'E', 13, 316, N'762e549f-e8bd-44ec-9427-a70853d52129', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (506, 6, N'M', 7, 390, N'a1a817d2-e626-4912-843b-6c8b9f844a5e', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (506, 50, N'W', 5, 121, N'47363db2-4f53-451a-a14b-e0f869b9827d', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (507, 6, N'N', 2, 673, N'c56d7527-ebf2-4ebe-b2f1-cbbd4b18ab42', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (507, 50, N'J', 1, 542, N'b9828c8c-1914-4588-a97d-d96ec6532d73', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (508, 6, N'N', 1, 681, N'fb6140e9-db0d-4a60-9658-940ca81fbc56', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (508, 50, N'J', 2, 550, N'3d43f6b1-73ac-44f8-ab93-b7c19bfb849d', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (509, 6, N'N', 3, 689, N'd465f931-320c-4ea4-a3ed-a2f4e24d5837', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (509, 50, N'J', 7, 558, N'fd33b300-db87-432e-8d9d-50eb8d620840', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (510, 6, N'N', 4, 406, N'd669a00a-6fe2-41c7-b8fb-956afda2061f', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (510, 50, N'J', 6, 316, N'ec4deab0-698d-4ad2-80dd-26f9623f55f9', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (511, 6, N'N', 5, 390, N'1d636314-2931-470a-9700-85e9e069495f', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (511, 50, N'J', 5, 350, N'2f10d142-992f-40d1-9cf6-6dca1723ac48', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (512, 6, N'N', 5, 334, N'0077a261-a5a8-44a0-aa20-e3adb9a66409', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (512, 50, N'J', 4, 281, N'5e88934c-fecb-4e02-8930-46bfcf17032c', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (513, 6, N'N', 9, 640, N'153f32e8-1ed4-41d0-91c1-c32760d36ff8', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (513, 50, N'J', 3, 724, N'80c9f5d1-2acb-4ec2-b1a2-f5b10c17d3be', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (514, 6, N'D', 10, 267, N'9a46ace3-6e4d-4071-8437-22c0e5405301', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (514, 50, N'G', 4, 318, N'b916987e-6171-4c56-a964-3fde5162b2ed', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (514, 60, N'F', 2, 212, N'4de1673f-b41a-4ca3-bb14-33c1013dccbb', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (515, 6, N'D', 2, 268, N'ee1ecf60-28a9-45cd-9f42-1b4c2468c926', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (515, 50, N'G', 22, 320, N'4a7adfe0-5dc6-41a8-80d4-58833cede47b', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (515, 60, N'F', 1, 214, N'4fc21929-d18c-4c2d-82ef-174d16ed59cf', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (516, 6, N'D', 3, 270, N'7388cac8-66b9-4df3-9ddd-3768dc5ce2b6', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (516, 50, N'G', 23, 321, N'4fae00ee-c465-4166-b787-ec749d28a1aa', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (516, 60, N'F', 3, 216, N'aac2b0b1-4847-4c59-bfc2-db70fa45e63c', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (517, 6, N'D', 16, 272, N'a52f59b5-417d-4d09-aae2-7319cfbe13eb', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (517, 50, N'G', 5, 323, N'3f555d79-9725-4925-8e93-d9a3656ae21a', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (517, 60, N'F', 5, 217, N'8f7c4499-0ab6-498e-abcc-c522b73f424f', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (518, 6, N'D', 17, 273, N'a5d60611-307f-409b-903e-b00c86594fca', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (518, 50, N'G', 6, 324, N'f243475d-2304-4a8e-b2cb-f7ab3af7b6b9', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (518, 60, N'F', 6, 219, N'0a320658-cba0-498c-bc23-1f754c77ea54', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (519, 6, N'D', 15, 275, N'77944f88-c91c-4e7e-a8cd-2fea4e557127', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (519, 50, N'G', 7, 326, N'2bb5bd8c-5a1b-4460-a47b-5f7583732e1b', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (519, 60, N'F', 13, 220, N'94c47da3-04db-4048-82b5-0c8ed73f3ef1', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (520, 6, N'D', 14, 276, N'fe246a1d-593e-4caa-b50b-cf1c9b983e97', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (520, 50, N'G', 2, 328, N'8dfffa6d-e753-4f0e-9d35-829d67afa2d4', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (520, 60, N'F', 14, 222, N'ad7bb0b1-c102-4226-85e1-2f6735db710e', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (521, 6, N'D', 11, 278, N'490b51f2-e8ce-45e5-a073-fc9bb9ebc8c3', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (521, 50, N'G', 1, 329, N'b3745b7f-ab41-4cc3-8d71-c754201fec4f', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (521, 60, N'F', 18, 224, N'e48cdd7c-79a9-4dfd-85f2-a1203ea32678', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (522, 6, N'D', 1, 280, N'62af5c55-3b86-4329-9454-9212ce7b84b9', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (522, 50, N'G', 3, 331, N'8b053459-bc75-427d-a872-8ecb02fbf572', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (522, 60, N'F', 7, 225, N'55298213-d7c0-4553-bb63-857daf106053', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (523, 6, N'K', 1, 164, N'738855d6-4122-48c1-80d0-f65e39631641', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (523, 50, N'Y', 1, 209, N'62bfe8f6-83c8-4e77-8172-f4f0bec46ec1', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (523, 60, N'L', 6, 139, N'428999ea-a90b-496f-9f4e-59b12a52539c', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (524, 6, N'L', 1, 124, N'9ea9ce85-98f3-4a8e-bf1a-c610335aa646', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (524, 50, N'Y', 2, 228, N'ca005fd5-9637-426a-b1f8-5f69566dd09b', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (524, 60, N'K', 1, 107, N'66aa90f2-e56b-4a4f-ab10-3fcc6581cb9c', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (525, 6, N'B', 2, 644, N'8bcb6f5a-6ef2-4b88-a036-6dadffe0c6c3', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (525, 50, N'F', 1, 619, N'73b67ace-5e90-4f51-9dc8-6879c5626c25', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (526, 6, N'B', 3, 587, N'17ce859e-0359-49c0-bb28-d4f835f060b1', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (526, 50, N'F', 5, 624, N'e3fb5bc0-912e-4ba7-a293-b0644815f78e', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (527, 6, N'B', 4, 888, N'ffae06c0-6dc1-4d15-b1e9-74a68a33072d', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (527, 50, N'F', 11, 702, N'6d440ce3-36a6-4d79-90f9-46b9ab087de6', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (528, 6, N'F', 5, 924, N'3bb6b654-0d95-408a-9fd3-e32e133cc9d1', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (528, 60, N'E', 3, 729, N'fb6d579d-db41-4224-8c20-63fde29d7e6d', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (529, 6, N'F', 6, 425, N'f92e94d4-7b20-48ae-b696-a1e8e290edeb', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (529, 60, N'E', 4, 371, N'e9037624-1f9a-4d60-a16d-f5f0072b13ee', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (530, 6, N'F', 7, 336, N'f2bec15d-6c84-4725-9f86-c509695bd98a', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (530, 60, N'E', 5, 444, N'e8673424-5469-4320-b3a2-f0da3cef7d3e', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (531, 6, N'F', 8, 427, N'3ba7883f-cedc-4409-9a26-c610c732db29', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (531, 60, N'E', 6, 374, N'c4ac637f-2f18-4ff0-afd1-f817a59f950c', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (532, 6, N'F', 4, 715, N'b4b13895-ed08-4dd8-8ea1-9517da10a6bd', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (532, 60, N'E', 7, 542, N'af9f8c8e-107d-4d82-ba22-5be5e2d86c06', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (533, 6, N'F', 1, 443, N'0cdb5e87-d659-4ef5-8c2d-a94de24babb5', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (533, 60, N'E', 1, 388, N'5ab84bec-940f-4f44-86b6-45d9081ddd32', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (534, 6, N'L', 12, 379, N'6192b157-0cb7-49cb-98ed-4e2cd3ecb1ac', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (534, 50, N'R', 12, 278, N'1b35570e-6092-4502-8618-4cdcc8811121', CAST(N'2008-03-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (535, 6, N'L', 14, 427, N'2cc3b5fe-e097-419b-b8e6-e3dbeb0e571f', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (535, 50, N'R', 14, 409, N'121faf11-d40d-4235-b606-32c41b39d284', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (679, 1, N'E', 22, 164, N'bcdf3dae-8ef7-4282-a01a-18b8aa1b7712', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (679, 6, N'M', 13, 136, N'4226e846-89e4-4d4b-b87a-761292a9f5da', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (679, 50, N'W', 13, 121, N'80f5c557-3b0e-4eb3-8f3d-ae3174209c1e', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (707, 7, N'N/A', 0, 288, N'1b7057e7-9d56-496a-a234-42379f91a836', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (708, 7, N'N/A', 0, 324, N'39d263b3-915e-4be2-a972-009b7009759c', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (709, 7, N'N/A', 0, 180, N'dbf7dc83-7953-4e1c-8d3a-4dc943b118ca', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (710, 7, N'N/A', 0, 216, N'eb067301-2a1a-4bd7-b844-a580bc586803', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (711, 7, N'N/A', 0, 216, N'effd3b6e-bee6-4e55-a675-f299765eb0e5', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (712, 7, N'N/A', 0, 288, N'9b43245d-a0eb-4513-b88f-12fdaa7078f2', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (713, 7, N'N/A', 0, 144, N'764d0206-b3cb-485c-a760-1a3aa239ea9d', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (714, 7, N'N/A', 0, 180, N'b6362555-5bef-48b9-8d11-20f7e81caac1', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (715, 7, N'N/A', 0, 216, N'721c2947-3c96-417c-94e8-80f6b7c24aa6', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (716, 7, N'N/A', 0, 252, N'5f55c7bc-5bc0-4dec-9294-539708913bae', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (747, 10, N'N/A', 0, 121, N'1c5d890e-4c6b-4537-abda-a0d80f75872b', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (747, 20, N'N/A', 0, 161, N'18b5af98-2293-4776-9d4e-122c009ef28c', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (747, 30, N'N/A', 0, 148, N'8e762604-0816-48ad-b289-94c843d9301a', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (747, 40, N'N/A', 0, 107, N'972b7c2b-d0e8-4c3d-88f6-416d8e450f36', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (747, 50, N'N/A', 0, 160, N'b8999891-844f-4147-9348-423d36400a09', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (747, 60, N'N/A', 0, 137, N'6d6ed50b-7e4b-40cd-b617-d93318f3dbf6', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (748, 10, N'N/A', 0, 105, N'693c794d-e82f-4d18-a1bb-457e4382f0eb', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (748, 20, N'N/A', 0, 145, N'2104148d-c96d-4cd4-9a75-940a70e1a124', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (748, 30, N'N/A', 0, 132, N'523153b7-92cc-45d0-9a6f-046995cb498e', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (748, 45, N'N/A', 0, 91, N'459634ae-40d9-498a-9d2b-5aab2664ec4d', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (748, 50, N'N/A', 0, 144, N'970834e0-d46f-4bda-bce5-fdce013d7fd5', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (748, 60, N'N/A', 0, 121, N'5577f565-07e8-4885-aaf4-43de53d51618', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (749, 7, N'N/A', 0, 73, N'54558772-09e3-4f0f-a8bd-92c0ca8243c7', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (749, 60, N'N/A', 0, 60, N'e7498117-e2cc-4aa5-b6d9-a1d0c9e4eabf', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (750, 7, N'N/A', 0, 102, N'36003282-934f-42b8-a728-8c77add3dc78', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (750, 60, N'N/A', 0, 121, N'f4f41897-db28-447c-b621-3fdb56671cc5', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (751, 7, N'N/A', 0, 32, N'cb2de498-349a-4d8d-ae4c-0f03041575c6', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (751, 60, N'N/A', 0, 108, N'fa8cc2ac-b715-43e4-9ab1-ccbe7039f0c2', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (752, 7, N'N/A', 0, 52, N'ce5255cc-ac11-4cee-9c7f-f188116c5353', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (752, 60, N'N/A', 0, 76, N'5c7e9ae4-97e8-4dd8-a1a9-7018ad17cc5a', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (753, 7, N'N/A', 0, 112, N'e3d6ab33-314e-4fbc-9743-b7af3c097d8a', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (753, 60, N'N/A', 0, 51, N'1ff999d3-0285-4084-8910-f1985e468675', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (754, 7, N'N/A', 0, 65, N'c6c248a6-ecd2-4dcd-8e79-2fcd345f4c39', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (754, 60, N'N/A', 0, 83, N'cd60cbbf-d180-44d7-a3f5-d4b75eac6eb3', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (755, 7, N'N/A', 0, 75, N'2a8eafcd-850f-4eb1-b205-a3c1a41ddc26', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (755, 60, N'N/A', 0, 62, N'f22c63c8-42b5-4f30-b1e8-0c4a74643991', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (756, 7, N'N/A', 0, 30, N'3409b5ee-9b07-4300-b05d-82c53862ce93', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (756, 60, N'N/A', 0, 99, N'fed4174f-1f1a-432a-b89c-80dafc774ae5', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (757, 7, N'N/A', 0, 56, N'8ee50e04-3e61-4d36-b4ad-2b629c22f12d', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (757, 60, N'N/A', 0, 78, N'b91bfbc6-8ac0-4a0c-8fd5-162c99c134fb', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (758, 7, N'N/A', 0, 116, N'aec6250b-fc25-4731-bb11-ff9eb03bb295', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (758, 60, N'N/A', 0, 49, N'52479ac5-f2b0-472e-b183-1a3f0ca39a06', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (759, 7, N'N/A', 0, 112, N'82b4cf97-b982-4179-906d-aeb3d06ac137', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (759, 60, N'N/A', 0, 51, N'708ee4d0-7ba1-40cd-9762-093d579a8556', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (760, 7, N'N/A', 0, 99, N'0db7aefc-297e-450c-9846-07c8c30ada31', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (760, 60, N'N/A', 0, 86, N'ca4ff838-8a35-4b8c-a48d-d6b9b5a53ff0', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (761, 7, N'N/A', 0, 67, N'873df6e9-8454-41be-867a-904550b5d761', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (761, 60, N'N/A', 0, 81, N'81aadcce-a85a-42fe-8a6b-58f21fa39d09', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (762, 7, N'N/A', 0, 75, N'3eea520d-614e-420e-9370-073da5ad2528', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (762, 60, N'N/A', 0, 62, N'8ce0f44a-7362-4c9a-a529-799892feb5bf', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (763, 7, N'N/A', 0, 102, N'a02c8843-0ec2-43dd-adff-d8ea509916e8', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (763, 60, N'N/A', 0, 121, N'0be8ab7e-ac8d-479e-b4a0-df8842a2011a', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (764, 7, N'N/A', 0, 32, N'668af318-9167-4ed5-9944-a95eb4a2c795', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (764, 60, N'N/A', 0, 108, N'8ab29d85-f45f-4913-ac9d-2a6251ef253d', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (765, 7, N'N/A', 0, 56, N'c248ad84-9405-4e64-a581-801f9c12d6ff', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (765, 60, N'N/A', 0, 78, N'b7161c02-ce9c-4254-9c28-3e4305dd7d43', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (766, 7, N'N/A', 0, 116, N'779e2130-5240-461f-96d1-77e3b1c844a2', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (766, 60, N'N/A', 0, 49, N'e2a8793f-4f05-4867-9f3d-9843f04c9872', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (767, 7, N'N/A', 0, 100, N'bc108f38-ec76-46f4-86a6-8c66e1834b78', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (767, 60, N'N/A', 0, 88, N'c1b8fc46-4bde-4e55-bb83-53929dc8f323', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (768, 7, N'N/A', 0, 67, N'53535f3e-ffb2-461a-a422-5fa327516dff', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (768, 60, N'N/A', 0, 81, N'08e56a6c-0d54-4d5c-bddf-2605ecdb6901', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (769, 7, N'N/A', 0, 73, N'3bc1861e-e170-475b-babb-25cf640cc5b6', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (769, 60, N'N/A', 0, 60, N'5fa547be-3d45-4a8a-85a5-b1ee8084a670', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (770, 7, N'N/A', 0, 104, N'933b7e02-2e78-4c26-91b4-f40c65dae6ad', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (770, 60, N'N/A', 0, 123, N'e259c06f-a31c-4e05-8835-fffaa0c4ff50', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (771, 7, N'N/A', 0, 49, N'629dc77c-9656-4c22-8c90-8a601305eb94', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (771, 60, N'N/A', 0, 100, N'd0012c1b-5e78-4faa-a7f2-ac21b11528c8', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (772, 7, N'N/A', 0, 88, N'3a92ad34-7ee5-4427-9e0e-6cd4d56d3d5f', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (772, 60, N'N/A', 0, 65, N'd5182806-8b50-4097-9741-bf000764b5e9', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (773, 7, N'N/A', 0, 83, N'09d6b98f-9914-461f-9b05-46ac3a78b747', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (773, 60, N'N/A', 0, 75, N'5ca5a38f-cb12-4615-bddf-e60109853188', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (774, 7, N'N/A', 0, 62, N'bf9de689-1302-4f0a-9bf9-9f535f99ecb5', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (774, 60, N'N/A', 0, 102, N'2c38acc2-cde7-4c90-bf15-95ca7426a963', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (775, 7, N'N/A', 0, 99, N'f17089a0-e7ed-488f-a3ee-179aa958b1eb', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (775, 60, N'N/A', 0, 56, N'4ae132b6-d196-4f81-901a-d533014e057b', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (776, 7, N'N/A', 0, 78, N'9c0eeae2-f2a1-44a3-96b7-97f96021dbf9', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (776, 60, N'N/A', 0, 116, N'84b419ad-11df-4fe5-bd81-5ded306a4eee', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (777, 7, N'N/A', 0, 49, N'dba602be-5412-42ff-916f-c372269c3a2c', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (777, 60, N'N/A', 0, 100, N'40775054-5d91-442c-85b2-8730ac71ec6a', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (778, 7, N'N/A', 0, 88, N'1fcfc1a8-1119-4cae-87b0-a9e9ff2f8389', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (778, 60, N'N/A', 0, 65, N'acb69e4b-c8e6-4eae-8d50-aa957896cd11', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (779, 7, N'N/A', 0, 75, N'73034e05-a2a8-4796-a242-a5b9af26fa41', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (779, 60, N'N/A', 0, 62, N'8e60bc44-245e-4520-9c54-94d2302ce45d', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (780, 7, N'N/A', 0, 102, N'd6e39b99-b034-4a75-b5ab-2839dd908065', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (780, 60, N'N/A', 0, 121, N'0a9cc443-06b5-4b97-a5a7-704e9ad95d1d', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (781, 7, N'N/A', 0, 32, N'23c0760f-96dc-493f-b016-1d60b8c0214a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (781, 60, N'N/A', 0, 108, N'b288c485-cbb3-450f-9395-562f28cf9edc', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (782, 7, N'N/A', 0, 100, N'f4dec682-9bfc-47c3-ba79-eed46067f317', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (782, 60, N'N/A', 0, 88, N'faf6a2ef-e1d5-4387-840c-9cf94c4c15ee', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (783, 7, N'N/A', 0, 65, N'a1ac022b-98cd-402b-bbed-62e430d7a712', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (783, 60, N'N/A', 0, 83, N'cfd6e018-7a86-4514-bd6a-7df5a579b74e', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (784, 7, N'N/A', 0, 75, N'aa64d2cb-1dba-454e-be6e-9126315a2c16', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (784, 60, N'N/A', 0, 62, N'9efbb119-da0d-4349-afea-663fca0ef4ee', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (785, 7, N'N/A', 0, 75, N'4bdc23ea-e827-4172-bcf7-50c24f7cc7a4', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (785, 60, N'N/A', 0, 62, N'ef665f70-ae6c-4e5a-af30-b61b249a47ae', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (786, 7, N'N/A', 0, 102, N'68e050e5-0408-41cb-86b8-e2ea4d0ae9dc', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (786, 60, N'N/A', 0, 121, N'9c29b402-9af3-4384-a695-0b94b76ef73a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (787, 7, N'N/A', 0, 32, N'fd3f495e-d3aa-455a-89c1-55f27adf3174', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (787, 60, N'N/A', 0, 108, N'da83ca89-babc-4d0f-829e-9ebc42ed052f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (788, 7, N'N/A', 0, 52, N'a577b5e6-9f1b-4cb8-bb23-008262f5e599', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (788, 60, N'N/A', 0, 76, N'18eef8f9-befc-449f-862d-2893beaa0cd4', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (789, 7, N'N/A', 0, 112, N'f6fd070e-7724-43d9-81aa-657631570721', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (789, 60, N'N/A', 0, 51, N'c934b5bf-229a-4bef-9a0a-8b60c320deee', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (790, 7, N'N/A', 0, 99, N'2361264c-f8b9-4f5a-b062-2d28096c0e59', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (790, 60, N'N/A', 0, 86, N'43ce4f80-3bff-423d-9a6d-b5e7c6959dfd', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (791, 7, N'N/A', 0, 67, N'a0b76244-7b54-4f7e-8e6b-735ea537800d', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (791, 60, N'N/A', 0, 81, N'cc201c04-6240-4469-8711-c52a87cb90bf', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (792, 7, N'N/A', 0, 104, N'ca96cf18-792b-4788-bfd5-c77cbed2f6c1', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (792, 60, N'N/A', 0, 123, N'532d5a39-04d0-457b-bfa3-ef16457dead9', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (793, 7, N'N/A', 0, 56, N'044a0ad7-7ea6-4502-9e21-aa7efb5f60cd', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (793, 60, N'N/A', 0, 78, N'dc5cb5ec-14f7-4ec0-8ae8-ad883bdd2ac0', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (794, 7, N'N/A', 0, 116, N'9c6c3c66-1b23-4ee5-9be0-1f948001639e', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (794, 60, N'N/A', 0, 49, N'f5fc0861-cffe-431c-869f-ff2edeed0442', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (795, 7, N'N/A', 0, 100, N'2b0526ed-45e2-4995-ae46-bb20304c51f5', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (795, 60, N'N/A', 0, 88, N'018da23f-292e-40d6-b061-dc72d2cd02b3', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (796, 7, N'N/A', 0, 65, N'c324a634-15a5-4ceb-a5d5-bd2953d15c2e', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (796, 60, N'N/A', 0, 83, N'4f4f7556-65ae-4b76-82fc-a5159dac1d87', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (797, 7, N'N/A', 0, 67, N'f9c9bd88-d505-480e-9d44-fff4eacf9fa4', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (797, 60, N'N/A', 0, 81, N'3ffe7c97-dd8b-4b38-9afa-5989eb7dbaa7', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (798, 7, N'N/A', 0, 73, N'5a7a63cb-b1e5-443f-b494-447972ba5033', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (798, 60, N'N/A', 0, 60, N'1637cfb2-cf10-4d1a-b2cf-48f532883b93', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (799, 7, N'N/A', 0, 104, N'd4a0556b-a14a-44d0-a4a2-e03c3617a8c9', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (799, 60, N'N/A', 0, 123, N'95824768-5d5b-4426-b4f8-f1b2c5403da1', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (800, 7, N'N/A', 0, 30, N'eac1040c-3ca5-43d1-aa10-052a3a0d836a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (800, 60, N'N/A', 0, 99, N'71b37a3f-e348-4fa0-86f6-80edd53a0473', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (801, 7, N'N/A', 0, 56, N'7ad3bdd5-e96f-40e6-964d-6612b321877c', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (801, 60, N'N/A', 0, 78, N'a2a3c882-9aa3-4b1b-8ac9-b2ebcd8031a4', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (802, 5, N'J', 7, 350, N'bebd11fc-746c-4b4b-a704-f39b93ead5d1', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (802, 10, N'C', 8, 240, N'8bf6d9a4-4d7b-45fd-a242-d46585df745c', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (802, 50, N'A', 17, 273, N'12534b74-9386-44db-853c-b19a95946528', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (803, 5, N'J', 8, 356, N'b6d8d615-52b7-47a2-b924-b662d82d976e', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (803, 10, N'C', 9, 246, N'0840bfc7-6efb-48c4-b830-777220990ba8', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (803, 50, N'A', 18, 280, N'c30b36ad-95b5-4ccf-8b59-937216d382d9', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (804, 5, N'J', 9, 363, N'27839638-d1fa-424f-bf44-d42d999261d7', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (804, 10, N'C', 10, 252, N'e109a831-1014-46cd-9e8c-e0745a52af2a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (804, 50, N'A', 19, 286, N'20992266-54ca-4cf8-b215-47d0d4b45788', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (805, 1, N'D', 13, 284, N'fff200bb-1705-4839-aa84-0abaa34e4700', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (805, 6, N'R', 40, 265, N'ce55f3f0-e588-44ac-a266-42b2eaf81392', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (805, 50, N'E', 40, 212, N'0b26d1cc-6655-4876-ae52-70102f8f3f9d', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (806, 1, N'D', 14, 288, N'7b1c2aa3-9e16-454d-8c71-fadf9088378c', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (806, 6, N'R', 41, 268, N'aab77a86-054b-4007-8c1d-b567a73f4844', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (806, 50, N'E', 41, 216, N'187a6429-2238-431c-9c9b-4a5cf38150cb', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (807, 1, N'D', 15, 291, N'c2d4bbc2-8488-429c-8c4f-96184f756d48', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (807, 6, N'R', 42, 272, N'5074ce54-a19e-47f3-b082-c08b215a626a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (807, 50, N'E', 42, 219, N'cd57d7f7-eca1-4405-8579-2fcde2e104cb', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (808, 10, N'E', 4, 267, N'8e51d869-550a-4912-89dc-a9dd436885f4', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (808, 20, N'S', 1, 276, N'2892a90f-0fb6-4747-a1cc-94a872bd06dd', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (808, 50, N'F', 2, 316, N'0f9636fc-b190-4461-842e-b91377c26f6a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (809, 10, N'E', 5, 264, N'79c7db57-abdf-40b7-81db-a2245fc853ea', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (809, 20, N'S', 2, 273, N'5148c79e-1339-43d0-940d-157dd706f133', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (809, 50, N'F', 3, 313, N'1c2ad20e-6e03-4bcf-998a-44d35bd82146', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (810, 10, N'E', 6, 260, N'0d9f8dc5-927e-42fa-a4c9-df74194fbc5f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (810, 20, N'S', 3, 270, N'd6249474-d050-4087-9337-9c84e5f4f345', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (810, 50, N'F', 4, 310, N'3ac58b40-9d61-42c0-994e-0601e9971059', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (811, 10, N'E', 7, 257, N'925b5f59-c5f3-4a1b-87ef-7c085d41ea07', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (811, 20, N'S', 4, 267, N'b677190c-1133-4008-a1ab-105684f2ce81', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (811, 50, N'F', 6, 307, N'05fda53f-f09c-4838-9e6e-c192347dfb5e', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (812, 10, N'E', 8, 254, N'6c8fe7b2-3265-4ff7-b7c5-a5c26f32da68', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (812, 20, N'S', 5, 264, N'437307d1-6a1d-4aa5-a244-7d534ba0e9a7', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (812, 50, N'F', 7, 304, N'7cfc9beb-f10d-4c89-a6d6-642b25e21ce6', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (813, 10, N'E', 9, 251, N'1fe8d8b6-4205-48f6-9583-de8c76066297', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (813, 20, N'S', 6, 260, N'dad4bf7f-0646-48e9-80a1-88bee19a14ac', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (813, 50, N'F', 8, 300, N'49c20091-5deb-4c75-bbdb-1ec7f7b97dab', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (814, 10, N'N/A', 0, 110, N'7f012da0-9fff-462b-90ce-3ded72b2c81f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (814, 20, N'N/A', 0, 150, N'6e66291c-30fe-4b35-9f2b-b58f308d93f3', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (814, 30, N'N/A', 0, 137, N'8451be00-88c6-4bc1-925e-da45208a2008', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (814, 40, N'N/A', 0, 96, N'9538c094-dedf-4a64-838e-72417e6813b8', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (814, 50, N'N/A', 0, 148, N'1e851dbc-0ec5-439c-a12c-c84a3b2268d9', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (814, 60, N'N/A', 0, 126, N'750f6c85-88de-425d-a60d-57c06777e71a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (815, 5, N'T', 1, 265, N'bf66a7c6-9bac-4a91-b4a0-93f72d59e20d', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (815, 50, N'B', 1, 457, N'cf175595-fb5a-4308-9489-930223773810', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (816, 5, N'T', 2, 406, N'fadd51f0-c329-43d8-ab23-214091724421', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (816, 50, N'B', 2, 412, N'4a5bd660-248d-473b-b2d7-eac2dcaaf6a7', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (817, 5, N'T', 3, 443, N'343f1d69-0606-4569-8228-13defbd7c118', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (817, 50, N'B', 3, 388, N'78904199-7c58-4bdf-b2c1-ed0de2034483', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (818, 5, N'T', 4, 428, N'b9f6524a-30fe-455f-ace3-d9bab321099c', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (818, 50, N'B', 4, 460, N'7f27ab63-be21-48a2-b925-6efa9a0f1a2e', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (819, 5, N'T', 5, 409, N'3e8deddb-045b-4a52-bdaa-3b5176323ea9', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (819, 50, N'B', 5, 384, N'4fbd565a-f25e-42a5-95b7-1d7d01e2c507', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (820, 5, N'T', 6, 446, N'5bacebc0-e5b3-454b-82b7-53d4bf89df88', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (820, 50, N'B', 6, 232, N'e815f562-bf7b-4a0a-b743-413aff059aee', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (821, 5, N'T', 7, 432, N'fdcd7382-4c5a-4ddb-86cb-6a693661dc02', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (821, 50, N'B', 7, 304, N'20ee2603-838d-4781-ad93-83753a432b5f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (822, 10, N'N/A', 0, 115, N'bfb96644-7a7a-44dd-92f5-1937a635ff82', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (822, 20, N'N/A', 0, 155, N'e88d26bf-22ef-4a72-acc0-a8020ede7165', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (822, 30, N'N/A', 0, 142, N'f439da99-9e74-43f7-b29b-925983a8f25f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (822, 40, N'N/A', 0, 100, N'0834ea74-bd46-4d2e-a44c-aaff90b58b3c', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (822, 50, N'N/A', 0, 153, N'de67bdac-048a-4250-8a44-ef5ec2c8e5b9', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (822, 60, N'N/A', 0, 131, N'46b5352f-f67e-4dfe-a862-3a476929525d', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (823, 6, N'A', 10, 425, N'b1740211-ca5e-4a3a-ba64-ae00b6795435', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (823, 50, N'V', 1, 256, N'9e04d5ef-c22b-4010-9f86-3e8d5ba31fe8', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (824, 6, N'A', 10, 411, N'f3f884ad-80b4-432b-b1ea-2c914e20e148', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (824, 50, N'V', 2, 401, N'e63a0296-6936-44a8-84ba-8aedd7c5714f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (825, 6, N'A', 11, 396, N'8f97b19e-ab98-4869-ae88-88e13f7fb28f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (825, 50, N'V', 3, 387, N'bf43453a-fad1-4fa8-a3da-7a9d46736e01', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (826, 6, N'A', 11, 393, N'945250d5-b83c-4977-9249-c537c9eebdf8', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (826, 50, N'V', 4, 406, N'f36cbf4c-c7e5-4659-bd54-df0eb1179220', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (827, 6, N'A', 12, 412, N'9c55e8c1-9531-4d69-98a6-4d5a6cc15b36', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (827, 50, N'V', 5, 425, N'1b9ebbd6-a215-4529-af58-e9a1ecdd2b56', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (828, 6, N'A', 12, 432, N'8d7eddf7-70bb-4c8e-936d-39645c50bfa0', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (828, 50, N'V', 6, 284, N'c1385a54-7e61-43f8-9b87-3170d0abeba0', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (829, 6, N'A', 12, 265, N'eb4d4b77-be2f-41f0-bae1-cfdb4d8db033', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (829, 50, N'V', 7, 476, N'331a0a6a-91a6-446b-837e-1368a978b1ee', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (841, 7, N'N/A', 0, 288, N'3ba20e3e-9810-4f68-bad2-44ab974ae2a1', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (842, 7, N'N/A', 0, 72, N'18545177-6236-4c20-9bf0-7dd2d0648216', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (843, 7, N'N/A', 0, 252, N'796d6d14-52e0-44a0-82e2-eebba7db3da3', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (844, 7, N'N/A', 0, 288, N'c44196d5-4609-42e9-bd4f-c7cf8361533a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (845, 7, N'N/A', 0, 324, N'c0d46f2e-c084-4f0e-9ea5-225b0ed160d9', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (846, 7, N'N/A', 0, 144, N'a2c4f76c-327c-479d-99f9-d40a132ebb94', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (847, 7, N'N/A', 0, 180, N'7a0bcd5a-280b-4050-91bb-5b9cf36a1d49', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (848, 7, N'N/A', 0, 216, N'fbe6fa36-8953-4814-872e-c88a1c61f201', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (849, 7, N'N/A', 0, 108, N'05fe1cfd-9c01-4a2a-a1a6-1d76dd6bfb2f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (850, 7, N'N/A', 0, 144, N'34b5c646-ff21-43f5-acba-3e5729e792bd', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (851, 7, N'N/A', 0, 180, N'5b80ec8e-6445-46fe-9779-eda9ab530aab', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (852, 7, N'N/A', 0, 324, N'0557ed14-e1c6-4408-b52e-9d19e7827516', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (853, 7, N'N/A', 0, 0, N'2961ba75-2083-481c-8a35-6ac8b139dcce', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (854, 7, N'N/A', 0, 36, N'2e972e00-9c38-4160-9d0f-0514a075d506', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (855, 7, N'N/A', 0, 72, N'dbfcb963-f64a-4cd5-8acb-c1bf19d0f8b0', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (856, 7, N'N/A', 0, 108, N'c4fb1c57-c4e6-4730-ac5b-55934bda833f', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (857, 7, N'N/A', 0, 144, N'ad62ab75-efc4-4766-9b65-d4308e234a1a', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (858, 7, N'N/A', 0, 324, N'37bb613d-eabc-4b4b-b3d6-3f1c433947af', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (859, 7, N'N/A', 0, 0, N'911fa74b-0353-4bb9-aa58-82a86e626b17', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (860, 7, N'N/A', 0, 36, N'8db84170-087b-4bfc-963b-375ab5fdb647', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (861, 7, N'N/A', 0, 72, N'd6cd1c79-2106-472b-8741-481e0fe7ec44', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (862, 7, N'N/A', 0, 108, N'43cffbe6-86a1-40bd-90f8-58cae90e0596', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (863, 7, N'N/A', 0, 144, N'880e2b88-61c0-46bd-b489-e1d9fef3f114', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (864, 7, N'N/A', 0, 180, N'93ebce66-e74b-4134-bca6-33b4b1eaeac8', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (865, 7, N'N/A', 0, 216, N'8ff570bb-b9ee-4fe8-9ece-20d33ee99f43', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (866, 7, N'N/A', 0, 252, N'838e81a3-3b2a-4cca-9fcb-5f0ec5186957', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (867, 7, N'N/A', 0, 216, N'760e44d7-1e76-454f-8f5c-b7b77e33c775', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (868, 7, N'N/A', 0, 252, N'674a3b97-695c-4655-89f0-5fb6aaf1a9f6', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (869, 7, N'N/A', 0, 288, N'e1a00fc9-e050-4a90-b8d2-e22e37451933', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (870, 7, N'N/A', 0, 252, N'1a650732-24b2-4abc-ba37-c866a764045b', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (871, 7, N'N/A', 0, 288, N'6f509d6f-09bd-45e0-9ea3-d0a0800b2a08', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (872, 7, N'N/A', 0, 324, N'89cf1979-a25d-43b2-b140-6228a79426dc', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (873, 7, N'N/A', 0, 180, N'cc99281d-bef4-425f-8532-7f0fe652d8d5', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (874, 7, N'N/A', 0, 252, N'78103d2b-69e5-49bb-bd15-212b92bad89d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (875, 7, N'N/A', 0, 288, N'e3f8d6cc-2ddc-4f51-a026-b5a5c7ef7b1d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (876, 7, N'N/A', 0, 0, N'5c965ec8-6fab-42bf-af30-02cad1f2a56e', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (877, 7, N'N/A', 0, 36, N'1fe439ee-d5fe-4b52-852b-2e981fe0316e', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (878, 7, N'N/A', 0, 108, N'1e526c88-7bd5-405f-83d1-9754d789863b', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (879, 7, N'N/A', 0, 144, N'9a96913a-fd02-47df-a55d-ef3590f3adf0', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (880, 7, N'N/A', 0, 108, N'324686ac-6e54-4a24-a7ad-31e2754069f8', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (881, 7, N'N/A', 0, 324, N'd835d63d-abe1-4b8d-81e7-dc6d1775af43', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (882, 7, N'N/A', 0, 0, N'71addba2-e713-4cef-b861-b9c0a71cce1d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (883, 7, N'N/A', 0, 36, N'b57157b7-ff2e-439e-80f5-92467eeb5ad6', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (884, 7, N'N/A', 0, 72, N'5d52fd35-aa84-4834-9db6-de793a5d82b3', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (894, 1, N'E', 23, 337, N'0740f824-9f6e-4451-b8f9-42c1172a4708', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (894, 6, N'M', 14, 355, N'223683c8-3267-454f-840e-bcc57f7a13ac', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (894, 50, N'W', 14, 155, N'9f4ff0a0-ad0d-4027-a590-c350595a52d2', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (907, 1, N'E', 19, 337, N'b58b5a11-8c36-4318-beec-413930b94176', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (907, 6, N'M', 12, 228, N'e3f87834-460d-4c26-b539-f5dc6de6aecf', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (907, 50, N'W', 12, 158, N'cfcee763-fcd8-4ee5-b435-cf9fecc5c4b3', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (908, 6, N'D', 4, 400, N'ff971875-ea46-48f1-9608-1c1826e1d04c', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (908, 50, N'G', 8, 214, N'6ee93012-4dc3-44e3-9792-6b696b250419', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (908, 60, N'F', 11, 195, N'5f120c84-6e91-47b2-913f-49a3c47e6f1f', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (909, 6, N'D', 5, 230, N'ebcd0818-44e6-4fce-9c54-ab5719529995', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (909, 50, N'G', 9, 72, N'9d3b051f-b982-4ab5-b6ac-36885ccdf734', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (909, 60, N'F', 12, 120, N'4942e44a-1d06-438c-b502-a9134853b3d2', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (910, 6, N'D', 7, 91, N'1b55f0eb-4eae-4240-817b-ceedea5d1736', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (910, 50, N'G', 19, 168, N'4700001f-0ac5-44a4-adac-1f9af4968128', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (910, 60, N'F', 8, 96, N'e2382b4d-9112-4678-89c3-cbf12027b209', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (911, 6, N'D', 8, 283, N'c724266c-9142-4716-a15d-d090f3fd1fd6', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (911, 50, N'G', 20, 321, N'7b07be23-cc70-4288-95af-eb07ad438dd6', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (911, 60, N'F', 9, 302, N'b771540f-1d3a-4fbf-9c8a-80958ed16527', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (912, 6, N'D', 9, 302, N'14f7e517-c58b-4551-88c0-d5d4edf97af6', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (912, 50, N'G', 21, 353, N'df81ff78-ba70-4155-a508-a34724e161f9', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (912, 60, N'F', 10, 246, N'40d347ba-7c2f-4a46-9277-d81923b0e5fc', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (913, 6, N'D', 12, 169, N'67d1996d-01bf-4abf-8ff3-833f547f41df', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (913, 50, N'G', 24, 145, N'0b2fe80c-d968-4ac4-8bf9-ea96867d11a6', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (913, 60, N'F', 15, 153, N'41bc79aa-d552-41ed-a6e8-2a638118f5b0', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (914, 6, N'D', 13, 248, N'554b6058-27f4-4905-842c-9c902c45c647', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (914, 50, N'G', 25, 171, N'7ee779f3-0091-4577-9775-d355ee8e99d4', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (914, 60, N'F', 16, 382, N'e5d83079-2266-4eda-943a-ed8d33bae8bb', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (915, 6, N'D', 18, 161, N'80324910-6353-4732-8d74-b1097f82ef77', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (915, 50, N'G', 26, 83, N'08a33af5-82b7-4914-8cc4-21d75077dbf6', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (915, 60, N'F', 17, 158, N'50435d87-be80-4151-9cfb-c1b55486bd03', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (916, 6, N'D', 6, 425, N'69d30c0d-f2db-480b-b444-f888a18c6b3f', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (916, 50, N'G', 27, 288, N'f8448077-eb8f-4118-8d9e-5ab68bd60658', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (916, 60, N'F', 4, 276, N'73fc31f9-6938-464e-9f31-3b251c2433b8', CAST(N'2014-07-31T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (921, 6, N'L', 16, 286, N'8bc326c3-1111-4d9b-985a-c2bf2d43f82c', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (921, 50, N'R', 15, 243, N'c501de18-2dfc-4a5b-9017-477ab633c146', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (922, 6, N'L', 17, 264, N'ac015b09-3fdb-470f-adf2-eb634dfe8af0', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (922, 50, N'R', 17, 241, N'69f7778e-8b1f-4acd-a2f3-36c612f57068', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (923, 6, N'L', 18, 262, N'8dfb94bc-4a9b-4f41-8fe1-1fe126869875', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (923, 50, N'R', 18, 240, N'b0e7d0af-9f2c-42bc-b5da-78d20a10d8cd', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (928, 6, N'L', 2, 240, N'ad995530-d123-4f43-b0a0-294f5c5410e9', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (928, 50, N'R', 1, 369, N'2ec545ac-000d-49c5-a0e6-737ced96ac9d', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (929, 6, N'L', 3, 385, N'd7e5780d-ffd8-4ec3-a5f7-295970e924d9', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (929, 50, N'R', 3, 284, N'241dd7b6-bb54-4542-88c6-8856dacb7b88', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (930, 6, N'L', 5, 267, N'4b23bab2-70b7-4df6-93cb-49ff3d89afd2', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (930, 50, N'R', 5, 232, N'c2100fd0-6a1f-49c7-a2b4-38dccec76e27', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (931, 6, N'L', 6, 236, N'415a9ce3-98a3-4fcd-a89c-5ccc6b50d718', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (931, 50, N'R', 6, 252, N'b3ae5a9e-b904-4831-a344-3136c2cbaafc', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (932, 6, N'L', 8, 382, N'b5b13d29-c771-4384-bda2-16f4da641ed3', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (932, 50, N'R', 7, 192, N'5afc19d1-94bc-453d-ab30-62acd71bc74b', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (933, 6, N'L', 10, 299, N'69c587fc-04ce-4a4b-a7f8-8b4e9d1d6214', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (933, 50, N'R', 9, 228, N'01475150-96a0-4373-8a60-0fdaa4d03ce2', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (934, 6, N'L', 11, 233, N'9d782c2c-c778-4657-90d0-41c8c0f31bbd', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (934, 50, N'R', 11, 249, N'894d8dc0-3a31-4732-8e98-14bcbc643c2e', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (935, 1, N'E', 24, 174, N'f5cdb9cb-dfde-40a1-a996-2cecf8cdf99a', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (935, 6, N'M', 1, 182, N'91eb4e12-e61f-4b98-ae80-1a0f000e62a4', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (935, 50, N'W', 1, 156, N'dccb77da-5850-4064-a698-c2a80224f654', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (936, 1, N'E', 25, 172, N'8ba1fdf6-4da8-44b2-ac67-1a2b68c421f3', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (936, 6, N'M', 2, 180, N'e8ab068a-c417-417e-86dc-5f8ffe7098da', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (936, 50, N'W', 2, 155, N'575c9376-0762-4ea9-88d9-adf39a72900f', CAST(N'2014-08-10T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (937, 1, N'E', 20, 171, N'aa0e5356-4e0c-4558-b159-bf0e0eb5b3c9', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (937, 6, N'M', 9, 179, N'd5fff97b-7f58-47b7-a015-7b07abc546ad', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (937, 50, N'W', 9, 153, N'a509885a-3619-4d96-950a-d677f885f74f', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (938, 1, N'E', 21, 169, N'1ba43a54-1487-43fb-bb22-fea092100e94', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (938, 6, N'M', 10, 177, N'ab8ed1ef-7981-45e9-af90-a669816597e2', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (938, 50, N'W', 10, 152, N'a51ed6ee-ee8d-4f94-92ac-35c75ae49128', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (939, 1, N'E', 16, 168, N'f000a245-bfa0-4393-8c58-2b444cdd9831', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (939, 6, N'M', 3, 176, N'2be3a0aa-5267-4573-856c-ad365efde45a', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (939, 50, N'W', 7, 150, N'bbfc30c6-0181-4778-b663-54719b5605d1', CAST(N'2014-08-11T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (940, 1, N'E', 17, 316, N'2fecb528-c0f2-4cb2-ac74-e48584a77a52', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (940, 6, N'M', 4, 267, N'77247401-f23f-42fb-b4ac-e55773cd4754', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (940, 50, N'W', 8, 323, N'36f2fb3f-7478-479e-9e28-baf3eb8a4cf7', CAST(N'2014-08-05T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (941, 1, N'E', 14, 235, N'19078460-ccbb-47c1-886d-5c4d34841258', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (941, 6, N'M', 5, 262, N'9c8119e4-90f6-4a0b-b7b2-c2691efa1482', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (941, 50, N'W', 3, 388, N'426ea11a-ab14-4255-8ea6-1a60be300f4d', CAST(N'2014-08-09T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (942, 10, N'N/A', 0, 120, N'13b8f8eb-8402-4c01-93e5-92f8c859f66e', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (942, 20, N'N/A', 0, 160, N'4ac770c3-3fba-4218-ac15-2739497e6724', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (942, 30, N'N/A', 0, 147, N'7b0cffd1-f81e-4ee6-91aa-f852e3f6ca9b', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (942, 45, N'N/A', 0, 105, N'5dece803-133b-4ba7-8a98-5e8b104ffe6d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (942, 50, N'N/A', 0, 158, N'f33264e5-94ff-4874-8c51-df367ed93eb6', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (942, 60, N'N/A', 0, 136, N'0f7b3e43-efb5-4c11-ab1f-c508647dea5a', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (943, 10, N'N/A', 0, 102, N'48bca16f-6741-44b3-bedb-fe08be2b5784', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (943, 20, N'N/A', 0, 142, N'ba293d19-c3f1-4104-8955-4da147b386f0', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (943, 30, N'N/A', 0, 129, N'd1a5cb11-24cf-41d5-b5cb-38b3bd5349ef', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (943, 40, N'N/A', 0, 88, N'dbb42163-1526-48a0-bac3-2253fc6ff4c6', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (943, 50, N'N/A', 0, 140, N'75bd5626-e15b-48f7-9ae1-84d91bc99ff1', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (943, 60, N'N/A', 0, 118, N'f50d3932-cd0e-4a14-a314-00f275264296', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (944, 10, N'N/A', 0, 112, N'fd1f1796-02ef-4bbc-9254-da8098f1ca53', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (944, 20, N'N/A', 0, 96, N'194f5765-79b9-42d3-9914-809f9e9e5f39', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (944, 30, N'N/A', 0, 123, N'a0c2a74a-96cb-4e1b-b2b9-8ba94aed0076', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (944, 45, N'N/A', 0, 136, N'7269ed3f-85cc-4bf6-9c54-2caf50acf9d4', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (944, 50, N'N/A', 0, 81, N'553ceab6-0e77-4053-85ba-872b411829b8', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (944, 60, N'N/A', 0, 134, N'cfc1219d-6e27-40d2-bde7-e971775a1701', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (945, 5, N'J', 4, 347, N'60b347ed-82c1-405a-b7b4-5e7fe00fec78', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (945, 10, N'C', 5, 236, N'fdf0dbf9-e8cb-4349-8bc4-2b86e0b27ba8', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (945, 50, N'A', 4, 270, N'22f9f1a2-917e-4781-a431-8177615a153b', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (946, 10, N'E', 10, 248, N'a789955b-fec4-4728-9fb2-7b24d2afc8c3', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (946, 20, N'S', 7, 257, N'd3207862-a8aa-4961-a65e-7aa0a77edf97', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (946, 50, N'F', 9, 297, N'41c646c2-811d-4f07-b960-26379ecc8f1e', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (947, 10, N'E', 11, 244, N'3bdc2970-658c-4008-b8c9-33be0a71e485', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (947, 20, N'S', 8, 254, N'5584594c-3752-498a-9184-51f4777e68b3', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (947, 50, N'F', 10, 294, N'd742bd98-900c-47db-a434-c2cd13d663b4', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (948, 5, N'J', 1, 347, N'ffd07590-9f3c-4abf-80c7-353c66bd8429', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (948, 50, N'A', 1, 420, N'1cf7ac5d-ec65-4082-981d-5da23dda0e04', CAST(N'2014-08-12T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (949, 1, N'E', 1, 265, N'6f19980f-16bc-4831-ba60-aa05d92e1098', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (949, 5, N'A', 14, 336, N'a8c7b453-dc9e-43b5-bc18-7fc2720a8b34', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (949, 50, N'A', 30, 284, N'a0e6d5d7-10b0-4042-854f-f48938025ded', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (950, 1, N'E', 2, 272, N'f279d0ca-e2a6-4123-8c5b-02e56ffdf3c3', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (950, 5, N'A', 15, 342, N'c1b83518-0a0b-4cc3-812b-2443fe022046', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (950, 50, N'A', 31, 291, N'4efcf527-d62a-4218-9aa4-dc241bd61d15', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (951, 1, N'E', 3, 278, N'6416d956-3ad6-4d36-a2b6-521bfc4efaac', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (951, 5, N'A', 16, 348, N'9d12924c-919b-4c9f-a8c3-65a5a179096d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (951, 50, N'A', 32, 297, N'31a1b4af-abf3-46ec-ae14-3acebc8e545f', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (952, 1, N'C', 5, 236, N'7a254a77-b8a6-40df-8e87-dcfece42d6da', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (952, 5, N'A', 5, 192, N'526b82ab-c32f-413e-bd3c-60d2ca192a82', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (952, 50, N'A', 25, 161, N'6ad8a954-fe98-4962-a297-53cc416c96c7', CAST(N'2014-08-08T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (953, 7, N'N/A', 0, 116, N'cbb9a926-531b-4893-b76c-2379375bd17c', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (953, 60, N'N/A', 0, 49, N'c2c28a46-6aa5-40a2-ac8e-8abe502b1fd5', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (954, 7, N'N/A', 0, 65, N'38c69cb8-fe9e-4ddd-853e-11d3eda5a9b0', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (954, 60, N'N/A', 0, 83, N'1f861fa6-8d78-4b13-afd8-c4d9b1000812', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (955, 7, N'N/A', 0, 75, N'04e178d8-fc9a-4fee-a979-a28a17699bec', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (955, 60, N'N/A', 0, 62, N'af285249-75db-4e85-87b7-21c973758253', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (956, 7, N'N/A', 0, 35, N'1f99b8a6-0cba-47b4-9189-2fd6456362ce', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (956, 60, N'N/A', 0, 40, N'd934d8d7-264d-4bd5-9be8-25a9ca566bf4', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (957, 7, N'N/A', 0, 51, N'44a051d5-6454-4441-b18c-7df8c305fe6a', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (957, 60, N'N/A', 0, 100, N'997b9627-0ac8-4f3c-91a4-d0b121b89b9c', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (958, 7, N'N/A', 0, 128, N'5f3e0a21-97fe-40d9-8c40-a739be677fd3', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (958, 60, N'N/A', 0, 35, N'bf1249c3-a84b-4f2f-b3c2-3dd6df37850d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (959, 7, N'N/A', 0, 83, N'33b8c62a-89da-48bd-b5ae-7b8f26f7a1dc', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (959, 60, N'N/A', 0, 121, N'c5e9f516-5b05-4d8f-a1c3-f4130290a3b8', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (960, 7, N'N/A', 0, 54, N'958978c8-df63-4801-9ac2-bc771367d251', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (960, 60, N'N/A', 0, 105, N'606a2367-3e56-4e6e-bd34-35ccccf4a9f2', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (961, 7, N'N/A', 0, 88, N'f6477c89-0b08-4bc5-ab2c-a3ffe2616a54', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (961, 60, N'N/A', 0, 80, N'833d5f4a-9a92-492d-8eaf-e761ce80c3c9', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (962, 7, N'N/A', 0, 67, N'1c299d4d-3e04-4de2-bd4f-a1f201cea98f', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (962, 60, N'N/A', 0, 107, N'7c03d802-5f43-493f-93cd-a491c86b351e', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (963, 7, N'N/A', 0, 126, N'00740703-f4b3-4a25-9ee9-249ddd1f2596', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (963, 60, N'N/A', 0, 36, N'56742f4d-adb4-428f-abfb-a75a653f4385', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (964, 7, N'N/A', 0, 81, N'e02989ae-2310-409e-a19c-f4c29f5ae1dc', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (964, 60, N'N/A', 0, 116, N'4d0b989f-a84b-47ca-ba77-76d4d46272df', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (965, 7, N'N/A', 0, 91, N'99fe7e39-bf2d-4afe-9aeb-a3ab6426598c', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (965, 60, N'N/A', 0, 72, N'ed288862-97be-495e-9bf8-9df6c63d06b5', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (966, 7, N'N/A', 0, 99, N'82a9d933-8bc0-4afe-acb1-98e59b5c9eef', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (966, 60, N'N/A', 0, 86, N'58a0d3ed-d403-4edb-ad6a-ce216775144f', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (967, 7, N'N/A', 0, 67, N'8fb8b038-987f-438f-b04a-ace3acfd8931', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (967, 60, N'N/A', 0, 81, N'2c760eb2-b1b6-4857-89bd-0a2d3b954439', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (968, 7, N'N/A', 0, 73, N'6907efc4-ce55-496e-af71-4ec7a389a49b', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (968, 60, N'N/A', 0, 60, N'0d180279-656a-4e41-83a4-b8e29ae6286b', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (969, 7, N'N/A', 0, 30, N'3678e2ba-85b5-420d-b1a2-e1a13bfd4835', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (969, 60, N'N/A', 0, 99, N'6410cee4-344b-49e9-b9c0-503a4503724c', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (970, 7, N'N/A', 0, 73, N'bd522099-9151-4c84-9434-fa2737e20849', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (970, 60, N'N/A', 0, 60, N'4b4384a8-4829-466c-b432-296681f309c7', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (971, 7, N'N/A', 0, 104, N'3cf518f7-fe6f-4634-8ee5-2be34a540b62', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (971, 60, N'N/A', 0, 123, N'8ee95877-9dd3-41d0-9133-7c7c9d230dcc', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (972, 7, N'N/A', 0, 30, N'3847fff4-7513-4004-bfda-1d96375626fc', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (972, 60, N'N/A', 0, 99, N'20fd8261-60a0-4882-a3a0-4ae1f6d09560', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (973, 7, N'N/A', 0, 99, N'8402fb47-3e3d-41e5-8ece-2849b793dbee', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (973, 60, N'N/A', 0, 86, N'41c0e74e-4032-4e60-bb16-f10b813cdf62', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (974, 7, N'N/A', 0, 67, N'69b40268-0b02-4505-a81e-4dc19487ca0e', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (974, 60, N'N/A', 0, 81, N'fa25bafa-9242-4297-80e3-2810fe60bd4a', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (975, 7, N'N/A', 0, 73, N'4870ccf2-639b-48d8-8144-00429e756050', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (975, 60, N'N/A', 0, 60, N'f45d4d75-30f6-473d-b483-e61f33816143', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (976, 7, N'N/A', 0, 104, N'1c8e0fdc-b8c2-4a90-90fa-b86a48955555', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (976, 60, N'N/A', 0, 123, N'0dcf7f0a-c9a8-4705-bdd0-ca0330371912', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (977, 7, N'N/A', 0, 88, N'ab046689-37dd-4c6e-8d0f-a80098fe0f12', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (977, 60, N'N/A', 0, 65, N'4b6782af-87e4-499b-9572-672ff7e89c70', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (978, 7, N'N/A', 0, 91, N'b2a9cc4c-f998-42f0-9f55-4cefdb524619', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (978, 60, N'N/A', 0, 72, N'49f78f8b-695f-47b8-9c9e-757053503c4c', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (979, 7, N'N/A', 0, 86, N'1bcd1193-92d2-40dc-b9c6-c8243fbc06c1', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (979, 60, N'N/A', 0, 78, N'5cc17093-c813-4bca-b536-aabb821400bc', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (980, 7, N'N/A', 0, 51, N'9ff19e16-dd55-419b-a54e-742a7d1890f8', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (980, 60, N'N/A', 0, 99, N'06a56062-e408-49fd-b457-b609a0ec95f2', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (981, 7, N'N/A', 0, 86, N'46410334-3741-4c83-af6d-504d4fdb0043', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (981, 60, N'N/A', 0, 67, N'0d3979d8-a910-4a0d-9f1d-47c7ce6ae81d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (982, 7, N'N/A', 0, 81, N'01f4a2f8-9c20-4f5f-bcf9-62bff79139ca', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (982, 60, N'N/A', 0, 73, N'62d0e6ae-520f-47bb-a990-2e3facc02a68', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (983, 7, N'N/A', 0, 60, N'a6ce5ed5-95ce-49c2-9e47-459122570a80', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (983, 60, N'N/A', 0, 104, N'0f37d5e1-4711-429d-b6f6-353c040ce0c0', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (984, 7, N'N/A', 0, 81, N'26663b83-3218-4f78-b6fd-4ae02923890c', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (984, 60, N'N/A', 0, 73, N'e93e4af6-83a5-499e-af4b-a08f300d6fce', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (985, 7, N'N/A', 0, 60, N'd2c8a478-0c4c-4063-b805-6cc6cb7e0472', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (985, 60, N'N/A', 0, 104, N'051de7a0-fe4e-43ed-8efd-998a358a1922', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (986, 7, N'N/A', 0, 123, N'c3bdf972-8c67-436a-a777-120a1611dcd4', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (986, 60, N'N/A', 0, 30, N'2d0806ba-aec9-43d3-8c3d-5b63950c4195', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (987, 7, N'N/A', 0, 99, N'f6523155-9c22-43b9-8622-5436fa170d76', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (987, 60, N'N/A', 0, 56, N'a3677547-272d-42bd-8695-42b62cfac65c', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (988, 7, N'N/A', 0, 78, N'9a6dede8-7390-4f0b-be3b-9c6a3077fbe2', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (988, 60, N'N/A', 0, 116, N'edd49182-044c-4221-a956-04eab17a4b78', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (989, 7, N'N/A', 0, 51, N'b4d7b1e6-f6d0-47a2-a199-1266098b9bd6', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (989, 60, N'N/A', 0, 99, N'd4d8248d-61f6-4e20-ba81-89cedfe3c8a7', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (990, 7, N'N/A', 0, 86, N'ffacca72-7e76-4aec-af4d-bbe70adb10bb', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (990, 60, N'N/A', 0, 67, N'64d1a000-b778-48de-92d9-766870860fdf', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (991, 7, N'N/A', 0, 81, N'3538eab5-6729-40d4-951b-12409bce9389', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (991, 60, N'N/A', 0, 73, N'5a58368e-e5b5-440f-8202-ef373d9d5767', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (992, 7, N'N/A', 0, 60, N'd5ae2682-4443-4a2b-a8f5-f0b7bebb5e95', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (992, 60, N'N/A', 0, 104, N'aa4d1028-4706-47d7-9c9c-764d66335d25', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (993, 7, N'N/A', 0, 123, N'06eaddb7-34d1-43c4-bd20-181ce355fcab', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (993, 60, N'N/A', 0, 30, N'a4d61b97-fc1f-4c57-b19f-1eac3533fd13', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (994, 1, N'A', 3, 244, N'86d87365-621e-4ff2-ad66-a7e3b1a2aa79', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (994, 6, N'B', 6, 358, N'a1dc8516-3d00-4a9e-a646-8b55227ebdcb', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (994, 50, N'A', 7, 212, N'79d0d86b-1d66-411f-a4cf-7004f335011b', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (995, 1, N'A', 4, 230, N'35731fe2-c930-4a21-8bd4-d8d1534c01ad', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (995, 6, N'B', 7, 321, N'81034bc0-2a9e-4c8e-831d-3f20cfe86b7a', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (995, 50, N'A', 8, 265, N'15562e5b-291d-4dfe-aa1d-8c66f98edeba', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (996, 1, N'A', 5, 321, N'94e9490e-6677-41b5-87b4-411fbd9fbe1d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (996, 6, N'B', 8, 475, N'9cdedcd7-979c-4ddd-bc2c-67b7176fd808', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (996, 50, N'A', 9, 174, N'9988c90a-ff42-4915-89fd-b8d848699e9c', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (997, 7, N'N/A', 0, 123, N'540b82be-09e5-4e99-9b7b-835ffab06950', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (997, 60, N'N/A', 0, 30, N'731e624a-bd0d-447c-9fe1-472f73917897', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (998, 7, N'N/A', 0, 99, N'b859a235-a1cc-48d7-92bb-10d0c2886e4e', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (998, 60, N'N/A', 0, 56, N'5021e7ea-ce96-433c-860a-b9e57a45ef03', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (999, 7, N'N/A', 0, 78, N'61a26db0-bd17-442b-b119-8e5227811b82', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Production].[ProductInventory] ([ProductID], [LocationID], [Shelf], [Bin], [Quantity], [rowguid], [ModifiedDate]) VALUES (999, 60, N'N/A', 0, 116, N'aff43c54-af78-4635-8f8a-733a1fc2d085', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
SET IDENTITY_INSERT [Purchasing].[ShipMethod] ON 

GO
INSERT [Purchasing].[ShipMethod] ([ShipMethodID], [Name], [ShipBase], [ShipRate], [rowguid], [ModifiedDate]) VALUES (1, N'XRQ - TRUCK GROUND', 3.9500, 0.9900, N'6be756d9-d7be-4463-8f2c-ae60c710d606', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Purchasing].[ShipMethod] ([ShipMethodID], [Name], [ShipBase], [ShipRate], [rowguid], [ModifiedDate]) VALUES (2, N'ZY - EXPRESS', 9.9500, 1.9900, N'3455079b-f773-4dc6-8f1e-2a58649c4ab8', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Purchasing].[ShipMethod] ([ShipMethodID], [Name], [ShipBase], [ShipRate], [rowguid], [ModifiedDate]) VALUES (3, N'OVERSEAS - DELUXE', 29.9500, 2.9900, N'22f4e461-28cf-4ace-a980-f686cf112ec8', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Purchasing].[ShipMethod] ([ShipMethodID], [Name], [ShipBase], [ShipRate], [rowguid], [ModifiedDate]) VALUES (4, N'OVERNIGHT J-FAST', 21.9500, 1.2900, N'107e8356-e7a8-463d-b60c-079fff467f3f', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Purchasing].[ShipMethod] ([ShipMethodID], [Name], [ShipBase], [ShipRate], [rowguid], [ModifiedDate]) VALUES (5, N'CARGO TRANSPORT 5', 8.9900, 1.4900, N'b166019a-b134-4e76-b957-2b0490c610ed', CAST(N'2008-04-30T00:00:00.000' AS DateTime))
GO
SET IDENTITY_INSERT [Purchasing].[ShipMethod] OFF
GO
SET IDENTITY_INSERT [Sales].[SpecialOffer] ON 

GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (1, N'No Discount', 0.0000, N'No Discount', N'No Discount', CAST(N'2011-05-01T00:00:00.000' AS DateTime), CAST(N'2014-11-30T00:00:00.000' AS DateTime), 0, NULL, N'0290c4f5-191f-4337-ab6b-0a2dde03cbf9', CAST(N'2011-04-01T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (2, N'Volume Discount 11 to 14', 0.0200, N'Volume Discount', N'Reseller', CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2014-05-30T00:00:00.000' AS DateTime), 11, 14, N'd7542ee7-15db-4541-985c-5cc27aef26d6', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (3, N'Volume Discount 15 to 24', 0.0500, N'Volume Discount', N'Reseller', CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2014-05-30T00:00:00.000' AS DateTime), 15, 24, N'4bdbcc01-8cf7-40a9-b643-40ec5b717491', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (4, N'Volume Discount 25 to 40', 0.1000, N'Volume Discount', N'Reseller', CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2014-05-30T00:00:00.000' AS DateTime), 25, 40, N'504b5e85-8f3f-4ebc-9e1d-c1bc5dea9aa8', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (5, N'Volume Discount 41 to 60', 0.1500, N'Volume Discount', N'Reseller', CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2014-05-30T00:00:00.000' AS DateTime), 41, 60, N'677e1d9d-944f-4e81-90e8-47eb0a82d48c', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (6, N'Volume Discount over 60', 0.2000, N'Volume Discount', N'Reseller', CAST(N'2011-05-31T00:00:00.000' AS DateTime), CAST(N'2014-05-30T00:00:00.000' AS DateTime), 61, NULL, N'8157f569-4e8d-46b6-9347-5d0f726a9439', CAST(N'2011-05-01T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (7, N'Mountain-100 Clearance Sale', 0.3500, N'Discontinued Product', N'Reseller', CAST(N'2012-04-13T00:00:00.000' AS DateTime), CAST(N'2012-05-29T00:00:00.000' AS DateTime), 0, NULL, N'7df15bf5-6c05-47e7-80a4-22bd1ce59a72', CAST(N'2012-03-14T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (8, N'Sport Helmet Discount-2002', 0.1000, N'Seasonal Discount', N'Reseller', CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2012-06-29T00:00:00.000' AS DateTime), 0, NULL, N'20c5d2cc-a38f-48f8-ac9a-8f15943e52ae', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (9, N'Road-650 Overstock', 0.3000, N'Excess Inventory', N'Reseller', CAST(N'2012-05-30T00:00:00.000' AS DateTime), CAST(N'2012-07-30T00:00:00.000' AS DateTime), 0, NULL, N'0cf8472b-f9e6-4945-9e09-549d7dde2198', CAST(N'2012-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (10, N'Mountain Tire Sale', 0.5000, N'Excess Inventory', N'Customer', CAST(N'2013-05-14T00:00:00.000' AS DateTime), CAST(N'2013-07-29T00:00:00.000' AS DateTime), 0, NULL, N'220444ad-2ef3-4e4c-87e9-3aa6ee39a877', CAST(N'2013-04-14T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (11, N'Sport Helmet Discount-2003', 0.1500, N'Seasonal Discount', N'Reseller', CAST(N'2013-05-30T00:00:00.000' AS DateTime), CAST(N'2013-06-29T00:00:00.000' AS DateTime), 0, NULL, N'e72dab1d-f44d-448b-9fe2-f259a2f0210d', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (12, N'LL Road Frame Sale', 0.3500, N'Excess Inventory', N'Reseller', CAST(N'2013-05-30T00:00:00.000' AS DateTime), CAST(N'2013-07-14T00:00:00.000' AS DateTime), 0, NULL, N'c0af1c89-9722-4235-9248-3fba4d9e5841', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (13, N'Touring-3000 Promotion', 0.1500, N'New Product', N'Reseller', CAST(N'2013-05-30T00:00:00.000' AS DateTime), CAST(N'2013-08-29T00:00:00.000' AS DateTime), 0, NULL, N'5061cce4-e021-45a8-9a75-dfb36cbbce85', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (14, N'Touring-1000 Promotion', 0.2000, N'New Product', N'Reseller', CAST(N'2013-05-30T00:00:00.000' AS DateTime), CAST(N'2013-08-29T00:00:00.000' AS DateTime), 0, NULL, N'1af84a9e-a98c-4bd9-b48f-dc2b8b6b010b', CAST(N'2013-04-30T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (15, N'Half-Price Pedal Sale', 0.5000, N'Seasonal Discount', N'Customer', CAST(N'2013-07-14T00:00:00.000' AS DateTime), CAST(N'2013-08-14T00:00:00.000' AS DateTime), 0, NULL, N'03e3594d-6ebb-46a6-b8ee-a9289c0c2e47', CAST(N'2013-06-14T00:00:00.000' AS DateTime))
GO
INSERT [Sales].[SpecialOffer] ([SpecialOfferID], [Description], [DiscountPct], [Type], [Category], [StartDate], [EndDate], [MinQty], [MaxQty], [rowguid], [ModifiedDate]) VALUES (16, N'Mountain-500 Silver Clearance Sale', 0.4000, N'Discontinued Product', N'Reseller', CAST(N'2014-03-31T00:00:00.000' AS DateTime), CAST(N'2014-05-30T00:00:00.000' AS DateTime), 0, NULL, N'eb7cb484-bccf-4d2d-bf73-521b20014174', CAST(N'2014-03-01T00:00:00.000' AS DateTime))
GO
SET IDENTITY_INSERT [Sales].[SpecialOffer] OFF
GO
SET IDENTITY_INSERT [Sales].[ShoppingCartItem] ON 

GO
INSERT [Sales].[ShoppingCartItem] ([ShoppingCartItemID], [ShoppingCartID], [Quantity], [ProductID], [DateCreated], [ModifiedDate]) VALUES (2, N'14951', 3, 862, CAST(N'2013-11-09T17:54:07.603' AS DateTime), CAST(N'2013-11-09T17:54:07.603' AS DateTime))
GO
INSERT [Sales].[ShoppingCartItem] ([ShoppingCartItemID], [ShoppingCartID], [Quantity], [ProductID], [DateCreated], [ModifiedDate]) VALUES (4, N'20621', 4, 881, CAST(N'2013-11-09T17:54:07.603' AS DateTime), CAST(N'2013-11-09T17:54:07.603' AS DateTime))
GO
INSERT [Sales].[ShoppingCartItem] ([ShoppingCartItemID], [ShoppingCartID], [Quantity], [ProductID], [DateCreated], [ModifiedDate]) VALUES (5, N'20621', 7, 874, CAST(N'2013-11-09T17:54:07.603' AS DateTime), CAST(N'2013-11-09T17:54:07.603' AS DateTime))
GO
SET IDENTITY_INSERT [Sales].[ShoppingCartItem] OFF
GO
ALTER TABLE [Production].[ProductCategory] ADD  CONSTRAINT [DF_ProductCategory_rowguid]  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [Production].[ProductCategory] ADD  CONSTRAINT [DF_ProductCategory_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [Production].[ProductSubcategory] ADD  CONSTRAINT [DF_ProductSubcategory_rowguid]  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [Production].[ProductSubcategory] ADD  CONSTRAINT [DF_ProductSubcategory_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [Production].[Product] ADD  CONSTRAINT [DF_Product_MakeFlag]  DEFAULT ((1)) FOR [MakeFlag]
GO
ALTER TABLE [Production].[Product] ADD  CONSTRAINT [DF_Product_FinishedGoodsFlag]  DEFAULT ((1)) FOR [FinishedGoodsFlag]
GO
ALTER TABLE [Production].[Product] ADD  CONSTRAINT [DF_Product_rowguid]  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [Production].[Product] ADD  CONSTRAINT [DF_Product_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [Production].[ProductInventory] ADD  CONSTRAINT [DF_ProductInventory_Quantity]  DEFAULT ((0)) FOR [Quantity]
GO
ALTER TABLE [Production].[ProductInventory] ADD  CONSTRAINT [DF_ProductInventory_rowguid]  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [Production].[ProductInventory] ADD  CONSTRAINT [DF_ProductInventory_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [Purchasing].[ShipMethod] ADD  CONSTRAINT [DF_ShipMethod_ShipBase]  DEFAULT ((0.00)) FOR [ShipBase]
GO
ALTER TABLE [Purchasing].[ShipMethod] ADD  CONSTRAINT [DF_ShipMethod_ShipRate]  DEFAULT ((0.00)) FOR [ShipRate]
GO
ALTER TABLE [Purchasing].[ShipMethod] ADD  CONSTRAINT [DF_ShipMethod_rowguid]  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [Purchasing].[ShipMethod] ADD  CONSTRAINT [DF_ShipMethod_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [Sales].[SpecialOffer] ADD  CONSTRAINT [DF_SpecialOffer_DiscountPct]  DEFAULT ((0.00)) FOR [DiscountPct]
GO
ALTER TABLE [Sales].[SpecialOffer] ADD  CONSTRAINT [DF_SpecialOffer_MinQty]  DEFAULT ((0)) FOR [MinQty]
GO
ALTER TABLE [Sales].[SpecialOffer] ADD  CONSTRAINT [DF_SpecialOffer_rowguid]  DEFAULT (newid()) FOR [rowguid]
GO
ALTER TABLE [Sales].[SpecialOffer] ADD  CONSTRAINT [DF_SpecialOffer_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [Sales].[ShoppingCartItem] ADD  CONSTRAINT [DF_ShoppingCartItem_Quantity]  DEFAULT ((1)) FOR [Quantity]
GO
ALTER TABLE [Sales].[ShoppingCartItem] ADD  CONSTRAINT [DF_ShoppingCartItem_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
GO
ALTER TABLE [Sales].[ShoppingCartItem] ADD  CONSTRAINT [DF_ShoppingCartItem_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_Class] CHECK  ((upper([Class])='H' OR upper([Class])='M' OR upper([Class])='L' OR [Class] IS NULL))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_Class]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_DaysToManufacture] CHECK  (([DaysToManufacture]>=(0)))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_DaysToManufacture]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_ListPrice] CHECK  (([ListPrice]>=(0.00)))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_ListPrice]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_ProductLine] CHECK  ((upper([ProductLine])='R' OR upper([ProductLine])='M' OR upper([ProductLine])='T' OR upper([ProductLine])='S' OR [ProductLine] IS NULL))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_ProductLine]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_ReorderPoint] CHECK  (([ReorderPoint]>(0)))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_ReorderPoint]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_SafetyStockLevel] CHECK  (([SafetyStockLevel]>(0)))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_SafetyStockLevel]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_SellEndDate] CHECK  (([SellEndDate]>=[SellStartDate] OR [SellEndDate] IS NULL))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_SellEndDate]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_StandardCost] CHECK  (([StandardCost]>=(0.00)))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_StandardCost]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_Style] CHECK  ((upper([Style])='U' OR upper([Style])='M' OR upper([Style])='W' OR [Style] IS NULL))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_Style]
GO
ALTER TABLE [Production].[Product]  WITH CHECK ADD  CONSTRAINT [CK_Product_Weight] CHECK  (([Weight]>(0.00)))
GO
ALTER TABLE [Production].[Product] CHECK CONSTRAINT [CK_Product_Weight]
GO
ALTER TABLE [Production].[ProductInventory]  WITH CHECK ADD  CONSTRAINT [CK_ProductInventory_Bin] CHECK  (([Bin]>=(0) AND [Bin]<=(100)))
GO
ALTER TABLE [Production].[ProductInventory] CHECK CONSTRAINT [CK_ProductInventory_Bin]
GO
ALTER TABLE [Production].[ProductInventory]  WITH CHECK ADD  CONSTRAINT [CK_ProductInventory_Shelf] CHECK  (([Shelf] like '[A-Za-z]' OR [Shelf]='N/A'))
GO
ALTER TABLE [Production].[ProductInventory] CHECK CONSTRAINT [CK_ProductInventory_Shelf]
GO
ALTER TABLE [Purchasing].[ShipMethod]  WITH CHECK ADD  CONSTRAINT [CK_ShipMethod_ShipBase] CHECK  (([ShipBase]>(0.00)))
GO
ALTER TABLE [Purchasing].[ShipMethod] CHECK CONSTRAINT [CK_ShipMethod_ShipBase]
GO
ALTER TABLE [Purchasing].[ShipMethod]  WITH CHECK ADD  CONSTRAINT [CK_ShipMethod_ShipRate] CHECK  (([ShipRate]>(0.00)))
GO
ALTER TABLE [Purchasing].[ShipMethod] CHECK CONSTRAINT [CK_ShipMethod_ShipRate]
GO
ALTER TABLE [Sales].[SpecialOffer]  WITH CHECK ADD  CONSTRAINT [CK_SpecialOffer_DiscountPct] CHECK  (([DiscountPct]>=(0.00)))
GO
ALTER TABLE [Sales].[SpecialOffer] CHECK CONSTRAINT [CK_SpecialOffer_DiscountPct]
GO
ALTER TABLE [Sales].[SpecialOffer]  WITH CHECK ADD  CONSTRAINT [CK_SpecialOffer_EndDate] CHECK  (([EndDate]>=[StartDate]))
GO
ALTER TABLE [Sales].[SpecialOffer] CHECK CONSTRAINT [CK_SpecialOffer_EndDate]
GO
ALTER TABLE [Sales].[SpecialOffer]  WITH CHECK ADD  CONSTRAINT [CK_SpecialOffer_MaxQty] CHECK  (([MaxQty]>=(0)))
GO
ALTER TABLE [Sales].[SpecialOffer] CHECK CONSTRAINT [CK_SpecialOffer_MaxQty]
GO
ALTER TABLE [Sales].[SpecialOffer]  WITH CHECK ADD  CONSTRAINT [CK_SpecialOffer_MinQty] CHECK  (([MinQty]>=(0)))
GO
ALTER TABLE [Sales].[SpecialOffer] CHECK CONSTRAINT [CK_SpecialOffer_MinQty]
GO
ALTER TABLE [Sales].[ShoppingCartItem]  WITH CHECK ADD  CONSTRAINT [CK_ShoppingCartItem_Quantity] CHECK  (([Quantity]>=(1)))
GO
ALTER TABLE [Sales].[ShoppingCartItem] CHECK CONSTRAINT [CK_ShoppingCartItem_Quantity]
GO
/* ---- Customers & orders : project-scoped subset (FKs omitted) + demo seed ---- */
CREATE TABLE [Person].[Person](
    [BusinessEntityID] int NOT NULL PRIMARY KEY,
    [PersonType] nchar(2) NOT NULL,
    [FirstName] [dbo].[Name] NOT NULL,
    [MiddleName] [dbo].[Name] NULL,
    [LastName] [dbo].[Name] NOT NULL,
    [ModifiedDate] datetime NOT NULL CONSTRAINT [DF_Person_ModifiedDate] DEFAULT (SYSDATETIME())
);
GO
CREATE TABLE [Person].[EmailAddress](
    [BusinessEntityID] int NOT NULL,
    [EmailAddressID] int NOT NULL,
    [EmailAddress] nvarchar(50) NULL,
    [ModifiedDate] datetime NOT NULL CONSTRAINT [DF_EmailAddress_ModifiedDate] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_EmailAddress] PRIMARY KEY ([BusinessEntityID],[EmailAddressID])
);
GO
CREATE TABLE [Person].[Address](
    [AddressID] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [AddressLine1] nvarchar(60) NOT NULL,
    [AddressLine2] nvarchar(60) NULL,
    [City] nvarchar(30) NOT NULL,
    [StateProvinceID] int NOT NULL,
    [PostalCode] nvarchar(15) NOT NULL,
    [ModifiedDate] datetime NOT NULL CONSTRAINT [DF_Address_ModifiedDate] DEFAULT (SYSDATETIME())
);
GO
CREATE TABLE [Person].[BusinessEntityAddress](
    [BusinessEntityID] int NOT NULL,
    [AddressID] int NOT NULL,
    [AddressTypeID] int NOT NULL,
    [ModifiedDate] datetime NOT NULL CONSTRAINT [DF_BEA_ModifiedDate] DEFAULT (SYSDATETIME()),
    CONSTRAINT [PK_BusinessEntityAddress] PRIMARY KEY ([BusinessEntityID],[AddressID],[AddressTypeID])
);
GO
CREATE TABLE [Sales].[Customer](
    [CustomerID] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [PersonID] int NULL,
    [StoreID] int NULL,
    [TerritoryID] int NULL,
    [AccountNumber] nvarchar(10) NULL,
    [ModifiedDate] datetime NOT NULL CONSTRAINT [DF_Customer_ModifiedDate] DEFAULT (SYSDATETIME())
);
GO
CREATE TABLE [Sales].[SalesOrderHeader](
    [SalesOrderID] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [OrderDate] datetime NOT NULL CONSTRAINT [DF_SOH_OrderDate] DEFAULT (SYSDATETIME()),
    [DueDate] datetime NOT NULL,
    [ShipDate] datetime NULL,
    [Status] tinyint NOT NULL CONSTRAINT [DF_SOH_Status] DEFAULT (1),
    [OnlineOrderFlag] [dbo].[Flag] NOT NULL CONSTRAINT [DF_SOH_Online] DEFAULT (1),
    [SalesOrderNumber] nvarchar(25) NULL,
    [CustomerID] int NOT NULL,
    [ShipToAddressID] int NULL,
    [BillToAddressID] int NULL,
    [ShipMethodID] int NOT NULL,
    [SubTotal] money NOT NULL CONSTRAINT [DF_SOH_SubTotal] DEFAULT (0.00),
    [TaxAmt] money NOT NULL CONSTRAINT [DF_SOH_TaxAmt] DEFAULT (0.00),
    [Freight] money NOT NULL CONSTRAINT [DF_SOH_Freight] DEFAULT (0.00),
    [TotalDue] AS (ISNULL(([SubTotal]+[TaxAmt])+[Freight],(0))),
    [Comment] nvarchar(128) NULL,
    [ModifiedDate] datetime NOT NULL CONSTRAINT [DF_SOH_ModifiedDate] DEFAULT (SYSDATETIME())
);
GO
CREATE TABLE [Sales].[SalesOrderDetail](
    [SalesOrderID] int NOT NULL,
    [SalesOrderDetailID] int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [OrderQty] smallint NOT NULL,
    [ProductID] int NOT NULL,
    [SpecialOfferID] int NOT NULL CONSTRAINT [DF_SOD_SpecialOffer] DEFAULT (1),
    [UnitPrice] money NOT NULL,
    [UnitPriceDiscount] money NOT NULL CONSTRAINT [DF_SOD_Discount] DEFAULT (0.00),
    [LineTotal] AS (ISNULL(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
    [ModifiedDate] datetime NOT NULL CONSTRAINT [DF_SOD_ModifiedDate] DEFAULT (SYSDATETIME())
);
GO
/* ---- Demo seed: one customer with one online order (matches the benchmark seed user) ---- */
INSERT INTO [Person].[Person] ([BusinessEntityID],[PersonType],[FirstName],[LastName])
VALUES (100000, N'IN', N'Alex', N'Customer');
INSERT INTO [Person].[EmailAddress] ([BusinessEntityID],[EmailAddressID],[EmailAddress])
VALUES (100000, 1, N'customer@adventureworks.com');
SET IDENTITY_INSERT [Person].[Address] ON;
INSERT INTO [Person].[Address] ([AddressID],[AddressLine1],[City],[StateProvinceID],[PostalCode])
VALUES (90000, N'123 Elm Street', N'Seattle', 79, N'98101');
SET IDENTITY_INSERT [Person].[Address] OFF;
INSERT INTO [Person].[BusinessEntityAddress] ([BusinessEntityID],[AddressID],[AddressTypeID])
VALUES (100000, 90000, 2);
SET IDENTITY_INSERT [Sales].[Customer] ON;
INSERT INTO [Sales].[Customer] ([CustomerID],[PersonID],[TerritoryID],[AccountNumber])
VALUES (90000, 100000, 1, N'AW90000');
SET IDENTITY_INSERT [Sales].[Customer] OFF;
SET IDENTITY_INSERT [Sales].[SalesOrderHeader] ON;
INSERT INTO [Sales].[SalesOrderHeader]
    ([SalesOrderID],[OrderDate],[DueDate],[Status],[OnlineOrderFlag],[SalesOrderNumber],
     [CustomerID],[ShipToAddressID],[BillToAddressID],[ShipMethodID],[SubTotal],[TaxAmt],[Freight],[Comment])
VALUES (90000, '2026-07-22T10:15:00', '2026-07-29T10:15:00', 1, 1, N'SO90000',
     90000, 90000, 90000, 1, 69.98, 5.60, 3.95, N'Demo order');
SET IDENTITY_INSERT [Sales].[SalesOrderHeader] OFF;
INSERT INTO [Sales].[SalesOrderDetail] ([SalesOrderID],[OrderQty],[ProductID],[SpecialOfferID],[UnitPrice])
VALUES (90000, 2, 707, 1, 34.99);
GO