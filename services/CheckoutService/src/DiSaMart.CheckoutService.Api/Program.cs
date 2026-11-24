using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddDbContext<CheckoutContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("CheckoutDb")));

builder.Services.AddHttpClient("cart", client => client.BaseAddress = new Uri(builder.Configuration["Services:Cart"] ?? "http://cartservice:8080"));
builder.Services.AddHttpClient("payment", client => client.BaseAddress = new Uri(builder.Configuration["Services:Payment"] ?? "http://paymentservice:8080"));
builder.Services.AddHttpClient("shipping", client => client.BaseAddress = new Uri(builder.Configuration["Services:Shipping"] ?? "http://shippingservice:8080"));
builder.Services.AddHttpClient("email", client => client.BaseAddress = new Uri(builder.Configuration["Services:Email"] ?? "http://emailservice:8080"));

var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "checkoutservice" }));
app.MapGet("/health/ready", async (CheckoutContext db) =>
{
    var canConnect = await db.Database.CanConnectAsync();
    return canConnect ? Results.Ok(new { status = "ready", service = "checkoutservice" }) : Results.StatusCode(503);
});

app.MapPost("/api/checkout/validate", async (CheckoutValidateRequest request, IHttpClientFactory http) =>
{
    if (request.UserId == Guid.Empty)
        return Results.BadRequest(new { error = "ValidationError", message = "User ID is required." });
    try
    {
        using var response = await http.CreateClient("cart").GetAsync($"/api/carts/{request.UserId}");
        if (!response.IsSuccessStatusCode)
            return Results.StatusCode((int)response.StatusCode);
        var cart = await response.Content.ReadFromJsonAsync<CartSnapshot>();
        if (cart is null || cart.Items.Count == 0)
            return Results.BadRequest(new { error = "EmptyCart", message = "The cart is empty." });
        var shippingCharge = cart.Subtotal >= 500m ? 0m : 79m;
        return Results.Ok(new
        {
            valid = true,
            subtotal = cart.Subtotal,
            shippingCharge,
            grandTotal = cart.Subtotal + shippingCharge
        });
    }
    catch (HttpRequestException ex)
    {
        app.Logger.LogWarning(ex, "Cart validation failed");
        return Results.Json(new { error = "ServiceUnavailable", message = "CartService is unavailable." }, statusCode: 503);
    }
});

app.MapPost("/api/checkout/orders", async (CreateOrderRequest request, CheckoutContext db, IHttpClientFactory http) =>
{
    if (request.UserId == Guid.Empty || request.CartId == Guid.Empty)
        return Results.BadRequest(new { error = "ValidationError", message = "User ID and cart ID are required." });
    if (request.PaymentMethod is not ("COD" or "MOCK_CARD"))
        return Results.BadRequest(new { error = "ValidationError", message = "Use COD or MOCK_CARD." });

    CartSnapshot cart;
    try
    {
        using var cartResponse = await http.CreateClient("cart").GetAsync($"/api/carts/{request.UserId}");
        if (!cartResponse.IsSuccessStatusCode)
            return Results.StatusCode((int)cartResponse.StatusCode);
        cart = await cartResponse.Content.ReadFromJsonAsync<CartSnapshot>()
            ?? throw new InvalidOperationException("CartService returned an empty response.");
    }
    catch (HttpRequestException ex)
    {
        app.Logger.LogWarning(ex, "Unable to retrieve cart");
        return Results.Json(new { error = "ServiceUnavailable", message = "CartService is unavailable." }, statusCode: 503);
    }

    if (cart.Items.Count == 0)
        return Results.BadRequest(new { error = "EmptyCart", message = "The cart is empty." });

    var shippingCharge = cart.Subtotal >= 500m ? 0m : 79m;
    var grandTotal = cart.Subtotal + shippingCharge;
    var order = new OrderEntity
    {
        Id = Guid.NewGuid(),
        UserId = request.UserId,
        CartId = request.CartId,
        Subtotal = cart.Subtotal,
        ShippingCharge = shippingCharge,
        Tax = 0m,
        GrandTotal = grandTotal,
        CurrencyCode = request.CurrencyCode.ToUpperInvariant(),
        Status = "PaymentPending"
    };
    db.Orders.Add(order);
    foreach (var item in cart.Items)
        db.OrderItems.Add(new OrderItemEntity
        {
            Id = Guid.NewGuid(),
            OrderId = order.Id,
            ProductId = item.ProductId,
            ProductName = item.ProductName,
            UnitPrice = item.UnitPrice,
            Quantity = item.Quantity,
            LineTotal = item.LineTotal
        });
    await db.SaveChangesAsync();

    using var paymentResponse = await http.CreateClient("payment").PostAsJsonAsync("/api/payments", new
    {
        orderId = order.Id,
        userId = request.UserId,
        amount = grandTotal,
        currencyCode = request.CurrencyCode,
        method = request.PaymentMethod
    });
    if (!paymentResponse.IsSuccessStatusCode)
    {
        order.Status = "PaymentFailed";
        await db.SaveChangesAsync();
        return Results.BadRequest(new { error = "PaymentFailed", message = "The mock payment could not be processed." });
    }
    var payment = await paymentResponse.Content.ReadFromJsonAsync<PaymentSnapshot>();
    if (payment is null)
        return Results.StatusCode(502);

    using var addressResponse = await http.CreateClient("shipping").PostAsJsonAsync("/api/shipping/addresses", new
    {
        userId = request.UserId,
        request.ShippingAddress.FullName,
        request.ShippingAddress.Phone,
        request.ShippingAddress.AddressLine1,
        request.ShippingAddress.AddressLine2,
        request.ShippingAddress.City,
        request.ShippingAddress.State,
        request.ShippingAddress.PostalCode,
        request.ShippingAddress.Country
    });
    if (!addressResponse.IsSuccessStatusCode)
        return Results.StatusCode(502);
    var address = await addressResponse.Content.ReadFromJsonAsync<AddressSnapshot>();
    if (address is null)
        return Results.StatusCode(502);

    using var shipmentResponse = await http.CreateClient("shipping").PostAsJsonAsync("/api/shipping/shipments", new
    {
        orderId = order.Id,
        addressId = address.Id,
        shippingCharge
    });
    if (!shipmentResponse.IsSuccessStatusCode)
        return Results.StatusCode(502);
    var shipment = await shipmentResponse.Content.ReadFromJsonAsync<ShipmentSnapshot>();
    if (shipment is null)
        return Results.StatusCode(502);

    order.PaymentId = payment.Id;
    order.ShipmentId = shipment.Id;
    order.Status = "Confirmed";
    await db.SaveChangesAsync();

    await http.CreateClient("email").PostAsJsonAsync("/api/emails/order-confirmation", new
    {
        recipient = request.ShippingAddress.Phone + "@example.local",
        subject = $"DiSaMart order {order.Id}",
        body = $"Your order total is {grandTotal} {request.CurrencyCode}."
    });
    await http.CreateClient("cart").DeleteAsync($"/api/carts/{request.UserId}");

    return Results.Created($"/api/orders/{order.Id}", new OrderConfirmation(order.Id, order.Status, grandTotal, payment.Id, shipment.Id, shipment.TrackingNumber));
});

app.MapGet("/api/orders/{orderId:guid}", async (Guid orderId, CheckoutContext db) =>
{
    var order = await db.Orders.AsNoTracking().FirstOrDefaultAsync(x => x.Id == orderId);
    return order is null ? Results.NotFound(new { error = "OrderNotFound", message = "Order was not found." }) : Results.Ok(order);
});

app.MapGet("/api/orders/user/{userId:guid}", async (Guid userId, CheckoutContext db) =>
    Results.Ok(await db.Orders.AsNoTracking().Where(x => x.UserId == userId).OrderByDescending(x => x.CreatedAtUtc).ToListAsync()));

app.MapControllers();
app.Run();

public sealed class CheckoutContext(DbContextOptions<CheckoutContext> options) : DbContext(options)
{
    public DbSet<OrderEntity> Orders => Set<OrderEntity>();
    public DbSet<OrderItemEntity> OrderItems => Set<OrderItemEntity>();
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<OrderEntity>().ToTable("Orders").HasKey(x => x.Id);
        modelBuilder.Entity<OrderEntity>().Property(x => x.Subtotal).HasPrecision(18, 2);
        modelBuilder.Entity<OrderEntity>().Property(x => x.ShippingCharge).HasPrecision(18, 2);
        modelBuilder.Entity<OrderEntity>().Property(x => x.Tax).HasPrecision(18, 2);
        modelBuilder.Entity<OrderEntity>().Property(x => x.GrandTotal).HasPrecision(18, 2);
        modelBuilder.Entity<OrderItemEntity>().ToTable("OrderItems").HasKey(x => x.Id);
        modelBuilder.Entity<OrderItemEntity>().Property(x => x.UnitPrice).HasPrecision(18, 2);
        modelBuilder.Entity<OrderItemEntity>().Property(x => x.LineTotal).HasPrecision(18, 2);
    }
}

public sealed class OrderEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid CartId { get; set; }
    public decimal Subtotal { get; set; }
    public decimal ShippingCharge { get; set; }
    public decimal Tax { get; set; }
    public decimal GrandTotal { get; set; }
    public string CurrencyCode { get; set; } = "INR";
    public Guid? PaymentId { get; set; }
    public Guid? ShipmentId { get; set; }
    public string Status { get; set; } = "PaymentPending";
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class OrderItemEntity
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = "";
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal LineTotal { get; set; }
}

public sealed record CheckoutValidateRequest(Guid UserId);
public sealed record CreateOrderRequest(Guid UserId, Guid CartId, string CurrencyCode, string PaymentMethod, ShippingAddressRequest ShippingAddress);
public sealed record ShippingAddressRequest(string FullName, string Phone, string AddressLine1, string? AddressLine2, string City, string State, string PostalCode, string Country);
public sealed record CartSnapshot(Guid Id, Guid UserId, string CurrencyCode, IReadOnlyList<CartItemSnapshot> Items, decimal Subtotal);
public sealed record CartItemSnapshot(Guid Id, Guid ProductId, string ProductName, decimal UnitPrice, int Quantity, decimal LineTotal);
public sealed record PaymentSnapshot(Guid Id, string Status);
public sealed record AddressSnapshot(Guid Id);
public sealed record ShipmentSnapshot(Guid Id, string TrackingNumber);
public sealed record OrderConfirmation(Guid OrderId, string Status, decimal GrandTotal, Guid PaymentId, Guid ShipmentId, string TrackingNumber);
