using System.Data;
using System.Data.Common;
using Microsoft.EntityFrameworkCore;
using CongregationManager.Data;
using Serilog;

namespace CongregationManager.Web.Services;

public static class DatabaseMigrator
{
    private const string TrackingTable = "__applied_migrations";

    public static void Run(FieldServiceDbContext context, string scriptsBasePath)
    {
        // Create database + full schema from the current model if it doesn't exist.
        // Returns true when the database was just created (all tables present).
        bool freshDatabase = context.Database.EnsureCreated();

        var connection = context.Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
            connection.Open();

        EnsureTrackingTable(connection);

        // Pick provider-specific scripts folder
        var subfolder = context.Database.IsNpgsql() ? "pgsql" : "sqlite";
        var scriptsPath = Path.Combine(scriptsBasePath, subfolder);

        if (!Directory.Exists(scriptsPath))
            return;

        var scripts = Directory.GetFiles(scriptsPath, "*.sql")
            .OrderBy(Path.GetFileName)
            .ToList();

        foreach (var filePath in scripts)
        {
            var name = Path.GetFileName(filePath);

            if (IsApplied(connection, name))
                continue;

            if (!freshDatabase)
            {
                var sql = File.ReadAllText(filePath);
                if (!string.IsNullOrWhiteSpace(sql))
                {
                    Execute(connection, sql);
                    Log.Information("Applied SQL migration: {Script}", name);
                }
            }
            else
            {
                Log.Information("Recorded SQL migration (fresh database): {Script}", name);
            }

            RecordApplied(connection, name);
        }
    }

    private static void EnsureTrackingTable(DbConnection connection)
    {
        Execute(connection, $"""
            CREATE TABLE IF NOT EXISTS "{TrackingTable}" (
                "script_name" TEXT PRIMARY KEY,
                "applied_at" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """);
    }

    private static bool IsApplied(DbConnection connection, string name)
    {
        using var cmd = connection.CreateCommand();
        cmd.CommandText = $"""SELECT COUNT(*) FROM "{TrackingTable}" WHERE "script_name" = @n""";
        AddParam(cmd, "n", name);
        return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
    }

    private static void RecordApplied(DbConnection connection, string name)
    {
        using var cmd = connection.CreateCommand();
        cmd.CommandText = $"""INSERT INTO "{TrackingTable}" ("script_name") VALUES (@n)""";
        AddParam(cmd, "n", name);
        cmd.ExecuteNonQuery();
    }

    private static void Execute(DbConnection connection, string sql)
    {
        using var cmd = connection.CreateCommand();
        cmd.CommandText = sql;
        cmd.ExecuteNonQuery();
    }

    private static void AddParam(DbCommand cmd, string name, object value)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.Value = value;
        cmd.Parameters.Add(p);
    }
}
