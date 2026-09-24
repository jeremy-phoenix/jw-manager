import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';

/// Provides all congregations; updates when sync changes them.
final congregationsProvider = StreamProvider<List<Congregation>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCongregations();
});

/// Seeded in main() from SharedPreferences before runApp.
final initialCongregationIdProvider = Provider<int?>((_) => null);

/// Tracks the currently selected congregation ID.
/// Persisted in SharedPreferences. Null means none selected yet.
final currentCongregationIdProvider =
    NotifierProvider<CurrentCongregationIdNotifier, int?>(
        CurrentCongregationIdNotifier.new);

class CurrentCongregationIdNotifier extends Notifier<int?> {
  static const _key = 'currentCongregationId';

  @override
  int? build() {
    return ref.read(initialCongregationIdProvider);
  }

  Future<void> set(int id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, id);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Provides the current congregation object; null if it no longer exists.
final currentCongregationProvider = StreamProvider<Congregation?>((ref) {
  final id = ref.watch(currentCongregationIdProvider);
  if (id == null) return Stream.value(null);
  return ref.read(databaseProvider).watchCongregation(id);
});

/// After sync replaced or added data, keeps the congregation selection
/// pointing at a congregation that exists.
Future<void> ensureValidCongregationSelection(WidgetRef ref) async {
  final congregations = await ref.read(databaseProvider).getAllCongregations();
  final notifier = ref.read(currentCongregationIdProvider.notifier);
  final current = ref.read(currentCongregationIdProvider);
  if (congregations.isEmpty) {
    await notifier.clear();
  } else if (!congregations.any((c) => c.id == current)) {
    await notifier.set(congregations.first.id);
  }
}
