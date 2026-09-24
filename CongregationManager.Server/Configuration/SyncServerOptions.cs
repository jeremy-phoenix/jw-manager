using System.Net;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Configuration;

public sealed class SyncServerOptions
{
    public const string SectionName = "SyncServer";

    public DatabaseOptions Database { get; set; } = new();
    public RegistrationOptions Registration { get; set; } = new();
    public SecurityOptions Security { get; set; } = new();
    public LimitOptions Limits { get; set; } = new();
    public RateLimitOptions RateLimits { get; set; } = new();
}

public sealed class DatabaseOptions
{
    /// <summary>"Sqlite" or "Postgres".</summary>
    public string Provider { get; set; } = DatabaseProviders.Sqlite;

    public string ConnectionString { get; set; } = "";
}

public static class DatabaseProviders
{
    public const string Sqlite = "Sqlite";
    public const string Postgres = "Postgres";
}

public sealed class RegistrationOptions
{
    public const int MinimumSecretLength = 24;

    /// <summary>
    /// Shared secret required to create a new vault. Empty disables vault
    /// creation entirely; it never grants access to existing vaults.
    /// </summary>
    public string Secret { get; set; } = "";

    public bool IsEnabled => !string.IsNullOrEmpty(Secret);
}

public sealed class SecurityOptions
{
    /// <summary>
    /// Rejects API requests that did not arrive over HTTPS (directly or via a
    /// trusted reverse proxy that sets X-Forwarded-Proto).
    /// </summary>
    public bool RequireHttps { get; set; } = true;

    /// <summary>
    /// Reverse-proxy addresses allowed to set X-Forwarded-* headers in
    /// addition to loopback.
    /// </summary>
    public List<string> TrustedProxies { get; set; } = [];
}

public sealed class LimitOptions
{
    public int MaxRecordBytes { get; set; } = 256 * 1024;
    public int MaxOperationsPerPush { get; set; } = 500;
    public int MaxPullPageSize { get; set; } = 1000;
    public int MaxDevicesPerVault { get; set; } = 25;
    public int MaxActiveInvitesPerVault { get; set; } = 10;
    public long MaxRequestBodyBytes { get; set; } = 16 * 1024 * 1024;
}

public sealed class RateLimitOptions
{
    /// <summary>Per client IP, for vault creation and enrollment.</summary>
    public int AnonymousPerMinute { get; set; } = 10;

    /// <summary>Per device token, for authenticated endpoints.</summary>
    public int DevicePerMinute { get; set; } = 600;
}

internal sealed class SyncServerOptionsValidator : IValidateOptions<SyncServerOptions>
{
    public ValidateOptionsResult Validate(string? name, SyncServerOptions options)
    {
        var failures = new List<string>();

        if (options.Database.Provider is not (DatabaseProviders.Sqlite or DatabaseProviders.Postgres))
        {
            failures.Add($"SyncServer:Database:Provider must be '{DatabaseProviders.Sqlite}' or '{DatabaseProviders.Postgres}'.");
        }

        if (string.IsNullOrWhiteSpace(options.Database.ConnectionString))
        {
            failures.Add("SyncServer:Database:ConnectionString is required.");
        }

        if (options.Registration.IsEnabled
            && options.Registration.Secret.Length < RegistrationOptions.MinimumSecretLength)
        {
            failures.Add(
                $"SyncServer:Registration:Secret must be at least {RegistrationOptions.MinimumSecretLength} characters, or empty to disable vault creation.");
        }

        foreach (var proxy in options.Security.TrustedProxies)
        {
            if (!IPAddress.TryParse(proxy, out _))
            {
                failures.Add($"SyncServer:Security:TrustedProxies contains an invalid IP address: '{proxy}'.");
            }
        }

        var limits = options.Limits;
        if (limits.MaxRecordBytes is < 1024 or > 8 * 1024 * 1024)
        {
            failures.Add("SyncServer:Limits:MaxRecordBytes must be between 1 KB and 8 MB.");
        }

        if (limits.MaxOperationsPerPush is < 1 or > 5000)
        {
            failures.Add("SyncServer:Limits:MaxOperationsPerPush must be between 1 and 5000.");
        }

        if (limits.MaxPullPageSize is < 1 or > 5000)
        {
            failures.Add("SyncServer:Limits:MaxPullPageSize must be between 1 and 5000.");
        }

        if (limits.MaxDevicesPerVault < 1)
        {
            failures.Add("SyncServer:Limits:MaxDevicesPerVault must be at least 1.");
        }

        if (limits.MaxActiveInvitesPerVault < 1)
        {
            failures.Add("SyncServer:Limits:MaxActiveInvitesPerVault must be at least 1.");
        }

        if (limits.MaxRequestBodyBytes < 64 * 1024)
        {
            failures.Add("SyncServer:Limits:MaxRequestBodyBytes must be at least 64 KB.");
        }

        if (options.RateLimits.AnonymousPerMinute < 1 || options.RateLimits.DevicePerMinute < 1)
        {
            failures.Add("SyncServer:RateLimits values must be at least 1.");
        }

        return failures.Count == 0
            ? ValidateOptionsResult.Success
            : ValidateOptionsResult.Fail(failures);
    }
}
