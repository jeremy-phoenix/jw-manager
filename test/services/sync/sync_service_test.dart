import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/services/sync/sync_api_client.dart';
import 'package:congregation_manager/services/sync/sync_credentials.dart';
import 'package:congregation_manager/services/sync/sync_crypto.dart';
import 'package:congregation_manager/services/sync/sync_service.dart';

import 'fake_sync_server.dart';

const serverUrl = 'https://sync.test';

class TestDevice {
  TestDevice(this.server, {this.name = 'Test device'}) {
    sync = SyncService(
      db,
      credentials,
      apiFactory: (url, {deviceToken}) => SyncApiClient(
        url,
        deviceToken: deviceToken,
        httpClient: server.client,
      ),
      backupBeforeReplace: () async {
        backups++;
        return 'backup';
      },
    );
  }

  final FakeSyncServer server;
  final String name;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final credentials = MemorySyncCredentialStore();
  late final SyncService sync;
  var backups = 0;

  Future<SyncSetting> get settings => db.getSyncSettings();

  Future<Person> person(String firstName) => (db.select(
    db.persons,
  )..where((p) => p.firstName.equals(firstName))).getSingle();

  Future<void> close() async {
    sync.dispose();
    await db.close();
  }
}

/// Seeds a congregation with every field the old server used to drop.
Future<({int congregationId, int personId})> seedCongregation(
  AppDatabase db,
) async {
  final congregationId = await db.insertCongregation(
    CongregationsCompanion.insert(
      name: const Value('Riverside'),
      circuitOverseerName: const Value('John Overseer'),
      circuitOverseerEmail: const Value('co@example.com'),
    ),
  );
  final personId = await db.insertPerson(
    PersonsCompanion.insert(
      firstName: const Value('Alice'),
      lastName: const Value('Adams'),
      email: const Value('alice@example.com'),
      address: const Value('12 Hidden Lane'),
      congregationId: Value(congregationId),
    ),
  );
  await db.insertPhoneNumber(
    PhoneNumbersCompanion.insert(
      number: const Value('555-0101'),
      personId: personId,
    ),
  );
  await db.insertServiceReport(
    ServiceReportsCompanion.insert(
      year: 2026,
      month: 3,
      personId: personId,
      note: const Value('confidential note'),
    ),
  );
  return (congregationId: congregationId, personId: personId);
}

void main() {
  late FakeSyncServer server;
  late TestDevice laptop;
  late RecoveryCode recoveryCode;
  final devices = <TestDevice>[];

  TestDevice newDevice([String name = 'Phone']) {
    final device = TestDevice(server, name: name);
    devices.add(device);
    return device;
  }

  Future<TestDevice> joinByInvite({
    LocalDataChoice localData = LocalDataChoice.replace,
    TestDevice? device,
  }) async {
    final invite = await laptop.sync.createInvite();
    final joining = device ?? newDevice();
    await joining.sync.joinWithInvite(
      invite: invite.invite,
      deviceLabel: joining.name,
      localData: localData,
    );
    return joining;
  }

  // Each simulated device has its own in-memory database on purpose.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  setUp(() async {
    server = FakeSyncServer();
    laptop = newDevice('Laptop');
    await seedCongregation(laptop.db);
    recoveryCode = RecoveryCode.generate();
    await laptop.sync.createVault(
      serverUrl: serverUrl,
      registrationSecret: server.registrationSecret,
      deviceLabel: 'Laptop',
      recoveryCode: recoveryCode,
    );
    await laptop.sync.syncNow();
  });

  tearDown(() async {
    for (final device in devices) {
      await device.close();
    }
    devices.clear();
  });

  test('the server only ever receives ciphertext', () async {
    final vaultId = (await laptop.settings).vaultId!;
    expect(server.recordsOf(vaultId), hasLength(4));
    for (final secret in [
      'Alice',
      'alice@example.com',
      '12 Hidden Lane',
      'confidential note',
      'Riverside',
      'John Overseer',
      '555-0101',
      'Laptop',
      recoveryCode.formatted,
    ]) {
      expect(
        server.requestBodies.join(),
        isNot(contains(secret)),
        reason: secret,
      );
      expect(
        server
            .recordsOf(vaultId)
            .map(
              (r) =>
                  utf8.decode(base64Decode(r.ciphertext), allowMalformed: true),
            )
            .join(),
        isNot(contains(secret)),
        reason: secret,
      );
    }
    expect(await laptop.db.getPendingSyncOperationCount(), 0);
  });

  test('credentials stay out of the database', () async {
    final settings = await laptop.settings;
    final stored = await laptop.credentials.read(settings.vaultId!);
    expect(stored, isNotNull);
    final dump = jsonEncode(settings.toJson());
    expect(dump, isNot(contains(stored!.deviceToken)));
    expect(dump, isNot(contains(base64Encode(stored.keys[1]!))));
  });

  test(
    'a joined device receives every field, including ones the old server dropped',
    () async {
      await laptop.db.archivePerson(
        (await laptop.person('Alice')).id,
        reason: PersonArchiveReason.transferredOut,
        archivedAt: DateTime.utc(2026, 5, 1),
      );
      await laptop.sync.syncNow();

      final phone = await joinByInvite();

      final alice = await phone.person('Alice');
      expect(alice.email, 'alice@example.com');
      expect(alice.address, '12 Hidden Lane');
      expect(alice.recordStatus, PersonRecordStatus.archived);
      expect(alice.archiveReason, PersonArchiveReason.transferredOut);
      expect(alice.archivedAt, isNotNull);
      final congregation = (await phone.db.getAllCongregations()).single;
      expect(congregation.circuitOverseerName, 'John Overseer');
      expect(congregation.circuitOverseerEmail, 'co@example.com');
      expect(alice.congregationId, congregation.id);
      expect(
        (await phone.db.getPhoneNumbers(alice.id)).single.number,
        '555-0101',
      );
      expect(
        (await phone.db.getServiceReports(personId: alice.id)).single.note,
        'confidential note',
      );

      // The originating device's own data survives the round trip too.
      final laptopAlice = await laptop.person('Alice');
      expect(laptopAlice.recordStatus, PersonRecordStatus.archived);
      expect(laptopAlice.email, 'alice@example.com');
    },
  );

  test(
    'records older than their publisher are not lost on a new device',
    () async {
      // The publisher is edited after the phone number was created, so it comes
      // later in the change feed than its phone number.
      final alice = await laptop.person('Alice');
      await laptop.db.updatePerson(
        alice.toCompanion(true).copyWith(lastName: const Value('Baker')),
      );
      await laptop.sync.syncNow();

      final phone = await joinByInvite();

      final synced = await phone.person('Alice');
      expect(synced.lastName, 'Baker');
      expect(await phone.db.getPhoneNumbers(synced.id), hasLength(1));
      expect(
        await phone.db.getServiceReports(personId: synced.id),
        hasLength(1),
      );
    },
  );

  test(
    'editing a record twice between syncs does not conflict with itself',
    () async {
      final alice = await laptop.person('Alice');
      await laptop.db.updatePerson(
        alice.toCompanion(true).copyWith(lastName: const Value('One')),
      );
      await laptop.db.updatePerson(
        (await laptop.person(
          'Alice',
        )).toCompanion(true).copyWith(lastName: const Value('Two')),
      );
      expect(await laptop.db.getPendingSyncOperationCount(), 1);

      final result = await laptop.sync.syncNow();

      expect(result.conflicts, 0);
      expect(result.pushed, 1);
      final phone = await joinByInvite();
      expect((await phone.person('Alice')).lastName, 'Two');
    },
  );

  test(
    'a concurrent edit keeps the server version and saves the local one',
    () async {
      final phone = await joinByInvite();

      final onLaptop = await laptop.person('Alice');
      await laptop.db.updatePerson(
        onLaptop
            .toCompanion(true)
            .copyWith(lastName: const Value('FromLaptop')),
      );
      await laptop.sync.syncNow();
      final onPhone = await phone.person('Alice');
      await phone.db.updatePerson(
        onPhone.toCompanion(true).copyWith(lastName: const Value('FromPhone')),
      );

      final result = await phone.sync.syncNow();

      expect(result.conflicts, 1);
      expect((await phone.person('Alice')).lastName, 'FromLaptop');
      final conflict =
          (await phone.db.select(phone.db.syncConflicts).get()).single;

      await phone.db.restoreLocalVersionFromConflict(conflict.id);
      expect((await phone.person('Alice')).lastName, 'FromPhone');
      expect((await phone.sync.syncNow()).conflicts, 0);
      await laptop.sync.syncNow();
      expect((await laptop.person('Alice')).lastName, 'FromPhone');
      expect(await phone.db.getOpenSyncConflictCount(), 0);
    },
  );

  test('deletes propagate, including everything a publisher owned', () async {
    final phone = await joinByInvite();
    final alice = await laptop.person('Alice');

    await laptop.db.movePersonToTrash(alice.id);
    await laptop.db.deletePersonPermanently(alice.id);
    await laptop.sync.syncNow();
    await phone.sync.syncNow();

    expect(await phone.db.select(phone.db.persons).get(), isEmpty);
    expect(await phone.db.select(phone.db.phoneNumbers).get(), isEmpty);
    expect(await phone.db.select(phone.db.serviceReports).get(), isEmpty);
  });

  test('an invite works once', () async {
    final invite = await laptop.sync.createInvite();
    await newDevice().sync.joinWithInvite(
      invite: invite.invite,
      deviceLabel: 'Phone',
      localData: LocalDataChoice.replace,
    );

    expect(
      () => newDevice('Tablet').sync.joinWithInvite(
        invite: invite.invite,
        deviceLabel: 'Tablet',
        localData: LocalDataChoice.replace,
      ),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('invite'),
        ),
      ),
    );
  });

  test('joining with replace backs up and replaces local data', () async {
    final phone = newDevice();
    await phone.db.insertCongregation(
      CongregationsCompanion.insert(name: const Value('Scratch')),
    );

    await joinByInvite(device: phone);

    expect(phone.backups, 1);
    expect((await phone.db.getAllCongregations()).map((c) => c.name), [
      'Riverside',
    ]);
  });

  test('joining with merge uploads local-only records', () async {
    final tablet = newDevice('Tablet');
    await tablet.db.insertCongregation(
      CongregationsCompanion.insert(name: const Value('Hillside')),
    );

    await joinByInvite(device: tablet, localData: LocalDataChoice.merge);
    await laptop.sync.syncNow();

    expect(tablet.backups, 0);
    expect(
      (await laptop.db.getAllCongregations()).map((c) => c.name),
      unorderedEquals(['Riverside', 'Hillside']),
    );
  });

  test('the recovery code enrolls a new device', () async {
    final replacement = newDevice('Replacement');

    await replacement.sync.recoverWithCode(
      serverUrl: serverUrl,
      recoveryCode: recoveryCode.formatted,
      deviceLabel: 'Replacement',
      localData: LocalDataChoice.replace,
    );

    expect((await replacement.person('Alice')).email, 'alice@example.com');
    expect(
      () => newDevice('Thief').sync.recoverWithCode(
        serverUrl: serverUrl,
        recoveryCode: RecoveryCode.generate().formatted,
        deviceLabel: 'Thief',
        localData: LocalDataChoice.replace,
      ),
      throwsA(isA<SyncException>()),
    );
  });

  test(
    'a removed device loses access and key rotation re-encrypts everything',
    () async {
      final phone = await joinByInvite();
      final stolen = await joinByInvite(device: newDevice('Stolen'));
      final vaultId = (await laptop.settings).vaultId!;
      final listed = await laptop.sync.listDevices();
      expect(
        listed.map((d) => d.label),
        unorderedEquals(['Laptop', 'Phone', 'Stolen']),
      );

      await laptop.sync.revokeDevice(
        listed.firstWhere((d) => d.label == 'Stolen').deviceId,
      );
      await expectLater(stolen.sync.syncNow(), throwsA(isA<SyncException>()));

      final rotation = await laptop.sync.rotateKey(
        recoveryCode: recoveryCode.formatted,
      );
      expect(rotation.reencrypted, 4);
      expect(rotation.unreadable, 0);
      expect(server.recordsOf(vaultId).every((r) => r.keyId == 2), isTrue);
      expect(
        (await laptop.sync.listDevices()).map((d) => d.label),
        unorderedEquals(['Laptop', 'Phone']),
      );

      // Another device must unlock the new key before it can sync again.
      await laptop.db.updatePerson(
        (await laptop.person(
          'Alice',
        )).toCompanion(true).copyWith(lastName: const Value('Rotated')),
      );
      await laptop.sync.syncNow();
      await expectLater(
        phone.sync.syncNow(),
        throwsA(isA<SyncKeyRequiredException>()),
      );
      expect((await phone.settings).needsKey, isTrue);

      await phone.sync.unlockWithRecoveryCode(recoveryCode.formatted);

      expect((await phone.settings).needsKey, isFalse);
      expect((await phone.person('Alice')).lastName, 'Rotated');
    },
  );

  test('rotation can replace the recovery code', () async {
    final newCode = RecoveryCode.generate();

    await laptop.sync.rotateKey(
      recoveryCode: recoveryCode.formatted,
      newRecoveryCode: newCode,
    );

    await expectLater(
      newDevice('Old code').sync.recoverWithCode(
        serverUrl: serverUrl,
        recoveryCode: recoveryCode.formatted,
        deviceLabel: 'Old code',
        localData: LocalDataChoice.replace,
      ),
      throwsA(isA<SyncException>()),
    );
    final recovered = newDevice('New code');
    await recovered.sync.recoverWithCode(
      serverUrl: serverUrl,
      recoveryCode: newCode.formatted,
      deviceLabel: 'New code',
      localData: LocalDataChoice.replace,
    );
    expect((await recovered.person('Alice')).email, 'alice@example.com');
  });

  test('a wrong recovery code changes nothing', () async {
    final vaultId = (await laptop.settings).vaultId!;

    await expectLater(
      laptop.sync.rotateKey(recoveryCode: RecoveryCode.generate().formatted),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('incorrect'),
        ),
      ),
    );
    expect(server.vaults[vaultId]!.currentKeyId, 1);
  });

  test(
    'importing a JSON backup while enrolled replaces the vault contents',
    () async {
      final phone = await joinByInvite();
      final export = await laptop.db.exportAllDataAsJson();
      (export['persons'] as List).first['firstName'] = 'Imported';

      await laptop.db.importFromJson(export);
      await laptop.sync.syncNow();
      await phone.sync.syncNow();

      final names = (await phone.db.select(phone.db.persons).get()).map(
        (p) => p.firstName,
      );
      expect(names, ['Imported']);
      expect(await phone.db.select(phone.db.congregations).get(), hasLength(1));
    },
  );

  test('disconnecting keeps local data but forgets sync secrets', () async {
    final vaultId = (await laptop.settings).vaultId!;

    await laptop.sync.disconnect();

    final settings = await laptop.settings;
    expect(settings.isEnabled, isFalse);
    expect(settings.vaultId, isNull);
    expect(settings.serverUrl, serverUrl);
    expect(await laptop.credentials.read(vaultId), isNull);
    expect(await laptop.person('Alice'), isNotNull);
    await laptop.db.updatePerson(
      (await laptop.person(
        'Alice',
      )).toCompanion(true).copyWith(lastName: const Value('Offline')),
    );
    expect(await laptop.db.getPendingSyncOperationCount(), 0);
  });

  test(
    'deleting the vault requires the recovery code and disconnects',
    () async {
      final vaultId = (await laptop.settings).vaultId!;

      await expectLater(
        laptop.sync.deleteVaultFromServer(RecoveryCode.generate().formatted),
        throwsA(isA<SyncException>()),
      );
      await laptop.sync.deleteVaultFromServer(recoveryCode.formatted);

      expect(server.vaults.containsKey(vaultId), isFalse);
      expect((await laptop.settings).isEnabled, isFalse);
    },
  );

  test('vault creation reports a wrong registration secret clearly', () async {
    final other = newDevice('Other');

    await expectLater(
      other.sync.createVault(
        serverUrl: serverUrl,
        registrationSecret: 'wrong',
        deviceLabel: 'Other',
        recoveryCode: RecoveryCode.generate(),
      ),
      throwsA(
        isA<SyncException>().having(
          (e) => e.message,
          'message',
          contains('registration secret'),
        ),
      ),
    );
    expect((await other.settings).isEnabled, isFalse);
  });
}
