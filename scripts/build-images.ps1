$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$services = @(
    'AdService','CartService','CheckoutService','CurrencyService','EmailService',
    'CustomizationService','LoadGenerator','PaymentService','ProductCatalogService',
    'RecommendationService','ShippingService'
)

foreach ($service in $services) {
    $imageName = $service.ToLowerInvariant()
    docker build -t "disamart/$imageName:1.0.0" "$root/services/$service"
}

docker build -t disamart/frontend:1.0.0 "$root/frontend"
docker build -t disamart/database-init:1.0.0 -f "$root/docker/database-init.Dockerfile" "$root"
