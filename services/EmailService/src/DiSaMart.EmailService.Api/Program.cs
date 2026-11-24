using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddOpenApi();
var app = builder.Build();
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

var emailLogs = new ConcurrentQueue<EmailLog>();

app.MapGet("/health/live", () => Results.Ok(new { status = "alive", service = "emailservice" }));
app.MapGet("/health/ready", () => Results.Ok(new { status = "ready", service = "emailservice" }));
app.MapPost("/api/emails/registration", (EmailRequest request) => QueueEmail(request, "registration-confirmation", emailLogs));
app.MapPost("/api/emails/order-confirmation", (EmailRequest request) => QueueEmail(request, "order-confirmation", emailLogs));
app.MapPost("/api/emails/payment", (EmailRequest request) => QueueEmail(request, "payment-confirmation", emailLogs));
app.MapPost("/api/emails/shipping", (EmailRequest request) => QueueEmail(request, "shipping-update", emailLogs));
app.MapGet("/api/emails/logs", () => Results.Ok(emailLogs.ToArray()));

app.MapControllers();
app.Run();

static IResult QueueEmail(EmailRequest request, string templateKey, ConcurrentQueue<EmailLog> logs)
{
    if (string.IsNullOrWhiteSpace(request.Recipient))
        return Results.BadRequest(new { error = "ValidationError", message = "Recipient is required." });
    var log = new EmailLog(Guid.NewGuid(), request.Recipient, request.Subject ?? $"DiSaMart {templateKey}", templateKey, "MockSent", DateTime.UtcNow);
    logs.Enqueue(log);
    return Results.Accepted($"/api/emails/logs/{log.Id}", log);
}

public sealed record EmailRequest(string Recipient, string? Subject, string? Body);
public sealed record EmailLog(Guid Id, string Recipient, string Subject, string TemplateKey, string Status, DateTime SentAtUtc);
