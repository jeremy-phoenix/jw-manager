import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/services/sync/sync_credentials.dart';
import 'package:congregation_manager/services/sync/sync_scheduler.dart';
import 'package:congregation_manager/services/sync/sync_service.dart';

final syncCredentialStoreProvider = Provider<SyncCredentialStore>(
  (ref) => const SecureSyncCredentialStore(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(
    db,
    ref.watch(syncCredentialStoreProvider),
    backupBeforeReplace: () => db.createBackupCopy('before-sync'),
  );
  ref.onDispose(service.dispose);
  return service;
});

final syncInProgressProvider = StreamProvider<bool>(
  (ref) => ref.watch(syncServiceProvider).syncingChanges,
);

final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final scheduler = SyncScheduler(
    ref.watch(syncServiceProvider),
    ref.watch(databaseProvider),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

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

final openSyncConflictsProvider = StreamProvider<List<SyncConflict>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchOpenSyncConflicts();
});
