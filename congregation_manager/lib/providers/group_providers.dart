import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/person_providers.dart';

/// Provides field service groups for the current congregation as a stream.
final fieldServiceGroupsProvider = StreamProvider<List<FieldServiceGroup>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final congId = ref.watch(currentCongregationIdProvider);
  return db.watchAllFieldServiceGroups(congregationId: congId);
});

/// Provides a single field service group by ID.
final fieldServiceGroupProvider = FutureProvider.family<FieldServiceGroup, int>(
  (ref, id) {
    final db = ref.watch(databaseProvider);
    return db.getFieldServiceGroup(id);
  },
);

/// Search filter for field service groups.
class GroupSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final groupSearchQueryProvider =
    NotifierProvider<GroupSearchQueryNotifier, String>(
      GroupSearchQueryNotifier.new,
    );

/// Filtered groups based on search query.
final filteredGroupsProvider = Provider<AsyncValue<List<FieldServiceGroup>>>((
  ref,
) {
  final groupsAsync = ref.watch(fieldServiceGroupsProvider);
  final query = ref.watch(groupSearchQueryProvider).toLowerCase();

  return groupsAsync.whenData((groups) {
    if (query.isEmpty) return groups;
    return groups.where((g) => g.name.toLowerCase().contains(query)).toList();
  });
});

/// Provides publishers keyed by their field service group ID.
final personsByGroupProvider = Provider<AsyncValue<Map<int?, List<Person>>>>((
  ref,
) {
  final personsAsync = ref.watch(personsProvider);

  return personsAsync.whenData((persons) {
    final grouped = <int?, List<Person>>{};
    for (final person in persons) {
      grouped.putIfAbsent(person.fieldServiceGroupId, () => []).add(person);
    }
    return grouped;
  });
});

/// Provides publishers assigned to a specific field service group.
final groupMembersProvider = Provider.family<AsyncValue<List<Person>>, int>((
  ref,
  groupId,
) {
  final groupedAsync = ref.watch(personsByGroupProvider);
  return groupedAsync.whenData((grouped) => grouped[groupId] ?? const []);
});
