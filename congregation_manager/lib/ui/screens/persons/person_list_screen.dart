import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
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
import 'package:congregation_manager/ui/dialogs/publisher_contact_list_options_dialog.dart';
import 'package:congregation_manager/ui/screens/import/csv_sync_preview_screen.dart';
import 'package:congregation_manager/ui/screens/import/import_persons_screen.dart';
import 'package:congregation_manager/ui/theme/layout.dart';
import 'package:congregation_manager/ui/widgets/app_popup_menu_item.dart';
import 'package:congregation_manager/ui/widgets/empty_state.dart';
import 'package:congregation_manager/ui/widgets/publisher_status.dart';
import 'package:congregation_manager/ui/widgets/screen_shortcuts.dart';
import 'package:congregation_manager/ui/widgets/search_text_field.dart';
import 'package:congregation_manager/ui/widgets/sticky_data_table.dart';
import 'package:congregation_manager/ui/widgets/toolbar_actions.dart';

class PersonListScreen extends ConsumerStatefulWidget {
  const PersonListScreen({super.key});

  @override
  ConsumerState<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends ConsumerState<PersonListScreen> {
  final _searchFocus = FocusNode(debugLabel: 'Publisher search');
  final _tableCommands = _TableCommands();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _addPublisher() => context.push('/persons/new');

  @override
  Widget build(BuildContext context) {
    final filteredPersons = ref.watch(filteredPersonsProvider);
    final searchQuery = ref.watch(personSearchQueryProvider);
    final listOptions = ref.watch(personListOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publishers'),
        actions: [
          ToolbarMenu<String>(
            icon: Icons.upload_file,
            label: 'Import',
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
          ToolbarMenu<String>(
            icon: Icons.print,
            label: 'Reports',
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
                  _previewPublisherContactList(context, svc);
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
          ToolbarMenu<String>(
            icon: Icons.inventory_2_outlined,
            label: 'Archive & Trash',
            tooltip: 'Publisher records',
            onSelected: (value) {
              switch (value) {
                case 'archive':
                  context.go('/persons/archive');
                case 'trash':
                  context.go('/persons/trash');
              }
            },
            itemBuilder: (_) => [
              AppPopupMenuItem(
                value: 'archive',
                icon: Icons.inventory_2_outlined,
                label: 'Archived Publishers',
              ),
              AppPopupMenuItem(
                value: 'trash',
                icon: Icons.delete_outline,
                label: 'Trash',
              ),
            ],
          ),
          ToolbarAction.primary(
            icon: Icons.person_add_outlined,
            label: 'Add publisher',
            tooltip: 'Add Publisher (Ctrl+N)',
            onPressed: _addPublisher,
          ),
        ],
      ),
      body: ScreenShortcuts(
        bindings: {
          commandKey(LogicalKeyboardKey.keyF): ScreenShortcut(
            _searchFocus.requestFocus,
            whileEditing: true,
          ),
          commandKey(LogicalKeyboardKey.keyN): ScreenShortcut(
            _addPublisher,
            whileEditing: true,
          ),
          commandKey(LogicalKeyboardKey.keyA): ScreenShortcut(
            () => _tableCommands.selectAll?.call(),
          ),
          const SingleActivator(LogicalKeyboardKey.escape): ScreenShortcut(
            () => _tableCommands.clearSelection?.call(),
          ),
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: SearchTextField(
                      focusNode: _searchFocus,
                      query: searchQuery,
                      hintText: 'Search publishers...',
                      onChanged: (value) => ref
                          .read(personSearchQueryProvider.notifier)
                          .set(value),
                      onClear: () =>
                          ref.read(personSearchQueryProvider.notifier).set(''),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildMoreFilters(context, ref, options: listOptions),
                ],
              ),
            ),
            Expanded(
              child: filteredPersons.when(
                data: (persons) {
                  if (persons.isEmpty) {
                    return _buildEmptyState(searchQuery, listOptions);
                  }
                  return _PersonDataTable(
                    key: ValueKey((
                      ref.watch(currentCongregationIdProvider),
                      listOptions.sortField,
                      listOptions.sortAscending,
                    )),
                    persons: persons,
                    commands: _tableCommands,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState.error(
                  title: 'Could not load publishers',
                  error: e,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery, PersonListOptions options) {
    if (searchQuery.trim().isEmpty && options.activeOptionCount == 0) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No publishers',
        message:
            'Add a publisher, or import S-21 forms or a CSV export from the '
            'Import menu.',
        action: FilledButton.icon(
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add publisher'),
          onPressed: _addPublisher,
        ),
      );
    }
    return EmptyState(
      icon: Icons.search_off,
      title: 'No matching publishers',
      message: 'Try another search, or clear the search and filters.',
      action: FilledButton.tonalIcon(
        icon: const Icon(Icons.filter_alt_off_outlined),
        label: const Text('Clear search and filters'),
        onPressed: () {
          ref.read(personSearchQueryProvider.notifier).set('');
          ref
              .read(personListOptionsProvider.notifier)
              .set(
                PersonListOptions(
                  sortField: options.sortField,
                  sortAscending: options.sortAscending,
                ),
              );
        },
      ),
    );
  }

  Widget _buildMoreFilters(
    BuildContext context,
    WidgetRef ref, {
    required PersonListOptions options,
  }) {
    return IconButton(
      icon: options.activeOptionCount == 0
          ? const Icon(Icons.tune)
          : Badge(
              label: Text('${options.activeOptionCount}'),
              child: const Icon(Icons.filter_alt),
            ),
      tooltip: 'More filters',
      onPressed: () async {
        final updated = await showDialog<PersonListOptions>(
          context: context,
          builder: (_) => _PersonListOptionsDialog(initialOptions: options),
        );
        if (updated != null) {
          ref.read(personListOptionsProvider.notifier).set(updated);
        }
      },
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

  Future<void> _previewPublisherContactList(
    BuildContext context,
    ReportService svc,
  ) async {
    final startInactiveOnNewPage = await PublisherContactListOptionsDialog.show(
      context,
    );
    if (startInactiveOnNewPage == null || !context.mounted) return;

    await svc.previewPublisherContactList(
      context,
      startInactiveOnNewPage: startInactiveOnNewPage,
    );
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
  ) => _exportPublisherRecordsFor(context, svc);

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
  final _TableCommands commands;

  const _PersonDataTable({
    super.key,
    required this.persons,
    required this.commands,
  });

  @override
  ConsumerState<_PersonDataTable> createState() => _PersonDataTableState();
}

class _PersonDataTableState extends ConsumerState<_PersonDataTable> {
  final Set<int> _selectedIds = {};
  int? _sortColumnIndex;
  bool _sortAscending = true;

  /// Rows in display order, for select-all and Shift-click ranges.
  List<int> _visibleIds = const [];

  /// The last row toggled without Shift: one end of a Shift-click range.
  int? _rangeAnchorId;

  @override
  void initState() {
    super.initState();
    _attachCommands();
  }

  @override
  void didUpdateWidget(covariant _PersonDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commands != widget.commands) _attachCommands();
  }

  @override
  void dispose() {
    // A replacement table may already have taken over the commands.
    if (widget.commands.selectAll == _selectAll) {
      widget.commands
        ..selectAll = null
        ..clearSelection = null;
    }
    super.dispose();
  }

  void _attachCommands() {
    widget.commands
      ..selectAll = _selectAll
      ..clearSelection = _clearSelection;
  }

  void _selectAll() => setState(() => _selectedIds.addAll(_visibleIds));

  void _clearSelection() {
    if (_selectedIds.isEmpty) return;
    setState(_selectedIds.clear);
  }

  void _toggleSelection(int id, bool selected) {
    setState(() {
      final anchor = _rangeAnchorId;
      final anchorIndex = anchor == null ? -1 : _visibleIds.indexOf(anchor);
      if (HardwareKeyboard.instance.isShiftPressed && anchorIndex >= 0) {
        final index = _visibleIds.indexOf(id);
        final range = _visibleIds.sublist(
          index < anchorIndex ? index : anchorIndex,
          (index < anchorIndex ? anchorIndex : index) + 1,
        );
        selected ? _selectedIds.addAll(range) : _selectedIds.removeAll(range);
      } else {
        selected ? _selectedIds.add(id) : _selectedIds.remove(id);
        _rangeAnchorId = id;
      }
    });
  }

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
            return _compareDates(
              a.baptismDate,
              b.baptismDate,
              ascending: _sortAscending,
            );
          case 4:
            result = a.congregationRole.index.compareTo(
              b.congregationRole.index,
            );
          case 5:
            result = a.pioneerType.index.compareTo(b.pioneerType.index);
          case 6:
            result = (a.isActive ? 1 : 0).compareTo(b.isActive ? 1 : 0);
          default:
            result = 0;
        }
        return _sortAscending ? result : -result;
      });
    }

    _visibleIds = [for (final person in sorted) person.id];
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.medium;
    // Three inline buttons need more room than the table breakpoint allows.
    final showInlineActions = width >= AppBreakpoints.expanded;

    return Column(
      children: [
        if (_selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear selection (Esc)',
                  onPressed: _clearSelection,
                ),
                Text('${_selectedIds.length} selected'),
                const Spacer(),
                if (showInlineActions) ...[
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.description),
                    label: const Text('Export Records'),
                    onPressed: () => _export(context, _selectedIds),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Archive'),
                    onPressed: () => _archive(context, _selectedIds),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Move to Trash'),
                    onPressed: () => _moveToTrash(context, _selectedIds),
                  ),
                ] else
                  PopupMenuButton<_PublisherAction>(
                    tooltip: 'Selected publisher actions',
                    onSelected: (action) =>
                        _runAction(context, action, _selectedIds),
                    itemBuilder: (_) => [
                      AppPopupMenuItem(
                        value: _PublisherAction.exportRecords,
                        icon: Icons.description,
                        label: 'Export Records (S-21)',
                      ),
                      AppPopupMenuItem(
                        value: _PublisherAction.archive,
                        icon: Icons.inventory_2_outlined,
                        label: 'Archive',
                      ),
                      AppPopupMenuItem(
                        value: _PublisherAction.moveToTrash,
                        icon: Icons.delete_outline,
                        label: 'Move to Trash',
                      ),
                    ],
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
    final colors = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final person = sorted[index];
        final isSelected = _selectedIds.contains(person.id);
        final badges = _publisherBadges(person);
        return ListTile(
          selected: isSelected,
          selectedTileColor: colors.secondaryContainer,
          leading: _InitialsAvatar(person: person, selected: isSelected),
          title: Text(
            formatPersonName(
              person.firstName,
              person.lastName,
              ref.watch(nameOrderProvider),
            ),
          ),
          subtitle: _buildCardSubtitle(person, badges),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/persons/edit/${person.id}'),
          onLongPress: () => _toggleSelection(person.id, !isSelected),
        );
      },
    );
  }

  Widget _buildDataTable(List<Person> sorted) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final checkboxTheme = CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withAlpha(30);
        }
        return states.contains(WidgetState.selected)
            ? colors.primary
            : colors.surfaceContainerHighest;
      }),
      checkColor: WidgetStatePropertyAll(colors.onPrimary),
      side: BorderSide(color: colors.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
    return StickyDataTable(
      minWidth: 1050,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      showCheckboxColumn: true,
      columnSpacing: 12,
      horizontalMargin: 12,
      checkboxHorizontalMargin: 8,
      headingCheckboxTheme: checkboxTheme,
      dataRowCheckboxTheme: checkboxTheme,
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
          label: const Text('Baptism Date'),
          fixedWidth: 130,
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
        return DataRow2(
          selected: _selectedIds.contains(person.id),
          onSelectChanged: (selected) =>
              _toggleSelection(person.id, selected ?? false),
          onLongPress: () => context.push('/persons/edit/${person.id}'),
          onSecondaryTapDown: (details) =>
              _showRowMenu(person, details.globalPosition),
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
            DataCell(
              Text(_formatDate(person.baptismDate)),
              onTap: () => context.push('/persons/edit/${person.id}'),
            ),
            DataCell(Center(child: _roleBadge(person.congregationRole))),
            DataCell(Center(child: _pioneerBadge(person.pioneerType))),
            DataCell(
              Center(child: ActiveStatusIcon(isActive: person.isActive)),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget? _buildCardSubtitle(Person person, List<Widget> badges) {
    if (!person.isActive) badges = [const InactiveLabel(), ...badges];
    final otherNames = person.otherNames.trim();
    final baptismDate = person.baptismDate;
    if (otherNames.isEmpty && baptismDate == null && badges.isEmpty) {
      return null;
    }

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
          if (baptismDate != null)
            Padding(
              padding: EdgeInsets.only(top: otherNames.isEmpty ? 0 : 2),
              child: Text(
                'Baptized: ${_formatDate(baptismDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (badges.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: otherNames.isEmpty && baptismDate == null ? 2 : 6,
              ),
              child: Wrap(spacing: 6, runSpacing: 6, children: badges),
            ),
        ],
      ),
    );
  }

  int _compareDates(DateTime? a, DateTime? b, {required bool ascending}) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return ascending ? a.compareTo(b) : b.compareTo(a);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMMMd().format(date);
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

  Future<void> _showRowMenu(Person person, Offset globalPosition) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_PublisherAction>(
      context: context,
      position: RelativeRect.fromRect(
        overlay.globalToLocal(globalPosition) & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        AppPopupMenuItem(
          value: _PublisherAction.edit,
          icon: Icons.edit_outlined,
          label: 'Edit',
        ),
        AppPopupMenuItem(
          value: _PublisherAction.exportRecords,
          icon: Icons.description,
          label: 'Export Record (S-21)',
        ),
        const PopupMenuDivider(),
        AppPopupMenuItem(
          value: _PublisherAction.archive,
          icon: Icons.inventory_2_outlined,
          label: 'Archive',
        ),
        AppPopupMenuItem(
          value: _PublisherAction.moveToTrash,
          icon: Icons.delete_outline,
          label: 'Move to Trash',
        ),
      ],
    );
    if (action != null && mounted) {
      _runAction(context, action, {person.id});
    }
  }

  void _runAction(BuildContext context, _PublisherAction action, Set<int> ids) {
    switch (action) {
      case _PublisherAction.edit:
        context.push('/persons/edit/${ids.single}');
      case _PublisherAction.exportRecords:
        _export(context, ids);
      case _PublisherAction.archive:
        _archive(context, ids);
      case _PublisherAction.moveToTrash:
        _moveToTrash(context, ids);
    }
  }

  Future<void> _export(BuildContext context, Set<int> ids) async {
    final svc = ReportService(
      ref.read(databaseProvider),
      congregationId: ref.read(currentCongregationIdProvider),
    );
    await _exportPublisherRecordsFor(
      context,
      svc,
      personIds: Set<int>.from(ids),
    );
  }

  Future<void> _archive(BuildContext context, Set<int> ids) async {
    var selectedReason = PersonArchiveReason.transferredOut;
    var selectedDate = DateTime.now();
    final request = await showDialog<_ArchiveRequest>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Archive Publishers'),
          scrollable: true,
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Archive ${ids.length} publisher(s). Their records '
                  'will be preserved but excluded from current lists, groups, '
                  'reports, and statistics.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<PersonArchiveReason>(
                  isExpanded: true,
                  initialValue: selectedReason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: PersonArchiveReason.values
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (reason) {
                    if (reason != null) {
                      setDialogState(() => selectedReason = reason);
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Effective date: '
                    '${MaterialLocalizations.of(context).formatMediumDate(selectedDate)}',
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                _ArchiveRequest(
                  reason: selectedReason,
                  archivedAt: selectedDate,
                ),
              ),
              child: const Text('Archive'),
            ),
          ],
        ),
      ),
    );

    if (request == null || !mounted) return;
    final targets = ids.toList();
    try {
      final db = ref.read(databaseProvider);
      for (final id in targets) {
        await db.archivePerson(
          id,
          reason: request.reason,
          archivedAt: request.archivedAt,
        );
      }
      setState(() => _selectedIds.removeAll(targets));
      ref.invalidate(personsProvider);
      ref.invalidate(archivedPersonsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${targets.length} publisher(s) archived.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to archive publishers: $error')),
        );
      }
    }
  }

  Future<void> _moveToTrash(BuildContext context, Set<int> ids) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move Publishers to Trash?'),
        content: Text(
          'Move ${ids.length} publisher(s) to Trash? Their records '
          'will be hidden but can be restored later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final targets = ids.toList();
    try {
      final db = ref.read(databaseProvider);
      for (final id in targets) {
        await db.movePersonToTrash(id);
      }
      setState(() => _selectedIds.removeAll(targets));
      ref.invalidate(personsProvider);
      ref.invalidate(trashedPersonsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${targets.length} publisher(s) moved to Trash.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to move publishers: $error')),
        );
      }
    }
  }
}

/// Runs the S-21 export flow: options, output directory, progress, result.
///
/// Passing [personIds] limits the export to those publishers instead of
/// exporting the whole congregation.
Future<void> _exportPublisherRecordsFor(
  BuildContext context,
  ReportService svc, {
  Set<int>? personIds,
}) async {
  try {
    final options = await ExportRecordsDialog.show(
      context,
      selectionCount: personIds?.length,
    );
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
        includeInactive: options.includeInactive,
        personIds: personIds,
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

enum _PublisherAction { edit, exportRecords, archive, moveToTrash }

/// Lets the screen's keyboard shortcuts reach the table's selection.
class _TableCommands {
  VoidCallback? selectAll;
  VoidCallback? clearSelection;
}

class _ArchiveRequest {
  const _ArchiveRequest({required this.reason, required this.archivedAt});

  final PersonArchiveReason reason;
  final DateTime archivedAt;
}

class _PersonListOptionsDialog extends StatefulWidget {
  final PersonListOptions initialOptions;

  const _PersonListOptionsDialog({required this.initialOptions});

  @override
  State<_PersonListOptionsDialog> createState() =>
      _PersonListOptionsDialogState();
}

class _PersonListOptionsDialogState extends State<_PersonListOptionsDialog> {
  late PersonListOptions _options;

  @override
  void initState() {
    super.initState();
    _options = widget.initialOptions;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter and Sort Publishers'),
      contentPadding: const EdgeInsets.only(top: 8),
      content: SizedBox(
        key: const ValueKey('person-list-options-content'),
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile.adaptive(
                key: const ValueKey('person-list-include-inactive'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: const Text('Include inactive publishers'),
                subtitle: const Text(
                  'Turn off to show active publishers only.',
                ),
                value: _options.includeInactive,
                onChanged: (value) => setState(
                  () => _options = _options.copyWith(includeInactive: value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 24),
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    _dropdown<BaptismDateFilter>(
                      label: 'Baptism Date',
                      value: _options.baptismDateFilter,
                      values: BaptismDateFilter.values,
                      labelFor: _baptismDateLabel,
                      onChanged: (value) => _options = _options.copyWith(
                        baptismDateFilter: value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _dropdown<GroupAssignmentFilter>(
                      label: 'Field Service Group',
                      value: _options.groupAssignmentFilter,
                      values: GroupAssignmentFilter.values,
                      labelFor: _groupAssignmentLabel,
                      onChanged: (value) => _options = _options.copyWith(
                        groupAssignmentFilter: value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _dropdown<PioneerAssignmentFilter>(
                      label: 'Pioneer Assignment',
                      value: _options.pioneerAssignmentFilter,
                      values: PioneerAssignmentFilter.values,
                      labelFor: _pioneerAssignmentLabel,
                      onChanged: (value) => _options = _options.copyWith(
                        pioneerAssignmentFilter: value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _dropdown<CongregationRoleFilter>(
                      label: 'Congregation Role',
                      value: _options.congregationRoleFilter,
                      values: CongregationRoleFilter.values,
                      labelFor: _congregationRoleLabel,
                      onChanged: (value) => _options = _options.copyWith(
                        congregationRoleFilter: value,
                      ),
                    ),
                    const Divider(height: 32),
                    Text('Sort', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    _dropdown<PersonSortField>(
                      label: 'Sort By',
                      value: _options.sortField,
                      values: PersonSortField.values,
                      labelFor: _sortFieldLabel,
                      onChanged: (value) =>
                          _options = _options.copyWith(sortField: value),
                    ),
                    const SizedBox(height: 12),
                    _dropdown<bool>(
                      label: 'Direction',
                      value: _options.sortAscending,
                      values: const [true, false],
                      labelFor: (value) => value ? 'Ascending' : 'Descending',
                      onChanged: (value) =>
                          _options = _options.copyWith(sortAscending: value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _options = const PersonListOptions()),
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_options),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
          )
          .toList(),
      onChanged: (selected) {
        if (selected == null) return;
        setState(() => onChanged(selected));
      },
    );
  }

  String _baptismDateLabel(BaptismDateFilter value) => switch (value) {
    BaptismDateFilter.any => 'Any',
    BaptismDateFilter.recorded => 'Date recorded',
    BaptismDateFilter.missing => 'Date missing',
  };

  String _groupAssignmentLabel(GroupAssignmentFilter value) => switch (value) {
    GroupAssignmentFilter.any => 'Any',
    GroupAssignmentFilter.assigned => 'Assigned to a group',
    GroupAssignmentFilter.unassigned => 'Not assigned to a group',
  };

  String _pioneerAssignmentLabel(PioneerAssignmentFilter value) =>
      switch (value) {
        PioneerAssignmentFilter.any => 'Any',
        PioneerAssignmentFilter.pioneer => 'Any pioneer',
        PioneerAssignmentFilter.publisher => 'Publisher (not a pioneer)',
        PioneerAssignmentFilter.regularPioneer => 'Regular Pioneer',
        PioneerAssignmentFilter.specialPioneer => 'Special Pioneer',
        PioneerAssignmentFilter.fieldMissionary => 'Field Missionary',
      };

  String _congregationRoleLabel(CongregationRoleFilter value) =>
      switch (value) {
        CongregationRoleFilter.any => 'Any',
        CongregationRoleFilter.noAppointment => 'No appointment',
        CongregationRoleFilter.elder => 'Elder',
        CongregationRoleFilter.ministerialServant => 'Ministerial Servant',
      };

  String _sortFieldLabel(PersonSortField value) => switch (value) {
    PersonSortField.name => 'Name',
    PersonSortField.baptismDate => 'Baptism Date',
    PersonSortField.birthDate => 'Birth Date',
    PersonSortField.congregationRole => 'Congregation Role',
    PersonSortField.pioneerType => 'Pioneer Assignment',
    PersonSortField.activeStatus => 'Active Status',
  };
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.person, required this.selected});

  final Person person;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (selected) {
      return CircleAvatar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.check),
      );
    }
    final initials = [
      person.firstName,
      person.lastName,
    ].where((name) => name.isNotEmpty).map((name) => name[0]).join();
    return CircleAvatar(
      backgroundColor: person.isActive
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      foregroundColor: person.isActive
          ? colors.onPrimaryContainer
          : colors.onSurfaceVariant,
      child: Text(initials.toUpperCase()),
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
