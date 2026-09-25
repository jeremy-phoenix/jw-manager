using CongregationManager.Server.Configuration;
using CongregationManager.Server.Infrastructure;
using CongregationManager.Server.Infrastructure.Database;
using CongregationManager.Server.Security;
using CongregationManager.Server.Web;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Features.Devices;

internal sealed class DeviceService(
    SyncDbContext database,
    IOptions<SyncServerOptions> options,
    TimeProvider timeProvider,
    VaultLocks locks)
{
    public const int DefaultInviteMinutes = 60;
    public const int MinimumInviteMinutes = 5;
    public const int MaximumInviteMinutes = 7 * 24 * 60;
    public const int InviteCodeBytes = 24;

    private static ApiException InvalidInvite() => new(
        StatusCodes.Status401Unauthorized,
        "INVALID_INVITE",
        "The invite is invalid, expired, or has already been used.");

    private static ApiException InvalidRecoveryKey() => new(
        StatusCodes.Status401Unauthorized,
        "INVALID_RECOVERY_KEY",
        "The recovery code does not match any vault on this server.");

    public async Task<EnrollmentResponse> EnrollWithInviteAsync(
        EnrollWithInviteRequest request,
        CancellationToken cancellationToken)
    {
        Guard.RequireId(request.DeviceId, "deviceId");
        if (string.IsNullOrWhiteSpace(request.InviteCode) || !SecretTokens.LooksLikeToken(request.InviteCode))
        {
            throw InvalidInvite();
        }

        var codeHash = SecretTokens.Hash(request.InviteCode);
        var vaultId = await database.Invites
            .AsNoTracking()
            .Where(invite => invite.CodeHash == codeHash)
            .Select(invite => (Guid?)invite.VaultId)
            .SingleOrDefaultAsync(cancellationToken)
            ?? throw InvalidInvite();

        // Re-read under the vault lock so one invite can never enroll twice.
        using var vaultLock = await locks.AcquireAsync(vaultId, cancellationToken);
        var now = Now();
        var invite = await database.Invites.SingleOrDefaultAsync(
            candidate => candidate.CodeHash == codeHash,
            cancellationToken);
        if (invite is null || invite.UsedAtMs is not null || invite.ExpiresAtMs <= now)
        {
            throw InvalidInvite();
        }

        var vault = await database.Vaults
            .AsNoTracking()
            .SingleOrDefaultAsync(candidate => candidate.Id == invite.VaultId, cancellationToken)
            ?? throw InvalidInvite();
        await EnsureDeviceCapacityAsync(vault.Id, cancellationToken);

        var token = AddDevice(vault.Id, request.DeviceId, EnrollmentMethods.Invite, now);
        invite.UsedAtMs = now;
        invite.UsedByDeviceId = request.DeviceId;
        await database.SaveChangesAsync(cancellationToken);

        return new EnrollmentResponse(vault.Id, request.DeviceId, token, vault.CurrentKeyId, null);
    }

    public async Task<EnrollmentResponse> EnrollWithRecoveryAsync(
        EnrollWithRecoveryRequest request,
        CancellationToken cancellationToken)
    {
        Guard.RequireId(request.DeviceId, "deviceId");
        var authKey = Guard.RequireExactLength(
            request.RecoveryAuthKey,
            "recoveryAuthKey",
            Guard.RecoveryAuthKeyBytes);
        var authHash = SecretTokens.Hash(authKey);

        var vaultId = await database.Vaults
            .AsNoTracking()
            .Where(vault => vault.RecoveryAuthHash == authHash)
            .Select(vault => (Guid?)vault.Id)
            .SingleOrDefaultAsync(cancellationToken)
            ?? throw InvalidRecoveryKey();

        using var vaultLock = await locks.AcquireAsync(vaultId, cancellationToken);
        var vault = await database.Vaults
            .AsNoTracking()
            .SingleOrDefaultAsync(candidate => candidate.Id == vaultId, cancellationToken)
            ?? throw InvalidRecoveryKey();
        // The recovery code may have been replaced while we waited for the lock.
        Guard.RequireRecoveryProof(vault, authKey);
        await EnsureDeviceCapacityAsync(vault.Id, cancellationToken);

        var token = AddDevice(vault.Id, request.DeviceId, EnrollmentMethods.Recovery, Now());
        await database.SaveChangesAsync(cancellationToken);

        return new EnrollmentResponse(vault.Id, request.DeviceId, token, vault.CurrentKeyId, vault.RecoveryEnvelope);
    }

    public async Task<DeviceListResponse> ListAsync(AuthenticatedDevice device, CancellationToken cancellationToken)
    {
        var devices = await database.Devices
            .AsNoTracking()
            .Where(candidate => candidate.VaultId == device.VaultId && candidate.RevokedAtMs == null)
            .OrderBy(candidate => candidate.CreatedAtMs)
            .ToListAsync(cancellationToken);
        return new DeviceListResponse(devices
            .Select(candidate => new DeviceResponse(
                candidate.Id,
                candidate.Label,
                candidate.LabelKeyId,
                candidate.EnrolledVia,
                DateTimeOffset.FromUnixTimeMilliseconds(candidate.CreatedAtMs),
                DateTimeOffset.FromUnixTimeMilliseconds(candidate.LastSeenAtMs),
                candidate.Id == device.DeviceId))
            .ToList());
    }

    /// <summary>Revokes a device in the caller's vault; revoking itself signs the caller out.</summary>
    public async Task RevokeAsync(AuthenticatedDevice device, Guid targetDeviceId, CancellationToken cancellationToken)
    {
        using var vaultLock = await locks.AcquireAsync(device.VaultId, cancellationToken);
        var target = await FindActiveDeviceAsync(device.VaultId, targetDeviceId, cancellationToken);
        target.RevokedAtMs = Now();
        await database.SaveChangesAsync(cancellationToken);
    }

    public async Task SetLabelAsync(
        AuthenticatedDevice device,
        Guid targetDeviceId,
        SetDeviceLabelRequest request,
        CancellationToken cancellationToken)
    {
        var label = Guard.RequireBytes(request.Label, "label", Guard.MaxLabelBytes);
        Guard.RequireKeyId(request.KeyId);

        using var vaultLock = await locks.AcquireAsync(device.VaultId, cancellationToken);
        var target = await FindActiveDeviceAsync(device.VaultId, targetDeviceId, cancellationToken);
        target.Label = label;
        target.LabelKeyId = request.KeyId;
        await database.SaveChangesAsync(cancellationToken);
    }

    public async Task<CreateInviteResponse> CreateInviteAsync(
        AuthenticatedDevice device,
        CreateInviteRequest request,
        CancellationToken cancellationToken)
    {
        var minutes = request.ExpiresInMinutes ?? DefaultInviteMinutes;
        if (minutes is < MinimumInviteMinutes or > MaximumInviteMinutes)
        {
            throw ApiException.BadRequest(
                $"expiresInMinutes must be between {MinimumInviteMinutes} and {MaximumInviteMinutes}.");
        }

        using var vaultLock = await locks.AcquireAsync(device.VaultId, cancellationToken);
        var now = Now();
        var activeInvites = await database.Invites.CountAsync(
            invite => invite.VaultId == device.VaultId && invite.UsedAtMs == null && invite.ExpiresAtMs > now,
            cancellationToken);
        if (activeInvites >= options.Value.Limits.MaxActiveInvitesPerVault)
        {
            throw ApiException.Conflict(
                "TOO_MANY_INVITES",
                "This vault has too many unused invites. Wait for them to expire.");
        }

        var code = SecretTokens.Generate(InviteCodeBytes);
        var expiresAt = now + TimeSpan.FromMinutes(minutes).Ticks / TimeSpan.TicksPerMillisecond;
        database.Invites.Add(new Invite
        {
            Id = Guid.NewGuid(),
            VaultId = device.VaultId,
            CodeHash = SecretTokens.Hash(code),
            CreatedByDeviceId = device.DeviceId,
            CreatedAtMs = now,
            ExpiresAtMs = expiresAt,
        });
        await database.SaveChangesAsync(cancellationToken);

        return new CreateInviteResponse(code, DateTimeOffset.FromUnixTimeMilliseconds(expiresAt));
    }

    private string AddDevice(Guid vaultId, Guid deviceId, string enrolledVia, long now)
    {
        var token = SecretTokens.Generate();
        database.Devices.Add(new Device
        {
            Id = deviceId,
            VaultId = vaultId,
            TokenHash = SecretTokens.Hash(token),
            EnrolledVia = enrolledVia,
            CreatedAtMs = now,
            LastSeenAtMs = now,
        });
        return token;
    }

    private async Task EnsureDeviceCapacityAsync(Guid vaultId, CancellationToken cancellationToken)
    {
        var activeDevices = await database.Devices.CountAsync(
            device => device.VaultId == vaultId && device.RevokedAtMs == null,
            cancellationToken);
        if (activeDevices >= options.Value.Limits.MaxDevicesPerVault)
        {
            throw ApiException.Conflict(
                "TOO_MANY_DEVICES",
                "This vault already has the maximum number of devices. Remove one first.");
        }
    }

    private async Task<Device> FindActiveDeviceAsync(Guid vaultId, Guid deviceId, CancellationToken cancellationToken) =>
        await database.Devices.SingleOrDefaultAsync(
            candidate => candidate.Id == deviceId && candidate.VaultId == vaultId && candidate.RevokedAtMs == null,
            cancellationToken)
        ?? throw ApiException.NotFound("Device not found.");

    private long Now() => timeProvider.GetUtcNow().ToUnixTimeMilliseconds();
}
