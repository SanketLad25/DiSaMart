using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

var preferences = new ConcurrentDictionary<Guid, UserPreference>();
var settings = new[]
{
    new ApplicationSetting("applicationName", "DiSaMart", "string", true),
    new ApplicationSetting("defaultTheme", "light", "string", true),
    new ApplicationSetting("defaultCurrency", "INR", "string", true),
    new ApplicationSetting("defaultLanguage", "en-IN", "string", true),
    new ApplicationSetting("itemsPerPage", "12", "integer", true)
};

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "customizationservice" }));
app.MapGet("/health/ready", () => Results.Ok(new { status = "ready", service = "customizationservice" }));
app.MapGet("/api/settings", () => Results.Ok(settings));
app.MapGet("/api/preferences/{userId:guid}", (Guid userId) =>
    Results.Ok(preferences.GetOrAdd(userId, id => new UserPreference(id, "light", "INR", "en-IN"))));
app.MapPut("/api/preferences/{userId:guid}", (Guid userId, UpdatePreferenceRequest request) =>
{
    var preference = new UserPreference(userId, request.Theme, request.CurrencyCode.ToUpperInvariant(), request.Language);
    preferences[userId] = preference;
    return Results.Ok(preference);
});

app.MapControllers();
app.Run();

public sealed record ApplicationSetting(string Key, string Value, string DataType, bool IsPublic);
public sealed record UserPreference(Guid UserId, string Theme, string CurrencyCode, string Language);
public sealed record UpdatePreferenceRequest(string Theme, string CurrencyCode, string Language);
