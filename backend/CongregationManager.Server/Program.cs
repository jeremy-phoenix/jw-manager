using CongregationManager.Server.Infrastructure;
using CongregationManager.Server.Infrastructure.Database;

var builder = WebApplication.CreateBuilder(args);
builder.AddSyncServer();

var app = builder.Build();
app.UseSyncServerPipeline();
app.MapSyncServerApi();

await app.Services.InitializeDatabaseAsync(app.Lifetime.ApplicationStopping);
await app.RunAsync();

public partial class Program;
