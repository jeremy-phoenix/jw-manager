using System.ComponentModel.DataAnnotations.Schema;
using CongregationManager.Data.Components;

namespace CongregationManager.Data.Models;

public class PhoneNumber : BaseEntity
{
    public string Number { get; set; } = string.Empty;

    public PhoneType PhoneType { get; set; }

    public bool IsPrimary { get; set; }

    public int PersonId { get; set; }

    [ForeignKey(nameof(PersonId))]
    public virtual Person Person { get; set; } = null!;

    public override string ToString() => $"{PhoneType}: {Number}";
}
