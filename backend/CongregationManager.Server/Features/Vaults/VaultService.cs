using System.Security.Cryptography;
using System.Text;
using CongregationManager.Server.Configuration;
using CongregationManager.Server.Infrastructure;
using CongregationManager.Server.Infrastructure.Database;
using CongregationManager.Server.Security;
using CongregationManager.Server.Web;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Features.Vaults;

internal sealed class VaultService(
    SyncDbContext database,
    IOptions<SyncServerOptions> options,
    TimeProvider timeProvider,
    VaultLocks locks)
{
    public async Task<EnrollmentResponse> CreateAsync(
        CreateVaultRequest request,
        string? registrationSecret,
        CancellationToken cancellationToken)
    {
        var registration = options.Value.Registration;
        if (!registration.IsEnabled)
        {
            throw ApiException.Forbidden(
                "REGISTRATION_DISABLED",
                "Creating vaults is disabled on this server.");
        }

        if (!SecretsMatch(registrationSecret, registration.Secret))
        {
            throw new ApiException(
                StatusCodes.Status401Unauthorized,
                "INVALID_REGISTRATION_SECRET",
                "The registration secret is incorrect.");
        }

        Guard.RequireId(request.VaultId, "vaultId");
        Guard.RequireId(request.DeviceId, "deviceId");
        Guard.RequireKeyId(request.KeyId);
        Guard.RequireExactLength(request.RecoveryAuthHash, "recoveryAuthHash", Guard.DigestBytes);
        Guard.RequireBytes(request.RecoveryEnvelope, "recoveryEnvelope", Guard.MaxEnvelopeBytes);

        var now = timeProvider.GetUtcNow().ToUnixTimeMilliseconds();
        var token = SecretTokens.Generate();
        database.Vaults.Add(new Vault
        {
            Id = request.VaultId,
            CreatedAtMs = now,
            Seq = 0,
            CurrentKeyId = request.KeyId,
            RecoveryAuthHash = request.RecoveryAuthHash,
            RecoveryEnvelope = request.RecoveryEnvelope,
        });
        database.Devices.Add(new Device
        {
            Id = request.DeviceId,
            VaultId = request.VaultId,
            TokenHash = SecretTokens.Hash(token),
            EnrolledVia = EnrollmentMethods.VaultCreation,
            CreatedAtMs = now,
            LastSeenAtMs = now,
        });
        await database.SaveChangesAsync(cancellationToken);

        return new EnrollmentResponse(request.VaultId, request.DeviceId, token, request.KeyId, null);
    }

    public async Task<VaultResponse> GetAsync(AuthenticatedDevice device, CancellationToken cancellationToken)
    {
        var vault = await database.Vaults
            .AsNoTracking()
            .SingleAsync(candidate => candidate.Id == device.VaultId, cancellationToken);
        return new VaultResponse(
            vault.Id,
            vault.CurrentKeyId,
            vault.Seq,
            vault.RecoveryEnvelope,
            DateTimeOffset.FromUnixTimeMilliseconds(vault.CreatedAtMs),
            vault.KeyRotatedAtMs is { } rotatedAt ? DateTimeOffset.FromUnixTimeMilliseconds(rotatedAt) : null);
    }

    /// <summary>
    /// Permanently erases the vault and everything in it. Requires the
    /// recovery code in addition to a device token.
    /// </summary>
    public async Task DeleteAsync(
        AuthenticatedDevice device,
        RecoveryProofRequest request,
        CancellationToken cancellationToken)
    {
        using var vaultLock = await locks.AcquireAsync(device.VaultId, cancellationToken);
        var vault = await database.Vaults
            .AsNoTracking()
            .SingleAsync(candidate => candidate.Id == device.VaultId, cancellationToken);
        Guard.RequireRecoveryProof(vault, request.RecoveryAuthKey);

        await using var transaction = await database.Database.BeginTransactionAsync(cancellationToken);
        await database.AppliedOperations.Where(row => row.VaultId == vault.Id).ExecuteDeleteAsync(cancellationToken);
        await database.Records.Where(row => row.VaultId == vault.Id).ExecuteDeleteAsync(cancellationToken);
        await database.Invites.Where(row => row.VaultId == vault.Id).ExecuteDeleteAsync(cancellationToken);
        await database.Devices.Where(row => row.VaultId == vault.Id).ExecuteDeleteAsync(cancellationToken);
        await database.Vaults.Where(row => row.Id == vault.Id).ExecuteDeleteAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    private static bool SecretsMatch(string? provided, string expected)
    {
        if (string.IsNullOrEmpty(provided))
        {
            return false;
        }

        // Compare fixed-length digests so neither content nor length leaks
        // through timing.
        return CryptographicOperations.FixedTimeEquals(
            SHA256.HashData(Encoding.UTF8.GetBytes(provided)),
            SHA256.HashData(Encoding.UTF8.GetBytes(expected)));
    }
}
