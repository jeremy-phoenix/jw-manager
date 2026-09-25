import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/service_year.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';

/// Period the service reports screen opens on.
///
/// Until the 20th the reports for the current month are still coming in, so
/// the previous month is shown. The service year has to come from that same
/// month: on 1 September 2026 the screen shows August, which still belongs to
/// service year 2026, not to the 2027 one that started that very day.
({int serviceYear, int month}) defaultServiceReportPeriod([DateTime? date]) {
  final today = date ?? DateTime.now();
  final month = today.day <= 20
      ? DateTime(today.year, today.month - 1)
      : DateTime(today.year, today.month);
  return (
    serviceYear: serviceYearOf(month.year, month.month),
    month: month.month,
  );
}

/// Selected service year for service reports filter.
class SelectedYearNotifier extends Notifier<int> {
  @override
  int build() => defaultServiceReportPeriod().serviceYear;

  void set(int value) => state = value;
}

final selectedYearProvider = NotifierProvider<SelectedYearNotifier, int>(
  SelectedYearNotifier.new,
);

/// Selected month for service reports filter.
class SelectedMonthNotifier extends Notifier<int> {
  @override
  int build() => defaultServiceReportPeriod().month;

  void set(int value) => state = value;
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, int>(
  SelectedMonthNotifier.new,
);

/// Whether to show only not-shared reports.
class ShowNotSharedOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final showNotSharedOnlyProvider =
    NotifierProvider<ShowNotSharedOnlyNotifier, bool>(
      ShowNotSharedOnlyNotifier.new,
    );

/// Whether to include inactive publishers in the service reports list.
class ShowInactivePublishersNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final showInactivePublishersProvider =
    NotifierProvider<ShowInactivePublishersNotifier, bool>(
      ShowInactivePublishersNotifier.new,
    );

/// Search query for the service reports screen.
class ServiceReportSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final serviceReportSearchQueryProvider =
    NotifierProvider<ServiceReportSearchQueryNotifier, String>(
      ServiceReportSearchQueryNotifier.new,
    );

/// Service reports stream based on current filters.
final serviceReportsProvider = StreamProvider<List<ServiceReport>>((ref) {
  final db = ref.watch(databaseProvider);
  final year = ref.watch(selectedYearProvider);
  final month = ref.watch(selectedMonthProvider);
  final congId = ref.watch(currentCongregationIdProvider);
  final showInactivePublishers = ref.watch(showInactivePublishersProvider);
  return db.watchServiceReports(
    year: year,
    month: month,
    congregationId: congId,
    includeInactivePublishers: showInactivePublishers,
  );
});

/// Filtered service reports (with not-shared filter).
final filteredServiceReportsProvider =
    Provider<AsyncValue<List<ServiceReport>>>((ref) {
      final reportsAsync = ref.watch(serviceReportsProvider);
      final showNotSharedOnly = ref.watch(showNotSharedOnlyProvider);

      return reportsAsync.whenData((reports) {
        if (!showNotSharedOnly) return reports;
        return reports.where((r) => !r.sharedInMinistry).toList();
      });
    });

/// Service reports for a specific person.
final personServiceReportsProvider =
    FutureProvider.family<List<ServiceReport>, int>((ref, personId) {
      final db = ref.watch(databaseProvider);
      return db.getServiceReports(personId: personId);
    });

/// Available service years (computed from existing data).
final serviceYearsProvider = FutureProvider<List<int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final selectedYear = ref.watch(selectedYearProvider);
  final reports = await db.getServiceReports();
  final years = <int>{};
  for (final report in reports) {
    // A report already stores the service year it belongs to, September
    // included; deriving one again would invent a year with no data in it.
    years.add(report.year);
  }
  years.add(selectedYear);
  years.add(currentServiceYear());
  final sorted = years.toList()..sort((a, b) => b.compareTo(a));
  return sorted;
});
