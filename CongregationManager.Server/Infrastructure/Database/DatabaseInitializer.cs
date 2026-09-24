using CongregationManager.Server.Configuration;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CongregationManager.Server.Infrastructure.Database;

public static class DatabaseInitializer
{
    /// <summary>
    /// Bump when the model changes and add the matching upgrade step to
    /// <see cref="UpgradeAsync"/>.
    /// </summary>
    public const int CurrentSchemaVersion = 1;

    private const string SchemaTable = "cm_schema_info";

    public static async Task InitializeDatabaseAsync(
        this IServiceProvider services,
        CancellationToken cancellationToken)
    {
        await using var scope = services.CreateAsyncScope();
        var options = scope.ServiceProvider.GetRequiredService<IOptions<SyncServerOptions>>().Value;
        var database = scope.ServiceProvider.GetRequiredService<SyncDbContext>();
        var logger = scope.ServiceProvider
            .GetRequiredService<ILoggerFactory>()
            .CreateLogger(typeof(DatabaseInitializer));

        var isSqlite = options.Database.Provider == DatabaseProviders.Sqlite;
        if (isSqlite)
        {
            EnsureSqliteDirectoryExists(options.Database.ConnectionString);
        }

        if (!await SchemaTableExistsAsync(database, isSqlite, cancellationToken))
        {
            // The script only creates this server's cm_* tables, so a shared
            // PostgreSQL database with unrelated tables is left alone. Both
            // providers support transactional DDL, so a crash cannot leave a
            // half-created schema behind.
            await using var transaction = await database.Database.BeginTransactionAsync(cancellationToken);
            await database.Database.ExecuteSqlRawAsync(
                database.Database.GenerateCreateScript(),
                cancellationToken);
            database.SchemaInfo.Add(new SchemaInfo { Id = 1, Version = CurrentSchemaVersion });
            await database.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            logger.LogInformation("Created sync database schema version {Version}.", CurrentSchemaVersion);
        }
        else
        {
            await UpgradeAsync(database, logger, cancellationToken);
        }

        if (isSqlite)
        {
            // WAL lets pulls read while a push transaction is writing.
            await database.Database.ExecuteSqlRawAsync("PRAGMA journal_mode=WAL;", cancellationToken);
        }
    }

    private static async Task UpgradeAsync(
        SyncDbContext database,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        var info = await database.SchemaInfo.SingleAsync(cancellationToken);
        if (info.Version > CurrentSchemaVersion)
        {
            throw new InvalidOperationException(
                $"The database schema (version {info.Version}) is newer than this server supports "
                + $"(version {CurrentSchemaVersion}). Upgrade the server.");
        }

        // Future schema changes: run each step for info.Version < N inside a
        // transaction, then store the new version.
        if (info.Version < CurrentSchemaVersion)
        {
            info.Version = CurrentSchemaVersion;
            await database.SaveChangesAsync(cancellationToken);
            logger.LogInformation("Upgraded sync database schema to version {Version}.", CurrentSchemaVersion);
        }
    }

    private static async Task<bool> SchemaTableExistsAsync(
        SyncDbContext database,
        bool isSqlite,
        CancellationToken cancellationToken)
    {
        var count = isSqlite
            ? await database.Database
                .SqlQuery<int>($"SELECT COUNT(*) AS \"Value\" FROM sqlite_master WHERE type = 'table' AND name = {SchemaTable}")
                .SingleAsync(cancellationToken)
            : await database.Database
                .SqlQuery<int>($"SELECT COUNT(*)::int AS \"Value\" FROM information_schema.tables WHERE table_schema = current_schema() AND table_name = {SchemaTable}")
                .SingleAsync(cancellationToken);
        return count > 0;
    }

    private static void EnsureSqliteDirectoryExists(string connectionString)
    {
        var dataSource = new SqliteConnectionStringBuilder(connectionString).DataSource;
        if (string.IsNullOrWhiteSpace(dataSource)
            || dataSource == ":memory:"
            || dataSource.StartsWith("file:", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var directory = Path.GetDirectoryName(Path.GetFullPath(dataSource));
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }
    }
}
