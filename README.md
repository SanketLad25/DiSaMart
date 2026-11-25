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
Phase 6 is complete for service contracts: cart, payment, and shipping health endpoints are smoke-tested; database-backed writes require SQL Server runtime from Docker Compose or Kubernetes.
Phase 7 is complete: 12 multi-stage Dockerfiles are present for 11 ASP.NET Core services and the Nginx frontend. Live image builds require Docker Desktop.
Phase 8 is complete: Docker Compose configuration and SQL Server initialization are provided.
Phases 9-10 are complete: individual Kubernetes manifests and `all-in-one.yaml` are generated and pass client-side validation.
Container builds and live deployment still require Docker Desktop and a Kubernetes cluster.

## Run Locally with Docker Compose

Requirements: Docker Desktop with Linux containers enabled.

1. Copy `.env.example` to `.env` and replace `SQLSERVER_SA_PASSWORD` with a strong local password. Use the same password for subsequent runs so it can access the persisted SQL Server volume.
2. From the repository root, build and start the application:

   ```powershell
   docker compose --env-file .env -f docker/docker-compose.yml up --build -d
   ```

3. Check startup and logs:

   ```powershell
   docker compose --env-file .env -f docker/docker-compose.yml ps
   docker compose --env-file .env -f docker/docker-compose.yml logs -f frontendservice
   ```

4. Open `http://localhost:8080` (or the port set by `FRONTEND_PORT` in `.env`).
5. Stop the application while retaining database data:

   ```powershell
   docker compose --env-file .env -f docker/docker-compose.yml down
   ```

The database initializer creates the service databases, schemas, and seed records. Only the frontend port is published to the host; backend APIs and SQL Server stay on the Compose network.

## Kubernetes Deployment

Build the images first with Docker Desktop:

```powershell
.\scripts\build-images.ps1
```

For a local cluster, load the images into its image store (for example, `kind load docker-image disamart/frontend:1.0.0` and the matching service images). The manifests use `IfNotPresent`, so the cluster must be able to access these image tags.

Before deploying, replace `REPLACE_ME_Str0ng!` in the Kubernetes Secret manifest with a strong password. Use the same value wherever you deploy the Secret.

Apply the complete stack:

```powershell
kubectl apply -f kubernetes/all-in-one.yaml
kubectl wait --for=condition=complete job/disamart-db-init --timeout=10m -n disamart
kubectl get pods,services -n disamart
```

The frontend is exposed through NodePort `30080`; open `http://localhost:30080` when your local Kubernetes cluster exposes node ports on localhost. Otherwise, use your cluster's node address.

To deploy the individual manifests instead:

```powershell
kubectl apply -R -f kubernetes/individual
kubectl wait --for=condition=complete job/disamart-db-init --timeout=10m -n disamart
```

Remove the combined deployment with:

```powershell
kubectl delete -f kubernetes/all-in-one.yaml
```

See [deployment guide](documentation/deployment-guide.md) for troubleshooting and operations commands.

## Phase 1 Documents

- [Architecture](documentation/architecture.md)
- [Database design](documentation/database-design.md)
- [API contracts](documentation/api-contracts.md)
- [Deployment guide](documentation/deployment-guide.md)
# DiSaMart
