import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';

/// Global database provider.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});
