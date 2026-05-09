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

class PersonListScreen extends ConsumerWidget {
  const PersonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPersons = ref.watch(filteredPersonsProvider);
    final searchQuery = ref.watch(personSearchQueryProvider);

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
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 's21',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Import S-21 Forms'),
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.sync),
                  title: Text('Sync Import from CSV'),
                ),
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
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'directory',
                child: ListTile(
                  leading: Icon(Icons.menu_book),
                  title: Text('Publisher Directory'),
                ),
              ),
              PopupMenuItem(
                value: 'list',
                child: ListTile(
                  leading: Icon(Icons.list_alt),
                  title: Text('Publisher List'),
                ),
              ),
              PopupMenuItem(
                value: 'contact',
                child: ListTile(
                  leading: Icon(Icons.contact_phone),
                  title: Text('Publisher Contact List'),
                ),
              ),
              PopupMenuItem(
                value: 'emergency',
                child: ListTile(
                  leading: Icon(Icons.emergency),
                  title: Text('Emergency Contact List'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'summary',
                child: ListTile(
                  leading: Icon(Icons.summarize),
                  title: Text('Congregation Summary'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'exportAll',
                child: ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('Export All Reports'),
                ),
              ),
              PopupMenuItem(
                value: 'exportExcel',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Export Excel List'),
                ),
              ),
              PopupMenuItem(
                value: 'exportRecords',
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Export Publisher Records (S-21)'),
                ),
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
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search publishers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref
                            .read(personSearchQueryProvider.notifier)
                            .set(''),
                      )
                    : null,
              ),
              onChanged: (value) =>
                  ref.read(personSearchQueryProvider.notifier).set(value),
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
            result = a.congregationRole.index.compareTo(
              b.congregationRole.index,
            );
          case 3:
            result = a.pioneerType.index.compareTo(b.pioneerType.index);
          case 4:
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
        Expanded(
          child: isWide ? _buildDataTable(sorted) : _buildCardList(sorted),
        ),
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
            subtitle: badges.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(spacing: 6, runSpacing: 6, children: badges),
                  ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                showCheckboxColumn: true,
                columns: [
                  DataColumn(
                    label: Text(
                      ref.watch(nameOrderProvider) == NameOrder.lastFirst
                          ? 'Last Name'
                          : 'First Name',
                    ),
                    onSort: _onSort,
                  ),
                  DataColumn(
                    label: Text(
                      ref.watch(nameOrderProvider) == NameOrder.lastFirst
                          ? 'First Name'
                          : 'Last Name',
                    ),
                    onSort: _onSort,
                  ),
                  DataColumn(label: const Text('Role'), onSort: _onSort),
                  DataColumn(label: const Text('Pioneer'), onSort: _onSort),
                  DataColumn(label: const Text('Active'), onSort: _onSort),
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
                    onLongPress: () =>
                        context.push('/persons/edit/${person.id}'),
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
                      DataCell(_roleBadge(person.congregationRole)),
                      DataCell(_pioneerBadge(person.pioneerType)),
                      DataCell(
                        Icon(
                          person.isActive ? Icons.check_circle : Icons.cancel,
                          color: person.isActive ? Colors.green : Colors.red,
                          size: 18,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
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
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
