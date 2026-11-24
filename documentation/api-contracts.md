# REST API Contracts

All APIs use JSON, UTC ISO-8601 timestamps, and `application/json`. IDs are GUID strings. Successful collection responses use an HTTP 200 response, creates use 201, and deletes use 204.

## Standard Error

```json
{
  "status": 400,
  "error": "ValidationError",
  "message": "One or more fields are invalid.",
  "traceId": "guid",
  "errors": {
    "Quantity": ["Quantity must be at least 1."]
  }
}
```

## ProductCatalogService

| Method | Route | Purpose |
|---|---|---|
| GET | `/api/categories` | List active categories |
| GET | `/api/products` | Search, filter, sort, and paginate |
| GET | `/api/products/{id}` | Get product detail |
| GET | `/api/products/featured` | Get featured products |
| POST | `/api/products/{id}/validate` | Validate stock and price |

Example product query:

```text
GET /api/products?search=phone&categoryId=<guid>&sort=priceAsc&page=1&pageSize=12
```

## CartService

| Method | Route | Purpose |
|---|---|---|
| GET | `/api/carts/{userId}` | Get or create a user cart |
| POST | `/api/carts/{userId}/items` | Add or merge an item |
| PUT | `/api/carts/{userId}/items/{itemId}` | Update quantity |
| DELETE | `/api/carts/{userId}/items/{itemId}` | Remove item |
| DELETE | `/api/carts/{userId}` | Clear cart |

Add-item body:

```json
{
  "productId": "guid",
  "productName": "Wireless Earbuds",
  "unitPrice": 2499.00,
  "quantity": 1
}
```

## CheckoutService

| Method | Route | Purpose |
|---|---|---|
| POST | `/api/checkout/validate` | Validate cart and address |
| POST | `/api/checkout/orders` | Create order |
| GET | `/api/orders/{orderId}` | Get order detail |
| GET | `/api/orders/user/{userId}` | Get user order history |

Create order body:

```json
{
  "userId": "guid",
  "cartId": "guid",
  "currencyCode": "INR",
  "paymentMethod": "COD",
  "shippingAddress": {
    "fullName": "Customer Name",
    "phone": "9999999999",
    "addressLine1": "Example Street",
    "city": "Pune",
    "state": "Maharashtra",
    "postalCode": "411001",
    "country": "India"
  }
}
```

## PaymentService

| Method | Route | Purpose |
|---|---|---|
| POST | `/api/payments` | Create a mock payment |
| GET | `/api/payments/{id}` | Get payment status |

Methods allowed initially: `COD` and `MOCK_CARD`.

## ShippingService

| Method | Route | Purpose |
|---|---|---|
| POST | `/api/shipping/addresses` | Save delivery address |
| POST | `/api/shipping/shipments` | Create simulated shipment |
| GET | `/api/shipping/shipments/{id}` | Get shipment status |

## EmailService

| Method | Route | Purpose |
|---|---|---|
| POST | `/api/emails/registration` | Send registration confirmation |
| POST | `/api/emails/order-confirmation` | Send order confirmation |
| POST | `/api/emails/payment` | Send payment notification |
| POST | `/api/emails/shipping` | Send shipping notification |
| GET | `/api/emails/logs` | Get development email logs |

## RecommendationService

| Method | Route | Purpose |
|---|---|---|
| GET | `/api/recommendations/trending` | Trending products |
| GET | `/api/recommendations/{productId}/related` | Related products |
| GET | `/api/recommendations/user/{userId}` | Personalized static recommendations |

## AdService

| Method | Route | Purpose |
|---|---|---|
| GET | `/api/advertisements` | Active advertisements |
| GET | `/api/advertisements/placement/{placement}` | Ads for a placement |
| GET | `/api/campaigns/active` | Active campaigns |

## CurrencyService

| Method | Route | Purpose |
|---|---|---|
| GET | `/api/currencies` | Supported currencies |
| POST | `/api/currencies/convert` | Convert an amount |

Example conversion body:

```json
{
  "amount": 2499.00,
  "fromCurrency": "INR",
  "toCurrency": "USD"
}
```

## CustomizationService

| Method | Route | Purpose |
|---|---|---|
| GET | `/api/settings` | Public application settings |
| GET | `/api/preferences/{userId}` | User preferences |
| PUT | `/api/preferences/{userId}` | Update user preferences |
