$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$base = Join-Path $root 'kubernetes\individual'
$yamlEncoding = New-Object System.Text.UTF8Encoding($false)

function Write-Yaml([string]$Path, [string]$Content) {
    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    [System.IO.File]::WriteAllText($Path, $Content.Trim() + "`n", $yamlEncoding)
}

$common = @'
apiVersion: v1
kind: Namespace
metadata:
  name: disamart
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: disamart-config
  namespace: disamart
data:
  ASPNETCORE_ENVIRONMENT: Production
  ASPNETCORE_HTTP_PORTS: "8080"
  Services__Cart: http://cartservice:8080
  Services__Payment: http://paymentservice:8080
  Services__Shipping: http://shippingservice:8080
  Services__Email: http://emailservice:8080
  TARGET_CATALOG_URL: http://productcatalogservice:8080
---
apiVersion: v1
kind: Secret
metadata:
  name: disamart-secrets
  namespace: disamart
type: Opaque
stringData:
  sql-sa-password: REPLACE_ME_Str0ng!
'@

$database = @'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sqlserver-data
  namespace: disamart
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Service
metadata:
  name: sqlserver
  namespace: disamart
spec:
  type: ClusterIP
  selector:
    app: sqlserver
  ports:
    - name: sql
      port: 1433
      targetPort: 1433
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sqlserver
  namespace: disamart
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sqlserver
  template:
    metadata:
      labels:
        app: sqlserver
    spec:
      containers:
        - name: sqlserver
          image: mcr.microsoft.com/mssql/server:2022-latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: sql
              containerPort: 1433
          env:
            - name: ACCEPT_EULA
              value: "Y"
            - name: MSSQL_PID
              value: Developer
            - name: MSSQL_MEMORY_LIMIT_MB
              value: "1800"
            - name: MSSQL_SA_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: disamart-secrets
                  key: sql-sa-password
          resources:
            requests:
              cpu: 300m
              memory: 1Gi
            limits:
              cpu: 750m
              memory: 2Gi
          startupProbe:
            exec:
              command:
                - /bin/bash
                - -c
                - /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b -Q "SELECT 1"
            periodSeconds: 10
            failureThreshold: 30
          readinessProbe:
            exec:
              command:
                - /bin/bash
                - -c
                - /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b -Q "SELECT 1"
            periodSeconds: 10
            timeoutSeconds: 5
          livenessProbe:
            exec:
              command:
                - /bin/bash
                - -c
                - /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b -Q "SELECT 1"
            periodSeconds: 20
            timeoutSeconds: 5
          volumeMounts:
            - name: sqlserver-data
              mountPath: /var/opt/mssql
      volumes:
        - name: sqlserver-data
          persistentVolumeClaim:
            claimName: sqlserver-data
---
apiVersion: batch/v1
kind: Job
metadata:
  name: disamart-db-init
  namespace: disamart
spec:
  backoffLimit: 5
  template:
    metadata:
      labels:
        app: disamart-db-init
    spec:
      restartPolicy: OnFailure
      containers:
        - name: db-init
          image: disamart/database-init:1.0.0
          imagePullPolicy: IfNotPresent
          env:
            - name: DB_HOST
              value: sqlserver
            - name: SQLSERVER_SA_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: disamart-secrets
                  key: sql-sa-password
          resources:
            requests:
              cpu: 25m
              memory: 64Mi
            limits:
              cpu: 150m
              memory: 256Mi
'@

$services = @(
    @{ Name='adservice'; Project='AdService'; Port=8080; Replicas=1; Db=''; DbName=''; Extra=''; Frontend=$false },
    @{ Name='cartservice'; Project='CartService'; Port=8080; Replicas=2; Db='CartDb'; DbName='CartDB'; Extra=''; Frontend=$false },
    @{ Name='checkoutservice'; Project='CheckoutService'; Port=8080; Replicas=2; Db='CheckoutDb'; DbName='CheckoutDB'; Extra=''; Frontend=$false },
    @{ Name='currencyservice'; Project='CurrencyService'; Port=8080; Replicas=1; Db=''; DbName=''; Extra=''; Frontend=$false },
    @{ Name='emailservice'; Project='EmailService'; Port=8080; Replicas=1; Db=''; DbName=''; Extra=''; Frontend=$false },
    @{ Name='customizationservice'; Project='CustomizationService'; Port=8080; Replicas=1; Db=''; DbName=''; Extra=''; Frontend=$false },
    @{ Name='loadgenerator'; Project='LoadGenerator'; Port=8080; Replicas=1; Db=''; DbName=''; Extra=''; Frontend=$false; Headless=$true },
    @{ Name='paymentservice'; Project='PaymentService'; Port=8080; Replicas=1; Db='PaymentDb'; DbName='PaymentDB'; Extra=''; Frontend=$false },
    @{ Name='productcatalogservice'; Project='ProductCatalogService'; Port=8080; Replicas=2; Db='ProductCatalogDb'; DbName='ProductCatalogDB'; Extra=''; Frontend=$false },
    @{ Name='recommendationservice'; Project='RecommendationService'; Port=8080; Replicas=1; Db=''; DbName=''; Extra=''; Frontend=$false },
    @{ Name='shippingservice'; Project='ShippingService'; Port=8080; Replicas=1; Db='ShippingDb'; DbName='ShippingDB'; Extra=''; Frontend=$false },
    @{ Name='frontendservice'; Project='frontend'; Port=80; Replicas=1; Db=''; DbName=''; Extra=''; Frontend=$true }
)

function New-ServiceManifest($Service) {
    $isFrontend = [bool]$Service.Frontend
    $headless = $Service.ContainsKey('Headless') -and [bool]$Service.Headless
    $port = [int]$Service.Port
    $replicas = [int]$Service.Replicas
    $image = if ($Service.Name -eq 'frontendservice') { 'disamart/frontend:1.0.0' } else { "disamart/$($Service.Name):1.0.0" }
    $probePath = if ($isFrontend) { '/' } else { '/health/live' }
    $readyPath = if ($isFrontend) { '/' } else { '/health/ready' }

    $content = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $($Service.Name)
  namespace: disamart
spec:
  replicas: $replicas
  selector:
    matchLabels:
      app: $($Service.Name)
  template:
    metadata:
      labels:
        app: $($Service.Name)
    spec:
      containers:
        - name: $($Service.Name)
          image: $image
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: $port
          envFrom:
            - configMapRef:
                name: disamart-config
"@
    $content += "`n"
    if (-not $isFrontend -and $Service.DbName) {
        $connectionName = "ConnectionStrings__$($Service.Db)"
        $content += @"
          env:
            - name: SQLSERVER_SA_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: disamart-secrets
                  key: sql-sa-password
            - name: $connectionName
              value: "Server=sqlserver,1433;Database=$($Service.DbName);User Id=sa;Password=`$(SQLSERVER_SA_PASSWORD);TrustServerCertificate=True"
"@
        $content += "`n"
    }
    if ($isFrontend) {
        $content += @"
          resources:
            requests:
              cpu: 25m
              memory: 64Mi
            limits:
              cpu: 150m
              memory: 128Mi
          livenessProbe:
            httpGet:
              path: $probePath
              port: $port
            initialDelaySeconds: 5
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: $readyPath
              port: $port
            initialDelaySeconds: 3
            periodSeconds: 10
"@
        $content += "`n"
    } elseif ($headless) {
        $content += @"
          resources:
            requests:
              cpu: 25m
              memory: 96Mi
            limits:
              cpu: 200m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: $probePath
              port: $port
            initialDelaySeconds: 10
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: $readyPath
              port: $port
            initialDelaySeconds: 5
            periodSeconds: 10
"@
        $content += "`n"
    } else {
        $content += @"
          resources:
            requests:
              cpu: 25m
              memory: 128Mi
            limits:
              cpu: 200m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: $probePath
              port: $port
            initialDelaySeconds: 10
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: $readyPath
              port: $port
            initialDelaySeconds: 5
            periodSeconds: 10
"@
        $content += "`n"
    }

    if (-not $headless) {
        $serviceType = if ($isFrontend) { 'NodePort' } else { 'ClusterIP' }
        $nodePort = if ($isFrontend) { "      nodePort: 30080`n" } else { '' }
        $content += @"
---
apiVersion: v1
kind: Service
metadata:
  name: $($Service.Name)
  namespace: disamart
spec:
  type: $serviceType
  selector:
    app: $($Service.Name)
  ports:
    - name: http
      port: $port
      targetPort: $port
"@
        $content += "`n"
        $content += $nodePort
    }
    return $content.Trim()
}

Write-Yaml (Join-Path $base 'namespace.yaml') @'
apiVersion: v1
kind: Namespace
metadata:
  name: disamart
'@
Write-Yaml (Join-Path $base 'configmap.yaml') @'
apiVersion: v1
kind: ConfigMap
metadata:
  name: disamart-config
  namespace: disamart
data:
  ASPNETCORE_ENVIRONMENT: Production
  ASPNETCORE_HTTP_PORTS: "8080"
  Services__Cart: http://cartservice:8080
  Services__Payment: http://paymentservice:8080
  Services__Shipping: http://shippingservice:8080
  Services__Email: http://emailservice:8080
  TARGET_CATALOG_URL: http://productcatalogservice:8080
'@
Write-Yaml (Join-Path $base 'secrets.yaml') @'
apiVersion: v1
kind: Secret
metadata:
  name: disamart-secrets
  namespace: disamart
type: Opaque
stringData:
  sql-sa-password: REPLACE_ME_Str0ng!
'@

$databasePath = Join-Path $base 'infrastructure\sqlserver.yaml'
Write-Yaml $databasePath $database
foreach ($service in $services) {
    $manifest = New-ServiceManifest $service
    $parts = @($manifest -split '(?m)^---\s*$')
    Write-Yaml (Join-Path $base "$($service.Name)\deployment.yaml") $parts[0]
    if ($parts.Count -gt 1) {
        Write-Yaml (Join-Path $base "$($service.Name)\service.yaml") $parts[1]
    }
}

$all = @($common, $database)
foreach ($service in $services) {
    $all += New-ServiceManifest $service
}
Write-Yaml (Join-Path $root 'kubernetes\all-in-one.yaml') ($all -join "`n---`n")
