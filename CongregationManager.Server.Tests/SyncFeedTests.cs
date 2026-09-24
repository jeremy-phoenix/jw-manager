using System.Net;
using System.Net.Http.Json;
using System.Security.Cryptography;
using CongregationManager.Server.Features;

namespace CongregationManager.Server.Tests;

public sealed class SyncFeedTests
{
    [Fact]
    public async Task PushedCiphertextComesBackUnchangedInCommitOrder()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var operations = Enumerable.Range(0, 3).Select(_ => Api.Upsert(Guid.NewGuid(), 0)).ToArray();

        var push = await Api.PushAsync(vault.Client, operations);

        Assert.Empty(push.Conflicts);
        Assert.Equal(new long[] { 1, 2, 3 }, push.Accepted.Select(accepted => accepted.Seq));
        Assert.All(push.Accepted, accepted => Assert.Equal(1, accepted.Version));

        var pull = await Api.PullAsync(vault.Client);
        Assert.False(pull.HasMore);
        Assert.Equal(3, pull.NextSince);
        Assert.Equal(1, pull.CurrentKeyId);
        Assert.Equal(operations.Select(operation => operation.RecordId), pull.Changes.Select(change => change.RecordId));
        Assert.Equal(operations.Select(operation => operation.Ciphertext), pull.Changes.Select(change => change.Ciphertext));

        var empty = await Api.PullAsync(vault.Client, pull.NextSince);
        Assert.Empty(empty.Changes);
        Assert.Equal(3, empty.NextSince);
    }

    [Fact]
    public async Task PullPagesThroughTheFeed()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        await Api.PushAsync(vault.Client, Enumerable.Range(0, 5).Select(_ => Api.Upsert(Guid.NewGuid(), 0)).ToArray());

        var seen = new List<long>();
        long since = 0;
        PullResponse page;
        do
        {
            page = await Api.PullAsync(vault.Client, since, limit: 2);
            seen.AddRange(page.Changes.Select(change => change.Seq));
            since = page.NextSince;
        }
        while (page.HasMore);

        Assert.Equal(new long[] { 1, 2, 3, 4, 5 }, seen);
    }

    [Fact]
    public async Task UpdatesMoveARecordToTheEndOfTheFeed()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var first = Guid.NewGuid();
        var second = Guid.NewGuid();
        await Api.PushAsync(vault.Client, Api.Upsert(first, 0), Api.Upsert(second, 0));

        var update = await Api.PushAsync(vault.Client, Api.Upsert(first, 1));

        Assert.Equal(2, Assert.Single(update.Accepted).Version);
        var pull = await Api.PullAsync(vault.Client, since: 1);
        Assert.Equal(new[] { second, first }, pull.Changes.Select(change => change.RecordId));
        Assert.Equal(new long[] { 1, 2 }, pull.Changes.Select(change => change.Version));
    }

    [Fact]
    public async Task StaleBaseVersionReturnsTheServerCopyAsAConflict()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var (_, otherDevice) = await host.EnrollWithInviteAsync(vault);
        using var _ = otherDevice;
        var recordId = Guid.NewGuid();
        var original = Api.Upsert(recordId, 0);
        await Api.PushAsync(vault.Client, original);

        var stale = Api.Upsert(recordId, 0);
        var response = await Api.PushAsync(otherDevice, stale);

        Assert.Empty(response.Accepted);
        var conflict = Assert.Single(response.Conflicts);
        Assert.Equal(stale.OperationId, conflict.OperationId);
        Assert.Equal(1, conflict.Version);
        Assert.False(conflict.Deleted);
        Assert.Equal(1, conflict.KeyId);
        Assert.Equal(original.Ciphertext, conflict.Ciphertext);
    }

    [Fact]
    public async Task ConflictForAMissingRecordReportsVersionZero()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();

        var response = await Api.PushAsync(vault.Client, Api.Upsert(Guid.NewGuid(), baseVersion: 4));

        var conflict = Assert.Single(response.Conflicts);
        Assert.Equal(0, conflict.Version);
        Assert.Null(conflict.Ciphertext);
    }

    [Fact]
    public async Task RetriedOperationsAreIdempotent()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var operation = Api.Upsert(Guid.NewGuid(), 0);

        var first = await Api.PushAsync(vault.Client, operation);
        var retry = await Api.PushAsync(vault.Client, operation);

        Assert.Equal(first.Accepted, retry.Accepted);
        Assert.Empty(retry.Conflicts);
        var pull = await Api.PullAsync(vault.Client);
        Assert.Single(pull.Changes);
        Assert.Equal(1, pull.NextSince);
    }

    [Fact]
    public async Task DeletesStayInTheFeedAsTombstones()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var recordId = Guid.NewGuid();
        await Api.PushAsync(vault.Client, Api.Upsert(recordId, 0));

        var deletion = Api.Delete(recordId, 1);
        var response = await Api.PushAsync(vault.Client, deletion);

        Assert.Equal(2, Assert.Single(response.Accepted).Version);
        var change = Assert.Single((await Api.PullAsync(vault.Client)).Changes);
        Assert.True(change.Deleted);
        Assert.Equal(2, change.Version);
        Assert.Equal(deletion.Ciphertext, change.Ciphertext);
    }

    [Fact]
    public async Task DeletingAnUnknownRecordIsANoOp()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();

        var response = await Api.PushAsync(vault.Client, Api.Delete(Guid.NewGuid(), 0));

        Assert.Equal(0, Assert.Single(response.Accepted).Version);
        Assert.Empty((await Api.PullAsync(vault.Client)).Changes);
    }

    [Fact]
    public async Task VaultsAreIsolatedFromEachOther()
    {
        await using var host = await SyncServerHost.StartAsync();
        var mine = await host.CreateVaultAsync();
        var theirs = await host.CreateVaultAsync();
        var sharedRecordId = Guid.NewGuid();
        await Api.PushAsync(theirs.Client, Api.Upsert(sharedRecordId, 0));

        Assert.Empty((await Api.PullAsync(mine.Client)).Changes);

        // The same record id in another vault is a different record.
        var response = await Api.PushAsync(mine.Client, Api.Upsert(sharedRecordId, 0));
        Assert.Equal(1, Assert.Single(response.Accepted).Version);
        Assert.Single((await Api.PullAsync(theirs.Client)).Changes);
    }

    [Fact]
    public async Task ConcurrentPushesKeepTheFeedGapFree()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();
        var (_, otherDevice) = await host.EnrollWithInviteAsync(vault);
        using var _ = otherDevice;

        var pushes = Enumerable.Range(0, 20).Select(index => Api.PushAsync(
            index % 2 == 0 ? vault.Client : otherDevice,
            Api.Upsert(Guid.NewGuid(), 0),
            Api.Upsert(Guid.NewGuid(), 0)));
        await Task.WhenAll(pushes);

        var pull = await Api.PullAsync(vault.Client, limit: 1000);
        Assert.Equal(Enumerable.Range(1, 40).Select(seq => (long)seq), pull.Changes.Select(change => change.Seq));
    }

    [Fact]
    public async Task PushInputIsValidated()
    {
        await using var host = await SyncServerHost.StartAsync(settings =>
        {
            settings["SyncServer:Limits:MaxOperationsPerPush"] = "3";
            settings["SyncServer:Limits:MaxRecordBytes"] = "1024";
        });
        var vault = await host.CreateVaultAsync();
        var duplicateId = Guid.NewGuid();
        PushOperation[][] invalid =
        [
            [],
            Enumerable.Range(0, 4).Select(_ => Api.Upsert(Guid.NewGuid(), 0)).ToArray(),
            [Api.Upsert(Guid.NewGuid(), 0, ciphertext: RandomNumberGenerator.GetBytes(1025))],
            [Api.Upsert(Guid.NewGuid(), 0, ciphertext: [])],
            [Api.Upsert(Guid.NewGuid(), -1)],
            [Api.Upsert(Guid.Empty, 0)],
            [Api.Upsert(Guid.NewGuid(), 0, keyId: 0)],
            [Api.Upsert(Guid.NewGuid(), 0) with { OperationId = duplicateId }, Api.Upsert(Guid.NewGuid(), 0) with { OperationId = duplicateId }],
        ];

        foreach (var operations in invalid)
        {
            using var response = await vault.Client.PostAsJsonAsync("/api/v1/sync/push", new PushRequest(operations), Api.Json);
            await Api.AssertErrorAsync(response, HttpStatusCode.BadRequest, "BAD_REQUEST");
        }

        Assert.Empty((await Api.PullAsync(vault.Client)).Changes);
    }

    [Theory]
    [InlineData("since=-1")]
    [InlineData("limit=0")]
    [InlineData("limit=100000")]
    public async Task PullPagingIsValidated(string query)
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();

        using var response = await vault.Client.GetAsync($"/api/v1/sync/pull?{query}");

        await Api.AssertErrorAsync(response, HttpStatusCode.BadRequest, "BAD_REQUEST");
    }
}
