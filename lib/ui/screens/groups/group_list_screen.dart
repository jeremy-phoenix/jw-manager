import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/group_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/widgets/app_popup_menu_item.dart';
import 'package:congregation_manager/ui/widgets/search_text_field.dart';
import 'package:congregation_manager/ui/theme/layout.dart';
import 'package:congregation_manager/ui/widgets/empty_state.dart';
import 'package:congregation_manager/ui/widgets/toolbar_actions.dart';
import 'package:congregation_manager/ui/widgets/screen_shortcuts.dart';

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});
  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  final _searchFocus = FocusNode();
  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = ref.watch(filteredGroupsProvider);
    final personsByGroup = ref.watch(personsByGroupProvider);
    final searchQuery = ref.watch(groupSearchQueryProvider);
    final nameOrder = ref.watch(nameOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Service Groups'),
        actions: [
          ToolbarAction.primary(
            icon: Icons.add,
            label: 'Add Group',
            tooltip: 'Add Group',
            onPressed: () => context.push('/groups/new'),
          ),
        ],
      ),
      body: ScreenShortcuts(
        bindings: {
          commandKey(LogicalKeyboardKey.keyF): ScreenShortcut(
            () => _searchFocus.requestFocus(),
            whileEditing: true,
          ),
          commandKey(LogicalKeyboardKey.keyN): ScreenShortcut(
            () => context.push('/groups/new'),
          ),
        },
        child: ReadableWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SearchTextField(
                  focusNode: _searchFocus,
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
                    return personsByGroup.when(
                      data: (groupedPersons) {
                        final allPersons = [
                          for (final persons in groupedPersons.values)
                            ...persons,
                        ];
                        final personsById = {
                          for (final person in allPersons) person.id: person,
                        };
                        final unassigned =
                            groupedPersons[null] ?? const <Person>[];
                        final normalizedQuery = searchQuery
                            .trim()
                            .toLowerCase();
                        final showUnassigned =
                            normalizedQuery.isEmpty ||
                            'unassigned publishers'.contains(normalizedQuery);

                        if (groups.isEmpty && !showUnassigned) {
                          return EmptyState(
                            icon: Icons.groups_outlined,
                            title: 'No field service groups found',
                            action: TextButton(
                              onPressed: () => ref
                                  .read(groupSearchQueryProvider.notifier)
                                  .set(''),
                              child: const Text('Clear search'),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: groups.length + (showUnassigned ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (showUnassigned && index == 0) {
                              return _UnassignedPersonsCard(
                                count: unassigned.length,
                                onView: () => _showUnassignedPersons(
                                  context,
                                  unassigned,
                                  nameOrder,
                                ),
                              );
                            }
                            final groupIndex = index - (showUnassigned ? 1 : 0);
                            final group = groups[groupIndex];
                            final members =
                                groupedPersons[group.id] ?? const [];
                            return _GroupListCard(
                              index: groupIndex,
                              group: group,
                              members: members,
                              personsById: personsById,
                              nameOrder: nameOrder,
                              onView: () =>
                                  context.push('/groups/${group.id}/persons'),
                              onEdit: () =>
                                  context.push('/groups/edit/${group.id}'),
                              onDelete: () => _deleteGroup(
                                context,
                                ref,
                                group,
                                members.length,
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => EmptyState.error(
                        title: 'Could not load groups',
                        error: e,
                        action: TextButton(
                          onPressed: () {
                            ref.invalidate(fieldServiceGroupsProvider);
                            ref.invalidate(personsByGroupProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => EmptyState.error(
                    title: 'Could not load groups',
                    error: e,
                    action: TextButton(
                      onPressed: () {
                        ref.invalidate(fieldServiceGroupsProvider);
                        ref.invalidate(personsByGroupProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUnassignedPersons(
    BuildContext context,
    List<Person> persons,
    NameOrder nameOrder,
  ) async {
    final sorted = List<Person>.from(persons)
      ..sort(
        (a, b) => formatPersonName(
          a.firstName,
          a.lastName,
          nameOrder,
        ).compareTo(formatPersonName(b.firstName, b.lastName, nameOrder)),
      );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Unassigned Publishers (${sorted.length})'),
        content: SizedBox(
          width: 440,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: sorted.isEmpty
                ? const Text('Everyone is assigned to a field service group.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final person = sorted[index];
                      return ListTile(
                        leading: Icon(
                          person.isActive ? Icons.person : Icons.person_off,
                        ),
                        title: Text(
                          formatPersonName(
                            person.firstName,
                            person.lastName,
                            nameOrder,
                          ),
                        ),
                        subtitle: person.isActive
                            ? null
                            : const Text('Inactive'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          context.push('/persons/edit/${person.id}');
                        },
                      );
                    },
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
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

class _UnassignedPersonsCard extends StatelessWidget {
  final int count;
  final VoidCallback onView;

  const _UnassignedPersonsCard({required this.count, required this.onView});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: count > 0 ? colors.tertiaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: count > 0
              ? colors.tertiary
              : colors.surfaceContainerHighest,
          foregroundColor: count > 0
              ? colors.onTertiary
              : colors.onSurfaceVariant,
          child: const Icon(Icons.person_off_outlined),
        ),
        title: const Text('Unassigned Publishers'),
        subtitle: Text(
          count == 0
              ? 'Everyone is assigned to a field service group.'
              : '$count ${count == 1 ? 'publisher is' : 'publishers are'} not assigned.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onView,
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}

String _memberCountLabel(int count) {
  final suffix = count == 1 ? 'publisher' : 'publishers';
  return '$count $suffix';
}
