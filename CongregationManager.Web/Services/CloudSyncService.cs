using System.Text.Json;
using CongregationManager.Data;
using CongregationManager.Data.Components;
using CongregationManager.Data.Models;
using CongregationManager.DataTransfer;
using Microsoft.EntityFrameworkCore;

namespace CongregationManager.Web.Services;

public sealed class CloudSyncService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly FieldServiceDbContext _db;

    public CloudSyncService(FieldServiceDbContext db)
    {
        _db = db;
    }

    public async Task<SyncPushResponse> PushAsync(SyncPushRequest request, CancellationToken cancellationToken)
    {
        var accepted = new List<AcceptedSyncOperationDto>();
        var conflicts = new List<SyncConflictDto>();

        foreach (var operation in request.Operations)
        {
            var conflict = await TryGetConflictAsync(operation, cancellationToken);
            if (conflict is not null)
            {
                conflicts.Add(conflict);
                continue;
            }

            var result = await ApplyOperationAsync(operation, cancellationToken);
            accepted.Add(result);
        }

        return new SyncPushResponse(accepted, conflicts);
    }

    public async Task<SyncPullResponse> PullAsync(string? cursor, CancellationToken cancellationToken)
    {
        var since = DateTime.TryParse(cursor, out var parsed)
            ? parsed.ToUniversalTime()
            : (DateTime?)null;
        var nextCursor = DateTime.UtcNow;
        var changes = new List<SyncChangeDto>();

        foreach (var row in await ChangedBaseEntities(_db.Congregations, since).ToListAsync(cancellationToken))
            changes.Add(Change("congregation", row.SyncId, RowOperation(row), row.ServerVersion, LastModified(row), CongregationPayload(row)));

        foreach (var row in await ChangedBaseEntities(_db.FieldServiceGroups, since).ToListAsync(cancellationToken))
            changes.Add(Change("fieldServiceGroup", row.SyncId, RowOperation(row), row.ServerVersion, LastModified(row), await FieldServiceGroupPayloadAsync(row, cancellationToken)));

        foreach (var row in await ChangedBaseEntities(_db.Persons, since).ToListAsync(cancellationToken))
            changes.Add(Change("person", row.SyncId, RowOperation(row), row.ServerVersion, LastModified(row), await PersonPayloadAsync(row, cancellationToken)));

        foreach (var row in await ChangedBaseEntities(_db.PhoneNumbers, since).ToListAsync(cancellationToken))
            changes.Add(Change("phoneNumber", row.SyncId, RowOperation(row), row.ServerVersion, LastModified(row), await PhoneNumberPayloadAsync(row, cancellationToken)));

        foreach (var row in await ChangedBaseEntities(_db.EmergencyContacts, since).ToListAsync(cancellationToken))
            changes.Add(Change("emergencyContact", row.SyncId, RowOperation(row), row.ServerVersion, LastModified(row), await EmergencyContactPayloadAsync(row, cancellationToken)));

        foreach (var row in await ChangedServiceReports(since).ToListAsync(cancellationToken))
            changes.Add(Change("serviceReport", row.SyncId, RowOperation(row.DeletedAt), row.ServerVersion, LastModified(row), await ServiceReportPayloadAsync(row, cancellationToken)));

        foreach (var row in await ChangedAuxiliaryPioneerPeriods(since).ToListAsync(cancellationToken))
            changes.Add(Change("auxiliaryPioneerPeriod", row.SyncId, RowOperation(row.DeletedAt), row.ServerVersion, LastModified(row), await AuxiliaryPioneerPeriodPayloadAsync(row, cancellationToken)));

        return new SyncPullResponse(
            nextCursor.ToString("O"),
            changes.OrderBy(c => c.ModifiedAt).ToList());
    }

    private async Task<SyncConflictDto?> TryGetConflictAsync(SyncOperationDto operation, CancellationToken cancellationToken)
    {
        if (!operation.BaseServerVersion.HasValue || IsDelete(operation) && operation.BaseServerVersion.Value == 0)
            return null;

        var syncId = Guid.Parse(operation.EntitySyncId);
        var current = await FindVersionedEntityAsync(operation.EntityType, syncId, cancellationToken);
        if (current is null || current.ServerVersion == operation.BaseServerVersion.Value)
            return null;

        return new SyncConflictDto(
            operation.OperationId,
            operation.EntityType,
            operation.EntitySyncId,
            current.ServerVersion,
            JsonSerializer.SerializeToElement(await BuildServerPayloadAsync(operation.EntityType, syncId, cancellationToken), JsonOptions));
    }

    private async Task<AcceptedSyncOperationDto> ApplyOperationAsync(SyncOperationDto operation, CancellationToken cancellationToken)
    {
        var syncId = Guid.Parse(operation.EntitySyncId);
        var version = operation.EntityType switch
        {
            "congregation" => await ApplyCongregationAsync(operation, syncId, cancellationToken),
            "fieldServiceGroup" => await ApplyFieldServiceGroupAsync(operation, syncId, cancellationToken),
            "person" => await ApplyPersonAsync(operation, syncId, cancellationToken),
            "phoneNumber" => await ApplyPhoneNumberAsync(operation, syncId, cancellationToken),
            "emergencyContact" => await ApplyEmergencyContactAsync(operation, syncId, cancellationToken),
            "serviceReport" => await ApplyServiceReportAsync(operation, syncId, cancellationToken),
            "auxiliaryPioneerPeriod" => await ApplyAuxiliaryPioneerPeriodAsync(operation, syncId, cancellationToken),
            _ => throw new InvalidOperationException($"Unsupported sync entity '{operation.EntityType}'."),
        };

        await _db.SaveChangesAsync(cancellationToken);
        return new AcceptedSyncOperationDto(operation.OperationId, operation.EntityType, operation.EntitySyncId, version);
    }

    private async Task<long> ApplyCongregationAsync(SyncOperationDto operation, Guid syncId, CancellationToken cancellationToken)
    {
        var entity = await _db.Congregations.FirstOrDefaultAsync(c => c.SyncId == syncId, cancellationToken);
        if (IsDelete(operation))
            return Tombstone(entity, operation.Payload);

        entity ??= Add(new Congregation { SyncId = syncId });
        entity.Name = ReadString(operation.Payload, "name") ?? string.Empty;
        entity.Number = ReadString(operation.Payload, "number");
        entity.City = ReadString(operation.Payload, "city");
        entity.CircuitNumber = ReadString(operation.Payload, "circuitNumber");
        return MarkChanged(entity, operation.Payload);
    }

    private async Task<long> ApplyFieldServiceGroupAsync(SyncOperationDto operation, Guid syncId, CancellationToken cancellationToken)
    {
        var entity = await _db.FieldServiceGroups.FirstOrDefaultAsync(g => g.SyncId == syncId, cancellationToken);
        if (IsDelete(operation))
            return Tombstone(entity, operation.Payload);

        entity ??= Add(new FieldServiceGroup { SyncId = syncId });
        entity.Name = ReadString(operation.Payload, "name") ?? string.Empty;
        entity.Description = ReadString(operation.Payload, "description");
        entity.CongregationId = await BaseEntityIdAsync(_db.Congregations, ReadString(operation.Payload, "congregationSyncId"), cancellationToken);
        entity.GroupOverseerId = await BaseEntityIdAsync(_db.Persons, ReadString(operation.Payload, "groupOverseerSyncId"), cancellationToken);
        entity.AssistantId = await BaseEntityIdAsync(_db.Persons, ReadString(operation.Payload, "assistantSyncId"), cancellationToken);
        return MarkChanged(entity, operation.Payload);
    }

    private async Task<long> ApplyPersonAsync(SyncOperationDto operation, Guid syncId, CancellationToken cancellationToken)
    {
        var entity = await _db.Persons.FirstOrDefaultAsync(p => p.SyncId == syncId, cancellationToken);
        if (IsDelete(operation))
            return Tombstone(entity, operation.Payload);

        entity ??= Add(new Person { SyncId = syncId });
        entity.FirstName = ReadString(operation.Payload, "firstName") ?? string.Empty;
        entity.LastName = ReadString(operation.Payload, "lastName") ?? string.Empty;
        entity.OtherNames = ReadString(operation.Payload, "otherNames");
        entity.BirthDate = ReadDate(operation.Payload, "birthDate");
        entity.BaptismDate = ReadDate(operation.Payload, "baptismDate");
        entity.Gender = ReadEnum(operation.Payload, "gender", Gender.Unknown);
        entity.Hope = ReadEnum(operation.Payload, "hopeClass", HopeClass.Unknown);
        entity.CongregationRole = ReadEnum(operation.Payload, "congregationRole", CongregationRole.None);
        entity.PioneerType = ReadEnum(operation.Payload, "pioneerType", PioneerType.None);
        entity.Address = ReadString(operation.Payload, "address");
        entity.IsActive = ReadBool(operation.Payload, "isActive") ?? true;
        entity.InactiveDate = ReadDate(operation.Payload, "inactiveDate");
        entity.CongregationId = await BaseEntityIdAsync(_db.Congregations, ReadString(operation.Payload, "congregationSyncId"), cancellationToken);
        entity.FieldServiceGroupId = await BaseEntityIdAsync(_db.FieldServiceGroups, ReadString(operation.Payload, "fieldServiceGroupSyncId"), cancellationToken);
        return MarkChanged(entity, operation.Payload);
    }

    private async Task<long> ApplyPhoneNumberAsync(SyncOperationDto operation, Guid syncId, CancellationToken cancellationToken)
    {
        var entity = await _db.PhoneNumbers.FirstOrDefaultAsync(p => p.SyncId == syncId, cancellationToken);
        if (IsDelete(operation))
            return Tombstone(entity, operation.Payload);

        var personId = await BaseEntityIdAsync(_db.Persons, ReadString(operation.Payload, "personSyncId"), cancellationToken)
            ?? throw new InvalidOperationException("Phone number sync payload is missing a known personSyncId.");
        entity ??= Add(new PhoneNumber { SyncId = syncId });
        entity.Number = ReadString(operation.Payload, "number") ?? string.Empty;
        entity.PhoneType = ReadEnum(operation.Payload, "phoneType", PhoneType.Mobile);
        entity.IsPrimary = ReadBool(operation.Payload, "isPrimary") ?? false;
        entity.PersonId = personId;
        return MarkChanged(entity, operation.Payload);
    }

    private async Task<long> ApplyEmergencyContactAsync(SyncOperationDto operation, Guid syncId, CancellationToken cancellationToken)
    {
        var entity = await _db.EmergencyContacts.FirstOrDefaultAsync(e => e.SyncId == syncId, cancellationToken);
        if (IsDelete(operation))
            return Tombstone(entity, operation.Payload);

        var personId = await BaseEntityIdAsync(_db.Persons, ReadString(operation.Payload, "personSyncId"), cancellationToken)
            ?? throw new InvalidOperationException("Emergency contact sync payload is missing a known personSyncId.");
        entity ??= Add(new EmergencyContact { SyncId = syncId });
        entity.Name = ReadString(operation.Payload, "name") ?? string.Empty;
        entity.PhoneNumber = ReadString(operation.Payload, "phoneNumber");
        entity.Relationship = ReadEnum(operation.Payload, "relationship", Relationship.Other);
        entity.IsPrimary = ReadBool(operation.Payload, "isPrimary") ?? false;
        entity.PersonId = personId;
        return MarkChanged(entity, operation.Payload);
    }

    private async Task<long> ApplyServiceReportAsync(SyncOperationDto operation, Guid syncId, CancellationToken cancellationToken)
    {
        var entity = await _db.ServiceReports.FirstOrDefaultAsync(s => s.SyncId == syncId, cancellationToken);
        if (IsDelete(operation))
            return Tombstone(entity, operation.Payload);

        var personId = await BaseEntityIdAsync(_db.Persons, ReadString(operation.Payload, "personSyncId"), cancellationToken)
            ?? throw new InvalidOperationException("Service report sync payload is missing a known personSyncId.");
        entity ??= Add(new ServiceReport { SyncId = syncId });
        entity.Year = ReadInt(operation.Payload, "year") ?? DateTime.UtcNow.Year;
        entity.Month = (Month)(ReadInt(operation.Payload, "month") ?? 1);
        entity.IsAuxiliaryPioneer = ReadBool(operation.Payload, "isAuxiliaryPioneer") ?? false;
        entity.IsActive = ReadBool(operation.Payload, "isActive") ?? true;
        entity.SharedInMinistry = ReadBool(operation.Payload, "sharedInMinistry") ?? false;
        entity.BibleStudies = ReadInt(operation.Payload, "bibleStudies") ?? 0;
        entity.Hours = (float?)(ReadDouble(operation.Payload, "hours") ?? 0);
        entity.Note = ReadString(operation.Payload, "note");
        entity.PersonId = personId;
        return MarkChanged(entity, operation.Payload);
    }

    private async Task<long> ApplyAuxiliaryPioneerPeriodAsync(SyncOperationDto operation, Guid syncId, CancellationToken cancellationToken)
    {
        var entity = await _db.AuxiliaryPioneerPeriods.FirstOrDefaultAsync(a => a.SyncId == syncId, cancellationToken);
        if (IsDelete(operation))
            return Tombstone(entity, operation.Payload);

        var personId = await BaseEntityIdAsync(_db.Persons, ReadString(operation.Payload, "personSyncId"), cancellationToken)
            ?? throw new InvalidOperationException("Auxiliary pioneer period sync payload is missing a known personSyncId.");
        entity ??= Add(new AuxiliaryPioneerPeriod { SyncId = syncId });
        entity.StartMonth = (Month)(ReadInt(operation.Payload, "startMonth") ?? 1);
        entity.StartYear = ReadInt(operation.Payload, "startYear") ?? DateTime.UtcNow.Year;
        entity.EndMonth = ReadInt(operation.Payload, "endMonth") is { } endMonth ? (Month)endMonth : null;
        entity.EndYear = ReadInt(operation.Payload, "endYear");
        entity.PersonId = personId;
        return MarkChanged(entity, operation.Payload);
    }

    private T Add<T>(T entity) where T : class
    {
        _db.Add(entity);
        return entity;
    }

    private static long Tombstone(BaseEntity? entity, JsonElement payload)
    {
        if (entity is null)
            return ReadLong(payload, "serverVersion") ?? 0;

        entity.DeletedAt = DateTime.UtcNow;
        return MarkChanged(entity, payload);
    }

    private static long Tombstone(ServiceReport? entity, JsonElement payload)
    {
        if (entity is null)
            return ReadLong(payload, "serverVersion") ?? 0;

        entity.DeletedAt = DateTime.UtcNow;
        return MarkChanged(entity, payload);
    }

    private static long Tombstone(AuxiliaryPioneerPeriod? entity, JsonElement payload)
    {
        if (entity is null)
            return ReadLong(payload, "serverVersion") ?? 0;

        entity.DeletedAt = DateTime.UtcNow;
        return MarkChanged(entity, payload);
    }

    private static long MarkChanged(BaseEntity entity, JsonElement payload)
    {
        entity.CreatedAt = ReadDate(payload, "createdAt") ?? entity.CreatedAt;
        entity.ModifiedAt = DateTime.UtcNow;
        entity.DeletedAt = ReadDate(payload, "deletedAt") ?? entity.DeletedAt;
        entity.ServerVersion++;
        return entity.ServerVersion;
    }

    private static long MarkChanged(ServiceReport entity, JsonElement payload)
    {
        entity.CreatedAt = ReadDate(payload, "createdAt") ?? entity.CreatedAt;
        entity.ModifiedAt = DateTime.UtcNow;
        entity.DeletedAt = ReadDate(payload, "deletedAt") ?? entity.DeletedAt;
        entity.ServerVersion++;
        return entity.ServerVersion;
    }

    private static long MarkChanged(AuxiliaryPioneerPeriod entity, JsonElement payload)
    {
        entity.CreatedAt = ReadDate(payload, "createdAt") ?? entity.CreatedAt;
        entity.ModifiedAt = DateTime.UtcNow;
        entity.DeletedAt = ReadDate(payload, "deletedAt") ?? entity.DeletedAt;
        entity.ServerVersion++;
        return entity.ServerVersion;
    }

    private async Task<object> BuildServerPayloadAsync(string entityType, Guid syncId, CancellationToken cancellationToken) => entityType switch
    {
        "congregation" => CongregationPayload(await _db.Congregations.SingleAsync(c => c.SyncId == syncId, cancellationToken)),
        "fieldServiceGroup" => await FieldServiceGroupPayloadAsync(await _db.FieldServiceGroups.SingleAsync(g => g.SyncId == syncId, cancellationToken), cancellationToken),
        "person" => await PersonPayloadAsync(await _db.Persons.SingleAsync(p => p.SyncId == syncId, cancellationToken), cancellationToken),
        "phoneNumber" => await PhoneNumberPayloadAsync(await _db.PhoneNumbers.SingleAsync(p => p.SyncId == syncId, cancellationToken), cancellationToken),
        "emergencyContact" => await EmergencyContactPayloadAsync(await _db.EmergencyContacts.SingleAsync(e => e.SyncId == syncId, cancellationToken), cancellationToken),
        "serviceReport" => await ServiceReportPayloadAsync(await _db.ServiceReports.SingleAsync(s => s.SyncId == syncId, cancellationToken), cancellationToken),
        "auxiliaryPioneerPeriod" => await AuxiliaryPioneerPeriodPayloadAsync(await _db.AuxiliaryPioneerPeriods.SingleAsync(a => a.SyncId == syncId, cancellationToken), cancellationToken),
        _ => new { },
    };

    private async Task<VersionedEntity?> FindVersionedEntityAsync(string entityType, Guid syncId, CancellationToken cancellationToken) => entityType switch
    {
        "congregation" => ToVersioned(await _db.Congregations.AsNoTracking().FirstOrDefaultAsync(c => c.SyncId == syncId, cancellationToken)),
        "fieldServiceGroup" => ToVersioned(await _db.FieldServiceGroups.AsNoTracking().FirstOrDefaultAsync(g => g.SyncId == syncId, cancellationToken)),
        "person" => ToVersioned(await _db.Persons.AsNoTracking().FirstOrDefaultAsync(p => p.SyncId == syncId, cancellationToken)),
        "phoneNumber" => ToVersioned(await _db.PhoneNumbers.AsNoTracking().FirstOrDefaultAsync(p => p.SyncId == syncId, cancellationToken)),
        "emergencyContact" => ToVersioned(await _db.EmergencyContacts.AsNoTracking().FirstOrDefaultAsync(e => e.SyncId == syncId, cancellationToken)),
        "serviceReport" => ToVersioned(await _db.ServiceReports.AsNoTracking().FirstOrDefaultAsync(s => s.SyncId == syncId, cancellationToken)),
        "auxiliaryPioneerPeriod" => ToVersioned(await _db.AuxiliaryPioneerPeriods.AsNoTracking().FirstOrDefaultAsync(a => a.SyncId == syncId, cancellationToken)),
        _ => null,
    };

    private static VersionedEntity? ToVersioned(BaseEntity? entity) => entity is null ? null : new(entity.ServerVersion);
    private static VersionedEntity? ToVersioned(ServiceReport? entity) => entity is null ? null : new(entity.ServerVersion);
    private static VersionedEntity? ToVersioned(AuxiliaryPioneerPeriod? entity) => entity is null ? null : new(entity.ServerVersion);

    private static IQueryable<T> ChangedBaseEntities<T>(DbSet<T> set, DateTime? since) where T : BaseEntity =>
        set.AsNoTracking().Where(e => since == null || (e.ModifiedAt ?? e.CreatedAt) > since || e.DeletedAt > since);

    private IQueryable<ServiceReport> ChangedServiceReports(DateTime? since) =>
        _db.ServiceReports.AsNoTracking().Where(e => since == null || (e.ModifiedAt ?? e.CreatedAt) > since || e.DeletedAt > since);

    private IQueryable<AuxiliaryPioneerPeriod> ChangedAuxiliaryPioneerPeriods(DateTime? since) =>
        _db.AuxiliaryPioneerPeriods.AsNoTracking().Where(e => since == null || (e.ModifiedAt ?? e.CreatedAt) > since || e.DeletedAt > since);

    private static SyncChangeDto Change(string entityType, Guid syncId, string operationType, long version, DateTime modifiedAt, object payload) =>
        new(entityType, syncId.ToString(), operationType, version, modifiedAt, payload);

    private static DateTime LastModified(BaseEntity entity) => entity.DeletedAt ?? entity.ModifiedAt ?? entity.CreatedAt;
    private static DateTime LastModified(ServiceReport entity) => entity.DeletedAt ?? entity.ModifiedAt ?? entity.CreatedAt;
    private static DateTime LastModified(AuxiliaryPioneerPeriod entity) => entity.DeletedAt ?? entity.ModifiedAt ?? entity.CreatedAt;

    private static string RowOperation(BaseEntity entity) => RowOperation(entity.DeletedAt);
    private static string RowOperation(DateTime? deletedAt) => deletedAt is null ? "upsert" : "delete";

    private static Dictionary<string, object?> CongregationPayload(Congregation row) => new()
    {
        ["syncId"] = row.SyncId,
        ["serverVersion"] = row.ServerVersion,
        ["name"] = row.Name,
        ["number"] = row.Number,
        ["city"] = row.City,
        ["circuitNumber"] = row.CircuitNumber,
        ["createdAt"] = row.CreatedAt,
        ["updatedAt"] = row.ModifiedAt ?? row.CreatedAt,
        ["deletedAt"] = row.DeletedAt,
    };

    private async Task<Dictionary<string, object?>> FieldServiceGroupPayloadAsync(FieldServiceGroup row, CancellationToken cancellationToken) => new()
    {
        ["syncId"] = row.SyncId,
        ["serverVersion"] = row.ServerVersion,
        ["name"] = row.Name,
        ["description"] = row.Description,
        ["congregationSyncId"] = await BaseEntitySyncIdAsync(_db.Congregations, row.CongregationId, cancellationToken),
        ["groupOverseerSyncId"] = await BaseEntitySyncIdAsync(_db.Persons, row.GroupOverseerId, cancellationToken),
        ["assistantSyncId"] = await BaseEntitySyncIdAsync(_db.Persons, row.AssistantId, cancellationToken),
        ["createdAt"] = row.CreatedAt,
        ["updatedAt"] = row.ModifiedAt ?? row.CreatedAt,
        ["deletedAt"] = row.DeletedAt,
    };

    private async Task<Dictionary<string, object?>> PersonPayloadAsync(Person row, CancellationToken cancellationToken) => new()
    {
        ["syncId"] = row.SyncId,
        ["serverVersion"] = row.ServerVersion,
        ["firstName"] = row.FirstName,
        ["lastName"] = row.LastName,
        ["otherNames"] = row.OtherNames,
        ["birthDate"] = row.BirthDate,
        ["baptismDate"] = row.BaptismDate,
        ["gender"] = (int)row.Gender,
        ["hopeClass"] = (int)row.Hope,
        ["congregationRole"] = (int)row.CongregationRole,
        ["pioneerType"] = (int)row.PioneerType,
        ["address"] = row.Address,
        ["isActive"] = row.IsActive,
        ["inactiveDate"] = row.InactiveDate,
        ["congregationSyncId"] = await BaseEntitySyncIdAsync(_db.Congregations, row.CongregationId, cancellationToken),
        ["fieldServiceGroupSyncId"] = await BaseEntitySyncIdAsync(_db.FieldServiceGroups, row.FieldServiceGroupId, cancellationToken),
        ["createdAt"] = row.CreatedAt,
        ["updatedAt"] = row.ModifiedAt ?? row.CreatedAt,
        ["deletedAt"] = row.DeletedAt,
    };

    private async Task<Dictionary<string, object?>> PhoneNumberPayloadAsync(PhoneNumber row, CancellationToken cancellationToken) => new()
    {
        ["syncId"] = row.SyncId,
        ["serverVersion"] = row.ServerVersion,
        ["number"] = row.Number,
        ["phoneType"] = (int)row.PhoneType,
        ["isPrimary"] = row.IsPrimary,
        ["personSyncId"] = await BaseEntitySyncIdAsync(_db.Persons, row.PersonId, cancellationToken),
        ["deletedAt"] = row.DeletedAt,
    };

    private async Task<Dictionary<string, object?>> EmergencyContactPayloadAsync(EmergencyContact row, CancellationToken cancellationToken) => new()
    {
        ["syncId"] = row.SyncId,
        ["serverVersion"] = row.ServerVersion,
        ["name"] = row.Name,
        ["phoneNumber"] = row.PhoneNumber,
        ["relationship"] = (int)row.Relationship,
        ["isPrimary"] = row.IsPrimary,
        ["personSyncId"] = await BaseEntitySyncIdAsync(_db.Persons, row.PersonId, cancellationToken),
        ["deletedAt"] = row.DeletedAt,
    };

    private async Task<Dictionary<string, object?>> ServiceReportPayloadAsync(ServiceReport row, CancellationToken cancellationToken) => new()
    {
        ["syncId"] = row.SyncId,
        ["serverVersion"] = row.ServerVersion,
        ["year"] = row.Year,
        ["month"] = (int)row.Month,
        ["isAuxiliaryPioneer"] = row.IsAuxiliaryPioneer,
        ["isActive"] = row.IsActive,
        ["sharedInMinistry"] = row.SharedInMinistry,
        ["bibleStudies"] = row.BibleStudies,
        ["hours"] = row.Hours,
        ["note"] = row.Note,
        ["personSyncId"] = await BaseEntitySyncIdAsync(_db.Persons, row.PersonId, cancellationToken),
        ["deletedAt"] = row.DeletedAt,
    };

    private async Task<Dictionary<string, object?>> AuxiliaryPioneerPeriodPayloadAsync(AuxiliaryPioneerPeriod row, CancellationToken cancellationToken) => new()
    {
        ["syncId"] = row.SyncId,
        ["serverVersion"] = row.ServerVersion,
        ["startMonth"] = (int)row.StartMonth,
        ["startYear"] = row.StartYear,
        ["endMonth"] = row.EndMonth is null ? null : (int)row.EndMonth,
        ["endYear"] = row.EndYear,
        ["personSyncId"] = await BaseEntitySyncIdAsync(_db.Persons, row.PersonId, cancellationToken),
        ["deletedAt"] = row.DeletedAt,
    };

    private static async Task<int?> BaseEntityIdAsync<T>(DbSet<T> set, string? syncId, CancellationToken cancellationToken) where T : BaseEntity
    {
        if (!Guid.TryParse(syncId, out var guid))
            return null;

        return await set.AsNoTracking()
            .Where(e => e.SyncId == guid)
            .Select(e => (int?)e.Id)
            .SingleOrDefaultAsync(cancellationToken);
    }

    private static async Task<string?> BaseEntitySyncIdAsync<T>(DbSet<T> set, int? id, CancellationToken cancellationToken) where T : BaseEntity
    {
        if (id is null)
            return null;

        var syncId = await set.AsNoTracking()
            .Where(e => e.Id == id.Value)
            .Select(e => (Guid?)e.SyncId)
            .SingleOrDefaultAsync(cancellationToken);
        return syncId?.ToString();
    }

    private static bool IsDelete(SyncOperationDto operation) =>
        string.Equals(operation.OperationType, "delete", StringComparison.OrdinalIgnoreCase);

    private static string? ReadString(JsonElement element, string name) =>
        TryGet(element, name, out var property) && property.ValueKind != JsonValueKind.Null
            ? property.GetString()
            : null;

    private static int? ReadInt(JsonElement element, string name) =>
        TryGet(element, name, out var property) && property.ValueKind == JsonValueKind.Number
            ? property.GetInt32()
            : null;

    private static long? ReadLong(JsonElement element, string name) =>
        TryGet(element, name, out var property) && property.ValueKind == JsonValueKind.Number
            ? property.GetInt64()
            : null;

    private static double? ReadDouble(JsonElement element, string name) =>
        TryGet(element, name, out var property) && property.ValueKind == JsonValueKind.Number
            ? property.GetDouble()
            : null;

    private static bool? ReadBool(JsonElement element, string name) =>
        TryGet(element, name, out var property) && (property.ValueKind == JsonValueKind.True || property.ValueKind == JsonValueKind.False)
            ? property.GetBoolean()
            : null;

    private static DateTime? ReadDate(JsonElement element, string name) =>
        DateTime.TryParse(ReadString(element, name), out var date)
            ? date.ToUniversalTime()
            : null;

    private static TEnum ReadEnum<TEnum>(JsonElement element, string name, TEnum fallback)
        where TEnum : struct, Enum
    {
        var value = ReadInt(element, name);
        return value.HasValue && Enum.IsDefined(typeof(TEnum), value.Value)
            ? (TEnum)Enum.ToObject(typeof(TEnum), value.Value)
            : fallback;
    }

    private static bool TryGet(JsonElement element, string name, out JsonElement value)
    {
        foreach (var property in element.EnumerateObject())
        {
            if (string.Equals(property.Name, name, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }

        value = default;
        return false;
    }

    private sealed record VersionedEntity(long ServerVersion);
}
