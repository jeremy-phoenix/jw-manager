import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory stand-in for CongregationManager.Server, speaking the same
/// wire protocol and enforcing the same rules, so multi-device sync can be
/// tested without a network.
class FakeSyncServer {
  FakeSyncServer({
    this.registrationSecret = 'registration-secret-for-tests-0000',
  });

  final String registrationSecret;
  final vaults = <String, FakeVault>{};
  final devices = <String, _Device>{}; // by token hash
  final _invites = <String, _Invite>{}; // by code hash

  /// Every request body received, to prove plaintext never reaches the server.
  final requestBodies = <String>[];
  DateTime now = DateTime.utc(2026, 9, 1, 12);

  final _random = Random.secure();

  http.Client get client => MockClient(_handle);

  Iterable<FakeRecord> recordsOf(String vaultId) =>
      vaults[vaultId]!.records.values;

  Future<http.Response> _handle(http.Request request) async {
    requestBodies.add(request.body);
    final path = request.url.path;
    final body = request.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;

    switch ((request.method, path)) {
      case ('POST', '/api/v1/vaults'):
        return _createVault(request, body);
      case ('POST', '/api/v1/devices/enroll'):
        return _enrollWithInvite(body);
      case ('POST', '/api/v1/recovery/enroll'):
        return _enrollWithRecovery(body);
    }

    final device = _authenticate(request);
    if (device == null) return _error(401, 'UNAUTHORIZED');
    final vault = vaults[device.vaultId]!;

    switch ((request.method, path)) {
      case ('GET', '/api/v1/vault'):
        return _json(200, {
          'vaultId': vault.id,
          'currentKeyId': vault.currentKeyId,
          'seq': vault.seq,
          'recoveryEnvelope': vault.recoveryEnvelope,
          'createdAt': now.toIso8601String(),
        });
      case ('POST', '/api/v1/vault/delete'):
        if (!_recoveryMatches(vault, body['recoveryAuthKey'])) {
          return _error(403, 'INVALID_RECOVERY_KEY');
        }
        vaults.remove(vault.id);
        devices.removeWhere((_, d) => d.vaultId == vault.id);
        _invites.removeWhere((_, i) => i.vaultId == vault.id);
        return http.Response('', 204);
      case ('GET', '/api/v1/devices'):
        return _json(200, {
          'devices': [
            for (final d in devices.values.where(
              (d) => d.vaultId == vault.id && !d.revoked,
            ))
              {
                'deviceId': d.id,
                'label': d.label,
                'labelKeyId': d.labelKeyId,
                'enrolledVia': d.enrolledVia,
                'createdAt': now.toIso8601String(),
                'lastSeenAt': now.toIso8601String(),
                'current': d.id == device.id,
              },
          ],
        });
      case ('POST', '/api/v1/invites'):
        final code = _token();
        final minutes = body['expiresInMinutes'] as int? ?? 60;
        final expiresAt = now.add(Duration(minutes: minutes));
        _invites[_hash(code)] = _Invite(vault.id, expiresAt);
        return _json(201, {
          'inviteCode': code,
          'expiresAt': expiresAt.toIso8601String(),
        });
      case ('POST', '/api/v1/sync/push'):
        return _push(vault, device, body);
      case ('GET', '/api/v1/sync/pull'):
        return _pull(vault, request.url.queryParameters);
      case ('POST', '/api/v1/keys/rotate'):
        if (!_recoveryMatches(vault, body['recoveryAuthKey'])) {
          return _error(403, 'INVALID_RECOVERY_KEY');
        }
        if (body['newKeyId'] != vault.currentKeyId + 1) {
          return _error(409, 'KEY_ID_MISMATCH');
        }
        vault.currentKeyId = body['newKeyId'] as int;
        vault.recoveryEnvelope = body['recoveryEnvelope'] as String;
        if (body['newRecoveryAuthHash'] != null) {
          vault.recoveryAuthHash = body['newRecoveryAuthHash'] as String;
        }
        _invites.removeWhere((_, i) => i.vaultId == vault.id && !i.used);
        return _json(200, {'currentKeyId': vault.currentKeyId});
      case ('GET', '/api/v1/keys/stale'):
        final limit = int.parse(request.url.queryParameters['limit'] ?? '200');
        final stale =
            vault.records.values
                .where((r) => r.keyId != vault.currentKeyId)
                .toList()
              ..sort((a, b) => a.seq.compareTo(b.seq));
        return _json(200, {
          'currentKeyId': vault.currentKeyId,
          'records': [
            for (final r in stale.take(limit))
              {
                'recordId': r.recordId,
                'version': r.version,
                'keyId': r.keyId,
                'ciphertext': r.ciphertext,
              },
          ],
        });
      case ('POST', '/api/v1/keys/rekey'):
        var updated = 0;
        final skipped = <String>[];
        for (final item
            in (body['records'] as List).cast<Map<String, dynamic>>()) {
          if (item['keyId'] != vault.currentKeyId) {
            return _error(409, 'KEY_ROTATED');
          }
          final record = vault.records[item['recordId']];
          if (record != null && record.version == item['version']) {
            record
              ..keyId = item['keyId'] as int
              ..ciphertext = item['ciphertext'] as String;
            updated++;
          } else {
            skipped.add(item['recordId'] as String);
          }
        }
        return _json(200, {'updated': updated, 'skipped': skipped});
    }

    final deviceRoute = RegExp(
      r'^/api/v1/devices/([0-9a-f-]+)(/label)?$',
    ).firstMatch(path);
    final target = deviceRoute == null
        ? null
        : _deviceById(vault.id, deviceRoute.group(1)!);
    if (target == null) return _error(404, 'NOT_FOUND');
    if (request.method == 'DELETE' && deviceRoute!.group(2) == null) {
      target.revoked = true;
      return http.Response('', 204);
    }
    if (request.method == 'PUT' && deviceRoute!.group(2) != null) {
      target
        ..label = body['label'] as String
        ..labelKeyId = body['keyId'] as int;
      return http.Response('', 204);
    }
    return _error(404, 'NOT_FOUND');
  }

  http.Response _createVault(http.Request request, Map<String, dynamic> body) {
    if (request.headers['X-Registration-Secret'] != registrationSecret) {
      return _error(401, 'INVALID_REGISTRATION_SECRET');
    }
    final vaultId = body['vaultId'] as String;
    if (vaults.containsKey(vaultId)) return _error(409, 'CONFLICT');
    vaults[vaultId] = FakeVault(
      id: vaultId,
      currentKeyId: body['keyId'] as int,
      recoveryAuthHash: body['recoveryAuthHash'] as String,
      recoveryEnvelope: body['recoveryEnvelope'] as String,
    );
    return _enrolled(vaultId, body['deviceId'] as String, 'create');
  }

  http.Response _enrollWithInvite(Map<String, dynamic> body) {
    final invite = _invites[_hash(body['inviteCode'] as String)];
    if (invite == null ||
        invite.used ||
        !invite.expiresAt.isAfter(now) ||
        !vaults.containsKey(invite.vaultId)) {
      return _error(401, 'INVALID_INVITE');
    }
    invite.used = true;
    return _enrolled(invite.vaultId, body['deviceId'] as String, 'invite');
  }

  http.Response _enrollWithRecovery(Map<String, dynamic> body) {
    final hash = base64Encode(
      sha256.convert(base64Decode(body['recoveryAuthKey'] as String)).bytes,
    );
    final vault = vaults.values
        .where((v) => v.recoveryAuthHash == hash)
        .firstOrNull;
    if (vault == null) return _error(401, 'INVALID_RECOVERY_KEY');
    return _enrolled(
      vault.id,
      body['deviceId'] as String,
      'recovery',
      envelope: vault.recoveryEnvelope,
    );
  }

  http.Response _enrolled(
    String vaultId,
    String deviceId,
    String via, {
    String? envelope,
  }) {
    final token = _token();
    devices[_hash(token)] = _Device(deviceId, vaultId, via);
    return _json(201, {
      'vaultId': vaultId,
      'deviceId': deviceId,
      'deviceToken': token,
      'currentKeyId': vaults[vaultId]!.currentKeyId,
      'recoveryEnvelope': ?envelope,
    });
  }

  http.Response _push(
    FakeVault vault,
    _Device device,
    Map<String, dynamic> body,
  ) {
    final operations = (body['operations'] as List)
        .cast<Map<String, dynamic>>();
    if (operations.any((o) => o['keyId'] != vault.currentKeyId)) {
      return _error(409, 'KEY_ROTATED');
    }
    final accepted = <Map<String, dynamic>>[];
    final conflicts = <Map<String, dynamic>>[];
    for (final operation in operations) {
      final operationId = operation['operationId'] as String;
      final recordId = operation['recordId'] as String;
      final previous = vault.applied[operationId];
      if (previous != null) {
        accepted.add({
          'operationId': operationId,
          'recordId': recordId,
          'version': previous.$1,
          'seq': previous.$2,
        });
        continue;
      }
      final record = vault.records[recordId];
      if ((record?.version ?? 0) != operation['baseVersion']) {
        conflicts.add({
          'operationId': operationId,
          'recordId': recordId,
          'version': record?.version ?? 0,
          'deleted': record?.deleted ?? false,
          'keyId': ?record?.keyId,
          'ciphertext': ?record?.ciphertext,
        });
        continue;
      }
      if (record == null && operation['deleted'] == true) {
        accepted.add({
          'operationId': operationId,
          'recordId': recordId,
          'version': 0,
          'seq': vault.seq,
        });
        continue;
      }
      final stored = vault.records.putIfAbsent(
        recordId,
        () => FakeRecord(recordId),
      );
      vault.seq++;
      stored
        ..version += 1
        ..seq = vault.seq
        ..deleted = operation['deleted'] as bool
        ..keyId = operation['keyId'] as int
        ..ciphertext = operation['ciphertext'] as String;
      vault.applied[operationId] = (stored.version, stored.seq);
      accepted.add({
        'operationId': operationId,
        'recordId': recordId,
        'version': stored.version,
        'seq': stored.seq,
      });
    }
    return _json(200, {'accepted': accepted, 'conflicts': conflicts});
  }

  http.Response _pull(FakeVault vault, Map<String, String> query) {
    final since = int.parse(query['since'] ?? '0');
    final limit = int.parse(query['limit'] ?? '500');
    final changes = vault.records.values.where((r) => r.seq > since).toList()
      ..sort((a, b) => a.seq.compareTo(b.seq));
    final page = changes.take(limit).toList();
    return _json(200, {
      'changes': [
        for (final r in page)
          {
            'recordId': r.recordId,
            'version': r.version,
            'seq': r.seq,
            'deleted': r.deleted,
            'keyId': r.keyId,
            'ciphertext': r.ciphertext,
          },
      ],
      'nextSince': page.isEmpty ? since : page.last.seq,
      'hasMore': changes.length > limit,
      'currentKeyId': vault.currentKeyId,
    });
  }

  _Device? _authenticate(http.Request request) {
    final header = request.headers['Authorization'] ?? '';
    if (!header.startsWith('Bearer ')) return null;
    final device = devices[_hash(header.substring(7))];
    return device == null || device.revoked ? null : device;
  }

  _Device? _deviceById(String vaultId, String deviceId) => devices.values
      .where((d) => d.vaultId == vaultId && d.id == deviceId && !d.revoked)
      .firstOrNull;

  bool _recoveryMatches(FakeVault vault, Object? authKey) =>
      authKey is String &&
      base64Encode(sha256.convert(base64Decode(authKey)).bytes) ==
          vault.recoveryAuthHash;

  String _token() => base64Url
      .encode(List<int>.generate(32, (_) => _random.nextInt(256)))
      .replaceAll('=', '');

  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static http.Response _json(int status, Map<String, dynamic> body) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  static http.Response _error(int status, String code) =>
      _json(status, {'code': code, 'message': code});
}

class FakeVault {
  FakeVault({
    required this.id,
    required this.currentKeyId,
    required this.recoveryAuthHash,
    required this.recoveryEnvelope,
  });

  final String id;
  int currentKeyId;
  String recoveryAuthHash;
  String recoveryEnvelope;
  int seq = 0;
  final records = <String, FakeRecord>{};
  final applied = <String, (int, int)>{};
}

class FakeRecord {
  FakeRecord(this.recordId);

  final String recordId;
  int version = 0;
  int seq = 0;
  int keyId = 0;
  bool deleted = false;
  String ciphertext = '';
}

class _Device {
  _Device(this.id, this.vaultId, this.enrolledVia);

  final String id;
  final String vaultId;
  final String enrolledVia;
  bool revoked = false;
  String? label;
  int? labelKeyId;
}

class _Invite {
  _Invite(this.vaultId, this.expiresAt);

  final String vaultId;
  final DateTime expiresAt;
  bool used = false;
}
