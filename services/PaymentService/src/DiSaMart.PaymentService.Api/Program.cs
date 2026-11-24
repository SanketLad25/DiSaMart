using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddDbContext<PaymentContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("PaymentDb")));

var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "paymentservice" }));
app.MapGet("/health/ready", async (PaymentContext db) =>
{
    var canConnect = await db.Database.CanConnectAsync();
    return canConnect ? Results.Ok(new { status = "ready", service = "paymentservice" }) : Results.StatusCode(503);
});

app.MapPost("/api/payments", async (PaymentRequest request, PaymentContext db) =>
{
    if (request.Amount <= 0)
        return Results.BadRequest(new { error = "ValidationError", message = "Amount must be greater than zero." });
    if (request.Method is not ("COD" or "MOCK_CARD"))
        return Results.BadRequest(new { error = "ValidationError", message = "Use COD or MOCK_CARD." });

    var payment = new PaymentEntity
    {
        Id = Guid.NewGuid(),
        OrderId = request.OrderId,
        UserId = request.UserId,
        Amount = request.Amount,
        CurrencyCode = string.IsNullOrWhiteSpace(request.CurrencyCode) ? "INR" : request.CurrencyCode.ToUpperInvariant(),
        Method = request.Method,
        Status = "Succeeded"
    };
    db.Payments.Add(payment);
    db.PaymentTransactions.Add(new PaymentTransactionEntity
    {
        Id = Guid.NewGuid(),
        PaymentId = payment.Id,
        ProviderReference = $"MOCK-{Guid.NewGuid():N}",
        Status = "Succeeded"
    });
    await db.SaveChangesAsync();
    return Results.Created($"/api/payments/{payment.Id}", payment);
});

app.MapGet("/api/payments/{id:guid}", async (Guid id, PaymentContext db) =>
{
    var payment = await db.Payments.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
    return payment is null ? Results.NotFound(new { error = "PaymentNotFound", message = "Payment was not found." }) : Results.Ok(payment);
});

app.MapControllers();
app.Run();

public sealed class PaymentContext(DbContextOptions<PaymentContext> options) : DbContext(options)
{
    public DbSet<PaymentEntity> Payments => Set<PaymentEntity>();
    public DbSet<PaymentTransactionEntity> PaymentTransactions => Set<PaymentTransactionEntity>();
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PaymentEntity>().ToTable("Payments").HasKey(x => x.Id);
        modelBuilder.Entity<PaymentEntity>().Property(x => x.Amount).HasPrecision(18, 2);
        modelBuilder.Entity<PaymentTransactionEntity>().ToTable("PaymentTransactions").HasKey(x => x.Id);
    }
}

public sealed class PaymentEntity
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid UserId { get; set; }
    public decimal Amount { get; set; }
    public string CurrencyCode { get; set; } = "INR";
    public string Method { get; set; } = "COD";
    public string Status { get; set; } = "Succeeded";
    public string? FailureReason { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class PaymentTransactionEntity
{
    public Guid Id { get; set; }
    public Guid PaymentId { get; set; }
    public string ProviderReference { get; set; } = "";
    public string Status { get; set; } = "Succeeded";
    public string? RequestPayload { get; set; }
    public string? ResponsePayload { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed record PaymentRequest(Guid OrderId, Guid UserId, decimal Amount, string CurrencyCode, string Method);
