import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/group_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persons = ref.watch(personsProvider);
    final groups = ref.watch(fieldServiceGroupsProvider);
    final currentCong = ref.watch(currentCongregationProvider);
    final theme = Theme.of(context);
    final stats = [
      _DashboardStat(
        icon: Icons.people,
        label: 'Total Publishers',
        value: persons.when(
          data: (list) => list.length.toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: Colors.blue,
      ),
      _DashboardStat(
        icon: Icons.check_circle,
        label: 'Active',
        value: persons.when(
          data: (list) => list.where((p) => p.isActive).length.toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: Colors.green,
      ),
      _DashboardStat(
        icon: Icons.cancel,
        label: 'Inactive',
        value: persons.when(
          data: (list) => list.where((p) => !p.isActive).length.toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: Colors.orange,
      ),
      _DashboardStat(
        icon: Icons.groups,
        label: 'Field Service Groups',
        value: groups.when(
          data: (list) => list.length.toString(),
          loading: () => '...',
          error: (e, s) => '–',
        ),
        color: Colors.purple,
      ),
    ];

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
          final isCompact = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 16),
                _DashboardGrid(stats: stats),
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
  final String value;
  final Color color;

  const _DashboardStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DashboardGrid extends StatelessWidget {
  final List<_DashboardStat> stats;

  const _DashboardGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 340
            ? 1
            : width < 720
            ? 2
            : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 116,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) => _StatCard(stat: stats[index]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _DashboardStat stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
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
                    borderRadius: BorderRadius.circular(8),
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
              ],
            ),
            const Spacer(),
            Text(
              stat.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
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
        return PopupMenuButton<Object>(
          icon: const Icon(Icons.swap_horiz),
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
