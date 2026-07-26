import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test(
    'archive preserves history and removes current group leadership',
    () async {
      final fixture = await _createPublisherFixture(db);
      final archivedAt = DateTime(2026, 7, 1);

      await db.archivePerson(
        fixture.personId,
        reason: PersonArchiveReason.transferredOut,
        archivedAt: archivedAt,
      );

      final person = await db.getPerson(fixture.personId);
      expect(person.recordStatus, PersonRecordStatus.archived);
      expect(person.archiveReason, PersonArchiveReason.transferredOut);
      expect(person.archivedAt, archivedAt);
      expect(await db.getAllPersons(), isEmpty);
      expect(
        await db.getAllPersons(recordStatus: PersonRecordStatus.archived),
        hasLength(1),
      );

      expect(await db.getPhoneNumbers(fixture.personId), hasLength(1));
      expect(await db.getEmergencyContacts(fixture.personId), hasLength(1));
      expect(
        await db.getServiceReports(personId: fixture.personId),
        hasLength(1),
      );
      expect(
        await db.getAuxiliaryPioneerPeriods(fixture.personId),
        hasLength(1),
      );
      expect(
        await db.getServiceReports(congregationId: fixture.congregationId),
        isEmpty,
      );

      final group = await db.getFieldServiceGroup(fixture.groupId);
      expect(group.groupOverseerId, isNull);
      expect(group.assistantId, isNull);
    },
  );

  test('Trash restore returns a publisher to their previous state', () async {
    final currentId = await _insertPerson(db, firstName: 'Current');
    await db.movePersonToTrash(currentId);
    expect(
      (await db.getPerson(currentId)).recordStatus,
      PersonRecordStatus.trashed,
    );
    expect(
      await db.restoreTrashedPerson(currentId),
      PersonRecordStatus.current,
    );
    expect(
      (await db.getPerson(currentId)).recordStatus,
      PersonRecordStatus.current,
    );

    final archivedId = await _insertPerson(db, firstName: 'Archived');
    await db.archivePerson(
      archivedId,
      reason: PersonArchiveReason.deceased,
      archivedAt: DateTime(2026, 6, 15),
    );
    await db.movePersonToTrash(archivedId);
    expect(
      await db.restoreTrashedPerson(archivedId),
      PersonRecordStatus.archived,
    );

    final restored = await db.getPerson(archivedId);
    expect(restored.recordStatus, PersonRecordStatus.archived);
    expect(restored.archiveReason, PersonArchiveReason.deceased);
    expect(restored.archivedAt, DateTime(2026, 6, 15));
    expect(restored.trashedAt, isNull);
  });

  test('permanent deletion removes every publisher-owned record', () async {
    final fixture = await _createPublisherFixture(db);
    await db.movePersonToTrash(fixture.personId);

    await db.deletePersonPermanently(fixture.personId);

    expect(
      await (db.select(
        db.persons,
      )..where((p) => p.id.equals(fixture.personId))).getSingleOrNull(),
      isNull,
    );
    expect(await db.getPhoneNumbers(fixture.personId), isEmpty);
    expect(await db.getEmergencyContacts(fixture.personId), isEmpty);
    expect(await db.getServiceReports(personId: fixture.personId), isEmpty);
    expect(await db.getAuxiliaryPioneerPeriods(fixture.personId), isEmpty);

    final group = await db.getFieldServiceGroup(fixture.groupId);
    expect(group.groupOverseerId, isNull);
    expect(group.assistantId, isNull);
  });

  test(
    'archive and Trash sync as upserts; purge syncs child deletes first',
    () async {
      final fixture = await _createPublisherFixture(db);
      await db.saveSyncSettings(
        isEnabled: true,
        serverUrl: 'https://example.com',
      );
      await db.delete(db.pendingSyncOperations).go();

      await db.archivePerson(
        fixture.personId,
        reason: PersonArchiveReason.deceased,
        archivedAt: DateTime(2026, 7, 2),
      );

      var operations = await db.getPendingSyncOperations();
      final archiveOperation = operations.lastWhere(
        (operation) => operation.entityType == 'person',
      );
      expect(archiveOperation.operationType, 'upsert');
      final archivePayload =
          jsonDecode(archiveOperation.payloadJson) as Map<String, dynamic>;
      expect(archivePayload['recordStatus'], PersonRecordStatus.archived.index);
      expect(
        archivePayload['archiveReason'],
        PersonArchiveReason.deceased.index,
      );

      await db.delete(db.pendingSyncOperations).go();
      await db.movePersonToTrash(fixture.personId);
      operations = await db.getPendingSyncOperations();
      final trashOperation = operations.lastWhere(
        (operation) => operation.entityType == 'person',
      );
      expect(trashOperation.operationType, 'upsert');
      final trashPayload =
          jsonDecode(trashOperation.payloadJson) as Map<String, dynamic>;
      expect(trashPayload['recordStatus'], PersonRecordStatus.trashed.index);

      await db.delete(db.pendingSyncOperations).go();
      await db.deletePersonPermanently(fixture.personId);
      operations = await db.getPendingSyncOperations(limit: 20);

      expect(
        operations.map((operation) => operation.entityType),
        containsAll([
          'phoneNumber',
          'emergencyContact',
          'serviceReport',
          'auxiliaryPioneerPeriod',
          'person',
        ]),
      );
      expect(operations.last.entityType, 'person');
      expect(operations.last.operationType, 'delete');
      expect(
        operations.where((operation) => operation.operationType != 'delete'),
        isEmpty,
      );
    },
  );
}

Future<({int congregationId, int groupId, int personId})>
_createPublisherFixture(AppDatabase db) async {
  final congregationId = await db.insertCongregation(
    CongregationsCompanion.insert(name: const Value('Riverside')),
  );
  final personId = await db.insertPerson(
    PersonsCompanion.insert(
      firstName: const Value('Alice'),
      lastName: const Value('Adams'),
      congregationId: Value(congregationId),
    ),
  );
  final groupId = await db.insertFieldServiceGroup(
    FieldServiceGroupsCompanion.insert(
      name: const Value('Group 1'),
      congregationId: Value(congregationId),
      groupOverseerId: Value(personId),
      assistantId: Value(personId),
    ),
  );
  await db.insertPhoneNumber(
    PhoneNumbersCompanion.insert(
      number: const Value('555-0100'),
      personId: personId,
    ),
  );
  await db.insertEmergencyContact(
    EmergencyContactsCompanion.insert(
      name: const Value('Bob Adams'),
      phoneNumber: const Value('555-0101'),
      personId: personId,
    ),
  );
  await db.insertServiceReport(
    ServiceReportsCompanion.insert(year: 2026, month: 6, personId: personId),
  );
  await db.insertAuxiliaryPioneerPeriod(
    AuxiliaryPioneerPeriodsCompanion.insert(
      startMonth: 6,
      startYear: 2026,
      personId: personId,
    ),
  );
  return (congregationId: congregationId, groupId: groupId, personId: personId);
}

Future<int> _insertPerson(AppDatabase db, {required String firstName}) {
  return db.insertPerson(
    PersonsCompanion.insert(
      firstName: Value(firstName),
      lastName: const Value('Publisher'),
    ),
  );
}
