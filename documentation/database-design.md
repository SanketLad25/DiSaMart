# Database Design

Microsoft SQL Server is used as the database engine. Each microservice owns one database. Database names are logical service boundaries and must not be accessed by another service.

## Database Ownership

| Database | Tables |
|---|---|
| ProductCatalogDB | Categories, Products, ProductImages |
| CartDB | Carts, CartItems |
| CheckoutDB | Orders, OrderItems, OrderStatusHistory |
| PaymentDB | Payments, PaymentTransactions |
| ShippingDB | Shipments, ShippingAddresses |
| EmailDB | EmailTemplates, EmailLogs |
| RecommendationDB | ProductRecommendations |
| AdDB | Advertisements, Campaigns |
| CurrencyDB | Currencies, ExchangeRates |
| CustomizationDB | ApplicationSettings, UserPreferences |

## Shared ID Policy

Services exchange IDs as strings or GUIDs. Cross-service foreign keys are intentionally avoided. If a foreign reference is stored, it is descriptive and not enforced by SQL Server.

## Common Audit Fields

Mutable records use `CreatedAtUtc`, `UpdatedAtUtc`, and `IsActive` where appropriate. Monetary values use `decimal(18,2)`.

## ProductCatalogDB

```sql
Categories (
  Id uniqueidentifier PK,
  Name nvarchar(100) NOT NULL UNIQUE,
  Slug nvarchar(100) NOT NULL UNIQUE,
  ImageUrl nvarchar(500),
  IsActive bit,
  CreatedAtUtc datetime2,
  UpdatedAtUtc datetime2
)

Products (
  Id uniqueidentifier PK,
  CategoryId uniqueidentifier NOT NULL,
  Name nvarchar(200) NOT NULL,
  Description nvarchar(2000) NOT NULL,
  ImageUrl nvarchar(500),
  OriginalPrice decimal(18,2),
  DiscountPrice decimal(18,2),
  StockQuantity int,
  Rating decimal(3,2),
  IsFeatured bit,
  IsActive bit,
  CreatedAtUtc datetime2,
  UpdatedAtUtc datetime2
)

ProductImages (
  Id uniqueidentifier PK,
  ProductId uniqueidentifier NOT NULL,
  ImageUrl nvarchar(500),
  SortOrder int
)
```

Add indexes for `Products.CategoryId`, `Products.IsFeatured`, `Products.IsActive`, and `Products.Name`.

## CartDB

```text
Carts: Id, UserId, CurrencyCode, CreatedAtUtc, UpdatedAtUtc
CartItems: Id, CartId, ProductId, ProductName, UnitPrice, Quantity, UpdatedAtUtc
```

The cart stores a product snapshot and quantity. The maximum quantity is constrained by product stock validation during checkout.

## CheckoutDB

```text
Orders: Id, UserId, CartId, Subtotal, ShippingCharge, Tax, GrandTotal,
        CurrencyCode, PaymentId, ShipmentId, Status, CreatedAtUtc
OrderItems: Id, OrderId, ProductId, ProductName, UnitPrice, Quantity, LineTotal
OrderStatusHistory: Id, OrderId, Status, Comment, CreatedAtUtc
```

## PaymentDB

```text
Payments: Id, OrderId, UserId, Amount, CurrencyCode, Method, Status, FailureReason,
          CreatedAtUtc, UpdatedAtUtc
PaymentTransactions: Id, PaymentId, ProviderReference, Status, RequestPayload,
                     ResponsePayload, CreatedAtUtc
```

## ShippingDB

```text
ShippingAddresses: Id, UserId, FullName, Phone, AddressLine1, AddressLine2,
                   City, State, PostalCode, Country
Shipments: Id, OrderId, AddressId, Carrier, TrackingNumber, Status,
           ShippingCharge, EstimatedDeliveryDateUtc, CreatedAtUtc, UpdatedAtUtc
```

## EmailDB

```text
EmailTemplates: Id, TemplateKey, SubjectTemplate, BodyTemplate, IsActive
EmailLogs: Id, Recipient, Subject, Body, TemplateKey, Status, Error,
           SentAtUtc, CreatedAtUtc
```

## RecommendationDB

```text
ProductRecommendations: Id, SourceProductId, RecommendedProductId,
                         RecommendationType, Score, IsActive
```

## AdDB

```text
Advertisements: Id, Title, Description, ImageUrl, TargetUrl, Placement,
                Priority, StartAtUtc, EndAtUtc, IsActive
Campaigns: Id, Name, DiscountPercentage, StartAtUtc, EndAtUtc, IsActive
```

## CurrencyDB

```text
Currencies: Id, Code, Name, Symbol, DecimalDigits, IsBase, IsActive
ExchangeRates: Id, BaseCurrencyCode, TargetCurrencyCode, Rate,
               EffectiveAtUtc, IsActive
```

## CustomizationDB

```text
ApplicationSettings: Id, Key, Value, DataType, IsPublic, IsActive
UserPreferences: Id, UserId, Theme, CurrencyCode, Language, UpdatedAtUtc
```
