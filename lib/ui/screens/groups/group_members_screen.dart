import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/group_providers.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/widgets/sticky_data_table.dart';
import 'package:congregation_manager/ui/theme/layout.dart';
import 'package:congregation_manager/ui/widgets/empty_state.dart';
import 'package:congregation_manager/ui/widgets/publisher_status.dart';
import 'package:congregation_manager/ui/widgets/toolbar_actions.dart';

class GroupMembersScreen extends ConsumerWidget {
  final int? groupId;

  const GroupMembersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = groupId;
    if (id == null) {
      return const Scaffold(body: Center(child: Text('Group not found.')));
    }

    final groupAsync = ref.watch(fieldServiceGroupProvider(id));
    final membersAsync = ref.watch(groupMembersProvider(id));
    final allPersonsAsync = ref.watch(personsProvider);
    final nameOrder = ref.watch(nameOrderProvider);

    return groupAsync.when(
      data: (group) => Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            ToolbarAction(
              icon: Icons.edit,
              label: 'Edit Group',
              tooltip: 'Edit Group',
              onPressed: () => context.push('/groups/edit/${group.id}'),
            ),
          ],
        ),
        body: membersAsync.when(
          data: (members) => allPersonsAsync.when(
            data: (allPersons) => _GroupMembersContent(
              group: group,
              members: members,
              allPersons: allPersons,
              nameOrder: nameOrder,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => EmptyState.error(
              title: 'Could not load group publishers',
              error: error,
              action: TextButton(
                onPressed: () {
                  ref.invalidate(fieldServiceGroupProvider(id));
                  ref.invalidate(groupMembersProvider(id));
                  ref.invalidate(personsProvider);
                },
                child: const Text('Retry'),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState.error(
            title: 'Could not load group publishers',
            error: error,
            action: TextButton(
              onPressed: () {
                ref.invalidate(fieldServiceGroupProvider(id));
                ref.invalidate(groupMembersProvider(id));
                ref.invalidate(personsProvider);
              },
              child: const Text('Retry'),
            ),
          ),
        ),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Group Publishers')),
        body: EmptyState.error(
          title: 'Could not load group publishers',
          error: error,
          action: TextButton(
            onPressed: () {
              ref.invalidate(fieldServiceGroupProvider(id));
              ref.invalidate(groupMembersProvider(id));
              ref.invalidate(personsProvider);
            },
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}

class _GroupMembersContent extends StatelessWidget {
  final FieldServiceGroup group;
  final List<Person> members;
  final List<Person> allPersons;
  final NameOrder nameOrder;

  const _GroupMembersContent({
    required this.group,
    required this.members,
    required this.allPersons,
    required this.nameOrder,
  });

  @override
  Widget build(BuildContext context) {
    final personsById = {for (final person in allPersons) person.id: person};
    final overseerName = _personName(personsById[group.groupOverseerId]);
    final assistantName = _personName(personsById[group.assistantId]);
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.medium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.description.isNotEmpty) ...[
                Text(group.description),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.groups,
                    label: _memberCountLabel(members.length),
                  ),
                  if (overseerName != null)
                    _InfoChip(
                      icon: Icons.shield,
                      label: 'Overseer: $overseerName',
                    ),
                  if (assistantName != null)
                    _InfoChip(
                      icon: Icons.badge,
                      label: 'Assistant: $assistantName',
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: members.isEmpty
              ? EmptyState(
                  icon: Icons.group_outlined,
                  title: 'No publishers assigned',
                  message:
                      "Assign a field service group from a publisher's profile.",
                  action: TextButton(
                    onPressed: () => context.go('/persons'),
                    child: const Text('View Publishers'),
                  ),
                )
              : isWide
              ? _GroupMembersTable(members: members, nameOrder: nameOrder)
              : _GroupMembersList(members: members, nameOrder: nameOrder),
        ),
      ],
    );
  }

  String? _personName(Person? person) {
    if (person == null) return null;
    return formatPersonName(person.firstName, person.lastName, nameOrder);
  }
}

class _GroupMembersList extends StatelessWidget {
  final List<Person> members;
  final NameOrder nameOrder;

  const _GroupMembersList({required this.members, required this.nameOrder});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final person = members[index];
        final badges = _publisherBadges(context, person);

        return ListTile(
          leading: ActiveStatusIcon(isActive: person.isActive),
          title: Text(
            formatPersonName(person.firstName, person.lastName, nameOrder),
          ),
          subtitle: badges.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(spacing: 6, runSpacing: 6, children: badges),
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/persons/edit/${person.id}'),
        );
      },
    );
  }
}

class _GroupMembersTable extends StatelessWidget {
  final List<Person> members;
  final NameOrder nameOrder;

  const _GroupMembersTable({required this.members, required this.nameOrder});

  @override
  Widget build(BuildContext context) {
    return StickyDataTable(
      minWidth: 850,
      columnSpacing: 16,
      horizontalMargin: 16,
      columns: [
        DataColumn2(
          label: Text(
            nameOrder == NameOrder.lastFirst ? 'Last Name' : 'First Name',
          ),
        ),
        DataColumn2(
          label: Text(
            nameOrder == NameOrder.lastFirst ? 'First Name' : 'Last Name',
          ),
        ),
        const DataColumn2(label: Text('Role'), fixedWidth: 180),
        const DataColumn2(label: Text('Pioneer'), fixedWidth: 180),
        const DataColumn2(label: Text('Active'), fixedWidth: 72),
      ],
      rows: members.map((person) {
        return DataRow(
          onLongPress: () => context.push('/persons/edit/${person.id}'),
          cells: [
            DataCell(
              Text(
                nameOrder == NameOrder.lastFirst
                    ? person.lastName
                    : person.firstName,
              ),
              onTap: () => context.push('/persons/edit/${person.id}'),
            ),
            DataCell(
              Text(
                nameOrder == NameOrder.lastFirst
                    ? person.firstName
                    : person.lastName,
              ),
              onTap: () => context.push('/persons/edit/${person.id}'),
            ),
            DataCell(_roleBadge(context, person.congregationRole)),
            DataCell(_pioneerBadge(context, person.pioneerType)),
            DataCell(ActiveStatusIcon(isActive: person.isActive)),
          ],
        );
      }).toList(),
    );
  }
}

List<Widget> _publisherBadges(BuildContext context, Person person) => [
  if (person.congregationRole != CongregationRole.none)
    _roleBadge(context, person.congregationRole),
  if (person.pioneerType != PioneerType.none)
    _pioneerBadge(context, person.pioneerType),
];

Widget _roleBadge(BuildContext context, CongregationRole role) {
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

Widget _pioneerBadge(BuildContext context, PioneerType type) {
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

String _memberCountLabel(int count) {
  final suffix = count == 1 ? 'publisher' : 'publishers';
  return '$count $suffix';
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

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
    return Tooltip(
      message: label,
      child: Container(
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
      ),
    );
  }
}
