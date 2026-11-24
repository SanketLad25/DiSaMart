var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

var advertisements = new[]
{
    new Advertisement(Guid.NewGuid(), "Big Savings Festival", "Discounts across electronics and fashion.", "/images/ads/savings-festival.svg", "/categories/electronics-gadgets", "hero", 100, true),
    new Advertisement(Guid.NewGuid(), "Daily Grocery Deals", "Fresh deals on everyday grocery essentials.", "/images/ads/grocery-deals.svg", "/categories/grocery", "banner", 90, true),
    new Advertisement(Guid.NewGuid(), "Appliance Upgrade", "Smart appliances for a comfortable home.", "/images/ads/appliance-upgrade.svg", "/categories/home-appliances", "banner", 80, true)
};

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "adservice" }));
app.MapGet("/health/ready", () => Results.Ok(new { status = "ready", service = "adservice" }));
app.MapGet("/api/advertisements", () => Results.Ok(advertisements.Where(x => x.IsActive)));
app.MapGet("/api/advertisements/placement/{placement}", (string placement) =>
    Results.Ok(advertisements.Where(x => x.IsActive && x.Placement.Equals(placement, StringComparison.OrdinalIgnoreCase))));
app.MapGet("/api/campaigns/active", () => Results.Ok(new[]
{
    new Campaign(Guid.NewGuid(), "Electronics Sale", 15m, true),
    new Campaign(Guid.NewGuid(), "Fashion Week", 20m, true)
}));

app.MapControllers();
app.Run();

public sealed record Advertisement(Guid Id, string Title, string Description, string ImageUrl, string TargetUrl, string Placement, int Priority, bool IsActive);
public sealed record Campaign(Guid Id, string Name, decimal DiscountPercentage, bool IsActive);
