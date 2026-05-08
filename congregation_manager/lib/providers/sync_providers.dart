import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/services/sync_service.dart';

final syncSettingsProvider = StreamProvider<SyncSetting>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchSyncSettings();
});

final pendingSyncOperationCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchPendingSyncOperationCount();
});

final openSyncConflictCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchOpenSyncConflictCount();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(databaseProvider));
});
