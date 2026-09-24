import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/statistics.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';

/// The twelve months of a service year in chronological order.
const _serviceYearMonths = [9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8];

/// Insert one person whose service year 2026 reports follow [sharedByMonth],
/// given in service-year order starting at September.
Future<void> _insertPersonWithYear(
  AppDatabase db, {
  required int personId,
  required int congregationId,
  required List<bool> sharedByMonth,
}) async {
  await db
      .into(db.persons)
      .insert(
        PersonsCompanion.insert(
          id: Value(personId),
          firstName: const Value('Publisher'),
          lastName: Value('Number $personId'),
          congregationId: Value(congregationId),
        ),
      );
  for (var i = 0; i < _serviceYearMonths.length; i++) {
    await db
        .into(db.serviceReports)
        .insert(
          ServiceReportsCompanion.insert(
            year: 2026,
            month: _serviceYearMonths[i],
            personId: personId,
            sharedInMinistry: Value(sharedByMonth[i]),
          ),
        );
  }
}

Future<int> _insertCongregation(AppDatabase db) => db
    .into(db.congregations)
    .insert(CongregationsCompanion.insert(name: const Value('Riverside')));

void main() {
  group('serviceReportPeriodIndex', () {
    test('orders a service year from September through August', () {
      final indexes = [
        for (final month in _serviceYearMonths)
          serviceReportPeriodIndex(2026, month),
      ];

      expect(indexes, orderedEquals(List<int>.from(indexes)..sort()));
      // The trap: January belongs to the same stored year as September but
      // falls four months after it, not eight months before it.
      expect(
        serviceReportPeriodIndex(2026, 9),
        lessThan(serviceReportPeriodIndex(2026, 1)),
      );
    });

    test('orders across service years', () {
      expect(
        serviceReportPeriodIndex(2026, 8),
        lessThan(serviceReportPeriodIndex(2027, 9)),
      );
      expect(
        serviceReportPeriodIndex(2025, 9),
        lessThan(serviceReportPeriodIndex(2026, 9)),
      );
    });
  });

  group('getCongregationAnalysis orders reports chronologically', () {
    test(
      'counts a publisher who stopped after November as newly inactive',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final congregationId = await _insertCongregation(db);

        // Shared September through November, then nothing for nine months.
        await _insertPersonWithYear(
          db,
          personId: 1,
          congregationId: congregationId,
          sharedByMonth: const [
            true, true, true, // Sep Oct Nov
            false, false, false, false, false, false, false, false, false,
          ],
        );

        final analysis = await db.getCongregationAnalysis(
          congregationId: congregationId,
          serviceYear: 2026,
        );

        expect(analysis.newInactivePublishers, 1);
        expect(analysis.allActivePublishers, 0);
        expect(analysis.reactivatedPublishers, 0);
      },
    );

    test('counts a publisher who resumed in March as reactivated', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final congregationId = await _insertCongregation(db);

      // Shared in the preceding August, nothing September through February,
      // then resumed March through August. The earlier activity distinguishes
      // a returning publisher from someone reporting for the first time.
      await _insertPersonWithYear(
        db,
        personId: 1,
        congregationId: congregationId,
        sharedByMonth: const [
          false, false, false, false, false, false, // Sep..Feb
          true, true, true, true, true, true, // Mar..Aug
        ],
      );
      await db
          .into(db.serviceReports)
          .insert(
            ServiceReportsCompanion.insert(
              year: 2025,
              month: 8,
              personId: 1,
              sharedInMinistry: const Value(true),
            ),
          );

      final analysis = await db.getCongregationAnalysis(
        congregationId: congregationId,
        serviceYear: 2026,
      );

      expect(analysis.reactivatedPublishers, 1);
      expect(analysis.allActivePublishers, 1);
      // Reaching six months without reporting and then resuming in the same
      // service year counts the person in both categories.
      expect(analysis.newInactivePublishers, 1);
    });
  });

  test(
    'serviceYearsProvider lists stored years without inventing one',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final congregationId = await _insertCongregation(db);

      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              id: const Value(1),
              firstName: const Value('Publisher'),
              lastName: const Value('One'),
              congregationId: Value(congregationId),
            ),
          );
      // September of service year 2020 — the month that used to be counted
      // forward into a service year 2021 that holds no reports at all.
      await db
          .into(db.serviceReports)
          .insert(
            ServiceReportsCompanion.insert(year: 2020, month: 9, personId: 1),
          );

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      final years = await container.read(serviceYearsProvider.future);

      expect(years, contains(2020));
      expect(years, isNot(contains(2021)));
    },
  );
}
