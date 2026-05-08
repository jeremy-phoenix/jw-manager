using System.ComponentModel.DataAnnotations;

namespace CongregationManager.Data.Components;

public enum UserRole
{
    [Display(Name = "Viewer")]
    Viewer,

    [Display(Name = "Editor")]
    Editor,

    [Display(Name = "Admin")]
    Admin,

    [Display(Name = "Super Admin")]
    SuperAdmin,
}
