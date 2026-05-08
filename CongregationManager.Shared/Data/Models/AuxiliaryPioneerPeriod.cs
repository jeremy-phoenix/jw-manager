using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Runtime.CompilerServices;
using System.Text.Json.Serialization;
using CongregationManager.Data.Components;

namespace CongregationManager.Data.Models;

/// <summary>
/// Represents a period during which a person serves as an Auxiliary Pioneer.
/// Can be for specific months, a range of months, or continuous (ongoing).
/// </summary>
public class AuxiliaryPioneerPeriod : INotifyPropertyChanged
{
    [Key]
    public int Id { get; set; }

    public Guid SyncId { get; set; } = Guid.NewGuid();

    public long ServerVersion { get; set; }

    public DateTime? DeletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ModifiedAt { get; set; }

    public int PersonId { get; set; }

    /// <summary>
    /// The month when auxiliary pioneering started.
    /// </summary>
    public Month StartMonth { get; set; }

    /// <summary>
    /// The year when auxiliary pioneering started.
    /// </summary>
    public int StartYear { get; set; }

    private Month? _endMonth;

    /// <summary>
    /// The month when auxiliary pioneering ended.
    /// Null if the period is continuous (ongoing).
    /// </summary>
    public Month? EndMonth
    {
        get => _endMonth;
        set { _endMonth = value; OnPropertyChanged(); OnPropertyChanged(nameof(IsContinuous)); }
    }

    private int? _endYear;

    /// <summary>
    /// The year when auxiliary pioneering ended.
    /// Null if the period is continuous (ongoing).
    /// </summary>
    public int? EndYear
    {
        get => _endYear;
        set { _endYear = value; OnPropertyChanged(); OnPropertyChanged(nameof(IsContinuous)); }
    }

    /// <summary>
    /// Indicates whether this is a continuous (ongoing) auxiliary pioneer period.
    /// Setting to true clears the end date; setting to false defaults end to the start date.
    /// </summary>
    [NotMapped]
    public bool IsContinuous
    {
        get => EndMonth is null && EndYear is null;
        set
        {
            if (value)
            {
                EndMonth = null;
                EndYear = null;
            }
            else
            {
                EndMonth ??= StartMonth;
                EndYear ??= StartYear;
            }
            OnPropertyChanged();
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

    [JsonIgnore]
    [ForeignKey(nameof(PersonId))]
    public virtual Person Person { get; set; } = default!;

    /// <summary>
    /// Determines if a given month/year falls within this auxiliary pioneer period.
    /// </summary>
    public bool IncludesMonth(Month month, int year)
    {
        var targetMonthIndex = ToMonthIndex(year, month);
        var startMonthIndex = ToMonthIndex(StartYear, StartMonth);

        // If continuous (no end date), check if target is >= start
        if (IsContinuous)
        {
            return targetMonthIndex >= startMonthIndex;
        }

        // If has an end date, check if target is within range
        var endMonthIndex = ToMonthIndex(EndYear!.Value, EndMonth!.Value);
        return targetMonthIndex >= startMonthIndex && targetMonthIndex <= endMonthIndex;
    }

    /// <summary>
    /// Converts service year and month to a comparable integer index.
    /// Uses service year ordering: Sep=1, Oct=2, ..., Aug=12.
    /// </summary>
    private static int ToMonthIndex(int year, Month month)
    {
        var serviceMonth = (int)month >= 9 ? (int)month - 8 : (int)month + 4;
        return year * 12 + serviceMonth;
    }

    public override string ToString()
    {
        var start = $"{StartMonth} {StartYear}";
        var end = IsContinuous ? "Ongoing" : $"{EndMonth} {EndYear}";
        return $"{start} - {end}";
    }
}
