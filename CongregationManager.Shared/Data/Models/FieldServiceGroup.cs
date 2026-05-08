using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace CongregationManager.Data.Models;

public class FieldServiceGroup : BaseEntity
{
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public int? GroupOverseerId { get; set; }

    public int? AssistantId { get; set; }

    public int? CongregationId { get; set; }

    [ForeignKey(nameof(GroupOverseerId))]
    public virtual Person? GroupOverseer { get; set; }

    [ForeignKey(nameof(AssistantId))]
    public virtual Person? Assistant { get; set; }

    [ForeignKey(nameof(CongregationId))]
    public virtual Congregation? Congregation { get; set; }

    public virtual ICollection<Person> Members { get; set; } = [];
}
