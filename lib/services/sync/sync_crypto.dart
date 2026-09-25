import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import 'package:congregation_manager/services/sync/base32.dart';

/// Client-side encryption for online sync.
///
/// Every record, device name and wrapped key is sealed with
/// XChaCha20-Poly1305 before it leaves the device. The associated data binds
/// each ciphertext to its vault, record and key id, so the server cannot
/// swap ciphertexts between records without detection.
class SyncCryptoException implements Exception {
  const SyncCryptoException(this.message);

  final String message;

  @override
  String toString() => message;
}

const vaultKeyLength = 32;

const _formatXchacha20Poly1305 = 1;
const _nonceLength = 24;
const _macLength = 16;

final _aead = Xchacha20.poly1305Aead();
final _random = Random.secure();

Uint8List randomBytes(int length) =>
    Uint8List.fromList(List<int>.generate(length, (_) => _random.nextInt(256)));

Uint8List sha256Bytes(List<int> data) =>
    Uint8List.fromList(crypto.sha256.convert(data).bytes);

bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}

List<int> _associatedData(String purpose, List<Object> parts) => utf8.encode(
  [
    'cm',
    purpose,
    'v1',
    ...parts.map((part) => '$part'.toLowerCase()),
  ].join('|'),
);

/// Output layout: format byte, 24-byte nonce, ciphertext, 16-byte tag.
Future<Uint8List> _seal(
  List<int> key,
  List<int> plaintext,
  List<int> associatedData,
) async {
  final box = await _aead.encrypt(
    plaintext,
    secretKey: SecretKey(key),
    nonce: randomBytes(_nonceLength),
    aad: associatedData,
  );
  return Uint8List.fromList([_formatXchacha20Poly1305, ...box.concatenation()]);
}

Future<Uint8List> _open(
  List<int> key,
  List<int> sealed,
  List<int> associatedData,
) async {
  if (sealed.length < 1 + _nonceLength + _macLength ||
      sealed.first != _formatXchacha20Poly1305) {
    throw const SyncCryptoException('Unsupported or truncated ciphertext.');
  }
  final box = SecretBox.fromConcatenation(
    sealed.sublist(1),
    nonceLength: _nonceLength,
    macLength: _macLength,
  );
  try {
    return Uint8List.fromList(
      await _aead.decrypt(box, secretKey: SecretKey(key), aad: associatedData),
    );
  } on SecretBoxAuthenticationError {
    throw const SyncCryptoException(
      'Decryption failed: the key is wrong or the data was altered.',
    );
  }
}

Future<Uint8List> sealRecord({
  required List<int> vaultKey,
  required String vaultId,
  required String recordId,
  required int keyId,
  required Map<String, dynamic> envelope,
}) => _seal(
  vaultKey,
  utf8.encode(jsonEncode(envelope)),
  _associatedData('record', [vaultId, recordId, keyId]),
);

Future<Map<String, dynamic>> openRecord({
  required List<int> vaultKey,
  required String vaultId,
  required String recordId,
  required int keyId,
  required List<int> ciphertext,
}) async {
  final plaintext = await _open(
    vaultKey,
    ciphertext,
    _associatedData('record', [vaultId, recordId, keyId]),
  );
  final decoded = jsonDecode(utf8.decode(plaintext));
  if (decoded is! Map<String, dynamic>) {
    throw const SyncCryptoException('Decrypted record is not a JSON object.');
  }
  return decoded;
}

/// Re-seals a record for key rotation without interpreting its contents.
Future<Uint8List> resealRecord({
  required List<int> oldKey,
  required int oldKeyId,
  required List<int> newKey,
  required int newKeyId,
  required String vaultId,
  required String recordId,
  required List<int> ciphertext,
}) async {
  final plaintext = await _open(
    oldKey,
    ciphertext,
    _associatedData('record', [vaultId, recordId, oldKeyId]),
  );
  return _seal(
    newKey,
    plaintext,
    _associatedData('record', [vaultId, recordId, newKeyId]),
  );
}

Future<Uint8List> sealVaultKey({
  required List<int> wrapKey,
  required List<int> vaultKey,
  required String vaultId,
  required int keyId,
}) => _seal(wrapKey, vaultKey, _associatedData('vault-key', [vaultId, keyId]));

Future<Uint8List> openVaultKey({
  required List<int> wrapKey,
  required List<int> envelope,
  required String vaultId,
  required int keyId,
}) async {
  try {
    final key = await _open(
      wrapKey,
      envelope,
      _associatedData('vault-key', [vaultId, keyId]),
    );
    if (key.length != vaultKeyLength) {
      throw const SyncCryptoException('The stored vault key is malformed.');
    }
    return key;
  } on SyncCryptoException {
    throw const SyncCryptoException('The recovery code is incorrect.');
  }
}

Future<Uint8List> sealDeviceLabel({
  required List<int> vaultKey,
  required String vaultId,
  required String deviceId,
  required int keyId,
  required String label,
}) => _seal(
  vaultKey,
  utf8.encode(label),
  _associatedData('device-label', [vaultId, deviceId, keyId]),
);

Future<String> openDeviceLabel({
  required List<int> vaultKey,
  required String vaultId,
  required String deviceId,
  required int keyId,
  required List<int> ciphertext,
}) async => utf8.decode(
  await _open(
    vaultKey,
    ciphertext,
    _associatedData('device-label', [vaultId, deviceId, keyId]),
  ),
);

/// Keys derived from a recovery code. The server only ever sees
/// [authKey] (to prove knowledge of the code) and [authHash]; [wrapKey]
/// never leaves the device.
class RecoveryKeys {
  const RecoveryKeys({
    required this.wrapKey,
    required this.authKey,
    required this.authHash,
  });

  final Uint8List wrapKey;
  final Uint8List authKey;
  final Uint8List authHash;
}

/// A random 256-bit secret, written as 55 Crockford base32 characters
/// (secret plus a 2-byte checksum) in groups of five.
class RecoveryCode {
  RecoveryCode._(this._secret, this.formatted);

  factory RecoveryCode.generate() =>
      RecoveryCode._fromSecret(randomBytes(_secretLength));

  factory RecoveryCode._fromSecret(Uint8List secret) {
    final encoded = encodeCrockfordBase32([...secret, ..._checksum(secret)]);
    final groups = <String>[
      for (var i = 0; i < encoded.length; i += 5)
        encoded.substring(i, min(i + 5, encoded.length)),
    ];
    return RecoveryCode._(secret, groups.join('-'));
  }

  static const _secretLength = 32;
  static const _checksumLength = 2;

  final Uint8List _secret;

  /// The code as shown to people, e.g. `7K3QX-M0T9B-...`.
  final String formatted;

  /// Parses a typed or pasted code. Throws [FormatException] with a message
  /// suitable for showing to people.
  static RecoveryCode parse(String input) {
    final bytes = decodeCrockfordBase32(input);
    if (bytes == null || bytes.length != _secretLength + _checksumLength) {
      throw const FormatException(
        'That is not a complete recovery code. Check for missing or extra characters.',
      );
    }
    final secret = Uint8List.fromList(bytes.sublist(0, _secretLength));
    if (!constantTimeEquals(bytes.sublist(_secretLength), _checksum(secret))) {
      throw const FormatException(
        'The recovery code has a typo. Check each group of characters.',
      );
    }
    return RecoveryCode._fromSecret(secret);
  }

  Future<RecoveryKeys> deriveKeys() async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final salt = utf8.encode('cm|recovery|v1');
    Future<Uint8List> derive(String info) async {
      final key = await hkdf.deriveKey(
        secretKey: SecretKey(_secret),
        nonce: salt,
        info: utf8.encode(info),
      );
      return Uint8List.fromList(key.bytes);
    }

    final authKey = await derive('auth');
    return RecoveryKeys(
      wrapKey: await derive('wrap'),
      authKey: authKey,
      authHash: sha256Bytes(authKey),
    );
  }

  static List<int> _checksum(List<int> secret) => sha256Bytes([
    ...utf8.encode('cm|recovery-checksum|v1'),
    ...secret,
  ]).sublist(0, _checksumLength);
}
