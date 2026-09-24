import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secrets for one vault on this device: the device's bearer token and every
/// vault key it has received. They live in the operating system's credential
/// store (Keychain, Android Keystore, Windows credential storage, libsecret),
/// never in the SQLite database.
class SyncCredentials {
  const SyncCredentials({
    required this.vaultId,
    required this.deviceId,
    required this.deviceToken,
    required this.keys,
  });

  final String vaultId;
  final String deviceId;
  final String deviceToken;
  final Map<int, Uint8List> keys;

  SyncCredentials withKey(int keyId, Uint8List key) => SyncCredentials(
    vaultId: vaultId,
    deviceId: deviceId,
    deviceToken: deviceToken,
    keys: {...keys, keyId: key},
  );

  String toJson() => jsonEncode({
    'vaultId': vaultId,
    'deviceId': deviceId,
    'deviceToken': deviceToken,
    'keys': {
      for (final entry in keys.entries)
        '${entry.key}': base64Encode(entry.value),
    },
  });

  static SyncCredentials fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final keys = json['keys'] as Map<String, dynamic>;
    return SyncCredentials(
      vaultId: json['vaultId'] as String,
      deviceId: json['deviceId'] as String,
      deviceToken: json['deviceToken'] as String,
      keys: {
        for (final entry in keys.entries)
          int.parse(entry.key): base64Decode(entry.value as String),
      },
    );
  }
}

abstract interface class SyncCredentialStore {
  Future<SyncCredentials?> read(String vaultId);

  Future<void> write(SyncCredentials credentials);

  Future<void> delete(String vaultId);
}

class SecureSyncCredentialStore implements SyncCredentialStore {
  const SecureSyncCredentialStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  static String _key(String vaultId) =>
      'congregation_manager.sync.v1.${vaultId.toLowerCase()}';

  @override
  Future<SyncCredentials?> read(String vaultId) async {
    final value = await _storage.read(key: _key(vaultId));
    return value == null ? null : SyncCredentials.fromJson(value);
  }

  @override
  Future<void> write(SyncCredentials credentials) => _storage.write(
    key: _key(credentials.vaultId),
    value: credentials.toJson(),
  );

  @override
  Future<void> delete(String vaultId) => _storage.delete(key: _key(vaultId));
}

/// For tests.
class MemorySyncCredentialStore implements SyncCredentialStore {
  final values = <String, String>{};

  @override
  Future<SyncCredentials?> read(String vaultId) async {
    final value = values[vaultId.toLowerCase()];
    return value == null ? null : SyncCredentials.fromJson(value);
  }

  @override
  Future<void> write(SyncCredentials credentials) async =>
      values[credentials.vaultId.toLowerCase()] = credentials.toJson();

  @override
  Future<void> delete(String vaultId) async =>
      values.remove(vaultId.toLowerCase());
}
