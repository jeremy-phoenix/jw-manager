using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using CongregationManager.Data;
using CongregationManager.Data.Components;
using CongregationManager.Data.Models;
using CongregationManager.DataTransfer;
using Serilog;

namespace CongregationManager.Services;

public class DataService
{
    private static readonly JsonSerializerOptions JsonExportSerializerOptions = new()
    {
        WriteIndented = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Converters = { new JsonStringEnumConverter() },
    };

    private FieldServiceDbContext _context;

    public DataService()
    {
        _context = InitializeContext();
    }

    public DataService(FieldServiceDbContext context)
    {
        _context = context;
        _context.Database.EnsureCreated();
        ApplySchemaUpdates(_context);
    }

    private static void ApplySchemaUpdates(FieldServiceDbContext context)
    {
        var conn = context.Database.GetDbConnection();
        if (conn.State != System.Data.ConnectionState.Open)
            conn.Open();

        using var cmd = conn.CreateCommand();

        // Check if Congregations table exists
        cmd.CommandText =
            "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='Congregations'";
        if (Convert.ToInt64(cmd.ExecuteScalar()) == 0)
        {
            cmd.CommandText = """
                CREATE TABLE "Congregations" (
                    "Id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                    "Name" TEXT NOT NULL,
                    "Number" TEXT,
                    "City" TEXT,
                    "CircuitNumber" TEXT,
                    "CreatedAt" TEXT NOT NULL,
                    "ModifiedAt" TEXT,
                    "CreatedBy" TEXT,
                    "ModifiedBy" TEXT,
                    "Status" INTEGER NOT NULL
                );
                """;
            cmd.ExecuteNonQuery();
        }

        // Check if CongregationId column exists on Persons
        cmd.CommandText = "PRAGMA table_info(Persons)";
        var hasCongregationId = false;
        using (var reader = cmd.ExecuteReader())
        {
            while (reader.Read())
            {
                if (
                    string.Equals(
                        reader.GetString(1),
                        "CongregationId",
                        StringComparison.OrdinalIgnoreCase
                    )
                )
                {
                    hasCongregationId = true;
                    break;
                }
            }
        }

        if (!hasCongregationId)
        {
            cmd.CommandText =
                "ALTER TABLE \"Persons\" ADD COLUMN \"CongregationId\" INTEGER REFERENCES \"Congregations\"(\"Id\")";
            cmd.ExecuteNonQuery();

            cmd.CommandText =
                "CREATE INDEX \"IX_Persons_CongregationId\" ON \"Persons\" (\"CongregationId\")";
            cmd.ExecuteNonQuery();
        }

        // Check if CongregationId column exists on FieldServiceGroups
        cmd.CommandText = "PRAGMA table_info(FieldServiceGroups)";
        var hasFsgCongregationId = false;
        using (var reader2 = cmd.ExecuteReader())
        {
            while (reader2.Read())
            {
                if (
                    string.Equals(
                        reader2.GetString(1),
                        "CongregationId",
                        StringComparison.OrdinalIgnoreCase
                    )
                )
                {
                    hasFsgCongregationId = true;
                    break;
                }
            }
        }

        if (!hasFsgCongregationId)
        {
            cmd.CommandText =
                "ALTER TABLE \"FieldServiceGroups\" ADD COLUMN \"CongregationId\" INTEGER REFERENCES \"Congregations\"(\"Id\")";
            cmd.ExecuteNonQuery();

            cmd.CommandText =
                "CREATE INDEX \"IX_FieldServiceGroups_CongregationId\" ON \"FieldServiceGroups\" (\"CongregationId\")";
            cmd.ExecuteNonQuery();
        }
    }

    private FieldServiceDbContext InitializeContext()
    {
        var context = new FieldServiceDbContext();
        context.Database.EnsureCreated();
        ApplySchemaUpdates(context);

        context.ChangeTracker.StateChanged += (s, e) =>
        {
            try
            {
                var entity = e.Entry.Entity;
                var entityState = e.Entry.State;

                Log.Verbose(
                    $"Entity of type {entity.GetType().Name} has changed state to {entityState}"
                );

                if (entityState is EntityState.Modified)
                {
                    foreach (var property in e.Entry.OriginalValues.Properties)
                    {
                        var originalValue = e.Entry.OriginalValues[property];
                        var currentValue = e.Entry.CurrentValues[property];

                        if (!object.Equals(originalValue, currentValue))
                        {
                            Log.Information(
                                $"Property '{property.Name}' changed from '{originalValue}' to '{currentValue}'"
                            );
                        }
                    }
                }

                if (entityState is EntityState.Added)
                {
                    Log.Verbose($"Entity {entity} was added.");
                }

                if (entityState is EntityState.Deleted)
                {
                    Log.Verbose($"Entity {entity} was deleted.");
                }
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Error in StateChanged event handler");
            }
        };

        context.ChangeTracker.StateChanging += (s, e) => { };

        context.ChangeTracker.DetectingAllChanges += (s, e) => { };

        return context;
    }

    public ChangeTracker ChangeTracker => _context.ChangeTracker;

    public bool HasChanges() => _context.ChangeTracker.HasChanges();

    public async Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        await _context.SaveChangesAsync(cancellationToken);

    public async Task<JsonDataExport> CreateJsonExportAsync(
        CancellationToken cancellationToken = default
    )
    {
        var congregations = await _context
            .Congregations.AsNoTracking()
            .Where(c => c.Status != EntityStatus.Deleted)
            .OrderBy(c => c.Name)
            .Select(c => new CongregationExportModel
            {
                Id = c.Id,
                CreatedAt = c.CreatedAt,
                ModifiedAt = c.ModifiedAt,
                CreatedBy = c.CreatedBy,
                ModifiedBy = c.ModifiedBy,
                Status = c.Status,
                Name = c.Name,
                Number = c.Number,
                City = c.City,
                CircuitNumber = c.CircuitNumber,
            })
            .ToListAsync(cancellationToken);

        var fieldServiceGroups = await _context
            .FieldServiceGroups.AsNoTracking()
            .Where(g => g.Status != EntityStatus.Deleted)
            .OrderBy(g => g.Name)
            .Select(g => new FieldServiceGroupExportModel
            {
                Id = g.Id,
                CreatedAt = g.CreatedAt,
                ModifiedAt = g.ModifiedAt,
                CreatedBy = g.CreatedBy,
                ModifiedBy = g.ModifiedBy,
                Status = g.Status,
                Name = g.Name,
                Description = g.Description,
                GroupOverseerId = g.GroupOverseerId,
                AssistantId = g.AssistantId,
                CongregationId = g.CongregationId,
            })
            .ToListAsync(cancellationToken);

        var persons = await _context
            .Persons.AsNoTracking()
            .Include(p => p.PhoneNumbers)
            .Include(p => p.EmergencyContacts)
            .Include(p => p.ServiceReports)
            .Include(p => p.AuxiliaryPioneerPeriods)
            .Where(p => p.Status != EntityStatus.Deleted)
            .OrderBy(p => p.FirstName)
            .ThenBy(p => p.LastName)
            .ToListAsync(cancellationToken);

        return new JsonDataExport
        {
            ExportedAtUtc = DateTime.UtcNow,
            Congregations = congregations,
            FieldServiceGroups = fieldServiceGroups,
            Persons = persons
                .Select(p => new PersonExportModel
                {
                    Id = p.Id,
                    CreatedAt = p.CreatedAt,
                    ModifiedAt = p.ModifiedAt,
                    CreatedBy = p.CreatedBy,
                    ModifiedBy = p.ModifiedBy,
                    Status = p.Status,
                    FirstName = p.FirstName,
                    LastName = p.LastName,
                    OtherNames = p.OtherNames,
                    CongregationRole = p.CongregationRole,
                    PioneerType = p.PioneerType,
                    Hope = p.Hope,
                    BirthDate = p.BirthDate,
                    BaptismDate = p.BaptismDate,
                    Gender = p.Gender,
                    Address = p.Address,
                    FieldServiceGroupId = p.FieldServiceGroupId,
                    CongregationId = p.CongregationId,
                    IsActive = p.IsActive,
                    PhoneNumbers = p
                        .PhoneNumbers.OrderBy(n => n.Id)
                        .Select(n => new PhoneNumberExportModel
                        {
                            Id = n.Id,
                            CreatedAt = n.CreatedAt,
                            ModifiedAt = n.ModifiedAt,
                            CreatedBy = n.CreatedBy,
                            ModifiedBy = n.ModifiedBy,
                            Status = n.Status,
                            Number = n.Number,
                            PhoneType = n.PhoneType,
                            IsPrimary = n.IsPrimary,
                            PersonId = n.PersonId,
                        })
                        .ToList(),
                    EmergencyContacts = p
                        .EmergencyContacts.OrderBy(c => c.Id)
                        .Select(c => new EmergencyContactExportModel
                        {
                            Id = c.Id,
                            CreatedAt = c.CreatedAt,
                            ModifiedAt = c.ModifiedAt,
                            CreatedBy = c.CreatedBy,
                            ModifiedBy = c.ModifiedBy,
                            Status = c.Status,
                            Name = c.Name,
                            PhoneNumber = c.PhoneNumber,
                            Relationship = c.Relationship,
                            IsPrimary = c.IsPrimary,
                            PersonId = c.PersonId,
                        })
                        .ToList(),
                    ServiceReports = p
                        .ServiceReports.OrderBy(r => r.Year)
                        .ThenBy(r => r.Month)
                        .ThenBy(r => r.Id)
                        .Select(r => new ServiceReportExportModel
                        {
                            Id = r.Id,
                            PersonId = r.PersonId,
                            Year = r.Year,
                            Month = r.Month,
                            IsAuxiliaryPioneer = r.IsAuxiliaryPioneer,
                            IsActive = r.IsActive,
                            SharedInMinistry = r.SharedInMinistry,
                            BibleStudies = r.BibleStudies,
                            Hours = r.Hours,
                            Note = r.Note,
                        })
                        .ToList(),
                    AuxiliaryPioneerPeriods = p
                        .AuxiliaryPioneerPeriods.OrderBy(a => a.StartYear)
                        .ThenBy(a => a.StartMonth)
                        .ThenBy(a => a.Id)
                        .Select(a => new AuxiliaryPioneerPeriodExportModel
                        {
                            Id = a.Id,
                            PersonId = a.PersonId,
                            StartMonth = a.StartMonth,
                            StartYear = a.StartYear,
                            EndMonth = a.EndMonth,
                            EndYear = a.EndYear,
                        })
                        .ToList(),
                })
                .ToList(),
        };
    }

    public async Task ExportAllDataAsJsonAsync(
        string filePath,
        CancellationToken cancellationToken = default
    )
    {
        if (string.IsNullOrWhiteSpace(filePath))
            throw new ArgumentException("A file path is required.", nameof(filePath));

        var export = await CreateJsonExportAsync(cancellationToken);
        var directory = Path.GetDirectoryName(filePath);

        if (!string.IsNullOrWhiteSpace(directory))
            Directory.CreateDirectory(directory);

        await using var stream = File.Create(filePath);
        await JsonSerializer.SerializeAsync(
            stream,
            export,
            JsonExportSerializerOptions,
            cancellationToken
        );
    }

    // Congregation operations
    public async Task<List<Congregation>> GetCongregationsAsync() =>
        await _context
            .Congregations.Where(c => c.Status == EntityStatus.Active)
            .OrderBy(c => c.Name)
            .ToListAsync();

    public async Task AddCongregationAsync(Congregation congregation)
    {
        await _context.Congregations.AddAsync(congregation);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateCongregationAsync(Congregation congregation)
    {
        _context.Congregations.Update(congregation);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteCongregationAsync(Congregation congregation)
    {
        congregation.Status = EntityStatus.Deleted;
        _context.Congregations.Update(congregation);
        await _context.SaveChangesAsync();
    }

    // Person operations
    public async Task<List<Person>> GetPersonsAsync(int? congregationId = null)
    {
        var query = _context
            .Persons.Include(p => p.PhoneNumbers)
            .Include(p => p.EmergencyContacts)
            .Include(p => p.ServiceReports)
            .Include(p => p.FieldServiceGroup)
            .Include(p => p.Congregation)
            .Include(p => p.AuxiliaryPioneerPeriods)
            .Where(p => p.Status == EntityStatus.Active);

        if (congregationId.HasValue)
            query = query.Where(p => p.CongregationId == congregationId.Value);

        return await query.OrderBy(p => p.FirstName).ThenBy(p => p.LastName).ToListAsync();
    }

    public async Task AddPersonAsync(Person person)
    {
        await _context.Persons.AddAsync(person);
        await _context.SaveChangesAsync();
    }

    public async Task AddPersonsAsync(IEnumerable<Person> persons)
    {
        await _context.Persons.AddRangeAsync(persons);
        await _context.SaveChangesAsync();
    }

    public async Task UpdatePersonAsync(Person person)
    {
        _context.ChangeTracker.Clear();

        var existing = await _context
            .Persons.Include(p => p.PhoneNumbers)
            .Include(p => p.EmergencyContacts)
            .Include(p => p.ServiceReports)
            .Include(p => p.AuxiliaryPioneerPeriods)
            .FirstOrDefaultAsync(p => p.Id == person.Id);

        if (existing is null)
        {
            _context.Persons.Add(person);
            await _context.SaveChangesAsync();
            return;
        }

        // Update scalar properties
        _context.Entry(existing).CurrentValues.SetValues(person);

        // Reconcile child collections
        ReconcileCollection(existing.PhoneNumbers, person.PhoneNumbers, e => e.Id);
        ReconcileCollection(existing.EmergencyContacts, person.EmergencyContacts, e => e.Id);
        ReconcileCollection(existing.ServiceReports, person.ServiceReports, e => e.Id);
        ReconcileCollection(
            existing.AuxiliaryPioneerPeriods,
            person.AuxiliaryPioneerPeriods,
            e => e.Id
        );

        await _context.SaveChangesAsync();
    }

    public async Task DeletePersonAsync(Person person)
    {
        person.Status = EntityStatus.Deleted;
        _context.Persons.Update(person);
        await _context.SaveChangesAsync();
    }

    private void ReconcileCollection<T>(
        ICollection<T> existing,
        ICollection<T> updated,
        Func<T, int> getId
    )
        where T : class
    {
        var updatedIds = updated.Where(e => getId(e) != 0).Select(getId).ToHashSet();

        // Remove deleted items
        var toRemove = existing.Where(e => !updatedIds.Contains(getId(e))).ToList();
        foreach (var item in toRemove)
            _context.Remove(item);

        // Update existing and add new items
        foreach (var item in updated)
        {
            var id = getId(item);
            var existingItem = existing.FirstOrDefault(e => getId(e) == id && id != 0);
            if (existingItem is not null)
                _context.Entry(existingItem).CurrentValues.SetValues(item);
            else
                existing.Add(item);
        }
    }

    // FieldServiceGroup operations
    public async Task<List<FieldServiceGroup>> GetFieldServiceGroupsAsync(
        int? congregationId = null
    )
    {
        var query = _context
            .FieldServiceGroups.Include(g => g.GroupOverseer)
            .Include(g => g.Assistant)
            .Include(g => g.Members)
            .Where(g => g.Status == EntityStatus.Active);

        if (congregationId.HasValue)
            query = query.Where(g => g.CongregationId == congregationId.Value);

        return await query.ToListAsync();
    }

    public async Task<FieldServiceGroup?> GetFieldServiceGroupByIdAsync(int id) =>
        await _context
            .FieldServiceGroups.Include(g => g.Members)
            .FirstOrDefaultAsync(g => g.Id == id && g.Status == EntityStatus.Active);

    public async Task AddFieldServiceGroupAsync(FieldServiceGroup group)
    {
        await _context.FieldServiceGroups.AddAsync(group);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateFieldServiceGroupAsync(FieldServiceGroup group)
    {
        _context.FieldServiceGroups.Update(group);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteFieldServiceGroupAsync(FieldServiceGroup group)
    {
        group.Status = EntityStatus.Deleted;
        _context.FieldServiceGroups.Update(group);
        await _context.SaveChangesAsync();
    }

    // ServiceReport operations
    public async Task<List<ServiceReport>> GetServiceReportsAsync(
        int? year = null,
        Month? month = null,
        int? congregationId = null
    )
    {
        var query = _context
            .ServiceReports.Include(r => r.Person)
            .Where(x =>
                x.Person.Status == EntityStatus.Active || x.Person.Status == EntityStatus.Inactive
            )
            .AsQueryable();

        if (congregationId.HasValue)
            query = query.Where(r => r.Person.CongregationId == congregationId.Value);

        if (year.HasValue)
            query = query.Where(r => r.Year == year.Value);

        if (month.HasValue)
            query = query.Where(r => r.Month == month.Value);

        return await query
            .OrderBy(r => r.Person.FirstName)
            .ThenBy(r => r.Person.LastName)
            .ToListAsync();
    }

    /// <summary>
    /// Gets existing service reports for the given period, and creates new ones
    /// for any active/inactive persons who don't have a report yet.
    /// </summary>
    public async Task<List<ServiceReport>> GetOrCreateServiceReportsForPeriodAsync(
        int year,
        Month month,
        int? congregationId = null
    )
    {
        // Get all persons that are not archived or deleted
        var personsQuery = _context
            .Persons.Include(p => p.AuxiliaryPioneerPeriods)
            .Where(p => p.Status != EntityStatus.Archived && p.Status != EntityStatus.Deleted);

        if (congregationId.HasValue)
            personsQuery = personsQuery.Where(p => p.CongregationId == congregationId.Value);

        var eligiblePersons = await personsQuery.ToListAsync();

        // Get existing reports for this period
        var reportsQuery = _context
            .ServiceReports.Include(r => r.Person)
            .Where(r => r.Year == year && r.Month == month);

        if (congregationId.HasValue)
            reportsQuery = reportsQuery.Where(r => r.Person.CongregationId == congregationId.Value);

        var existingReports = await reportsQuery.ToListAsync();

        // Find persons without a report for this period
        var existingPersonIds = existingReports.Select(r => r.PersonId).ToHashSet();
        var personsWithoutReport = eligiblePersons
            .Where(p => !existingPersonIds.Contains(p.Id))
            .ToList();

        // Create new reports for persons without one
        if (personsWithoutReport.Count > 0)
        {
            var newReports = personsWithoutReport
                .Select(person => new ServiceReport
                {
                    PersonId = person.Id,
                    Person = person,
                    Year = year,
                    Month = month,
                    IsAuxiliaryPioneer = person.IsAuxiliaryPioneerFor(month, year),
                    IsActive = person.IsActive,
                    SharedInMinistry = false,
                    Hours = null,
                    BibleStudies = 0,
                })
                .ToList();

            await _context.ServiceReports.AddRangeAsync(newReports);
            await _context.SaveChangesAsync();

            existingReports.AddRange(newReports);
        }

        return existingReports
            .OrderBy(r => r.Person.FirstName)
            .ThenBy(r => r.Person.LastName)
            .ToList();
    }

    public async Task UpdateServiceReportAsync(ServiceReport report)
    {
        _context.ServiceReports.Update(report);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteServiceReportAsync(ServiceReport report)
    {
        _context.ServiceReports.Remove(report);
        await _context.SaveChangesAsync();
    }

    public async Task ImportPersonsAsync(
        List<Person> newPersons,
        List<(Person Existing, Person Updated)> updates
    )
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            if (newPersons.Count > 0)
            {
                await _context.Persons.AddRangeAsync(newPersons);
            }

            foreach (var (existing, updated) in updates)
            {
                existing.FirstName = updated.FirstName;
                existing.LastName = updated.LastName;
                existing.OtherNames = updated.OtherNames;
                existing.Gender = updated.Gender;
                existing.CongregationRole = updated.CongregationRole;
                existing.PioneerType = updated.PioneerType;
                existing.Hope = updated.Hope;
                existing.BirthDate = updated.BirthDate;
                existing.BaptismDate = updated.BaptismDate;
                existing.Address = updated.Address;
                existing.IsActive = updated.IsActive;
                existing.CongregationId = updated.CongregationId;
                existing.ModifiedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    public async Task<ImportFullExportResult> ImportFullExportAsync(JsonDataExport export)
    {
        _context.ChangeTracker.Clear();
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var result = new ImportFullExportResult();

            // Phase 1: Import congregations — match by name
            var existingCongregations = await _context
                .Congregations.Where(c => c.Status != EntityStatus.Deleted)
                .ToListAsync();
            var congIdMap = new Dictionary<int, int>();
            var newCongregations = new List<(int ExportId, Congregation Entity)>();

            foreach (var ec in export.Congregations)
            {
                var match = existingCongregations.FirstOrDefault(c =>
                    string.Equals(c.Name, ec.Name, StringComparison.OrdinalIgnoreCase)
                );

                if (match != null)
                {
                    match.Number = ec.Number;
                    match.City = ec.City;
                    match.CircuitNumber = ec.CircuitNumber;
                    match.ModifiedAt = DateTime.UtcNow;
                    congIdMap[ec.Id] = match.Id;
                    result.CongregationsUpdated++;
                }
                else
                {
                    var entity = new Congregation
                    {
                        Name = ec.Name,
                        Number = ec.Number,
                        City = ec.City,
                        CircuitNumber = ec.CircuitNumber,
                    };
                    await _context.Congregations.AddAsync(entity);
                    newCongregations.Add((ec.Id, entity));
                    result.CongregationsAdded++;
                }
            }

            await _context.SaveChangesAsync();
            foreach (var (exportId, entity) in newCongregations)
                congIdMap[exportId] = entity.Id;

            // Phase 2: Import persons with sub-data (FieldServiceGroupId deferred)
            var existingPersons = await _context
                .Persons.Include(p => p.PhoneNumbers)
                .Include(p => p.EmergencyContacts)
                .Include(p => p.ServiceReports)
                .Include(p => p.AuxiliaryPioneerPeriods)
                .Where(p => p.Status != EntityStatus.Deleted)
                .ToListAsync();
            var personIdMap = new Dictionary<int, int>();
            var newPersonEntries = new List<(int ExportId, Person Entity)>();

            foreach (var ep in export.Persons)
            {
                int? remappedCongId =
                    ep.CongregationId.HasValue
                    && congIdMap.TryGetValue(ep.CongregationId.Value, out var cid)
                        ? cid
                        : null;

                var match = existingPersons.FirstOrDefault(p =>
                    string.Equals(p.FirstName, ep.FirstName, StringComparison.OrdinalIgnoreCase)
                    && string.Equals(p.LastName, ep.LastName, StringComparison.OrdinalIgnoreCase)
                );

                if (match != null)
                {
                    match.OtherNames = ep.OtherNames;
                    match.CongregationRole = ep.CongregationRole;
                    match.PioneerType = ep.PioneerType;
                    match.Hope = ep.Hope;
                    match.BirthDate = ep.BirthDate;
                    match.BaptismDate = ep.BaptismDate;
                    match.Gender = ep.Gender;
                    match.Address = ep.Address;
                    match.IsActive = ep.IsActive;
                    match.CongregationId = remappedCongId ?? match.CongregationId;
                    match.ModifiedAt = DateTime.UtcNow;

                    MergePhoneNumbers(match, ep.PhoneNumbers);
                    MergeEmergencyContacts(match, ep.EmergencyContacts);
                    result.ServiceReportsAdded += MergeServiceReports(match, ep.ServiceReports);
                    MergeAuxiliaryPioneerPeriods(match, ep.AuxiliaryPioneerPeriods);

                    personIdMap[ep.Id] = match.Id;
                    result.PersonsUpdated++;
                }
                else
                {
                    var person = new Person
                    {
                        FirstName = ep.FirstName,
                        LastName = ep.LastName,
                        OtherNames = ep.OtherNames,
                        CongregationRole = ep.CongregationRole,
                        PioneerType = ep.PioneerType,
                        Hope = ep.Hope,
                        BirthDate = ep.BirthDate,
                        BaptismDate = ep.BaptismDate,
                        Gender = ep.Gender,
                        Address = ep.Address,
                        IsActive = ep.IsActive,
                        CongregationId = remappedCongId,
                    };

                    foreach (var phone in ep.PhoneNumbers)
                        person.PhoneNumbers.Add(
                            new PhoneNumber
                            {
                                Number = phone.Number,
                                PhoneType = phone.PhoneType,
                                IsPrimary = phone.IsPrimary,
                            }
                        );

                    foreach (var contact in ep.EmergencyContacts)
                        person.EmergencyContacts.Add(
                            new EmergencyContact
                            {
                                Name = contact.Name,
                                PhoneNumber = contact.PhoneNumber,
                                Relationship = contact.Relationship,
                                IsPrimary = contact.IsPrimary,
                            }
                        );

                    foreach (var report in ep.ServiceReports)
                    {
                        person.ServiceReports.Add(
                            new ServiceReport
                            {
                                Year = report.Year,
                                Month = report.Month,
                                IsAuxiliaryPioneer = report.IsAuxiliaryPioneer,
                                IsActive = report.IsActive,
                                SharedInMinistry = report.SharedInMinistry,
                                BibleStudies = report.BibleStudies,
                                Hours = report.Hours,
                                Note = report.Note,
                            }
                        );
                        result.ServiceReportsAdded++;
                    }

                    foreach (var period in ep.AuxiliaryPioneerPeriods)
                        person.AuxiliaryPioneerPeriods.Add(
                            new AuxiliaryPioneerPeriod
                            {
                                StartMonth = period.StartMonth,
                                StartYear = period.StartYear,
                                EndMonth = period.EndMonth,
                                EndYear = period.EndYear,
                            }
                        );

                    await _context.Persons.AddAsync(person);
                    newPersonEntries.Add((ep.Id, person));
                    result.PersonsAdded++;
                }
            }

            await _context.SaveChangesAsync();
            foreach (var (exportId, entity) in newPersonEntries)
                personIdMap[exportId] = entity.Id;

            // Phase 3: Import field service groups — match by name + congregation
            var existingGroups = await _context
                .FieldServiceGroups.Where(g => g.Status != EntityStatus.Deleted)
                .ToListAsync();
            var groupIdMap = new Dictionary<int, int>();
            var newGroupEntries = new List<(int ExportId, FieldServiceGroup Entity)>();

            foreach (var eg in export.FieldServiceGroups)
            {
                int? remappedCongId =
                    eg.CongregationId.HasValue
                    && congIdMap.TryGetValue(eg.CongregationId.Value, out var gcid)
                        ? gcid
                        : null;
                int? remappedOverseerId =
                    eg.GroupOverseerId.HasValue
                    && personIdMap.TryGetValue(eg.GroupOverseerId.Value, out var oid)
                        ? oid
                        : null;
                int? remappedAssistantId =
                    eg.AssistantId.HasValue
                    && personIdMap.TryGetValue(eg.AssistantId.Value, out var aid)
                        ? aid
                        : null;

                var match = existingGroups.FirstOrDefault(g =>
                    string.Equals(g.Name, eg.Name, StringComparison.OrdinalIgnoreCase)
                    && g.CongregationId == remappedCongId
                );

                if (match != null)
                {
                    match.Description = eg.Description;
                    match.GroupOverseerId = remappedOverseerId;
                    match.AssistantId = remappedAssistantId;
                    match.ModifiedAt = DateTime.UtcNow;
                    groupIdMap[eg.Id] = match.Id;
                    result.GroupsUpdated++;
                }
                else
                {
                    var group = new FieldServiceGroup
                    {
                        Name = eg.Name,
                        Description = eg.Description,
                        CongregationId = remappedCongId,
                        GroupOverseerId = remappedOverseerId,
                        AssistantId = remappedAssistantId,
                    };
                    await _context.FieldServiceGroups.AddAsync(group);
                    newGroupEntries.Add((eg.Id, group));
                    result.GroupsAdded++;
                }
            }

            await _context.SaveChangesAsync();
            foreach (var (exportId, entity) in newGroupEntries)
                groupIdMap[exportId] = entity.Id;

            // Phase 4: Assign FieldServiceGroupId to persons using remapped group IDs
            var allPersonEntities = existingPersons.ToDictionary(p => p.Id);
            foreach (var (_, entity) in newPersonEntries)
                allPersonEntities[entity.Id] = entity;

            foreach (var ep in export.Persons)
            {
                if (
                    ep.FieldServiceGroupId.HasValue
                    && groupIdMap.TryGetValue(ep.FieldServiceGroupId.Value, out var newGroupId)
                    && newGroupId > 0
                    && personIdMap.TryGetValue(ep.Id, out var newPersonId)
                    && allPersonEntities.TryGetValue(newPersonId, out var person)
                )
                {
                    person.FieldServiceGroupId = newGroupId;
                }
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return result;
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    private static void MergePhoneNumbers(Person existing, List<PhoneNumberExportModel> exported)
    {
        foreach (var phone in exported)
        {
            if (
                !existing.PhoneNumbers.Any(p =>
                    string.Equals(p.Number, phone.Number, StringComparison.OrdinalIgnoreCase)
                )
            )
            {
                existing.PhoneNumbers.Add(
                    new PhoneNumber
                    {
                        Number = phone.Number,
                        PhoneType = phone.PhoneType,
                        IsPrimary = phone.IsPrimary,
                        PersonId = existing.Id,
                    }
                );
            }
        }
    }

    private static void MergeEmergencyContacts(
        Person existing,
        List<EmergencyContactExportModel> exported
    )
    {
        foreach (var contact in exported)
        {
            if (
                !existing.EmergencyContacts.Any(c =>
                    string.Equals(c.Name, contact.Name, StringComparison.OrdinalIgnoreCase)
                )
            )
            {
                existing.EmergencyContacts.Add(
                    new EmergencyContact
                    {
                        Name = contact.Name,
                        PhoneNumber = contact.PhoneNumber,
                        Relationship = contact.Relationship,
                        IsPrimary = contact.IsPrimary,
                        PersonId = existing.Id,
                    }
                );
            }
        }
    }

    private static int MergeServiceReports(Person existing, List<ServiceReportExportModel> exported)
    {
        var added = 0;
        foreach (var report in exported)
        {
            if (!existing.ServiceReports.Any(r => r.Year == report.Year && r.Month == report.Month))
            {
                existing.ServiceReports.Add(
                    new ServiceReport
                    {
                        PersonId = existing.Id,
                        Year = report.Year,
                        Month = report.Month,
                        IsAuxiliaryPioneer = report.IsAuxiliaryPioneer,
                        IsActive = report.IsActive,
                        SharedInMinistry = report.SharedInMinistry,
                        BibleStudies = report.BibleStudies,
                        Hours = report.Hours,
                        Note = report.Note,
                    }
                );
                added++;
            }
        }
        return added;
    }

    private static void MergeAuxiliaryPioneerPeriods(
        Person existing,
        List<AuxiliaryPioneerPeriodExportModel> exported
    )
    {
        foreach (var period in exported)
        {
            if (
                !existing.AuxiliaryPioneerPeriods.Any(a =>
                    a.StartMonth == period.StartMonth && a.StartYear == period.StartYear
                )
            )
            {
                existing.AuxiliaryPioneerPeriods.Add(
                    new AuxiliaryPioneerPeriod
                    {
                        PersonId = existing.Id,
                        StartMonth = period.StartMonth,
                        StartYear = period.StartYear,
                        EndMonth = period.EndMonth,
                        EndYear = period.EndYear,
                    }
                );
            }
        }
    }

    #region Summary Statistics

    /// <summary>
    /// Gets field service report statistics for a given month.
    /// </summary>
    public async Task<FieldServiceReportStatistics> GetSummaryAsync(
        int year,
        Month month,
        int monthsBack = 6,
        int? congregationId = null
    )
    {
        if (month == Month.None)
            throw new ArgumentException(
                "Month must be between January and December.",
                nameof(month)
            );

        monthsBack = Math.Max(1, monthsBack);

        var personsQuery = _context
            .Persons.AsNoTracking()
            .Where(p => p.Status == EntityStatus.Active && p.IsActive);
        if (congregationId.HasValue)
            personsQuery = personsQuery.Where(p => p.CongregationId == congregationId.Value);

        var activePersonCount = await personsQuery.CountAsync();

        var reportsQuery = _context
            .ServiceReports.AsNoTracking()
            .Include(r => r.Person)
            .Where(r => r.Year == year && r.Month == month)
            .Where(r => r.Person.Status == EntityStatus.Active && r.Person.IsActive);

        if (congregationId.HasValue)
            reportsQuery = reportsQuery.Where(r => r.Person.CongregationId == congregationId.Value);

        var monthReports = await reportsQuery
            .Where(r => r.SharedInMinistry || (r.Hours ?? 0) > 0 || r.BibleStudies > 0)
            .Select(r => new
            {
                r.IsAuxiliaryPioneer,
                IsRegularPioneer = r.Person.PioneerType == PioneerType.RegularPioneer
                    || r.Person.PioneerType == PioneerType.SpecialPioneer
                    || r.Person.PioneerType == PioneerType.FieldMissionary,
                r.Hours,
                r.BibleStudies,
            })
            .ToListAsync();

        var publishers = monthReports
            .Where(r => !r.IsAuxiliaryPioneer && !r.IsRegularPioneer)
            .ToList();
        var auxiliaryPioneers = monthReports.Where(r => r.IsAuxiliaryPioneer).ToList();
        var regularPioneers = monthReports
            .Where(r => r.IsRegularPioneer && !r.IsAuxiliaryPioneer)
            .ToList();

        return new FieldServiceReportStatistics
        {
            AllActivePublishers = activePersonCount,
            Publishers = new FieldServiceReportStatistics.ReportMetrics
            {
                NumberOfReports = publishers.Count,
                BibleStudies = publishers.Sum(r => r.BibleStudies),
                Hours = 0,
            },
            AuxiliaryPioneers = new FieldServiceReportStatistics.ReportMetrics
            {
                NumberOfReports = auxiliaryPioneers.Count,
                BibleStudies = auxiliaryPioneers.Sum(r => r.BibleStudies),
                Hours = auxiliaryPioneers.Sum(r => (double)(r.Hours ?? 0)),
            },
            RegularPioneers = new FieldServiceReportStatistics.ReportMetrics
            {
                NumberOfReports = regularPioneers.Count,
                BibleStudies = regularPioneers.Sum(r => r.BibleStudies),
                Hours = regularPioneers.Sum(r => (double)(r.Hours ?? 0)),
            },
        };
    }

    /// <summary>
    /// Gets congregation summary with counts.
    /// </summary>
    public async Task<CongregationSummary> GetCongregationSummaryAsync(
        DateTime? today = null,
        int? congregationId = null
    )
    {
        var detailed = await GetCongregationSummaryDetailedAsync(today, congregationId);

        return new CongregationSummary
        {
            AllActivePublishers = detailed.AllActivePublishers.Count,
            NewInactivePublishers = detailed.NewInactivePublishers.Count,
            ReactivatedPublishers = detailed.ReactivatedPublishers.Count,
        };
    }

    /// <summary>
    /// Gets detailed congregation summary with lists of persons.
    /// </summary>
    public async Task<CongregationSummaryDetailed> GetCongregationSummaryDetailedAsync(
        DateTime? today = null,
        int? congregationId = null
    )
    {
        var query = _context
            .Persons.AsNoTracking()
            .Include(p => p.ServiceReports)
            .Where(p => p.Status == EntityStatus.Active && p.IsActive);

        if (congregationId.HasValue)
            query = query.Where(p => p.CongregationId == congregationId.Value);

        var persons = await query.ToListAsync();

        if (persons.Count == 0)
            return new CongregationSummaryDetailed();

        var result = new CongregationSummaryDetailed();

        foreach (var person in persons)
        {
            var reports = person
                .ServiceReports.Where(r => r.Month != Month.None)
                .OrderBy(r => ToServiceYearIndex(r.Year, r.Month))
                .Select(r => r.SharedInMinistry)
                .ToList();

            if (reports.Count == 0)
                continue;

            var last6Reports = reports.TakeLast(6).ToList();
            var isActive = last6Reports.Any(shared => shared);

            if (isActive)
                result.AllActivePublishers.Add(person);

            var (hasInactivityStreak, firstInactivityEndIndex) = FindInactivityStreak(reports);

            var isCurrentlyInactive = !isActive && hasInactivityStreak;

            if (isCurrentlyInactive)
                result.NewInactivePublishers.Add(person);

            if (hasInactivityStreak && firstInactivityEndIndex < reports.Count - 1)
            {
                var sharedAfterInactivity = reports
                    .Skip(firstInactivityEndIndex + 1)
                    .Any(shared => shared);

                if (sharedAfterInactivity)
                    result.ReactivatedPublishers.Add(person);
            }
        }

        return result;
    }

    #endregion

    /// <summary>
    /// Returns true if the person's last 6 service reports all have SharedInMinistry = false.
    /// </summary>
    public static bool IsPersonInactive(Person person)
    {
        var reports = person
            .ServiceReports.Where(r => r.Month != Month.None)
            .OrderBy(r => ToServiceYearIndex(r.Year, r.Month))
            .Select(r => r.SharedInMinistry)
            .ToList();

        if (reports.Count < 6)
            return false;

        return reports.TakeLast(6).All(shared => !shared);
    }

    #region Helpers

    private static int ToServiceYearIndex(int year, Month month)
    {
        var serviceYear = (int)month >= 9 ? year + 1 : year;
        var serviceMonth = (int)month >= 9 ? (int)month - 8 : (int)month + 4;

        return serviceYear * 12 + serviceMonth;
    }

    private static (bool HasStreak, int FirstStreakEndIndex) FindInactivityStreak(
        List<bool> reports
    )
    {
        var consecutiveNoShare = 0;

        for (var i = 0; i < reports.Count; i++)
        {
            if (reports[i])
            {
                consecutiveNoShare = 0;
            }
            else
            {
                consecutiveNoShare++;
                if (consecutiveNoShare >= 6)
                    return (true, i);
            }
        }

        return (false, -1);
    }

    #endregion

    #region Connection Management

    /// <summary>
    /// Gets the path to the database file.
    /// </summary>
    public string DatabasePath => _context.DbPath;

    /// <summary>
    /// Closes the database connection to allow file operations like restore.
    /// </summary>
    public async Task CloseConnectionAsync()
    {
        try
        {
            await _context.Database.CloseConnectionAsync();
            await _context.DisposeAsync();
            SqliteConnection.ClearAllPools();
            Log.Information("Database connection closed for maintenance operations");
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error closing database connection");
            throw;
        }
    }

    /// <summary>
    /// Re-initializes the database context after a restore or other maintenance operation.
    /// </summary>
    public Task ReopenConnectionAsync()
    {
        _context = InitializeContext();
        Log.Information("Database connection re-initialized after maintenance operation");
        return Task.CompletedTask;
    }

    /// <summary>
    /// Ensures any pending writes are flushed to disk (checkpoint for SQLite).
    /// </summary>
    public async Task CheckpointAsync()
    {
        try
        {
            await _context.Database.ExecuteSqlRawAsync("PRAGMA wal_checkpoint(TRUNCATE);");
            Log.Debug("Database checkpoint completed");
        }
        catch (Exception ex)
        {
            Log.Warning(
                ex,
                "Database checkpoint failed (this is normal if WAL mode is not enabled)"
            );
        }
    }

    #endregion

    #region CSV Sync

    /// <summary>
    /// Applies CSV sync updates in a single transaction.
    /// </summary>
    public async Task ApplyCsvSyncAsync(List<CsvPublisherSyncService.SyncRecordResult> updates)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            foreach (var update in updates)
            {
                var person = update.DbPerson;

                if (update.AddressChanged)
                {
                    person.Address = update.NewAddress;
                }

                if (update.PhonesChanged)
                {
                    var existingPhones = await _context
                        .PhoneNumbers.Where(p => p.PersonId == person.Id)
                        .ToListAsync();
                    _context.PhoneNumbers.RemoveRange(existingPhones);

                    var newPhones = CsvPublisherSyncService.BuildPhoneNumbers(
                        update.NewPhones,
                        person.Id
                    );
                    await _context.PhoneNumbers.AddRangeAsync(newPhones);
                }

                person.ModifiedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    #endregion
}
