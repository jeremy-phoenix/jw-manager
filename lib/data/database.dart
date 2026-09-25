import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:congregation_manager/data/tables.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/data/statistics.dart';
import 'package:congregation_manager/data/service_year.dart';
import 'package:congregation_manager/data/sync_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

class DatabaseLocationInfo {
  const DatabaseLocationInfo({
    required this.currentPath,
    required this.defaultPath,
    required this.customDirectoryPath,
  });

  final String currentPath;
  final String defaultPath;
  final String? customDirectoryPath;

  bool get isCustom => customDirectoryPath != null;
}

@DriftDatabase(
  tables: [
    Congregations,
    Persons,
    PhoneNumbers,
    EmergencyContacts,
    ServiceReports,
    FieldServiceGroups,
    AuxiliaryPioneerPeriods,
    SyncSettings,
    PendingSyncOperations,
    SyncConflicts,
    DeferredRemoteChanges,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  /// For testing only.
  AppDatabase.forTesting(super.e);

  static const _uuid = Uuid();
  static const databaseFileName = 'congregation_manager.sqlite';
  static const _databaseName = 'congregation_manager';
  static const _customDatabaseDirectoryKey = 'databaseDirectoryPath';
  static const _databaseSidecarSuffixes = ['', '-wal', '-shm', '-journal'];

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(persons, persons.inactiveDate);
      }
      if (from < 3) {
        await _addSyncColumns(m, congregations);
        await _addSyncColumns(m, persons);
        await _addSyncColumns(m, phoneNumbers);
        await _addSyncColumns(m, emergencyContacts);
        await _addSyncColumns(m, serviceReports);
        await _addSyncColumns(m, fieldServiceGroups);
        await _addSyncColumns(m, auxiliaryPioneerPeriods);
        await m.createTable(syncSettings);
        await m.createTable(pendingSyncOperations);
        await m.createTable(syncConflicts);
      }
      if (from < 5) {
        await _addColumnIfMissing(
          m,
          congregations,
          congregations.circuitOverseerName,
        );
        await _addColumnIfMissing(
          m,
          congregations,
          congregations.circuitOverseerSpouseName,
        );
        await _addColumnIfMissing(
          m,
          congregations,
          congregations.circuitOverseerPhone,
        );
        await _addColumnIfMissing(
          m,
          congregations,
          congregations.circuitOverseerEmail,
        );
        await _addColumnIfMissing(
          m,
          congregations,
          congregations.circuitOverseerAddress,
        );
        await _addColumnIfMissing(m, persons, persons.email);
      }
      if (from < 6) {
        await _addColumnIfMissing(m, persons, persons.recordStatus);
        await _addColumnIfMissing(m, persons, persons.archiveReason);
        await _addColumnIfMissing(m, persons, persons.archivedAt);
        await _addColumnIfMissing(m, persons, persons.trashedAt);
      }
      if (from < 8) {
        await _migrateToEncryptedSync(m);
      }
    },
  );

  /// v8 replaces plaintext sync (shared token stored in this database, a
  /// server that parsed every field) with end-to-end encrypted sync. The old
  /// token, queue, conflicts and server versions are all discarded; only the
  /// server address is kept as a hint. Each step is safe to re-run.
  Future<void> _migrateToEncryptedSync(Migrator m) async {
    final columns = await _columnNames(syncSettings.actualTableName);
    if (!columns.contains('vault_id')) {
      String? serverUrl;
      if (columns.contains('server_url')) {
        final row = await customSelect(
          'SELECT server_url FROM sync_settings WHERE id = 1',
        ).getSingleOrNull();
        serverUrl = row?.readNullable<String>('server_url');
      }
      await customStatement('DROP TABLE IF EXISTS sync_settings');
      await m.createTable(syncSettings);
      await into(
        syncSettings,
      ).insert(SyncSettingsCompanion.insert(serverUrl: Value(serverUrl)));
    }
    if ((await _columnNames(deferredRemoteChanges.actualTableName)).isEmpty) {
      await m.createTable(deferredRemoteChanges);
    }
    await customStatement(
      'CREATE INDEX IF NOT EXISTS pending_sync_operations_entity_sync_id '
      'ON pending_sync_operations (entity_sync_id)',
    );
    await customStatement('DELETE FROM pending_sync_operations');
    await customStatement('DELETE FROM sync_conflicts');
    for (final table in <TableInfo>[
      congregations,
      fieldServiceGroups,
      persons,
      phoneNumbers,
      emergencyContacts,
      serviceReports,
      auxiliaryPioneerPeriods,
    ]) {
      // The server stores record ids as lowercase UUIDs.
      await customStatement(
        'UPDATE ${table.actualTableName} '
        'SET server_version = 0, last_synced_at = NULL, sync_id = lower(sync_id)',
      );
    }
  }

  Future<Set<String>> _columnNames(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return {for (final row in rows) row.read<String>('name')};
  }

  /// Adds [column] unless the table already has it. Drift runs migrations
  /// without a transaction, so an interrupted upgrade can leave columns
  /// half-applied with the old user_version; plain addColumn would then fail
  /// with "duplicate column" on every subsequent open.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final existing = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    final present = existing.any(
      (row) => row.read<String>('name') == column.name,
    );
    if (!present) {
      await m.addColumn(table, column);
    }
  }

  Future<void> _addSyncColumns(Migrator m, TableInfo table) async {
    await _addColumnIfMissing(
      m,
      table,
      table.$columns.firstWhere((c) => c.name == 'sync_id'),
    );
    await _addColumnIfMissing(
      m,
      table,
      table.$columns.firstWhere((c) => c.name == 'server_version'),
    );
    await _addColumnIfMissing(
      m,
      table,
      table.$columns.firstWhere((c) => c.name == 'deleted_at'),
    );
    await _addColumnIfMissing(
      m,
      table,
      table.$columns.firstWhere((c) => c.name == 'last_synced_at'),
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: _databaseName,
      native: DriftNativeOptions(databasePath: databasePath),
    );
  }

  static Future<String> databasePath() async {
    final customDirectoryPath = await _customDatabaseDirectoryPath();
    if (customDirectoryPath != null) {
      final customPath = databasePathInDirectory(customDirectoryPath);
      await _ensureParentDirectory(customPath);
      return customPath;
    }

    final defaultPath = await defaultDatabasePath();
    await _copyLegacyDatabaseIfNeeded(defaultPath);
    return defaultPath;
  }

  static Future<String> defaultDatabasePath() async {
    final directory = await getApplicationSupportDirectory();
    final path = databasePathInDirectory(directory.path);
    await _ensureParentDirectory(path);
    return path;
  }

  static String databasePathInDirectory(String directoryPath) {
    final normalizedDirectory = _trimTrailingSeparators(directoryPath);
    return '$normalizedDirectory${Platform.pathSeparator}$databaseFileName';
  }

  static Future<DatabaseLocationInfo> getDatabaseLocationInfo() async {
    return DatabaseLocationInfo(
      currentPath: await databasePath(),
      defaultPath: await defaultDatabasePath(),
      customDirectoryPath: await _customDatabaseDirectoryPath(),
    );
  }

  static Future<String> changeDatabaseDirectory({
    required AppDatabase openDatabase,
    required String directoryPath,
    required bool overwrite,
  }) async {
    final targetPath = databasePathInDirectory(directoryPath);
    final currentPath = await databasePath();
    if (!_samePath(currentPath, targetPath)) {
      await openDatabase.copyDatabaseToPath(targetPath, overwrite: overwrite);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customDatabaseDirectoryKey,
      _trimTrailingSeparators(directoryPath),
    );
    return targetPath;
  }

  static Future<String> resetDatabaseDirectory({
    required AppDatabase openDatabase,
    required bool overwrite,
  }) async {
    final targetPath = await defaultDatabasePath();
    final currentPath = await databasePath();
    if (!_samePath(currentPath, targetPath)) {
      await openDatabase.copyDatabaseToPath(targetPath, overwrite: overwrite);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customDatabaseDirectoryKey);
    return targetPath;
  }

  Future<void> copyDatabaseToPath(
    String targetPath, {
    required bool overwrite,
  }) async {
    await _ensureParentDirectory(targetPath);

    final target = File(targetPath);
    if (await target.exists()) {
      if (!overwrite) {
        throw FileSystemException('Database file already exists.', targetPath);
      }
      await target.delete();
    }

    for (final suffix in _databaseSidecarSuffixes.skip(1)) {
      final sidecar = File('$targetPath$suffix');
      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }

    try {
      await customStatement('VACUUM INTO ${_sqliteStringLiteral(targetPath)}');
    } catch (_) {
      if (await target.exists()) {
        await target.delete();
      }
      rethrow;
    }
  }

  static Future<String?> _customDatabaseDirectoryPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_customDatabaseDirectoryKey)?.trim();
    if (path == null || path.isEmpty) return null;
    return _trimTrailingSeparators(path);
  }

  static Future<void> _copyLegacyDatabaseIfNeeded(String targetPath) async {
    final target = File(targetPath);
    if (await target.exists()) return;

    final legacyDirectory = await getApplicationDocumentsDirectory();
    final legacyPath = databasePathInDirectory(legacyDirectory.path);
    if (_samePath(legacyPath, targetPath)) return;

    final legacyDatabase = File(legacyPath);
    if (!await legacyDatabase.exists()) return;

    await _copyDatabaseFiles(legacyPath, targetPath, overwrite: false);
  }

  static Future<void> _copyDatabaseFiles(
    String sourcePath,
    String targetPath, {
    required bool overwrite,
  }) async {
    await _ensureParentDirectory(targetPath);

    for (final suffix in _databaseSidecarSuffixes) {
      final source = File('$sourcePath$suffix');
      if (!await source.exists()) continue;

      final target = File('$targetPath$suffix');
      if (await target.exists()) {
        if (!overwrite) continue;
        await target.delete();
      }
      await source.copy(target.path);
    }
  }

  static Future<void> _ensureParentDirectory(String filePath) async {
    await Directory(_parentDirectoryPath(filePath)).create(recursive: true);
  }

  static String _parentDirectoryPath(String filePath) {
    final separatorIndex = filePath.lastIndexOf(RegExp(r'[\\/]'));
    if (separatorIndex == -1) return Directory.current.path;
    return filePath.substring(0, separatorIndex);
  }

  static String _trimTrailingSeparators(String path) {
    var normalizedPath = path.trim();
    while (normalizedPath.length > 1 &&
        (normalizedPath.endsWith('/') || normalizedPath.endsWith('\\'))) {
      normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
    }
    return normalizedPath;
  }

  static bool _samePath(String left, String right) {
    var normalizedLeft = _trimTrailingSeparators(left).replaceAll('/', '\\');
    var normalizedRight = _trimTrailingSeparators(right).replaceAll('/', '\\');
    if (Platform.isWindows) {
      normalizedLeft = normalizedLeft.toLowerCase();
      normalizedRight = normalizedRight.toLowerCase();
    }
    return normalizedLeft == normalizedRight;
  }

  static String _sqliteStringLiteral(String value) {
    return "'${value.replaceAll("'", "''")}'";
  }

  // ──────────────────────────────────────────────────
  // Online sync: settings and enrollment
  // ──────────────────────────────────────────────────

  static const _upsertOrder = [
    SyncEntityTypes.congregation,
    SyncEntityTypes.fieldServiceGroup,
    SyncEntityTypes.person,
    SyncEntityTypes.phoneNumber,
    SyncEntityTypes.emergencyContact,
    SyncEntityTypes.serviceReport,
    SyncEntityTypes.auxiliaryPioneerPeriod,
  ];

  static const _deleteOrder = [
    SyncEntityTypes.phoneNumber,
    SyncEntityTypes.emergencyContact,
    SyncEntityTypes.serviceReport,
    SyncEntityTypes.auxiliaryPioneerPeriod,
    SyncEntityTypes.person,
    SyncEntityTypes.fieldServiceGroup,
    SyncEntityTypes.congregation,
  ];

  Future<SyncSetting> getSyncSettings() => _ensureSyncSettings();

  Stream<SyncSetting> watchSyncSettings() async* {
    await _ensureSyncSettings();
    yield* (select(syncSettings)..where((s) => s.id.equals(1))).watchSingle();
  }

  /// Enrolls this database in a vault. Leftover sync bookkeeping is discarded
  /// and every record starts again from server version 0. For a brand-new
  /// vault, [uploadLocalData] queues every local record for upload.
  Future<void> activateSyncVault({
    required String serverUrl,
    required String vaultId,
    required String deviceId,
    required String deviceLabel,
    required int keyId,
    required bool uploadLocalData,
    bool needsKey = false,
  }) => transaction(() async {
    await _clearSyncBookkeeping();
    await _resetSyncVersions();
    await _updateSyncSettings(
      SyncSettingsCompanion(
        isEnabled: const Value(true),
        serverUrl: Value(serverUrl),
        vaultId: Value(vaultId),
        deviceId: Value(deviceId),
        deviceLabel: Value(deviceLabel),
        currentKeyId: Value(keyId),
        needsKey: Value(needsKey),
        pullSeq: const Value(0),
        lastSyncAt: const Value(null),
        lastError: const Value(null),
      ),
    );
    if (uploadLocalData) await queueLocalSnapshotForSync();
  });

  /// Leaves the vault. Local data stays; the server address is remembered.
  Future<void> deactivateSyncVault() => transaction(() async {
    await _clearSyncBookkeeping();
    await _resetSyncVersions();
    await _updateSyncSettings(
      const SyncSettingsCompanion(
        isEnabled: Value(false),
        vaultId: Value(null),
        deviceId: Value(null),
        deviceLabel: Value(null),
        currentKeyId: Value(null),
        needsKey: Value(false),
        pullSeq: Value(0),
        lastSyncAt: Value(null),
        lastError: Value(null),
      ),
    );
  });

  Future<void> updateSyncServerUrl(String serverUrl) =>
      _updateSyncSettings(SyncSettingsCompanion(serverUrl: Value(serverUrl)));

  Future<void> updateSyncDeviceLabel(String label) =>
      _updateSyncSettings(SyncSettingsCompanion(deviceLabel: Value(label)));

  Future<void> setSyncKeyState({
    required int currentKeyId,
    required bool needsKey,
  }) => _updateSyncSettings(
    SyncSettingsCompanion(
      currentKeyId: Value(currentKeyId),
      needsKey: Value(needsKey),
    ),
  );

  Future<void> setSyncNeedsKey(bool needsKey) =>
      _updateSyncSettings(SyncSettingsCompanion(needsKey: Value(needsKey)));

  Future<void> recordSyncSuccess() => _updateSyncSettings(
    SyncSettingsCompanion(
      lastSyncAt: Value(DateTime.now().toUtc()),
      lastError: const Value(null),
    ),
  );

  Future<void> recordSyncError(String error) =>
      _updateSyncSettings(SyncSettingsCompanion(lastError: Value(error)));

  /// Whether this device holds any congregation records.
  Future<bool> hasLocalCongregationData() async {
    final congregation = await (select(
      congregations,
    )..limit(1)).getSingleOrNull();
    if (congregation != null) return true;
    final person = await (select(persons)..limit(1)).getSingleOrNull();
    return person != null;
  }

  /// Removes every congregation record from this device, without queueing
  /// anything, so a vault being joined can replace it.
  Future<void> clearLocalDataForSyncJoin() => transaction(() async {
    await delete(auxiliaryPioneerPeriods).go();
    await delete(emergencyContacts).go();
    await delete(phoneNumbers).go();
    await delete(serviceReports).go();
    await delete(persons).go();
    await delete(fieldServiceGroups).go();
    await delete(congregations).go();
    await _clearSyncBookkeeping();
  });

  Future<SyncSetting> _ensureSyncSettings() async {
    final existing = await (select(
      syncSettings,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;
    await into(syncSettings).insert(
      const SyncSettingsCompanion(id: Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    return (select(syncSettings)..where((s) => s.id.equals(1))).getSingle();
  }

  Future<void> _updateSyncSettings(SyncSettingsCompanion fields) async {
    await _ensureSyncSettings();
    await (update(syncSettings)..where((s) => s.id.equals(1))).write(fields);
  }

  Future<void> _clearSyncBookkeeping() async {
    await delete(pendingSyncOperations).go();
    await delete(deferredRemoteChanges).go();
    await delete(syncConflicts).go();
  }

  /// Forgets server versions, e.g. when switching to a different vault.
  Future<void> _resetSyncVersions() async {
    await update(congregations).write(
      const CongregationsCompanion(
        serverVersion: Value(0),
        lastSyncedAt: Value(null),
      ),
    );
    await update(fieldServiceGroups).write(
      const FieldServiceGroupsCompanion(
        serverVersion: Value(0),
        lastSyncedAt: Value(null),
      ),
    );
    await update(persons).write(
      const PersonsCompanion(
        serverVersion: Value(0),
        lastSyncedAt: Value(null),
      ),
    );
    await update(phoneNumbers).write(
      const PhoneNumbersCompanion(
        serverVersion: Value(0),
        lastSyncedAt: Value(null),
      ),
    );
    await update(emergencyContacts).write(
      const EmergencyContactsCompanion(
        serverVersion: Value(0),
        lastSyncedAt: Value(null),
      ),
    );
    await update(serviceReports).write(
      const ServiceReportsCompanion(
        serverVersion: Value(0),
        lastSyncedAt: Value(null),
      ),
    );
    await update(auxiliaryPioneerPeriods).write(
      const AuxiliaryPioneerPeriodsCompanion(
        serverVersion: Value(0),
        lastSyncedAt: Value(null),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Online sync: outgoing changes
  // ──────────────────────────────────────────────────

  /// Queues local records for upload, parents before children. With
  /// [onlyUnsynced], only records the server has never seen are queued.
  Future<void> queueLocalSnapshotForSync({bool onlyUnsynced = false}) =>
      transaction(() async {
        await _ensureAllLocalSyncIds();
        bool include(int serverVersion) => !onlyUnsynced || serverVersion == 0;

        for (final row in await select(congregations).get()) {
          if (!include(row.serverVersion)) continue;
          await _queueOperationIfEnabled(
            entityType: SyncEntityTypes.congregation,
            entitySyncId: row.syncId!,
            operationType: 'upsert',
            payload: _congregationPayload(row),
            baseServerVersion: row.serverVersion,
          );
        }
        for (final row in await select(fieldServiceGroups).get()) {
          if (!include(row.serverVersion)) continue;
          await _queueOperationIfEnabled(
            entityType: SyncEntityTypes.fieldServiceGroup,
            entitySyncId: row.syncId!,
            operationType: 'upsert',
            payload: await _fieldServiceGroupPayload(row),
            baseServerVersion: row.serverVersion,
          );
        }
        for (final row in await select(persons).get()) {
          if (!include(row.serverVersion)) continue;
          await _queueOperationIfEnabled(
            entityType: SyncEntityTypes.person,
            entitySyncId: row.syncId!,
            operationType: 'upsert',
            payload: await _personPayload(row),
            baseServerVersion: row.serverVersion,
          );
        }
        for (final row in await select(phoneNumbers).get()) {
          if (!include(row.serverVersion)) continue;
          await _queueOperationIfEnabled(
            entityType: SyncEntityTypes.phoneNumber,
            entitySyncId: row.syncId!,
            operationType: 'upsert',
            payload: await _phoneNumberPayload(row),
            baseServerVersion: row.serverVersion,
          );
        }
        for (final row in await select(emergencyContacts).get()) {
          if (!include(row.serverVersion)) continue;
          await _queueOperationIfEnabled(
            entityType: SyncEntityTypes.emergencyContact,
            entitySyncId: row.syncId!,
            operationType: 'upsert',
            payload: await _emergencyContactPayload(row),
            baseServerVersion: row.serverVersion,
          );
        }
        for (final row in await select(serviceReports).get()) {
          if (!include(row.serverVersion)) continue;
          await _queueOperationIfEnabled(
            entityType: SyncEntityTypes.serviceReport,
            entitySyncId: row.syncId!,
            operationType: 'upsert',
            payload: await _serviceReportPayload(row),
            baseServerVersion: row.serverVersion,
          );
        }
        for (final row in await select(auxiliaryPioneerPeriods).get()) {
          if (!include(row.serverVersion)) continue;
          await _queueOperationIfEnabled(
            entityType: SyncEntityTypes.auxiliaryPioneerPeriod,
            entitySyncId: row.syncId!,
            operationType: 'upsert',
            payload: await _auxiliaryPioneerPeriodPayload(row),
            baseServerVersion: row.serverVersion,
          );
        }
      });

  Future<int> getPendingSyncOperationCount() async {
    final count = pendingSyncOperations.id.count();
    final row = await (selectOnly(
      pendingSyncOperations,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchPendingSyncOperationCount() {
    final count = pendingSyncOperations.id.count();
    return (selectOnly(
      pendingSyncOperations,
    )..addColumns([count])).map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<List<PendingSyncOperation>> getPendingSyncOperations({
    int limit = 50,
  }) =>
      (select(pendingSyncOperations)
            ..orderBy([(o) => OrderingTerm.asc(o.id)])
            ..limit(limit))
          .get();

  Future<void> markSyncOperationFailed(int id, String error) async {
    final operation = await (select(
      pendingSyncOperations,
    )..where((o) => o.id.equals(id))).getSingleOrNull();
    if (operation == null) return;

    await (update(pendingSyncOperations)..where((o) => o.id.equals(id))).write(
      PendingSyncOperationsCompanion(
        attemptCount: Value(operation.attemptCount + 1),
        lastAttemptAt: Value(DateTime.now().toUtc()),
        lastError: Value(error),
      ),
    );
  }

  /// Records that the server accepted [sent] as [version].
  Future<void> completePushedOperation(
    PendingSyncOperation sent,
    int version,
  ) => transaction(() async {
    if (version > 0) {
      await markEntitySynced(
        entityType: sent.entityType,
        entitySyncId: sent.entitySyncId,
        serverVersion: version,
      );
    }
    final current = await (select(
      pendingSyncOperations,
    )..where((o) => o.id.equals(sent.id))).getSingleOrNull();
    if (current == null) return;
    if (current.operationId == sent.operationId) {
      await (delete(
        pendingSyncOperations,
      )..where((o) => o.id.equals(sent.id))).go();
    } else {
      // Edited again while the push was in flight: that newer change now
      // builds on the version the server just accepted.
      await (update(
        pendingSyncOperations,
      )..where((o) => o.id.equals(sent.id))).write(
        PendingSyncOperationsCompanion(baseServerVersion: Value(version)),
      );
    }
  });

  /// Handles a push the server rejected because the record changed there
  /// first. The server copy wins locally; the local copy is kept as a
  /// conflict that can be restored. A null [server] means the server has no
  /// copy at all, so the record is sent again as new.
  Future<void> resolvePushConflict(
    PendingSyncOperation sent, {
    RemoteChange? server,
  }) => transaction(() async {
    final current = await (select(
      pendingSyncOperations,
    )..where((o) => o.id.equals(sent.id))).getSingleOrNull();

    if (server == null) {
      await markEntitySynced(
        entityType: sent.entityType,
        entitySyncId: sent.entitySyncId,
        serverVersion: 0,
      );
      if (current != null) {
        await (update(
          pendingSyncOperations,
        )..where((o) => o.id.equals(sent.id))).write(
          const PendingSyncOperationsCompanion(baseServerVersion: Value(0)),
        );
      }
      return;
    }

    final local = current ?? sent;
    await into(syncConflicts).insert(
      SyncConflictsCompanion.insert(
        entityType: local.entityType,
        entitySyncId: local.entitySyncId,
        localPayloadJson: jsonEncode({
          'operationType': local.operationType,
          'payload': jsonDecode(local.payloadJson),
        }),
        serverPayloadJson: jsonEncode({
          'deleted': server.deleted,
          'payload': server.payload,
        }),
        serverVersion: server.version,
      ),
    );
    if (current != null) {
      await (delete(
        pendingSyncOperations,
      )..where((o) => o.id.equals(sent.id))).go();
    }
    await _applyRemoteBatch(
      [server],
      retryDeferred: false,
      respectPending: false,
    );
  });

  Future<void> markEntitySynced({
    required String entityType,
    required String entitySyncId,
    required int serverVersion,
  }) async {
    final syncedAt = Value(DateTime.now().toUtc());
    switch (entityType) {
      case SyncEntityTypes.congregation:
        await (update(
          congregations,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          CongregationsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: syncedAt,
          ),
        );
      case SyncEntityTypes.fieldServiceGroup:
        await (update(
          fieldServiceGroups,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          FieldServiceGroupsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: syncedAt,
          ),
        );
      case SyncEntityTypes.person:
        await (update(
          persons,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          PersonsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: syncedAt,
          ),
        );
      case SyncEntityTypes.phoneNumber:
        await (update(
          phoneNumbers,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          PhoneNumbersCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: syncedAt,
          ),
        );
      case SyncEntityTypes.emergencyContact:
        await (update(
          emergencyContacts,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          EmergencyContactsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: syncedAt,
          ),
        );
      case SyncEntityTypes.serviceReport:
        await (update(
          serviceReports,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          ServiceReportsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: syncedAt,
          ),
        );
      case SyncEntityTypes.auxiliaryPioneerPeriod:
        await (update(
          auxiliaryPioneerPeriods,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          AuxiliaryPioneerPeriodsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: syncedAt,
          ),
        );
    }
  }

  // ──────────────────────────────────────────────────
  // Online sync: conflicts
  // ──────────────────────────────────────────────────

  Future<int> getOpenSyncConflictCount() async {
    final count = syncConflicts.id.count();
    final row =
        await (selectOnly(syncConflicts)
              ..addColumns([count])
              ..where(syncConflicts.resolvedAt.isNull()))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchOpenSyncConflictCount() {
    final count = syncConflicts.id.count();
    return (selectOnly(syncConflicts)
          ..addColumns([count])
          ..where(syncConflicts.resolvedAt.isNull()))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  Stream<List<SyncConflict>> watchOpenSyncConflicts() =>
      (select(syncConflicts)
            ..where((c) => c.resolvedAt.isNull())
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .watch();

  /// Keeps the server version (already applied) and closes the conflict.
  Future<void> dismissSyncConflict(int id) =>
      (update(syncConflicts)..where((c) => c.id.equals(id))).write(
        SyncConflictsCompanion(resolvedAt: Value(DateTime.now().toUtc())),
      );

  /// Puts this device's version back and queues it on top of the server
  /// version, then closes the conflict.
  Future<void> restoreLocalVersionFromConflict(int id) => transaction(() async {
    final conflict = await (select(
      syncConflicts,
    )..where((c) => c.id.equals(id))).getSingle();
    final local = jsonDecode(conflict.localPayloadJson) as Map<String, dynamic>;
    final operationType = local['operationType'] as String? ?? 'upsert';
    final payload =
        (local['payload'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final index = await _SyncIndex.load(this);
    final baseVersion =
        index.find(conflict.entityType, conflict.entitySyncId)?.serverVersion ??
        conflict.serverVersion;
    final change = RemoteChange(
      entityType: conflict.entityType,
      syncId: conflict.entitySyncId,
      version: baseVersion,
      deleted: operationType == 'delete',
      payload: payload,
    );

    if (change.deleted) {
      await _applyDelete(change, index);
    } else {
      final outcome = await _applyUpsert(
        change,
        index,
        DateTime.now().toUtc(),
        force: true,
      );
      if (outcome == _ApplyOutcome.deferred) {
        throw StateError(
          'This record belongs to a publisher that no longer exists.',
        );
      }
    }
    await _queueOperationIfEnabled(
      entityType: conflict.entityType,
      entitySyncId: conflict.entitySyncId,
      operationType: operationType,
      payload: payload,
      baseServerVersion: baseVersion,
    );
    await dismissSyncConflict(id);
  });

  // ──────────────────────────────────────────────────
  // Online sync: incoming changes
  // ──────────────────────────────────────────────────

  /// Applies pulled changes in dependency order within one transaction and,
  /// when given, stores [pullSeq] as the new feed position. Returns the
  /// number of local rows that changed.
  Future<int> applyRemoteChanges(List<RemoteChange> changes, {int? pullSeq}) =>
      transaction(() async {
        final applied = await _applyRemoteBatch(changes, retryDeferred: true);
        if (pullSeq != null) {
          await _updateSyncSettings(
            SyncSettingsCompanion(pullSeq: Value(pullSeq)),
          );
        }
        return applied;
      });

  /// Applies one change; convenient for tests.
  Future<void> applyRemoteChange({
    required String entityType,
    required String operationType,
    required String entitySyncId,
    required int serverVersion,
    required Map<String, dynamic> payload,
  }) => applyRemoteChanges([
    RemoteChange(
      entityType: entityType,
      syncId: entitySyncId,
      version: serverVersion,
      deleted: operationType == 'delete',
      payload: payload,
    ),
  ]);

  Future<int> _applyRemoteBatch(
    List<RemoteChange> incoming, {
    required bool retryDeferred,
    bool respectPending = true,
  }) async {
    final changes = <String, RemoteChange>{};
    if (retryDeferred) {
      for (final row in await select(deferredRemoteChanges).get()) {
        changes[row.entitySyncId] = RemoteChange(
          entityType: row.entityType,
          syncId: row.entitySyncId,
          version: row.serverVersion,
          payload: jsonDecode(row.payloadJson) as Map<String, dynamic>,
        );
      }
    }
    for (final change in incoming) {
      final existing = changes[change.syncId];
      if (existing == null || change.version >= existing.version) {
        changes[change.syncId] = change;
      }
    }
    if (changes.isEmpty) return 0;
    final processed = changes.keys.toList();

    // Unpushed local edits win for now. The push that follows is
    // version-checked, so a real clash becomes a recorded conflict.
    if (respectPending) {
      final pendingIds =
          await (selectOnly(pendingSyncOperations)
                ..addColumns([pendingSyncOperations.entitySyncId]))
              .map((row) => row.read(pendingSyncOperations.entitySyncId)!)
              .get();
      for (final syncId in pendingIds) {
        changes.remove(syncId);
      }
    }

    final index = await _SyncIndex.load(this);
    final syncedAt = DateTime.now().toUtc();
    final deferred = <RemoteChange>[];
    final appliedGroups = <RemoteChange>[];
    var applied = 0;

    final upserts = changes.values.where((c) => !c.deleted).toList();
    for (final type in _upsertOrder) {
      for (final change in upserts.where((c) => c.entityType == type)) {
        switch (await _applyUpsert(change, index, syncedAt)) {
          case _ApplyOutcome.applied:
            applied++;
            if (type == SyncEntityTypes.fieldServiceGroup) {
              appliedGroups.add(change);
            }
          case _ApplyOutcome.unchanged:
            break;
          case _ApplyOutcome.deferred:
            deferred.add(change);
        }
      }
    }
    // A group can arrive before the publishers who lead it.
    for (final group in appliedGroups) {
      await _linkGroupLeaders(group, index);
    }

    final deletes = changes.values.where((c) => c.deleted).toList();
    for (final type in _deleteOrder) {
      for (final change in deletes.where((c) => c.entityType == type)) {
        if (await _applyDelete(change, index)) applied++;
      }
    }

    for (var start = 0; start < processed.length; start += 500) {
      final chunk = processed.sublist(
        start,
        min(start + 500, processed.length),
      );
      await (delete(
        deferredRemoteChanges,
      )..where((d) => d.entitySyncId.isIn(chunk))).go();
    }
    for (final change in deferred) {
      await into(deferredRemoteChanges).insert(
        DeferredRemoteChangesCompanion.insert(
          entityType: change.entityType,
          entitySyncId: change.syncId,
          serverVersion: change.version,
          payloadJson: jsonEncode(change.payload),
        ),
      );
    }
    return applied;
  }

  Future<_ApplyOutcome> _applyUpsert(
    RemoteChange change,
    _SyncIndex index,
    DateTime syncedAt, {
    bool force = false,
  }) async {
    final local = index.find(change.entityType, change.syncId);
    // Our own pushes come back in the feed; skip versions we already have.
    if (!force && local != null && change.version <= local.serverVersion) {
      return _ApplyOutcome.unchanged;
    }
    final p = change.payload;
    final syncId = Value(change.syncId);
    final version = Value(change.version);
    final lastSyncedAt = Value<DateTime?>(syncedAt);
    DateTime timestamp(String key) => _date(p[key]) ?? syncedAt;

    switch (change.entityType) {
      case SyncEntityTypes.congregation:
        final companion = CongregationsCompanion(
          syncId: syncId,
          serverVersion: version,
          lastSyncedAt: lastSyncedAt,
          deletedAt: const Value(null),
          name: Value(_string(p['name']) ?? ''),
          number: Value(_string(p['number']) ?? ''),
          city: Value(_string(p['city']) ?? ''),
          circuitNumber: Value(_string(p['circuitNumber']) ?? ''),
          circuitOverseerName: Value(_string(p['circuitOverseerName']) ?? ''),
          circuitOverseerSpouseName: Value(
            _string(p['circuitOverseerSpouseName']) ?? '',
          ),
          circuitOverseerPhone: Value(_string(p['circuitOverseerPhone']) ?? ''),
          circuitOverseerEmail: Value(_string(p['circuitOverseerEmail']) ?? ''),
          circuitOverseerAddress: Value(
            _string(p['circuitOverseerAddress']) ?? '',
          ),
          createdAt: Value(timestamp('createdAt')),
          updatedAt: Value(timestamp('updatedAt')),
        );
        final id = local == null
            ? await into(congregations).insert(companion)
            : await (update(congregations)..where((t) => t.id.equals(local.id)))
                  .write(companion)
                  .then((_) => local.id);
        index.put(change.entityType, change.syncId, id, change.version);

      case SyncEntityTypes.fieldServiceGroup:
        final companion = FieldServiceGroupsCompanion(
          syncId: syncId,
          serverVersion: version,
          lastSyncedAt: lastSyncedAt,
          deletedAt: const Value(null),
          name: Value(_string(p['name']) ?? ''),
          description: Value(_string(p['description']) ?? ''),
          congregationId: Value(
            index.idOf(
              SyncEntityTypes.congregation,
              _string(p['congregationSyncId']),
            ),
          ),
          groupOverseerId: Value(
            index.idOf(
              SyncEntityTypes.person,
              _string(p['groupOverseerSyncId']),
            ),
          ),
          assistantId: Value(
            index.idOf(SyncEntityTypes.person, _string(p['assistantSyncId'])),
          ),
          createdAt: Value(timestamp('createdAt')),
          updatedAt: Value(timestamp('updatedAt')),
        );
        final id = local == null
            ? await into(fieldServiceGroups).insert(companion)
            : await (update(fieldServiceGroups)
                    ..where((t) => t.id.equals(local.id)))
                  .write(companion)
                  .then((_) => local.id);
        index.put(change.entityType, change.syncId, id, change.version);

      case SyncEntityTypes.person:
        final companion = PersonsCompanion(
          syncId: syncId,
          serverVersion: version,
          lastSyncedAt: lastSyncedAt,
          deletedAt: const Value(null),
          firstName: Value(_string(p['firstName']) ?? ''),
          lastName: Value(_string(p['lastName']) ?? ''),
          otherNames: Value(_string(p['otherNames']) ?? ''),
          birthDate: Value(_date(p['birthDate'])),
          baptismDate: Value(_date(p['baptismDate'])),
          gender: Value(_enumAt(Gender.values, p['gender'], Gender.unknown)),
          hopeClass: Value(
            _enumAt(HopeClass.values, p['hopeClass'], HopeClass.unknown),
          ),
          congregationRole: Value(
            _enumAt(
              CongregationRole.values,
              p['congregationRole'],
              CongregationRole.none,
            ),
          ),
          pioneerType: Value(
            _enumAt(PioneerType.values, p['pioneerType'], PioneerType.none),
          ),
          address: Value(_string(p['address']) ?? ''),
          email: Value(_string(p['email']) ?? ''),
          isActive: Value(_bool(p['isActive']) ?? true),
          inactiveDate: Value(_date(p['inactiveDate'])),
          recordStatus: Value(
            _enumAt(
              PersonRecordStatus.values,
              p['recordStatus'],
              PersonRecordStatus.current,
            ),
          ),
          archiveReason: Value(
            p['archiveReason'] == null
                ? null
                : _enumAt(
                    PersonArchiveReason.values,
                    p['archiveReason'],
                    PersonArchiveReason.other,
                  ),
          ),
          archivedAt: Value(_date(p['archivedAt'])),
          trashedAt: Value(_date(p['trashedAt'])),
          congregationId: Value(
            index.idOf(
              SyncEntityTypes.congregation,
              _string(p['congregationSyncId']),
            ),
          ),
          fieldServiceGroupId: Value(
            index.idOf(
              SyncEntityTypes.fieldServiceGroup,
              _string(p['fieldServiceGroupSyncId']),
            ),
          ),
          createdAt: Value(timestamp('createdAt')),
          updatedAt: Value(timestamp('updatedAt')),
        );
        final id = local == null
            ? await into(persons).insert(companion)
            : await (update(persons)..where((t) => t.id.equals(local.id)))
                  .write(companion)
                  .then((_) => local.id);
        index.put(change.entityType, change.syncId, id, change.version);

      case SyncEntityTypes.phoneNumber:
        final personId = index.idOf(
          SyncEntityTypes.person,
          _string(p['personSyncId']),
        );
        if (personId == null) return _ApplyOutcome.deferred;
        final companion = PhoneNumbersCompanion(
          syncId: syncId,
          serverVersion: version,
          lastSyncedAt: lastSyncedAt,
          deletedAt: const Value(null),
          number: Value(_string(p['number']) ?? ''),
          phoneType: Value(
            _enumAt(PhoneType.values, p['phoneType'], PhoneType.mobile),
          ),
          isPrimary: Value(_bool(p['isPrimary']) ?? false),
          personId: Value(personId),
        );
        final id = local == null
            ? await into(phoneNumbers).insert(companion)
            : await (update(phoneNumbers)..where((t) => t.id.equals(local.id)))
                  .write(companion)
                  .then((_) => local.id);
        index.put(change.entityType, change.syncId, id, change.version);

      case SyncEntityTypes.emergencyContact:
        final personId = index.idOf(
          SyncEntityTypes.person,
          _string(p['personSyncId']),
        );
        if (personId == null) return _ApplyOutcome.deferred;
        final companion = EmergencyContactsCompanion(
          syncId: syncId,
          serverVersion: version,
          lastSyncedAt: lastSyncedAt,
          deletedAt: const Value(null),
          name: Value(_string(p['name']) ?? ''),
          phoneNumber: Value(_string(p['phoneNumber']) ?? ''),
          relationship: Value(
            _enumAt(Relationship.values, p['relationship'], Relationship.other),
          ),
          isPrimary: Value(_bool(p['isPrimary']) ?? false),
          personId: Value(personId),
        );
        final id = local == null
            ? await into(emergencyContacts).insert(companion)
            : await (update(emergencyContacts)
                    ..where((t) => t.id.equals(local.id)))
                  .write(companion)
                  .then((_) => local.id);
        index.put(change.entityType, change.syncId, id, change.version);

      case SyncEntityTypes.serviceReport:
        final personId = index.idOf(
          SyncEntityTypes.person,
          _string(p['personSyncId']),
        );
        if (personId == null) return _ApplyOutcome.deferred;
        final now = DateTime.now();
        final companion = ServiceReportsCompanion(
          syncId: syncId,
          serverVersion: version,
          lastSyncedAt: lastSyncedAt,
          deletedAt: const Value(null),
          year: Value(_int(p['year']) ?? now.year),
          month: Value(_int(p['month']) ?? now.month),
          isAuxiliaryPioneer: Value(_bool(p['isAuxiliaryPioneer']) ?? false),
          isActive: Value(_bool(p['isActive']) ?? true),
          sharedInMinistry: Value(_bool(p['sharedInMinistry']) ?? false),
          bibleStudies: Value(_int(p['bibleStudies']) ?? 0),
          hours: Value(_double(p['hours']) ?? 0),
          note: Value(_string(p['note']) ?? ''),
          personId: Value(personId),
        );
        final id = local == null
            ? await into(serviceReports).insert(companion)
            : await (update(serviceReports)
                    ..where((t) => t.id.equals(local.id)))
                  .write(companion)
                  .then((_) => local.id);
        index.put(change.entityType, change.syncId, id, change.version);

      case SyncEntityTypes.auxiliaryPioneerPeriod:
        final personId = index.idOf(
          SyncEntityTypes.person,
          _string(p['personSyncId']),
        );
        if (personId == null) return _ApplyOutcome.deferred;
        final now = DateTime.now();
        final companion = AuxiliaryPioneerPeriodsCompanion(
          syncId: syncId,
          serverVersion: version,
          lastSyncedAt: lastSyncedAt,
          deletedAt: const Value(null),
          startMonth: Value(_int(p['startMonth']) ?? 1),
          startYear: Value(_int(p['startYear']) ?? now.year),
          endMonth: Value(_int(p['endMonth'])),
          endYear: Value(_int(p['endYear'])),
          personId: Value(personId),
        );
        final id = local == null
            ? await into(auxiliaryPioneerPeriods).insert(companion)
            : await (update(auxiliaryPioneerPeriods)
                    ..where((t) => t.id.equals(local.id)))
                  .write(companion)
                  .then((_) => local.id);
        index.put(change.entityType, change.syncId, id, change.version);

      default:
        // Unknown types are filtered out before they get here.
        return _ApplyOutcome.unchanged;
    }
    return _ApplyOutcome.applied;
  }

  Future<void> _linkGroupLeaders(RemoteChange group, _SyncIndex index) async {
    final local = index.find(SyncEntityTypes.fieldServiceGroup, group.syncId);
    if (local == null) return;
    await (update(
      fieldServiceGroups,
    )..where((g) => g.id.equals(local.id))).write(
      FieldServiceGroupsCompanion(
        groupOverseerId: Value(
          index.idOf(
            SyncEntityTypes.person,
            _string(group.payload['groupOverseerSyncId']),
          ),
        ),
        assistantId: Value(
          index.idOf(
            SyncEntityTypes.person,
            _string(group.payload['assistantSyncId']),
          ),
        ),
      ),
    );
  }

  /// Deletes the local row for a remote tombstone. Deleting a publisher also
  /// removes what they own and their group leadership, as it did on the
  /// device that deleted them.
  Future<bool> _applyDelete(RemoteChange change, _SyncIndex index) async {
    final local = index.find(change.entityType, change.syncId);
    if (local == null) return false;
    final id = local.id;
    switch (change.entityType) {
      case SyncEntityTypes.congregation:
        await (delete(congregations)..where((t) => t.id.equals(id))).go();
      case SyncEntityTypes.fieldServiceGroup:
        await (delete(fieldServiceGroups)..where((t) => t.id.equals(id))).go();
      case SyncEntityTypes.person:
        await (delete(phoneNumbers)..where((t) => t.personId.equals(id))).go();
        await (delete(
          emergencyContacts,
        )..where((t) => t.personId.equals(id))).go();
        await (delete(
          serviceReports,
        )..where((t) => t.personId.equals(id))).go();
        await (delete(
          auxiliaryPioneerPeriods,
        )..where((t) => t.personId.equals(id))).go();
        await (update(
          fieldServiceGroups,
        )..where((g) => g.groupOverseerId.equals(id))).write(
          const FieldServiceGroupsCompanion(groupOverseerId: Value(null)),
        );
        await (update(fieldServiceGroups)
              ..where((g) => g.assistantId.equals(id)))
            .write(const FieldServiceGroupsCompanion(assistantId: Value(null)));
        await (delete(persons)..where((t) => t.id.equals(id))).go();
      case SyncEntityTypes.phoneNumber:
        await (delete(phoneNumbers)..where((t) => t.id.equals(id))).go();
      case SyncEntityTypes.emergencyContact:
        await (delete(emergencyContacts)..where((t) => t.id.equals(id))).go();
      case SyncEntityTypes.serviceReport:
        await (delete(serviceReports)..where((t) => t.id.equals(id))).go();
      case SyncEntityTypes.auxiliaryPioneerPeriod:
        await (delete(
          auxiliaryPioneerPeriods,
        )..where((t) => t.id.equals(id))).go();
      default:
        return false;
    }
    index.remove(change.entityType, change.syncId);
    return true;
  }

  static String? _string(Object? value) => value?.toString();

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : null;

  static bool? _bool(Object? value) => value is bool ? value : null;

  static DateTime? _date(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

  static T _enumAt<T>(List<T> values, Object? index, T fallback) {
    final intIndex = _int(index);
    if (intIndex == null || intIndex < 0 || intIndex >= values.length) {
      return fallback;
    }
    return values[intIndex];
  }

  // ──────────────────────────────────────────────────
  // Online sync: local record identities and payloads
  // ──────────────────────────────────────────────────

  Future<void> _ensureAllLocalSyncIds() async {
    for (final row in await select(congregations).get()) {
      if (row.syncId == null || row.syncId!.isEmpty) {
        await (update(congregations)..where((t) => t.id.equals(row.id))).write(
          CongregationsCompanion(syncId: Value(_uuid.v4())),
        );
      }
    }
    for (final row in await select(fieldServiceGroups).get()) {
      if (row.syncId == null || row.syncId!.isEmpty) {
        await (update(fieldServiceGroups)..where((t) => t.id.equals(row.id)))
            .write(FieldServiceGroupsCompanion(syncId: Value(_uuid.v4())));
      }
    }
    for (final row in await select(persons).get()) {
      if (row.syncId == null || row.syncId!.isEmpty) {
        await (update(persons)..where((t) => t.id.equals(row.id))).write(
          PersonsCompanion(syncId: Value(_uuid.v4())),
        );
      }
    }
    for (final row in await select(phoneNumbers).get()) {
      if (row.syncId == null || row.syncId!.isEmpty) {
        await (update(phoneNumbers)..where((t) => t.id.equals(row.id))).write(
          PhoneNumbersCompanion(syncId: Value(_uuid.v4())),
        );
      }
    }
    for (final row in await select(emergencyContacts).get()) {
      if (row.syncId == null || row.syncId!.isEmpty) {
        await (update(emergencyContacts)..where((t) => t.id.equals(row.id)))
            .write(EmergencyContactsCompanion(syncId: Value(_uuid.v4())));
      }
    }
    for (final row in await select(serviceReports).get()) {
      if (row.syncId == null || row.syncId!.isEmpty) {
        await (update(serviceReports)..where((t) => t.id.equals(row.id))).write(
          ServiceReportsCompanion(syncId: Value(_uuid.v4())),
        );
      }
    }
    for (final row in await select(auxiliaryPioneerPeriods).get()) {
      if (row.syncId == null || row.syncId!.isEmpty) {
        await (update(auxiliaryPioneerPeriods)
              ..where((t) => t.id.equals(row.id)))
            .write(AuxiliaryPioneerPeriodsCompanion(syncId: Value(_uuid.v4())));
      }
    }
  }

  /// Queues [payload] for upload while this database is enrolled in a vault.
  ///
  /// Each record has at most one pending operation. A newer edit replaces the
  /// queued payload (payloads always carry the full record) but keeps the
  /// original queue position and base version, so repeated edits between
  /// syncs cannot conflict with each other.
  Future<void> _queueOperationIfEnabled({
    required String entityType,
    required String entitySyncId,
    required String operationType,
    required Map<String, dynamic> payload,
    int? baseServerVersion,
  }) async {
    final settings = await _ensureSyncSettings();
    if (!settings.isEnabled) return;

    final payloadJson = jsonEncode(payload);
    final existing =
        await (select(pendingSyncOperations)
              ..where((o) => o.entitySyncId.equals(entitySyncId))
              ..orderBy([(o) => OrderingTerm.asc(o.id)])
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      await (update(
        pendingSyncOperations,
      )..where((o) => o.id.equals(existing.id))).write(
        PendingSyncOperationsCompanion(
          operationId: Value(_uuid.v4()),
          entityType: Value(entityType),
          operationType: Value(operationType),
          payloadJson: Value(payloadJson),
          attemptCount: const Value(0),
          lastAttemptAt: const Value(null),
          lastError: const Value(null),
        ),
      );
      return;
    }

    await into(pendingSyncOperations).insert(
      PendingSyncOperationsCompanion.insert(
        operationId: _uuid.v4(),
        entityType: entityType,
        entitySyncId: entitySyncId,
        operationType: operationType,
        payloadJson: payloadJson,
        baseServerVersion: Value(baseServerVersion),
      ),
    );
  }

  /// Collects every record the vault already has, children first, so a bulk
  /// replacement can delete them there.
  Future<List<RemoteChange>> _recordsOnServer() async {
    final index = await _SyncIndex.load(this);
    return [
      for (final type in _deleteOrder)
        for (final entry in index.entries(type))
          if (entry.value.serverVersion > 0)
            RemoteChange(
              entityType: type,
              syncId: entry.key,
              version: entry.value.serverVersion,
              deleted: true,
            ),
    ];
  }

  /// After local data was replaced wholesale (JSON import), makes the vault
  /// match: delete what it had, then upload the new records.
  Future<void> _replaceVaultContents(List<RemoteChange> previous) async {
    await delete(pendingSyncOperations).go();
    await delete(deferredRemoteChanges).go();
    for (final record in previous) {
      await into(pendingSyncOperations).insert(
        PendingSyncOperationsCompanion.insert(
          operationId: _uuid.v4(),
          entityType: record.entityType,
          entitySyncId: record.syncId,
          operationType: 'delete',
          payloadJson: jsonEncode({'syncId': record.syncId}),
          baseServerVersion: Value(record.version),
        ),
      );
    }
    await queueLocalSnapshotForSync();
  }

  Future<String> _ensureCongregationSyncId(int id) async {
    final row = await getCongregation(id);
    if (row.syncId?.isNotEmpty == true) return row.syncId!;
    final syncId = _uuid.v4();
    await (update(congregations)..where((t) => t.id.equals(id))).write(
      CongregationsCompanion(syncId: Value(syncId)),
    );
    return syncId;
  }

  Future<String> _ensureFieldServiceGroupSyncId(int id) async {
    final row = await getFieldServiceGroup(id);
    if (row.syncId?.isNotEmpty == true) return row.syncId!;
    final syncId = _uuid.v4();
    await (update(fieldServiceGroups)..where((t) => t.id.equals(id))).write(
      FieldServiceGroupsCompanion(syncId: Value(syncId)),
    );
    return syncId;
  }

  Future<String> _ensurePersonSyncId(int id) async {
    final row = await getPerson(id);
    if (row.syncId?.isNotEmpty == true) return row.syncId!;
    final syncId = _uuid.v4();
    await (update(persons)..where((t) => t.id.equals(id))).write(
      PersonsCompanion(syncId: Value(syncId)),
    );
    return syncId;
  }

  Future<String> _ensurePhoneNumberSyncId(int id) async {
    final row = await (select(
      phoneNumbers,
    )..where((t) => t.id.equals(id))).getSingle();
    if (row.syncId?.isNotEmpty == true) return row.syncId!;
    final syncId = _uuid.v4();
    await (update(phoneNumbers)..where((t) => t.id.equals(id))).write(
      PhoneNumbersCompanion(syncId: Value(syncId)),
    );
    return syncId;
  }

  Future<String> _ensureEmergencyContactSyncId(int id) async {
    final row = await (select(
      emergencyContacts,
    )..where((t) => t.id.equals(id))).getSingle();
    if (row.syncId?.isNotEmpty == true) return row.syncId!;
    final syncId = _uuid.v4();
    await (update(emergencyContacts)..where((t) => t.id.equals(id))).write(
      EmergencyContactsCompanion(syncId: Value(syncId)),
    );
    return syncId;
  }

  Future<String> _ensureServiceReportSyncId(int id) async {
    final row = await (select(
      serviceReports,
    )..where((t) => t.id.equals(id))).getSingle();
    if (row.syncId?.isNotEmpty == true) return row.syncId!;
    final syncId = _uuid.v4();
    await (update(serviceReports)..where((t) => t.id.equals(id))).write(
      ServiceReportsCompanion(syncId: Value(syncId)),
    );
    return syncId;
  }

  Future<String> _ensureAuxiliaryPioneerPeriodSyncId(int id) async {
    final row = await (select(
      auxiliaryPioneerPeriods,
    )..where((t) => t.id.equals(id))).getSingle();
    if (row.syncId?.isNotEmpty == true) return row.syncId!;
    final syncId = _uuid.v4();
    await (update(auxiliaryPioneerPeriods)..where((t) => t.id.equals(id)))
        .write(AuxiliaryPioneerPeriodsCompanion(syncId: Value(syncId)));
    return syncId;
  }

  // Payloads hold the complete record. The server stores them encrypted and
  // never interprets them, so every field survives a round trip.

  Map<String, dynamic> _congregationPayload(Congregation row) => {
    'syncId': row.syncId,
    'name': row.name,
    'number': row.number,
    'city': row.city,
    'circuitNumber': row.circuitNumber,
    'circuitOverseerName': row.circuitOverseerName,
    'circuitOverseerSpouseName': row.circuitOverseerSpouseName,
    'circuitOverseerPhone': row.circuitOverseerPhone,
    'circuitOverseerEmail': row.circuitOverseerEmail,
    'circuitOverseerAddress': row.circuitOverseerAddress,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  };

  Future<Map<String, dynamic>> _fieldServiceGroupPayload(
    FieldServiceGroup row,
  ) async => {
    'syncId': row.syncId,
    'name': row.name,
    'description': row.description,
    'congregationSyncId': row.congregationId == null
        ? null
        : await _ensureCongregationSyncId(row.congregationId!),
    'groupOverseerSyncId': row.groupOverseerId == null
        ? null
        : await _ensurePersonSyncId(row.groupOverseerId!),
    'assistantSyncId': row.assistantId == null
        ? null
        : await _ensurePersonSyncId(row.assistantId!),
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  };

  Future<Map<String, dynamic>> _personPayload(Person row) async => {
    'syncId': row.syncId,
    'firstName': row.firstName,
    'lastName': row.lastName,
    'otherNames': row.otherNames,
    'birthDate': row.birthDate?.toUtc().toIso8601String(),
    'baptismDate': row.baptismDate?.toUtc().toIso8601String(),
    'gender': row.gender.index,
    'hopeClass': row.hopeClass.index,
    'congregationRole': row.congregationRole.index,
    'pioneerType': row.pioneerType.index,
    'address': row.address,
    'email': row.email,
    'isActive': row.isActive,
    'inactiveDate': row.inactiveDate?.toUtc().toIso8601String(),
    'recordStatus': row.recordStatus.index,
    'archiveReason': row.archiveReason?.index,
    'archivedAt': row.archivedAt?.toUtc().toIso8601String(),
    'trashedAt': row.trashedAt?.toUtc().toIso8601String(),
    'congregationSyncId': row.congregationId == null
        ? null
        : await _ensureCongregationSyncId(row.congregationId!),
    'fieldServiceGroupSyncId': row.fieldServiceGroupId == null
        ? null
        : await _ensureFieldServiceGroupSyncId(row.fieldServiceGroupId!),
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  };

  Future<Map<String, dynamic>> _phoneNumberPayload(PhoneNumber row) async => {
    'syncId': row.syncId,
    'number': row.number,
    'phoneType': row.phoneType.index,
    'isPrimary': row.isPrimary,
    'personSyncId': await _ensurePersonSyncId(row.personId),
    'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  };

  Future<Map<String, dynamic>> _emergencyContactPayload(
    EmergencyContact row,
  ) async => {
    'syncId': row.syncId,
    'name': row.name,
    'phoneNumber': row.phoneNumber,
    'relationship': row.relationship.index,
    'isPrimary': row.isPrimary,
    'personSyncId': await _ensurePersonSyncId(row.personId),
    'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  };

  Future<Map<String, dynamic>> _serviceReportPayload(ServiceReport row) async =>
      {
        'syncId': row.syncId,
        'year': row.year,
        'month': row.month,
        'isAuxiliaryPioneer': row.isAuxiliaryPioneer,
        'isActive': row.isActive,
        'sharedInMinistry': row.sharedInMinistry,
        'bibleStudies': row.bibleStudies,
        'hours': row.hours,
        'note': row.note,
        'personSyncId': await _ensurePersonSyncId(row.personId),
        'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
      };

  Future<Map<String, dynamic>> _auxiliaryPioneerPeriodPayload(
    AuxiliaryPioneerPeriod row,
  ) async => {
    'syncId': row.syncId,
    'startMonth': row.startMonth,
    'startYear': row.startYear,
    'endMonth': row.endMonth,
    'endYear': row.endYear,
    'personSyncId': await _ensurePersonSyncId(row.personId),
    'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  };

  // ──────────────────────────────────────────────────
  // Congregation queries
  // ──────────────────────────────────────────────────

  Future<List<Congregation>> getAllCongregations() =>
      select(congregations).get();

  Stream<List<Congregation>> watchAllCongregations() =>
      select(congregations).watch();

  Future<Congregation> getCongregation(int id) =>
      (select(congregations)..where((c) => c.id.equals(id))).getSingle();

  Stream<Congregation?> watchCongregation(int id) => (select(
    congregations,
  )..where((c) => c.id.equals(id))).watchSingleOrNull();

  Future<int> insertCongregation(CongregationsCompanion entry) async {
    final id = await into(congregations).insert(entry);
    final syncId = await _ensureCongregationSyncId(id);
    final row = await getCongregation(id);
    await _queueOperationIfEnabled(
      entityType: 'congregation',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: _congregationPayload(row),
      baseServerVersion: row.serverVersion,
    );
    return id;
  }

  Future<bool> updateCongregation(CongregationsCompanion entry) async {
    final existing = entry.id.present
        ? await getCongregation(entry.id.value)
        : null;
    final result = await update(congregations).replace(entry);
    if (existing != null) {
      final syncId = await _ensureCongregationSyncId(existing.id);
      final row = await getCongregation(existing.id);
      await _queueOperationIfEnabled(
        entityType: 'congregation',
        entitySyncId: syncId,
        operationType: 'upsert',
        payload: _congregationPayload(row),
        baseServerVersion: existing.serverVersion,
      );
    }
    return result;
  }

  Future<int> deleteCongregation(int id) async {
    final existing = await getCongregation(id);
    final syncId = await _ensureCongregationSyncId(id);
    await _queueOperationIfEnabled(
      entityType: 'congregation',
      entitySyncId: syncId,
      operationType: 'delete',
      payload: {
        ..._congregationPayload(existing),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      },
      baseServerVersion: existing.serverVersion,
    );
    return (delete(congregations)..where((c) => c.id.equals(id))).go();
  }

  // ──────────────────────────────────────────────────
  // Person queries
  // ──────────────────────────────────────────────────

  Future<List<Person>> getAllPersons({
    int? congregationId,
    PersonRecordStatus? recordStatus = PersonRecordStatus.current,
  }) {
    final query = select(persons);
    if (congregationId != null) {
      query.where((p) => p.congregationId.equals(congregationId));
    }
    if (recordStatus != null) {
      query.where((p) => p.recordStatus.equalsValue(recordStatus));
    }
    query.orderBy([
      (p) => OrderingTerm(expression: p.lastName),
      (p) => OrderingTerm(expression: p.firstName),
    ]);
    return query.get();
  }

  Stream<List<Person>> watchAllPersons({
    int? congregationId,
    PersonRecordStatus? recordStatus = PersonRecordStatus.current,
  }) {
    final query = select(persons);
    if (congregationId != null) {
      query.where((p) => p.congregationId.equals(congregationId));
    }
    if (recordStatus != null) {
      query.where((p) => p.recordStatus.equalsValue(recordStatus));
    }
    query.orderBy([
      (p) => OrderingTerm(expression: p.lastName),
      (p) => OrderingTerm(expression: p.firstName),
    ]);
    return query.watch();
  }

  Future<Person> getPerson(int id) =>
      (select(persons)..where((p) => p.id.equals(id))).getSingle();

  Future<int> insertPerson(PersonsCompanion entry) async {
    final id = await into(persons).insert(entry);
    final syncId = await _ensurePersonSyncId(id);
    final row = await getPerson(id);
    await _queueOperationIfEnabled(
      entityType: 'person',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _personPayload(row),
      baseServerVersion: row.serverVersion,
    );
    return id;
  }

  Future<bool> updatePerson(PersonsCompanion entry) async {
    final existing = entry.id.present ? await getPerson(entry.id.value) : null;
    final result = await update(persons).replace(entry);
    if (existing != null) {
      final syncId = await _ensurePersonSyncId(existing.id);
      final row = await getPerson(existing.id);
      await _queueOperationIfEnabled(
        entityType: 'person',
        entitySyncId: syncId,
        operationType: 'upsert',
        payload: await _personPayload(row),
        baseServerVersion: existing.serverVersion,
      );
    }
    return result;
  }

  Future<void> updatePersonPioneerType(int id, PioneerType pioneerType) async {
    final existing = await getPerson(id);
    await _updatePersonFields(
      existing,
      PersonsCompanion(
        pioneerType: Value(pioneerType),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> archivePerson(
    int id, {
    required PersonArchiveReason reason,
    required DateTime archivedAt,
  }) async {
    await transaction(() async {
      final existing = await getPerson(id);
      if (existing.recordStatus != PersonRecordStatus.current) {
        throw StateError('Only current publishers can be archived.');
      }
      await _clearPersonLeadershipAssignments(id);
      await _updatePersonFields(
        existing,
        PersonsCompanion(
          recordStatus: const Value(PersonRecordStatus.archived),
          archiveReason: Value(reason),
          archivedAt: Value(archivedAt),
          trashedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> movePersonToTrash(int id) async {
    await transaction(() async {
      final existing = await getPerson(id);
      if (existing.recordStatus == PersonRecordStatus.trashed) return;
      await _clearPersonLeadershipAssignments(id);
      await _updatePersonFields(
        existing,
        PersonsCompanion(
          recordStatus: const Value(PersonRecordStatus.trashed),
          trashedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> restoreArchivedPerson(int id) async {
    await transaction(() async {
      final existing = await getPerson(id);
      if (existing.recordStatus != PersonRecordStatus.archived) {
        throw StateError('Only archived publishers can be restored.');
      }
      await _updatePersonFields(
        existing,
        PersonsCompanion(
          recordStatus: const Value(PersonRecordStatus.current),
          archiveReason: const Value(null),
          archivedAt: const Value(null),
          trashedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Restores a trashed publisher to the state they had before being trashed.
  Future<PersonRecordStatus> restoreTrashedPerson(int id) async {
    return transaction(() async {
      final existing = await getPerson(id);
      if (existing.recordStatus != PersonRecordStatus.trashed) {
        throw StateError('Only trashed publishers can be restored.');
      }
      final destination = existing.archivedAt == null
          ? PersonRecordStatus.current
          : PersonRecordStatus.archived;
      await _updatePersonFields(
        existing,
        PersonsCompanion(
          recordStatus: Value(destination),
          trashedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return destination;
    });
  }

  /// Permanently removes a publisher and every record owned by them.
  ///
  /// Publishers must first be moved to Trash. Child delete operations are
  /// queued before the publisher delete so online sync can apply them in a
  /// referentially safe order.
  Future<int> deletePersonPermanently(int id) async {
    return transaction(() async {
      final existing = await getPerson(id);
      if (existing.recordStatus != PersonRecordStatus.trashed) {
        throw StateError(
          'A publisher must be moved to Trash before permanent deletion.',
        );
      }

      await deletePhoneNumbersForPerson(id);
      await deleteEmergencyContactsForPerson(id);
      await deleteServiceReportsForPerson(id);
      await deleteAuxiliaryPioneerPeriodsForPerson(id);
      await _clearPersonLeadershipAssignments(id);

      final syncId = await _ensurePersonSyncId(id);
      await _queueOperationIfEnabled(
        entityType: 'person',
        entitySyncId: syncId,
        operationType: 'delete',
        payload: {
          ...await _personPayload(existing),
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
        },
        baseServerVersion: existing.serverVersion,
      );
      return (delete(persons)..where((p) => p.id.equals(id))).go();
    });
  }

  @Deprecated('Use movePersonToTrash or deletePersonPermanently instead.')
  Future<int> deletePerson(int id) => deletePersonPermanently(id);

  Future<void> _updatePersonFields(
    Person existing,
    PersonsCompanion fields,
  ) async {
    final updated = await (update(
      persons,
    )..where((p) => p.id.equals(existing.id))).write(fields);
    if (updated == 0) {
      throw StateError('Publisher ${existing.id} no longer exists.');
    }
    final syncId = await _ensurePersonSyncId(existing.id);
    final row = await getPerson(existing.id);
    await _queueOperationIfEnabled(
      entityType: 'person',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _personPayload(row),
      baseServerVersion: existing.serverVersion,
    );
  }

  Future<void> _clearPersonLeadershipAssignments(int personId) async {
    final affected =
        await (select(fieldServiceGroups)..where(
              (g) =>
                  g.groupOverseerId.equals(personId) |
                  g.assistantId.equals(personId),
            ))
            .get();
    for (final group in affected) {
      final fields = FieldServiceGroupsCompanion(
        groupOverseerId: group.groupOverseerId == personId
            ? const Value(null)
            : const Value.absent(),
        assistantId: group.assistantId == personId
            ? const Value(null)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );
      await (update(
        fieldServiceGroups,
      )..where((g) => g.id.equals(group.id))).write(fields);
      final syncId = await _ensureFieldServiceGroupSyncId(group.id);
      final row = await getFieldServiceGroup(group.id);
      await _queueOperationIfEnabled(
        entityType: 'fieldServiceGroup',
        entitySyncId: syncId,
        operationType: 'upsert',
        payload: await _fieldServiceGroupPayload(row),
        baseServerVersion: group.serverVersion,
      );
    }
  }

  // ──────────────────────────────────────────────────
  // Phone number queries
  // ──────────────────────────────────────────────────

  Future<List<PhoneNumber>> getPhoneNumbers(int personId) =>
      (select(phoneNumbers)..where((p) => p.personId.equals(personId))).get();

  Future<int> insertPhoneNumber(PhoneNumbersCompanion entry) async {
    final id = await into(phoneNumbers).insert(entry);
    final syncId = await _ensurePhoneNumberSyncId(id);
    final row = await (select(
      phoneNumbers,
    )..where((p) => p.id.equals(id))).getSingle();
    await _queueOperationIfEnabled(
      entityType: 'phoneNumber',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _phoneNumberPayload(row),
      baseServerVersion: row.serverVersion,
    );
    return id;
  }

  Future<bool> updatePhoneNumber(PhoneNumbersCompanion entry) async {
    final existing = entry.id.present
        ? await (select(
            phoneNumbers,
          )..where((p) => p.id.equals(entry.id.value))).getSingleOrNull()
        : null;
    final result = await update(phoneNumbers).replace(entry);
    if (existing != null) {
      final syncId = await _ensurePhoneNumberSyncId(existing.id);
      final row = await (select(
        phoneNumbers,
      )..where((p) => p.id.equals(existing.id))).getSingle();
      await _queueOperationIfEnabled(
        entityType: 'phoneNumber',
        entitySyncId: syncId,
        operationType: 'upsert',
        payload: await _phoneNumberPayload(row),
        baseServerVersion: existing.serverVersion,
      );
    }
    return result;
  }

  Future<int> deletePhoneNumber(int id) async {
    final existing = await (select(
      phoneNumbers,
    )..where((p) => p.id.equals(id))).getSingle();
    final syncId = await _ensurePhoneNumberSyncId(id);
    await _queueOperationIfEnabled(
      entityType: 'phoneNumber',
      entitySyncId: syncId,
      operationType: 'delete',
      payload: {
        ...await _phoneNumberPayload(existing),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      },
      baseServerVersion: existing.serverVersion,
    );
    return (delete(phoneNumbers)..where((p) => p.id.equals(id))).go();
  }

  Future<void> deletePhoneNumbersForPerson(int personId) async {
    final rows = await getPhoneNumbers(personId);
    for (final row in rows) {
      await deletePhoneNumber(row.id);
    }
  }

  // ──────────────────────────────────────────────────
  // Emergency contact queries
  // ──────────────────────────────────────────────────

  Future<List<EmergencyContact>> getEmergencyContacts(int personId) => (select(
    emergencyContacts,
  )..where((e) => e.personId.equals(personId))).get();

  Future<int> insertEmergencyContact(EmergencyContactsCompanion entry) async {
    final id = await into(emergencyContacts).insert(entry);
    final syncId = await _ensureEmergencyContactSyncId(id);
    final row = await (select(
      emergencyContacts,
    )..where((e) => e.id.equals(id))).getSingle();
    await _queueOperationIfEnabled(
      entityType: 'emergencyContact',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _emergencyContactPayload(row),
      baseServerVersion: row.serverVersion,
    );
    return id;
  }

  Future<bool> updateEmergencyContact(EmergencyContactsCompanion entry) async {
    final existing = entry.id.present
        ? await (select(
            emergencyContacts,
          )..where((e) => e.id.equals(entry.id.value))).getSingleOrNull()
        : null;
    final result = await update(emergencyContacts).replace(entry);
    if (existing != null) {
      final syncId = await _ensureEmergencyContactSyncId(existing.id);
      final row = await (select(
        emergencyContacts,
      )..where((e) => e.id.equals(existing.id))).getSingle();
      await _queueOperationIfEnabled(
        entityType: 'emergencyContact',
        entitySyncId: syncId,
        operationType: 'upsert',
        payload: await _emergencyContactPayload(row),
        baseServerVersion: existing.serverVersion,
      );
    }
    return result;
  }

  Future<int> deleteEmergencyContact(int id) async {
    final existing = await (select(
      emergencyContacts,
    )..where((e) => e.id.equals(id))).getSingle();
    final syncId = await _ensureEmergencyContactSyncId(id);
    await _queueOperationIfEnabled(
      entityType: 'emergencyContact',
      entitySyncId: syncId,
      operationType: 'delete',
      payload: {
        ...await _emergencyContactPayload(existing),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      },
      baseServerVersion: existing.serverVersion,
    );
    return (delete(emergencyContacts)..where((e) => e.id.equals(id))).go();
  }

  Future<void> deleteEmergencyContactsForPerson(int personId) async {
    final rows = await getEmergencyContacts(personId);
    for (final row in rows) {
      await deleteEmergencyContact(row.id);
    }
  }

  // ──────────────────────────────────────────────────
  // Service report queries
  // ──────────────────────────────────────────────────

  Future<List<ServiceReport>> getServiceReports({
    int? personId,
    int? year,
    int? month,
    int? congregationId,
    bool includeInactivePublishers = true,
  }) {
    final query = select(serviceReports);
    if (personId != null) {
      query.where((s) => s.personId.equals(personId));
    }
    if (year != null) {
      query.where((s) => s.year.equals(year));
    }
    if (month != null) {
      query.where((s) => s.month.equals(month));
    }
    if (!includeInactivePublishers) {
      query.where((s) => s.isActive.equals(true));
    }
    if (congregationId != null || !includeInactivePublishers) {
      final personIdQuery = selectOnly(persons)..addColumns([persons.id]);
      personIdQuery.where(
        persons.recordStatus.equalsValue(PersonRecordStatus.current),
      );
      if (congregationId != null) {
        personIdQuery.where(persons.congregationId.equals(congregationId));
      }
      if (!includeInactivePublishers) {
        personIdQuery.where(persons.isActive.equals(true));
      }
      query.where((s) => s.personId.isInQuery(personIdQuery));
    }
    query.orderBy([
      (s) => OrderingTerm.desc(s.year),
      (s) => OrderingTerm.desc(s.month),
    ]);
    return query.get();
  }

  Stream<List<ServiceReport>> watchServiceReports({
    int? personId,
    int? year,
    int? month,
    int? congregationId,
    bool includeInactivePublishers = true,
  }) {
    final query = select(serviceReports);
    if (personId != null) {
      query.where((s) => s.personId.equals(personId));
    }
    if (year != null) {
      query.where((s) => s.year.equals(year));
    }
    if (month != null) {
      query.where((s) => s.month.equals(month));
    }
    if (!includeInactivePublishers) {
      query.where((s) => s.isActive.equals(true));
    }
    if (congregationId != null || !includeInactivePublishers) {
      final personIdQuery = selectOnly(persons)..addColumns([persons.id]);
      personIdQuery.where(
        persons.recordStatus.equalsValue(PersonRecordStatus.current),
      );
      if (congregationId != null) {
        personIdQuery.where(persons.congregationId.equals(congregationId));
      }
      if (!includeInactivePublishers) {
        personIdQuery.where(persons.isActive.equals(true));
      }
      query.where((s) => s.personId.isInQuery(personIdQuery));
    }
    query.orderBy([
      (s) => OrderingTerm.desc(s.year),
      (s) => OrderingTerm.desc(s.month),
    ]);
    return query.watch();
  }

  Future<int> insertServiceReport(ServiceReportsCompanion entry) async {
    final id = await into(serviceReports).insert(entry);
    final syncId = await _ensureServiceReportSyncId(id);
    final row = await (select(
      serviceReports,
    )..where((s) => s.id.equals(id))).getSingle();
    await _queueOperationIfEnabled(
      entityType: 'serviceReport',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _serviceReportPayload(row),
      baseServerVersion: row.serverVersion,
    );
    return id;
  }

  Future<int> upsertServiceReport(ServiceReportsCompanion entry) async {
    final id = await into(serviceReports).insertOnConflictUpdate(entry);
    final syncId = await _ensureServiceReportSyncId(id);
    final row = await (select(
      serviceReports,
    )..where((s) => s.id.equals(id))).getSingle();
    await _queueOperationIfEnabled(
      entityType: 'serviceReport',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _serviceReportPayload(row),
      baseServerVersion: row.serverVersion,
    );
    return id;
  }

  Future<bool> updateServiceReport(ServiceReportsCompanion entry) async {
    final existing = entry.id.present
        ? await (select(
            serviceReports,
          )..where((s) => s.id.equals(entry.id.value))).getSingleOrNull()
        : null;
    final result = await update(serviceReports).replace(entry);
    if (existing != null) {
      final syncId = await _ensureServiceReportSyncId(existing.id);
      final row = await (select(
        serviceReports,
      )..where((s) => s.id.equals(existing.id))).getSingle();
      await _queueOperationIfEnabled(
        entityType: 'serviceReport',
        entitySyncId: syncId,
        operationType: 'upsert',
        payload: await _serviceReportPayload(row),
        baseServerVersion: existing.serverVersion,
      );
    }
    return result;
  }

  Future<bool> updateServiceReportFields(
    int id,
    ServiceReportsCompanion fields,
  ) async {
    final existing = await (select(
      serviceReports,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (existing == null) return false;

    final updated = await (update(
      serviceReports,
    )..where((s) => s.id.equals(id))).write(fields);
    if (updated == 0) return false;

    final syncId = await _ensureServiceReportSyncId(existing.id);
    final row = await (select(
      serviceReports,
    )..where((s) => s.id.equals(existing.id))).getSingle();
    await _queueOperationIfEnabled(
      entityType: 'serviceReport',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _serviceReportPayload(row),
      baseServerVersion: existing.serverVersion,
    );
    return true;
  }

  Future<int> deleteServiceReport(int id) async {
    final existing = await (select(
      serviceReports,
    )..where((s) => s.id.equals(id))).getSingle();
    final syncId = await _ensureServiceReportSyncId(id);
    await _queueOperationIfEnabled(
      entityType: 'serviceReport',
      entitySyncId: syncId,
      operationType: 'delete',
      payload: {
        ...await _serviceReportPayload(existing),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      },
      baseServerVersion: existing.serverVersion,
    );
    return (delete(serviceReports)..where((s) => s.id.equals(id))).go();
  }

  Future<void> deleteServiceReportsForPerson(int personId) async {
    final rows = await getServiceReports(personId: personId);
    for (final row in rows) {
      await deleteServiceReport(row.id);
    }
  }

  Future<int> deleteServiceReportsByPersonAndYear(
    int personId,
    int year,
  ) async {
    final rows = await getServiceReports(personId: personId, year: year);
    var deleted = 0;
    for (final row in rows) {
      deleted += await deleteServiceReport(row.id);
    }
    return deleted;
  }

  Future<int> deleteServiceReportsByMonth(int year, int month) async {
    final rows = await getServiceReports(year: year, month: month);
    var deleted = 0;
    for (final row in rows) {
      deleted += await deleteServiceReport(row.id);
    }
    return deleted;
  }

  Future<int> deleteServiceReportsByYear(int year) async {
    final rows = await getServiceReports(year: year);
    var deleted = 0;
    for (final row in rows) {
      deleted += await deleteServiceReport(row.id);
    }
    return deleted;
  }

  /// Get or create service reports for all active persons in a given month/year.
  /// Persons made inactive before the given month are excluded.
  Future<List<ServiceReport>> getOrCreateReportsForPeriod(
    int year,
    int month, {
    int? congregationId,
  }) async {
    final personQuery = select(persons)
      ..where((p) => p.isActive.equals(true))
      ..where((p) => p.recordStatus.equalsValue(PersonRecordStatus.current));
    if (congregationId != null) {
      personQuery.where((p) => p.congregationId.equals(congregationId));
    }
    final allActive = await personQuery.get();

    // Also include persons who became inactive during or after this month
    final inactiveQuery = select(persons)
      ..where((p) => p.isActive.equals(false))
      ..where((p) => p.recordStatus.equalsValue(PersonRecordStatus.current));
    if (congregationId != null) {
      inactiveQuery.where((p) => p.congregationId.equals(congregationId));
    }
    // Include if inactiveDate is null (legacy) or >= first day of the requested month
    final periodStart = DateTime(year, month);
    inactiveQuery.where(
      (p) =>
          p.inactiveDate.isNull() |
          p.inactiveDate.isBiggerOrEqualValue(periodStart),
    );
    final recentlyInactive = await inactiveQuery.get();

    final allPersons = [...allActive, ...recentlyInactive];
    final allPeriods = await select(auxiliaryPioneerPeriods).get();
    final periodsByPerson = <int, List<AuxiliaryPioneerPeriod>>{};
    for (final period in allPeriods) {
      periodsByPerson.putIfAbsent(period.personId, () => []).add(period);
    }
    final existing = await getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final existingPersonIds = existing.map((r) => r.personId).toSet();

    for (final person in allPersons) {
      if (!existingPersonIds.contains(person.id)) {
        final isAuxiliaryPioneer =
            person.pioneerType == PioneerType.none &&
            (periodsByPerson[person.id] ?? const <AuxiliaryPioneerPeriod>[])
                .any((period) => _periodIncludes(period, year, month));
        await insertServiceReport(
          ServiceReportsCompanion.insert(
            year: year,
            month: month,
            personId: person.id,
            isAuxiliaryPioneer: Value(isAuxiliaryPioneer),
          ),
        );
      }
    }

    return getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
  }

  static bool _periodIncludes(
    AuxiliaryPioneerPeriod period,
    int year,
    int month,
  ) {
    final target = year * 12 + month;
    final start = period.startYear * 12 + period.startMonth;
    if (target < start) return false;
    if (period.endYear == null || period.endMonth == null) return true;
    final end = period.endYear! * 12 + period.endMonth!;
    return target <= end;
  }

  /// Get month statistics for a given service year and month.
  Future<FieldServiceReportStatistics> getMonthStatistics(
    int year,
    int month, {
    int? congregationId,
  }) async {
    final personQuery = select(persons)
      ..where((p) => p.recordStatus.equalsValue(PersonRecordStatus.current));
    if (congregationId != null) {
      personQuery.where((p) => p.congregationId.equals(congregationId));
    }
    final currentPersons = await personQuery.get();
    final activePersons = currentPersons.where((person) => person.isActive);

    final reports = await getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final activeReports = reports.where((r) {
      return r.sharedInMinistry || r.hours > 0 || r.bibleStudies > 0;
    }).toList();
    final pioneerTypesByPerson = {
      for (final person in currentPersons) person.id: person.pioneerType,
    };

    final reportsByCategory =
        <FieldServicePublisherCategory, List<ServiceReport>>{
          for (final category in FieldServicePublisherCategory.values)
            category: <ServiceReport>[],
        };
    for (final report in activeReports) {
      final category = classifyFieldServicePublisher(
        pioneerType: pioneerTypesByPerson[report.personId] ?? PioneerType.none,
        isAuxiliaryPioneer: report.isAuxiliaryPioneer,
      );
      reportsByCategory[category]!.add(report);
    }

    ReportMetrics metricsFor(
      FieldServicePublisherCategory category, {
      bool includeHours = true,
    }) {
      final categoryReports = reportsByCategory[category]!;
      return ReportMetrics(
        numberOfReports: categoryReports.length,
        bibleStudies: categoryReports.fold(
          0,
          (sum, report) => sum + report.bibleStudies,
        ),
        hours: includeHours
            ? categoryReports.fold(0.0, (sum, report) => sum + report.hours)
            : 0,
        personIds: categoryReports.map((report) => report.personId).toList(),
      );
    }

    return FieldServiceReportStatistics(
      allActivePublishers: activePersons.length,
      publishers: metricsFor(
        FieldServicePublisherCategory.publisher,
        includeHours: false,
      ),
      auxiliaryPioneers: metricsFor(
        FieldServicePublisherCategory.auxiliaryPioneer,
      ),
      regularPioneers: metricsFor(FieldServicePublisherCategory.regularPioneer),
      specialPioneers: metricsFor(FieldServicePublisherCategory.specialPioneer),
      fieldMissionaries: metricsFor(
        FieldServicePublisherCategory.fieldMissionary,
      ),
    );
  }

  /// Analyze calendar months through [throughMonth] of [serviceYear].
  /// Defaults to the last completed service year for annual summaries.
  /// Missing months after the first recorded ministry participation count as
  /// not reporting. Leading blank reports cannot establish prior activity.
  Future<CongregationAnalysis> getCongregationAnalysis({
    int? congregationId,
    int? serviceYear,
    int throughMonth = 8,
  }) async {
    RangeError.checkValueInInterval(throughMonth, 1, 12, 'throughMonth');
    final year = serviceYear ?? currentServiceYear() - 1;
    final start = serviceReportPeriodIndex(year, 9);
    final end = serviceReportPeriodIndex(year, throughMonth);
    final personQuery = select(persons)
      ..where((p) => p.recordStatus.equalsValue(PersonRecordStatus.current))
      ..where((p) => p.deletedAt.isNull());
    if (congregationId != null) {
      personQuery.where((p) => p.congregationId.equals(congregationId));
    }
    final currentPersons = await personQuery.get();
    // Load the history once, rather than making a query per publisher.
    final reports = await getServiceReports(congregationId: congregationId);
    final monthsByPerson = <int, Map<int, bool>>{};
    for (final report in reports) {
      if (report.deletedAt != null) continue;
      final period = serviceReportPeriodIndex(report.year, report.month);
      if (period > end) continue;
      final months = monthsByPerson.putIfAbsent(report.personId, () => {});
      // A duplicate report must not create an extra month or hide activity.
      months[period] = (months[period] ?? false) || report.sharedInMinistry;
    }

    final active = <int>[];
    final newInactive = <int>[];
    final reactivated = <int>[];
    for (final person in currentPersons) {
      final months = monthsByPerson[person.id];
      if (months == null || months.isEmpty) continue;
      final sharedPeriods =
          months.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList()
            ..sort();
      if (sharedPeriods.isEmpty) continue;
      if (sharedPeriods.last >= end - 5) {
        active.add(person.id);
      }

      // Imports and year entry can save blank months before a new publisher's
      // first participation. Establish activity before tracking any absence;
      // the first actual participation is never itself a reactivation.
      // Carry inactivity across service-year boundaries. Count transitions
      // only in this service year, once per person in each category.
      var consecutive = 0;
      var becameInactive = false;
      var resumed = false;
      for (var period = sharedPeriods.first; period <= end; period++) {
        if (months[period] == true) {
          if (consecutive >= 6 && period >= start) resumed = true;
          consecutive = 0;
        } else {
          consecutive++;
          if (consecutive == 6 && period >= start) becameInactive = true;
        }
      }
      if (becameInactive) newInactive.add(person.id);
      if (resumed) reactivated.add(person.id);
    }

    return CongregationAnalysis(
      serviceYear: year,
      throughMonth: throughMonth,
      allActivePersonIds: List.unmodifiable(active),
      newInactivePersonIds: List.unmodifiable(newInactive),
      reactivatedPersonIds: List.unmodifiable(reactivated),
    );
  }

  // ──────────────────────────────────────────────────
  // Field service group queries
  // ──────────────────────────────────────────────────

  Future<List<FieldServiceGroup>> getAllFieldServiceGroups({
    int? congregationId,
  }) {
    final query = select(fieldServiceGroups);
    if (congregationId != null) {
      query.where((g) => g.congregationId.equals(congregationId));
    }
    return query.get();
  }

  Stream<List<FieldServiceGroup>> watchAllFieldServiceGroups({
    int? congregationId,
  }) {
    final query = select(fieldServiceGroups);
    if (congregationId != null) {
      query.where((g) => g.congregationId.equals(congregationId));
    }
    return query.watch();
  }

  Future<FieldServiceGroup> getFieldServiceGroup(int id) =>
      (select(fieldServiceGroups)..where((g) => g.id.equals(id))).getSingle();

  Future<int> insertFieldServiceGroup(FieldServiceGroupsCompanion entry) async {
    final id = await into(fieldServiceGroups).insert(entry);
    final syncId = await _ensureFieldServiceGroupSyncId(id);
    final row = await getFieldServiceGroup(id);
    await _queueOperationIfEnabled(
      entityType: 'fieldServiceGroup',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _fieldServiceGroupPayload(row),
      baseServerVersion: row.serverVersion,
    );
    return id;
  }

  Future<bool> updateFieldServiceGroup(
    FieldServiceGroupsCompanion entry,
  ) async {
    final existing = entry.id.present
        ? await getFieldServiceGroup(entry.id.value)
        : null;
    final result = await update(fieldServiceGroups).replace(entry);
    if (existing != null) {
      final syncId = await _ensureFieldServiceGroupSyncId(existing.id);
      final row = await getFieldServiceGroup(existing.id);
      await _queueOperationIfEnabled(
        entityType: 'fieldServiceGroup',
        entitySyncId: syncId,
        operationType: 'upsert',
        payload: await _fieldServiceGroupPayload(row),
        baseServerVersion: existing.serverVersion,
      );
    }
    return result;
  }

  Future<int> deleteFieldServiceGroup(int id) async {
    final existing = await getFieldServiceGroup(id);
    final syncId = await _ensureFieldServiceGroupSyncId(id);
    await _queueOperationIfEnabled(
      entityType: 'fieldServiceGroup',
      entitySyncId: syncId,
      operationType: 'delete',
      payload: {
        ...await _fieldServiceGroupPayload(existing),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      },
      baseServerVersion: existing.serverVersion,
    );
    return (delete(fieldServiceGroups)..where((g) => g.id.equals(id))).go();
  }

  // ──────────────────────────────────────────────────
  // Auxiliary pioneer period queries
  // ──────────────────────────────────────────────────

  Future<List<AuxiliaryPioneerPeriod>> getAuxiliaryPioneerPeriods(
    int personId,
  ) => (select(
    auxiliaryPioneerPeriods,
  )..where((a) => a.personId.equals(personId))).get();

  Future<int> insertAuxiliaryPioneerPeriod(
    AuxiliaryPioneerPeriodsCompanion entry,
  ) async {
    final id = await into(auxiliaryPioneerPeriods).insert(entry);
    final syncId = await _ensureAuxiliaryPioneerPeriodSyncId(id);
    final row = await (select(
      auxiliaryPioneerPeriods,
    )..where((a) => a.id.equals(id))).getSingle();
    await _queueOperationIfEnabled(
      entityType: 'auxiliaryPioneerPeriod',
      entitySyncId: syncId,
      operationType: 'upsert',
      payload: await _auxiliaryPioneerPeriodPayload(row),
      baseServerVersion: row.serverVersion,
    );
    return id;
  }

  Future<int> deleteAuxiliaryPioneerPeriod(int id) async {
    final existing = await (select(
      auxiliaryPioneerPeriods,
    )..where((a) => a.id.equals(id))).getSingle();
    final syncId = await _ensureAuxiliaryPioneerPeriodSyncId(id);
    await _queueOperationIfEnabled(
      entityType: 'auxiliaryPioneerPeriod',
      entitySyncId: syncId,
      operationType: 'delete',
      payload: {
        ...await _auxiliaryPioneerPeriodPayload(existing),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      },
      baseServerVersion: existing.serverVersion,
    );
    return (delete(
      auxiliaryPioneerPeriods,
    )..where((a) => a.id.equals(id))).go();
  }

  Future<void> deleteAuxiliaryPioneerPeriodsForPerson(int personId) async {
    final rows = await getAuxiliaryPioneerPeriods(personId);
    for (final row in rows) {
      await deleteAuxiliaryPioneerPeriod(row.id);
    }
  }

  // ──────────────────────────────────────────────────
  // Bulk / export operations
  // ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportAllDataAsJson() async {
    final allPersons = await select(persons).get();
    final allPhones = await select(phoneNumbers).get();
    final allEmergency = await select(emergencyContacts).get();
    final allReports = await select(serviceReports).get();
    final allGroups = await select(fieldServiceGroups).get();
    final allPeriods = await select(auxiliaryPioneerPeriods).get();
    final allCongregations = await select(congregations).get();

    return {
      'congregations': allCongregations
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'number': c.number,
              'city': c.city,
              'circuitNumber': c.circuitNumber,
            },
          )
          .toList(),
      'persons': allPersons
          .map(
            (p) => {
              'id': p.id,
              'firstName': p.firstName,
              'lastName': p.lastName,
              'otherNames': p.otherNames,
              'birthDate': p.birthDate?.toIso8601String(),
              'baptismDate': p.baptismDate?.toIso8601String(),
              'gender': p.gender.index,
              'hopeClass': p.hopeClass.index,
              'congregationRole': p.congregationRole.index,
              'pioneerType': p.pioneerType.index,
              'address': p.address,
              'isActive': p.isActive,
              'inactiveDate': p.inactiveDate?.toIso8601String(),
              'recordStatus': p.recordStatus.index,
              'archiveReason': p.archiveReason?.index,
              'archivedAt': p.archivedAt?.toIso8601String(),
              'trashedAt': p.trashedAt?.toIso8601String(),
              'congregationId': p.congregationId,
              'fieldServiceGroupId': p.fieldServiceGroupId,
            },
          )
          .toList(),
      'phoneNumbers': allPhones
          .map(
            (p) => {
              'id': p.id,
              'number': p.number,
              'phoneType': p.phoneType.index,
              'isPrimary': p.isPrimary,
              'personId': p.personId,
            },
          )
          .toList(),
      'emergencyContacts': allEmergency
          .map(
            (e) => {
              'id': e.id,
              'name': e.name,
              'phoneNumber': e.phoneNumber,
              'relationship': e.relationship.index,
              'isPrimary': e.isPrimary,
              'personId': e.personId,
            },
          )
          .toList(),
      'serviceReports': allReports
          .map(
            (s) => {
              'id': s.id,
              'year': s.year,
              'month': s.month,
              'isAuxiliaryPioneer': s.isAuxiliaryPioneer,
              'isActive': s.isActive,
              'sharedInMinistry': s.sharedInMinistry,
              'bibleStudies': s.bibleStudies,
              'hours': s.hours,
              'note': s.note,
              'personId': s.personId,
            },
          )
          .toList(),
      'fieldServiceGroups': allGroups
          .map(
            (g) => {
              'id': g.id,
              'name': g.name,
              'description': g.description,
              'congregationId': g.congregationId,
              'groupOverseerId': g.groupOverseerId,
              'assistantId': g.assistantId,
            },
          )
          .toList(),
      'auxiliaryPioneerPeriods': allPeriods
          .map(
            (a) => {
              'id': a.id,
              'startMonth': a.startMonth,
              'startYear': a.startYear,
              'endMonth': a.endMonth,
              'endYear': a.endYear,
              'personId': a.personId,
            },
          )
          .toList(),
    };
  }

  Future<void> importFromJson(Map<String, dynamic> data) async {
    // Detect format: old .NET export has PascalCase keys like "Congregations", "Persons"
    // and nested related data under each person.
    final isOldFormat =
        data.containsKey('Congregations') || data.containsKey('FormatVersion');

    await transaction(() async {
      // An import replaces every record, so an enrolled vault must follow:
      // what it had is deleted there and the imported records are uploaded.
      final syncEnabled = (await _ensureSyncSettings()).isEnabled;
      final onServer = syncEnabled
          ? await _recordsOnServer()
          : const <RemoteChange>[];

      if (isOldFormat) {
        await _importOldFormat(data);
      } else {
        await _importNativeFormat(data);
      }

      if (syncEnabled) await _replaceVaultContents(onServer);
    });
  }

  /// Copies the database next to itself (e.g. before joining a vault replaces
  /// local data) and returns the copy's path.
  Future<String> createBackupCopy(String label) async {
    final currentPath = await databasePath();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    final target =
        '${_parentDirectoryPath(currentPath)}${Platform.pathSeparator}'
        'congregation_manager.$label-$stamp.sqlite';
    await copyDatabaseToPath(target, overwrite: false);
    return target;
  }

  // Month name to number mapping for old .NET format
  static int _parseMonthName(String name) {
    const months = {
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };
    return months[name] ?? 1;
  }

  static T _parseEnum<T extends Enum>(
    String? value,
    List<T> values,
    T defaultValue,
  ) {
    if (value == null) return defaultValue;
    final lower = value.toLowerCase();
    for (final v in values) {
      if (v.name.toLowerCase() == lower) return v;
    }
    // Handle special cases
    if (T == HopeClass && lower == 'othersheep') {
      return values.firstWhere(
        (v) => v.name.toLowerCase() == 'othersheep',
        orElse: () => defaultValue,
      );
    }
    if (T == CongregationRole && lower == 'ministerialservant') {
      return values.firstWhere(
        (v) => v.name.toLowerCase() == 'ministerialservant',
        orElse: () => defaultValue,
      );
    }
    if (T == PioneerType && lower == 'regularpioneer') {
      return values.firstWhere(
        (v) => v.name.toLowerCase() == 'regularpioneer',
        orElse: () => defaultValue,
      );
    }
    if (T == PioneerType && lower == 'specialpioneer') {
      return values.firstWhere(
        (v) => v.name.toLowerCase() == 'specialpioneer',
        orElse: () => defaultValue,
      );
    }
    if (T == PioneerType && lower == 'fieldmissionary') {
      return values.firstWhere(
        (v) => v.name.toLowerCase() == 'fieldmissionary',
        orElse: () => defaultValue,
      );
    }
    return defaultValue;
  }

  /// Import from old .NET PublisherRecordsUpdater format.
  /// Persons contain nested PhoneNumbers, EmergencyContacts, ServiceReports, AuxiliaryPioneerPeriods.
  /// Enums are strings, keys are PascalCase.
  Future<void> _importOldFormat(Map<String, dynamic> data) async {
    await transaction(() async {
      // Clear all tables
      await delete(auxiliaryPioneerPeriods).go();
      await delete(emergencyContacts).go();
      await delete(phoneNumbers).go();
      await delete(serviceReports).go();
      await delete(persons).go();
      await delete(fieldServiceGroups).go();
      await delete(congregations).go();
      // Reset autoincrement sequences
      await customStatement("DELETE FROM sqlite_sequence");

      // Import congregations
      for (final c in (data['Congregations'] as List? ?? [])) {
        await into(congregations).insert(
          CongregationsCompanion(
            id: Value(c['Id'] as int),
            name: Value(c['Name'] as String? ?? ''),
            number: Value(c['Number'] as String? ?? ''),
            city: Value(c['City'] as String? ?? ''),
            circuitNumber: Value(c['CircuitNumber'] as String? ?? ''),
          ),
        );
      }

      // Import groups
      for (final g in (data['FieldServiceGroups'] as List? ?? [])) {
        await into(fieldServiceGroups).insert(
          FieldServiceGroupsCompanion(
            id: Value(g['Id'] as int),
            name: Value(g['Name'] as String? ?? ''),
            description: Value(g['Description'] as String? ?? ''),
            congregationId: Value(g['CongregationId'] as int?),
            groupOverseerId: Value(g['GroupOverseerId'] as int?),
            assistantId: Value(g['AssistantId'] as int?),
          ),
        );
      }

      // Import persons with nested related data
      for (final p in (data['Persons'] as List? ?? [])) {
        final personId = p['Id'] as int;

        await into(persons).insert(
          PersonsCompanion(
            id: Value(personId),
            firstName: Value(p['FirstName'] as String? ?? ''),
            lastName: Value(p['LastName'] as String? ?? ''),
            otherNames: Value(p['OtherNames'] as String? ?? ''),
            address: Value(p['Address'] as String? ?? ''),
            birthDate: Value(
              p['BirthDate'] != null
                  ? DateTime.tryParse(p['BirthDate'] as String)
                  : null,
            ),
            baptismDate: Value(
              p['BaptismDate'] != null
                  ? DateTime.tryParse(p['BaptismDate'] as String)
                  : null,
            ),
            gender: Value(
              _parseEnum(p['Gender'] as String?, Gender.values, Gender.unknown),
            ),
            hopeClass: Value(
              _parseEnum(
                p['Hope'] as String?,
                HopeClass.values,
                HopeClass.unknown,
              ),
            ),
            congregationRole: Value(
              _parseEnum(
                p['CongregationRole'] as String?,
                CongregationRole.values,
                CongregationRole.none,
              ),
            ),
            pioneerType: Value(
              _parseEnum(
                p['PioneerType'] as String?,
                PioneerType.values,
                PioneerType.none,
              ),
            ),
            isActive: Value(p['IsActive'] as bool? ?? true),
            inactiveDate: const Value(null),
            congregationId: Value(p['CongregationId'] as int?),
            fieldServiceGroupId: Value(p['FieldServiceGroupId'] as int?),
          ),
        );

        // Nested phone numbers
        for (final pn in (p['PhoneNumbers'] as List? ?? [])) {
          await into(phoneNumbers).insert(
            PhoneNumbersCompanion(
              id: Value(pn['Id'] as int),
              number: Value(pn['Number'] as String? ?? ''),
              phoneType: Value(
                _parseEnum(
                  pn['PhoneType'] as String?,
                  PhoneType.values,
                  PhoneType.mobile,
                ),
              ),
              isPrimary: Value(pn['IsPrimary'] as bool? ?? false),
              personId: Value(personId),
            ),
          );
        }

        // Nested emergency contacts
        for (final ec in (p['EmergencyContacts'] as List? ?? [])) {
          await into(emergencyContacts).insert(
            EmergencyContactsCompanion(
              id: Value(ec['Id'] as int),
              name: Value(ec['Name'] as String? ?? ''),
              phoneNumber: Value(ec['PhoneNumber'] as String? ?? ''),
              relationship: Value(
                _parseEnum(
                  ec['Relationship'] as String?,
                  Relationship.values,
                  Relationship.other,
                ),
              ),
              isPrimary: Value(ec['IsPrimary'] as bool? ?? false),
              personId: Value(personId),
            ),
          );
        }

        // Nested service reports
        for (final sr in (p['ServiceReports'] as List? ?? [])) {
          final month = sr['Month'] is String
              ? _parseMonthName(sr['Month'] as String)
              : sr['Month'] as int? ?? 1;
          await into(serviceReports).insert(
            ServiceReportsCompanion(
              id: Value(sr['Id'] as int),
              year: Value(sr['Year'] as int),
              month: Value(month),
              personId: Value(personId),
              isAuxiliaryPioneer: Value(
                sr['IsAuxiliaryPioneer'] as bool? ?? false,
              ),
              isActive: Value(sr['IsActive'] as bool? ?? true),
              sharedInMinistry: Value(sr['SharedInMinistry'] as bool? ?? false),
              bibleStudies: Value(sr['BibleStudies'] as int? ?? 0),
              hours: Value((sr['Hours'] as num?)?.toDouble() ?? 0.0),
              note: Value(sr['Note'] as String? ?? ''),
            ),
          );
        }

        // Nested auxiliary pioneer periods
        for (final ap in (p['AuxiliaryPioneerPeriods'] as List? ?? [])) {
          final startMonth = ap['StartMonth'] is String
              ? _parseMonthName(ap['StartMonth'] as String)
              : ap['StartMonth'] as int? ?? 1;
          final endMonth = ap['EndMonth'] is String
              ? _parseMonthName(ap['EndMonth'] as String)
              : ap['EndMonth'] as int?;
          await into(auxiliaryPioneerPeriods).insert(
            AuxiliaryPioneerPeriodsCompanion(
              id: Value(ap['Id'] as int),
              startMonth: Value(startMonth),
              startYear: Value(ap['StartYear'] as int),
              endMonth: Value(endMonth),
              endYear: Value(ap['EndYear'] as int?),
              personId: Value(personId),
            ),
          );
        }
      }
    });
  }

  /// Import from native Flutter app format (camelCase keys, flat arrays, enum indices).
  Future<void> _importNativeFormat(Map<String, dynamic> data) async {
    await transaction(() async {
      // Clear all tables
      await delete(auxiliaryPioneerPeriods).go();
      await delete(emergencyContacts).go();
      await delete(phoneNumbers).go();
      await delete(serviceReports).go();
      await delete(persons).go();
      await delete(fieldServiceGroups).go();
      await delete(congregations).go();
      // Reset autoincrement sequences
      await customStatement("DELETE FROM sqlite_sequence");

      // Import congregations
      for (final c in (data['congregations'] as List? ?? [])) {
        await into(congregations).insert(
          CongregationsCompanion(
            id: c['id'] != null ? Value(c['id'] as int) : const Value.absent(),
            name: Value(c['name'] as String? ?? ''),
            number: Value(c['number'] as String? ?? ''),
            city: Value(c['city'] as String? ?? ''),
            circuitNumber: Value(c['circuitNumber'] as String? ?? ''),
          ),
        );
      }

      // Import groups
      for (final g in (data['fieldServiceGroups'] as List? ?? [])) {
        await into(fieldServiceGroups).insert(
          FieldServiceGroupsCompanion(
            id: g['id'] != null ? Value(g['id'] as int) : const Value.absent(),
            name: Value(g['name'] as String? ?? ''),
            description: Value(g['description'] as String? ?? ''),
            congregationId: Value(g['congregationId'] as int?),
            groupOverseerId: Value(g['groupOverseerId'] as int?),
            assistantId: Value(g['assistantId'] as int?),
          ),
        );
      }

      // Import persons
      for (final p in (data['persons'] as List? ?? [])) {
        await into(persons).insert(
          PersonsCompanion(
            id: p['id'] != null ? Value(p['id'] as int) : const Value.absent(),
            firstName: Value(p['firstName'] as String? ?? ''),
            lastName: Value(p['lastName'] as String? ?? ''),
            otherNames: Value(p['otherNames'] as String? ?? ''),
            address: Value(p['address'] as String? ?? ''),
            birthDate: Value(
              p['birthDate'] != null
                  ? DateTime.tryParse(p['birthDate'] as String)
                  : null,
            ),
            baptismDate: Value(
              p['baptismDate'] != null
                  ? DateTime.tryParse(p['baptismDate'] as String)
                  : null,
            ),
            gender: Value(Gender.values[p['gender'] as int? ?? 0]),
            hopeClass: Value(HopeClass.values[p['hopeClass'] as int? ?? 0]),
            congregationRole: Value(
              CongregationRole.values[p['congregationRole'] as int? ?? 0],
            ),
            pioneerType: Value(
              PioneerType.values[p['pioneerType'] as int? ?? 0],
            ),
            isActive: Value(p['isActive'] as bool? ?? true),
            inactiveDate: Value(
              p['inactiveDate'] != null
                  ? DateTime.tryParse(p['inactiveDate'] as String)
                  : null,
            ),
            recordStatus: Value(
              _enumAt(
                PersonRecordStatus.values,
                p['recordStatus'],
                PersonRecordStatus.current,
              ),
            ),
            archiveReason: Value(
              p['archiveReason'] == null
                  ? null
                  : _enumAt(
                      PersonArchiveReason.values,
                      p['archiveReason'],
                      PersonArchiveReason.other,
                    ),
            ),
            archivedAt: Value(
              p['archivedAt'] != null
                  ? DateTime.tryParse(p['archivedAt'] as String)
                  : null,
            ),
            trashedAt: Value(
              p['trashedAt'] != null
                  ? DateTime.tryParse(p['trashedAt'] as String)
                  : null,
            ),
            congregationId: Value(p['congregationId'] as int?),
            fieldServiceGroupId: Value(p['fieldServiceGroupId'] as int?),
          ),
        );
      }

      // Import phone numbers
      for (final pn in (data['phoneNumbers'] as List? ?? [])) {
        await into(phoneNumbers).insert(
          PhoneNumbersCompanion(
            id: pn['id'] != null
                ? Value(pn['id'] as int)
                : const Value.absent(),
            number: Value(pn['number'] as String? ?? ''),
            phoneType: Value(PhoneType.values[pn['phoneType'] as int? ?? 0]),
            isPrimary: Value(pn['isPrimary'] as bool? ?? false),
            personId: Value(pn['personId'] as int),
          ),
        );
      }

      // Import emergency contacts
      for (final ec in (data['emergencyContacts'] as List? ?? [])) {
        await into(emergencyContacts).insert(
          EmergencyContactsCompanion(
            id: ec['id'] != null
                ? Value(ec['id'] as int)
                : const Value.absent(),
            name: Value(ec['name'] as String? ?? ''),
            phoneNumber: Value(ec['phoneNumber'] as String? ?? ''),
            relationship: Value(
              Relationship.values[ec['relationship'] as int? ?? 0],
            ),
            isPrimary: Value(ec['isPrimary'] as bool? ?? false),
            personId: Value(ec['personId'] as int),
          ),
        );
      }

      // Import service reports
      for (final sr in (data['serviceReports'] as List? ?? [])) {
        await into(serviceReports).insert(
          ServiceReportsCompanion(
            id: sr['id'] != null
                ? Value(sr['id'] as int)
                : const Value.absent(),
            year: Value(sr['year'] as int),
            month: Value(sr['month'] as int),
            personId: Value(sr['personId'] as int),
            isAuxiliaryPioneer: Value(
              sr['isAuxiliaryPioneer'] as bool? ?? false,
            ),
            isActive: Value(sr['isActive'] as bool? ?? true),
            sharedInMinistry: Value(sr['sharedInMinistry'] as bool? ?? false),
            bibleStudies: Value(sr['bibleStudies'] as int? ?? 0),
            hours: Value((sr['hours'] as num?)?.toDouble() ?? 0.0),
            note: Value(sr['note'] as String? ?? ''),
          ),
        );
      }

      // Import auxiliary pioneer periods
      for (final ap in (data['auxiliaryPioneerPeriods'] as List? ?? [])) {
        await into(auxiliaryPioneerPeriods).insert(
          AuxiliaryPioneerPeriodsCompanion(
            id: ap['id'] != null
                ? Value(ap['id'] as int)
                : const Value.absent(),
            startMonth: Value(ap['startMonth'] as int),
            startYear: Value(ap['startYear'] as int),
            endMonth: Value(ap['endMonth'] as int?),
            endYear: Value(ap['endYear'] as int?),
            personId: Value(ap['personId'] as int),
          ),
        );
      }
    });
  }
}

enum _ApplyOutcome { applied, unchanged, deferred }

class _LocalRef {
  const _LocalRef(this.id, this.serverVersion);

  final int id;
  final int serverVersion;
}

/// Sync id → local row id and server version for every synced table. Loaded
/// once per batch so thousands of pulled changes need no per-row lookups,
/// and updated as rows are inserted so children find parents from the same
/// batch.
class _SyncIndex {
  _SyncIndex._(this._byType);

  static const _tables = {
    SyncEntityTypes.congregation: 'congregations',
    SyncEntityTypes.fieldServiceGroup: 'field_service_groups',
    SyncEntityTypes.person: 'persons',
    SyncEntityTypes.phoneNumber: 'phone_numbers',
    SyncEntityTypes.emergencyContact: 'emergency_contacts',
    SyncEntityTypes.serviceReport: 'service_reports',
    SyncEntityTypes.auxiliaryPioneerPeriod: 'auxiliary_pioneer_periods',
  };

  final Map<String, Map<String, _LocalRef>> _byType;

  static Future<_SyncIndex> load(AppDatabase database) async {
    final byType = <String, Map<String, _LocalRef>>{};
    for (final MapEntry(key: type, value: table) in _tables.entries) {
      final rows = await database
          .customSelect(
            'SELECT id, sync_id, server_version FROM $table '
            'WHERE sync_id IS NOT NULL',
          )
          .get();
      byType[type] = {
        for (final row in rows)
          row.read<String>('sync_id'): _LocalRef(
            row.read<int>('id'),
            row.read<int>('server_version'),
          ),
      };
    }
    return _SyncIndex._(byType);
  }

  _LocalRef? find(String type, String? syncId) =>
      syncId == null || syncId.isEmpty ? null : _byType[type]?[syncId];

  int? idOf(String type, String? syncId) => find(type, syncId)?.id;

  Iterable<MapEntry<String, _LocalRef>> entries(String type) =>
      _byType[type]?.entries ?? const [];

  void put(String type, String syncId, int id, int serverVersion) =>
      _byType[type]![syncId] = _LocalRef(id, serverVersion);

  void remove(String type, String syncId) => _byType[type]?.remove(syncId);
}
