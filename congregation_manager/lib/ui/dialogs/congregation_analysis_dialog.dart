import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/service_year.dart';
import 'package:congregation_manager/data/statistics.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/theme/layout.dart';

class CongregationAnalysisDialog extends ConsumerStatefulWidget {
  final int serviceYear;
  final int throughMonth;

  const CongregationAnalysisDialog({
    super.key,
    required this.serviceYear,
    required this.throughMonth,
  });

  @override
  ConsumerState<CongregationAnalysisDialog> createState() =>
      _CongregationAnalysisDialogState();
}

class _CongregationAnalysisDialogState
    extends ConsumerState<CongregationAnalysisDialog> {
  late int _year = widget.serviceYear;
  late int _month = widget.throughMonth;
  int _category = 0;
  late Future<({CongregationAnalysis analysis, List<Person> people})> _result;

  static const _titles = [
    'All Active Publishers',
    'New Inactive Publishers',
    'Reactivated Publishers',
  ];
  static const _icons = [
    Icons.people_outline,
    Icons.person_off_outlined,
    Icons.person_add_alt_1_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _result = _load();
  }

  Future<({CongregationAnalysis analysis, List<Person> people})> _load() async {
    final db = ref.read(databaseProvider);
    final congregationId = ref.read(currentCongregationIdProvider);
    final analysis = await db.getCongregationAnalysis(
      congregationId: congregationId,
      serviceYear: _year,
      throughMonth: _month,
    );
    final people = await db.getAllPersons(congregationId: congregationId);
    return (analysis: analysis, people: people);
  }

  void _changePeriod({int? year, int? month}) {
    setState(() {
      _year = year ?? _year;
      _month = month ?? _month;
      _result = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final years = {
      ...?ref.watch(serviceYearsProvider).asData?.value,
      currentServiceYear() - 1,
      _year,
    }.toList()..sort((a, b) => b.compareTo(a));
    final end = DateTime(calendarYearOf(_year, _month), _month);
    final dateFormat = DateFormat('MMM yyyy');
    final activeRange =
        '${dateFormat.format(DateTime(end.year, end.month - 5))} – '
        '${dateFormat.format(end)}';
    final yearRange =
        '${dateFormat.format(DateTime(_year - 1, 9))} – ${dateFormat.format(end)}';

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Congregation Analysis',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('analysis-year-$_year'),
                            initialValue: _year,
                            decoration: const InputDecoration(
                              labelText: 'Service year',
                            ),
                            items: [
                              for (final year in years)
                                DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                ),
                            ],
                            onChanged: (year) => _changePeriod(year: year),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('analysis-month-$_month'),
                            initialValue: _month,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Through month',
                            ),
                            items: [
                              for (final month in [
                                9,
                                10,
                                11,
                                12,
                                1,
                                2,
                                3,
                                4,
                                5,
                                6,
                                7,
                                8,
                              ])
                                DropdownMenuItem(
                                  value: month,
                                  child: Text(formatServiceMonth(_year, month)),
                                ),
                            ],
                            onChanged: (month) => _changePeriod(month: month),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_month == 8 ? 'Full service year' : 'Service year to date'} · $yearRange',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (_month != 8) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Select August for the full service-year totals.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    FutureBuilder(
                      future: _result,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Column(
                            children: [
                              const Text(
                                'Unable to load congregation analysis.',
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _changePeriod,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try again'),
                              ),
                            ],
                          );
                        }
                        final data = snapshot.requireData;
                        final categories = [
                          data.analysis.allActivePersonIds,
                          data.analysis.newInactivePersonIds,
                          data.analysis.reactivatedPersonIds,
                        ];
                        final descriptions = [
                          'Reported ministry at least once in six months.\n$activeRange',
                          'Reached six consecutive months without reporting during this service year.',
                          'Resumed reporting this service year after at least six months without reporting.',
                        ];
                        final ids = categories[_category].toSet();
                        final order = ref.watch(nameOrderProvider);
                        final names =
                            data.people
                                .where((person) => ids.contains(person.id))
                                .map(
                                  (person) => formatPersonName(
                                    person.firstName,
                                    person.lastName,
                                    order,
                                  ),
                                )
                                .toList()
                              ..sort(
                                (a, b) =>
                                    a.toLowerCase().compareTo(b.toLowerCase()),
                              );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide =
                                    constraints.maxWidth >=
                                    AppBreakpoints.medium;
                                final cards = [
                                  for (var i = 0; i < _titles.length; i++)
                                    _AnalysisCard(
                                      title: _titles[i],
                                      count: categories[i].length,
                                      description: descriptions[i],
                                      icon: _icons[i],
                                      selected: i == _category,
                                      compact: !wide,
                                      onTap: () =>
                                          setState(() => _category = i),
                                    ),
                                ];
                                if (wide) {
                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (
                                          var i = 0;
                                          i < cards.length;
                                          i++
                                        ) ...[
                                          if (i > 0) const SizedBox(width: 12),
                                          Expanded(child: cards[i]),
                                        ],
                                      ],
                                    ),
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (var i = 0; i < cards.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 12),
                                      cards[i],
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'A publisher may be counted as both newly inactive and reactivated in the same service year.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '${_titles[_category]} (${names.length})',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a total above to see the publishers included.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            if (names.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  'No publishers meet this definition for the selected period.',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 220,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Scrollbar(
                                  child: ListView.builder(
                                    primary: false,
                                    shrinkWrap: true,
                                    itemCount: names.length,
                                    itemBuilder: (context, index) => ListTile(
                                      dense: true,
                                      leading: Text('${index + 1}'),
                                      title: Text(names[index]),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      title: const Text('How totals are counted'),
                      children: const [
                        Text(
                          'All active publishers includes pioneers, unbaptized, irregular, '
                          'reactivated, deaf, blind and incarcerated publishers, and special '
                          'full-time servants. No baptism or pioneer-status filter is applied.\n\n'
                          'New inactive publishers includes only those whose sixth consecutive '
                          'month without reporting falls within the selected service year, '
                          'through the selected month. Those who became inactive in an earlier '
                          'service year and remained inactive are excluded.\n\n'
                          'Reactivated publishers includes those who resumed reporting within '
                          'the selected period after at least six consecutive months without reporting. '
                          'Each person is counted once per category.\n\n'
                          'Totals use saved ministry participation, including people marked inactive '
                          'in the publisher list. Archived and trashed records are excluded. '
                          'Missing months after the first recorded ministry participation count as not reporting. '
                          'Blank months before that first participation are ignored, so a new publisher '
                          'is not counted as newly inactive or reactivated simply for starting to report. '
                          'Earlier activity cannot be inferred, so incomplete or missing report '
                          'history can affect the totals.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final int count;
  final String description;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.title,
    required this.count,
    required this.description,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: '$title: $count. $description. View publishers',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: compact
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 42),
                        child: Column(
                          children: [
                            Icon(icon, color: colors.primary, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              '$count',
                              style: theme.textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text(description, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: colors.primary),
                          const Spacer(),
                          Icon(
                            selected ? Icons.check_circle : Icons.arrow_forward,
                            size: 18,
                            color: colors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('$count', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(description, style: theme.textTheme.bodySmall),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
