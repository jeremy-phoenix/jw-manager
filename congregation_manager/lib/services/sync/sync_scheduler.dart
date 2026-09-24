import 'dart:async';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/services/sync/sync_service.dart';

/// Syncs in the background while the app is open: shortly after launch,
/// a little while after local edits, and periodically. Failures are stored
/// in the sync settings and shown on the Online Sync screen.
class SyncScheduler {
  SyncScheduler(
    this._service,
    this._db, {
    this.interval = const Duration(minutes: 5),
    this.afterEdit = const Duration(seconds: 20),
  });

  final SyncService _service;
  final AppDatabase _db;
  final Duration interval;
  final Duration afterEdit;

  Timer? _periodic;
  Timer? _pending;
  StreamSubscription<int>? _pendingCount;

  void start() {
    if (_periodic != null) return;
    _periodic = Timer.periodic(interval, (_) => _trigger());
    _pending = Timer(const Duration(seconds: 5), _trigger);
    _pendingCount = _db.watchPendingSyncOperationCount().listen((count) {
      if (count == 0) return;
      _pending?.cancel();
      _pending = Timer(afterEdit, _trigger);
    });
  }

  void dispose() {
    _periodic?.cancel();
    _pending?.cancel();
    _pendingCount?.cancel();
    _periodic = null;
  }

  Future<void> _trigger() async {
    final settings = await _db.getSyncSettings();
    if (!settings.isEnabled || settings.needsKey || _service.isSyncing) return;
    try {
      await _service.syncNow();
    } on Object {
      // Recorded as lastError by SyncService.
    }
  }
}
