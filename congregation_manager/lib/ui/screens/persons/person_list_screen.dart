import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/reporting/report_service.dart';
import 'package:congregation_manager/services/export_progress.dart';
import 'package:congregation_manager/services/publisher_record_reader.dart';
import 'package:congregation_manager/ui/dialogs/export_records_dialog.dart';
import 'package:congregation_manager/ui/dialogs/export_progress_dialog.dart';
import 'package:congregation_manager/ui/screens/import/csv_sync_preview_screen.dart';
import 'package:congregation_manager/ui/screens/import/import_persons_screen.dart';
import 'package:congregation_manager/ui/widgets/app_popup_menu_item.dart';
import 'package:congregation_manager/ui/widgets/search_text_field.dart';
import 'package:congregation_manager/ui/widgets/sticky_data_table.dart';

class PersonListScreen extends ConsumerWidget {
  const PersonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPersons = ref.watch(filteredPersonsProvider);
    final searchQuery = ref.watch(personSearchQueryProvider);
    final showInactivePersons = ref.watch(showInactivePersonsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publishers'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import',
            onSelected: (value) {
              switch (value) {
                case 's21':
                  _importS21(context);
                case 'csv':
                  _importCsv(context);
              }
            },
            itemBuilder: (_) => [
              AppPopupMenuItem(
                value: 's21',
                icon: Icons.picture_as_pdf,
                label: 'Import S-21 Forms',
              ),
              AppPopupMenuItem(
                value: 'csv',
                icon: Icons.sync,
                label: 'Sync Import from CSV',
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.print),
            tooltip: 'Export Reports',
            onSelected: (value) {
              final svc = ReportService(
                ref.read(databaseProvider),
                congregationId: ref.read(currentCongregationIdProvider),
              );
              switch (value) {
                case 'directory':
                  svc.previewPublisherDirectory(context);
                case 'list':
                  svc.previewPublisherList(context);
                case 'contact':
                  svc.previewPublisherContactList(context);
                case 'emergency':
                  svc.previewEmergencyContactList(context);
                case 'summary':
                  svc.previewCongregationSummary(context);
                case 'exportAll':
                  _exportAllReports(context, svc);
                case 'exportExcel':
                  _exportExcel(context, svc);
                case 'exportRecords':
                  _exportPublisherRecords(context, svc);
              }
            },
            itemBuilder: (_) => [
              AppPopupMenuItem(
                value: 'directory',
                icon: Icons.menu_book,
                label: 'Publisher Directory',
              ),
              AppPopupMenuItem(
                value: 'list',
                icon: Icons.list_alt,
                label: 'Publisher List',
              ),
              AppPopupMenuItem(
                value: 'contact',
                icon: Icons.contact_phone,
                label: 'Publisher Contact List',
              ),
              AppPopupMenuItem(
                value: 'emergency',
                icon: Icons.emergency,
                label: 'Emergency Contact List',
              ),
              PopupMenuDivider(),
              AppPopupMenuItem(
                value: 'summary',
                icon: Icons.summarize,
                label: 'Congregation Summary',
              ),
              PopupMenuDivider(),
              AppPopupMenuItem(
                value: 'exportAll',
                icon: Icons.folder,
                label: 'Export All Reports',
              ),
              AppPopupMenuItem(
                value: 'exportExcel',
                icon: Icons.table_chart,
                label: 'Export Excel List',
              ),
              AppPopupMenuItem(
                value: 'exportRecords',
                icon: Icons.description,
                label: 'Export Publisher Records (S-21)',
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Person',
            onPressed: () => context.push('/persons/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: SearchTextField(
                    query: searchQuery,
                    hintText: 'Search publishers...',
                    onChanged: (value) =>
                        ref.read(personSearchQueryProvider.notifier).set(value),
                    onClear: () =>
                        ref.read(personSearchQueryProvider.notifier).set(''),
                  ),
                ),
                const SizedBox(width: 8),
                _buildMoreFilters(
                  ref,
                  showInactivePersons: showInactivePersons,
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredPersons.when(
              data: (persons) {
                if (persons.isEmpty) {
                  return const Center(child: Text('No publishers found.'));
                }
                return _PersonDataTable(persons: persons);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreFilters(WidgetRef ref, {required bool showInactivePersons}) {
    return PopupMenuButton<String>(
      icon: Icon(showInactivePersons ? Icons.tune : Icons.more_horiz),
      tooltip: 'More filters',
      onSelected: (value) {
        switch (value) {
          case 'inactive':
            ref
                .read(showInactivePersonsProvider.notifier)
                .set(!showInactivePersons);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'inactive',
          child: _MoreFilterMenuItem(
            checked: showInactivePersons,
            label: 'Show inactive publishers',
          ),
        ),
      ],
    );
  }

  Future<void> _exportAllReports(
    BuildContext context,
    ReportService svc,
  ) async {
    try {
      final dirPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Export Directory',
      );
      if (dirPath == null) return;
      if (!context.mounted) return;

      await _runWithProgress<void>(
        context,
        title: 'Exporting Reports',
        initialProgress: const ExportProgress(
          current: 0,
          total: 0,
          message: 'Preparing reports',
        ),
        task: (onProgress) =>
            svc.exportAllReports(dirPath, onProgress: onProgress),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All reports exported to $dirPath')),
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

  Future<void> _exportExcel(BuildContext context, ReportService svc) async {
    try {
      final bytes = await svc.buildPublisherContactListExcel();
      final filePath = await FilePicker.saveFile(
        dialogTitle: 'Export Excel',
        fileName: 'Publisher_Contact_List.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
      if (filePath == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel list exported successfully.')),
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

  Future<void> _exportPublisherRecords(
    BuildContext context,
    ReportService svc,
  ) async {
    try {
      final options = await ExportRecordsDialog.show(context);
      if (options == null) return;

      if (!context.mounted) return;
      final dirPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select S-21 Export Directory',
      );
      if (dirPath == null) return;
      if (!context.mounted) return;

      final errors = await _runWithProgress<List<String>>(
        context,
        title: 'Exporting S-21 Records',
        initialProgress: const ExportProgress(
          current: 0,
          total: 0,
          message: 'Preparing publisher records',
        ),
        task: (onProgress) => svc.exportPublisherRecords(
          dirPath: dirPath,
          serviceYear: options.serviceYear,
          flatten: options.flattenPdf,
          groupByRole: options.groupByRole,
          groupByFieldServiceGroup: options.groupByFieldServiceGroup,
          twoYearsPerPage: options.twoYearsPerPage,
          onlyUpToPreviousMonth: options.onlyUpToPreviousMonth,
          fileNameTemplate: options.fileNameTemplate,
          onProgress: onProgress,
        ),
      );

      if (context.mounted) {
        if (errors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Publisher records exported to $dirPath')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export completed with ${errors.length} error(s).'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<T> _runWithProgress<T>(
    BuildContext context, {
    required String title,
    required ExportProgress initialProgress,
    required Future<T> Function(ExportProgressCallback onProgress) task,
  }) async {
    final notifier = ValueNotifier(initialProgress);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ExportProgressDialog(title: title, progressListenable: notifier),
    );

    try {
      return await task((progress) => notifier.value = progress);
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      notifier.dispose();
    }
  }

  Future<void> _importCsv(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CsvSyncPreviewScreen(csvFilePath: result.files.single.path!),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _importS21(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final importedPersons = <ImportedPerson>[];
      for (final file in result.files) {
        if (file.path == null) continue;
        final imported = await PublisherRecordReader.readFromFile(file.path!);
        if (imported != null) importedPersons.add(imported);
      }

      if (importedPersons.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No valid publisher records found in the selected files.',
              ),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ImportPersonsScreen(importedPersons: importedPersons),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}

class _PersonDataTable extends ConsumerStatefulWidget {
  final List<Person> persons;

  const _PersonDataTable({required this.persons});

  @override
  ConsumerState<_PersonDataTable> createState() => _PersonDataTableState();
}

class _PersonDataTableState extends ConsumerState<_PersonDataTable> {
  final Set<int> _selectedIds = {};
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final sorted = List<Person>.from(widget.persons);
    if (_sortColumnIndex != null) {
      sorted.sort((a, b) {
        int result;
        final nameOrder = ref.read(nameOrderProvider);
        switch (_sortColumnIndex) {
          case 0:
            result = nameOrder == NameOrder.lastFirst
                ? a.lastName.compareTo(b.lastName)
                : a.firstName.compareTo(b.firstName);
          case 1:
            result = nameOrder == NameOrder.lastFirst
                ? a.firstName.compareTo(b.firstName)
                : a.lastName.compareTo(b.lastName);
          case 2:
            result = a.otherNames.compareTo(b.otherNames);
          case 3:
            result = a.congregationRole.index.compareTo(
              b.congregationRole.index,
            );
          case 4:
            result = a.pioneerType.index.compareTo(b.pioneerType.index);
          case 5:
            result = (a.isActive ? 1 : 0).compareTo(b.isActive ? 1 : 0);
          default:
            result = 0;
        }
        return _sortAscending ? result : -result;
      });
    }

    final isWide = MediaQuery.of(context).size.width >= 600;

    return Column(
      children: [
        if (_selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text('${_selectedIds.length} selected'),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: () => _deleteSelected(context),
                ),
              ],
            ),
          ),
        Expanded(child: _buildListWithFooter(sorted, isWide: isWide)),
      ],
    );
  }

  Widget _buildListWithFooter(List<Person> sorted, {required bool isWide}) {
    return Column(
      children: [
        Expanded(
          child: isWide ? _buildDataTable(sorted) : _buildCardList(sorted),
        ),
        _PublisherListFooter(persons: sorted),
      ],
    );
  }

  Widget _buildCardList(List<Person> sorted) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final person = sorted[index];
        final isSelected = _selectedIds.contains(person.id);
        final badges = _publisherBadges(person);
        final cardSubtitle = _buildCardSubtitle(person, badges);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: Icon(
              person.isActive ? Icons.check_circle : Icons.cancel,
              color: person.isActive ? Colors.green : Colors.red,
            ),
            title: Text(
              formatPersonName(
                person.firstName,
                person.lastName,
                ref.watch(nameOrderProvider),
              ),
            ),
            subtitle: cardSubtitle,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/persons/edit/${person.id}'),
            onLongPress: () {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(person.id);
                } else {
                  _selectedIds.add(person.id);
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<Person> sorted) {
    return StickyDataTable(
      minWidth: 900,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      showCheckboxColumn: true,
      columnSpacing: 12,
      horizontalMargin: 12,
      checkboxHorizontalMargin: 8,
      columns: [
        DataColumn2(
          label: Text(
            ref.watch(nameOrderProvider) == NameOrder.lastFirst
                ? 'Last Name'
                : 'First Name',
          ),
          size: ColumnSize.M,
          minWidth: 130,
          onSort: _onSort,
        ),
        DataColumn2(
          label: Text(
            ref.watch(nameOrderProvider) == NameOrder.lastFirst
                ? 'First Name'
                : 'Last Name',
          ),
          size: ColumnSize.M,
          minWidth: 130,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Other Name'),
          size: ColumnSize.M,
          minWidth: 150,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Role'),
          fixedWidth: 160,
          headingRowAlignment: MainAxisAlignment.center,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Pioneer'),
          fixedWidth: 168,
          headingRowAlignment: MainAxisAlignment.center,
          onSort: _onSort,
        ),
        DataColumn2(
          label: const Text('Active'),
          fixedWidth: 88,
          headingRowAlignment: MainAxisAlignment.center,
          onSort: _onSort,
        ),
      ],
      rows: sorted.map((person) {
        return DataRow(
          selected: _selectedIds.contains(person.id),
          onSelectChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedIds.add(person.id);
              } else {
                _selectedIds.remove(person.id);
              }
            });
          },
          onLongPress: () => context.push('/persons/edit/${person.id}'),
          cells: [
            DataCell(
              Text(
                ref.watch(nameOrderProvider) == NameOrder.lastFirst
                    ? person.lastName
                    : person.firstName,
              ),
              onTap: () => context.push('/persons/edit/${person.id}'),
            ),
            DataCell(
              Text(
                ref.watch(nameOrderProvider) == NameOrder.lastFirst
                    ? person.firstName
                    : person.lastName,
              ),
              onTap: () => context.push('/persons/edit/${person.id}'),
            ),
            DataCell(
              Text(
                person.otherNames.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => context.push('/persons/edit/${person.id}'),
            ),
            DataCell(Center(child: _roleBadge(person.congregationRole))),
            DataCell(Center(child: _pioneerBadge(person.pioneerType))),
            DataCell(
              Center(
                child: Icon(
                  person.isActive ? Icons.check_circle : Icons.cancel,
                  color: person.isActive ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget? _buildCardSubtitle(Person person, List<Widget> badges) {
    final otherNames = person.otherNames.trim();
    if (otherNames.isEmpty && badges.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (otherNames.isNotEmpty)
            Text(
              'Other: $otherNames',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (badges.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: otherNames.isEmpty ? 2 : 6),
              child: Wrap(spacing: 6, runSpacing: 6, children: badges),
            ),
        ],
      ),
    );
  }

  List<Widget> _publisherBadges(Person person) => [
    if (person.congregationRole != CongregationRole.none)
      _roleBadge(person.congregationRole),
    if (person.pioneerType != PioneerType.none)
      _pioneerBadge(person.pioneerType),
  ];

  Widget _roleBadge(CongregationRole role) {
    if (role == CongregationRole.none) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return _PublisherBadge(
      label: role.displayName,
      icon: role == CongregationRole.elder ? Icons.shield : Icons.badge,
      backgroundColor: role == CongregationRole.elder
          ? colorScheme.primaryContainer
          : colorScheme.secondaryContainer,
      foregroundColor: role == CongregationRole.elder
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSecondaryContainer,
    );
  }

  Widget _pioneerBadge(PioneerType type) {
    if (type == PioneerType.none) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (type) {
      PioneerType.regularPioneer => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
        Icons.star,
      ),
      PioneerType.specialPioneer => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.workspace_premium,
      ),
      PioneerType.fieldMissionary => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
        Icons.travel_explore,
      ),
      PioneerType.none => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
        Icons.label,
      ),
    };

    return _PublisherBadge(
      label: type.displayName,
      icon: icon,
      backgroundColor: background,
      foregroundColor: foreground,
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Publishers'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} publisher(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      for (final id in _selectedIds) {
        await db.deletePerson(id);
      }
      setState(() => _selectedIds.clear());
      ref.invalidate(personsProvider);
    }
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

class _PublisherListFooter extends StatelessWidget {
  final List<Person> persons;

  const _PublisherListFooter({required this.persons});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = persons.where((person) => person.isActive).length;
    final inactive = persons.length - active;
    final elders = persons
        .where((person) => person.congregationRole == CongregationRole.elder)
        .length;
    final servants = persons
        .where(
          (person) =>
              person.congregationRole == CongregationRole.ministerialServant,
        )
        .length;
    final pioneers = persons
        .where((person) => person.pioneerType != PioneerType.none)
        .length;

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
            _FooterMetric(label: 'Rows', value: '${persons.length}'),
            _FooterMetric(label: 'Active', value: '$active'),
            _FooterMetric(label: 'Inactive', value: '$inactive'),
            _FooterMetric(label: 'Elders', value: '$elders'),
            _FooterMetric(label: 'Servants', value: '$servants'),
            _FooterMetric(label: 'Pioneers', value: '$pioneers'),
          ],
        ),
      ),
    );
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

class _PublisherBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _PublisherBadge({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
