using System.ComponentModel.DataAnnotations.Schema;
using CongregationManager.Data.Components;

namespace CongregationManager.Data.Models;

public class EmergencyContact : BaseEntity
{
    public string Name { get; set; } = string.Empty;

    public string? PhoneNumber { get; set; }

    public Relationship Relationship { get; set; }

    public bool IsPrimary { get; set; }

    public int PersonId { get; set; }

    [ForeignKey(nameof(PersonId))]
    public virtual Person Person { get; set; } = null!;

    public override string ToString() => $"{Name} ({Relationship})";
}
