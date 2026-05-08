using System.ComponentModel.DataAnnotations;

namespace CongregationManager.Data.Components;

public enum PioneerType
{
    None,

    [Display(Name = "Regular Pioneer")]
    RegularPioneer,

    [Display(Name = "Special Pioneer")]
    SpecialPioneer,

    [Display(Name = "Field Missionary")]
    FieldMissionary,
}
