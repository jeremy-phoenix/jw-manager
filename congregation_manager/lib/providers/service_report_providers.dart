import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';

/// Selected year for service reports filter.
class SelectedYearNotifier extends Notifier<int> {
  @override
  int build() {
    final now = DateTime.now();
    return now.month >= 9 ? now.year + 1 : now.year;
  }

  void set(int value) => state = value;
}

final selectedYearProvider = NotifierProvider<SelectedYearNotifier, int>(
  SelectedYearNotifier.new,
);

/// Selected month for service reports filter.
class SelectedMonthNotifier extends Notifier<int> {
  @override
  int build() {
    final now = DateTime.now();
    // If day <= 20, default to previous month
    if (now.day <= 20) {
      final prev = DateTime(now.year, now.month - 1);
      return prev.month;
    }
    return now.month;
  }

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
    // Service year: Sep=next year, Jan-Aug=same year
    final serviceYear = report.month >= 9 ? report.year + 1 : report.year;
    years.add(serviceYear);
  }
  final now = DateTime.now();
  final currentServiceYear = now.month >= 9 ? now.year + 1 : now.year;
  years.add(selectedYear);
  years.add(currentServiceYear);
  final sorted = years.toList()..sort((a, b) => b.compareTo(a));
  return sorted;
});
