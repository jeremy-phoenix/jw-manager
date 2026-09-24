import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/sync_models.dart';
import 'package:congregation_manager/services/sync/server_url.dart';
import 'package:congregation_manager/services/sync/sync_api_client.dart';
import 'package:congregation_manager/services/sync/sync_credentials.dart';
import 'package:congregation_manager/services/sync/sync_crypto.dart';
import 'package:congregation_manager/services/sync/sync_invite.dart';

/// A sync failure with a message suitable for showing to people.
class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The vault key was rotated and this device does not have the new key.
class SyncKeyRequiredException extends SyncException {
  const SyncKeyRequiredException()
    : super(
        'The vault key was changed on another device. Enter the recovery '
        'code on this device to keep syncing.',
      );
}

/// What to do with records already on this device when joining a vault.
enum LocalDataChoice {
  /// Delete them (after a backup copy) and use the vault's data.
  replace,

  /// Upload them to the vault alongside its data.
  merge,
}

class SyncResult {
  const SyncResult({this.pushed = 0, this.pulled = 0, this.conflicts = 0});

  final int pushed;
  final int pulled;
  final int conflicts;
}

class SyncDevice {
  const SyncDevice({
    required this.deviceId,
    required this.label,
    required this.enrolledVia,
    required this.createdAt,
    required this.lastSeenAt,
    required this.isCurrent,
  });

  final String deviceId;

  /// Null when the name cannot be decrypted with the keys on this device.
  final String? label;
  final String enrolledVia;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final bool isCurrent;
}

class CreatedSyncInvite {
  const CreatedSyncInvite(this.invite, this.expiresAt);

  /// Contains the vault key: hand it over directly and treat it as a password.
  final String invite;
  final DateTime expiresAt;
}

class KeyRotationResult {
  const KeyRotationResult({
    required this.reencrypted,
    required this.unreadable,
  });

  final int reencrypted;

  /// Records this device could not re-encrypt because it never had their key.
  final int unreadable;
}

typedef SyncApiFactory =
    SyncApiClient Function(Uri serverUrl, {String? deviceToken});

/// Returns the path of a backup copy, made before local data is replaced.
typedef DatabaseBackup = Future<String?> Function();

/// End-to-end encrypted sync with CongregationManager.Server.
///
/// Records are encrypted on this device with the vault key before upload;
/// the server stores ciphertext and version numbers only. The vault key
/// reaches other devices through invites (handed over directly) or is
/// unwrapped with the recovery code, never through the server in the clear.
class SyncService {
  SyncService(
    this._db,
    this._credentials, {
    SyncApiFactory? apiFactory,
    DatabaseBackup? backupBeforeReplace,
  }) : _apiFactory = apiFactory ?? _defaultApiFactory,
       _backupBeforeReplace = backupBeforeReplace;

  /// Version of the envelope inside each encrypted record. Increase it only
  /// for incompatible payload changes: older apps then stop syncing and ask
  /// to be updated instead of overwriting fields they do not know.
  static const payloadFormatVersion = 1;

  static const _pushBatchSize = 200;
  static const _pullPageSize = 500;
  static const _uuid = Uuid();
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final AppDatabase _db;
  final SyncCredentialStore _credentials;
  final SyncApiFactory _apiFactory;
  final DatabaseBackup? _backupBeforeReplace;

  Future<void> _tail = Future.value();
  Future<SyncResult>? _running;
  final _syncing = StreamController<bool>.broadcast();

  static SyncApiClient _defaultApiFactory(
    Uri serverUrl, {
    String? deviceToken,
  }) => SyncApiClient(serverUrl, deviceToken: deviceToken);

  bool get isSyncing => _running != null;

  /// Emits true when a sync starts and false when it ends.
  Stream<bool> get syncingChanges => _syncing.stream;

  /// Pushes local changes, then pulls everything new. Calls made while a
  /// sync is running share that run.
  Future<SyncResult> syncNow() {
    final running = _running;
    if (running != null) return running;
    _syncing.add(true);
    return _running = _exclusive(_sync).whenComplete(() {
      _running = null;
      _syncing.add(false);
    });
  }

  void dispose() => _syncing.close();

  // ──────────────────────────────────────────────────
  // Setting up a vault
  // ──────────────────────────────────────────────────

  /// Creates a vault protected by [recoveryCode] and queues this device's
  /// records for upload. Show the recovery code to the person, and have them
  /// save it, before calling this.
  Future<void> createVault({
    required String serverUrl,
    required String registrationSecret,
    required String deviceLabel,
    required RecoveryCode recoveryCode,
  }) => _exclusive(() async {
    final url = _parseUrl(serverUrl);
    final vaultId = _uuid.v4();
    final deviceId = _uuid.v4();
    const keyId = 1;
    final vaultKey = randomBytes(vaultKeyLength);
    final recoveryKeys = await recoveryCode.deriveKeys();
    final envelope = await sealVaultKey(
      wrapKey: recoveryKeys.wrapKey,
      vaultKey: vaultKey,
      vaultId: vaultId,
      keyId: keyId,
    );

    final enrollment = await _anonymous(
      url,
      (api) => api.createVault(
        registrationSecret: registrationSecret.trim(),
        vaultId: vaultId,
        deviceId: deviceId,
        keyId: keyId,
        recoveryAuthHash: recoveryKeys.authHash,
        recoveryEnvelope: envelope,
      ),
    );
    final credentials = SyncCredentials(
      vaultId: vaultId,
      deviceId: deviceId,
      deviceToken: enrollment.deviceToken,
      keys: {keyId: vaultKey},
    );
    final api = _apiFactory(url, deviceToken: enrollment.deviceToken);
    try {
      try {
        await _credentials.write(credentials);
        await _db.activateSyncVault(
          serverUrl: url.toString(),
          vaultId: vaultId,
          deviceId: deviceId,
          deviceLabel: deviceLabel,
          keyId: keyId,
          uploadLocalData: true,
        );
      } catch (_) {
        // Leave nothing half-created behind.
        await _ignoreFailure(() => api.deleteVault(recoveryKeys.authKey));
        await _credentials.delete(vaultId);
        await _db.deactivateSyncVault();
        rethrow;
      }
      await _trySetLabel(api, credentials, deviceLabel, keyId);
    } finally {
      api.close();
    }
  });

  /// Joins the vault an invite points to, then downloads it.
  Future<void> joinWithInvite({
    required String invite,
    required String deviceLabel,
    required LocalDataChoice localData,
  }) => _exclusive(() async {
    final parsed = _parseOrThrow(() => SyncInvite.parse(invite));
    final deviceId = _uuid.v4();
    final enrollment = await _anonymous(
      parsed.serverUrl,
      (api) => api.enrollWithInvite(
        inviteCode: parsed.inviteCode,
        deviceId: deviceId,
      ),
    );
    if (enrollment.vaultId != parsed.vaultId) {
      throw const SyncException(
        'The invite does not match the vault on this server.',
      );
    }
    await _finishJoining(
      serverUrl: parsed.serverUrl,
      credentials: SyncCredentials(
        vaultId: enrollment.vaultId,
        deviceId: enrollment.deviceId,
        deviceToken: enrollment.deviceToken,
        keys: {parsed.keyId: parsed.vaultKey},
      ),
      currentKeyId: enrollment.currentKeyId,
      deviceLabel: deviceLabel,
      localData: localData,
    );
  });

  /// Adds this device to a vault using its recovery code, e.g. after all
  /// other devices were lost.
  Future<void> recoverWithCode({
    required String serverUrl,
    required String recoveryCode,
    required String deviceLabel,
    required LocalDataChoice localData,
  }) => _exclusive(() async {
    final url = _parseUrl(serverUrl);
    final keys = await _recoveryKeys(recoveryCode);
    final deviceId = _uuid.v4();
    final enrollment = await _anonymous(
      url,
      (api) => api.enrollWithRecovery(
        recoveryAuthKey: keys.authKey,
        deviceId: deviceId,
      ),
    );
    final envelope = enrollment.recoveryEnvelope;
    if (envelope == null) {
      throw const SyncException('The server did not return the vault key.');
    }
    final vaultKey = await _unwrapVaultKey(
      keys,
      envelope,
      enrollment.vaultId,
      enrollment.currentKeyId,
    );
    await _finishJoining(
      serverUrl: url,
      credentials: SyncCredentials(
        vaultId: enrollment.vaultId,
        deviceId: enrollment.deviceId,
        deviceToken: enrollment.deviceToken,
        keys: {enrollment.currentKeyId: vaultKey},
      ),
      currentKeyId: enrollment.currentKeyId,
      deviceLabel: deviceLabel,
      localData: localData,
    );
  });

  Future<void> _finishJoining({
    required Uri serverUrl,
    required SyncCredentials credentials,
    required int currentKeyId,
    required String deviceLabel,
    required LocalDataChoice localData,
  }) async {
    await _credentials.write(credentials);
    final hasCurrentKey = credentials.keys.containsKey(currentKeyId);
    if (localData == LocalDataChoice.replace) {
      await _backupBeforeReplace?.call();
      await _db.clearLocalDataForSyncJoin();
    }
    await _db.activateSyncVault(
      serverUrl: serverUrl.toString(),
      vaultId: credentials.vaultId,
      deviceId: credentials.deviceId,
      deviceLabel: deviceLabel,
      keyId: currentKeyId,
      uploadLocalData: false,
      needsKey: !hasCurrentKey,
    );
    if (!hasCurrentKey) return;

    final api = _apiFactory(serverUrl, deviceToken: credentials.deviceToken);
    try {
      await _trySetLabel(api, credentials, deviceLabel, currentKeyId);
    } finally {
      api.close();
    }
    await _sync();
    if (localData == LocalDataChoice.merge) {
      // Only what the vault did not already have.
      await _db.queueLocalSnapshotForSync(onlyUnsynced: true);
      await _sync();
    }
  }

  // ──────────────────────────────────────────────────
  // Managing an enrolled device
  // ──────────────────────────────────────────────────

  /// Receives the current vault key after it was rotated elsewhere.
  Future<void> unlockWithRecoveryCode(String recoveryCode) =>
      _exclusive(() async {
        final session = await _requireSession();
        try {
          final keys = await _recoveryKeys(recoveryCode);
          final vault = await _call(session.api.getVault);
          final key = await _unwrapVaultKey(
            keys,
            vault.recoveryEnvelope,
            session.vaultId,
            vault.currentKeyId,
          );
          await _credentials.write(
            session.credentials.withKey(vault.currentKeyId, key),
          );
          await _db.setSyncKeyState(
            currentKeyId: vault.currentKeyId,
            needsKey: false,
          );
        } finally {
          session.api.close();
        }
        await _sync();
      });

  Future<CreatedSyncInvite> createInvite({
    Duration lifetime = const Duration(hours: 1),
  }) => _exclusive(() async {
    final session = await _requireSession();
    try {
      final (keyId, key) = session.currentKey();
      final created = await _call(() => session.api.createInvite(lifetime));
      final invite = SyncInvite(
        serverUrl: Uri.parse(session.settings.serverUrl!),
        vaultId: session.vaultId,
        inviteCode: created.inviteCode,
        vaultKey: key,
        keyId: keyId,
      );
      return CreatedSyncInvite(invite.encode(), created.expiresAt);
    } finally {
      session.api.close();
    }
  });

  Future<List<SyncDevice>> listDevices() => _exclusive(() async {
    final session = await _requireSession();
    try {
      final devices = await _call(session.api.listDevices);
      return [
        for (final device in devices)
          SyncDevice(
            deviceId: device.deviceId,
            label: await _readLabel(session, device),
            enrolledVia: device.enrolledVia,
            createdAt: device.createdAt,
            lastSeenAt: device.lastSeenAt,
            isCurrent: device.isCurrent,
          ),
      ];
    } finally {
      session.api.close();
    }
  });

  /// Removes another device's access immediately. If that device was lost,
  /// also rotate the key so it cannot read anything added later.
  Future<void> revokeDevice(String deviceId) => _exclusive(() async {
    final session = await _requireSession();
    try {
      await _call(() => session.api.revokeDevice(deviceId));
    } finally {
      session.api.close();
    }
  });

  Future<void> renameThisDevice(String label) => _exclusive(() async {
    final session = await _requireSession();
    try {
      final (keyId, _) = session.currentKey();
      await _trySetLabel(session.api, session.credentials, label, keyId);
      await _db.updateSyncDeviceLabel(label);
    } finally {
      session.api.close();
    }
  });

  /// Replaces the vault key and re-encrypts everything on the server with
  /// it. Use after a device is lost (revoke it first). Requires the current
  /// recovery code; pass [newRecoveryCode] (already shown to and saved by
  /// the person) to replace the recovery code at the same time.
  ///
  /// Other devices keep syncing after entering the recovery code once.
  Future<KeyRotationResult> rotateKey({
    required String recoveryCode,
    RecoveryCode? newRecoveryCode,
    void Function(int reencrypted)? onProgress,
  }) => _exclusive(() async {
    // Upload pending changes while they can still use the current key.
    await _sync();
    final session = await _requireSession();
    try {
      final keys = await _recoveryKeys(recoveryCode);
      final vault = await _call(session.api.getVault);
      // Checks the code before anything changes on the server.
      await _unwrapVaultKey(
        keys,
        vault.recoveryEnvelope,
        session.vaultId,
        vault.currentKeyId,
      );

      final newKeyId = vault.currentKeyId + 1;
      final newKey = randomBytes(vaultKeyLength);
      final wrapWith = newRecoveryCode == null
          ? keys
          : await newRecoveryCode.deriveKeys();
      final envelope = await sealVaultKey(
        wrapKey: wrapWith.wrapKey,
        vaultKey: newKey,
        vaultId: session.vaultId,
        keyId: newKeyId,
      );
      // Store the new key before the server switches so it cannot be lost.
      final credentials = session.credentials.withKey(newKeyId, newKey);
      await _credentials.write(credentials);
      await _call(
        () => session.api.rotateKey(
          recoveryAuthKey: keys.authKey,
          newKeyId: newKeyId,
          recoveryEnvelope: envelope,
          newRecoveryAuthHash: newRecoveryCode == null
              ? null
              : wrapWith.authHash,
        ),
      );
      await _db.setSyncKeyState(currentKeyId: newKeyId, needsKey: false);

      final result = await _reencryptRecords(
        session.api,
        credentials,
        session.vaultId,
        newKeyId,
        newKey,
        onProgress,
      );
      await _reencryptDeviceLabels(
        session.api,
        credentials,
        session.vaultId,
        newKeyId,
        newKey,
      );
      return result;
    } finally {
      session.api.close();
    }
  });

  /// Leaves the vault on this device. Local data stays.
  Future<void> disconnect({bool removeFromServer = true}) => _exclusive(
    () async {
      final settings = await _db.getSyncSettings();
      final vaultId = settings.vaultId;
      if (vaultId != null) {
        final credentials = await _credentials.read(vaultId);
        if (removeFromServer &&
            credentials != null &&
            settings.serverUrl != null) {
          final api = _apiFactory(
            Uri.parse(settings.serverUrl!),
            deviceToken: credentials.deviceToken,
          );
          try {
            // Offline or already removed: disconnect locally anyway.
            await _ignoreFailure(() => api.revokeDevice(credentials.deviceId));
          } finally {
            api.close();
          }
        }
        await _credentials.delete(vaultId);
      }
      await _db.deactivateSyncVault();
    },
  );

  /// Permanently erases the vault on the server (all devices lose access).
  /// Data on this device stays.
  Future<void> deleteVaultFromServer(String recoveryCode) =>
      _exclusive(() async {
        final session = await _requireSession();
        try {
          final keys = await _recoveryKeys(recoveryCode);
          await _call(() => session.api.deleteVault(keys.authKey));
        } finally {
          session.api.close();
        }
        await _credentials.delete(session.vaultId);
        await _db.deactivateSyncVault();
      });

  // ──────────────────────────────────────────────────
  // Push and pull
  // ──────────────────────────────────────────────────

  Future<SyncResult> _sync() async {
    final settings = await _db.getSyncSettings();
    if (!settings.isEnabled || settings.vaultId == null) {
      return const SyncResult();
    }
    _Session? session;
    try {
      session = await _requireSession();
      final pushed = await _push(session);
      final pulled = await _pull(session);
      await _db.recordSyncSuccess();
      return SyncResult(
        pushed: pushed.accepted,
        pulled: pulled,
        conflicts: pushed.conflicts,
      );
    } catch (error) {
      final failure = _describe(error);
      if (failure is SyncKeyRequiredException) {
        await _db.setSyncNeedsKey(true);
      }
      await _db.recordSyncError(failure.message);
      throw failure;
    } finally {
      session?.api.close();
    }
  }

  Future<({int accepted, int conflicts})> _push(_Session session) async {
    final (keyId, key) = session.currentKey();
    var accepted = 0;
    var conflicts = 0;
    String? previousBatch;
    while (true) {
      final pending = await _db.getPendingSyncOperations(limit: _pushBatchSize);
      if (pending.isEmpty) break;
      // Stop if nothing changed since the last round (e.g. only invalid ids).
      final batch = pending
          .map((o) => '${o.id}:${o.operationId}:${o.baseServerVersion}')
          .join(',');
      if (batch == previousBatch) break;
      previousBatch = batch;

      final requests = <PushOperationRequest>[];
      final sent = <String, PendingSyncOperation>{};
      for (final operation in pending) {
        if (!_uuidPattern.hasMatch(operation.entitySyncId)) {
          await _db.markSyncOperationFailed(
            operation.id,
            'The record id is not a UUID and cannot be synced.',
          );
          continue;
        }
        final deleted = operation.operationType == 'delete';
        final recordId = operation.entitySyncId.toLowerCase();
        requests.add(
          PushOperationRequest(
            operationId: operation.operationId,
            recordId: recordId,
            baseVersion: operation.baseServerVersion ?? 0,
            deleted: deleted,
            keyId: keyId,
            ciphertext: await sealRecord(
              vaultKey: key,
              vaultId: session.vaultId,
              recordId: recordId,
              keyId: keyId,
              envelope: {
                's': payloadFormatVersion,
                't': operation.entityType,
                if (deleted)
                  'd': true
                else
                  'p': jsonDecode(operation.payloadJson),
              },
            ),
          ),
        );
        sent[operation.operationId.toLowerCase()] = operation;
      }
      if (requests.isEmpty) break;

      final result = await _call(() => session.api.push(requests));
      for (final item in result.accepted) {
        final operation = sent[item.operationId];
        if (operation == null) continue;
        await _db.completePushedOperation(operation, item.version);
        accepted++;
      }
      for (final conflict in result.conflicts) {
        final operation = sent[conflict.operationId];
        if (operation == null) continue;
        final ciphertext = conflict.ciphertext;
        final server = ciphertext == null
            ? null
            : await _decrypt(
                session,
                EncryptedRecord(
                  recordId: conflict.recordId,
                  version: conflict.version,
                  deleted: conflict.deleted,
                  keyId: conflict.keyId ?? 0,
                  ciphertext: ciphertext,
                ),
              );
        await _db.resolvePushConflict(operation, server: server);
        conflicts++;
      }
    }
    return (accepted: accepted, conflicts: conflicts);
  }

  Future<int> _pull(_Session session) async {
    var since = session.settings.pullSeq;
    final changes = <RemoteChange>[];
    PullPage page;
    do {
      page = await _call(
        () => session.api.pull(since: since, limit: _pullPageSize),
      );
      for (final record in page.changes) {
        changes.add(await _decrypt(session, record));
      }
      since = page.nextSince;
    } while (page.hasMore);
    // One batch, so parents and children are always applied together.
    final applied = await _db.applyRemoteChanges(changes, pullSeq: since);

    // Re-encryption does not add to the change feed, so notice a rotation
    // here rather than on this device's next upload.
    final serverKeyId = page.currentKeyId;
    if (serverKeyId != session.settings.currentKeyId) {
      if (!session.credentials.keys.containsKey(serverKeyId)) {
        throw const SyncKeyRequiredException();
      }
      await _db.setSyncKeyState(currentKeyId: serverKeyId, needsKey: false);
    }
    return applied;
  }

  Future<RemoteChange> _decrypt(
    _Session session,
    EncryptedRecord record,
  ) async {
    final key = session.credentials.keys[record.keyId];
    if (key == null) throw const SyncKeyRequiredException();
    final envelope = await openRecord(
      vaultKey: key,
      vaultId: session.vaultId,
      recordId: record.recordId,
      keyId: record.keyId,
      ciphertext: record.ciphertext,
    );
    final format = envelope['s'];
    final entityType = envelope['t'];
    if (format is! int ||
        format > payloadFormatVersion ||
        entityType is! String ||
        !SyncEntityTypes.all.contains(entityType)) {
      throw const SyncException(
        'Another device synced data in a newer format. Update Congregation '
        'Manager on this device, then sync again.',
      );
    }
    final deleted = record.deleted || envelope['d'] == true;
    return RemoteChange(
      entityType: entityType,
      syncId: record.recordId,
      version: record.version,
      deleted: deleted,
      payload: deleted
          ? const <String, dynamic>{}
          : (envelope['p'] as Map).cast<String, dynamic>(),
    );
  }

  Future<KeyRotationResult> _reencryptRecords(
    SyncApiClient api,
    SyncCredentials credentials,
    String vaultId,
    int newKeyId,
    Uint8List newKey,
    void Function(int reencrypted)? onProgress,
  ) async {
    var reencrypted = 0;
    final unreadable = <String>{};
    // Every round removes records from the stale list: re-encrypted ones,
    // and ones changed meanwhile (those were pushed with the new key).
    for (var round = 0; round < 100000; round++) {
      final stale = await _call(() => api.staleRecords(limit: 200));
      final items = <RekeyItem>[];
      for (final record in stale) {
        if (unreadable.contains(record.recordId)) continue;
        final oldKey = credentials.keys[record.keyId];
        if (oldKey == null) {
          unreadable.add(record.recordId);
          continue;
        }
        try {
          items.add(
            RekeyItem(
              record.recordId,
              record.version,
              newKeyId,
              await resealRecord(
                oldKey: oldKey,
                oldKeyId: record.keyId,
                newKey: newKey,
                newKeyId: newKeyId,
                vaultId: vaultId,
                recordId: record.recordId,
                ciphertext: record.ciphertext,
              ),
            ),
          );
        } on SyncCryptoException {
          unreadable.add(record.recordId);
        }
      }
      if (items.isEmpty) break;
      reencrypted += await _call(() => api.rekey(items));
      onProgress?.call(reencrypted);
    }
    return KeyRotationResult(
      reencrypted: reencrypted,
      unreadable: unreadable.length,
    );
  }

  Future<void> _reencryptDeviceLabels(
    SyncApiClient api,
    SyncCredentials credentials,
    String vaultId,
    int newKeyId,
    Uint8List newKey,
  ) async {
    await _ignoreFailure(() async {
      for (final device in await api.listDevices()) {
        final label = device.label;
        final keyId = device.labelKeyId;
        final oldKey = keyId == null ? null : credentials.keys[keyId];
        if (label == null || keyId == newKeyId || oldKey == null) continue;
        await _ignoreFailure(() async {
          final plain = await openDeviceLabel(
            vaultKey: oldKey,
            vaultId: vaultId,
            deviceId: device.deviceId,
            keyId: keyId!,
            ciphertext: label,
          );
          await api.setDeviceLabel(
            device.deviceId,
            await sealDeviceLabel(
              vaultKey: newKey,
              vaultId: vaultId,
              deviceId: device.deviceId,
              keyId: newKeyId,
              label: plain,
            ),
            newKeyId,
          );
        });
      }
    });
  }

  // ──────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────

  /// Runs [action] after every earlier sync operation has finished, so a
  /// background sync never interleaves with setup or key rotation.
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<_Session> _requireSession() async {
    final settings = await _db.getSyncSettings();
    final vaultId = settings.vaultId;
    final serverUrl = settings.serverUrl;
    if (!settings.isEnabled || vaultId == null || serverUrl == null) {
      throw const SyncException('Online sync is not set up on this device.');
    }
    final credentials = await _credentials.read(vaultId);
    if (credentials == null) {
      throw const SyncException(
        'This device lost its sync credentials. Disconnect, then join the '
        'vault again with an invite or the recovery code.',
      );
    }
    return _Session(
      settings,
      credentials,
      _apiFactory(Uri.parse(serverUrl), deviceToken: credentials.deviceToken),
    );
  }

  Future<EnrollmentResult> _anonymous(
    Uri serverUrl,
    Future<EnrollmentResult> Function(SyncApiClient api) call,
  ) async {
    final api = _apiFactory(serverUrl);
    try {
      return await _call(() => call(api));
    } finally {
      api.close();
    }
  }

  /// Translates server errors into messages people can act on.
  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SyncApiException catch (error) {
      throw switch (error.code) {
        'KEY_ROTATED' => const SyncKeyRequiredException(),
        'INVALID_REGISTRATION_SECRET' => const SyncException(
          'The registration secret is incorrect.',
        ),
        'REGISTRATION_DISABLED' => const SyncException(
          'This server does not allow creating vaults. Set a registration '
          'secret in the server configuration first.',
        ),
        'INVALID_INVITE' => const SyncException(
          'The invite is invalid, expired or already used. Ask for a new one.',
        ),
        'INVALID_RECOVERY_KEY' => const SyncException(
          'The recovery code is incorrect.',
        ),
        'RATE_LIMITED' => const SyncException(
          'Too many attempts. Wait a minute and try again.',
        ),
        'HTTPS_REQUIRED' => const SyncException(
          'The server only accepts HTTPS. Check the server address.',
        ),
        _ when error.isUnauthorized => const SyncException(
          'This device is no longer allowed to sync. It may have been '
          'removed from the vault. Disconnect, then join again.',
        ),
        _ => SyncException(error.message),
      };
    }
  }

  static SyncException _describe(Object error) => switch (error) {
    SyncException() => error,
    SyncCryptoException() => SyncException(
      'A synced record could not be decrypted: ${error.message}',
    ),
    _ => SyncException('Sync failed: $error'),
  };

  static Uri _parseUrl(String serverUrl) =>
      _parseOrThrow(() => parseSyncServerUrl(serverUrl));

  static T _parseOrThrow<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException catch (error) {
      throw SyncException(error.message);
    }
  }

  static Future<RecoveryKeys> _recoveryKeys(String recoveryCode) =>
      _parseOrThrow(() => RecoveryCode.parse(recoveryCode)).deriveKeys();

  static Future<Uint8List> _unwrapVaultKey(
    RecoveryKeys keys,
    List<int> envelope,
    String vaultId,
    int keyId,
  ) async {
    try {
      return await openVaultKey(
        wrapKey: keys.wrapKey,
        envelope: envelope,
        vaultId: vaultId,
        keyId: keyId,
      );
    } on SyncCryptoException catch (error) {
      throw SyncException(error.message);
    }
  }

  Future<void> _trySetLabel(
    SyncApiClient api,
    SyncCredentials credentials,
    String label,
    int keyId,
  ) async {
    final key = credentials.keys[keyId];
    if (key == null) return;
    // A missing name is cosmetic; it must not fail setup.
    await _ignoreFailure(() async {
      await api.setDeviceLabel(
        credentials.deviceId,
        await sealDeviceLabel(
          vaultKey: key,
          vaultId: credentials.vaultId,
          deviceId: credentials.deviceId,
          keyId: keyId,
          label: label,
        ),
        keyId,
      );
    });
  }

  static Future<String?> _readLabel(
    _Session session,
    RemoteDevice device,
  ) async {
    final label = device.label;
    final keyId = device.labelKeyId;
    final key = keyId == null ? null : session.credentials.keys[keyId];
    if (label == null || key == null) return null;
    try {
      return await openDeviceLabel(
        vaultKey: key,
        vaultId: session.vaultId,
        deviceId: device.deviceId,
        keyId: keyId!,
        ciphertext: label,
      );
    } on SyncCryptoException {
      return null;
    }
  }

  static Future<void> _ignoreFailure(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Deliberately best-effort.
    }
  }
}

class _Session {
  _Session(this.settings, this.credentials, this.api);

  final SyncSetting settings;
  final SyncCredentials credentials;
  final SyncApiClient api;

  String get vaultId => settings.vaultId!;

  (int, Uint8List) currentKey() {
    final keyId = settings.currentKeyId;
    final key = keyId == null ? null : credentials.keys[keyId];
    if (keyId == null || key == null || settings.needsKey) {
      throw const SyncKeyRequiredException();
    }
    return (keyId, key);
  }
}
