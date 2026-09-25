using CongregationManager.Server.Configuration;
using CongregationManager.Server.Infrastructure;
using CongregationManager.Server.Infrastructure.Database;
using CongregationManager.Server.Security;
using CongregationManager.Server.Web;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Features.Keys;

/// <summary>
/// Key rotation after a device is lost: the client switches the vault to a
/// new key (proving it knows the recovery code), then re-encrypts every
/// record still sealed with an older key.
/// </summary>
internal sealed class KeyService(
    SyncDbContext database,
    IOptions<SyncServerOptions> options,
    TimeProvider timeProvider,
    VaultLocks locks)
{
    public const int DefaultStalePageSize = 200;
    public const int MaxStalePageSize = 500;

    public async Task<RotateKeyResponse> RotateAsync(
        AuthenticatedDevice device,
        RotateKeyRequest request,
        CancellationToken cancellationToken)
    {
        Guard.RequireKeyId(request.NewKeyId, "newKeyId");
        Guard.RequireBytes(request.RecoveryEnvelope, "recoveryEnvelope", Guard.MaxEnvelopeBytes);
        if (request.NewRecoveryAuthHash is not null)
        {
            Guard.RequireExactLength(request.NewRecoveryAuthHash, "newRecoveryAuthHash", Guard.DigestBytes);
        }

        using var vaultLock = await locks.AcquireAsync(device.VaultId, cancellationToken);
        await using var transaction = await database.Database.BeginTransactionAsync(cancellationToken);
        var vault = await database.Vaults.SingleAsync(candidate => candidate.Id == device.VaultId, cancellationToken);
        Guard.RequireRecoveryProof(vault, request.RecoveryAuthKey);

        if (request.NewKeyId != vault.CurrentKeyId + 1)
        {
            throw ApiException.Conflict(
                "KEY_ID_MISMATCH",
                $"The next key id must be {vault.CurrentKeyId + 1}.");
        }

        var now = timeProvider.GetUtcNow().ToUnixTimeMilliseconds();
        vault.CurrentKeyId = request.NewKeyId;
        vault.RecoveryEnvelope = request.RecoveryEnvelope;
        vault.KeyRotatedAtMs = now;
        if (request.NewRecoveryAuthHash is not null)
        {
            vault.RecoveryAuthHash = request.NewRecoveryAuthHash;
        }

        // Unused invites carry the old key; they must not enroll new devices.
        await database.Invites
            .Where(invite => invite.VaultId == vault.Id && invite.UsedAtMs == null)
            .ExecuteDeleteAsync(cancellationToken);

        await database.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return new RotateKeyResponse(vault.CurrentKeyId);
    }

    public async Task<StaleRecordsResponse> GetStaleAsync(
        AuthenticatedDevice device,
        int? limit,
        CancellationToken cancellationToken)
    {
        var pageSize = limit ?? DefaultStalePageSize;
        if (pageSize is < 1 or > MaxStalePageSize)
        {
            throw ApiException.BadRequest($"limit must be between 1 and {MaxStalePageSize}.");
        }

        var currentKeyId = await database.Vaults
            .AsNoTracking()
            .Where(vault => vault.Id == device.VaultId)
            .Select(vault => vault.CurrentKeyId)
            .SingleAsync(cancellationToken);

        var records = await database.Records
            .AsNoTracking()
            .Where(record => record.VaultId == device.VaultId && record.KeyId != currentKeyId)
            .OrderBy(record => record.Seq)
            .Take(pageSize)
            .Select(record => new StaleRecord(record.RecordId, record.Version, record.KeyId, record.Ciphertext))
            .ToListAsync(cancellationToken);

        return new StaleRecordsResponse(records, currentKeyId);
    }

    /// <summary>
    /// Replaces ciphertext in place. Versions and sequence numbers do not
    /// change: the content is the same, so devices that already have it do
    /// not download it again. Records changed since they were read are
    /// skipped; the client re-reads and retries them.
    /// </summary>
    public async Task<RekeyResponse> RekeyAsync(
        AuthenticatedDevice device,
        RekeyRequest request,
        CancellationToken cancellationToken)
    {
        var items = request.Records;
        if (items is null || items.Count == 0)
        {
            throw ApiException.BadRequest("records must contain at least one record.");
        }

        if (items.Count > MaxStalePageSize)
        {
            throw ApiException.BadRequest($"A rekey request may contain at most {MaxStalePageSize} records.");
        }

        var maxRecordBytes = options.Value.Limits.MaxRecordBytes;
        foreach (var item in items)
        {
            if (item is null)
            {
                throw ApiException.BadRequest("records must not contain null entries.");
            }

            Guard.RequireId(item.RecordId, "recordId");
            Guard.RequireKeyId(item.KeyId);
            Guard.RequireBytes(item.Ciphertext, "ciphertext", maxRecordBytes);
        }

        using var vaultLock = await locks.AcquireAsync(device.VaultId, cancellationToken);
        await using var transaction = await database.Database.BeginTransactionAsync(cancellationToken);
        var currentKeyId = await database.Vaults
            .Where(vault => vault.Id == device.VaultId)
            .Select(vault => vault.CurrentKeyId)
            .SingleAsync(cancellationToken);
        if (items.Any(item => item.KeyId != currentKeyId))
        {
            throw ApiException.Conflict(
                "KEY_ROTATED",
                "Records must be re-encrypted with the vault's current key.");
        }

        var recordIds = items.Select(item => item.RecordId).Distinct().ToList();
        var records = await database.Records
            .Where(record => record.VaultId == device.VaultId && recordIds.Contains(record.RecordId))
            .ToDictionaryAsync(record => record.RecordId, cancellationToken);

        var updated = 0;
        var skipped = new List<Guid>();
        foreach (var item in items)
        {
            if (records.TryGetValue(item.RecordId, out var record) && record.Version == item.Version)
            {
                record.KeyId = item.KeyId;
                record.Ciphertext = item.Ciphertext;
                updated++;
            }
            else
            {
                skipped.Add(item.RecordId);
            }
        }

        await database.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return new RekeyResponse(updated, skipped);
    }
}
