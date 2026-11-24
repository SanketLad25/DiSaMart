# DiSaMart

DiSaMart is a beginner-friendly, enterprise-style online shopping platform built as independent ASP.NET Core microservices with a React TypeScript frontend.

## Technology

- ASP.NET Core Web API 9
- Entity Framework Core
- Microsoft SQL Server
- React and TypeScript
- Docker and Docker Compose
- Kubernetes

## Repository Structure

```text
frontend/
database/
services/
  AdService/
  CartService/
  CheckoutService/
  CurrencyService/
  EmailService/
  CustomizationService/
  LoadGenerator/
  PaymentService/
  ProductCatalogService/
  RecommendationService/
  ShippingService/
docker/
kubernetes/
  individual/
  all-in-one.yaml
documentation/
  architecture.md
  database-design.md
  api-contracts.md
  deployment-guide.md
```

## Current Development Phase

Phase 1 is complete: clean structure, service boundaries, architecture, database ownership, and REST API contracts are defined.
Phase 2 is prepared: separate SQL databases, DDL scripts, static seed data, and four-category/40-product catalog data are defined.
Phase 3 is complete: all 11 backend ASP.NET Core microservices compile successfully in `DiSaMart.slnx`, expose health endpoints, and include service-specific APIs.
Phase 4 is complete: the React + TypeScript frontend builds successfully and includes responsive branded shopping, categories, search, product details, cart, wishlist, checkout, profile, authentication, and order pages.
Phase 5 is complete: an Axios API adapter is configured for cart and checkout integration, with typed requests, timeout handling, and service-error feedback.
Phase 6 is complete for service contracts: cart, payment, shipping health endpoints and mock-payment behavior are validated; database-backed writes require SQL Server runtime from Docker Compose or Kubernetes.
Phase 7 is complete: 12 multi-stage Dockerfiles are present for 11 ASP.NET Core services and the Nginx frontend. Live image builds require Docker Desktop.

Implementation proceeds phase by phase. Later phases add runnable source code, containers, Compose configuration, Kubernetes manifests, and deployment testing.

## Phase 1 Documents

- [Architecture](documentation/architecture.md)
- [Database design](documentation/database-design.md)
- [API contracts](documentation/api-contracts.md)
- [Deployment guide](documentation/deployment-guide.md)
# DiSaMart
