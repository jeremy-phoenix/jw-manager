import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/widgets/app_popup_menu_item.dart';
import 'package:congregation_manager/ui/widgets/search_text_field.dart';

enum PersonRecordsView { archive, trash }

class PersonRecordsScreen extends ConsumerStatefulWidget {
  const PersonRecordsScreen({super.key, required this.view});

  final PersonRecordsView view;

  @override
  ConsumerState<PersonRecordsScreen> createState() =>
      _PersonRecordsScreenState();
}

class _PersonRecordsScreenState extends ConsumerState<PersonRecordsScreen> {
  String _searchQuery = '';

  bool get _isArchive => widget.view == PersonRecordsView.archive;

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(
      _isArchive ? archivedPersonsProvider : trashedPersonsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Publishers',
          onPressed: () => context.go('/persons'),
        ),
        title: Text(_isArchive ? 'Archived Publishers' : 'Trash'),
        actions: [
          if (_isArchive)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Open Trash',
              onPressed: () => context.go('/persons/trash'),
            )
          else
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              tooltip: 'Open Archive',
              onPressed: () => context.go('/persons/archive'),
            ),
          if (!_isArchive)
            personsAsync.maybeWhen(
              data: (persons) => IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Empty Trash',
                onPressed: persons.isEmpty
                    ? null
                    : () => _emptyTrash(context, persons),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: Column(
        children: [
          _RecordsInfoBanner(isArchive: _isArchive),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SearchTextField(
              query: _searchQuery,
              hintText: _isArchive
                  ? 'Search archived publishers...'
                  : 'Search Trash...',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () => setState(() => _searchQuery = ''),
            ),
          ),
          Expanded(
            child: personsAsync.when(
              data: (persons) {
                final filtered = _filter(persons);
                if (filtered.isEmpty) {
                  return _EmptyRecordsView(
                    isArchive: _isArchive,
                    hasSearch: _searchQuery.trim().isNotEmpty,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _buildPersonCard(context, filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Unable to load publisher records: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Person> _filter(List<Person> persons) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return persons;
    return persons.where((person) {
      return [
        person.firstName,
        person.lastName,
        person.otherNames,
        '${person.firstName} ${person.lastName}',
        '${person.lastName}, ${person.firstName}',
        person.archiveReason?.displayName ?? '',
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildPersonCard(BuildContext context, Person person) {
    final nameOrder = ref.watch(nameOrderProvider);
    final subtitle = _isArchive
        ? _archiveDescription(context, person)
        : _trashDescription(context, person);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            _isArchive ? Icons.inventory_2_outlined : Icons.delete_outline,
          ),
        ),
        title: Text(
          formatPersonName(person.firstName, person.lastName, nameOrder),
        ),
        subtitle: Text(subtitle),
        trailing: PopupMenuButton<_RecordAction>(
          tooltip: 'Publisher actions',
          onSelected: (action) => _handleAction(context, person, action),
          itemBuilder: (_) => _isArchive
              ? [
                  AppPopupMenuItem(
                    value: _RecordAction.restore,
                    icon: Icons.restore,
                    label: 'Restore to Publishers',
                  ),
                  AppPopupMenuItem(
                    value: _RecordAction.moveToTrash,
                    icon: Icons.delete_outline,
                    label: 'Move to Trash',
                  ),
                ]
              : [
                  AppPopupMenuItem(
                    value: _RecordAction.restore,
                    icon: Icons.restore_from_trash,
                    label: person.archivedAt == null
                        ? 'Restore to Publishers'
                        : 'Restore to Archive',
                  ),
                  AppPopupMenuItem(
                    value: _RecordAction.deletePermanently,
                    icon: Icons.delete_forever,
                    label: 'Delete Permanently',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
        ),
      ),
    );
  }

  String _archiveDescription(BuildContext context, Person person) {
    final reason = person.archiveReason?.displayName ?? 'Archived';
    final date = person.archivedAt;
    return date == null ? reason : '$reason · ${_formatDate(context, date)}';
  }

  String _trashDescription(BuildContext context, Person person) {
    final source = person.archivedAt == null
        ? 'From Publishers'
        : 'From Archive';
    final date = person.trashedAt;
    return date == null ? source : '$source · ${_formatDate(context, date)}';
  }

  Future<void> _handleAction(
    BuildContext context,
    Person person,
    _RecordAction action,
  ) async {
    switch (action) {
      case _RecordAction.restore:
        await _restore(context, person);
      case _RecordAction.moveToTrash:
        await _moveToTrash(context, person);
      case _RecordAction.deletePermanently:
        await _deletePermanently(context, person);
    }
  }

  Future<void> _restore(BuildContext context, Person person) async {
    try {
      final db = ref.read(databaseProvider);
      final String destination;
      if (_isArchive) {
        await db.restoreArchivedPerson(person.id);
        destination = 'Publishers';
      } else {
        final restoredStatus = await db.restoreTrashedPerson(person.id);
        destination = restoredStatus == PersonRecordStatus.archived
            ? 'Archive'
            : 'Publishers';
      }
      if (context.mounted) {
        _showMessage(
          context,
          '${_displayName(person)} restored to $destination.',
        );
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Unable to restore publisher: $error');
      }
    }
  }

  Future<void> _moveToTrash(BuildContext context, Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move Publisher to Trash?'),
        content: Text(
          '${_displayName(person)} will be hidden from the Archive. '
          'Their information can still be restored from Trash.',
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
    if (confirmed != true) return;

    try {
      await ref.read(databaseProvider).movePersonToTrash(person.id);
      if (context.mounted) {
        _showMessage(context, '${_displayName(person)} moved to Trash.');
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Unable to move publisher to Trash: $error');
      }
    }
  }

  Future<void> _deletePermanently(BuildContext context, Person person) async {
    final confirmed = await _confirmPermanentDeletion(
      context,
      title: 'Delete Publisher Permanently?',
      message:
          '${_displayName(person)} and all of their phone numbers, emergency '
          'contacts, service reports, and pioneer periods will be permanently '
          'deleted. This cannot be undone.',
    );
    if (!confirmed) return;

    try {
      await ref.read(databaseProvider).deletePersonPermanently(person.id);
      if (context.mounted) {
        _showMessage(context, '${_displayName(person)} permanently deleted.');
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Unable to delete publisher: $error');
      }
    }
  }

  Future<void> _emptyTrash(BuildContext context, List<Person> persons) async {
    final confirmed = await _confirmPermanentDeletion(
      context,
      title: 'Empty Trash?',
      message:
          'Permanently delete ${persons.length} publisher(s) and all related '
          'records? This cannot be undone.',
    );
    if (!confirmed) return;

    try {
      final db = ref.read(databaseProvider);
      for (final person in persons) {
        await db.deletePersonPermanently(person.id);
      }
      if (context.mounted) {
        _showMessage(context, 'Trash emptied.');
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Unable to empty Trash: $error');
      }
    }
  }

  Future<bool> _confirmPermanentDeletion(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(dialogContext).colorScheme.error,
            ),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete Permanently'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _displayName(Person person) =>
      '${person.firstName} ${person.lastName}'.trim();

  String _formatDate(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date.toLocal());

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _RecordAction { restore, moveToTrash, deletePermanently }

class _RecordsInfoBanner extends StatelessWidget {
  const _RecordsInfoBanner({required this.isArchive});

  final bool isArchive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            isArchive ? Icons.info_outline : Icons.warning_amber_rounded,
            color: isArchive ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isArchive
                  ? 'Archived publishers are excluded from current lists, '
                        'groups, reports, and statistics.'
                  : 'Items in Trash remain restorable until they are '
                        'permanently deleted.',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecordsView extends StatelessWidget {
  const _EmptyRecordsView({required this.isArchive, required this.hasSearch});

  final bool isArchive;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off
                  : isArchive
                  ? Icons.inventory_2_outlined
                  : Icons.delete_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch
                  ? 'No matching publishers found.'
                  : isArchive
                  ? 'No archived publishers.'
                  : 'Trash is empty.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
