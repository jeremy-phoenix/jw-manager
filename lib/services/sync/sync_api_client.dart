import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// An error response from the sync server (`{ code, message }`).
class SyncApiException implements Exception {
  const SyncApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String code;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isKeyRotated => code == 'KEY_ROTATED';

  @override
  String toString() => message;
}

class EnrollmentResult {
  const EnrollmentResult({
    required this.vaultId,
    required this.deviceId,
    required this.deviceToken,
    required this.currentKeyId,
    this.recoveryEnvelope,
  });

  final String vaultId;
  final String deviceId;
  final String deviceToken;
  final int currentKeyId;
  final Uint8List? recoveryEnvelope;
}

class VaultInfo {
  const VaultInfo({
    required this.vaultId,
    required this.currentKeyId,
    required this.recoveryEnvelope,
  });

  final String vaultId;
  final int currentKeyId;
  final Uint8List recoveryEnvelope;
}

class RemoteDevice {
  const RemoteDevice({
    required this.deviceId,
    required this.label,
    required this.labelKeyId,
    required this.enrolledVia,
    required this.createdAt,
    required this.lastSeenAt,
    required this.isCurrent,
  });

  final String deviceId;
  final Uint8List? label;
  final int? labelKeyId;
  final String enrolledVia;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final bool isCurrent;
}

class CreatedInvite {
  const CreatedInvite({required this.inviteCode, required this.expiresAt});

  final String inviteCode;
  final DateTime expiresAt;
}

class PushOperationRequest {
  const PushOperationRequest({
    required this.operationId,
    required this.recordId,
    required this.baseVersion,
    required this.deleted,
    required this.keyId,
    required this.ciphertext,
  });

  final String operationId;
  final String recordId;
  final int baseVersion;
  final bool deleted;
  final int keyId;
  final Uint8List ciphertext;

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'recordId': recordId,
    'baseVersion': baseVersion,
    'deleted': deleted,
    'keyId': keyId,
    'ciphertext': base64Encode(ciphertext),
  };
}

class AcceptedPush {
  const AcceptedPush(this.operationId, this.version);

  final String operationId;
  final int version;
}

/// The server's copy of a record we tried to change from a stale version.
/// A null [ciphertext] means the server has no such record.
class ConflictedPush {
  const ConflictedPush({
    required this.operationId,
    required this.recordId,
    required this.version,
    required this.deleted,
    this.keyId,
    this.ciphertext,
  });

  final String operationId;
  final String recordId;
  final int version;
  final bool deleted;
  final int? keyId;
  final Uint8List? ciphertext;
}

class PushResult {
  const PushResult(this.accepted, this.conflicts);

  final List<AcceptedPush> accepted;
  final List<ConflictedPush> conflicts;
}

class EncryptedRecord {
  const EncryptedRecord({
    required this.recordId,
    required this.version,
    required this.deleted,
    required this.keyId,
    required this.ciphertext,
  });

  final String recordId;
  final int version;
  final bool deleted;
  final int keyId;
  final Uint8List ciphertext;
}

class PullPage {
  const PullPage({
    required this.changes,
    required this.nextSince,
    required this.hasMore,
    required this.currentKeyId,
  });

  final List<EncryptedRecord> changes;
  final int nextSince;
  final bool hasMore;
  final int currentKeyId;
}

class RekeyItem {
  const RekeyItem(this.recordId, this.version, this.keyId, this.ciphertext);

  final String recordId;
  final int version;
  final int keyId;
  final Uint8List ciphertext;
}

/// Thin client for the encrypted sync relay (CongregationManager.Server).
/// Every payload it sends is already encrypted or a derived digest.
class SyncApiClient {
  SyncApiClient(
    this.baseUrl, {
    this.deviceToken,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 45),
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final String? deviceToken;
  final Duration timeout;
  final http.Client _http;

  void close() => _http.close();

  Future<EnrollmentResult> createVault({
    required String registrationSecret,
    required String vaultId,
    required String deviceId,
    required int keyId,
    required List<int> recoveryAuthHash,
    required List<int> recoveryEnvelope,
  }) async => _enrollment(
    await _send(
      'POST',
      '/vaults',
      body: {
        'vaultId': vaultId,
        'deviceId': deviceId,
        'keyId': keyId,
        'recoveryAuthHash': base64Encode(recoveryAuthHash),
        'recoveryEnvelope': base64Encode(recoveryEnvelope),
      },
      headers: {'X-Registration-Secret': registrationSecret},
    ),
  );

  Future<EnrollmentResult> enrollWithInvite({
    required String inviteCode,
    required String deviceId,
  }) async => _enrollment(
    await _send(
      'POST',
      '/devices/enroll',
      body: {'inviteCode': inviteCode, 'deviceId': deviceId},
    ),
  );

  Future<EnrollmentResult> enrollWithRecovery({
    required List<int> recoveryAuthKey,
    required String deviceId,
  }) async => _enrollment(
    await _send(
      'POST',
      '/recovery/enroll',
      body: {
        'recoveryAuthKey': base64Encode(recoveryAuthKey),
        'deviceId': deviceId,
      },
    ),
  );

  Future<VaultInfo> getVault() async {
    final json = await _send('GET', '/vault');
    return VaultInfo(
      vaultId: (json['vaultId'] as String).toLowerCase(),
      currentKeyId: json['currentKeyId'] as int,
      recoveryEnvelope: base64Decode(json['recoveryEnvelope'] as String),
    );
  }

  Future<void> deleteVault(List<int> recoveryAuthKey) => _send(
    'POST',
    '/vault/delete',
    body: {'recoveryAuthKey': base64Encode(recoveryAuthKey)},
  );

  Future<List<RemoteDevice>> listDevices() async {
    final json = await _send('GET', '/devices');
    return [
      for (final device in json['devices'] as List)
        RemoteDevice(
          deviceId: (device['deviceId'] as String).toLowerCase(),
          label: device['label'] == null
              ? null
              : base64Decode(device['label'] as String),
          labelKeyId: device['labelKeyId'] as int?,
          enrolledVia: device['enrolledVia'] as String,
          createdAt: DateTime.parse(device['createdAt'] as String),
          lastSeenAt: DateTime.parse(device['lastSeenAt'] as String),
          isCurrent: device['current'] as bool,
        ),
    ];
  }

  Future<void> revokeDevice(String deviceId) =>
      _send('DELETE', '/devices/$deviceId');

  Future<void> setDeviceLabel(String deviceId, List<int> label, int keyId) =>
      _send(
        'PUT',
        '/devices/$deviceId/label',
        body: {'label': base64Encode(label), 'keyId': keyId},
      );

  Future<CreatedInvite> createInvite(Duration lifetime) async {
    final json = await _send(
      'POST',
      '/invites',
      body: {'expiresInMinutes': lifetime.inMinutes},
    );
    return CreatedInvite(
      inviteCode: json['inviteCode'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Future<PushResult> push(List<PushOperationRequest> operations) async {
    final json = await _send(
      'POST',
      '/sync/push',
      body: {
        'operations': [for (final operation in operations) operation.toJson()],
      },
    );
    return PushResult(
      [
        for (final accepted in json['accepted'] as List)
          AcceptedPush(
            (accepted['operationId'] as String).toLowerCase(),
            accepted['version'] as int,
          ),
      ],
      [
        for (final conflict in json['conflicts'] as List)
          ConflictedPush(
            operationId: (conflict['operationId'] as String).toLowerCase(),
            recordId: (conflict['recordId'] as String).toLowerCase(),
            version: conflict['version'] as int,
            deleted: conflict['deleted'] as bool,
            keyId: conflict['keyId'] as int?,
            ciphertext: conflict['ciphertext'] == null
                ? null
                : base64Decode(conflict['ciphertext'] as String),
          ),
      ],
    );
  }

  Future<PullPage> pull({required int since, int limit = 500}) async {
    final json = await _send('GET', '/sync/pull?since=$since&limit=$limit');
    return PullPage(
      changes: [for (final change in json['changes'] as List) _record(change)],
      nextSince: json['nextSince'] as int,
      hasMore: json['hasMore'] as bool,
      currentKeyId: json['currentKeyId'] as int,
    );
  }

  Future<int> rotateKey({
    required List<int> recoveryAuthKey,
    required int newKeyId,
    required List<int> recoveryEnvelope,
    List<int>? newRecoveryAuthHash,
  }) async {
    final json = await _send(
      'POST',
      '/keys/rotate',
      body: {
        'recoveryAuthKey': base64Encode(recoveryAuthKey),
        'newKeyId': newKeyId,
        'recoveryEnvelope': base64Encode(recoveryEnvelope),
        if (newRecoveryAuthHash != null)
          'newRecoveryAuthHash': base64Encode(newRecoveryAuthHash),
      },
    );
    return json['currentKeyId'] as int;
  }

  Future<List<EncryptedRecord>> staleRecords({int limit = 200}) async {
    final json = await _send('GET', '/keys/stale?limit=$limit');
    return [
      for (final record in json['records'] as List)
        EncryptedRecord(
          recordId: (record['recordId'] as String).toLowerCase(),
          version: record['version'] as int,
          deleted: false,
          keyId: record['keyId'] as int,
          ciphertext: base64Decode(record['ciphertext'] as String),
        ),
    ];
  }

  /// Returns the number of records updated; the rest changed meanwhile.
  Future<int> rekey(List<RekeyItem> items) async {
    final json = await _send(
      'POST',
      '/keys/rekey',
      body: {
        'records': [
          for (final item in items)
            {
              'recordId': item.recordId,
              'version': item.version,
              'keyId': item.keyId,
              'ciphertext': base64Encode(item.ciphertext),
            },
        ],
      },
    );
    return json['updated'] as int;
  }

  static EncryptedRecord _record(dynamic json) => EncryptedRecord(
    recordId: (json['recordId'] as String).toLowerCase(),
    version: json['version'] as int,
    deleted: json['deleted'] as bool,
    keyId: json['keyId'] as int,
    ciphertext: base64Decode(json['ciphertext'] as String),
  );

  static EnrollmentResult _enrollment(Map<String, dynamic> json) =>
      EnrollmentResult(
        vaultId: (json['vaultId'] as String).toLowerCase(),
        deviceId: (json['deviceId'] as String).toLowerCase(),
        deviceToken: json['deviceToken'] as String,
        currentKeyId: json['currentKeyId'] as int,
        recoveryEnvelope: json['recoveryEnvelope'] == null
            ? null
            : base64Decode(json['recoveryEnvelope'] as String),
      );

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
  }) async {
    final basePath = baseUrl.path.endsWith('/')
        ? baseUrl.path.substring(0, baseUrl.path.length - 1)
        : baseUrl.path;
    final uri = Uri.parse('${baseUrl.replace(path: basePath)}/api/v1$path');
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (deviceToken != null) 'Authorization': 'Bearer $deviceToken',
        ...headers,
      });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      ).timeout(timeout);
    } on TimeoutException {
      throw const SyncApiException(
        0,
        'TIMEOUT',
        'The sync server did not respond in time.',
      );
    } on http.ClientException catch (error) {
      throw SyncApiException(
        0,
        'NETWORK',
        'Could not reach the sync server: ${error.message}',
      );
    } on Exception catch (error) {
      // Socket and TLS failures (for example an untrusted certificate).
      throw SyncApiException(
        0,
        'NETWORK',
        'Could not reach the sync server: $error',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return const {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw _error(response);
  }

  static SyncApiException _error(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SyncApiException(
        response.statusCode,
        json['code'] as String? ?? 'HTTP_${response.statusCode}',
        json['message'] as String? ??
            'The sync server returned ${response.statusCode}.',
      );
    } on Object {
      return SyncApiException(
        response.statusCode,
        'HTTP_${response.statusCode}',
        'The sync server returned ${response.statusCode}.',
      );
    }
  }
}
