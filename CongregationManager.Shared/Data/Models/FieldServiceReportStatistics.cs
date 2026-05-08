namespace CongregationManager.Data.Models;

public class FieldServiceReportStatistics
{
    public int AllActivePublishers { get; set; }

    public ReportMetrics Publishers { get; set; } = new();
    public ReportMetrics AuxiliaryPioneers { get; set; } = new();
    public ReportMetrics RegularPioneers { get; set; } = new();

    public sealed class ReportMetrics
    {
        public int NumberOfReports { get; set; }
        public int BibleStudies { get; set; }
        public double Hours { get; set; }
    }
}
