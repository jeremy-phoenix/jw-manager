import 'package:congregation_manager/data/enums.dart';

enum FieldServicePublisherCategory {
  publisher,
  auxiliaryPioneer,
  regularPioneer,
  specialPioneer,
  fieldMissionary,
}

FieldServicePublisherCategory classifyFieldServicePublisher({
  required PioneerType pioneerType,
  required bool isAuxiliaryPioneer,
}) {
  if (isAuxiliaryPioneer) {
    return FieldServicePublisherCategory.auxiliaryPioneer;
  }
  return switch (pioneerType) {
    PioneerType.regularPioneer => FieldServicePublisherCategory.regularPioneer,
    PioneerType.specialPioneer => FieldServicePublisherCategory.specialPioneer,
    PioneerType.fieldMissionary =>
      FieldServicePublisherCategory.fieldMissionary,
    PioneerType.none => FieldServicePublisherCategory.publisher,
  };
}

/// Chronological index of a service report period, September first.
///
/// [serviceYear] is the value stored on a report, which already names the
/// service year the month belongs to: the September through December of one
/// calendar year carry the same [serviceYear] as the January through August
/// that follow them. Ordering therefore only has to remap the month; deriving
/// a service year again would push September past January.
int serviceReportPeriodIndex(int serviceYear, int month) {
  final serviceMonth = month >= 9 ? month - 8 : month + 4;
  return serviceYear * 12 + serviceMonth;
}

class ReportMetrics {
  final int numberOfReports;
  final int bibleStudies;
  final double hours;
  final List<int> personIds;

  const ReportMetrics({
    this.numberOfReports = 0,
    this.bibleStudies = 0,
    this.hours = 0,
    this.personIds = const [],
  });
}

class FieldServiceReportStatistics {
  final int allActivePublishers;
  final ReportMetrics publishers;
  final ReportMetrics auxiliaryPioneers;
  final ReportMetrics regularPioneers;
  final ReportMetrics specialPioneers;
  final ReportMetrics fieldMissionaries;

  const FieldServiceReportStatistics({
    this.allActivePublishers = 0,
    this.publishers = const ReportMetrics(),
    this.auxiliaryPioneers = const ReportMetrics(),
    this.regularPioneers = const ReportMetrics(),
    this.specialPioneers = const ReportMetrics(),
    this.fieldMissionaries = const ReportMetrics(),
  });
}

class CongregationAnalysis {
  final int serviceYear;
  final int throughMonth;
  final List<int> allActivePersonIds;
  final List<int> newInactivePersonIds;
  final List<int> reactivatedPersonIds;

  int get allActivePublishers => allActivePersonIds.length;
  int get newInactivePublishers => newInactivePersonIds.length;
  int get reactivatedPublishers => reactivatedPersonIds.length;

  const CongregationAnalysis({
    required this.serviceYear,
    required this.throughMonth,
    this.allActivePersonIds = const [],
    this.newInactivePersonIds = const [],
    this.reactivatedPersonIds = const [],
  });
}
