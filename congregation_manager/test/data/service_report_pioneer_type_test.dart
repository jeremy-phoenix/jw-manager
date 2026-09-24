import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';

void main() {
  late AppDatabase db;
  late int congregationId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    congregationId = await db
        .into(db.congregations)
        .insert(CongregationsCompanion.insert(name: const Value('Riverside')));
  });

  tearDown(() => db.close());

  test('new months apply approved auxiliary pioneer periods', () async {
    final publisherId = await _insertPerson(
      db,
      congregationId,
      'Alex',
      PioneerType.none,
    );
    await db.insertAuxiliaryPioneerPeriod(
      AuxiliaryPioneerPeriodsCompanion.insert(
        startMonth: 6,
        startYear: 2026,
        endMonth: const Value(7),
        endYear: const Value(2026),
        personId: publisherId,
      ),
    );

    final juneReports = await db.getOrCreateReportsForPeriod(
      2026,
      6,
      congregationId: congregationId,
    );
    expect(juneReports.single.isAuxiliaryPioneer, isTrue);

    final augustReports = await db.getOrCreateReportsForPeriod(
      2026,
      8,
      congregationId: congregationId,
    );
    expect(augustReports.single.isAuxiliaryPioneer, isFalse);
  });

  test('month statistics use each publisher current pioneer type', () async {
    final publisherId = await _insertPerson(
      db,
      congregationId,
      'Publisher',
      PioneerType.none,
    );
    final auxiliaryId = await _insertPerson(
      db,
      congregationId,
      'Auxiliary',
      PioneerType.none,
    );
    final regularId = await _insertPerson(
      db,
      congregationId,
      'Regular',
      PioneerType.regularPioneer,
    );
    final specialId = await _insertPerson(
      db,
      congregationId,
      'Special',
      PioneerType.specialPioneer,
    );
    final missionaryId = await _insertPerson(
      db,
      congregationId,
      'Missionary',
      PioneerType.fieldMissionary,
    );

    await _insertReport(db, publisherId, hours: 1);
    await _insertReport(db, auxiliaryId, isAuxiliaryPioneer: true, hours: 2);
    await _insertReport(db, regularId, hours: 3);
    await _insertReport(db, specialId, hours: 4);
    await _insertReport(db, missionaryId, hours: 5);

    var stats = await db.getMonthStatistics(
      2026,
      6,
      congregationId: congregationId,
    );

    expect(stats.publishers.personIds, [publisherId]);
    expect(stats.auxiliaryPioneers.personIds, [auxiliaryId]);
    expect(stats.regularPioneers.personIds, [regularId]);
    expect(stats.specialPioneers.personIds, [specialId]);
    expect(stats.fieldMissionaries.personIds, [missionaryId]);

    await db.updatePersonPioneerType(regularId, PioneerType.specialPioneer);
    stats = await db.getMonthStatistics(
      2026,
      6,
      congregationId: congregationId,
    );

    expect(stats.regularPioneers.personIds, isEmpty);
    expect(stats.specialPioneers.personIds, [regularId, specialId]);
  });
}

Future<int> _insertPerson(
  AppDatabase db,
  int congregationId,
  String firstName,
  PioneerType pioneerType,
) {
  return db
      .into(db.persons)
      .insert(
        PersonsCompanion.insert(
          firstName: Value(firstName),
          lastName: const Value('Test'),
          congregationId: Value(congregationId),
          pioneerType: Value(pioneerType),
        ),
      );
}

Future<void> _insertReport(
  AppDatabase db,
  int personId, {
  bool isAuxiliaryPioneer = false,
  required double hours,
}) async {
  await db
      .into(db.serviceReports)
      .insert(
        ServiceReportsCompanion.insert(
          year: 2026,
          month: 6,
          personId: personId,
          isAuxiliaryPioneer: Value(isAuxiliaryPioneer),
          sharedInMinistry: const Value(true),
          bibleStudies: const Value(1),
          hours: Value(hours),
        ),
      );
}
