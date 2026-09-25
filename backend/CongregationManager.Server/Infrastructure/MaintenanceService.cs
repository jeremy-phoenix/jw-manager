using CongregationManager.Server.Infrastructure.Database;
using Microsoft.EntityFrameworkCore;

namespace CongregationManager.Server.Infrastructure;

/// <summary>
/// Prunes bookkeeping that is only needed for a while: idempotency records
/// for old pushes and invites that were used or expired long ago.
/// </summary>
internal sealed class MaintenanceService(
    IServiceScopeFactory scopeFactory,
    TimeProvider timeProvider,
    ILogger<MaintenanceService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(6);
    private static readonly TimeSpan Retention = TimeSpan.FromDays(30);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval, timeProvider);
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await PruneAsync(stoppingToken);
            }
            catch (Exception exception) when (exception is not OperationCanceledException)
            {
                logger.LogWarning(exception, "Sync server maintenance failed; retrying next interval.");
            }
        }
    }

    internal async Task PruneAsync(CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var database = scope.ServiceProvider.GetRequiredService<SyncDbContext>();
        var now = timeProvider.GetUtcNow().ToUnixTimeMilliseconds();
        var cutoff = now - (long)Retention.TotalMilliseconds;

        var operations = await database.AppliedOperations
            .Where(operation => operation.AppliedAtMs < cutoff)
            .ExecuteDeleteAsync(cancellationToken);
        var invites = await database.Invites
            .Where(invite => invite.CreatedAtMs < cutoff && (invite.UsedAtMs != null || invite.ExpiresAtMs < now))
            .ExecuteDeleteAsync(cancellationToken);

        if (operations + invites > 0)
        {
            logger.LogInformation(
                "Pruned {Operations} applied operations and {Invites} old invites.",
                operations,
                invites);
        }
    }
}
