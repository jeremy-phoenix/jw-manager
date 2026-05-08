using System.IO;
using Microsoft.EntityFrameworkCore;
using CongregationManager.Data.Models;
using CongregationManager.Utils;

namespace CongregationManager.Data;

public class FieldServiceDbContext : DbContext
{
    public DbSet<Person> Persons { get; set; }
    public DbSet<EmergencyContact> EmergencyContacts { get; set; }
    public DbSet<FieldServiceGroup> FieldServiceGroups { get; set; }
    public DbSet<PhoneNumber> PhoneNumbers { get; set; }
    public DbSet<ServiceReport> ServiceReports { get; set; }
    public DbSet<AuxiliaryPioneerPeriod> AuxiliaryPioneerPeriods { get; set; }
    public DbSet<Congregation> Congregations { get; set; }
    public DbSet<User> Users { get; set; }

    public string DbPath { get; }

    public FieldServiceDbContext()
    {
        DbPath = Path.Join(Directory.GetCurrentDirectory(), "field-service.db");
    }

    public FieldServiceDbContext(string dbPath)
    {
        DbPath = dbPath;
    }

    public FieldServiceDbContext(DbContextOptions<FieldServiceDbContext> options)
        : base(options)
    {
        DbPath = "";
    }

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        if (!options.IsConfigured)
            options.UseSqlite($"Data Source={DbPath}");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder
            .Entity<ServiceReport>()
            .HasChangeTrackingStrategy(ChangeTrackingStrategy.ChangingAndChangedNotificationsWithOriginalValues);

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(u => u.Email).IsUnique();
        });

        modelBuilder.Entity<Congregation>(entity =>
        {
            entity.HasIndex(c => c.SyncId).IsUnique();
            entity.HasMany(c => c.Members)
                .WithOne(p => p.Congregation)
                .HasForeignKey(p => p.CongregationId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<FieldServiceGroup>(entity =>
        {
            entity.HasIndex(g => g.SyncId).IsUnique();
            entity.HasOne(g => g.Congregation)
                .WithMany()
                .HasForeignKey(g => g.CongregationId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(g => g.GroupOverseer)
                .WithMany()
                .HasForeignKey(g => g.GroupOverseerId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(g => g.Assistant)
                .WithMany()
                .HasForeignKey(g => g.AssistantId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasMany(g => g.Members)
                .WithOne(p => p.FieldServiceGroup)
                .HasForeignKey(p => p.FieldServiceGroupId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Person>(entity =>
        {
            entity.HasIndex(p => p.SyncId).IsUnique();
        });

        modelBuilder.Entity<PhoneNumber>(entity =>
        {
            entity.HasIndex(p => p.SyncId).IsUnique();
        });

        modelBuilder.Entity<EmergencyContact>(entity =>
        {
            entity.HasIndex(e => e.SyncId).IsUnique();
        });

        modelBuilder.Entity<ServiceReport>(entity =>
        {
            entity.HasIndex(s => s.SyncId).IsUnique();
        });

        modelBuilder.Entity<AuxiliaryPioneerPeriod>(entity =>
        {
            entity.ToTable("AuxiliaryPioneerPeriod");
            entity.HasIndex(a => a.SyncId).IsUnique();
        });

        // Application-level encryption for sensitive fields
        if (EncryptionProvider.IsEnabled)
        {
            var encryptedString = new EncryptedStringConverter();
            var nullableEncryptedString = new NullableEncryptedStringConverter();

            modelBuilder.Entity<Person>(entity =>
            {
                entity.Property(p => p.FirstName).HasConversion(encryptedString);
                entity.Property(p => p.LastName).HasConversion(encryptedString);
                entity.Property(p => p.OtherNames).HasConversion(nullableEncryptedString);
                entity.Property(p => p.Address).HasConversion(nullableEncryptedString);
            });

            modelBuilder.Entity<PhoneNumber>(entity =>
            {
                entity.Property(p => p.Number).HasConversion(encryptedString);
            });

            modelBuilder.Entity<EmergencyContact>(entity =>
            {
                entity.Property(e => e.Name).HasConversion(encryptedString);
                entity.Property(e => e.PhoneNumber).HasConversion(nullableEncryptedString);
            });
        }

        base.OnModelCreating(modelBuilder);
    }
}
