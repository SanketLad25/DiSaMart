var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "recommendationservice" }));
app.MapGet("/health/ready", () => Results.Ok(new { status = "ready", service = "recommendationservice" }));
app.MapGet("/api/recommendations/trending", () =>
    Results.Ok(TrendingProducts()));
app.MapGet("/api/recommendations/{productId:guid}/related", (Guid productId) =>
    Results.Ok(new[]
    {
        new ProductRecommendation(Guid.NewGuid(), productId, "Related", 92m),
        new ProductRecommendation(Guid.NewGuid(), productId, "FrequentlyBought", 88m)
    }));
app.MapGet("/api/recommendations/user/{userId:guid}", (Guid userId) =>
    Results.Ok(TrendingProducts()));

app.MapControllers();
app.Run();

static object[] TrendingProducts() => new object[]
{
    new { name = "True Wireless Earbuds", category = "Electronics & Gadgets", score = 98m },
    new { name = "Smart Watch", category = "Electronics & Gadgets", score = 96m },
    new { name = "Sports Running Shoes", category = "Fashion & Clothing", score = 94m },
    new { name = "RO Water Purifier", category = "Home Appliances", score = 92m }
};

public sealed record ProductRecommendation(Guid RecommendedProductId, Guid SourceProductId, string RecommendationType, decimal Score);
