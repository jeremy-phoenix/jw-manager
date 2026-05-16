import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:congregation_manager/data/tables.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/data/statistics.dart';
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
  int get schemaVersion => 4;

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
    },
  );

  Future<void> _addSyncColumns(Migrator m, TableInfo table) async {
    await m.addColumn(
      table,
      table.$columns.firstWhere((c) => c.name == 'sync_id'),
    );
    await m.addColumn(
      table,
      table.$columns.firstWhere((c) => c.name == 'server_version'),
    );
    await m.addColumn(
      table,
      table.$columns.firstWhere((c) => c.name == 'deleted_at'),
    );
    await m.addColumn(
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
  // Sync settings and queue helpers
  // ──────────────────────────────────────────────────

  Future<SyncSetting> getSyncSettings() async => _ensureSyncSettings();

  Stream<SyncSetting> watchSyncSettings() async* {
    await _ensureSyncSettings();
    yield* select(syncSettings).watchSingle();
  }

  Future<SyncSetting> saveSyncSettings({
    required bool isEnabled,
    required String serverUrl,
    String? bearerToken,
  }) async {
    final current = await _ensureSyncSettings();
    final shouldQueueInitialSnapshot = isEnabled && !current.isEnabled;
    await into(syncSettings).insertOnConflictUpdate(
      SyncSettingsCompanion(
        id: const Value(1),
        isEnabled: Value(isEnabled),
        serverUrl: Value(serverUrl.trim().isEmpty ? null : serverUrl.trim()),
        bearerToken: Value(
          bearerToken == null || bearerToken.trim().isEmpty
              ? null
              : bearerToken.trim(),
        ),
        deviceId: Value(current.deviceId),
        pullCursor: Value(current.pullCursor),
        lastSyncAt: Value(current.lastSyncAt),
        lastError: const Value(null),
      ),
    );
    if (shouldQueueInitialSnapshot) {
      await queueLocalSnapshotForSync();
    }
    return _ensureSyncSettings();
  }

  Future<void> queueLocalSnapshotForSync() async {
    await _ensureAllLocalSyncIds();

    for (final row in await select(congregations).get()) {
      await _queueOperationIfEnabled(
        entityType: 'congregation',
        entitySyncId: row.syncId!,
        operationType: 'upsert',
        payload: _congregationPayload(row),
        baseServerVersion: row.serverVersion,
      );
    }
    for (final row in await select(fieldServiceGroups).get()) {
      await _queueOperationIfEnabled(
        entityType: 'fieldServiceGroup',
        entitySyncId: row.syncId!,
        operationType: 'upsert',
        payload: await _fieldServiceGroupPayload(row),
        baseServerVersion: row.serverVersion,
      );
    }
    for (final row in await select(persons).get()) {
      await _queueOperationIfEnabled(
        entityType: 'person',
        entitySyncId: row.syncId!,
        operationType: 'upsert',
        payload: await _personPayload(row),
        baseServerVersion: row.serverVersion,
      );
    }
    for (final row in await select(phoneNumbers).get()) {
      await _queueOperationIfEnabled(
        entityType: 'phoneNumber',
        entitySyncId: row.syncId!,
        operationType: 'upsert',
        payload: await _phoneNumberPayload(row),
        baseServerVersion: row.serverVersion,
      );
    }
    for (final row in await select(emergencyContacts).get()) {
      await _queueOperationIfEnabled(
        entityType: 'emergencyContact',
        entitySyncId: row.syncId!,
        operationType: 'upsert',
        payload: await _emergencyContactPayload(row),
        baseServerVersion: row.serverVersion,
      );
    }
    for (final row in await select(serviceReports).get()) {
      await _queueOperationIfEnabled(
        entityType: 'serviceReport',
        entitySyncId: row.syncId!,
        operationType: 'upsert',
        payload: await _serviceReportPayload(row),
        baseServerVersion: row.serverVersion,
      );
    }
    for (final row in await select(auxiliaryPioneerPeriods).get()) {
      await _queueOperationIfEnabled(
        entityType: 'auxiliaryPioneerPeriod',
        entitySyncId: row.syncId!,
        operationType: 'upsert',
        payload: await _auxiliaryPioneerPeriodPayload(row),
        baseServerVersion: row.serverVersion,
      );
    }
  }

  Future<void> recordSyncSuccess({String? pullCursor}) async {
    final current = await _ensureSyncSettings();
    await into(syncSettings).insertOnConflictUpdate(
      current
          .toCompanion(false)
          .copyWith(
            lastSyncAt: Value(DateTime.now().toUtc()),
            pullCursor: Value(pullCursor ?? current.pullCursor),
            lastError: const Value(null),
          ),
    );
  }

  Future<void> recordSyncError(String error) async {
    final current = await _ensureSyncSettings();
    await into(syncSettings).insertOnConflictUpdate(
      current.toCompanion(false).copyWith(lastError: Value(error)),
    );
  }

  Future<int> getPendingSyncOperationCount() async {
    final rows = await select(pendingSyncOperations).get();
    return rows.length;
  }

  Stream<int> watchPendingSyncOperationCount() =>
      select(pendingSyncOperations).watch().map((rows) => rows.length);

  Future<int> getOpenSyncConflictCount() async {
    final rows = await (select(
      syncConflicts,
    )..where((c) => c.resolvedAt.isNull())).get();
    return rows.length;
  }

  Stream<int> watchOpenSyncConflictCount() => (select(
    syncConflicts,
  )..where((c) => c.resolvedAt.isNull())).watch().map((rows) => rows.length);

  Future<List<PendingSyncOperation>> getPendingSyncOperations({
    int limit = 50,
  }) =>
      (select(pendingSyncOperations)
            ..orderBy([(o) => OrderingTerm.asc(o.id)])
            ..limit(limit))
          .get();

  Future<void> markSyncOperationSucceeded(int id) =>
      (delete(pendingSyncOperations)..where((o) => o.id.equals(id))).go();

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

  Future<void> recordSyncConflict({
    required String entityType,
    required String entitySyncId,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverPayload,
    required int serverVersion,
  }) async {
    await into(syncConflicts).insert(
      SyncConflictsCompanion.insert(
        entityType: entityType,
        entitySyncId: entitySyncId,
        localPayloadJson: jsonEncode(localPayload),
        serverPayloadJson: jsonEncode(serverPayload),
        serverVersion: serverVersion,
      ),
    );
  }

  Future<void> markEntitySynced({
    required String entityType,
    required String entitySyncId,
    required int serverVersion,
  }) async {
    final syncedAt = DateTime.now().toUtc();
    switch (entityType) {
      case 'congregation':
        await (update(
          congregations,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          CongregationsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      case 'fieldServiceGroup':
        await (update(
          fieldServiceGroups,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          FieldServiceGroupsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      case 'person':
        await (update(
          persons,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          PersonsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      case 'phoneNumber':
        await (update(
          phoneNumbers,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          PhoneNumbersCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      case 'emergencyContact':
        await (update(
          emergencyContacts,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          EmergencyContactsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      case 'serviceReport':
        await (update(
          serviceReports,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          ServiceReportsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: Value(syncedAt),
          ),
        );
      case 'auxiliaryPioneerPeriod':
        await (update(
          auxiliaryPioneerPeriods,
        )..where((t) => t.syncId.equals(entitySyncId))).write(
          AuxiliaryPioneerPeriodsCompanion(
            serverVersion: Value(serverVersion),
            lastSyncedAt: Value(syncedAt),
          ),
        );
    }
  }

  Future<void> applyRemoteChange({
    required String entityType,
    required String operationType,
    required String entitySyncId,
    required int serverVersion,
    required Map<String, dynamic> payload,
  }) async {
    final syncedAt = DateTime.now().toUtc();
    if (operationType == 'delete') {
      await _deleteLocalBySyncId(entityType, entitySyncId);
      return;
    }

    switch (entityType) {
      case 'congregation':
        final existingId = await _congregationIdBySyncId(entitySyncId);
        final companion = CongregationsCompanion(
          id: existingId == null ? const Value.absent() : Value(existingId),
          syncId: Value(entitySyncId),
          serverVersion: Value(serverVersion),
          lastSyncedAt: Value(syncedAt),
          deletedAt: Value(_date(payload['deletedAt'])),
          name: Value(_string(payload['name']) ?? ''),
          number: Value(_string(payload['number']) ?? ''),
          city: Value(_string(payload['city']) ?? ''),
          circuitNumber: Value(_string(payload['circuitNumber']) ?? ''),
        );
        if (existingId == null) {
          await into(congregations).insert(companion);
        } else {
          await update(congregations).replace(companion);
        }
      case 'fieldServiceGroup':
        final existingId = await _fieldServiceGroupIdBySyncId(entitySyncId);
        final companion = FieldServiceGroupsCompanion(
          id: existingId == null ? const Value.absent() : Value(existingId),
          syncId: Value(entitySyncId),
          serverVersion: Value(serverVersion),
          lastSyncedAt: Value(syncedAt),
          deletedAt: Value(_date(payload['deletedAt'])),
          name: Value(_string(payload['name']) ?? ''),
          description: Value(_string(payload['description']) ?? ''),
          congregationId: Value(
            await _congregationIdBySyncId(
              _string(payload['congregationSyncId']),
            ),
          ),
          groupOverseerId: Value(
            await _personIdBySyncId(_string(payload['groupOverseerSyncId'])),
          ),
          assistantId: Value(
            await _personIdBySyncId(_string(payload['assistantSyncId'])),
          ),
        );
        if (existingId == null) {
          await into(fieldServiceGroups).insert(companion);
        } else {
          await update(fieldServiceGroups).replace(companion);
        }
      case 'person':
        final existingId = await _personIdBySyncId(entitySyncId);
        final companion = PersonsCompanion(
          id: existingId == null ? const Value.absent() : Value(existingId),
          syncId: Value(entitySyncId),
          serverVersion: Value(serverVersion),
          lastSyncedAt: Value(syncedAt),
          deletedAt: Value(_date(payload['deletedAt'])),
          firstName: Value(_string(payload['firstName']) ?? ''),
          lastName: Value(_string(payload['lastName']) ?? ''),
          otherNames: Value(_string(payload['otherNames']) ?? ''),
          birthDate: Value(_date(payload['birthDate'])),
          baptismDate: Value(_date(payload['baptismDate'])),
          gender: Value(
            _enumAt(Gender.values, payload['gender'], Gender.unknown),
          ),
          hopeClass: Value(
            _enumAt(HopeClass.values, payload['hopeClass'], HopeClass.unknown),
          ),
          congregationRole: Value(
            _enumAt(
              CongregationRole.values,
              payload['congregationRole'],
              CongregationRole.none,
            ),
          ),
          pioneerType: Value(
            _enumAt(
              PioneerType.values,
              payload['pioneerType'],
              PioneerType.none,
            ),
          ),
          address: Value(_string(payload['address']) ?? ''),
          isActive: Value(_bool(payload['isActive']) ?? true),
          inactiveDate: Value(_date(payload['inactiveDate'])),
          congregationId: Value(
            await _congregationIdBySyncId(
              _string(payload['congregationSyncId']),
            ),
          ),
          fieldServiceGroupId: Value(
            await _fieldServiceGroupIdBySyncId(
              _string(payload['fieldServiceGroupSyncId']),
            ),
          ),
        );
        if (existingId == null) {
          await into(persons).insert(companion);
        } else {
          await update(persons).replace(companion);
        }
      case 'phoneNumber':
        final personId = await _personIdBySyncId(
          _string(payload['personSyncId']),
        );
        if (personId == null) return;
        final existingId = await _phoneNumberIdBySyncId(entitySyncId);
        final companion = PhoneNumbersCompanion(
          id: existingId == null ? const Value.absent() : Value(existingId),
          syncId: Value(entitySyncId),
          serverVersion: Value(serverVersion),
          lastSyncedAt: Value(syncedAt),
          deletedAt: Value(_date(payload['deletedAt'])),
          number: Value(_string(payload['number']) ?? ''),
          phoneType: Value(
            _enumAt(PhoneType.values, payload['phoneType'], PhoneType.mobile),
          ),
          isPrimary: Value(_bool(payload['isPrimary']) ?? false),
          personId: Value(personId),
        );
        if (existingId == null) {
          await into(phoneNumbers).insert(companion);
        } else {
          await update(phoneNumbers).replace(companion);
        }
      case 'emergencyContact':
        final personId = await _personIdBySyncId(
          _string(payload['personSyncId']),
        );
        if (personId == null) return;
        final existingId = await _emergencyContactIdBySyncId(entitySyncId);
        final companion = EmergencyContactsCompanion(
          id: existingId == null ? const Value.absent() : Value(existingId),
          syncId: Value(entitySyncId),
          serverVersion: Value(serverVersion),
          lastSyncedAt: Value(syncedAt),
          deletedAt: Value(_date(payload['deletedAt'])),
          name: Value(_string(payload['name']) ?? ''),
          phoneNumber: Value(_string(payload['phoneNumber']) ?? ''),
          relationship: Value(
            _enumAt(
              Relationship.values,
              payload['relationship'],
              Relationship.other,
            ),
          ),
          isPrimary: Value(_bool(payload['isPrimary']) ?? false),
          personId: Value(personId),
        );
        if (existingId == null) {
          await into(emergencyContacts).insert(companion);
        } else {
          await update(emergencyContacts).replace(companion);
        }
      case 'serviceReport':
        final personId = await _personIdBySyncId(
          _string(payload['personSyncId']),
        );
        if (personId == null) return;
        final existingId = await _serviceReportIdBySyncId(entitySyncId);
        final companion = ServiceReportsCompanion(
          id: existingId == null ? const Value.absent() : Value(existingId),
          syncId: Value(entitySyncId),
          serverVersion: Value(serverVersion),
          lastSyncedAt: Value(syncedAt),
          deletedAt: Value(_date(payload['deletedAt'])),
          year: Value(_int(payload['year']) ?? DateTime.now().year),
          month: Value(_int(payload['month']) ?? DateTime.now().month),
          isAuxiliaryPioneer: Value(
            _bool(payload['isAuxiliaryPioneer']) ?? false,
          ),
          isActive: Value(_bool(payload['isActive']) ?? true),
          sharedInMinistry: Value(_bool(payload['sharedInMinistry']) ?? false),
          bibleStudies: Value(_int(payload['bibleStudies']) ?? 0),
          hours: Value(_double(payload['hours']) ?? 0),
          note: Value(_string(payload['note']) ?? ''),
          personId: Value(personId),
        );
        if (existingId == null) {
          await into(serviceReports).insert(companion);
        } else {
          await update(serviceReports).replace(companion);
        }
      case 'auxiliaryPioneerPeriod':
        final personId = await _personIdBySyncId(
          _string(payload['personSyncId']),
        );
        if (personId == null) return;
        final existingId = await _auxiliaryPioneerPeriodIdBySyncId(
          entitySyncId,
        );
        final companion = AuxiliaryPioneerPeriodsCompanion(
          id: existingId == null ? const Value.absent() : Value(existingId),
          syncId: Value(entitySyncId),
          serverVersion: Value(serverVersion),
          lastSyncedAt: Value(syncedAt),
          deletedAt: Value(_date(payload['deletedAt'])),
          startMonth: Value(_int(payload['startMonth']) ?? 1),
          startYear: Value(_int(payload['startYear']) ?? DateTime.now().year),
          endMonth: Value(_int(payload['endMonth'])),
          endYear: Value(_int(payload['endYear'])),
          personId: Value(personId),
        );
        if (existingId == null) {
          await into(auxiliaryPioneerPeriods).insert(companion);
        } else {
          await update(auxiliaryPioneerPeriods).replace(companion);
        }
    }
  }

  Future<void> _deleteLocalBySyncId(String entityType, String syncId) async {
    switch (entityType) {
      case 'congregation':
        await (delete(
          congregations,
        )..where((t) => t.syncId.equals(syncId))).go();
      case 'fieldServiceGroup':
        await (delete(
          fieldServiceGroups,
        )..where((t) => t.syncId.equals(syncId))).go();
      case 'person':
        await (delete(persons)..where((t) => t.syncId.equals(syncId))).go();
      case 'phoneNumber':
        await (delete(
          phoneNumbers,
        )..where((t) => t.syncId.equals(syncId))).go();
      case 'emergencyContact':
        await (delete(
          emergencyContacts,
        )..where((t) => t.syncId.equals(syncId))).go();
      case 'serviceReport':
        await (delete(
          serviceReports,
        )..where((t) => t.syncId.equals(syncId))).go();
      case 'auxiliaryPioneerPeriod':
        await (delete(
          auxiliaryPioneerPeriods,
        )..where((t) => t.syncId.equals(syncId))).go();
    }
  }

  Future<int?> _congregationIdBySyncId(String? syncId) async {
    if (syncId == null || syncId.isEmpty) return null;
    return (await (select(
      congregations,
    )..where((t) => t.syncId.equals(syncId))).getSingleOrNull())?.id;
  }

  Future<int?> _fieldServiceGroupIdBySyncId(String? syncId) async {
    if (syncId == null || syncId.isEmpty) return null;
    return (await (select(
      fieldServiceGroups,
    )..where((t) => t.syncId.equals(syncId))).getSingleOrNull())?.id;
  }

  Future<int?> _personIdBySyncId(String? syncId) async {
    if (syncId == null || syncId.isEmpty) return null;
    return (await (select(
      persons,
    )..where((t) => t.syncId.equals(syncId))).getSingleOrNull())?.id;
  }

  Future<int?> _phoneNumberIdBySyncId(String syncId) async => (await (select(
    phoneNumbers,
  )..where((t) => t.syncId.equals(syncId))).getSingleOrNull())?.id;

  Future<int?> _emergencyContactIdBySyncId(String syncId) async =>
      (await (select(
        emergencyContacts,
      )..where((t) => t.syncId.equals(syncId))).getSingleOrNull())?.id;

  Future<int?> _serviceReportIdBySyncId(String syncId) async => (await (select(
    serviceReports,
  )..where((t) => t.syncId.equals(syncId))).getSingleOrNull())?.id;

  Future<int?> _auxiliaryPioneerPeriodIdBySyncId(String syncId) async =>
      (await (select(
        auxiliaryPioneerPeriods,
      )..where((t) => t.syncId.equals(syncId))).getSingleOrNull())?.id;

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

  Future<SyncSetting> _ensureSyncSettings() async {
    final existing = await select(syncSettings).getSingleOrNull();
    if (existing != null && (existing.deviceId?.isNotEmpty ?? false)) {
      return existing;
    }

    final deviceId = existing?.deviceId?.isNotEmpty == true
        ? existing!.deviceId!
        : _uuid.v4();
    await into(syncSettings).insertOnConflictUpdate(
      SyncSettingsCompanion(
        id: const Value(1),
        isEnabled: Value(existing?.isEnabled ?? false),
        serverUrl: Value(existing?.serverUrl),
        bearerToken: Value(existing?.bearerToken),
        deviceId: Value(deviceId),
        pullCursor: Value(existing?.pullCursor),
        lastSyncAt: Value(existing?.lastSyncAt),
        lastError: Value(existing?.lastError),
      ),
    );
    return select(syncSettings).getSingle();
  }

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

  Future<void> _queueOperationIfEnabled({
    required String entityType,
    required String entitySyncId,
    required String operationType,
    required Map<String, dynamic> payload,
    int? baseServerVersion,
  }) async {
    final settings = await _ensureSyncSettings();
    if (!settings.isEnabled) return;

    await into(pendingSyncOperations).insert(
      PendingSyncOperationsCompanion.insert(
        operationId: _uuid.v4(),
        entityType: entityType,
        entitySyncId: entitySyncId,
        operationType: operationType,
        payloadJson: jsonEncode(payload),
        baseServerVersion: Value(baseServerVersion),
      ),
    );
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

  Map<String, dynamic> _congregationPayload(Congregation row) => {
    'syncId': row.syncId,
    'serverVersion': row.serverVersion,
    'name': row.name,
    'number': row.number,
    'city': row.city,
    'circuitNumber': row.circuitNumber,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
    'deletedAt': row.deletedAt?.toUtc().toIso8601String(),
  };

  Future<Map<String, dynamic>> _fieldServiceGroupPayload(
    FieldServiceGroup row,
  ) async => {
    'syncId': row.syncId,
    'serverVersion': row.serverVersion,
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
    'serverVersion': row.serverVersion,
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
    'isActive': row.isActive,
    'inactiveDate': row.inactiveDate?.toUtc().toIso8601String(),
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
    'serverVersion': row.serverVersion,
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
    'serverVersion': row.serverVersion,
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
        'serverVersion': row.serverVersion,
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
    'serverVersion': row.serverVersion,
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

  Future<Congregation> getCongregation(int id) =>
      (select(congregations)..where((c) => c.id.equals(id))).getSingle();

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

  Future<List<Person>> getAllPersons({int? congregationId}) {
    final query = select(persons);
    if (congregationId != null) {
      query.where((p) => p.congregationId.equals(congregationId));
    }
    query.orderBy([
      (p) => OrderingTerm(expression: p.lastName),
      (p) => OrderingTerm(expression: p.firstName),
    ]);
    return query.get();
  }

  Stream<List<Person>> watchAllPersons({int? congregationId}) {
    final query = select(persons);
    if (congregationId != null) {
      query.where((p) => p.congregationId.equals(congregationId));
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

  Future<int> deletePerson(int id) async {
    final existing = await getPerson(id);
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
    final personQuery = select(persons)..where((p) => p.isActive.equals(true));
    if (congregationId != null) {
      personQuery.where((p) => p.congregationId.equals(congregationId));
    }
    final allActive = await personQuery.get();

    // Also include persons who became inactive during or after this month
    final inactiveQuery = select(persons)
      ..where((p) => p.isActive.equals(false));
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
    final existing = await getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final existingPersonIds = existing.map((r) => r.personId).toSet();

    for (final person in allPersons) {
      if (!existingPersonIds.contains(person.id)) {
        await insertServiceReport(
          ServiceReportsCompanion.insert(
            year: year,
            month: month,
            personId: person.id,
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

  /// Get month statistics for a given service year and month.
  Future<FieldServiceReportStatistics> getMonthStatistics(
    int year,
    int month, {
    int? congregationId,
  }) async {
    final personQuery = select(persons)..where((p) => p.isActive.equals(true));
    if (congregationId != null) {
      personQuery.where((p) => p.congregationId.equals(congregationId));
    }
    final activePersons = await personQuery.get();

    final reports = await getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final activeReports = reports.where((r) {
      return r.sharedInMinistry || r.hours > 0 || r.bibleStudies > 0;
    }).toList();

    // Build a set of person IDs that are regular/special pioneers
    final pioneerPersonIds = <int>{};
    for (final p in activePersons) {
      if (p.pioneerType == PioneerType.regularPioneer ||
          p.pioneerType == PioneerType.specialPioneer ||
          p.pioneerType == PioneerType.fieldMissionary) {
        pioneerPersonIds.add(p.id);
      }
    }

    final publishers = activeReports
        .where(
          (r) =>
              !r.isAuxiliaryPioneer && !pioneerPersonIds.contains(r.personId),
        )
        .toList();
    final auxPioneers = activeReports
        .where((r) => r.isAuxiliaryPioneer)
        .toList();
    final regPioneers = activeReports
        .where(
          (r) => pioneerPersonIds.contains(r.personId) && !r.isAuxiliaryPioneer,
        )
        .toList();

    return FieldServiceReportStatistics(
      allActivePublishers: activePersons.length,
      publishers: ReportMetrics(
        numberOfReports: publishers.length,
        bibleStudies: publishers.fold(0, (sum, r) => sum + r.bibleStudies),
        hours: 0,
      ),
      auxiliaryPioneers: ReportMetrics(
        numberOfReports: auxPioneers.length,
        bibleStudies: auxPioneers.fold(0, (sum, r) => sum + r.bibleStudies),
        hours: auxPioneers.fold(0.0, (sum, r) => sum + r.hours),
      ),
      regularPioneers: ReportMetrics(
        numberOfReports: regPioneers.length,
        bibleStudies: regPioneers.fold(0, (sum, r) => sum + r.bibleStudies),
        hours: regPioneers.fold(0.0, (sum, r) => sum + r.hours),
      ),
    );
  }

  /// Get congregation analysis summary.
  Future<CongregationAnalysis> getCongregationAnalysis({
    int? congregationId,
  }) async {
    final personQuery = select(persons)..where((p) => p.isActive.equals(true));
    if (congregationId != null) {
      personQuery.where((p) => p.congregationId.equals(congregationId));
    }
    final activePersons = await personQuery.get();

    int activeCount = 0;
    int newInactive = 0;
    int reactivated = 0;

    for (final person in activePersons) {
      final reports = await getServiceReports(personId: person.id);
      // Order by service year index
      reports.sort((a, b) {
        final aIdx = _serviceYearIndex(a.year, a.month);
        final bIdx = _serviceYearIndex(b.year, b.month);
        return aIdx.compareTo(bIdx);
      });

      final sharedList = reports.map((r) => r.sharedInMinistry).toList();
      if (sharedList.isEmpty) continue;

      // Active: shared in any of the last 6 reports
      final last6 = sharedList.length > 6
          ? sharedList.sublist(sharedList.length - 6)
          : sharedList;
      final isActive = last6.any((s) => s);
      if (isActive) activeCount++;

      // Find inactivity streak (6+ consecutive not shared)
      final (hasStreak, streakEndIndex) = _findInactivityStreak(sharedList);

      if (hasStreak && !isActive) {
        newInactive++;
      }

      if (hasStreak && streakEndIndex < sharedList.length - 1) {
        final sharedAfter = sharedList
            .sublist(streakEndIndex + 1)
            .any((s) => s);
        if (sharedAfter) reactivated++;
      }
    }

    return CongregationAnalysis(
      allActivePublishers: activeCount,
      newInactivePublishers: newInactive,
      reactivatedPublishers: reactivated,
    );
  }

  static int _serviceYearIndex(int year, int month) {
    final sy = month >= 9 ? year + 1 : year;
    final sm = month >= 9 ? month - 8 : month + 4;
    return sy * 12 + sm;
  }

  static (bool, int) _findInactivityStreak(List<bool> reports) {
    var consecutive = 0;
    for (var i = 0; i < reports.length; i++) {
      if (reports[i]) {
        consecutive = 0;
      } else {
        consecutive++;
        if (consecutive >= 6) return (true, i);
      }
    }
    return (false, -1);
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

    if (isOldFormat) {
      await _importOldFormat(data);
    } else {
      await _importNativeFormat(data);
    }
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
