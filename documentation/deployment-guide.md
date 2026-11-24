# Deployment Guide

This guide defines the deployment conventions that each later implementation phase must follow.

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

## Expected Commands

```powershell
# Docker Compose
docker compose -f docker/docker-compose.yml up --build
docker compose -f docker/docker-compose.yml ps
docker compose -f docker/docker-compose.yml logs -f frontendservice
docker compose -f docker/docker-compose.yml down

# Individual Kubernetes manifests
kubectl apply -f kubernetes/individual/namespace.yaml
kubectl apply -f kubernetes/individual

# Combined Kubernetes manifest
kubectl apply -f kubernetes/all-in-one.yaml
kubectl delete -f kubernetes/all-in-one.yaml

# Kubernetes verification
kubectl get pods -n disamart
kubectl get services -n disamart
kubectl get deployments -n disamart
kubectl describe pod <pod-name> -n disamart
kubectl logs <pod-name> -n disamart
kubectl scale deployment cartservice --replicas=3 -n disamart
```
