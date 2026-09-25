using System.Net;
using System.Net.Http.Json;
using System.Security.Cryptography;
using CongregationManager.Server.Features;

namespace CongregationManager.Server.Tests;

public sealed class VaultAndDeviceTests
{
    [Fact]
    public async Task HealthIsAvailableWithoutAuthentication()
    {
        await using var host = await SyncServerHost.StartAsync();
        using var client = host.CreateClient();

        using var response = await client.GetAsync("/health");

        var health = await Api.ReadAsync<HealthResponse>(response, HttpStatusCode.OK);
        Assert.Equal("ok", health.Status);
    }

    [Fact]
    public async Task VaultCreationIsDisabledWithoutConfiguredSecret()
    {
        await using var host = await SyncServerHost.StartAsync(settings =>
            settings["SyncServer:Registration:Secret"] = "");
        using var client = host.CreateClient();

        using var response = await client.SendAsync(Api.CreateVaultMessage(NewVaultRequest(), "anything-at-all-here-000"));

        await Api.AssertErrorAsync(response, HttpStatusCode.Forbidden, "REGISTRATION_DISABLED");
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("test-registration-secret-0123456788")]
    public async Task VaultCreationRejectsMissingOrWrongSecret(string? secret)
    {
        await using var host = await SyncServerHost.StartAsync();
        using var client = host.CreateClient();

        using var response = await client.SendAsync(Api.CreateVaultMessage(NewVaultRequest(), secret));

        await Api.AssertErrorAsync(response, HttpStatusCode.Unauthorized, "INVALID_REGISTRATION_SECRET");
    }

    [Fact]
    public async Task CreatedVaultIssuesAWorkingDeviceToken()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();

        using var response = await vault.Client.GetAsync("/api/v1/vault");

        var info = await Api.ReadAsync<VaultResponse>(response, HttpStatusCode.OK);
        Assert.Equal(vault.VaultId, info.VaultId);
        Assert.Equal(1, info.CurrentKeyId);
        Assert.Equal(0, info.Seq);
        Assert.Equal(vault.RecoveryEnvelope, info.RecoveryEnvelope);
    }

    [Fact]
    public async Task DuplicateVaultIdIsRejected()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        using var client = host.CreateClient();
        var duplicate = NewVaultRequest() with { VaultId = vault.VaultId };

        using var response = await client.SendAsync(Api.CreateVaultMessage(duplicate, SyncServerHost.RegistrationSecret));

        await Api.AssertErrorAsync(response, HttpStatusCode.Conflict, "CONFLICT");
    }

    [Theory]
    [InlineData(null)]
    [InlineData("Bearer ")]
    [InlineData("Bearer not-a-real-token-but-well-formed-0000")]
    [InlineData("Basic dXNlcjpwYXNz")]
    public async Task AuthenticatedEndpointsFailClosed(string? authorization)
    {
        await using var host = await SyncServerHost.StartAsync();
        await host.CreateVaultAsync();
        using var client = host.CreateClient();
        if (authorization is not null)
        {
            client.DefaultRequestHeaders.TryAddWithoutValidation("Authorization", authorization);
        }

        foreach (var path in new[] { "/api/v1/vault", "/api/v1/sync/pull", "/api/v1/devices", "/api/v1/keys/stale" })
        {
            using var response = await client.GetAsync(path);
            await Api.AssertErrorAsync(response, HttpStatusCode.Unauthorized, "UNAUTHORIZED");
        }

        using var push = await client.PostAsJsonAsync(
            "/api/v1/sync/push",
            new PushRequest([Api.Upsert(Guid.NewGuid(), 0)]),
            Api.Json);
        await Api.AssertErrorAsync(push, HttpStatusCode.Unauthorized, "UNAUTHORIZED");
    }

    [Fact]
    public async Task InviteEnrollsExactlyOneDevice()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        using var inviteResponse = await vault.Client.PostAsJsonAsync("/api/v1/invites", new CreateInviteRequest(), Api.Json);
        var invite = await Api.ReadAsync<CreateInviteResponse>(inviteResponse, HttpStatusCode.Created);
        Assert.Equal(host.Clock.Now.AddMinutes(60), invite.ExpiresAt);
        using var anonymous = host.CreateClient();

        using var first = await anonymous.PostAsJsonAsync(
            "/api/v1/devices/enroll",
            new EnrollWithInviteRequest(invite.InviteCode, Guid.NewGuid()),
            Api.Json);
        var enrollment = await Api.ReadAsync<EnrollmentResponse>(first, HttpStatusCode.Created);
        Assert.Equal(vault.VaultId, enrollment.VaultId);
        Assert.Equal(1, enrollment.CurrentKeyId);
        using var invitedClient = host.CreateClient(enrollment.DeviceToken);
        using var vaultResponse = await invitedClient.GetAsync("/api/v1/vault");
        Assert.Equal(HttpStatusCode.OK, vaultResponse.StatusCode);

        using var second = await anonymous.PostAsJsonAsync(
            "/api/v1/devices/enroll",
            new EnrollWithInviteRequest(invite.InviteCode, Guid.NewGuid()),
            Api.Json);
        await Api.AssertErrorAsync(second, HttpStatusCode.Unauthorized, "INVALID_INVITE");
    }

    [Fact]
    public async Task InviteExpires()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        using var inviteResponse = await vault.Client.PostAsJsonAsync("/api/v1/invites", new CreateInviteRequest(5), Api.Json);
        var invite = await Api.ReadAsync<CreateInviteResponse>(inviteResponse, HttpStatusCode.Created);
        host.Clock.Advance(TimeSpan.FromMinutes(6));
        using var anonymous = host.CreateClient();

        using var response = await anonymous.PostAsJsonAsync(
            "/api/v1/devices/enroll",
            new EnrollWithInviteRequest(invite.InviteCode, Guid.NewGuid()),
            Api.Json);

        await Api.AssertErrorAsync(response, HttpStatusCode.Unauthorized, "INVALID_INVITE");
    }

    [Theory]
    [InlineData(1)]
    [InlineData(4)]
    [InlineData(7 * 24 * 60 + 1)]
    public async Task InviteLifetimeIsBounded(int minutes)
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();

        using var response = await vault.Client.PostAsJsonAsync("/api/v1/invites", new CreateInviteRequest(minutes), Api.Json);

        await Api.AssertErrorAsync(response, HttpStatusCode.BadRequest, "BAD_REQUEST");
    }

    [Fact]
    public async Task UnknownInviteCodeIsRejected()
    {
        await using var host = await SyncServerHost.StartAsync();
        using var anonymous = host.CreateClient();

        using var response = await anonymous.PostAsJsonAsync(
            "/api/v1/devices/enroll",
            new EnrollWithInviteRequest("definitely-not-an-issued-invite-code", Guid.NewGuid()),
            Api.Json);

        await Api.AssertErrorAsync(response, HttpStatusCode.Unauthorized, "INVALID_INVITE");
    }

    [Fact]
    public async Task RecoveryEnrollmentReturnsTheWrappedKey()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        using var anonymous = host.CreateClient();

        using var wrong = await anonymous.PostAsJsonAsync(
            "/api/v1/recovery/enroll",
            new EnrollWithRecoveryRequest(RandomNumberGenerator.GetBytes(32), Guid.NewGuid()),
            Api.Json);
        await Api.AssertErrorAsync(wrong, HttpStatusCode.Unauthorized, "INVALID_RECOVERY_KEY");

        using var right = await anonymous.PostAsJsonAsync(
            "/api/v1/recovery/enroll",
            new EnrollWithRecoveryRequest(vault.RecoveryAuthKey, Guid.NewGuid()),
            Api.Json);
        var enrollment = await Api.ReadAsync<EnrollmentResponse>(right, HttpStatusCode.Created);
        Assert.Equal(vault.VaultId, enrollment.VaultId);
        Assert.Equal(vault.RecoveryEnvelope, enrollment.RecoveryEnvelope);
    }

    [Fact]
    public async Task RevokedDeviceLosesAccessImmediately()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var (invitedId, invitedClient) = await host.EnrollWithInviteAsync(vault);
        using var _ = invitedClient;
        var before = await vault.Client.GetFromJsonAsync<DeviceListResponse>("/api/v1/devices", Api.Json);
        Assert.Equal(2, before!.Devices.Count);
        Assert.Single(before.Devices, device => device.Current);

        using var revoke = await vault.Client.DeleteAsync($"/api/v1/devices/{invitedId}");
        Assert.Equal(HttpStatusCode.NoContent, revoke.StatusCode);

        using var denied = await invitedClient.GetAsync("/api/v1/vault");
        await Api.AssertErrorAsync(denied, HttpStatusCode.Unauthorized, "UNAUTHORIZED");
        var after = await vault.Client.GetFromJsonAsync<DeviceListResponse>("/api/v1/devices", Api.Json);
        Assert.Equal(vault.DeviceId, Assert.Single(after!.Devices).DeviceId);
    }

    [Fact]
    public async Task DevicesOfOtherVaultsCannotBeRevokedOrRelabeled()
    {
        await using var host = await SyncServerHost.StartAsync();
        var mine = await host.CreateVaultAsync();
        var theirs = await host.CreateVaultAsync();

        using var revoke = await mine.Client.DeleteAsync($"/api/v1/devices/{theirs.DeviceId}");
        await Api.AssertErrorAsync(revoke, HttpStatusCode.NotFound, "NOT_FOUND");

        using var relabel = await mine.Client.PutAsJsonAsync(
            $"/api/v1/devices/{theirs.DeviceId}/label",
            new SetDeviceLabelRequest([1, 2, 3], 1),
            Api.Json);
        await Api.AssertErrorAsync(relabel, HttpStatusCode.NotFound, "NOT_FOUND");

        using var stillWorks = await theirs.Client.GetAsync("/api/v1/vault");
        Assert.Equal(HttpStatusCode.OK, stillWorks.StatusCode);
    }

    [Fact]
    public async Task DeviceLabelIsStoredOpaquely()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        byte[] label = RandomNumberGenerator.GetBytes(64);

        using var response = await vault.Client.PutAsJsonAsync(
            $"/api/v1/devices/{vault.DeviceId}/label",
            new SetDeviceLabelRequest(label, 1),
            Api.Json);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        var devices = await vault.Client.GetFromJsonAsync<DeviceListResponse>("/api/v1/devices", Api.Json);
        var device = Assert.Single(devices!.Devices);
        Assert.Equal(label, device.Label);
        Assert.Equal(1, device.LabelKeyId);
        Assert.Equal("create", device.EnrolledVia);
    }

    [Fact]
    public async Task DeviceLimitIsEnforced()
    {
        await using var host = await SyncServerHost.StartAsync(settings =>
            settings["SyncServer:Limits:MaxDevicesPerVault"] = "2");
        var vault = await host.CreateVaultAsync();
        var (_, second) = await host.EnrollWithInviteAsync(vault);
        second.Dispose();
        using var inviteResponse = await vault.Client.PostAsJsonAsync("/api/v1/invites", new CreateInviteRequest(), Api.Json);
        var invite = await Api.ReadAsync<CreateInviteResponse>(inviteResponse, HttpStatusCode.Created);
        using var anonymous = host.CreateClient();

        using var response = await anonymous.PostAsJsonAsync(
            "/api/v1/devices/enroll",
            new EnrollWithInviteRequest(invite.InviteCode, Guid.NewGuid()),
            Api.Json);

        await Api.AssertErrorAsync(response, HttpStatusCode.Conflict, "TOO_MANY_DEVICES");
    }

    [Fact]
    public async Task DeletingTheVaultRequiresTheRecoveryCodeAndErasesIt()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        await Api.PushAsync(vault.Client, Api.Upsert(Guid.NewGuid(), 0));

        using var wrong = await vault.Client.PostAsJsonAsync(
            "/api/v1/vault/delete",
            new RecoveryProofRequest(RandomNumberGenerator.GetBytes(32)),
            Api.Json);
        await Api.AssertErrorAsync(wrong, HttpStatusCode.Forbidden, "INVALID_RECOVERY_KEY");

        using var right = await vault.Client.PostAsJsonAsync(
            "/api/v1/vault/delete",
            new RecoveryProofRequest(vault.RecoveryAuthKey),
            Api.Json);
        Assert.Equal(HttpStatusCode.NoContent, right.StatusCode);

        using var afterwards = await vault.Client.GetAsync("/api/v1/vault");
        await Api.AssertErrorAsync(afterwards, HttpStatusCode.Unauthorized, "UNAUTHORIZED");
        using var anonymous = host.CreateClient();
        using var recovery = await anonymous.PostAsJsonAsync(
            "/api/v1/recovery/enroll",
            new EnrollWithRecoveryRequest(vault.RecoveryAuthKey, Guid.NewGuid()),
            Api.Json);
        await Api.AssertErrorAsync(recovery, HttpStatusCode.Unauthorized, "INVALID_RECOVERY_KEY");
    }

    private static CreateVaultRequest NewVaultRequest() => new(
        Guid.NewGuid(),
        Guid.NewGuid(),
        1,
        RandomNumberGenerator.GetBytes(32),
        RandomNumberGenerator.GetBytes(72));
}
