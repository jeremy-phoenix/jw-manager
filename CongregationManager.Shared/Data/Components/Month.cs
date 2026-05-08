using System.ComponentModel.DataAnnotations;

namespace CongregationManager.Data.Components;

public enum Month
{
    [Display(Order = 0)]
    None = 0,

    [Display(Order = 5)]
    January = 1,

    [Display(Order = 6)]
    February = 2,

    [Display(Order = 7)]
    March = 3,

    [Display(Order = 8)]
    April = 4,

    [Display(Order = 9)]
    May = 5,

    [Display(Order = 10)]
    June = 6,

    [Display(Order = 11)]
    July = 7,

    [Display(Order = 12)]
    August = 8,

    [Display(Order = 1)]
    September = 9,

    [Display(Order = 2)]
    October = 10,

    [Display(Order = 3)]
    November = 11,

    [Display(Order = 4)]
    December = 12,
}
