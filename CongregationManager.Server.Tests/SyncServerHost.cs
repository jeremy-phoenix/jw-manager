using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text.Json;
using CongregationManager.Server.Features;
using CongregationManager.Server.Infrastructure;
using CongregationManager.Server.Infrastructure.Database;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace CongregationManager.Server.Tests;

internal sealed class MutableTimeProvider(DateTimeOffset start) : TimeProvider
{
    public DateTimeOffset Now { get; set; } = start;

    public override DateTimeOffset GetUtcNow() => Now;

    public void Advance(TimeSpan duration) => Now += duration;
}

/// <summary>Runs the real pipeline on TestHost against a throwaway SQLite file.</summary>
internal sealed class SyncServerHost : IAsyncDisposable
{
    public const string RegistrationSecret = "test-registration-secret-0123456789";

    private readonly WebApplication application;
    private readonly string databasePath;

    private SyncServerHost(WebApplication application, string databasePath, MutableTimeProvider clock)
    {
        this.application = application;
        this.databasePath = databasePath;
        Clock = clock;
    }

    public MutableTimeProvider Clock { get; }

    public TestServer Server => application.GetTestServer();

    public static async Task<SyncServerHost> StartAsync(Action<IDictionary<string, string?>>? configure = null)
    {
        var databasePath = Path.Combine(Path.GetTempPath(), $"cm-sync-tests-{Guid.NewGuid():N}.db");
        var settings = new Dictionary<string, string?>
        {
            ["SyncServer:Database:Provider"] = "Sqlite",
            ["SyncServer:Database:ConnectionString"] = $"Data Source={databasePath};Pooling=False",
            ["SyncServer:Registration:Secret"] = RegistrationSecret,
            ["SyncServer:Security:RequireHttps"] = "false",
            ["SyncServer:RateLimits:AnonymousPerMinute"] = "1000",
            ["SyncServer:RateLimits:DevicePerMinute"] = "10000",
        };
        configure?.Invoke(settings);

        var builder = WebApplication.CreateBuilder(new WebApplicationOptions
        {
            EnvironmentName = "Testing",
            ContentRootPath = AppContext.BaseDirectory,
        });
        builder.Configuration.AddInMemoryCollection(settings);
        builder.AddSyncServer();
        builder.WebHost.UseTestServer();
        builder.Logging.ClearProviders();
        var clock = new MutableTimeProvider(new DateTimeOffset(2026, 9, 1, 12, 0, 0, TimeSpan.Zero));
        builder.Services.AddSingleton<TimeProvider>(clock);

        var application = builder.Build();
        application.UseSyncServerPipeline();
        application.MapSyncServerApi();
        try
        {
            await application.Services.InitializeDatabaseAsync(CancellationToken.None);
            await application.StartAsync();
        }
        catch
        {
            await application.DisposeAsync();
            DeleteDatabaseFiles(databasePath);
            throw;
        }

        return new SyncServerHost(application, databasePath, clock);
    }

    public HttpClient CreateClient(string? token = null)
    {
        var client = application.GetTestClient();
        if (token is not null)
        {
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        return client;
    }

    public async Task<TestVault> CreateVaultAsync()
    {
        var recoveryAuthKey = RandomNumberGenerator.GetBytes(32);
        var request = new CreateVaultRequest(
            Guid.NewGuid(),
            Guid.NewGuid(),
            1,
            SHA256.HashData(recoveryAuthKey),
            RandomNumberGenerator.GetBytes(72));
        using var client = CreateClient();
        using var response = await client.SendAsync(Api.CreateVaultMessage(request, RegistrationSecret));
        var enrollment = await Api.ReadAsync<EnrollmentResponse>(response, HttpStatusCode.Created);
        return new TestVault(
            request.VaultId,
            request.DeviceId,
            enrollment.DeviceToken,
            recoveryAuthKey,
            request.RecoveryEnvelope,
            CreateClient(enrollment.DeviceToken));
    }

    public async Task<(Guid DeviceId, HttpClient Client)> EnrollWithInviteAsync(TestVault vault)
    {
        using var inviteResponse = await vault.Client.PostAsJsonAsync("/api/v1/invites", new CreateInviteRequest(60), Api.Json);
        var invite = await Api.ReadAsync<CreateInviteResponse>(inviteResponse, HttpStatusCode.Created);
        var deviceId = Guid.NewGuid();
        using var anonymous = CreateClient();
        using var enrollResponse = await anonymous.PostAsJsonAsync(
            "/api/v1/devices/enroll",
            new EnrollWithInviteRequest(invite.InviteCode, deviceId),
            Api.Json);
        var enrollment = await Api.ReadAsync<EnrollmentResponse>(enrollResponse, HttpStatusCode.Created);
        return (deviceId, CreateClient(enrollment.DeviceToken));
    }

    public async ValueTask DisposeAsync()
    {
        await application.StopAsync();
        await application.DisposeAsync();
        DeleteDatabaseFiles(databasePath);
    }

    private static void DeleteDatabaseFiles(string path)
    {
        SqliteConnection.ClearAllPools();
        foreach (var file in new[] { path, $"{path}-wal", $"{path}-shm" })
        {
            try
            {
                File.Delete(file);
            }
            catch (IOException)
            {
                // Best effort: a leftover temp file must not fail a test.
            }
        }
    }
}

internal sealed record TestVault(
    Guid VaultId,
    Guid DeviceId,
    string Token,
    byte[] RecoveryAuthKey,
    byte[] RecoveryEnvelope,
    HttpClient Client);

internal static class Api
{
    public static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    public static HttpRequestMessage CreateVaultMessage(CreateVaultRequest request, string? secret)
    {
        var message = new HttpRequestMessage(HttpMethod.Post, "/api/v1/vaults")
        {
            Content = JsonContent.Create(request, options: Json),
        };
        if (secret is not null)
        {
            message.Headers.Add("X-Registration-Secret", secret);
        }

        return message;
    }

    public static async Task<T> ReadAsync<T>(HttpResponseMessage response, HttpStatusCode expected)
    {
        var body = await response.Content.ReadAsStringAsync();
        Assert.True(expected == response.StatusCode, $"Expected {expected} but got {response.StatusCode}: {body}");
        return JsonSerializer.Deserialize<T>(body, Json)!;
    }

    public static async Task AssertErrorAsync(HttpResponseMessage response, HttpStatusCode expected, string code)
    {
        var body = await response.Content.ReadAsStringAsync();
        Assert.True(expected == response.StatusCode, $"Expected {expected} but got {response.StatusCode}: {body}");
        using var document = JsonDocument.Parse(body);
        Assert.Equal(code, document.RootElement.GetProperty("code").GetString());
    }

    public static PushOperation Upsert(Guid recordId, long baseVersion, int keyId = 1, byte[]? ciphertext = null) =>
        new(Guid.NewGuid(), recordId, baseVersion, false, keyId, ciphertext ?? RandomNumberGenerator.GetBytes(48));

    public static PushOperation Delete(Guid recordId, long baseVersion, int keyId = 1) =>
        new(Guid.NewGuid(), recordId, baseVersion, true, keyId, RandomNumberGenerator.GetBytes(40));

    public static async Task<PushResponse> PushAsync(HttpClient client, params PushOperation[] operations)
    {
        using var response = await client.PostAsJsonAsync("/api/v1/sync/push", new PushRequest(operations), Json);
        return await ReadAsync<PushResponse>(response, HttpStatusCode.OK);
    }

    public static async Task<PullResponse> PullAsync(HttpClient client, long since = 0, int? limit = null)
    {
        var url = $"/api/v1/sync/pull?since={since}" + (limit is null ? "" : $"&limit={limit}");
        using var response = await client.GetAsync(url);
        return await ReadAsync<PullResponse>(response, HttpStatusCode.OK);
    }
}
