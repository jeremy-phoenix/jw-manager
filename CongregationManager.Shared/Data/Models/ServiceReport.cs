using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using CommunityToolkit.Mvvm.ComponentModel;
using CongregationManager.Data.Components;

namespace CongregationManager.Data.Models;

public partial class ServiceReport : ObservableObject
{
    [Key]
    public int Id { get; set; }

    public Guid SyncId { get; set; } = Guid.NewGuid();

    public long ServerVersion { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ModifiedAt { get; set; }

    public int PersonId { get; set; }

    [ObservableProperty]
    public partial int Year { get; set; }

    [ObservableProperty]
    public partial bool IsAuxiliaryPioneer { get; set; }

    public Month Month { get; set; }

    [ObservableProperty]
    public partial bool IsActive { get; set; }

    [ObservableProperty]
    public partial bool SharedInMinistry { get; set; }

    [ObservableProperty]
    public partial int BibleStudies { get; set; }

    [ObservableProperty]
    public partial float? Hours { get; set; }

    [ObservableProperty]
    public partial string? Note { get; set; }

    [JsonIgnore]
    [ForeignKey(nameof(PersonId))]
    public virtual Person Person { get; set; } = default!;

    [NotMapped]
    public bool HasHighBibleStudies => BibleStudies > 10;

    [NotMapped]
    public bool IsPioneer => Person is not null && Person.PioneerType is not PioneerType.None;

    public override string? ToString() =>
        $"Person Id={PersonId}, Year={Year}, Month={Month}, SharedInMinistry={SharedInMinistry}";
}
