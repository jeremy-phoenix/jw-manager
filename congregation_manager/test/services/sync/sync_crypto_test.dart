import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:congregation_manager/services/sync/base32.dart';
import 'package:congregation_manager/services/sync/server_url.dart';
import 'package:congregation_manager/services/sync/sync_crypto.dart';
import 'package:congregation_manager/services/sync/sync_invite.dart';

void main() {
  const vaultId = '0f1e2d3c-4b5a-4968-8776-655443322110';
  const recordId = '11111111-2222-4333-8444-555555555555';

  group('Crockford base32', () {
    test('round-trips arbitrary bytes', () {
      for (final length in [0, 1, 5, 16, 34]) {
        final bytes = randomBytes(length);
        expect(decodeCrockfordBase32(encodeCrockfordBase32(bytes)), bytes);
      }
    });

    test('accepts look-alike characters, dashes and lowercase', () {
      expect(decodeCrockfordBase32('o1-il'), decodeCrockfordBase32('0111'));
      expect(decodeCrockfordBase32('U'), isNull);
    });
  });

  group('recovery code', () {
    test(
      'formats as 11 groups of 5 and parses back to the same keys',
      () async {
        final code = RecoveryCode.generate();
        expect(
          code.formatted,
          matches(RegExp(r'^([0-9A-Z]{5}-){10}[0-9A-Z]{5}$')),
        );

        final parsed = RecoveryCode.parse(
          code.formatted.toLowerCase().replaceAll('-', ' '),
        );
        final original = await code.deriveKeys();
        final again = await parsed.deriveKeys();
        expect(again.wrapKey, original.wrapKey);
        expect(again.authKey, original.authKey);
        expect(original.authHash, sha256Bytes(original.authKey));
        expect(original.wrapKey, isNot(original.authKey));
      },
    );

    test('detects typos with its checksum', () {
      final code = RecoveryCode.generate().formatted;
      final typo = code.replaceRange(0, 1, code[0] == 'A' ? 'B' : 'A');
      expect(
        () => RecoveryCode.parse(typo),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('typo'),
          ),
        ),
      );
      expect(
        () => RecoveryCode.parse(code.substring(0, 20)),
        throwsFormatException,
      );
    });
  });

  group('record encryption', () {
    test('round-trips an envelope', () async {
      final key = randomBytes(vaultKeyLength);
      final envelope = {
        's': 1,
        't': 'person',
        'p': {'firstName': 'Alice'},
      };
      final sealed = await sealRecord(
        vaultKey: key,
        vaultId: vaultId,
        recordId: recordId,
        keyId: 1,
        envelope: envelope,
      );

      expect(
        utf8.decode(sealed, allowMalformed: true),
        isNot(contains('Alice')),
      );
      final opened = await openRecord(
        vaultKey: key,
        vaultId: vaultId,
        recordId: recordId,
        keyId: 1,
        ciphertext: sealed,
      );
      expect(opened, envelope);
    });

    test(
      'encrypting the same record twice gives different ciphertext',
      () async {
        final key = randomBytes(vaultKeyLength);
        Future<List<int>> seal() => sealRecord(
          vaultKey: key,
          vaultId: vaultId,
          recordId: recordId,
          keyId: 1,
          envelope: const {'s': 1},
        );
        expect(await seal(), isNot(await seal()));
      },
    );

    test('is bound to its key, vault, record and key id', () async {
      final key = randomBytes(vaultKeyLength);
      final sealed = await sealRecord(
        vaultKey: key,
        vaultId: vaultId,
        recordId: recordId,
        keyId: 1,
        envelope: const {'s': 1},
      );

      Future<void> expectRejected({
        List<int>? withKey,
        String withVault = vaultId,
        String withRecord = recordId,
        int withKeyId = 1,
        List<int>? ciphertext,
      }) => expectLater(
        openRecord(
          vaultKey: withKey ?? key,
          vaultId: withVault,
          recordId: withRecord,
          keyId: withKeyId,
          ciphertext: ciphertext ?? sealed,
        ),
        throwsA(isA<SyncCryptoException>()),
      );

      await expectRejected(withKey: randomBytes(vaultKeyLength));
      await expectRejected(withVault: '99999999-2222-4333-8444-555555555555');
      await expectRejected(withRecord: '99999999-2222-4333-8444-555555555555');
      await expectRejected(withKeyId: 2);
      final tampered = List<int>.of(sealed)..[sealed.length - 20] ^= 1;
      await expectRejected(ciphertext: tampered);
    });

    test('reseal moves a record to a new key without reading it', () async {
      final oldKey = randomBytes(vaultKeyLength);
      final newKey = randomBytes(vaultKeyLength);
      final sealed = await sealRecord(
        vaultKey: oldKey,
        vaultId: vaultId,
        recordId: recordId,
        keyId: 1,
        envelope: const {'s': 1, 't': 'person'},
      );
      final resealed = await resealRecord(
        oldKey: oldKey,
        oldKeyId: 1,
        newKey: newKey,
        newKeyId: 2,
        vaultId: vaultId,
        recordId: recordId,
        ciphertext: sealed,
      );
      final opened = await openRecord(
        vaultKey: newKey,
        vaultId: vaultId,
        recordId: recordId,
        keyId: 2,
        ciphertext: resealed,
      );
      expect(opened, {'s': 1, 't': 'person'});
    });
  });

  group('vault key envelope', () {
    test('opens only with the right recovery code', () async {
      final vaultKey = randomBytes(vaultKeyLength);
      final keys = await RecoveryCode.generate().deriveKeys();
      final envelope = await sealVaultKey(
        wrapKey: keys.wrapKey,
        vaultKey: vaultKey,
        vaultId: vaultId,
        keyId: 3,
      );

      expect(
        await openVaultKey(
          wrapKey: keys.wrapKey,
          envelope: envelope,
          vaultId: vaultId,
          keyId: 3,
        ),
        vaultKey,
      );
      final other = await RecoveryCode.generate().deriveKeys();
      await expectLater(
        openVaultKey(
          wrapKey: other.wrapKey,
          envelope: envelope,
          vaultId: vaultId,
          keyId: 3,
        ),
        throwsA(
          isA<SyncCryptoException>().having(
            (e) => e.message,
            'message',
            contains('incorrect'),
          ),
        ),
      );
    });
  });

  group('invite', () {
    test('round-trips all fields and tolerates whitespace from copy/paste', () {
      final invite = SyncInvite(
        serverUrl: Uri.parse('https://sync.example.org'),
        vaultId: vaultId,
        inviteCode: 'abcDEF123_-xyz',
        vaultKey: randomBytes(vaultKeyLength),
        keyId: 2,
      );
      final text = invite.encode();
      expect(text, startsWith(SyncInvite.prefix));

      final wrapped = '${text.substring(0, 30)}\n  ${text.substring(30)} ';
      final parsed = SyncInvite.parse(wrapped);
      expect(parsed.serverUrl, invite.serverUrl);
      expect(parsed.vaultId, vaultId);
      expect(parsed.inviteCode, invite.inviteCode);
      expect(parsed.vaultKey, invite.vaultKey);
      expect(parsed.keyId, 2);
    });

    test('rejects damaged or foreign text', () {
      expect(() => SyncInvite.parse('hello'), throwsFormatException);
      expect(
        () => SyncInvite.parse('${SyncInvite.prefix}not-base64!'),
        throwsFormatException,
      );
      final valid = SyncInvite(
        serverUrl: Uri.parse('https://sync.example.org'),
        vaultId: vaultId,
        inviteCode: 'code',
        vaultKey: randomBytes(vaultKeyLength),
        keyId: 1,
      ).encode();
      expect(
        () => SyncInvite.parse(valid.substring(0, valid.length - 12)),
        throwsFormatException,
      );
    });
  });

  group('server address', () {
    test('requires https except for local development hosts', () {
      expect(
        parseSyncServerUrl(' https://sync.example.org/ ').toString(),
        'https://sync.example.org',
      );
      expect(parseSyncServerUrl('https://example.org/sync/').path, '/sync');
      expect(
        parseSyncServerUrl('http://localhost:5080').toString(),
        'http://localhost:5080',
      );
      expect(parseSyncServerUrl('http://10.0.2.2:5080').host, '10.0.2.2');

      for (final bad in [
        '',
        'sync.example.org',
        'http://sync.example.org',
        'ftp://sync.example.org',
        'https://user:pass@sync.example.org',
        'https://sync.example.org/?token=1',
      ]) {
        expect(
          () => parseSyncServerUrl(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });
  });
}
