using System.Net;
using System.Text.Json.Serialization;
using CongregationManager.Server.Configuration;
using CongregationManager.Server.Features;
using CongregationManager.Server.Features.Devices;
using CongregationManager.Server.Features.Keys;
using CongregationManager.Server.Features.Sync;
using CongregationManager.Server.Features.Vaults;
using CongregationManager.Server.Infrastructure.Database;
using CongregationManager.Server.Security;
using CongregationManager.Server.Web;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Infrastructure;

public static class ServerSetup
{
    public static WebApplicationBuilder AddSyncServer(this WebApplicationBuilder builder)
    {
        builder.Host.UseDefaultServiceProvider((_, serviceProvider) =>
        {
            serviceProvider.ValidateOnBuild = true;
            serviceProvider.ValidateScopes = true;
        });

        var services = builder.Services;
        services.AddOptions<SyncServerOptions>()
            .Bind(builder.Configuration.GetSection(SyncServerOptions.SectionName))
            .ValidateOnStart();
        services.AddSingleton<IValidateOptions<SyncServerOptions>, SyncServerOptionsValidator>();

        services.Configure<JsonOptions>(options =>
        {
            options.SerializerOptions.RespectNullableAnnotations = true;
            options.SerializerOptions.RespectRequiredConstructorParameters = true;
            options.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
        });

        services.TryAddSingleton(TimeProvider.System);
        services.AddSingleton<VaultLocks>();
        services.AddDbContext<SyncDbContext>((serviceProvider, options) =>
        {
            var database = serviceProvider.GetRequiredService<IOptions<SyncServerOptions>>().Value.Database;
            if (database.Provider == DatabaseProviders.Postgres)
            {
                options.UseNpgsql(database.ConnectionString);
            }
            else
            {
                options.UseSqlite(database.ConnectionString);
            }
        });

        services.AddScoped<VaultService>();
        services.AddScoped<DeviceService>();
        services.AddScoped<SyncService>();
        services.AddScoped<KeyService>();
        services.AddHostedService<MaintenanceService>();

        services.AddExceptionHandler<ApiExceptionHandler>();
        services.AddProblemDetails();
        services.AddSyncServerRateLimiting();

        services.AddOptions<ForwardedHeadersOptions>()
            .Configure<IOptions<SyncServerOptions>>((forwarded, serverOptions) =>
            {
                // Loopback proxies (Caddy/nginx on the same host) are trusted
                // by default; add others explicitly.
                forwarded.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
                foreach (var proxy in serverOptions.Value.Security.TrustedProxies)
                {
                    forwarded.KnownProxies.Add(IPAddress.Parse(proxy));
                }
            });

        var maxBodyBytes = builder.Configuration
            .GetSection(SyncServerOptions.SectionName)
            .Get<SyncServerOptions>()?.Limits.MaxRequestBodyBytes
            ?? new LimitOptions().MaxRequestBodyBytes;
        builder.WebHost.ConfigureKestrel(kestrel =>
        {
            kestrel.AddServerHeader = false;
            kestrel.Limits.MaxRequestBodySize = maxBodyBytes;
        });

        return builder;
    }

    public static WebApplication UseSyncServerPipeline(this WebApplication app)
    {
        app.UseForwardedHeaders();
        app.UseExceptionHandler();
        if (!app.Environment.IsDevelopment())
        {
            app.UseHsts();
        }

        app.UseMiddleware<SecurityHeadersMiddleware>();
        app.UseRateLimiter();
        return app;
    }

    public static WebApplication MapSyncServerApi(this WebApplication app)
    {
        app.MapGet("/health", () => new HealthResponse("ok"));

        var api = app.MapGroup("/api/v1");

        // Unauthenticated: each of these requires its own secret (registration
        // secret, invite code, or recovery key) and is rate limited per IP.
        api.MapPost("/vaults", (
                CreateVaultRequest request,
                HttpRequest httpRequest,
                VaultService vaults,
                CancellationToken cancellationToken) =>
                CreatedResult(vaults.CreateAsync(
                    request,
                    httpRequest.Headers["X-Registration-Secret"].ToString(),
                    cancellationToken)))
            .RequireRateLimiting(RateLimiting.AnonymousPolicy);
        api.MapPost("/devices/enroll", (
                EnrollWithInviteRequest request,
                DeviceService devices,
                CancellationToken cancellationToken) =>
                CreatedResult(devices.EnrollWithInviteAsync(request, cancellationToken)))
            .RequireRateLimiting(RateLimiting.AnonymousPolicy);
        api.MapPost("/recovery/enroll", (
                EnrollWithRecoveryRequest request,
                DeviceService devices,
                CancellationToken cancellationToken) =>
                CreatedResult(devices.EnrollWithRecoveryAsync(request, cancellationToken)))
            .RequireRateLimiting(RateLimiting.AnonymousPolicy);

        var device = api.MapGroup("")
            .AddEndpointFilter<DeviceAuthenticationFilter>()
            .RequireRateLimiting(RateLimiting.DevicePolicy);

        device.MapGet("/vault", (HttpContext context, VaultService vaults, CancellationToken cancellationToken) =>
            vaults.GetAsync(AuthenticatedDevice.Current(context), cancellationToken));
        device.MapPost("/vault/delete", async (
            RecoveryProofRequest request,
            HttpContext context,
            VaultService vaults,
            CancellationToken cancellationToken) =>
        {
            await vaults.DeleteAsync(AuthenticatedDevice.Current(context), request, cancellationToken);
            return Results.NoContent();
        });

        device.MapGet("/devices", (HttpContext context, DeviceService devices, CancellationToken cancellationToken) =>
            devices.ListAsync(AuthenticatedDevice.Current(context), cancellationToken));
        device.MapDelete("/devices/{deviceId:guid}", async (
            Guid deviceId,
            HttpContext context,
            DeviceService devices,
            CancellationToken cancellationToken) =>
        {
            await devices.RevokeAsync(AuthenticatedDevice.Current(context), deviceId, cancellationToken);
            return Results.NoContent();
        });
        device.MapPut("/devices/{deviceId:guid}/label", async (
            Guid deviceId,
            SetDeviceLabelRequest request,
            HttpContext context,
            DeviceService devices,
            CancellationToken cancellationToken) =>
        {
            await devices.SetLabelAsync(AuthenticatedDevice.Current(context), deviceId, request, cancellationToken);
            return Results.NoContent();
        });
        device.MapPost("/invites", (
                CreateInviteRequest request,
                HttpContext context,
                DeviceService devices,
                CancellationToken cancellationToken) =>
            CreatedResult(devices.CreateInviteAsync(AuthenticatedDevice.Current(context), request, cancellationToken)));

        device.MapPost("/sync/push", (
                PushRequest request,
                HttpContext context,
                SyncService sync,
                CancellationToken cancellationToken) =>
            sync.PushAsync(AuthenticatedDevice.Current(context), request, cancellationToken));
        device.MapGet("/sync/pull", (
                long? since,
                int? limit,
                HttpContext context,
                SyncService sync,
                CancellationToken cancellationToken) =>
            sync.PullAsync(AuthenticatedDevice.Current(context), since, limit, cancellationToken));

        device.MapPost("/keys/rotate", (
                RotateKeyRequest request,
                HttpContext context,
                KeyService keys,
                CancellationToken cancellationToken) =>
            keys.RotateAsync(AuthenticatedDevice.Current(context), request, cancellationToken));
        device.MapGet("/keys/stale", (
                int? limit,
                HttpContext context,
                KeyService keys,
                CancellationToken cancellationToken) =>
            keys.GetStaleAsync(AuthenticatedDevice.Current(context), limit, cancellationToken));
        device.MapPost("/keys/rekey", (
                RekeyRequest request,
                HttpContext context,
                KeyService keys,
                CancellationToken cancellationToken) =>
            keys.RekeyAsync(AuthenticatedDevice.Current(context), request, cancellationToken));

        return app;
    }

    private static async Task<IResult> CreatedResult<T>(Task<T> operation) =>
        TypedResults.Json(await operation, statusCode: StatusCodes.Status201Created);
}
