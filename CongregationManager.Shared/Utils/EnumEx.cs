using System.ComponentModel.DataAnnotations;
using System.Reflection;

namespace CongregationManager.Utils;

public class EnumSelectItem
{
    public int Value { get; set; }
    public string Text { get; set; } = string.Empty;
}

public static class EnumEx
{
    public static List<EnumSelectItem> GetSelectList<TEnum>(bool excludeDefault = false) where TEnum : Enum
    {
        return Enum.GetValues(typeof(TEnum))
            .Cast<TEnum>()
            .Where(e => !excludeDefault || Convert.ToInt32(e) != 0)
            .OrderBy(e => e.GetDisplayOrder())
            .ThenBy(e => Convert.ToInt32(e))
            .Select(e => new EnumSelectItem
            {
                Value = Convert.ToInt32(e),
                Text = e.GetBestDisplayName()
            })
            .ToList();
    }

    private static int GetDisplayOrder(this Enum value)
    {
        var field = value.GetType().GetField(value.ToString());
        var attr = field?.GetCustomAttribute<DisplayAttribute>();
        return attr?.GetOrder() ?? int.MaxValue;
    }
}
