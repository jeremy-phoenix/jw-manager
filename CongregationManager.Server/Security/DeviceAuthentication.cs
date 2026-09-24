using CongregationManager.Server.Infrastructure.Database;
using CongregationManager.Server.Web;
using Microsoft.EntityFrameworkCore;

namespace CongregationManager.Server.Security;

public sealed record AuthenticatedDevice(Guid DeviceId, Guid VaultId)
{
    private const string ItemKey = "congregation-manager.device";

    public static AuthenticatedDevice Current(HttpContext context) =>
        context.Items.TryGetValue(ItemKey, out var value) && value is AuthenticatedDevice device
            ? device
            : throw ApiException.Unauthorized();

    internal static void Set(HttpContext context, AuthenticatedDevice device) =>
        context.Items[ItemKey] = device;
}

/// <summary>
/// Resolves <c>Authorization: Bearer &lt;device token&gt;</c> to an active
/// device. Fails closed: no token, an unknown token, or a revoked device is
/// always 401.
/// </summary>
internal sealed class DeviceAuthenticationFilter(SyncDbContext database, TimeProvider timeProvider)
    : IEndpointFilter
{
    private static readonly TimeSpan LastSeenResolution = TimeSpan.FromMinutes(5);

    public async ValueTask<object?> InvokeAsync(
        EndpointFilterInvocationContext invocationContext,
        EndpointFilterDelegate next)
    {
        var context = invocationContext.HttpContext;
        var token = ReadBearerToken(context.Request) ?? throw ApiException.Unauthorized();
        var tokenHash = SecretTokens.Hash(token);

        var device = await database.Devices
            .AsNoTracking()
            .Where(candidate => candidate.TokenHash == tokenHash && candidate.RevokedAtMs == null)
            .Select(candidate => new { candidate.Id, candidate.VaultId, candidate.LastSeenAtMs })
            .SingleOrDefaultAsync(context.RequestAborted)
            ?? throw ApiException.Unauthorized();

        AuthenticatedDevice.Set(context, new AuthenticatedDevice(device.Id, device.VaultId));

        var now = timeProvider.GetUtcNow().ToUnixTimeMilliseconds();
        if (now - device.LastSeenAtMs >= LastSeenResolution.TotalMilliseconds)
        {
            await database.Devices
                .Where(candidate => candidate.Id == device.Id)
                .ExecuteUpdateAsync(
                    setters => setters.SetProperty(candidate => candidate.LastSeenAtMs, now),
                    context.RequestAborted);
        }

        return await next(invocationContext);
    }

    private static string? ReadBearerToken(HttpRequest request)
    {
        const string scheme = "Bearer ";
        var header = request.Headers.Authorization.ToString();
        if (!header.StartsWith(scheme, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var token = header[scheme.Length..].Trim();
        return SecretTokens.LooksLikeToken(token) ? token : null;
    }
}
