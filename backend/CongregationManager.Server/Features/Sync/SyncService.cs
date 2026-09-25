using CongregationManager.Server.Configuration;
using CongregationManager.Server.Infrastructure;
using CongregationManager.Server.Infrastructure.Database;
using CongregationManager.Server.Security;
using CongregationManager.Server.Web;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Features.Sync;

/// <summary>
/// Blind change feed: stores whatever ciphertext a device sends, versioned
/// per record, and hands changes back in commit order. It never needs to know
/// the client's data model.
/// </summary>
internal sealed class SyncService(
    SyncDbContext database,
    IOptions<SyncServerOptions> options,
    TimeProvider timeProvider,
    VaultLocks locks)
{
    public const int DefaultPullPageSize = 500;

    public async Task<PushResponse> PushAsync(
        AuthenticatedDevice device,
        PushRequest request,
        CancellationToken cancellationToken)
    {
        var operations = ValidatePush(request);

        using var vaultLock = await locks.AcquireAsync(device.VaultId, cancellationToken);
        await using var transaction = await database.Database.BeginTransactionAsync(cancellationToken);

        var vault = await database.Vaults.SingleAsync(candidate => candidate.Id == device.VaultId, cancellationToken);
        if (operations.Any(operation => operation.KeyId != vault.CurrentKeyId))
        {
            throw ApiException.Conflict(
                "KEY_ROTATED",
                "The vault key was rotated. Unlock the new key on this device before syncing.");
        }

        var operationIds = operations.Select(operation => operation.OperationId).ToList();
        var alreadyApplied = await database.AppliedOperations
            .AsNoTracking()
            .Where(applied => applied.VaultId == vault.Id && operationIds.Contains(applied.OperationId))
            .ToDictionaryAsync(applied => applied.OperationId, cancellationToken);

        var recordIds = operations.Select(operation => operation.RecordId).Distinct().ToList();
        var records = await database.Records
            .Where(record => record.VaultId == vault.Id && recordIds.Contains(record.RecordId))
            .ToDictionaryAsync(record => record.RecordId, cancellationToken);

        var now = timeProvider.GetUtcNow().ToUnixTimeMilliseconds();
        var accepted = new List<AcceptedOperation>(operations.Count);
        var conflicts = new List<ConflictedOperation>();

        foreach (var operation in operations)
        {
            // A retried request after a lost response: report the original result.
            if (alreadyApplied.TryGetValue(operation.OperationId, out var previous))
            {
                accepted.Add(new AcceptedOperation(
                    operation.OperationId,
                    operation.RecordId,
                    previous.ResultVersion,
                    previous.ResultSeq));
                continue;
            }

            records.TryGetValue(operation.RecordId, out var record);
            var currentVersion = record?.Version ?? 0;
            if (currentVersion != operation.BaseVersion)
            {
                conflicts.Add(new ConflictedOperation(
                    operation.OperationId,
                    operation.RecordId,
                    currentVersion,
                    record?.Deleted ?? false,
                    record?.KeyId,
                    record?.Ciphertext));
                continue;
            }

            if (record is null && operation.Deleted)
            {
                // Deleting something the server never stored: nothing to keep.
                accepted.Add(new AcceptedOperation(operation.OperationId, operation.RecordId, 0, vault.Seq));
                continue;
            }

            if (record is null)
            {
                record = new SyncRecord { VaultId = vault.Id, RecordId = operation.RecordId };
                database.Records.Add(record);
                records[operation.RecordId] = record;
            }

            vault.Seq++;
            record.Version++;
            record.Seq = vault.Seq;
            record.Deleted = operation.Deleted;
            record.KeyId = operation.KeyId;
            record.Ciphertext = operation.Ciphertext;
            record.UpdatedAtMs = now;
            record.UpdatedByDeviceId = device.DeviceId;

            database.AppliedOperations.Add(new AppliedOperation
            {
                VaultId = vault.Id,
                OperationId = operation.OperationId,
                RecordId = operation.RecordId,
                ResultVersion = record.Version,
                ResultSeq = record.Seq,
                AppliedAtMs = now,
            });
            accepted.Add(new AcceptedOperation(operation.OperationId, operation.RecordId, record.Version, record.Seq));
        }

        await database.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return new PushResponse(accepted, conflicts);
    }

    public async Task<PullResponse> PullAsync(
        AuthenticatedDevice device,
        long? since,
        int? limit,
        CancellationToken cancellationToken)
    {
        var after = since ?? 0;
        if (after < 0)
        {
            throw ApiException.BadRequest("since must not be negative.");
        }

        var maximum = options.Value.Limits.MaxPullPageSize;
        var pageSize = limit ?? Math.Min(DefaultPullPageSize, maximum);
        if (pageSize < 1 || pageSize > maximum)
        {
            throw ApiException.BadRequest($"limit must be between 1 and {maximum}.");
        }

        var currentKeyId = await database.Vaults
            .AsNoTracking()
            .Where(vault => vault.Id == device.VaultId)
            .Select(vault => vault.CurrentKeyId)
            .SingleAsync(cancellationToken);

        var rows = await database.Records
            .AsNoTracking()
            .Where(record => record.VaultId == device.VaultId && record.Seq > after)
            .OrderBy(record => record.Seq)
            .Take(pageSize + 1)
            .Select(record => new RecordChange(
                record.RecordId,
                record.Version,
                record.Seq,
                record.Deleted,
                record.KeyId,
                record.Ciphertext))
            .ToListAsync(cancellationToken);

        var hasMore = rows.Count > pageSize;
        if (hasMore)
        {
            rows.RemoveAt(rows.Count - 1);
        }

        var nextSince = rows.Count > 0 ? rows[^1].Seq : after;
        return new PullResponse(rows, nextSince, hasMore, currentKeyId);
    }

    private List<PushOperation> ValidatePush(PushRequest request)
    {
        var limits = options.Value.Limits;
        var operations = request.Operations;
        if (operations is null || operations.Count == 0)
        {
            throw ApiException.BadRequest("operations must contain at least one operation.");
        }

        if (operations.Count > limits.MaxOperationsPerPush)
        {
            throw ApiException.BadRequest($"A push may contain at most {limits.MaxOperationsPerPush} operations.");
        }

        var seen = new HashSet<Guid>();
        foreach (var operation in operations)
        {
            if (operation is null)
            {
                throw ApiException.BadRequest("operations must not contain null entries.");
            }

            Guard.RequireId(operation.OperationId, "operationId");
            Guard.RequireId(operation.RecordId, "recordId");
            Guard.RequireKeyId(operation.KeyId);
            Guard.RequireBytes(operation.Ciphertext, "ciphertext", limits.MaxRecordBytes);
            if (operation.BaseVersion < 0)
            {
                throw ApiException.BadRequest("baseVersion must not be negative.");
            }

            if (!seen.Add(operation.OperationId))
            {
                throw ApiException.BadRequest("operationId values must be unique within a push.");
            }
        }

        return operations.ToList();
    }
}
