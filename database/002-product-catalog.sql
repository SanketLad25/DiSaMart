USE ProductCatalogDB;
GO

IF OBJECT_ID(N'dbo.ProductImages', N'U') IS NOT NULL
    DROP TABLE dbo.ProductImages;
IF OBJECT_ID(N'dbo.Products', N'U') IS NOT NULL
    DROP TABLE dbo.Products;
IF OBJECT_ID(N'dbo.Categories', N'U') IS NOT NULL
    DROP TABLE dbo.Categories;
GO

CREATE TABLE dbo.Categories (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Categories PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Slug NVARCHAR(100) NOT NULL,
    ImageUrl NVARCHAR(500) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Categories_IsActive DEFAULT(1),
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Categories_CreatedAtUtc DEFAULT(SYSUTCDATETIME()),
    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Categories_UpdatedAtUtc DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT UQ_Categories_Name UNIQUE (Name),
    CONSTRAINT UQ_Categories_Slug UNIQUE (Slug)
);
GO

CREATE TABLE dbo.Products (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
    CategoryId UNIQUEIDENTIFIER NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(2000) NOT NULL,
    ImageUrl NVARCHAR(500) NULL,
    OriginalPrice DECIMAL(18,2) NOT NULL,
    DiscountPrice DECIMAL(18,2) NOT NULL,
    StockQuantity INT NOT NULL,
    Rating DECIMAL(3,2) NOT NULL,
    IsFeatured BIT NOT NULL CONSTRAINT DF_Products_IsFeatured DEFAULT(0),
    IsActive BIT NOT NULL CONSTRAINT DF_Products_IsActive DEFAULT(1),
    CreatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Products_CreatedAtUtc DEFAULT(SYSUTCDATETIME()),
    UpdatedAtUtc DATETIME2 NOT NULL CONSTRAINT DF_Products_UpdatedAtUtc DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryId) REFERENCES dbo.Categories(Id),
    CONSTRAINT CK_Products_Prices CHECK (OriginalPrice >= 0 AND DiscountPrice >= 0 AND DiscountPrice <= OriginalPrice),
    CONSTRAINT CK_Products_Stock CHECK (StockQuantity >= 0),
    CONSTRAINT CK_Products_Rating CHECK (Rating BETWEEN 0 AND 5)
);
GO

CREATE TABLE dbo.ProductImages (
    Id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ProductImages PRIMARY KEY,
    ProductId UNIQUEIDENTIFIER NOT NULL,
    ImageUrl NVARCHAR(500) NOT NULL,
    SortOrder INT NOT NULL CONSTRAINT DF_ProductImages_SortOrder DEFAULT(0),
    CONSTRAINT FK_ProductImages_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(Id)
);
GO

CREATE INDEX IX_Products_CategoryId ON dbo.Products(CategoryId);
CREATE INDEX IX_Products_IsFeatured ON dbo.Products(IsFeatured) INCLUDE (Name, DiscountPrice);
CREATE INDEX IX_Products_IsActive ON dbo.Products(IsActive);
CREATE INDEX IX_Products_Name ON dbo.Products(Name);
CREATE INDEX IX_ProductImages_ProductId ON dbo.ProductImages(ProductId, SortOrder);
GO

DECLARE @Grocery UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000001';
DECLARE @Appliances UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000002';
DECLARE @Electronics UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000003';
DECLARE @Fashion UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000004';

MERGE dbo.Categories AS target
USING (VALUES
    (@Grocery, N'Grocery', N'grocery', N'/images/categories/grocery.svg'),
    (@Appliances, N'Home Appliances', N'home-appliances', N'/images/categories/home-appliances.svg'),
    (@Electronics, N'Electronics & Gadgets', N'electronics-gadgets', N'/images/categories/electronics-gadgets.svg'),
    (@Fashion, N'Fashion & Clothing', N'fashion-clothing', N'/images/categories/fashion-clothing.svg')
) AS source(Id, Name, Slug, ImageUrl)
ON target.Id = source.Id
WHEN MATCHED THEN UPDATE SET Name=source.Name, Slug=source.Slug, ImageUrl=source.ImageUrl, UpdatedAtUtc=SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (Id, Name, Slug, ImageUrl) VALUES (source.Id, source.Name, source.Slug, source.ImageUrl);
GO

DECLARE @Grocery UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000001';
DECLARE @Appliances UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000002';
DECLARE @Electronics UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000003';
DECLARE @Fashion UNIQUEIDENTIFIER = 'A0000000-0000-0000-0000-000000000004';

MERGE dbo.Products AS target
USING (VALUES
(NEWID(), @Grocery, N'Premium Basmati Rice', N'Long-grain aromatic rice suitable for everyday cooking.', N'/images/products/rice.svg', 1499.00, 1299.00, 120, 4.70, 1),
(NEWID(), @Grocery, N'Whole Wheat Flour', N'Stone-ground whole wheat flour for soft rotis and breads.', N'/images/products/wheat-flour.svg', 349.00, 299.00, 180, 4.60, 0),
(NEWID(), @Grocery, N'Refined Sugar', N'Clean and finely granulated sugar for cooking and beverages.', N'/images/products/sugar.svg', 220.00, 189.00, 200, 4.40, 0),
(NEWID(), @Grocery, N'Sunflower Cooking Oil', N'Light cooking oil packed in a convenient 5 litre container.', N'/images/products/cooking-oil.svg', 899.00, 799.00, 90, 4.50, 1),
(NEWID(), @Grocery, N'Darjeeling Tea Powder', N'Full-bodied tea powder with a smooth aromatic finish.', N'/images/products/tea.svg', 399.00, 349.00, 140, 4.80, 1),
(NEWID(), @Grocery, N'Premium Coffee Powder', N'Dark roasted coffee powder with a rich balanced flavour.', N'/images/products/coffee.svg', 699.00, 599.00, 100, 4.70, 0),
(NEWID(), @Grocery, N'Fresh Milk', N'Pasteurized full cream milk in a one litre pack.', N'/images/products/milk.svg', 72.00, 68.00, 300, 4.30, 0),
(NEWID(), @Grocery, N'Multigrain Biscuits', N'Crispy fibre-rich biscuits with a wholesome taste.', N'/images/products/biscuits.svg', 180.00, 149.00, 160, 4.50, 0),
(NEWID(), @Grocery, N'Mixed Dry Fruits', N'A premium mix of almonds, cashews, raisins, and pistachios.', N'/images/products/dry-fruits.svg', 1199.00, 999.00, 75, 4.80, 1),
(NEWID(), @Grocery, N'Masala Spice Box', N'Assorted everyday spices for classic Indian cooking.', N'/images/products/spices.svg', 499.00, 429.00, 110, 4.60, 0),
(NEWID(), @Appliances, N'Double Door Refrigerator', N'Energy-efficient 340 litre refrigerator with frost-free cooling.', N'/images/products/refrigerator.svg', 38999.00, 34999.00, 22, 4.70, 1),
(NEWID(), @Appliances, N'Front Load Washing Machine', N'8 kg washing machine with inverter motor and 15 wash programs.', N'/images/products/washing-machine.svg', 32999.00, 28999.00, 18, 4.60, 1),
(NEWID(), @Appliances, N'Convection Microwave Oven', N'28 litre convection oven for baking, grilling, and reheating.', N'/images/products/microwave.svg', 14999.00, 12999.00, 28, 4.50, 0),
(NEWID(), @Appliances, N'Split Air Conditioner', N'1.5 ton inverter AC with rapid cooling and energy-saving mode.', N'/images/products/ac.svg', 46999.00, 39999.00, 12, 4.60, 1),
(NEWID(), @Appliances, N'Mixer Grinder', N'750 watt mixer grinder with three stainless steel jars.', N'/images/products/mixer-grinder.svg', 5999.00, 4499.00, 42, 4.40, 0),
(NEWID(), @Appliances, N'Steel Electric Kettle', N'1.8 litre cordless electric kettle with automatic shutoff.', N'/images/products/kettle.svg', 2499.00, 1999.00, 65, 4.30, 0),
(NEWID(), @Appliances, N'Bagless Vacuum Cleaner', N'Compact cyclonic vacuum cleaner with powerful suction.', N'/images/products/vacuum-cleaner.svg', 7999.00, 6499.00, 35, 4.50, 0),
(NEWID(), @Appliances, N'RO Water Purifier', N'Seven-stage water purifier with UV and mineral boost.', N'/images/products/water-purifier.svg', 17999.00, 14999.00, 24, 4.70, 1),
(NEWID(), @Appliances, N'BLDC Ceiling Fan', N'Silent energy-saving ceiling fan with remote control.', N'/images/products/ceiling-fan.svg', 4999.00, 3999.00, 55, 4.60, 0),
(NEWID(), @Appliances, N'Induction Cooktop', N'2000 watt induction cooktop with digital touch controls.', N'/images/products/induction-cooktop.svg', 4999.00, 3999.00, 48, 4.40, 0),
(NEWID(), @Electronics, N'5G Android Smartphone', N'6.7 inch AMOLED smartphone with 256 GB storage and 50 MP camera.', N'/images/products/smartphone.svg', 35999.00, 29999.00, 32, 4.70, 1),
(NEWID(), @Electronics, N'Business Laptop', N'14 inch laptop with 16 GB RAM, 512 GB SSD, and Windows 11.', N'/images/products/laptop.svg', 74999.00, 67999.00, 16, 4.60, 1),
(NEWID(), @Electronics, N'Smart Watch', N'AMOLED fitness watch with GPS, heart-rate, and sleep tracking.', N'/images/products/smart-watch.svg', 12999.00, 9999.00, 52, 4.50, 1),
(NEWID(), @Electronics, N'Wireless Bluetooth Headphones', N'Over-ear wireless headphones with active noise cancellation.', N'/images/products/headphones.svg', 8999.00, 6999.00, 44, 4.60, 0),
(NEWID(), @Electronics, N'True Wireless Earbuds', N'Compact earbuds with low-latency mode and 30-hour battery case.', N'/images/products/earbuds.svg', 4999.00, 3499.00, 80, 4.50, 1),
(NEWID(), @Electronics, N'Portable Bluetooth Speaker', N'Water-resistant speaker with deep bass and 24-hour playback.', N'/images/products/speaker.svg', 5999.00, 4499.00, 58, 4.40, 0),
(NEWID(), @Electronics, N'Fast Charging Power Bank', N'20,000 mAh power bank with USB-C and multi-device charging.', N'/images/products/power-bank.svg', 2999.00, 2499.00, 95, 4.50, 0),
(NEWID(), @Electronics, N'Mechanical Keyboard', N'Tenkeyless mechanical keyboard with hot-swappable switches.', N'/images/products/keyboard.svg', 6999.00, 5499.00, 38, 4.70, 0),
(NEWID(), @Electronics, N'Ergonomic Computer Mouse', N'Wireless ergonomic mouse with adjustable sensitivity and silent clicks.', N'/images/products/mouse.svg', 2999.00, 1999.00, 70, 4.40, 0),
(NEWID(), @Electronics, N'10-inch Android Tablet', N'High-resolution tablet with 8 GB RAM and 128 GB storage.', N'/images/products/tablet.svg', 32999.00, 27999.00, 26, 4.60, 1),
(NEWID(), @Fashion, N'Men''s Cotton T-Shirt', N'Regular-fit breathable cotton T-shirt for everyday wear.', N'/images/products/mens-t-shirt.svg', 999.00, 699.00, 150, 4.40, 0),
(NEWID(), @Fashion, N'Men''s Casual Shirt', N'Slim-fit casual shirt in a soft and easy-care fabric.', N'/images/products/mens-shirt.svg', 1799.00, 1299.00, 125, 4.50, 1),
(NEWID(), @Fashion, N'Men''s Stretch Jeans', N'Dark wash stretch jeans with a modern tapered fit.', N'/images/products/mens-jeans.svg', 2999.00, 2299.00, 88, 4.60, 0),
(NEWID(), @Fashion, N'Women''s Printed Dress', N'Flowing printed dress with a flattering midi silhouette.', N'/images/products/womens-dress.svg', 3499.00, 2499.00, 76, 4.70, 1),
(NEWID(), @Fashion, N'Women''s Cotton Kurti', N'Soft cotton kurti with subtle embroidery and side pockets.', N'/images/products/womens-kurti.svg', 1999.00, 1499.00, 94, 4.60, 0),
(NEWID(), @Fashion, N'Women''s Casual Top', N'Lightweight casual top with an elegant relaxed fit.', N'/images/products/womens-top.svg', 1499.00, 999.00, 112, 4.50, 0),
(NEWID(), @Fashion, N'All-Season Jacket', N'Light insulated jacket with wind-resistant outer fabric.', N'/images/products/jacket.svg', 4499.00, 3499.00, 64, 4.60, 1),
(NEWID(), @Fashion, N'Sports Running Shoes', N'Cushioned running shoes with breathable mesh uppers.', N'/images/products/shoes.svg', 4999.00, 3999.00, 72, 4.70, 1),
(NEWID(), @Fashion, N'Sports Wear Set', N'Moisture-wicking top and shorts set for training sessions.', N'/images/products/sports-wear.svg', 2499.00, 1799.00, 84, 4.40, 0),
(NEWID(), @Fashion, N'Fashion Accessories Set', N'Stylish everyday accessories set for casual outfits.', N'/images/products/accessories.svg', 1999.00, 1299.00, 68, 4.30, 0)
) AS source(Id, CategoryId, Name, Description, ImageUrl, OriginalPrice, DiscountPrice, StockQuantity, Rating, IsFeatured)
ON target.Name = source.Name
WHEN MATCHED THEN UPDATE SET
    CategoryId = source.CategoryId,
    Description = source.Description,
    ImageUrl = source.ImageUrl,
    OriginalPrice = source.OriginalPrice,
    DiscountPrice = source.DiscountPrice,
    StockQuantity = source.StockQuantity,
    Rating = source.Rating,
    IsFeatured = source.IsFeatured,
    IsActive = 1,
    UpdatedAtUtc = SYSUTCDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Id, CategoryId, Name, Description, ImageUrl, OriginalPrice, DiscountPrice, StockQuantity, Rating, IsFeatured)
    VALUES (source.Id, source.CategoryId, source.Name, source.Description, source.ImageUrl, source.OriginalPrice, source.DiscountPrice, source.StockQuantity, source.Rating, source.IsFeatured);
GO
