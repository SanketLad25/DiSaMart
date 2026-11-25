# Deployment Guide

This guide covers the current local Docker Compose and Kubernetes deployment files.

## Local Docker Compose

From the repository root, copy `.env.example` to `.env`, replace the SQL Server password, then run:

```powershell
docker compose --env-file .env -f docker/docker-compose.yml up --build -d
docker compose --env-file .env -f docker/docker-compose.yml ps
docker compose --env-file .env -f docker/docker-compose.yml logs -f frontendservice
```

Open `http://localhost:8080`. Only the frontend is published to the host. Stop without deleting SQL data:

```powershell
docker compose --env-file .env -f docker/docker-compose.yml down
```

Database initialization is run by a one-shot container and is safe to rerun. SQL Server data is stored in the `sqlserver-data` named volume.

## Kubernetes Deployment

Build images using `.\scripts\build-images.ps1`, load them into the selected cluster, and replace the placeholder password in the Kubernetes Secret. The frontend image must be available as `disamart/frontend:1.0.0`; backend images use `disamart/<service>:1.0.0`; the database initializer uses `disamart/database-init:1.0.0`.

Combined deployment:

```powershell
kubectl apply -f kubernetes/all-in-one.yaml
kubectl wait --for=condition=complete job/disamart-db-init --timeout=10m -n disamart
kubectl get pods -n disamart
```

Individual deployment:

```powershell
kubectl apply -R -f kubernetes/individual
kubectl wait --for=condition=complete job/disamart-db-init --timeout=10m -n disamart
```

The frontend is the only externally exposed Kubernetes service (NodePort `30080`). Other APIs and SQL Server use ClusterIP.

## Service DNS Names

Backend services will use fixed Docker Compose and Kubernetes service names:

- `adservice`
- `cartservice`
- `checkoutservice`
- `currencyservice`
- `emailservice`
- `customizationservice`
- `loadgenerator`
- `paymentservice`
- `productcatalogservice`
- `recommendationservice`
- `shippingservice`
- `frontendservice`

Compose ports may differ during development, but container ports use port `8080`. The frontend container uses port `80`.

## Kubernetes Resource Policy

The initial learning-cluster manifests use small resources:

- Stateless API: 100m-250m CPU, 128Mi-256Mi memory
- Frontend: 50m-150m CPU, 64Mi-128Mi memory
- LoadGenerator: 25m-100m CPU, 64Mi-128Mi memory
- SQL Server: 500m-1000m CPU, 1Gi-2Gi memory

Important services run with at least two replicas where supported. SQL Server uses a persistent volume and one replica.

## Health Endpoints

Every API exposes:

- `GET /health/live`
- `GET /health/ready`

The Docker health check targets `/health/live`.

## Environment Conventions

All HTTP services accept `ASPNETCORE_HTTP_PORTS=8080` and `ASPNETCORE_ENVIRONMENT=Production`.

SQL Server connection strings use:

```text
Server=sqlserver,1433;Database=<DatabaseName>;User Id=sa;Password=<Password>;TrustServerCertificate=True
```

Passwords come from environment variables or Kubernetes Secrets.

## Operations Commands

```powershell
kubectl get pods -n disamart
kubectl get services -n disamart
kubectl get deployments -n disamart
kubectl describe pod <pod-name> -n disamart
kubectl logs <pod-name> -n disamart
kubectl scale deployment cartservice --replicas=3 -n disamart
```
