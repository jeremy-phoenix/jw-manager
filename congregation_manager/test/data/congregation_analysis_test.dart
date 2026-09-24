import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/data/service_year.dart';

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

  Future<int> person({
    bool active = true,
    PioneerType pioneer = PioneerType.none,
    PersonRecordStatus status = PersonRecordStatus.current,
    int? congregation,
  }) => db
      .into(db.persons)
      .insert(
        PersonsCompanion.insert(
          firstName: const Value('Publisher'),
          congregationId: Value(congregation ?? congregationId),
          isActive: Value(active),
          pioneerType: Value(pioneer),
          recordStatus: Value(status),
        ),
      );

  Future<void> report(int id, int year, int month, {bool shared = true}) async {
    await db
        .into(db.serviceReports)
        .insert(
          ServiceReportsCompanion.insert(
            personId: id,
            year: serviceYearOf(year, month),
            month: month,
            sharedInMinistry: Value(shared),
          ),
        );
  }

  test(
    'active means one of six calendar months, including the cutoff',
    () async {
      final stale = await person();
      final boundary = await person();
      final recent = await person(active: false);
      await report(stale, 2026, 2);
      await report(boundary, 2026, 3);
      await report(recent, 2026, 8);
      // Later saved activity must not leak into an earlier analysis.
      await report(stale, 2026, 9);

      final result = await db.getCongregationAnalysis(
        congregationId: congregationId,
        serviceYear: 2026,
      );
      expect(result.allActivePersonIds, unorderedEquals([boundary, recent]));
      expect(result.newInactivePersonIds, [stale]);
    },
  );

  test('missing months count and inactivity can cross September', () async {
    final id = await person(active: false);
    await report(id, 2025, 3);
    final result = await db.getCongregationAnalysis(
      congregationId: congregationId,
      serviceYear: 2026,
    );
    // April through September 2025: the sixth month is in service year 2026.
    expect(result.newInactivePersonIds, [id]);
    expect(result.allActivePublishers, 0);
  });

  test(
    'continuing inactivity from a previous service year is excluded',
    () async {
      final id = await person(active: false);
      await report(id, 2025, 2);
      final result = await db.getCongregationAnalysis(serviceYear: 2026);
      expect(result.newInactivePublishers, 0);
      expect(result.allActivePublishers, 0);
      expect(result.reactivatedPublishers, 0);
    },
  );

  test(
    'a person may be newly inactive and reactivated in the same year',
    () async {
      final id = await person();
      await report(id, 2025, 8);
      await report(id, 2026, 3);
      final result = await db.getCongregationAnalysis(serviceYear: 2026);
      expect(result.newInactivePersonIds, [id]);
      expect(result.reactivatedPersonIds, [id]);
      expect(result.allActivePersonIds, [id]);
    },
  );

  test(
    'prior-year inactivity can reactivate, once per person per year',
    () async {
      final id = await person();
      await report(id, 2025, 2);
      await report(id, 2025, 9);
      await report(id, 2026, 4);
      final result = await db.getCongregationAnalysis(serviceYear: 2026);
      expect(result.reactivatedPersonIds, [id]);
      expect(result.newInactivePersonIds, [id]);
    },
  );

  test('old reactivations are not carried into a later year', () async {
    final id = await person();
    await report(id, 2024, 9);
    await report(id, 2025, 4);
    final result = await db.getCongregationAnalysis(serviceYear: 2026);
    expect(result.reactivatedPublishers, 0);
    expect(result.newInactivePersonIds, [id]);
  });

  test('through month limits activity and both kinds of transition', () async {
    final id = await person();
    await report(id, 2025, 8);
    await report(id, 2026, 3);
    final january = await db.getCongregationAnalysis(
      serviceYear: 2026,
      throughMonth: 1,
    );
    expect(january.allActivePersonIds, [id]);
    expect(january.newInactivePublishers, 0);
    expect(january.reactivatedPublishers, 0);
    final february = await db.getCongregationAnalysis(
      serviceYear: 2026,
      throughMonth: 2,
    );
    expect(february.allActivePublishers, 0);
    expect(february.newInactivePersonIds, [id]);
    expect(february.reactivatedPublishers, 0);
  });

  test('includes all pioneer types and unbaptized publishers', () async {
    final ids = <int>[];
    for (final type in PioneerType.values) {
      final id = await person(pioneer: type);
      ids.add(id);
      await report(id, 2026, 8);
    }
    final result = await db.getCongregationAnalysis(serviceYear: 2026);
    expect(result.allActivePersonIds, unorderedEquals(ids));
  });

  test('respects congregation and record lifecycle boundaries', () async {
    final current = await person();
    final archived = await person(status: PersonRecordStatus.archived);
    final trashed = await person(status: PersonRecordStatus.trashed);
    final otherCongregation = await db
        .into(db.congregations)
        .insert(CongregationsCompanion.insert(name: const Value('Other')));
    final other = await person(congregation: otherCongregation);
    final deleted = await person();
    await (db.update(db.persons)..where((p) => p.id.equals(deleted))).write(
      PersonsCompanion(deletedAt: Value(DateTime(2026, 9))),
    );
    for (final id in [current, archived, trashed, other, deleted]) {
      await report(id, 2026, 8);
    }
    final result = await db.getCongregationAnalysis(
      congregationId: congregationId,
      serviceYear: 2026,
    );
    expect(result.allActivePersonIds, [current]);
  });

  test(
    'does not invent earlier history for new or unreported people',
    () async {
      await person();
      final firstReport = await person();
      await report(firstReport, 2026, 8);
      final futureOnly = await person();
      await report(futureOnly, 2026, 9);
      final result = await db.getCongregationAnalysis(serviceYear: 2026);
      expect(result.allActivePersonIds, [firstReport]);
      expect(result.newInactivePublishers, 0);
      expect(result.reactivatedPublishers, 0);
    },
  );

  test(
    'new July publisher with a prefilled year is only counted as active',
    () async {
      final id = await person();
      // An imported S-21 saves all twelve months, including the blank months
      // before the person became a publisher in July.
      for (final month in [9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8]) {
        await report(
          id,
          month >= 9 ? 2025 : 2026,
          month,
          shared: month == 7 || month == 8,
        );
      }
      final result = await db.getCongregationAnalysis(serviceYear: 2026);
      expect(result.allActivePersonIds, [id]);
      expect(result.newInactivePublishers, 0);
      expect(result.reactivatedPublishers, 0);

      // Even when analyzing before their first report, the leading blank
      // months must not be mistaken for a period of inactivity.
      final june = await db.getCongregationAnalysis(
        serviceYear: 2026,
        throughMonth: 6,
      );
      expect(june.allActivePublishers, 0);
      expect(june.newInactivePublishers, 0);
      expect(june.reactivatedPublishers, 0);
    },
  );

  test('blank years do not establish earlier ministry activity', () async {
    final id = await person();
    await report(id, 2024, 9, shared: false);
    await report(id, 2025, 9, shared: false);
    await report(id, 2026, 7);
    await report(id, 2026, 8);
    final result = await db.getCongregationAnalysis(serviceYear: 2026);
    expect(result.allActivePersonIds, [id]);
    expect(result.newInactivePublishers, 0);
    expect(result.reactivatedPublishers, 0);
  });

  test(
    'a person with only blank reports has no activity transitions',
    () async {
      final id = await person();
      for (final month in [9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8]) {
        await report(id, month >= 9 ? 2025 : 2026, month, shared: false);
      }
      final result = await db.getCongregationAnalysis(serviceYear: 2026);
      expect(result.allActivePublishers, 0);
      expect(result.newInactivePublishers, 0);
      expect(result.reactivatedPublishers, 0);
    },
  );

  test(
    'one recorded year can contain genuine inactivity and reactivation',
    () async {
      final id = await person();
      await report(id, 2025, 9);
      await report(id, 2026, 4);
      // October through March are six months after actual ministry activity,
      // so these transitions are valid even within a person's first year.
      final march = await db.getCongregationAnalysis(
        serviceYear: 2026,
        throughMonth: 3,
      );
      expect(march.allActivePublishers, 0);
      expect(march.newInactivePersonIds, [id]);
      expect(march.reactivatedPublishers, 0);
      final august = await db.getCongregationAnalysis(serviceYear: 2026);
      expect(august.allActivePersonIds, [id]);
      expect(august.newInactivePersonIds, [id]);
      expect(august.reactivatedPersonIds, [id]);
    },
  );

  test(
    'duplicate and deleted reports do not create months of inactivity',
    () async {
      final id = await person();
      for (var i = 0; i < 6; i++) {
        await report(id, 2026, 8, shared: false);
      }
      await report(id, 2026, 3, shared: false);
      await (db.update(db.serviceReports)..where((r) => r.month.equals(3)))
          .write(ServiceReportsCompanion(deletedAt: Value(DateTime(2026, 9))));
      final result = await db.getCongregationAnalysis(serviceYear: 2026);
      expect(result.newInactivePublishers, 0);
      expect(result.allActivePublishers, 0);
    },
  );
}
