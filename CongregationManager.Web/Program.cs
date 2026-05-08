using Microsoft.EntityFrameworkCore;
using CongregationManager.Data;
using CongregationManager.Data.Components;
using CongregationManager.Web.Services;
using CongregationManager.Utils;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateLogger();

builder.Host.UseSerilog();

// Configure application-level encryption
var encryptionKey = builder.Configuration.GetValue<string>("EncryptionKey");
if (!string.IsNullOrEmpty(encryptionKey))
{
    EncryptionProvider.Initialize(encryptionKey);
    Log.Information("Application-level data encryption enabled");
}
else
{
    Log.Warning("EncryptionKey not configured - sensitive data will be stored unencrypted");
}

// Configure EF Core
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(connectionString))
{
    // PostgreSQL for production/web
    builder.Services.AddDbContext<FieldServiceDbContext>(options =>
        options.UseNpgsql(connectionString));
}
else
{
    // Fallback to SQLite for local development
    var dbPath = builder.Configuration.GetValue<string>("DatabasePath");
    if (string.IsNullOrEmpty(dbPath))
        dbPath = Path.Combine(Directory.GetCurrentDirectory(), "field-service.db");

    builder.Services.AddDbContext<FieldServiceDbContext>(options =>
        options.UseSqlite($"Data Source={dbPath}"));
}

builder.Services.AddScoped<CloudSyncService>();
builder.Services.AddControllers();

var app = builder.Build();

// Apply database schema
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<FieldServiceDbContext>();
    var scriptsPath = Path.Combine(app.Environment.ContentRootPath, "SqlMigrations");

    CongregationManager.Web.Services.DatabaseMigrator.Run(context, scriptsPath);
}

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));
app.MapControllers();

app.Run();
