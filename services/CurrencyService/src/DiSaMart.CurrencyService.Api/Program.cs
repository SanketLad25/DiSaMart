var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

var currencies = new[]
{
    new CurrencyResponse("INR", "Indian Rupee", "₹", 2),
    new CurrencyResponse("USD", "US Dollar", "$", 2),
    new CurrencyResponse("EUR", "Euro", "€", 2),
    new CurrencyResponse("GBP", "British Pound", "£", 2),
    new CurrencyResponse("AED", "UAE Dirham", "DH", 2)
};
var rates = new Dictionary<(string Base, string Target), decimal>
{
    [("INR", "INR")] = 1m,
    [("INR", "USD")] = 0.012m,
    [("INR", "EUR")] = 0.011m,
    [("INR", "GBP")] = 0.0094m,
    [("INR", "AED")] = 0.044m
};

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "currencyservice" }));
app.MapGet("/health/ready", () => Results.Ok(new { status = "ready", service = "currencyservice" }));
app.MapGet("/api/currencies", () => Results.Ok(currencies));
app.MapPost("/api/currencies/convert", (ConversionRequest request) =>
{
    var from = request.FromCurrency.ToUpperInvariant();
    var to = request.ToCurrency.ToUpperInvariant();
    if (request.Amount < 0)
        return Results.BadRequest(new { error = "ValidationError", message = "Amount cannot be negative." });
    if (!rates.TryGetValue((from, to), out var rate))
    {
        var reverse = rates.TryGetValue((to, from), out var reverseRate);
        if (!reverse) return Results.BadRequest(new { error = "UnsupportedCurrencyPair", message = "Currency pair is not supported." });
        rate = 1 / reverseRate;
    }
    return Results.Ok(new ConversionResponse(request.Amount, from, to, Math.Round(request.Amount * rate, 2), rate));
});

app.MapControllers();
app.Run();

public sealed record CurrencyResponse(string Code, string Name, string Symbol, int DecimalDigits);
public sealed record ConversionRequest(decimal Amount, string FromCurrency, string ToCurrency);
public sealed record ConversionResponse(decimal Amount, string FromCurrency, string ToCurrency, decimal ConvertedAmount, decimal Rate);
