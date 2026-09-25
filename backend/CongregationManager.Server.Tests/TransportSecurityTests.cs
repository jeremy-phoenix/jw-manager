using System.Net;
using System.Security.Cryptography;
using System.Text.Json;
using CongregationManager.Server.Features;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Tests;

public sealed class TransportSecurityTests
{
    [Fact]
    public async Task ResponsesAreMarkedNonCacheable()
    {
        await using var host = await SyncServerHost.StartAsync();
        var vault = await host.CreateVaultAsync();

        using var response = await vault.Client.GetAsync("/api/v1/vault");
        using var failure = await host.CreateClient().GetAsync("/api/v1/vault");

        foreach (var message in new[] { response, failure })
        {
            Assert.True(message.Headers.CacheControl?.NoStore, $"{message.RequestMessage?.RequestUri} is cacheable.");
        }

        Assert.Equal("nosniff", response.Headers.GetValues("X-Content-Type-Options").Single());
    }

    [Fact]
    public async Task PlainHttpIsRejectedWhenHttpsIsRequired()
    {
        await using var host = await SyncServerHost.StartAsync(settings =>
            settings["SyncServer:Security:RequireHttps"] = "true");
        using var client = host.CreateClient();

        using var api = await client.GetAsync("/api/v1/vault");
        await Api.AssertErrorAsync(api, HttpStatusCode.BadRequest, "HTTPS_REQUIRED");

        using var health = await client.GetAsync("/health");
        Assert.Equal(HttpStatusCode.OK, health.StatusCode);
    }

    [Fact]
    public async Task OnlyTrustedProxiesCanVouchForHttps()
    {
        await using var host = await SyncServerHost.StartAsync(settings =>
            settings["SyncServer:Security:RequireHttps"] = "true");

        var viaLocalProxy = await SendViaProxyAsync(host, IPAddress.Loopback);
        var viaUnknownHost = await SendViaProxyAsync(host, IPAddress.Parse("203.0.113.9"));

        // Past the HTTPS check, the missing device token is what fails.
        Assert.Equal((StatusCodes.Status401Unauthorized, "UNAUTHORIZED"), viaLocalProxy);
        Assert.Equal((StatusCodes.Status400BadRequest, "HTTPS_REQUIRED"), viaUnknownHost);
    }

    [Fact]
    public async Task AnonymousEndpointsAreRateLimitedPerClient()
    {
        await using var host = await SyncServerHost.StartAsync(settings =>
            settings["SyncServer:RateLimits:AnonymousPerMinute"] = "2");
        using var client = host.CreateClient();
        var statuses = new List<HttpStatusCode>();

        for (var attempt = 0; attempt < 3; attempt++)
        {
            var request = new CreateVaultRequest(
                Guid.NewGuid(),
                Guid.NewGuid(),
                1,
                RandomNumberGenerator.GetBytes(32),
                RandomNumberGenerator.GetBytes(72));
            using var response = await client.SendAsync(Api.CreateVaultMessage(request, "wrong-secret-guess-000000000"));
            statuses.Add(response.StatusCode);
        }

        Assert.Equal(
            [HttpStatusCode.Unauthorized, HttpStatusCode.Unauthorized, HttpStatusCode.TooManyRequests],
            statuses);
    }

    [Theory]
    [InlineData("SyncServer:Registration:Secret", "too-short")]
    [InlineData("SyncServer:Database:Provider", "SqlServer")]
    [InlineData("SyncServer:Security:TrustedProxies:0", "not-an-ip")]
    public async Task UnsafeConfigurationFailsAtStartup(string key, string value)
    {
        await Assert.ThrowsAsync<OptionsValidationException>(async () =>
        {
            await using var host = await SyncServerHost.StartAsync(settings => settings[key] = value);
        });
    }

    private static async Task<(int Status, string? Code)> SendViaProxyAsync(SyncServerHost host, IPAddress proxy)
    {
        var context = await host.Server.SendAsync(http =>
        {
            http.Connection.RemoteIpAddress = proxy;
            http.Request.Method = HttpMethods.Get;
            http.Request.Path = "/api/v1/vault";
            http.Request.Headers["X-Forwarded-Proto"] = "https";
            http.Request.Headers["X-Forwarded-For"] = "198.51.100.7";
        });
        using var document = await JsonDocument.ParseAsync(context.Response.Body);
        return (context.Response.StatusCode, document.RootElement.GetProperty("code").GetString());
    }
}
