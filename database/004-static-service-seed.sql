USE CurrencyDB;
GO

MERGE dbo.Currencies AS target
USING (VALUES
    (NEWID(), N'INR', N'Indian Rupee', N'₹', 2, 1, 1),
    (NEWID(), N'USD', N'US Dollar', N'$', 2, 0, 1),
    (NEWID(), N'EUR', N'Euro', N'€', 2, 0, 1),
    (NEWID(), N'GBP', N'British Pound', N'£', 2, 0, 1),
    (NEWID(), N'AED', N'UAE Dirham', N'DH', 2, 0, 1)
) AS source(Id, Code, Name, Symbol, DecimalDigits, IsBase, IsActive)
ON target.Code = source.Code
WHEN MATCHED THEN UPDATE SET Name=source.Name, Symbol=source.Symbol, DecimalDigits=source.DecimalDigits,
                            IsBase=source.IsBase, IsActive=source.IsActive
WHEN NOT MATCHED THEN INSERT (Id, Code, Name, Symbol, DecimalDigits, IsBase, IsActive)
VALUES (source.Id, source.Code, source.Name, source.Symbol, source.DecimalDigits, source.IsBase, source.IsActive);

MERGE dbo.ExchangeRates AS target
USING (VALUES
    (NEWID(), N'INR', N'INR', 1.00000000),
    (NEWID(), N'INR', N'USD', 0.01200000),
    (NEWID(), N'INR', N'EUR', 0.01100000),
    (NEWID(), N'INR', N'GBP', 0.00940000),
    (NEWID(), N'INR', N'AED', 0.04400000)
) AS source(Id, BaseCurrencyCode, TargetCurrencyCode, Rate)
ON target.BaseCurrencyCode = source.BaseCurrencyCode AND target.TargetCurrencyCode = source.TargetCurrencyCode
WHEN MATCHED THEN UPDATE SET Rate=source.Rate, IsActive=1, EffectiveAtUtc=SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (Id, BaseCurrencyCode, TargetCurrencyCode, Rate)
VALUES (source.Id, source.BaseCurrencyCode, source.TargetCurrencyCode, source.Rate);
GO

USE EmailDB;
GO
MERGE dbo.EmailTemplates AS target
USING (VALUES
    (NEWID(), N'registration-confirmation', N'Welcome to DiSaMart', N'<h2>Welcome to DiSaMart</h2><p>Your account is ready.</p>', 1),
    (NEWID(), N'order-confirmation', N'DiSaMart order confirmation', N'<h2>Thank you for your order</h2><p>Order {{orderId}} has been confirmed.</p>', 1),
    (NEWID(), N'payment-confirmation', N'DiSaMart payment update', N'<p>Payment {{paymentId}} has been {{status}}.</p>', 1),
    (NEWID(), N'shipping-update', N'DiSaMart shipment update', N'<p>Shipment {{trackingNumber}} is now {{status}}.</p>', 1)
) AS source(Id, TemplateKey, SubjectTemplate, BodyTemplate, IsActive)
ON target.TemplateKey = source.TemplateKey
WHEN MATCHED THEN UPDATE SET SubjectTemplate=source.SubjectTemplate, BodyTemplate=source.BodyTemplate, IsActive=source.IsActive
WHEN NOT MATCHED THEN INSERT (Id, TemplateKey, SubjectTemplate, BodyTemplate, IsActive)
VALUES (source.Id, source.TemplateKey, source.SubjectTemplate, source.BodyTemplate, source.IsActive);
GO

USE AdDB;
GO
MERGE dbo.Advertisements AS target
USING (VALUES
    (NEWID(), N'Big Savings Festival', N'Discover discounts across electronics and fashion.', N'/images/ads/savings-festival.svg', N'/categories/electronics-gadgets', N'hero', 100, SYSUTCDATETIME(), NULL, 1),
    (NEWID(), N'Daily Grocery Deals', N'Fresh deals on everyday grocery essentials.', N'/images/ads/grocery-deals.svg', N'/categories/grocery', N'banner', 90, SYSUTCDATETIME(), NULL, 1),
    (NEWID(), N'Appliance Upgrade', N'Smart appliances for a comfortable home.', N'/images/ads/appliance-upgrade.svg', N'/categories/home-appliances', N'banner', 80, SYSUTCDATETIME(), NULL, 1)
) AS source(Id, Title, Description, ImageUrl, TargetUrl, Placement, Priority, StartAtUtc, EndAtUtc, IsActive)
ON target.Title = source.Title
WHEN MATCHED THEN UPDATE SET Description=source.Description, ImageUrl=source.ImageUrl, TargetUrl=source.TargetUrl,
                            Placement=source.Placement, Priority=source.Priority, IsActive=source.IsActive
WHEN NOT MATCHED THEN INSERT (Id, Title, Description, ImageUrl, TargetUrl, Placement, Priority, StartAtUtc, EndAtUtc, IsActive)
VALUES (source.Id, source.Title, source.Description, source.ImageUrl, source.TargetUrl, source.Placement,
        source.Priority, source.StartAtUtc, source.EndAtUtc, source.IsActive);

MERGE dbo.Campaigns AS target
USING (VALUES
    (NEWID(), N'Electronics Sale', 15.00, SYSUTCDATETIME(), NULL, 1),
    (NEWID(), N'Fashion Week', 20.00, SYSUTCDATETIME(), NULL, 1)
) AS source(Id, Name, DiscountPercentage, StartAtUtc, EndAtUtc, IsActive)
ON target.Name = source.Name
WHEN MATCHED THEN UPDATE SET DiscountPercentage=source.DiscountPercentage, StartAtUtc=source.StartAtUtc,
                            EndAtUtc=source.EndAtUtc, IsActive=source.IsActive
WHEN NOT MATCHED THEN INSERT (Id, Name, DiscountPercentage, StartAtUtc, EndAtUtc, IsActive)
VALUES (source.Id, source.Name, source.DiscountPercentage, source.StartAtUtc, source.EndAtUtc, source.IsActive);
GO

USE CustomizationDB;
GO
MERGE dbo.ApplicationSettings AS target
USING (VALUES
    (NEWID(), N'applicationName', N'DiSaMart', N'string', 1, 1),
    (NEWID(), N'defaultTheme', N'light', N'string', 1, 1),
    (NEWID(), N'defaultCurrency', N'INR', N'string', 1, 1),
    (NEWID(), N'defaultLanguage', N'en-IN', N'string', 1, 1),
    (NEWID(), N'itemsPerPage', N'12', N'integer', 1, 1)
) AS source(Id, [Key], [Value], DataType, IsPublic, IsActive)
ON target.[Key] = source.[Key]
WHEN MATCHED THEN UPDATE SET [Value]=source.[Value], DataType=source.DataType, IsPublic=source.IsPublic, IsActive=source.IsActive
WHEN NOT MATCHED THEN INSERT (Id, [Key], [Value], DataType, IsPublic, IsActive)
VALUES (source.Id, source.[Key], source.[Value], source.DataType, source.IsPublic, source.IsActive);
GO
