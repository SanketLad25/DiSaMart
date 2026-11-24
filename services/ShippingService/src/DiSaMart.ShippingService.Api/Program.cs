using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddDbContext<ShippingContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ShippingDb")));

var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "shippingservice" }));
app.MapGet("/health/ready", async (ShippingContext db) =>
{
    var canConnect = await db.Database.CanConnectAsync();
    return canConnect ? Results.Ok(new { status = "ready", service = "shippingservice" }) : Results.StatusCode(503);
});

app.MapPost("/api/shipping/addresses", async (ShippingAddressRequest request, ShippingContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.FullName) || string.IsNullOrWhiteSpace(request.AddressLine1))
        return Results.BadRequest(new { error = "ValidationError", message = "Full name and address line 1 are required." });
    if (string.IsNullOrWhiteSpace(request.Phone) || string.IsNullOrWhiteSpace(request.PostalCode))
        return Results.BadRequest(new { error = "ValidationError", message = "Phone and postal code are required." });

    var address = new ShippingAddressEntity
    {
        Id = Guid.NewGuid(),
        UserId = request.UserId,
        FullName = request.FullName,
        Phone = request.Phone,
        AddressLine1 = request.AddressLine1,
        AddressLine2 = request.AddressLine2,
        City = request.City,
        State = request.State,
        PostalCode = request.PostalCode,
        Country = request.Country
    };
    db.Addresses.Add(address);
    await db.SaveChangesAsync();
    return Results.Created($"/api/shipping/addresses/{address.Id}", address);
});

app.MapPost("/api/shipping/shipments", async (ShipmentRequest request, ShippingContext db) =>
{
    var address = await db.Addresses.AsNoTracking().FirstOrDefaultAsync(x => x.Id == request.AddressId);
    if (address is null)
        return Results.NotFound(new { error = "AddressNotFound", message = "Shipping address was not found." });
    var shipment = new ShipmentEntity
    {
        Id = Guid.NewGuid(),
        OrderId = request.OrderId,
        AddressId = request.AddressId,
        Carrier = "DiSaMart Express",
        TrackingNumber = $"DSM{Random.Shared.Next(10000000, 99999999)}",
        Status = "Confirmed",
        ShippingCharge = request.ShippingCharge,
        EstimatedDeliveryDateUtc = DateTime.UtcNow.AddDays(4)
    };
    db.Shipments.Add(shipment);
    await db.SaveChangesAsync();
    return Results.Created($"/api/shipping/shipments/{shipment.Id}", shipment);
});

app.MapGet("/api/shipping/shipments/{id:guid}", async (Guid id, ShippingContext db) =>
{
    var shipment = await db.Shipments.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
    return shipment is null ? Results.NotFound(new { error = "ShipmentNotFound", message = "Shipment was not found." }) : Results.Ok(shipment);
});

app.MapControllers();
app.Run();

public sealed class ShippingContext(DbContextOptions<ShippingContext> options) : DbContext(options)
{
    public DbSet<ShippingAddressEntity> Addresses => Set<ShippingAddressEntity>();
    public DbSet<ShipmentEntity> Shipments => Set<ShipmentEntity>();
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ShippingAddressEntity>().ToTable("ShippingAddresses").HasKey(x => x.Id);
        modelBuilder.Entity<ShipmentEntity>().ToTable("Shipments").HasKey(x => x.Id);
        modelBuilder.Entity<ShipmentEntity>().Property(x => x.ShippingCharge).HasPrecision(18, 2);
    }
}

public sealed class ShippingAddressEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string FullName { get; set; } = "";
    public string Phone { get; set; } = "";
    public string AddressLine1 { get; set; } = "";
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = "";
    public string State { get; set; } = "";
    public string PostalCode { get; set; } = "";
    public string Country { get; set; } = "India";
}

public sealed class ShipmentEntity
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid AddressId { get; set; }
    public string Carrier { get; set; } = "";
    public string TrackingNumber { get; set; } = "";
    public string Status { get; set; } = "Confirmed";
    public decimal ShippingCharge { get; set; }
    public DateTime EstimatedDeliveryDateUtc { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed record ShippingAddressRequest(Guid UserId, string FullName, string Phone, string AddressLine1, string? AddressLine2, string City, string State, string PostalCode, string Country);
public sealed record ShipmentRequest(Guid OrderId, Guid AddressId, decimal ShippingCharge);
