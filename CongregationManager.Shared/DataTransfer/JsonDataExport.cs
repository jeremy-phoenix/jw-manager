using CongregationManager.Data.Components;

namespace CongregationManager.DataTransfer;

public sealed class JsonDataExport
{
    public string FormatVersion { get; init; } = "1.0";
    public DateTime ExportedAtUtc { get; init; }
    public List<CongregationExportModel> Congregations { get; init; } = [];
    public List<FieldServiceGroupExportModel> FieldServiceGroups { get; init; } = [];
    public List<PersonExportModel> Persons { get; init; } = [];
}

public abstract class ExportEntityBase
{
    public int Id { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? ModifiedAt { get; init; }
    public string? CreatedBy { get; init; }
    public string? ModifiedBy { get; init; }
    public EntityStatus Status { get; init; }
}

public sealed class CongregationExportModel : ExportEntityBase
{
    public string Name { get; init; } = string.Empty;
    public string? Number { get; init; }
    public string? City { get; init; }
    public string? CircuitNumber { get; init; }
}

public sealed class FieldServiceGroupExportModel : ExportEntityBase
{
    public string Name { get; init; } = string.Empty;
    public string? Description { get; init; }
    public int? GroupOverseerId { get; init; }
    public int? AssistantId { get; init; }
    public int? CongregationId { get; init; }
}

public sealed class PersonExportModel : ExportEntityBase
{
    public string FirstName { get; init; } = string.Empty;
    public string LastName { get; init; } = string.Empty;
    public string? OtherNames { get; init; }
    public CongregationRole CongregationRole { get; init; }
    public PioneerType PioneerType { get; init; }
    public HopeClass Hope { get; init; }
    public DateTime? BirthDate { get; init; }
    public DateTime? BaptismDate { get; init; }
    public Gender Gender { get; init; }
    public string? Address { get; init; }
    public int? FieldServiceGroupId { get; init; }
    public int? CongregationId { get; init; }
    public bool IsActive { get; init; }
    public List<PhoneNumberExportModel> PhoneNumbers { get; init; } = [];
    public List<EmergencyContactExportModel> EmergencyContacts { get; init; } = [];
    public List<ServiceReportExportModel> ServiceReports { get; init; } = [];
    public List<AuxiliaryPioneerPeriodExportModel> AuxiliaryPioneerPeriods { get; init; } = [];
}

public sealed class PhoneNumberExportModel : ExportEntityBase
{
    public string Number { get; init; } = string.Empty;
    public PhoneType PhoneType { get; init; }
    public bool IsPrimary { get; init; }
    public int PersonId { get; init; }
}

public sealed class EmergencyContactExportModel : ExportEntityBase
{
    public string Name { get; init; } = string.Empty;
    public string? PhoneNumber { get; init; }
    public Relationship Relationship { get; init; }
    public bool IsPrimary { get; init; }
    public int PersonId { get; init; }
}

public sealed class ServiceReportExportModel
{
    public int Id { get; init; }
    public int PersonId { get; init; }
    public int Year { get; init; }
    public Month Month { get; init; }
    public bool IsAuxiliaryPioneer { get; init; }
    public bool IsActive { get; init; }
    public bool SharedInMinistry { get; init; }
    public int BibleStudies { get; init; }
    public float? Hours { get; init; }
    public string? Note { get; init; }
}

public sealed class AuxiliaryPioneerPeriodExportModel
{
    public int Id { get; init; }
    public int PersonId { get; init; }
    public Month StartMonth { get; init; }
    public int StartYear { get; init; }
    public Month? EndMonth { get; init; }
    public int? EndYear { get; init; }
}

public sealed class ImportFullExportResult
{
    public int CongregationsAdded { get; set; }
    public int CongregationsUpdated { get; set; }
    public int PersonsAdded { get; set; }
    public int PersonsUpdated { get; set; }
    public int GroupsAdded { get; set; }
    public int GroupsUpdated { get; set; }
    public int ServiceReportsAdded { get; set; }
}
