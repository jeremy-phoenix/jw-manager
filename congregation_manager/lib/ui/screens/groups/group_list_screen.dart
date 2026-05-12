import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/group_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/widgets/app_popup_menu_item.dart';
import 'package:congregation_manager/ui/widgets/search_text_field.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredGroups = ref.watch(filteredGroupsProvider);
    final personsByGroup = ref.watch(personsByGroupProvider);
    final searchQuery = ref.watch(groupSearchQueryProvider);
    final nameOrder = ref.watch(nameOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Service Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Group',
            onPressed: () => context.push('/groups/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchTextField(
              query: searchQuery,
              hintText: 'Search groups...',
              onChanged: (value) =>
                  ref.read(groupSearchQueryProvider.notifier).set(value),
              onClear: () =>
                  ref.read(groupSearchQueryProvider.notifier).set(''),
            ),
          ),
          Expanded(
            child: filteredGroups.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(
                    child: Text('No field service groups found.'),
                  );
                }
                return personsByGroup.when(
                  data: (groupedPersons) {
                    final allPersons = [
                      for (final persons in groupedPersons.values) ...persons,
                    ];
                    final personsById = {
                      for (final person in allPersons) person.id: person,
                    };

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final members = groupedPersons[group.id] ?? const [];
                        return _GroupListCard(
                          index: index,
                          group: group,
                          members: members,
                          personsById: personsById,
                          nameOrder: nameOrder,
                          onView: () =>
                              context.push('/groups/${group.id}/persons'),
                          onEdit: () =>
                              context.push('/groups/edit/${group.id}'),
                          onDelete: () =>
                              _deleteGroup(context, ref, group, members.length),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
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

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    FieldServiceGroup group,
    int memberCount,
  ) async {
    if (memberCount > 0) {
      final viewPublishers = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Group Has Publishers'),
          content: Text(
            'Move or unassign ${_memberCountLabel(memberCount)} before deleting "${group.name}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('View Publishers'),
            ),
          ],
        ),
      );

      if (viewPublishers == true && context.mounted) {
        context.push('/groups/${group.id}/persons');
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
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

    if (confirmed == true && context.mounted) {
      final db = ref.read(databaseProvider);
      try {
        await db.deleteFieldServiceGroup(group.id);
        ref.invalidate(fieldServiceGroupsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }
}

class _GroupListCard extends StatelessWidget {
  final int index;
  final FieldServiceGroup group;
  final List<Person> members;
  final Map<int, Person> personsById;
  final NameOrder nameOrder;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupListCard({
    required this.index,
    required this.group,
    required this.members,
    required this.personsById,
    required this.nameOrder,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final overseerName = _personName(personsById[group.groupOverseerId]);
    final assistantName = _personName(personsById[group.assistantId]);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(group.name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.description.isNotEmpty) ...[
                Text(group.description),
                const SizedBox(height: 6),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _GroupInfoChip(
                    icon: Icons.groups,
                    label: _memberCountLabel(members.length),
                  ),
                  if (overseerName != null)
                    _GroupInfoChip(
                      icon: Icons.shield,
                      label: 'Overseer: $overseerName',
                    ),
                  if (assistantName != null)
                    _GroupInfoChip(
                      icon: Icons.badge,
                      label: 'Assistant: $assistantName',
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Group Actions',
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (_) => [
            AppPopupMenuItem(
              value: 'view',
              icon: Icons.groups,
              label: 'View Publishers',
            ),
            AppPopupMenuItem(
              value: 'edit',
              icon: Icons.edit,
              label: 'Edit Group',
            ),
            PopupMenuDivider(),
            AppPopupMenuItem(
              value: 'delete',
              icon: Icons.delete,
              label: 'Delete Group',
            ),
          ],
        ),
        onTap: onView,
      ),
    );
  }

  String? _personName(Person? person) {
    if (person == null) return null;
    return formatPersonName(person.firstName, person.lastName, nameOrder);
  }
}

class _GroupInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GroupInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

String _memberCountLabel(int count) {
  final suffix = count == 1 ? 'publisher' : 'publishers';
  return '$count $suffix';
}
