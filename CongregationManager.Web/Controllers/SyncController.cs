using CongregationManager.DataTransfer;
using CongregationManager.Web.Services;
using Microsoft.AspNetCore.Mvc;

namespace CongregationManager.Web.Controllers;

[ApiController]
[Route("api/v1/sync")]
public sealed class SyncController : ControllerBase
{
    private readonly CloudSyncService _syncService;
    private readonly IConfiguration _configuration;

    public SyncController(CloudSyncService syncService, IConfiguration configuration)
    {
        _syncService = syncService;
        _configuration = configuration;
    }

    [HttpPost("push")]
    public async Task<ActionResult<SyncPushResponse>> Push(
        [FromBody] SyncPushRequest request,
        CancellationToken cancellationToken)
    {
        if (!IsAuthorized())
            return Unauthorized();

        return Ok(await _syncService.PushAsync(request, cancellationToken));
    }

    [HttpGet("pull")]
    public async Task<ActionResult<SyncPullResponse>> Pull(
        [FromQuery] string? cursor,
        CancellationToken cancellationToken)
    {
        if (!IsAuthorized())
            return Unauthorized();

        return Ok(await _syncService.PullAsync(cursor, cancellationToken));
    }

    [HttpGet("bootstrap")]
    public async Task<ActionResult<SyncPullResponse>> Bootstrap(CancellationToken cancellationToken)
    {
        if (!IsAuthorized())
            return Unauthorized();

        return Ok(await _syncService.PullAsync(null, cancellationToken));
    }

    private bool IsAuthorized()
    {
        var configuredSecret = _configuration.GetValue<string>("Sync:SharedSecret");
        if (string.IsNullOrWhiteSpace(configuredSecret))
            return true;

        var token = Request.Headers.Authorization.ToString();
        const string bearerPrefix = "Bearer ";
        if (token.StartsWith(bearerPrefix, StringComparison.OrdinalIgnoreCase))
            token = token[bearerPrefix.Length..];

        if (string.IsNullOrWhiteSpace(token))
            token = Request.Headers["X-Sync-Token"].ToString();

        return string.Equals(token, configuredSecret, StringComparison.Ordinal);
    }
}
