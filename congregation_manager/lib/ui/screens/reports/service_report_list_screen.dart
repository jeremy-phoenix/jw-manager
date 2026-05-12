import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
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

class ServiceReportListScreen extends ConsumerWidget {
  const ServiceReportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(filteredServiceReportsProvider);
    final selectedYear = ref.watch(selectedYearProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final showNotSharedOnly = ref.watch(showNotSharedOnlyProvider);
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
              searchQuery: searchQuery,
              serviceYears: serviceYears,
            );
          }

          return _buildWideFilters(
            ref: ref,
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
            showNotSharedOnly: showNotSharedOnly,
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
            _buildNotSharedFilter(ref, showNotSharedOnly, iconOnly: true),
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
            _buildNotSharedFilter(ref, showNotSharedOnly),
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

  Widget _buildNotSharedFilter(
    WidgetRef ref,
    bool showNotSharedOnly, {
    bool iconOnly = false,
  }) {
    if (iconOnly) {
      return IconButton.filledTonal(
        isSelected: showNotSharedOnly,
        icon: const Icon(Icons.filter_alt_outlined),
        selectedIcon: const Icon(Icons.filter_alt),
        tooltip: 'Show not shared only',
        style: IconButton.styleFrom(
          fixedSize: const Size.square(48),
          minimumSize: const Size.square(48),
        ),
        onPressed: () => ref
            .read(showNotSharedOnlyProvider.notifier)
            .set(!showNotSharedOnly),
      );
    }

    return FilterChip(
      avatar: const Icon(Icons.filter_alt, size: 18),
      label: const Text('Not Shared'),
      tooltip: 'Show not shared only',
      selected: showNotSharedOnly,
      onSelected: (value) =>
          ref.read(showNotSharedOnlyProvider.notifier).set(value),
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
    return isWide ? _buildDataTable(sorted) : _buildCardList(sorted);
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
        final name = _personNames[report.personId] ?? '...';
        final monthName = DateFormat.MMMM().format(
          DateTime(report.year, report.month),
        );

        return Card(
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
                        value: report.bibleStudies,
                        onChanged: (v) =>
                            _updateReport(report, bibleStudies: v),
                        label: 'Studies',
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: _EditableDoubleField(
                        value: report.hours,
                        onChanged: (v) => _updateReport(report, hours: v),
                        label: 'Hours',
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
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
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<ServiceReport> sorted) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: SingleChildScrollView(
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columnSpacing: 24,
              columns: [
                DataColumn(label: const Text('Name'), onSort: _onSort),
                DataColumn(label: const Text('Month'), onSort: _onSort),
                DataColumn(label: const Text('Shared'), onSort: _onSort),
                DataColumn(
                  label: const Text('Studies'),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('Hours'),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(label: const Text('Aux. Pioneer'), onSort: _onSort),
                const DataColumn(label: Text('Actions')),
              ],
              rows: sorted.map((report) {
                final name = _personNames[report.personId] ?? '...';
                final monthName = DateFormat.MMMM().format(
                  DateTime(report.year, report.month),
                );

                return DataRow(
                  cells: [
                    DataCell(Text(name)),
                    DataCell(Text('$monthName ${report.year}')),
                    DataCell(
                      _EditableCheckbox(
                        value: report.sharedInMinistry,
                        onChanged: (v) =>
                            _updateReport(report, sharedInMinistry: v),
                      ),
                    ),
                    DataCell(
                      _EditableNumberField(
                        value: report.bibleStudies,
                        onChanged: (v) =>
                            _updateReport(report, bibleStudies: v),
                      ),
                    ),
                    DataCell(
                      _EditableDoubleField(
                        value: report.hours,
                        onChanged: (v) => _updateReport(report, hours: v),
                      ),
                    ),
                    DataCell(
                      _EditableCheckbox(
                        value: report.isAuxiliaryPioneer,
                        onChanged: (v) =>
                            _updateReport(report, isAuxiliaryPioneer: v),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => _deleteReport(report),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateReport(
    ServiceReport report, {
    bool? sharedInMinistry,
    int? bibleStudies,
    double? hours,
    bool? isAuxiliaryPioneer,
  }) async {
    final db = ref.read(databaseProvider);
    await db.updateServiceReport(
      ServiceReportsCompanion(
        id: drift.Value(report.id),
        year: drift.Value(report.year),
        month: drift.Value(report.month),
        personId: drift.Value(report.personId),
        sharedInMinistry: drift.Value(
          sharedInMinistry ?? report.sharedInMinistry,
        ),
        bibleStudies: drift.Value(bibleStudies ?? report.bibleStudies),
        hours: drift.Value(hours ?? report.hours),
        isAuxiliaryPioneer: drift.Value(
          isAuxiliaryPioneer ?? report.isAuxiliaryPioneer,
        ),
        isActive: drift.Value(report.isActive),
        note: drift.Value(report.note),
      ),
    );
    ref.invalidate(serviceReportsProvider);
  }

  Future<void> _deleteReport(ServiceReport report) async {
    final db = ref.read(databaseProvider);
    await db.deleteServiceReport(report.id);
    ref.invalidate(serviceReportsProvider);
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }
}

// ──────────────────────────────────────────────────
// Inline editable widgets
// ──────────────────────────────────────────────────

class _EditableCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EditableCheckbox({required this.value, required this.onChanged});

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
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<_EditableNumberField> createState() => _EditableNumberFieldState();
}

class _EditableNumberFieldState extends State<_EditableNumberField> {
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _EditableNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          border: widget.label != null
              ? const OutlineInputBorder()
              : InputBorder.none,
          labelText: widget.label,
        ),
        onTap: () => _editing = true,
        onSubmitted: (v) {
          _editing = false;
          final parsed = int.tryParse(v);
          if (parsed != null) widget.onChanged(parsed);
        },
        onTapOutside: (_) {
          _editing = false;
          final parsed = int.tryParse(_controller.text);
          if (parsed != null && parsed != widget.value) {
            widget.onChanged(parsed);
          }
        },
      ),
    );
  }
}

class _EditableDoubleField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String? label;

  const _EditableDoubleField({
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<_EditableDoubleField> createState() => _EditableDoubleFieldState();
}

class _EditableDoubleFieldState extends State<_EditableDoubleField> {
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value == widget.value.truncateToDouble()
          ? '${widget.value.toInt()}'
          : '${widget.value}',
    );
  }

  @override
  void didUpdateWidget(covariant _EditableDoubleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _controller.text = widget.value == widget.value.truncateToDouble()
          ? '${widget.value.toInt()}'
          : '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          border: widget.label != null
              ? const OutlineInputBorder()
              : InputBorder.none,
          labelText: widget.label,
        ),
        onTap: () => _editing = true,
        onSubmitted: (v) {
          _editing = false;
          final parsed = double.tryParse(v);
          if (parsed != null) widget.onChanged(parsed);
        },
        onTapOutside: (_) {
          _editing = false;
          final parsed = double.tryParse(_controller.text);
          if (parsed != null && parsed != widget.value) {
            widget.onChanged(parsed);
          }
        },
      ),
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
