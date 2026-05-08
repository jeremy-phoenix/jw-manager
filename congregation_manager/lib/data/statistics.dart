class ReportMetrics {
  final int numberOfReports;
  final int bibleStudies;
  final double hours;

  const ReportMetrics({
    this.numberOfReports = 0,
    this.bibleStudies = 0,
    this.hours = 0,
  });
}

class FieldServiceReportStatistics {
  final int allActivePublishers;
  final ReportMetrics publishers;
  final ReportMetrics auxiliaryPioneers;
  final ReportMetrics regularPioneers;

  const FieldServiceReportStatistics({
    this.allActivePublishers = 0,
    this.publishers = const ReportMetrics(),
    this.auxiliaryPioneers = const ReportMetrics(),
    this.regularPioneers = const ReportMetrics(),
  });
}

class CongregationAnalysis {
  final int allActivePublishers;
  final int newInactivePublishers;
  final int reactivatedPublishers;

  const CongregationAnalysis({
    this.allActivePublishers = 0,
    this.newInactivePublishers = 0,
    this.reactivatedPublishers = 0,
  });
}
