import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:congregation_manager/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('insert queues sync payloads with circuit overseer and email', () async {
    await db.saveSyncSettings(
      isEnabled: true,
      serverUrl: 'https://example.com',
    );

    final congId = await db.insertCongregation(
      CongregationsCompanion.insert(
        name: const Value('Riverside'),
        number: const Value('12345'),
        circuitOverseerName: const Value('John Smith'),
        circuitOverseerSpouseName: const Value('Jane Smith'),
        circuitOverseerPhone: const Value('(555) 123-4567'),
        circuitOverseerEmail: const Value('jsmith@example.com'),
        circuitOverseerAddress: const Value('1 Circuit Way'),
      ),
    );
    await db.insertPerson(
      PersonsCompanion.insert(
        firstName: const Value('Alice'),
        lastName: const Value('Adams'),
        email: const Value('alice@example.com'),
        congregationId: Value(congId),
      ),
    );

    final ops = await db.getPendingSyncOperations();
    final congOp = ops.firstWhere((o) => o.entityType == 'congregation');
    final congPayload = jsonDecode(congOp.payloadJson) as Map<String, dynamic>;
    expect(congPayload['circuitOverseerName'], 'John Smith');
    expect(congPayload['circuitOverseerSpouseName'], 'Jane Smith');
    expect(congPayload['circuitOverseerPhone'], '(555) 123-4567');
    expect(congPayload['circuitOverseerEmail'], 'jsmith@example.com');
    expect(congPayload['circuitOverseerAddress'], '1 Circuit Way');

    final personOp = ops.firstWhere((o) => o.entityType == 'person');
    final personPayload =
        jsonDecode(personOp.payloadJson) as Map<String, dynamic>;
    expect(personPayload['email'], 'alice@example.com');
  });

  test('applyRemoteChange round-trips circuit overseer and email', () async {
    await db.applyRemoteChange(
      entityType: 'congregation',
      operationType: 'upsert',
      entitySyncId: 'remote-cong-1',
      serverVersion: 1,
      payload: {
        'name': 'Remote',
        'number': '99',
        'city': 'Town',
        'circuitNumber': 'C-7',
        'circuitOverseerName': 'John Smith',
        'circuitOverseerSpouseName': 'Jane Smith',
        'circuitOverseerPhone': '(555) 123-4567',
        'circuitOverseerEmail': 'jsmith@example.com',
        'circuitOverseerAddress': '1 Circuit Way',
      },
    );
    final cong = await (db.select(
      db.congregations,
    )..where((c) => c.syncId.equals('remote-cong-1'))).getSingle();
    expect(cong.circuitOverseerName, 'John Smith');
    expect(cong.circuitOverseerSpouseName, 'Jane Smith');
    expect(cong.circuitOverseerPhone, '(555) 123-4567');
    expect(cong.circuitOverseerEmail, 'jsmith@example.com');
    expect(cong.circuitOverseerAddress, '1 Circuit Way');

    await db.applyRemoteChange(
      entityType: 'person',
      operationType: 'upsert',
      entitySyncId: 'remote-person-1',
      serverVersion: 1,
      payload: {
        'firstName': 'Alice',
        'lastName': 'Adams',
        'email': 'alice@example.com',
      },
    );
    final person = await (db.select(
      db.persons,
    )..where((p) => p.syncId.equals('remote-person-1'))).getSingle();
    expect(person.email, 'alice@example.com');
  });

  test(
    'applyRemoteChange defaults missing new keys to empty strings',
    () async {
      // Payloads from clients that predate the new columns.
      await db.applyRemoteChange(
        entityType: 'congregation',
        operationType: 'upsert',
        entitySyncId: 'legacy-cong-1',
        serverVersion: 1,
        payload: {
          'name': 'Legacy',
          'number': '1',
          'city': '',
          'circuitNumber': '',
        },
      );
      final cong = await (db.select(
        db.congregations,
      )..where((c) => c.syncId.equals('legacy-cong-1'))).getSingle();
      expect(cong.circuitOverseerName, '');
      expect(cong.circuitOverseerSpouseName, '');
      expect(cong.circuitOverseerPhone, '');
      expect(cong.circuitOverseerEmail, '');
      expect(cong.circuitOverseerAddress, '');

      await db.applyRemoteChange(
        entityType: 'person',
        operationType: 'upsert',
        entitySyncId: 'legacy-person-1',
        serverVersion: 1,
        payload: {'firstName': 'Bob', 'lastName': 'Brown'},
      );
      final person = await (db.select(
        db.persons,
      )..where((p) => p.syncId.equals('legacy-person-1'))).getSingle();
      expect(person.email, '');
    },
  );

  test('migration self-heals a half-applied upgrade', () async {
    // Drift runs onUpgrade without a transaction, so an interrupted upgrade
    // can leave the new columns present while user_version stays behind. The
    // next open then re-runs the migration and must not fail on the columns
    // that already exist.
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}half_applied_migration_test.sqlite',
    );
    if (file.existsSync()) file.deleteSync();
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    var fileDb = AppDatabase.forTesting(NativeDatabase(file));
    await fileDb.insertCongregation(
      CongregationsCompanion.insert(name: const Value('Riverside')),
    );
    await fileDb.customStatement('PRAGMA user_version = 4');
    await fileDb.close();

    fileDb = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(fileDb.close);
    final congs = await fileDb.select(fileDb.congregations).get();
    expect(congs, hasLength(1));
    final version = await fileDb
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((row) => row.data.values.first);
    expect(version, 6);
  });
}
