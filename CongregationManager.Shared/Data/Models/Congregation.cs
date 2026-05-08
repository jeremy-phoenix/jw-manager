namespace CongregationManager.Data.Models;

public class Congregation : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Number { get; set; }
    public string? City { get; set; }
    public string? CircuitNumber { get; set; }

    public virtual ICollection<Person> Members { get; set; } = [];
}
