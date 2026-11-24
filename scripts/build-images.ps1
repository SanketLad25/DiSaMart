$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$services = @(
    'AdService','CartService','CheckoutService','CurrencyService','EmailService',
    'CustomizationService','LoadGenerator','PaymentService','ProductCatalogService',
    'RecommendationService','ShippingService'
)

foreach ($service in $services) {
    docker build -t "disamart/${service.ToLowerInvariant()}:1.0.0" "$root/services/$service"
}

docker build -t disamart/frontend:1.0.0 "$root/frontend"
