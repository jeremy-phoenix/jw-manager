using System;
using System.ComponentModel.DataAnnotations;
using CongregationManager.Data.Components;

namespace CongregationManager.Data.Models;

public abstract class BaseEntity
{
    [Key]
    public int Id { get; set; }

    public Guid SyncId { get; set; } = Guid.NewGuid();

    public long ServerVersion { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ModifiedAt { get; set; }

    public string? CreatedBy { get; set; }

    public string? ModifiedBy { get; set; }

    public EntityStatus Status { get; set; } = EntityStatus.Active;
}
