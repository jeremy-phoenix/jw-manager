import 'dart:convert';
import 'dart:typed_data';

import 'package:congregation_manager/services/sync/server_url.dart';
import 'package:congregation_manager/services/sync/sync_crypto.dart';

/// Everything a new device needs to join a vault: where the server is, a
/// one-time enrollment code, and the vault key itself. The key never passes
/// through the server, so the invite must be handed over directly (QR code
/// or a trusted channel) and treated like a password.
class SyncInvite {
  const SyncInvite({
    required this.serverUrl,
    required this.vaultId,
    required this.inviteCode,
    required this.vaultKey,
    required this.keyId,
  });

  static const prefix = 'CMSYNC1:';

  final Uri serverUrl;
  final String vaultId;
  final String inviteCode;
  final Uint8List vaultKey;
  final int keyId;

  String encode() {
    final json = jsonEncode({
      'u': serverUrl.toString(),
      'v': vaultId,
      'c': inviteCode,
      'k': base64Url.encode(vaultKey).replaceAll('=', ''),
      'i': keyId,
    });
    return prefix + base64Url.encode(utf8.encode(json)).replaceAll('=', '');
  }

  /// Throws [FormatException] with a message suitable for display.
  static SyncInvite parse(String input) {
    const damaged = FormatException(
      'The invite is incomplete or damaged. Copy it again.',
    );
    final compact = input.replaceAll(RegExp(r'\s'), '');
    if (!compact.toUpperCase().startsWith(prefix)) {
      throw const FormatException(
        'This is not a Congregation Manager sync invite.',
      );
    }

    final Map<String, dynamic> json;
    final Uint8List key;
    try {
      final decoded = jsonDecode(
        utf8.decode(_decodeBase64Url(compact.substring(prefix.length))),
      );
      if (decoded is! Map<String, dynamic>) throw damaged;
      json = decoded;
      key = _decodeBase64Url(json['k'] as String);
    } on Object {
      throw damaged;
    }

    final keyId = json['i'];
    final vaultId = json['v'];
    final inviteCode = json['c'];
    final serverUrl = json['u'];
    if (key.length != vaultKeyLength ||
        keyId is! int ||
        keyId < 1 ||
        vaultId is! String ||
        vaultId.isEmpty ||
        inviteCode is! String ||
        inviteCode.isEmpty ||
        serverUrl is! String) {
      throw damaged;
    }
    return SyncInvite(
      serverUrl: parseSyncServerUrl(serverUrl),
      vaultId: vaultId.toLowerCase(),
      inviteCode: inviteCode,
      vaultKey: key,
      keyId: keyId,
    );
  }

  static Uint8List _decodeBase64Url(String value) =>
      base64Url.decode(base64Url.normalize(value));
}
