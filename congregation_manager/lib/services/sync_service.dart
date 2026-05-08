import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:congregation_manager/data/database.dart';

class SyncResult {
  final int pushed;
  final int pulled;
  final int conflicts;

  const SyncResult({
    required this.pushed,
    required this.pulled,
    required this.conflicts,
  });
}

class SyncService {
  final AppDatabase _db;
  final http.Client _client;

  SyncService(this._db, {http.Client? client})
    : _client = client ?? http.Client();

  Future<SyncResult> syncNow() async {
    final settings = await _db.getSyncSettings();
    final serverUrl = settings.serverUrl?.trim();
    if (!settings.isEnabled || serverUrl == null || serverUrl.isEmpty) {
      return const SyncResult(pushed: 0, pulled: 0, conflicts: 0);
    }

    try {
      final pushed = await _pushPendingChanges(serverUrl, settings);
      final pulled = await _pullRemoteChanges(serverUrl, settings);
      await _db.recordSyncSuccess(pullCursor: pulled.cursor);
      return SyncResult(
        pushed: pushed.accepted,
        pulled: pulled.applied,
        conflicts: pushed.conflicts,
      );
    } catch (error) {
      await _db.recordSyncError(error.toString());
      rethrow;
    }
  }

  Future<_PushResult> _pushPendingChanges(
    String serverUrl,
    SyncSetting settings,
  ) async {
    final operations = await _db.getPendingSyncOperations();
    if (operations.isEmpty) return const _PushResult(accepted: 0, conflicts: 0);

    final operationById = {for (final op in operations) op.operationId: op};
    final response = await _client.post(
      _endpoint(serverUrl, '/api/v1/sync/push'),
      headers: _headers(settings),
      body: jsonEncode({
        'deviceId': settings.deviceId,
        'operations': operations
            .map(
              (op) => {
                'operationId': op.operationId,
                'entityType': op.entityType,
                'entitySyncId': op.entitySyncId,
                'operationType': op.operationType,
                'baseServerVersion': op.baseServerVersion,
                'payload': jsonDecode(op.payloadJson),
              },
            )
            .toList(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.body.isEmpty
          ? response.reasonPhrase
          : response.body;
      for (final op in operations) {
        await _db.markSyncOperationFailed(op.id, message ?? 'Sync push failed');
      }
      throw StateError(
        'Sync push failed: ${response.statusCode} ${message ?? ''}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    var acceptedCount = 0;
    for (final accepted in _list(body, 'acceptedOperations')) {
      final operationId = _string(accepted, 'operationId');
      final operation = operationById[operationId];
      if (operation == null) continue;

      await _db.markEntitySynced(
        entityType: _string(accepted, 'entityType') ?? operation.entityType,
        entitySyncId:
            _string(accepted, 'entitySyncId') ?? operation.entitySyncId,
        serverVersion:
            _int(accepted, 'serverVersion') ?? operation.baseServerVersion ?? 0,
      );
      await _db.markSyncOperationSucceeded(operation.id);
      acceptedCount++;
    }

    var conflictCount = 0;
    for (final conflict in _list(body, 'conflicts')) {
      final operationId = _string(conflict, 'operationId');
      final operation = operationById[operationId];
      if (operation == null) continue;

      await _db.recordSyncConflict(
        entityType: operation.entityType,
        entitySyncId: operation.entitySyncId,
        localPayload: jsonDecode(operation.payloadJson) as Map<String, dynamic>,
        serverPayload: _map(conflict, 'serverPayload'),
        serverVersion: _int(conflict, 'serverVersion') ?? 0,
      );
      await _db.markSyncOperationSucceeded(operation.id);
      conflictCount++;
    }

    return _PushResult(accepted: acceptedCount, conflicts: conflictCount);
  }

  Future<_PullResult> _pullRemoteChanges(
    String serverUrl,
    SyncSetting settings,
  ) async {
    final cursor = settings.pullCursor;
    final uri = _endpoint(serverUrl, '/api/v1/sync/pull').replace(
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    final response = await _client.get(uri, headers: _headers(settings));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.body.isEmpty
          ? response.reasonPhrase
          : response.body;
      throw StateError(
        'Sync pull failed: ${response.statusCode} ${message ?? ''}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    var applied = 0;
    for (final change in _list(body, 'changes')) {
      final payload = _map(change, 'payload');
      final entityType = _string(change, 'entityType');
      final syncId =
          _string(change, 'entitySyncId') ?? _string(change, 'syncId');
      final operationType = _string(change, 'operationType') ?? 'upsert';
      final serverVersion = _int(change, 'serverVersion') ?? 0;
      if (entityType == null || syncId == null) continue;

      await _db.applyRemoteChange(
        entityType: entityType,
        operationType: operationType,
        entitySyncId: syncId,
        serverVersion: serverVersion,
        payload: payload,
      );
      applied++;
    }

    return _PullResult(
      applied: applied,
      cursor: _string(body, 'cursor') ?? cursor,
    );
  }

  Uri _endpoint(String serverUrl, String path) {
    final base = Uri.parse(
      serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl,
    );
    return base.replace(path: '${base.path}$path');
  }

  Map<String, String> _headers(SyncSetting settings) {
    final token = settings.bearerToken?.trim();
    return {
      'Content-Type': 'application/json',
      if (settings.deviceId?.isNotEmpty == true)
        'X-Device-Id': settings.deviceId!,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (token != null && token.isNotEmpty) 'X-Sync-Token': token,
    };
  }

  static List<Map<String, dynamic>> _list(
    Map<String, dynamic> source,
    String key,
  ) {
    final value = source[key] ?? source[_pascal(key)];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  static Map<String, dynamic> _map(Map<String, dynamic> source, String key) {
    final value = source[key] ?? source[_pascal(key)];
    if (value is Map) return value.cast<String, dynamic>();
    return const {};
  }

  static String? _string(Map<String, dynamic> source, String key) {
    final value = source[key] ?? source[_pascal(key)];
    return value?.toString();
  }

  static int? _int(Map<String, dynamic> source, String key) {
    final value = source[key] ?? source[_pascal(key)];
    return value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
  }

  static String _pascal(String key) => key.isEmpty
      ? key
      : '${key.substring(0, 1).toUpperCase()}${key.substring(1)}';
}

class _PushResult {
  final int accepted;
  final int conflicts;

  const _PushResult({required this.accepted, required this.conflicts});
}

class _PullResult {
  final int applied;
  final String? cursor;

  const _PullResult({required this.applied, required this.cursor});
}
