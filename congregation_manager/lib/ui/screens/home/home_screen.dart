import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/group_providers.dart';
import 'package:congregation_manager/ui/theme/layout.dart';
import 'package:congregation_manager/ui/widgets/toolbar_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persons = ref.watch(personsProvider);
    final groups = ref.watch(fieldServiceGroupsProvider);
    final currentCong = ref.watch(currentCongregationProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stats = [
      _DashboardStat(
        icon: Icons.people_alt_outlined,
        label: 'Publishers',
        description: 'All current publisher records',
        value: persons.when(
          data: (list) => list.length.toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: colors.primary,
        onTap: () => context.go('/persons'),
      ),
      _DashboardStat(
        icon: Icons.check_circle_outline,
        label: 'Active Publishers',
        description: 'Currently active',
        value: persons.when(
          data: (list) => list.where((p) => p.isActive).length.toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: colors.tertiary,
        onTap: () => context.go('/persons'),
      ),
      _DashboardStat(
        icon: Icons.person_off_outlined,
        label: 'Inactive Publishers',
        description: 'Included in current records',
        value: persons.when(
          data: (list) => list.where((p) => !p.isActive).length.toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: colors.secondary,
        onTap: () => context.go('/persons'),
      ),
      _DashboardStat(
        icon: Icons.explore_outlined,
        label: 'Pioneers',
        description: 'Active RP, SP, and FM',
        value: persons.when(
          data: (list) => list
              .where((p) => p.isActive && p.pioneerType != PioneerType.none)
              .length
              .toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: colors.primary,
        onTap: () {
          ref
              .read(personListOptionsProvider.notifier)
              .set(
                const PersonListOptions(
                  includeInactive: false,
                  pioneerAssignmentFilter: PioneerAssignmentFilter.pioneer,
                ),
              );
          context.go('/persons');
        },
      ),
      _DashboardStat(
        icon: Icons.groups_outlined,
        label: 'Field Service Groups',
        description: 'Current group arrangement',
        value: groups.when(
          data: (list) => list.length.toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: colors.secondary,
        onTap: () => context.go('/groups'),
      ),
      _DashboardStat(
        icon: Icons.person_add_disabled_outlined,
        label: 'Unassigned',
        description: 'Active publishers without a group',
        value: persons.when(
          data: (list) => list
              .where((p) => p.isActive && p.fieldServiceGroupId == null)
              .length
              .toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: colors.error,
        onTap: () => context.go('/groups'),
      ),
    ];

    final missingBaptismDates = persons.when(
      data: (list) =>
          list.where((p) => p.isActive && p.baptismDate == null).length,
      loading: () => null,
      error: (e, s) => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentCong.when(
            data: (c) => c?.name ?? 'Congregation Manager',
            loading: () => 'Congregation Manager',
            error: (e, s) => 'Congregation Manager',
          ),
        ),
        actions: [_CongregationSwitcher()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final inset = constraints.maxWidth < AppBreakpoints.medium
              ? AppSpacing.lg
              : AppSpacing.xl;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(inset, AppSpacing.sm, inset, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardGrid(stats: stats),
                const SizedBox(height: AppSpacing.xl),
                Text('Quick Actions', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _QuickActions(
                  onAddPerson: () => context.push('/persons/new'),
                  onServiceReports: () => context.go('/reports'),
                  onManageGroups: () => context.go('/groups'),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Publisher Records', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _BaptismDateOverviewCard(
                  missingCount: missingBaptismDates,
                  onTap: () {
                    ref
                        .read(personListOptionsProvider.notifier)
                        .set(
                          const PersonListOptions(
                            includeInactive: false,
                            baptismDateFilter: BaptismDateFilter.missing,
                          ),
                        );
                    context.go('/persons');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardStat {
  final IconData icon;
  final String label;
  final String description;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _DashboardStat({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.color,
    required this.onTap,
  });
}

class _DashboardGrid extends StatelessWidget {
  final List<_DashboardStat> stats;

  const _DashboardGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    // Tiles fill the row and wrap as the window narrows, so no breakpoints.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 142,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemBuilder: (context, index) => _StatCard(stat: stats[index]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _DashboardStat stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: stat.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: stat.color.withAlpha(28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(stat.icon, color: stat.color, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stat.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: stat.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                stat.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                stat.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onAddPerson;
  final VoidCallback onServiceReports;
  final VoidCallback onManageGroups;

  const _QuickActions({
    required this.onAddPerson,
    required this.onServiceReports,
    required this.onManageGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.icon(
          onPressed: onAddPerson,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Publisher'),
        ),
        OutlinedButton.icon(
          onPressed: onServiceReports,
          icon: const Icon(Icons.assignment_outlined),
          label: const Text('Service Reports'),
        ),
        OutlinedButton.icon(
          onPressed: onManageGroups,
          icon: const Icon(Icons.groups_outlined),
          label: const Text('Manage Groups'),
        ),
      ],
    );
  }
}

class _BaptismDateOverviewCard extends StatelessWidget {
  final int? missingCount;
  final VoidCallback onTap;

  const _BaptismDateOverviewCard({
    required this.missingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final description = switch (missingCount) {
      null => 'Loading baptism date information…',
      0 => 'Every active publisher has a baptism date recorded.',
      1 => '1 active publisher has no baptism date recorded.',
      final count => '$count active publishers have no baptism date recorded.',
    };

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: const Icon(Icons.water_drop_outlined),
        ),
        title: const Text('Baptism Date Overview'),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _CongregationSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final congregationsAsync = ref.watch(congregationsProvider);
    final currentId = ref.watch(currentCongregationIdProvider);

    return congregationsAsync.when(
      data: (congregations) {
        return ToolbarMenu<Object>(
          icon: Icons.swap_horiz,
          label: 'Switch congregation',
          tooltip: 'Switch Congregation',
          itemBuilder: (context) => [
            ...congregations.map(
              (c) => PopupMenuItem<int>(
                value: c.id,
                child: Row(
                  children: [
                    if (c.id == currentId)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.name)),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'new',
              child: Row(
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 8),
                  const Text('New Congregation'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18),
                  const SizedBox(width: 8),
                  const Text('Edit Current'),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value is int) {
              await ref.read(currentCongregationIdProvider.notifier).set(value);
            } else if (value == 'new') {
              context.push('/congregations/new');
            } else if (value == 'edit' && currentId != null) {
              context.push('/congregations/edit/$currentId');
            }
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
