using System.Collections.Generic;

namespace CongregationManager.Data.Models;

public class CongregationSummary
{
    public int AllActivePublishers { get; set; }
    public int NewInactivePublishers { get; set; }
    public int ReactivatedPublishers { get; set; }
}

public class CongregationSummaryDetailed
{
    public List<Person> AllActivePublishers { get; set; } = [];
    public List<Person> NewInactivePublishers { get; set; } = [];
    public List<Person> ReactivatedPublishers { get; set; } = [];
}
