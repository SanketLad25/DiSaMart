var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddHttpClient();
var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

var generator = new LoadGeneratorState();

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "loadgenerator", generator.IsRunning }));
app.MapGet("/health/ready", () => Results.Ok(new { status = "ready", service = "loadgenerator" }));
app.MapGet("/api/load/status", () => Results.Ok(new { generator.IsRunning, generator.RequestCount }));
app.MapPost("/api/load/start", async (LoadStartRequest request, IHttpClientFactory http) =>
{
    if (generator.IsRunning)
        return Results.Ok(new { status = "already-running", generator.RequestCount });
    generator.Start(request.Users, request.IntervalMilliseconds);
    _ = Task.Run(() => generator.RunAsync(http.CreateClient(), app.Logger));
    return Results.Accepted("/api/load/status", new { status = "started", users = request.Users });
});
app.MapPost("/api/load/stop", () =>
{
    generator.Stop();
    return Results.Ok(new { status = "stopped", generator.RequestCount });
});

app.MapControllers();
app.Run();

public sealed class LoadGeneratorState
{
    private CancellationTokenSource? _source;
    public bool IsRunning { get; private set; }
    public long RequestCount;

    public void Start(int users, int intervalMilliseconds)
    {
        Users = Math.Clamp(users, 1, 100);
        IntervalMilliseconds = Math.Clamp(intervalMilliseconds, 100, 60_000);
        _source = new CancellationTokenSource();
        IsRunning = true;
    }

    public void Stop()
    {
        _source?.Cancel();
        _source?.Dispose();
        _source = null;
        IsRunning = false;
    }

    private int Users { get; set; } = 5;
    private int IntervalMilliseconds { get; set; } = 1000;

    public async Task RunAsync(HttpClient client, ILogger logger)
    {
        var catalogUrl = Environment.GetEnvironmentVariable("TARGET_CATALOG_URL") ?? "http://productcatalogservice:8080";
        while (IsRunning && _source is { IsCancellationRequested: false } source)
        {
            try
            {
                await client.GetAsync($"{catalogUrl}/api/products?pageSize=12", source.Token);
                Interlocked.Increment(ref RequestCount);
            }
            catch (OperationCanceledException) { break; }
            catch (HttpRequestException ex) { logger.LogDebug(ex, "Load generator request failed"); }
            await Task.Delay(IntervalMilliseconds, source.Token);
        }
    }
}

public sealed record LoadStartRequest(int Users = 5, int IntervalMilliseconds = 1000);
