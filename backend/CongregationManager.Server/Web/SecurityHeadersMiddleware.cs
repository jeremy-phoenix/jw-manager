using CongregationManager.Server.Configuration;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Web;

/// <summary>
/// Refuses plain-HTTP API calls (after forwarded headers are applied) and
/// marks every response as non-cacheable.
/// </summary>
internal sealed class SecurityHeadersMiddleware(RequestDelegate next, IOptions<SyncServerOptions> options)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var headers = context.Response.Headers;
        headers.CacheControl = "no-store";
        headers.XContentTypeOptions = "nosniff";
        headers.XFrameOptions = "DENY";
        headers["Referrer-Policy"] = "no-referrer";

        // Local health probes stay on plain HTTP; everything else carries
        // tokens or ciphertext and must be encrypted in transit.
        if (options.Value.Security.RequireHttps
            && !context.Request.IsHttps
            && !context.Request.Path.StartsWithSegments("/health"))
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsJsonAsync(
                new ApiError("HTTPS_REQUIRED", "This server only accepts HTTPS requests."),
                context.RequestAborted);
            return;
        }

        await next(context);
    }
}
