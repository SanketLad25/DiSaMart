USE CartDB;
GO
IF OBJECT_ID(N'dbo.Carts', N'U') IS NULL
BEGIN
CREATE TABLE dbo.Carts (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Carts PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    CurrencyCode NVARCHAR(3) NOT NULL CONSTRAINT DF_Carts_Currency DEFAULT(N'INR'),
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Carts_CreatedAtUtc DEFAULT(SYSUTCDATETIME()),
    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Carts_UpdatedAtUtc DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT UQ_Carts_User UNIQUE (UserId)
);
END;
GO
IF OBJECT_ID(N'dbo.CartItems', N'U') IS NULL
BEGIN
CREATE TABLE dbo.CartItems (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_CartItems PRIMARY KEY,
    CartId UNIQUEIDENTIFIER NOT NULL,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    Quantity INT NOT NULL,
    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_CartItems_UpdatedAtUtc DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT FK_CartItems_Carts FOREIGN KEY (CartId) REFERENCES dbo.Carts(Id),
    CONSTRAINT CK_CartItems_Quantity CHECK (Quantity BETWEEN 1 AND 99),
    CONSTRAINT CK_CartItems_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT UQ_CartItems_CartProduct UNIQUE (CartId, ProductId)
);
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.CartItems') AND name=N'IX_CartItems_CartId')
    CREATE INDEX IX_CartItems_CartId ON dbo.CartItems(CartId);
GO

USE CheckoutDB;
GO
IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
CREATE TABLE dbo.Orders (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    CartId UNIQUEIDENTIFIER NOT NULL,
    Subtotal DECIMAL(18,2) NOT NULL,
    ShippingCharge DECIMAL(18,2) NOT NULL,
    Tax DECIMAL(18,2) NOT NULL,
    GrandTotal DECIMAL(18,2) NOT NULL,
    CurrencyCode NVARCHAR(3) NOT NULL,
    PaymentId UNIQUEIDENTIFIER NULL,
    ShipmentId UNIQUEIDENTIFIER NULL,
    Status NVARCHAR(30) NOT NULL,
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Orders_CreatedAtUtc DEFAULT(SYSUTCDATETIME()),
    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Orders_UpdatedAtUtc DEFAULT(SYSUTCDATETIME())
);
END;
GO
IF OBJECT_ID(N'dbo.OrderItems', N'U') IS NULL
BEGIN
CREATE TABLE dbo.OrderItems (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_OrderItems PRIMARY KEY,
    OrderId UNIQUEIDENTIFIER NOT NULL,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    Quantity INT NOT NULL,
    LineTotal DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id),
    CONSTRAINT CK_OrderItems_Quantity CHECK (Quantity > 0)
);
END;
GO
IF OBJECT_ID(N'dbo.OrderStatusHistory', N'U') IS NULL
BEGIN
CREATE TABLE dbo.OrderStatusHistory (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_OrderStatusHistory PRIMARY KEY,
    OrderId UNIQUEIDENTIFIER NOT NULL,
    Status NVARCHAR(30) NOT NULL,
    Comment NVARCHAR(500) NULL,
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_OrderStatusHistory_CreatedAtUtc DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT FK_OrderStatusHistory_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id)
);
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.Orders') AND name=N'IX_Orders_UserId')
    CREATE INDEX IX_Orders_UserId ON dbo.Orders(UserId, CreatedAtUtc DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.OrderItems') AND name=N'IX_OrderItems_OrderId')
    CREATE INDEX IX_OrderItems_OrderId ON dbo.OrderItems(OrderId);
GO

USE PaymentDB;
GO
IF OBJECT_ID(N'dbo.Payments', N'U') IS NULL
BEGIN
CREATE TABLE dbo.Payments (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Payments PRIMARY KEY,
    OrderId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    CurrencyCode NVARCHAR(3) NOT NULL,
    Method NVARCHAR(30) NOT NULL,
    Status NVARCHAR(30) NOT NULL,
    FailureReason NVARCHAR(500) NULL,
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Payments_CreatedAtUtc DEFAULT(SYSUTCDATETIME()),
    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Payments_UpdatedAtUtc DEFAULT(SYSUTCDATETIME())
);
END;
GO
IF OBJECT_ID(N'dbo.PaymentTransactions', N'U') IS NULL
BEGIN
CREATE TABLE dbo.PaymentTransactions (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_PaymentTransactions PRIMARY KEY,
    PaymentId UNIQUEIDENTIFIER NOT NULL,
    ProviderReference NVARCHAR(100) NOT NULL,
    Status NVARCHAR(30) NOT NULL,
    RequestPayload NVARCHAR(MAX) NULL,
    ResponsePayload NVARCHAR(MAX) NULL,
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_PaymentTransactions_CreatedAtUtc DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT FK_PaymentTransactions_Payments FOREIGN KEY (PaymentId) REFERENCES dbo.Payments(Id)
);
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.Payments') AND name=N'IX_Payments_OrderId')
    CREATE INDEX IX_Payments_OrderId ON dbo.Payments(OrderId);
GO

USE ShippingDB;
GO
IF OBJECT_ID(N'dbo.ShippingAddresses', N'U') IS NULL
BEGIN
CREATE TABLE dbo.ShippingAddresses (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ShippingAddresses PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    FullName NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(20) NOT NULL,
    AddressLine1 NVARCHAR(300) NOT NULL,
    AddressLine2 NVARCHAR(300) NULL,
    City NVARCHAR(100) NOT NULL,
    State NVARCHAR(100) NOT NULL,
    PostalCode NVARCHAR(20) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_ShippingAddresses_User UNIQUE (UserId, FullName, Phone, AddressLine1, PostalCode)
);
END;
GO
IF OBJECT_ID(N'dbo.Shipments', N'U') IS NULL
BEGIN
CREATE TABLE dbo.Shipments (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Shipments PRIMARY KEY,
    OrderId UNIQUEIDENTIFIER NOT NULL,
    AddressId UNIQUEIDENTIFIER NOT NULL,
    Carrier NVARCHAR(100) NOT NULL,
    TrackingNumber NVARCHAR(100) NOT NULL,
    Status NVARCHAR(30) NOT NULL,
    ShippingCharge DECIMAL(18,2) NOT NULL,
    EstimatedDeliveryDateUtc DATETIME2 NOT NULL,
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Shipments_CreatedAtUtc DEFAULT(SYSUTCDATETIME()),
    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Shipments_UpdatedAtUtc DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT FK_Shipments_Addresses FOREIGN KEY (AddressId) REFERENCES dbo.ShippingAddresses(Id)
);
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.Shipments') AND name=N'IX_Shipments_OrderId')
    CREATE INDEX IX_Shipments_OrderId ON dbo.Shipments(OrderId);
GO

USE EmailDB;
GO
IF OBJECT_ID(N'dbo.EmailTemplates', N'U') IS NULL
BEGIN
CREATE TABLE dbo.EmailTemplates (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_EmailTemplates PRIMARY KEY,
    TemplateKey NVARCHAR(100) NOT NULL,
    SubjectTemplate NVARCHAR(300) NOT NULL,
    BodyTemplate NVARCHAR(MAX) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_EmailTemplates_IsActive DEFAULT(1),
    CONSTRAINT UQ_EmailTemplates_Key UNIQUE (TemplateKey)
);
END;
GO
IF OBJECT_ID(N'dbo.EmailLogs', N'U') IS NULL
BEGIN
CREATE TABLE dbo.EmailLogs (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_EmailLogs PRIMARY KEY,
    Recipient NVARCHAR(320) NOT NULL,
    Subject NVARCHAR(300) NOT NULL,
    Body NVARCHAR(MAX) NOT NULL,
    TemplateKey NVARCHAR(100) NULL,
    Status NVARCHAR(30) NOT NULL,
    Error NVARCHAR(1000) NULL,
    SentAtUtc DATETIME2 NULL,
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_EmailLogs_CreatedAtUtc DEFAULT(SYSUTCDATETIME())
);
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.EmailLogs') AND name=N'IX_EmailLogs_CreatedAtUtc')
    CREATE INDEX IX_EmailLogs_CreatedAtUtc ON dbo.EmailLogs(CreatedAtUtc DESC);
GO

USE RecommendationDB;
GO
IF OBJECT_ID(N'dbo.ProductRecommendations', N'U') IS NULL
BEGIN
CREATE TABLE dbo.ProductRecommendations (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ProductRecommendations PRIMARY KEY,
    SourceProductId UNIQUEIDENTIFIER NULL,
    RecommendedProductId UNIQUEIDENTIFIER NOT NULL,
    RecommendationType NVARCHAR(30) NOT NULL,
    Score DECIMAL(5,2) NOT NULL CONSTRAINT DF_ProductRecommendations_Score DEFAULT(0),
    IsActive BIT NOT NULL CONSTRAINT DF_ProductRecommendations_IsActive DEFAULT(1),
    CONSTRAINT CK_ProductRecommendations_Score CHECK (Score BETWEEN 0 AND 100)
);
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.ProductRecommendations') AND name=N'IX_ProductRecommendations_Source')
    CREATE INDEX IX_ProductRecommendations_Source ON dbo.ProductRecommendations(SourceProductId, IsActive);
GO

USE AdDB;
GO
IF OBJECT_ID(N'dbo.Advertisements', N'U') IS NULL
BEGIN
CREATE TABLE dbo.Advertisements (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Advertisements PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000) NULL,
    ImageUrl NVARCHAR(500) NULL,
    TargetUrl NVARCHAR(500) NULL,
    Placement NVARCHAR(50) NOT NULL,
    Priority INT NOT NULL CONSTRAINT DF_Advertisements_Priority DEFAULT(0),
    StartAtUtc DATETIME2 NOT NULL,
    EndAtUtc DATETIME2 NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Advertisements_IsActive DEFAULT(1)
);
END;
GO
IF OBJECT_ID(N'dbo.Campaigns', N'U') IS NULL
BEGIN
CREATE TABLE dbo.Campaigns (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Campaigns PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    DiscountPercentage DECIMAL(5,2) NOT NULL,
    StartAtUtc DATETIME2 NOT NULL,
    EndAtUtc DATETIME2 NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Campaigns_IsActive DEFAULT(1),
    CONSTRAINT CK_Campaigns_Discount CHECK (DiscountPercentage BETWEEN 0 AND 100)
);
END;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.Advertisements') AND name=N'IX_Advertisements_ActivePlacement')
    CREATE INDEX IX_Advertisements_ActivePlacement ON dbo.Advertisements(IsActive, Placement, Priority);
GO

USE CurrencyDB;
GO
IF OBJECT_ID(N'dbo.Currencies', N'U') IS NULL
BEGIN
CREATE TABLE dbo.Currencies (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Currencies PRIMARY KEY,
    Code NVARCHAR(3) NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    Symbol NVARCHAR(10) NOT NULL,
    DecimalDigits INT NOT NULL,
    IsBase BIT NOT NULL CONSTRAINT DF_Currencies_IsBase DEFAULT(0),
    IsActive BIT NOT NULL CONSTRAINT DF_Currencies_IsActive DEFAULT(1),
    CONSTRAINT UQ_Currencies_Code UNIQUE (Code)
);
END;
GO
IF OBJECT_ID(N'dbo.ExchangeRates', N'U') IS NULL
BEGIN
CREATE TABLE dbo.ExchangeRates (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ExchangeRates PRIMARY KEY,
    BaseCurrencyCode NVARCHAR(3) NOT NULL,
    TargetCurrencyCode NVARCHAR(3) NOT NULL,
    Rate DECIMAL(18,8) NOT NULL,
    EffectiveAtUtc DATETIME2 NOT NULL CONSTRAINT DF_ExchangeRates_EffectiveAtUtc DEFAULT(SYSUTCDATETIME()),
    IsActive BIT NOT NULL CONSTRAINT DF_ExchangeRates_IsActive DEFAULT(1),
    CONSTRAINT CK_ExchangeRates_Rate CHECK (Rate > 0),
    CONSTRAINT UQ_ExchangeRates_Pair UNIQUE (BaseCurrencyCode, TargetCurrencyCode)
);
END;
GO

USE CustomizationDB;
GO
IF OBJECT_ID(N'dbo.ApplicationSettings', N'U') IS NULL
BEGIN
CREATE TABLE dbo.ApplicationSettings (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ApplicationSettings PRIMARY KEY,
    [Key] NVARCHAR(100) NOT NULL,
    [Value] NVARCHAR(MAX) NOT NULL,
    DataType NVARCHAR(30) NOT NULL,
    IsPublic BIT NOT NULL CONSTRAINT DF_ApplicationSettings_IsPublic DEFAULT(1),
    IsActive BIT NOT NULL CONSTRAINT DF_ApplicationSettings_IsActive DEFAULT(1),
    CONSTRAINT UQ_ApplicationSettings_Key UNIQUE ([Key])
);
END;
GO
IF OBJECT_ID(N'dbo.UserPreferences', N'U') IS NULL
BEGIN
CREATE TABLE dbo.UserPreferences (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_UserPreferences PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    Theme NVARCHAR(30) NOT NULL,
    CurrencyCode NVARCHAR(3) NOT NULL,
    [Language] NVARCHAR(10) NOT NULL,
    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_UserPreferences_UpdatedAtUtc DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT UQ_UserPreferences_User UNIQUE (UserId)
);
END;
GO
