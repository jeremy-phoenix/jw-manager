import 'package:drift/drift.dart' as drift;
import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/data/statistics.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';
import 'package:congregation_manager/reporting/report_service.dart';
import 'package:congregation_manager/ui/widgets/app_popup_menu_item.dart';
import 'package:congregation_manager/ui/widgets/search_text_field.dart';
import 'package:congregation_manager/ui/widgets/sticky_data_table.dart';

class ServiceReportListScreen extends ConsumerWidget {
  const ServiceReportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(filteredServiceReportsProvider);
    final selectedYear = ref.watch(selectedYearProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final showNotSharedOnly = ref.watch(showNotSharedOnlyProvider);
    final showInactivePublishers = ref.watch(showInactivePublishersProvider);
    final searchQuery = ref.watch(serviceReportSearchQueryProvider);
    final serviceYears = ref.watch(serviceYearsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Month's Statistics",
            onPressed: () => _showMonthStatistics(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Congregation Analysis',
            onPressed: () => _showCongregationAnalysis(context, ref),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.print),
            tooltip: 'Export Reports',
            onSelected: (value) {
              final svc = ReportService(
                ref.read(databaseProvider),
                congregationId: ref.read(currentCongregationIdProvider),
              );
              final year = selectedYear;
              final month = selectedMonth;
              switch (value) {
                case 'reports_by_group':
                  svc.previewServiceReportsByGroup(
                    context,
                    year: year,
                    month: month,
                  );
                case 'group_totals':
                  svc.previewFieldServiceGroupSummary(
                    context,
                    year: year,
                    month: month,
                  );
                case 'pioneer_hours':
                  svc.previewPioneerHours(context, year: year, month: month);
                case 'missing_by_group':
                  svc.previewMissingReportsByGroup(
                    context,
                    year: year,
                    month: month,
                  );
                case 'not_shared':
                  svc.previewNotSharedInMinistry(
                    context,
                    year: year,
                    month: month,
                  );
                case 'not_shared_group':
                  svc.previewNotSharedByGroup(
                    context,
                    year: year,
                    month: month,
                  );
                case 'delete_reports':
                  _deleteReports(context, ref);
              }
            },
            itemBuilder: (_) => [
              AppPopupMenuItem(
                value: 'reports_by_group',
                icon: Icons.groups,
                label: 'Reports by Group',
              ),
              AppPopupMenuItem(
                value: 'group_totals',
                icon: Icons.summarize,
                label: 'Group Totals Summary',
              ),
              AppPopupMenuItem(
                value: 'pioneer_hours',
                icon: Icons.star,
                label: 'Pioneer Hours',
              ),
              AppPopupMenuItem(
                value: 'missing_by_group',
                icon: Icons.report_off,
                label: 'Missing Reports by Group',
              ),
              PopupMenuDivider(),
              AppPopupMenuItem(
                value: 'not_shared',
                icon: Icons.person_off,
                label: 'Not Shared in Ministry',
              ),
              AppPopupMenuItem(
                value: 'not_shared_group',
                icon: Icons.group_off,
                label: 'Not Shared by Group',
              ),
              PopupMenuDivider(),
              AppPopupMenuItem(
                value: 'delete_reports',
                icon: Icons.delete_outline,
                label: 'Delete Reports...',
                color: Colors.red,
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export Excel',
            onSelected: (value) {
              final svc = ReportService(
                ref.read(databaseProvider),
                congregationId: ref.read(currentCongregationIdProvider),
              );
              final year = selectedYear;
              final month = selectedMonth;
              final suffix = _periodFileSuffix(year, month);
              switch (value) {
                case 'reports_by_group':
                  _exportExcelReport(
                    context,
                    build: () => svc.buildServiceReportsByGroupExcelBytes(
                      year: year,
                      month: month,
                    ),
                    fileName: 'Reports_by_Group_$suffix.xlsx',
                  );
                case 'group_totals':
                  _exportExcelReport(
                    context,
                    build: () => svc.buildFieldServiceGroupSummaryExcelBytes(
                      year: year,
                      month: month,
                    ),
                    fileName: 'Group_Totals_$suffix.xlsx',
                  );
                case 'pioneer_hours':
                  _exportExcelReport(
                    context,
                    build: () => svc.buildPioneerHoursExcelBytes(
                      year: year,
                      month: month,
                    ),
                    fileName: 'Pioneer_Hours_$suffix.xlsx',
                  );
                case 'missing_by_group':
                  _exportExcelReport(
                    context,
                    build: () => svc.buildMissingReportsByGroupExcelBytes(
                      year: year,
                      month: month,
                    ),
                    fileName: 'Missing_Reports_$suffix.xlsx',
                  );
              }
            },
            itemBuilder: (_) => [
              AppPopupMenuItem(
                value: 'reports_by_group',
                icon: Icons.groups,
                label: 'Reports by Group',
              ),
              AppPopupMenuItem(
                value: 'group_totals',
                icon: Icons.summarize,
                label: 'Group Totals Summary',
              ),
              AppPopupMenuItem(
                value: 'pioneer_hours',
                icon: Icons.star,
                label: 'Pioneer Hours',
              ),
              AppPopupMenuItem(
                value: 'missing_by_group',
                icon: Icons.report_off,
                label: 'Missing Reports by Group',
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Generate Reports for Period',
            onPressed: () => _generateReports(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(
            ref: ref,
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
            showNotSharedOnly: showNotSharedOnly,
            showInactivePublishers: showInactivePublishers,
            searchQuery: searchQuery,
            serviceYears: serviceYears,
          ),
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const Center(
                    child: Text('No service reports for this period.'),
                  );
                }
                return _ReportDataTable(
                  reports: reports,
                  searchQuery: searchQuery,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters({
    required WidgetRef ref,
    required int selectedYear,
    required int selectedMonth,
    required bool showNotSharedOnly,
    required bool showInactivePublishers,
    required String searchQuery,
    required AsyncValue<List<int>> serviceYears,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;

          if (isCompact) {
            return _buildCompactFilters(
              ref: ref,
              selectedYear: selectedYear,
              selectedMonth: selectedMonth,
              showNotSharedOnly: showNotSharedOnly,
              showInactivePublishers: showInactivePublishers,
              searchQuery: searchQuery,
              serviceYears: serviceYears,
            );
          }

          return _buildWideFilters(
            ref: ref,
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
            showNotSharedOnly: showNotSharedOnly,
            showInactivePublishers: showInactivePublishers,
            searchQuery: searchQuery,
            serviceYears: serviceYears,
          );
        },
      ),
    );
  }

  Widget _buildCompactFilters({
    required WidgetRef ref,
    required int selectedYear,
    required int selectedMonth,
    required bool showNotSharedOnly,
    required bool showInactivePublishers,
    required String searchQuery,
    required AsyncValue<List<int>> serviceYears,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _MonthNavButton(
              icon: Icons.chevron_left,
              tooltip: 'Previous Month',
              onPressed: () => _changeMonth(ref, -1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildYearSelector(ref, selectedYear, serviceYears),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _buildMonthSelector(ref, selectedMonth)),
            const SizedBox(width: 8),
            _MonthNavButton(
              icon: Icons.chevron_right,
              tooltip: 'Next Month',
              onPressed: () => _changeMonth(ref, 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSearchField(ref, searchQuery)),
            const SizedBox(width: 8),
            _buildMoreFilters(
              ref,
              showNotSharedOnly: showNotSharedOnly,
              showInactivePublishers: showInactivePublishers,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideFilters({
    required WidgetRef ref,
    required int selectedYear,
    required int selectedMonth,
    required bool showNotSharedOnly,
    required bool showInactivePublishers,
    required String searchQuery,
    required AsyncValue<List<int>> serviceYears,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildYearSelector(ref, selectedYear, serviceYears),
            ),
            const SizedBox(width: 8),
            _MonthNavButton(
              icon: Icons.chevron_left,
              tooltip: 'Previous Month',
              onPressed: () => _changeMonth(ref, -1),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: _buildMonthSelector(ref, selectedMonth)),
            const SizedBox(width: 8),
            _MonthNavButton(
              icon: Icons.chevron_right,
              tooltip: 'Next Month',
              onPressed: () => _changeMonth(ref, 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSearchField(ref, searchQuery)),
            const SizedBox(width: 8),
            _buildMoreFilters(
              ref,
              showNotSharedOnly: showNotSharedOnly,
              showInactivePublishers: showInactivePublishers,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearSelector(
    WidgetRef ref,
    int selectedYear,
    AsyncValue<List<int>> serviceYears,
  ) {
    return serviceYears.when(
      data: (years) => DropdownButtonFormField<int>(
        initialValue: selectedYear,
        isExpanded: true,
        decoration: _filterDecoration('Year'),
        items: years
            .map(
              (year) => DropdownMenuItem(
                value: year,
                child: Text('$year', overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(selectedYearProvider.notifier).set(value);
          }
        },
      ),
      loading: () => _DisabledFilterField(label: 'Year'),
      error: (e, s) => _DisabledFilterField(label: 'Year', value: '–'),
    );
  }

  Widget _buildMonthSelector(WidgetRef ref, int selectedMonth) {
    return DropdownButtonFormField<int>(
      initialValue: selectedMonth,
      isExpanded: true,
      decoration: _filterDecoration('Month'),
      items: ServiceMonth.values
          .map(
            (month) => DropdownMenuItem(
              value: month.monthNumber,
              child: Text(month.displayName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          ref.read(selectedMonthProvider.notifier).set(value);
        }
      },
    );
  }

  Widget _buildSearchField(WidgetRef ref, String searchQuery) {
    return SearchTextField(
      query: searchQuery,
      hintText: 'Search reports...',
      onChanged: (value) =>
          ref.read(serviceReportSearchQueryProvider.notifier).set(value),
      onClear: () =>
          ref.read(serviceReportSearchQueryProvider.notifier).set(''),
    );
  }

  Widget _buildMoreFilters(
    WidgetRef ref, {
    required bool showNotSharedOnly,
    required bool showInactivePublishers,
  }) {
    final hasActiveFilters = showNotSharedOnly || showInactivePublishers;

    return PopupMenuButton<String>(
      icon: Icon(hasActiveFilters ? Icons.tune : Icons.more_horiz),
      tooltip: 'More filters',
      onSelected: (value) {
        switch (value) {
          case 'notShared':
            ref
                .read(showNotSharedOnlyProvider.notifier)
                .set(!showNotSharedOnly);
          case 'inactive':
            ref
                .read(showInactivePublishersProvider.notifier)
                .set(!showInactivePublishers);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'notShared',
          child: _MoreFilterMenuItem(
            checked: showNotSharedOnly,
            label: 'Not shared only',
          ),
        ),
        PopupMenuItem(
          value: 'inactive',
          child: _MoreFilterMenuItem(
            checked: showInactivePublishers,
            label: 'Show inactive publishers',
          ),
        ),
      ],
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  void _changeMonth(WidgetRef ref, int direction) {
    final currentYear = ref.read(selectedYearProvider);
    final currentMonth = ref.read(selectedMonthProvider);

    var nextYear = currentYear;
    late final int nextMonth;

    if (direction < 0) {
      if (currentMonth == 9) {
        nextYear--;
        nextMonth = 8;
      } else {
        nextMonth = currentMonth == 1 ? 12 : currentMonth - 1;
      }
    } else {
      if (currentMonth == 8) {
        nextYear++;
        nextMonth = 9;
      } else {
        nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
      }
    }

    ref.read(selectedYearProvider.notifier).set(nextYear);
    ref.read(selectedMonthProvider.notifier).set(nextMonth);
  }
}

class _MoreFilterMenuItem extends StatelessWidget {
  final bool checked;
  final String label;

  const _MoreFilterMenuItem({required this.checked, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          child: IgnorePointer(
            child: Checkbox(
              value: checked,
              onChanged: (_) {},
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MonthNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      icon: Icon(icon),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }
}

class _DisabledFilterField extends StatelessWidget {
  final String label;
  final String value;

  const _DisabledFilterField({required this.label, this.value = ''});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabled: false,
      ),
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

String _periodFileSuffix(int year, int month) {
  return '${year}_${month.toString().padLeft(2, '0')}';
}

Future<void> _exportExcelReport(
  BuildContext context, {
  required Future<Uint8List> Function() build,
  required String fileName,
}) async {
  try {
    final bytes = await build();
    final filePath = await FilePicker.saveFile(
      dialogTitle: 'Export Excel',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );
    if (filePath == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel report exported successfully.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

Future<void> _generateReports(BuildContext context, WidgetRef ref) async {
  final year = ref.read(selectedYearProvider);
  final month = ref.read(selectedMonthProvider);
  final db = ref.read(databaseProvider);
  final monthName = DateFormat.MMMM().format(DateTime(2000, month));

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      var scope = 'month';
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Generate Reports'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate service report entries for all active publishers.',
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'month',
                    label: Text('$monthName $year'),
                  ),
                  ButtonSegment(
                    value: 'year',
                    label: Text('Entire Year ($year)'),
                  ),
                ],
                selected: {scope},
                onSelectionChanged: (values) =>
                    setState(() => scope = values.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(scope),
              child: const Text('Generate'),
            ),
          ],
        ),
      );
    },
  );

  if (result == 'month') {
    final congId = ref.read(currentCongregationIdProvider);
    await db.getOrCreateReportsForPeriod(year, month, congregationId: congId);
    ref.invalidate(serviceReportsProvider);
  } else if (result == 'year') {
    final congId = ref.read(currentCongregationIdProvider);
    for (int m = 1; m <= 12; m++) {
      await db.getOrCreateReportsForPeriod(year, m, congregationId: congId);
    }
    ref.invalidate(serviceReportsProvider);
  }
}

Future<void> _deleteReports(BuildContext context, WidgetRef ref) async {
  final year = ref.read(selectedYearProvider);
  final month = ref.read(selectedMonthProvider);
  final db = ref.read(databaseProvider);
  final monthName = DateFormat.MMMM().format(DateTime(2000, month));

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      var scope = 'month';
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Delete Reports'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete all service reports for the selected period.',
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'month',
                    label: Text('$monthName $year'),
                  ),
                  ButtonSegment(
                    value: 'year',
                    label: Text('Entire Year ($year)'),
                  ),
                ],
                selected: {scope},
                onSelectionChanged: (values) =>
                    setState(() => scope = values.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(scope),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    },
  );

  if (result == 'month') {
    await db.deleteServiceReportsByMonth(year, month);
    ref.invalidate(serviceReportsProvider);
  } else if (result == 'year') {
    await db.deleteServiceReportsByYear(year);
    ref.invalidate(serviceReportsProvider);
  }
}

Future<void> _showMonthStatistics(BuildContext context, WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final year = ref.read(selectedYearProvider);
  final month = ref.read(selectedMonthProvider);
  final stats = await db.getMonthStatistics(
    year,
    month,
    congregationId: ref.read(currentCongregationIdProvider),
  );
  final monthName = DateFormat.MMMM().format(DateTime(2000, month));

  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("$monthName $year — Month's Statistics"),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatCard(
                icon: Icons.people,
                title: 'All Active Publishers',
                value: '${stats.allActivePublishers}',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricsCard(
                    icon: Icons.person,
                    title: 'Publishers',
                    metrics: stats.publishers,
                    showHours: false,
                  ),
                  _MetricsCard(
                    icon: Icons.person_pin,
                    title: 'Auxiliary Pioneers',
                    metrics: stats.auxiliaryPioneers,
                  ),
                  _MetricsCard(
                    icon: Icons.star,
                    title: 'Regular Pioneers',
                    metrics: stats.regularPioneers,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _showCongregationAnalysis(
  BuildContext context,
  WidgetRef ref,
) async {
  final db = ref.read(databaseProvider);
  final analysis = await db.getCongregationAnalysis(
    congregationId: ref.read(currentCongregationIdProvider),
  );

  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Congregation Analysis'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatCard(
              icon: Icons.people,
              title: 'All Active Publishers',
              value: '${analysis.allActivePublishers}',
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.person_off,
              title: 'New Inactive Publishers',
              value: '${analysis.newInactivePublishers}',
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.refresh,
              title: 'Reactivated Publishers',
              value: '${analysis.reactivatedPublishers}',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _ReportDataTable extends ConsumerStatefulWidget {
  final List<ServiceReport> reports;
  final String searchQuery;

  const _ReportDataTable({required this.reports, required this.searchQuery});

  @override
  ConsumerState<_ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends ConsumerState<_ReportDataTable> {
  // Cache of person names by ID
  final Map<int, String> _personNames = {};
  final Map<int, bool> _personIsActive = {};
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadPersonNames();
  }

  Future<void> _loadPersonNames() async {
    final db = ref.read(databaseProvider);
    final persons = await db.getAllPersons(
      congregationId: ref.read(currentCongregationIdProvider),
    );
    if (!mounted) return;
    final order = ref.read(nameOrderProvider);
    setState(() {
      for (final p in persons) {
        _personNames[p.id] = formatPersonName(p.firstName, p.lastName, order);
        _personIsActive[p.id] = p.isActive;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _filterReports(widget.reports);
    if (_sortColumnIndex != null) {
      sorted.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0: // Name
            final nameA = _personNames[a.personId] ?? '';
            final nameB = _personNames[b.personId] ?? '';
            result = nameA.compareTo(nameB);
          case 1: // Month
            result = (a.year * 100 + a.month).compareTo(b.year * 100 + b.month);
          case 2: // Shared
            result = (a.sharedInMinistry ? 1 : 0).compareTo(
              b.sharedInMinistry ? 1 : 0,
            );
          case 3: // Studies
            result = a.bibleStudies.compareTo(b.bibleStudies);
          case 4: // Hours
            result = a.hours.compareTo(b.hours);
          case 5: // Aux Pioneer
            result = (a.isAuxiliaryPioneer ? 1 : 0).compareTo(
              b.isAuxiliaryPioneer ? 1 : 0,
            );
          case 6: // Notes/Remarks
            result = a.note.compareTo(b.note);
          default:
            result = 0;
        }
        return _sortAscending ? result : -result;
      });
    }

    if (sorted.isEmpty) {
      return const Center(child: Text('No matching service reports.'));
    }

    final isWide = MediaQuery.of(context).size.width >= 600;
    return isWide ? _buildDataGrid(sorted) : _buildCardList(sorted);
  }

  List<ServiceReport> _filterReports(List<ServiceReport> reports) {
    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return List<ServiceReport>.from(reports);

    return reports.where((report) {
      final name = (_personNames[report.personId] ?? '').toLowerCase();
      final monthName = DateFormat.MMMM()
          .format(DateTime(report.year, report.month))
          .toLowerCase();
      final values = [
        name,
        monthName,
        '${report.year}',
        report.sharedInMinistry ? 'shared yes true' : 'not shared no false',
        '${report.bibleStudies}',
        '${report.hours}',
        report.isAuxiliaryPioneer ? 'aux pioneer auxiliary yes true' : '',
        report.note.toLowerCase(),
      ].join(' ');
      return values.contains(query);
    }).toList();
  }

  Widget _buildCardList(List<ServiceReport> sorted) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final report = sorted[index];
        final name = _displayName(report);
        final monthName = DateFormat.MMMM().format(
          DateTime(report.year, report.month),
        );

        return Card(
          key: ValueKey('service-report-card-${report.id}'),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => _deleteReport(report),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Text(
                  '$monthName ${report.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          key: ValueKey('service-report-${report.id}-shared'),
                          value: report.sharedInMinistry,
                          onChanged: (v) => _updateReport(
                            report,
                            sharedInMinistry: v ?? false,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text('Shared'),
                      ],
                    ),
                    SizedBox(
                      width: 80,
                      child: _EditableNumberField(
                        key: ValueKey('service-report-${report.id}-studies'),
                        value: report.bibleStudies,
                        onChanged: (v) =>
                            _updateReport(report, bibleStudies: v),
                        label: 'Studies',
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: _EditableDoubleField(
                        key: ValueKey('service-report-${report.id}-hours'),
                        value: report.hours,
                        onChanged: (v) => _updateReport(report, hours: v),
                        label: 'Hours',
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          key: ValueKey(
                            'service-report-${report.id}-auxiliary',
                          ),
                          value: report.isAuxiliaryPioneer,
                          onChanged: (v) => _updateReport(
                            report,
                            isAuxiliaryPioneer: v ?? false,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text('Aux. Pioneer'),
                      ],
                    ),
                    SizedBox(
                      width: 220,
                      child: _EditableTextField(
                        key: ValueKey('service-report-${report.id}-note'),
                        value: report.note,
                        onChanged: (v) => _updateReport(report, note: v),
                        label: 'Notes',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataGrid(List<ServiceReport> sorted) {
    return Column(
      children: [
        Expanded(child: _buildDataTable(sorted)),
        _ServiceReportGridFooter(reports: sorted),
      ],
    );
  }

  Widget _buildDataTable(List<ServiceReport> sorted) {
    return StickyDataTable(
      minWidth: 980,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      columnSpacing: 12,
      horizontalMargin: 12,
      columns: [
        DataColumn2(
          label: const Text('Name'),
          size: ColumnSize.L,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Month'),
          fixedWidth: 132,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Shared'),
          fixedWidth: 104,
          headingRowAlignment: MainAxisAlignment.center,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Studies'),
          fixedWidth: 108,
          headingRowAlignment: MainAxisAlignment.center,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Hours'),
          fixedWidth: 96,
          headingRowAlignment: MainAxisAlignment.center,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Aux.'),
          tooltip: 'Auxiliary Pioneer',
          fixedWidth: 84,
          headingRowAlignment: MainAxisAlignment.center,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Notes'),
          size: ColumnSize.L,
          minWidth: 220,
          headingRowAlignment: MainAxisAlignment.center,
          onSort: _onSort,
        ),
        const DataColumn2(
          label: Text('Actions'),
          fixedWidth: 64,
          headingRowAlignment: MainAxisAlignment.center,
        ),
      ],
      rows: sorted.map(_buildDataRow).toList(),
    );
  }

  DataRow _buildDataRow(ServiceReport report) {
    final monthName = DateFormat.MMMM().format(
      DateTime(report.year, report.month),
    );

    return DataRow(
      key: ValueKey('service-report-row-${report.id}'),
      cells: [
        DataCell(Text(_displayName(report))),
        DataCell(Text('$monthName ${report.year}')),
        DataCell(
          Center(
            child: _EditableCheckbox(
              key: ValueKey('service-report-${report.id}-shared'),
              value: report.sharedInMinistry,
              onChanged: (v) => _updateReport(report, sharedInMinistry: v),
            ),
          ),
        ),
        DataCell(
          Center(
            child: _EditableNumberField(
              key: ValueKey('service-report-${report.id}-studies'),
              value: report.bibleStudies,
              onChanged: (v) => _updateReport(report, bibleStudies: v),
            ),
          ),
        ),
        DataCell(
          Center(
            child: _EditableDoubleField(
              key: ValueKey('service-report-${report.id}-hours'),
              value: report.hours,
              onChanged: (v) => _updateReport(report, hours: v),
            ),
          ),
        ),
        DataCell(
          Center(
            child: _EditableCheckbox(
              key: ValueKey('service-report-${report.id}-auxiliary'),
              value: report.isAuxiliaryPioneer,
              onChanged: (v) => _updateReport(report, isAuxiliaryPioneer: v),
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180),
            child: _EditableTextField(
              key: ValueKey('service-report-${report.id}-note'),
              value: report.note,
              onChanged: (v) => _updateReport(report, note: v),
            ),
          ),
        ),
        DataCell(
          Center(
            child: IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: () => _deleteReport(report),
            ),
          ),
        ),
      ],
    );
  }

  String _displayName(ServiceReport report) {
    final name = _personNames[report.personId] ?? '...';
    if (_personIsActive[report.personId] == false || !report.isActive) {
      return '$name (Inactive)';
    }
    return name;
  }

  Future<void> _updateReport(
    ServiceReport report, {
    bool? sharedInMinistry,
    int? bibleStudies,
    double? hours,
    bool? isAuxiliaryPioneer,
    String? note,
  }) async {
    if (sharedInMinistry == null &&
        bibleStudies == null &&
        hours == null &&
        isAuxiliaryPioneer == null &&
        note == null) {
      return;
    }

    final db = ref.read(databaseProvider);
    await db.updateServiceReportFields(
      report.id,
      ServiceReportsCompanion(
        sharedInMinistry: sharedInMinistry == null
            ? const drift.Value.absent()
            : drift.Value(sharedInMinistry),
        bibleStudies: bibleStudies == null
            ? const drift.Value.absent()
            : drift.Value(bibleStudies),
        hours: hours == null ? const drift.Value.absent() : drift.Value(hours),
        isAuxiliaryPioneer: isAuxiliaryPioneer == null
            ? const drift.Value.absent()
            : drift.Value(isAuxiliaryPioneer),
        note: note == null ? const drift.Value.absent() : drift.Value(note),
      ),
    );
    // No ref.invalidate needed: serviceReportsProvider wraps a Drift
    // `watch()` stream that re-emits automatically when the underlying
    // table changes.
  }

  Future<void> _deleteReport(ServiceReport report) async {
    final db = ref.read(databaseProvider);
    await db.deleteServiceReport(report.id);
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }
}

class _ServiceReportGridFooter extends StatelessWidget {
  final List<ServiceReport> reports;

  const _ServiceReportGridFooter({required this.reports});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shared = reports.where((report) => report.sharedInMinistry).length;
    final studies = reports.fold<int>(
      0,
      (total, report) => total + report.bibleStudies,
    );
    final hours = reports.fold<double>(
      0,
      (total, report) => total + report.hours,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        child: Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            _FooterMetric(label: 'Rows', value: '${reports.length}'),
            _FooterMetric(label: 'Shared', value: '$shared'),
            _FooterMetric(
              label: 'Not shared',
              value: '${reports.length - shared}',
            ),
            _FooterMetric(label: 'Studies', value: '$studies'),
            _FooterMetric(label: 'Hours', value: _formatHours(hours)),
          ],
        ),
      ),
    );
  }

  String _formatHours(double hours) {
    return hours == hours.truncateToDouble()
        ? '${hours.toInt()}'
        : hours.toStringAsFixed(1);
  }
}

class _FooterMetric extends StatelessWidget {
  final String label;
  final String value;

  const _FooterMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text('$label: $value');
  }
}

// ──────────────────────────────────────────────────
// Inline editable widgets
// ──────────────────────────────────────────────────

class _EditableCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EditableCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(value: value, onChanged: (v) => onChanged(v ?? false));
  }
}

class _EditableNumberField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String? label;

  const _EditableNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<_EditableNumberField> createState() => _EditableNumberFieldState();
}

class _EditableNumberFieldState extends State<_EditableNumberField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late int _lastCommittedValue;

  @override
  void initState() {
    super.initState();
    _lastCommittedValue = widget.value;
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EditableNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      _lastCommittedValue = widget.value;
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commitCurrentValue();
  }

  void _commitCurrentValue() {
    final parsed = int.tryParse(_controller.text);
    if (parsed == null || parsed == _lastCommittedValue) return;

    _lastCommittedValue = parsed;
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          isDense: true,
          border: widget.label != null
              ? const OutlineInputBorder()
              : InputBorder.none,
          labelText: widget.label,
        ),
        onSubmitted: (_) => _commitCurrentValue(),
        onTapOutside: (_) => _focusNode.unfocus(),
      ),
    );
  }
}

class _EditableDoubleField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String? label;

  const _EditableDoubleField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<_EditableDoubleField> createState() => _EditableDoubleFieldState();
}

class _EditableDoubleFieldState extends State<_EditableDoubleField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late double _lastCommittedValue;

  @override
  void initState() {
    super.initState();
    _lastCommittedValue = widget.value;
    _controller = TextEditingController(
      text: widget.value == widget.value.truncateToDouble()
          ? '${widget.value.toInt()}'
          : '${widget.value}',
    );
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EditableDoubleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      _lastCommittedValue = widget.value;
      _controller.text = widget.value == widget.value.truncateToDouble()
          ? '${widget.value.toInt()}'
          : '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commitCurrentValue();
  }

  void _commitCurrentValue() {
    final parsed = double.tryParse(_controller.text);
    if (parsed == null || parsed == _lastCommittedValue) return;

    _lastCommittedValue = parsed;
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(
          isDense: true,
          border: widget.label != null
              ? const OutlineInputBorder()
              : InputBorder.none,
          labelText: widget.label,
        ),
        onSubmitted: (_) => _commitCurrentValue(),
        onTapOutside: (_) => _focusNode.unfocus(),
      ),
    );
  }
}

class _EditableTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String? label;

  const _EditableTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<_EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<_EditableTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late String _lastCommittedValue;

  @override
  void initState() {
    super.initState();
    _lastCommittedValue = widget.value;
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _EditableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      _lastCommittedValue = widget.value;
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _commitCurrentValue();
  }

  void _commitCurrentValue() {
    final value = _controller.text.trim();
    if (value == _lastCommittedValue) return;

    _lastCommittedValue = value;
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        isDense: true,
        border: widget.label != null
            ? const OutlineInputBorder()
            : InputBorder.none,
        labelText: widget.label,
      ),
      onSubmitted: (_) => _commitCurrentValue(),
      onTapOutside: (_) => _focusNode.unfocus(),
    );
  }
}

// ──────────────────────────────────────────────────
// Statistics dialog widgets
// ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final ReportMetrics metrics;
  final bool showHours;

  const _MetricsCard({
    required this.icon,
    required this.title,
    required this.metrics,
    this.showHours = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _metricRow(
                context,
                'Number of Reports',
                '${metrics.numberOfReports}',
              ),
              if (showHours)
                _metricRow(context, 'Hours', metrics.hours.toStringAsFixed(1)),
              _metricRow(context, 'Bible Studies', '${metrics.bibleStudies}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
