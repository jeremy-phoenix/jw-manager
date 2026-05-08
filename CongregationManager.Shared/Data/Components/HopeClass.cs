using System.ComponentModel.DataAnnotations;

namespace CongregationManager.Data.Components;

public enum HopeClass
{
    [Display(Name = "Unknown")]
    Unknown,

    [Display(Name = "Other Sheep")]
    OtherSheep,

    [Display(Name = "Anointed")]
    Anointed,
}
