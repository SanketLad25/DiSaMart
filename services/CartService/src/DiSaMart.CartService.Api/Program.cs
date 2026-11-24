using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddDbContext<CartContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("CartDb")));

var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "cartservice" }));
app.MapGet("/health/ready", async (CartContext db) =>
{
    var canConnect = await db.Database.CanConnectAsync();
    return canConnect
        ? Results.Ok(new { status = "ready", service = "cartservice" })
        : Results.StatusCode(StatusCodes.Status503ServiceUnavailable);
});

app.MapGet("/api/carts/{userId:guid}", async (Guid userId, CartContext db) =>
{
    var cart = await GetOrCreateCartAsync(userId, db);
    var items = await db.CartItems.AsNoTracking().Where(x => x.CartId == cart.Id).ToListAsync();
    return Results.Ok(new CartResponse(cart.Id, cart.UserId, cart.CurrencyCode,
        items.Select(x => new CartItemResponse(x.Id, x.ProductId, x.ProductName, x.UnitPrice, x.Quantity, x.UnitPrice * x.Quantity)).ToList(),
        items.Sum(x => x.UnitPrice * x.Quantity)));
});

app.MapPost("/api/carts/{userId:guid}/items", async (Guid userId, AddCartItem request, CartContext db) =>
{
    if (request.Quantity < 1 || request.Quantity > 99)
        return Results.BadRequest(new { error = "ValidationError", message = "Quantity must be from 1 to 99." });
    if (request.UnitPrice < 0)
        return Results.BadRequest(new { error = "ValidationError", message = "Unit price cannot be negative." });

    var cart = await GetOrCreateCartAsync(userId, db);
    var item = await db.CartItems.FirstOrDefaultAsync(x => x.CartId == cart.Id && x.ProductId == request.ProductId);
    if (item is null)
    {
        item = new CartItemEntity
        {
            Id = Guid.NewGuid(),
            CartId = cart.Id,
            ProductId = request.ProductId,
            ProductName = request.ProductName,
            UnitPrice = request.UnitPrice,
            Quantity = request.Quantity
        };
        db.CartItems.Add(item);
    }
    else
    {
        item.ProductName = request.ProductName;
        item.UnitPrice = request.UnitPrice;
        item.Quantity = Math.Min(99, item.Quantity + request.Quantity);
        item.UpdatedAtUtc = DateTime.UtcNow;
    }

    cart.UpdatedAtUtc = DateTime.UtcNow;
    await db.SaveChangesAsync();
    return Results.Ok(new { cartId = cart.Id, itemId = item.Id, quantity = item.Quantity });
});

app.MapPut("/api/carts/{userId:guid}/items/{itemId:guid}", async (Guid userId, Guid itemId, UpdateCartItem request, CartContext db) =>
{
    if (request.Quantity < 1 || request.Quantity > 99)
        return Results.BadRequest(new { error = "ValidationError", message = "Quantity must be from 1 to 99." });

    var cart = await db.Carts.FirstOrDefaultAsync(x => x.UserId == userId);
    if (cart is null)
        return Results.NotFound(new { error = "CartNotFound", message = "Cart was not found." });

    var item = await db.CartItems.FirstOrDefaultAsync(x => x.Id == itemId && x.CartId == cart.Id);
    if (item is null)
        return Results.NotFound(new { error = "CartItemNotFound", message = "Cart item was not found." });

    item.Quantity = request.Quantity;
    item.UpdatedAtUtc = DateTime.UtcNow;
    cart.UpdatedAtUtc = DateTime.UtcNow;
    await db.SaveChangesAsync();
    return Results.Ok(new { itemId = item.Id, quantity = item.Quantity });
});

app.MapDelete("/api/carts/{userId:guid}/items/{itemId:guid}", async (Guid userId, Guid itemId, CartContext db) =>
{
    var cart = await db.Carts.FirstOrDefaultAsync(x => x.UserId == userId);
    if (cart is null)
        return Results.NotFound(new { error = "CartNotFound", message = "Cart was not found." });
    var item = await db.CartItems.FirstOrDefaultAsync(x => x.Id == itemId && x.CartId == cart.Id);
    if (item is null)
        return Results.NotFound(new { error = "CartItemNotFound", message = "Cart item was not found." });
    db.CartItems.Remove(item);
    await db.SaveChangesAsync();
    return Results.NoContent();
});

app.MapDelete("/api/carts/{userId:guid}", async (Guid userId, CartContext db) =>
{
    var cart = await db.Carts.FirstOrDefaultAsync(x => x.UserId == userId);
    if (cart is null)
        return Results.NoContent();
    await db.CartItems.Where(x => x.CartId == cart.Id).ExecuteDeleteAsync();
    cart.UpdatedAtUtc = DateTime.UtcNow;
    await db.SaveChangesAsync();
    return Results.NoContent();
});

app.MapControllers();
app.Run();

static async Task<CartEntity> GetOrCreateCartAsync(Guid userId, CartContext db)
{
    var cart = await db.Carts.FirstOrDefaultAsync(x => x.UserId == userId);
    if (cart is not null)
        return cart;
    cart = new CartEntity { Id = Guid.NewGuid(), UserId = userId, CurrencyCode = "INR" };
    db.Carts.Add(cart);
    await db.SaveChangesAsync();
    return cart;
}

public sealed class CartContext(DbContextOptions<CartContext> options) : DbContext(options)
{
    public DbSet<CartEntity> Carts => Set<CartEntity>();
    public DbSet<CartItemEntity> CartItems => Set<CartItemEntity>();
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CartEntity>().ToTable("Carts").HasKey(x => x.Id);
        modelBuilder.Entity<CartItemEntity>().ToTable("CartItems").HasKey(x => x.Id);
        modelBuilder.Entity<CartItemEntity>().Property(x => x.UnitPrice).HasPrecision(18, 2);
    }
}

public sealed class CartEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string CurrencyCode { get; set; } = "INR";
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class CartItemEntity
{
    public Guid Id { get; set; }
    public Guid CartId { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = "";
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed record AddCartItem(Guid ProductId, string ProductName, decimal UnitPrice, int Quantity);
public sealed record UpdateCartItem(int Quantity);
public sealed record CartItemResponse(Guid Id, Guid ProductId, string ProductName, decimal UnitPrice, int Quantity, decimal LineTotal);
public sealed record CartResponse(Guid Id, Guid UserId, string CurrencyCode, IReadOnlyCollection<CartItemResponse> Items, decimal Subtotal);
