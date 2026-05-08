using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Reflection;

namespace CongregationManager.Utils;

public static class EnumExtensions
{
    public static string GetBestDisplayName(this Enum value)
    {
        var field = value.GetType().GetField(value.ToString());
        if (field == null) return value.ToString();

        var displayAttr = field.GetCustomAttribute<DisplayAttribute>();
        if (displayAttr?.Name != null) return displayAttr.Name;

        var descAttr = field.GetCustomAttribute<DescriptionAttribute>();
        if (descAttr?.Description != null) return descAttr.Description;

        // Insert spaces before capitals: "OtherSheep" -> "Other Sheep"
        return System.Text.RegularExpressions.Regex.Replace(value.ToString(), "(?<!^)([A-Z])", " $1");
    }
}
