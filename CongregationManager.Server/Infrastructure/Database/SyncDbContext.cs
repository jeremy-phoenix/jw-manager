using System.Text;
using Microsoft.EntityFrameworkCore;

namespace CongregationManager.Server.Infrastructure.Database;

public sealed class SyncDbContext(DbContextOptions<SyncDbContext> options) : DbContext(options)
{
    public DbSet<Vault> Vaults => Set<Vault>();

    public DbSet<Device> Devices => Set<Device>();

    public DbSet<Invite> Invites => Set<Invite>();

    public DbSet<SyncRecord> Records => Set<SyncRecord>();

    public DbSet<AppliedOperation> AppliedOperations => Set<AppliedOperation>();

    public DbSet<SchemaInfo> SchemaInfo => Set<SchemaInfo>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Vault>(entity =>
        {
            entity.ToTable("cm_vaults");
            entity.HasKey(vault => vault.Id);
            entity.Property(vault => vault.Id).ValueGeneratedNever();
            entity.HasIndex(vault => vault.RecoveryAuthHash).IsUnique();
        });

        modelBuilder.Entity<Device>(entity =>
        {
            entity.ToTable("cm_devices");
            entity.HasKey(device => device.Id);
            entity.Property(device => device.Id).ValueGeneratedNever();
            entity.Property(device => device.EnrolledVia).HasMaxLength(16);
            entity.HasIndex(device => device.TokenHash).IsUnique();
            entity.HasIndex(device => device.VaultId);
            entity.HasOne<Vault>()
                .WithMany()
                .HasForeignKey(device => device.VaultId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Invite>(entity =>
        {
            entity.ToTable("cm_invites");
            entity.HasKey(invite => invite.Id);
            entity.Property(invite => invite.Id).ValueGeneratedNever();
            entity.HasIndex(invite => invite.CodeHash).IsUnique();
            entity.HasIndex(invite => invite.VaultId);
            entity.HasOne<Vault>()
                .WithMany()
                .HasForeignKey(invite => invite.VaultId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SyncRecord>(entity =>
        {
            entity.ToTable("cm_records");
            entity.HasKey(record => new { record.VaultId, record.RecordId });
            entity.HasIndex(record => new { record.VaultId, record.Seq }).IsUnique();
            entity.HasIndex(record => new { record.VaultId, record.KeyId });
            entity.HasOne<Vault>()
                .WithMany()
                .HasForeignKey(record => record.VaultId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AppliedOperation>(entity =>
        {
            entity.ToTable("cm_applied_operations");
            entity.HasKey(operation => new { operation.VaultId, operation.OperationId });
            entity.HasIndex(operation => operation.AppliedAtMs);
            entity.HasOne<Vault>()
                .WithMany()
                .HasForeignKey(operation => operation.VaultId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SchemaInfo>(entity =>
        {
            entity.ToTable("cm_schema_info");
            entity.HasKey(info => info.Id);
            entity.Property(info => info.Id).ValueGeneratedNever();
        });

        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entityType.GetProperties())
            {
                property.SetColumnName(ToSnakeCase(property.Name));
            }
        }
    }

    private static string ToSnakeCase(string name)
    {
        var builder = new StringBuilder(name.Length + 8);
        for (var i = 0; i < name.Length; i++)
        {
            var character = name[i];
            if (char.IsUpper(character))
            {
                if (i > 0)
                {
                    builder.Append('_');
                }

                builder.Append(char.ToLowerInvariant(character));
            }
            else
            {
                builder.Append(character);
            }
        }

        return builder.ToString();
    }
}
