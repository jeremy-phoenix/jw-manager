using System.ComponentModel.DataAnnotations;

namespace CongregationManager.Data.Components;

public enum CongregationRole
{
    None,

    [Display(Name = "Elder")]
    Elder,

    [Display(Name = "Ministerial Servant")]
    MinisterialServant,
}
