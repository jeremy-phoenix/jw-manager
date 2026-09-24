using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Threading.RateLimiting;
using CongregationManager.Server.Configuration;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Web;

internal static class RateLimiting
{
    /// <summary>Vault creation and enrollment, partitioned by client IP.</summary>
    public const string AnonymousPolicy = "anonymous";

    /// <summary>Authenticated calls, partitioned by device token.</summary>
    public const string DevicePolicy = "device";

    public static IServiceCollection AddSyncServerRateLimiting(this IServiceCollection services)
    {
        services.AddRateLimiter(_ => { });
        services.AddOptions<RateLimiterOptions>()
            .Configure<IOptions<SyncServerOptions>>((options, serverOptions) =>
            {
                var limits = serverOptions.Value.RateLimits;
                options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
                options.OnRejected = OnRejectedAsync;

                // Coarse per-IP ceiling for everything, including unknown routes.
                options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
                    FixedWindow($"global:{ClientIp(context)}", 1200));

                options.AddPolicy(AnonymousPolicy, context =>
                    FixedWindow($"anonymous:{ClientIp(context)}", limits.AnonymousPerMinute));

                options.AddPolicy(DevicePolicy, context =>
                    FixedWindow($"device:{TokenPartition(context)}", limits.DevicePerMinute));
            });
        return services;
    }

    private static RateLimitPartition<string> FixedWindow(string key, int permitsPerMinute) =>
        RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = permitsPerMinute,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
            AutoReplenishment = true,
        });

    private static string ClientIp(HttpContext context) =>
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown";

    private static string TokenPartition(HttpContext context)
    {
        var authorization = context.Request.Headers.Authorization.ToString();
        if (string.IsNullOrEmpty(authorization))
        {
            return $"ip:{ClientIp(context)}";
        }

        // Partition by a digest so raw tokens never become limiter keys.
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(authorization)), 0, 16);
    }

    private static async ValueTask OnRejectedAsync(OnRejectedContext rejection, CancellationToken cancellationToken)
    {
        var context = rejection.HttpContext;
        if (rejection.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
        {
            context.Response.Headers.RetryAfter =
                Math.Ceiling(retryAfter.TotalSeconds).ToString(CultureInfo.InvariantCulture);
        }

        await context.Response.WriteAsJsonAsync(
            new ApiError("RATE_LIMITED", "Too many requests. Try again later."),
            cancellationToken);
    }
}
