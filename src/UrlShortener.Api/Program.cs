var builder = WebApplication.CreateBuilder(args);
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.WriteIndented = true);
var app = builder.Build();

app.MapGet("/", () => new
{
    app = "UrlShortener",
    status = "running",
    version = "4"
});

// Health check. Used by App Service (week 35), by health-check.sh (week 36)
// and by the container (week 38). Do not remove.
app.MapGet("/health", () => Results.Ok(new
{
    status = "healthy",
    version = "4.0.0"
}));

app.MapGet("/info", () => new
{
    app = "UrlShortener",
    machine = Environment.MachineName,
    environment = Environment.GetEnvironmentVariable("BEACON_ENVIRONMENT") ?? "unset",
    message = Environment.GetEnvironmentVariable("BEACON_MESSAGE") ?? "unset",
    apiKeySet = !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("BEACON_API_KEY")),
    description = "Get a shorter version of a (very) long url."
});

app.Run();

// Makes Program visible to the test project.
public partial class Program { }
