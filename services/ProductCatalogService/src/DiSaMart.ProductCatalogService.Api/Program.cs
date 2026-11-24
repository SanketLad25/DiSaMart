using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddDbContext<CatalogContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ProductCatalogDb")));

var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "productcatalogservice" }));
app.MapGet("/health/ready", async (CatalogContext db) =>
{
    var canConnect = await db.Database.CanConnectAsync();
    return canConnect
        ? Results.Ok(new { status = "ready", service = "productcatalogservice" })
        : Results.StatusCode(StatusCodes.Status503ServiceUnavailable);
});

app.MapGet("/api/categories", async (CatalogContext db) =>
    Results.Ok(await db.Categories.AsNoTracking().Where(x => x.IsActive).OrderBy(x => x.Name).ToListAsync()));

app.MapGet("/api/products", async (
    CatalogContext db,
    string? search,
    Guid? categoryId,
    string? sort,
    int page = 1,
    int pageSize = 12) =>
{
    page = Math.Max(1, page);
    pageSize = Math.Clamp(pageSize, 1, 100);

    var query = db.Products.AsNoTracking().Where(x => x.IsActive);
    if (!string.IsNullOrWhiteSpace(search))
        query = query.Where(x => x.Name.Contains(search) || x.Description.Contains(search));
    if (categoryId.HasValue)
        query = query.Where(x => x.CategoryId == categoryId.Value);

    query = sort?.ToLowerInvariant() switch
    {
        "pricedesc" => query.OrderByDescending(x => x.DiscountPrice),
        "rating" => query.OrderByDescending(x => x.Rating),
        "name" => query.OrderBy(x => x.Name),
        _ => query.OrderBy(x => x.DiscountPrice)
    };

    var total = await query.CountAsync();
    var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
    return Results.Ok(new
    {
        items,
        page,
        pageSize,
        total,
        totalPages = (int)Math.Ceiling(total / (double)pageSize)
    });
});

app.MapGet("/api/products/featured", async (CatalogContext db) =>
    Results.Ok(await db.Products.AsNoTracking()
        .Where(x => x.IsActive && x.IsFeatured)
        .OrderByDescending(x => x.Rating)
        .Take(12)
        .ToListAsync()));

app.MapGet("/api/products/{id:guid}", async (Guid id, CatalogContext db) =>
{
    var product = await db.Products.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id && x.IsActive);
    return product is null ? Results.NotFound(new { error = "ProductNotFound", message = "Product was not found." }) : Results.Ok(product);
});

app.MapPost("/api/products/{id:guid}/validate", async (Guid id, StockValidation request, CatalogContext db) =>
{
    if (request.Quantity < 1)
        return Results.BadRequest(new { error = "ValidationError", message = "Quantity must be at least 1." });

    var product = await db.Products.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id && x.IsActive);
    if (product is null)
        return Results.NotFound(new { error = "ProductNotFound", message = "Product was not found." });
    if (request.Quantity > product.StockQuantity)
        return Results.BadRequest(new { error = "InsufficientStock", message = "Requested quantity exceeds available stock." });

    return Results.Ok(new { product.Id, product.Name, unitPrice = product.DiscountPrice, quantity = request.Quantity, available = true });
});

app.MapControllers();
app.Run();

public sealed class CatalogContext(DbContextOptions<CatalogContext> options) : DbContext(options)
{
    public DbSet<CategoryEntity> Categories => Set<CategoryEntity>();
    public DbSet<ProductEntity> Products => Set<ProductEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CategoryEntity>().ToTable("Categories");
        modelBuilder.Entity<CategoryEntity>().HasKey(x => x.Id);
        modelBuilder.Entity<ProductEntity>().ToTable("Products");
        modelBuilder.Entity<ProductEntity>().HasKey(x => x.Id);
        modelBuilder.Entity<ProductEntity>().Property(x => x.OriginalPrice).HasPrecision(18, 2);
        modelBuilder.Entity<ProductEntity>().Property(x => x.DiscountPrice).HasPrecision(18, 2);
        modelBuilder.Entity<ProductEntity>().Property(x => x.Rating).HasPrecision(3, 2);
    }
}

public sealed class CategoryEntity
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Slug { get; set; } = "";
    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; }
}

public sealed class ProductEntity
{
    public Guid Id { get; set; }
    public Guid CategoryId { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string? ImageUrl { get; set; }
    public decimal OriginalPrice { get; set; }
    public decimal DiscountPrice { get; set; }
    public int StockQuantity { get; set; }
    public decimal Rating { get; set; }
    public bool IsFeatured { get; set; }
    public bool IsActive { get; set; }
}

public sealed record StockValidation(int Quantity);
