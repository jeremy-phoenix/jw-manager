using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using CongregationManager.Data.Components;

namespace CongregationManager.Data.Models;

public class Person : BaseEntity
{
    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public string? OtherNames { get; set; }

    public CongregationRole CongregationRole { get; set; }
    public PioneerType PioneerType { get; set; }
    public HopeClass Hope { get; set; }

    public DateTime? BirthDate { get; set; }

    public DateTime? BaptismDate { get; set; }

    public Gender Gender { get; set; }

    public string? Address { get; set; }

    public int? FieldServiceGroupId { get; set; }

    public int? CongregationId { get; set; }

    public bool IsActive { get; set; }

    public DateTime? InactiveDate { get; set; }

    [NotMapped]
    public string FullName =>
        string.Join(
            " ",
            new[] { FirstName, LastName }
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .Select(s => s!.Trim())
        );

    [ForeignKey(nameof(FieldServiceGroupId))]
    public virtual FieldServiceGroup? FieldServiceGroup { get; set; }

    [ForeignKey(nameof(CongregationId))]
    public virtual Congregation? Congregation { get; set; }

    public virtual ICollection<EmergencyContact> EmergencyContacts { get; set; } = [];
    public virtual ICollection<PhoneNumber> PhoneNumbers { get; set; } = [];
    public virtual ICollection<ServiceReport> ServiceReports { get; set; } = [];
    public virtual ICollection<AuxiliaryPioneerPeriod> AuxiliaryPioneerPeriods { get; set; } = [];

    /// <summary>
    /// Determines if this person is an Auxiliary Pioneer for the given month and year.
    /// </summary>
    public bool IsAuxiliaryPioneerFor(Month month, int year) =>
        AuxiliaryPioneerPeriods.Any(p => p.IncludesMonth(month, year));

    public override string ToString() => $"{Id} - {FullName}";

    /// <summary>
    /// Creates a deep clone of this person, including child collections.
    /// The clone is detached from EF Core tracking, safe for UI editing.
    /// MemberwiseClone handles all scalar/value-type properties automatically,
    /// so new properties added to Person are included without code changes.
    /// </summary>
    public Person DeepClone()
    {
        var clone = (Person)MemberwiseClone();

        // MemberwiseClone copies collection references, so replace with independent copies
        clone.PhoneNumbers = PhoneNumbers
            .Select(p => new PhoneNumber
            {
                Id = p.Id,
                SyncId = p.SyncId,
                ServerVersion = p.ServerVersion,
                DeletedAt = p.DeletedAt,
                Number = p.Number,
                PhoneType = p.PhoneType,
                IsPrimary = p.IsPrimary,
                PersonId = p.PersonId,
            })
            .ToList();

        clone.EmergencyContacts = EmergencyContacts
            .Select(c => new EmergencyContact
            {
                Id = c.Id,
                SyncId = c.SyncId,
                ServerVersion = c.ServerVersion,
                DeletedAt = c.DeletedAt,
                Name = c.Name,
                PhoneNumber = c.PhoneNumber,
                Relationship = c.Relationship,
                IsPrimary = c.IsPrimary,
                PersonId = c.PersonId,
            })
            .ToList();

        clone.AuxiliaryPioneerPeriods = AuxiliaryPioneerPeriods
            .Select(p => new AuxiliaryPioneerPeriod
            {
                Id = p.Id,
                SyncId = p.SyncId,
                ServerVersion = p.ServerVersion,
                DeletedAt = p.DeletedAt,
                PersonId = p.PersonId,
                StartMonth = p.StartMonth,
                StartYear = p.StartYear,
                EndMonth = p.EndMonth,
                EndYear = p.EndYear,
            })
            .ToList();

        clone.ServiceReports = ServiceReports
            .Select(r => new ServiceReport
            {
                Id = r.Id,
                SyncId = r.SyncId,
                ServerVersion = r.ServerVersion,
                DeletedAt = r.DeletedAt,
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
            .ToList();

        return clone;
    }
}
