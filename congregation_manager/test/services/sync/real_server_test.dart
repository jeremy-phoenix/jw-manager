// End-to-end check of the Dart client against a running
// CongregationManager.Server. Skipped unless these are set:
//
//   SYNC_TEST_SERVER_URL=http://127.0.0.1:5080
//   SYNC_TEST_REGISTRATION_SECRET=<the server's SyncServer:Registration:Secret>
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/services/sync/sync_credentials.dart';
import 'package:congregation_manager/services/sync/sync_crypto.dart';
import 'package:congregation_manager/services/sync/sync_service.dart';

void main() {
  final serverUrl = Platform.environment['SYNC_TEST_SERVER_URL'];
  final secret = Platform.environment['SYNC_TEST_REGISTRATION_SECRET'];
  final skip = serverUrl == null || secret == null
      ? 'Set SYNC_TEST_SERVER_URL and SYNC_TEST_REGISTRATION_SECRET to run.'
      : null;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('two devices sync, resolve a conflict and survive key rotation', () async {
    final laptopDb = AppDatabase.forTesting(NativeDatabase.memory());
    final phoneDb = AppDatabase.forTesting(NativeDatabase.memory());
    final replacementDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      await laptopDb.close();
      await phoneDb.close();
      await replacementDb.close();
    });
    final laptop = SyncService(laptopDb, MemorySyncCredentialStore());
    final phone = SyncService(phoneDb, MemorySyncCredentialStore());
    final replacement = SyncService(replacementDb, MemorySyncCredentialStore());

    final congregationId = await laptopDb.insertCongregation(
      CongregationsCompanion.insert(
        name: const Value('Riverside'),
        circuitOverseerName: const Value('John Overseer'),
      ),
    );
    final personId = await laptopDb.insertPerson(
      PersonsCompanion.insert(
        firstName: const Value('Alice'),
        lastName: const Value('Adams'),
        email: const Value('alice@example.com'),
        congregationId: Value(congregationId),
      ),
    );
    for (var month = 1; month <= 12; month++) {
      await laptopDb.insertServiceReport(
        ServiceReportsCompanion.insert(
          year: 2025,
          month: month,
          personId: personId,
        ),
      );
    }
    await laptopDb.archivePerson(
      personId,
      reason: PersonArchiveReason.transferredOut,
      archivedAt: DateTime.utc(2026, 1, 1),
    );

    final recoveryCode = RecoveryCode.generate();
    await laptop.createVault(
      serverUrl: serverUrl!,
      registrationSecret: secret!,
      deviceLabel: 'Laptop',
      recoveryCode: recoveryCode,
    );
    final uploaded = await laptop.syncNow();
    expect(uploaded.pushed, 14);

    final invite = await laptop.createInvite(
      lifetime: const Duration(minutes: 30),
    );
    await phone.joinWithInvite(
      invite: invite.invite,
      deviceLabel: 'Phone',
      localData: LocalDataChoice.replace,
    );
    final alice = await (phoneDb.select(phoneDb.persons)).getSingle();
    expect(alice.email, 'alice@example.com');
    expect(alice.recordStatus, PersonRecordStatus.archived);
    expect(await phoneDb.getServiceReports(personId: alice.id), hasLength(12));
    expect(
      (await phoneDb.getAllCongregations()).single.circuitOverseerName,
      'John Overseer',
    );

    // Conflicting edits: the second pusher gets the server copy and can restore its own.
    final onLaptop = await laptopDb.getPerson(personId);
    await laptopDb.updatePerson(
      onLaptop.toCompanion(true).copyWith(lastName: const Value('FromLaptop')),
    );
    await laptop.syncNow();
    await phoneDb.updatePerson(
      alice.toCompanion(true).copyWith(lastName: const Value('FromPhone')),
    );
    expect((await phone.syncNow()).conflicts, 1);
    expect((await phoneDb.getPerson(alice.id)).lastName, 'FromLaptop');

    // Rotation re-encrypts on the server; the phone unlocks with the recovery code.
    final rotation = await laptop.rotateKey(
      recoveryCode: recoveryCode.formatted,
    );
    expect(rotation.reencrypted, 14);
    await expectLater(
      phone.syncNow(),
      throwsA(isA<SyncKeyRequiredException>()),
    );
    await phone.unlockWithRecoveryCode(recoveryCode.formatted);
    await phone.syncNow();

    await replacement.recoverWithCode(
      serverUrl: serverUrl,
      recoveryCode: recoveryCode.formatted,
      deviceLabel: 'Replacement',
      localData: LocalDataChoice.replace,
    );
    expect(
      (await replacementDb.select(replacementDb.persons).getSingle()).lastName,
      'FromLaptop',
    );
    final devices = await replacement.listDevices();
    expect(
      devices.map((d) => d.label),
      unorderedEquals(['Laptop', 'Phone', 'Replacement']),
    );

    await laptop.deleteVaultFromServer(recoveryCode.formatted);
    await expectLater(phone.syncNow(), throwsA(isA<SyncException>()));
  }, skip: skip);
}
