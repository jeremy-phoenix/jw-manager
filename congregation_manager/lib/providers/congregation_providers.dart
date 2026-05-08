import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';

/// Provides all congregations.
final congregationsProvider = FutureProvider<List<Congregation>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAllCongregations();
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

/// Provides the current congregation object.
final currentCongregationProvider = FutureProvider<Congregation?>((ref) async {
  final id = ref.watch(currentCongregationIdProvider);
  if (id == null) return null;
  final db = ref.read(databaseProvider);
  try {
    return await db.getCongregation(id);
  } catch (_) {
    return null;
  }
});
