using System.Net;
using System.Net.Http.Json;
using System.Security.Cryptography;
using CongregationManager.Server.Features;

namespace CongregationManager.Server.Tests;

public sealed class KeyRotationTests
{
    [Fact]
    public async Task RotationRequiresTheRecoveryCodeAndTheNextKeyId()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();

        using var wrongCode = await RotateAsync(vault, RandomNumberGenerator.GetBytes(32), 2);
        await Api.AssertErrorAsync(wrongCode, HttpStatusCode.Forbidden, "INVALID_RECOVERY_KEY");

        using var skippedKey = await RotateAsync(vault, vault.RecoveryAuthKey, 3);
        await Api.AssertErrorAsync(skippedKey, HttpStatusCode.Conflict, "KEY_ID_MISMATCH");

        var info = await vault.Client.GetFromJsonAsync<VaultResponse>("/api/v1/vault", Api.Json);
        Assert.Equal(1, info!.CurrentKeyId);
    }

    [Fact]
    public async Task RotationFencesTheOldKeyUntilRecordsAreRekeyed()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var records = Enumerable.Range(0, 3).Select(_ => Api.Upsert(Guid.NewGuid(), 0)).ToArray();
        await Api.PushAsync(vault.Client, records);

        using var rotated = await RotateAsync(vault, vault.RecoveryAuthKey, 2);
        Assert.Equal(2, (await Api.ReadAsync<RotateKeyResponse>(rotated, HttpStatusCode.OK)).CurrentKeyId);

        using var oldKeyPush = await vault.Client.PostAsJsonAsync(
            "/api/v1/sync/push",
            new PushRequest([Api.Upsert(Guid.NewGuid(), 0, keyId: 1)]),
            Api.Json);
        await Api.AssertErrorAsync(oldKeyPush, HttpStatusCode.Conflict, "KEY_ROTATED");

        var stale = await vault.Client.GetFromJsonAsync<StaleRecordsResponse>("/api/v1/keys/stale", Api.Json);
        Assert.Equal(2, stale!.CurrentKeyId);
        Assert.Equal(records.Select(record => record.RecordId), stale.Records.Select(record => record.RecordId));

        var rekeyed = stale.Records
            .Select(record => new RekeyRecord(record.RecordId, record.Version, 2, RandomNumberGenerator.GetBytes(48)))
            .ToList();
        using var rekeyResponse = await vault.Client.PostAsJsonAsync("/api/v1/keys/rekey", new RekeyRequest(rekeyed), Api.Json);
        var rekey = await Api.ReadAsync<RekeyResponse>(rekeyResponse, HttpStatusCode.OK);
        Assert.Equal(3, rekey.Updated);
        Assert.Empty(rekey.Skipped);

        var after = await vault.Client.GetFromJsonAsync<StaleRecordsResponse>("/api/v1/keys/stale", Api.Json);
        Assert.Empty(after!.Records);

        // Re-encryption changes neither versions nor the change feed.
        var pull = await Api.PullAsync(vault.Client);
        Assert.Equal(new long[] { 1, 2, 3 }, pull.Changes.Select(change => change.Seq));
        Assert.All(pull.Changes, change => Assert.Equal(1, change.Version));
        Assert.All(pull.Changes, change => Assert.Equal(2, change.KeyId));
        Assert.Equal(rekeyed.Select(record => record.Ciphertext), pull.Changes.Select(change => change.Ciphertext));

        var newKeyPush = await Api.PushAsync(vault.Client, Api.Upsert(Guid.NewGuid(), 0, keyId: 2));
        Assert.Single(newKeyPush.Accepted);
    }

    [Fact]
    public async Task RekeySkipsRecordsThatChangedMeanwhile()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var recordId = Guid.NewGuid();
        await Api.PushAsync(vault.Client, Api.Upsert(recordId, 0));
        using var rotated = await RotateAsync(vault, vault.RecoveryAuthKey, 2);
        Assert.Equal(HttpStatusCode.OK, rotated.StatusCode);
        await Api.PushAsync(vault.Client, Api.Upsert(recordId, 1, keyId: 2));

        using var response = await vault.Client.PostAsJsonAsync(
            "/api/v1/keys/rekey",
            new RekeyRequest([new RekeyRecord(recordId, 1, 2, RandomNumberGenerator.GetBytes(48))]),
            Api.Json);

        var rekey = await Api.ReadAsync<RekeyResponse>(response, HttpStatusCode.OK);
        Assert.Equal(0, rekey.Updated);
        Assert.Equal(recordId, Assert.Single(rekey.Skipped));
    }

    [Fact]
    public async Task RekeyMustUseTheCurrentKey()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var recordId = Guid.NewGuid();
        await Api.PushAsync(vault.Client, Api.Upsert(recordId, 0));

        using var response = await vault.Client.PostAsJsonAsync(
            "/api/v1/keys/rekey",
            new RekeyRequest([new RekeyRecord(recordId, 1, 5, RandomNumberGenerator.GetBytes(48))]),
            Api.Json);

        await Api.AssertErrorAsync(response, HttpStatusCode.Conflict, "KEY_ROTATED");
    }

    [Fact]
    public async Task RotationRevokesUnusedInvitesAndCanReplaceTheRecoveryCode()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        using var inviteResponse = await vault.Client.PostAsJsonAsync("/api/v1/invites", new CreateInviteRequest(), Api.Json);
        var invite = await Api.ReadAsync<CreateInviteResponse>(inviteResponse, HttpStatusCode.Created);
        var newRecoveryAuthKey = RandomNumberGenerator.GetBytes(32);
        var newEnvelope = RandomNumberGenerator.GetBytes(72);

        using var rotated = await vault.Client.PostAsJsonAsync(
            "/api/v1/keys/rotate",
            new RotateKeyRequest(vault.RecoveryAuthKey, 2, newEnvelope, SHA256.HashData(newRecoveryAuthKey)),
            Api.Json);
        Assert.Equal(HttpStatusCode.OK, rotated.StatusCode);

        using var anonymous = host.CreateClient();
        using var withInvite = await anonymous.PostAsJsonAsync(
            "/api/v1/devices/enroll",
            new EnrollWithInviteRequest(invite.InviteCode, Guid.NewGuid()),
            Api.Json);
        await Api.AssertErrorAsync(withInvite, HttpStatusCode.Unauthorized, "INVALID_INVITE");

        using var withOldCode = await anonymous.PostAsJsonAsync(
            "/api/v1/recovery/enroll",
            new EnrollWithRecoveryRequest(vault.RecoveryAuthKey, Guid.NewGuid()),
            Api.Json);
        await Api.AssertErrorAsync(withOldCode, HttpStatusCode.Unauthorized, "INVALID_RECOVERY_KEY");

        using var withNewCode = await anonymous.PostAsJsonAsync(
            "/api/v1/recovery/enroll",
            new EnrollWithRecoveryRequest(newRecoveryAuthKey, Guid.NewGuid()),
            Api.Json);
        var enrollment = await Api.ReadAsync<EnrollmentResponse>(withNewCode, HttpStatusCode.Created);
        Assert.Equal(2, enrollment.CurrentKeyId);
        Assert.Equal(newEnvelope, enrollment.RecoveryEnvelope);
    }

    private static Task<HttpResponseMessage> RotateAsync(TestVault vault, byte[] recoveryAuthKey, int newKeyId) =>
        vault.Client.PostAsJsonAsync(
            "/api/v1/keys/rotate",
            new RotateKeyRequest(recoveryAuthKey, newKeyId, RandomNumberGenerator.GetBytes(72)),
            Api.Json);
}
