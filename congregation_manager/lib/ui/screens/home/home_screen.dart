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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  icon: Icons.people,
                  label: 'Total Publishers',
                  value: persons.when(
                    data: (list) => list.length.toString(),
                    loading: () => '...',
                    error: (e, s) => '–',
                  ),
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.check_circle,
                  label: 'Active',
                  value: persons.when(
                    data: (list) =>
                        list.where((p) => p.isActive).length.toString(),
                    loading: () => '...',
                    error: (e, s) => '–',
                  ),
                  color: Colors.green,
                ),
                _StatCard(
                  icon: Icons.cancel,
                  label: 'Inactive',
                  value: persons.when(
                    data: (list) =>
                        list.where((p) => !p.isActive).length.toString(),
                    loading: () => '...',
                    error: (e, s) => '–',
                  ),
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.groups,
                  label: 'Field Service Groups',
                  value: groups.when(
                    data: (list) => list.length.toString(),
                    loading: () => '...',
                    error: (e, s) => '–',
                  ),
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 200,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
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
