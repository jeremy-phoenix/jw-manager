import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/data/statistics.dart';
import 'package:congregation_manager/reporting/ministry_totals_report.dart';

final _now = DateTime(2026, 1, 1);

Person _person({
  required int id,
  PioneerType pioneerType = PioneerType.none,
  bool isActive = true,
}) {
  return Person(
    id: id,
    firstName: 'Publisher',
    lastName: 'Number $id',
    otherNames: '',
    birthDate: null,
    baptismDate: null,
    gender: Gender.unknown,
    hopeClass: HopeClass.unknown,
    congregationRole: CongregationRole.none,
    pioneerType: pioneerType,
    address: '',
    email: '',
    isActive: isActive,
    recordStatus: PersonRecordStatus.current,
    congregationId: 1,
    fieldServiceGroupId: null,
    serverVersion: 0,
    createdAt: _now,
    updatedAt: _now,
  );
}

ServiceReport _report({
  required int id,
  required int personId,
  required int month,
  int year = 2026,
  bool sharedInMinistry = true,
  bool isAuxiliaryPioneer = false,
  int bibleStudies = 0,
  double hours = 0,
}) {
  return ServiceReport(
    serverVersion: 0,
    id: id,
    year: year,
    month: month,
    isAuxiliaryPioneer: isAuxiliaryPioneer,
    isActive: true,
    sharedInMinistry: sharedInMinistry,
    bibleStudies: bibleStudies,
    hours: hours,
    note: '',
    personId: personId,
  );
}

MinistryTotalsSection _section(
  List<MinistryTotalsSection> sections,
  FieldServicePublisherCategory category,
) => sections.firstWhere((s) => s.category == category);

void main() {
  group('buildMinistryTotals', () {
    test('always includes the three standard sections, months in order', () {
      final sections = buildMinistryTotals(
        persons: const [],
        reports: const [],
        serviceYear: 2026,
      );

      expect(sections.map((s) => s.category), [
        FieldServicePublisherCategory.publisher,
        FieldServicePublisherCategory.auxiliaryPioneer,
        FieldServicePublisherCategory.regularPioneer,
      ]);
      expect(sections.first.months.map((m) => m.month.displayName).toList(), [
        'September',
        'October',
        'November',
        'December',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
      ]);
      expect(sections.first.hasReports, isFalse);
      expect(sections.first.averageBibleStudies, 0);
    });

    test('splits publishers, auxiliary and regular pioneers by month', () {
      final persons = [
        _person(id: 1),
        _person(id: 2),
        _person(id: 3, pioneerType: PioneerType.regularPioneer),
      ];
      final reports = [
        // September: two publishers (one of them auxiliary) and a regular.
        _report(id: 1, personId: 1, month: 9, bibleStudies: 2),
        _report(
          id: 2,
          personId: 2,
          month: 9,
          isAuxiliaryPioneer: true,
          bibleStudies: 3,
          hours: 30,
        ),
        _report(id: 3, personId: 3, month: 9, bibleStudies: 5, hours: 55.5),
        // October: only the publisher and the regular pioneer reported.
        _report(id: 4, personId: 1, month: 10, bibleStudies: 4),
        _report(id: 5, personId: 3, month: 10, bibleStudies: 7, hours: 60),
      ];

      final sections = buildMinistryTotals(
        persons: persons,
        reports: reports,
        serviceYear: 2026,
      );

      final publishers = _section(
        sections,
        FieldServicePublisherCategory.publisher,
      );
      expect(publishers.showsHours, isFalse);
      expect(publishers.months[0].reportingPublishers, 1);
      expect(publishers.months[0].bibleStudies, 2);
      expect(publishers.months[1].bibleStudies, 4);
      expect(publishers.totalBibleStudies, 6);
      expect(publishers.reportedMonthCount, 2);
      expect(publishers.averageBibleStudies, 3);

      final auxiliary = _section(
        sections,
        FieldServicePublisherCategory.auxiliaryPioneer,
      );
      expect(auxiliary.reportedMonthCount, 1);
      expect(auxiliary.totalHours, 30);
      expect(auxiliary.totalBibleStudies, 3);

      final regular = _section(
        sections,
        FieldServicePublisherCategory.regularPioneer,
      );
      expect(regular.totalHours, 115.5);
      expect(regular.totalBibleStudies, 12);
      expect(regular.averageHours, 58); // 115.5 / 2 rounded
      expect(regular.averageBibleStudies, 6);
      expect(regular.averageReportingPublishers, 1);
    });

    test('ignores other service years and reports with no activity', () {
      final persons = [_person(id: 1), _person(id: 2)];
      final reports = [
        _report(id: 1, personId: 1, month: 9, bibleStudies: 4),
        _report(id: 2, personId: 2, month: 9, sharedInMinistry: false),
        _report(id: 3, personId: 1, month: 9, year: 2025, bibleStudies: 99),
      ];

      final publishers = _section(
        buildMinistryTotals(
          persons: persons,
          reports: reports,
          serviceYear: 2026,
        ),
        FieldServicePublisherCategory.publisher,
      );

      expect(publishers.months[0].reportingPublishers, 1);
      expect(publishers.totalBibleStudies, 4);
    });

    test('counts a not-shared report that still carries hours or studies', () {
      final publishers = _section(
        buildMinistryTotals(
          persons: [_person(id: 1)],
          reports: [
            _report(
              id: 1,
              personId: 1,
              month: 9,
              sharedInMinistry: false,
              bibleStudies: 1,
            ),
          ],
          serviceYear: 2026,
        ),
        FieldServicePublisherCategory.publisher,
      );

      expect(publishers.months[0].reportingPublishers, 1);
    });

    test('adds special pioneer and missionary sections only when used', () {
      final sections = buildMinistryTotals(
        persons: [
          _person(id: 1, pioneerType: PioneerType.specialPioneer),
          _person(id: 2, pioneerType: PioneerType.fieldMissionary),
        ],
        reports: [_report(id: 1, personId: 1, month: 9, hours: 90)],
        serviceYear: 2026,
      );

      expect(sections.map((s) => s.category), [
        FieldServicePublisherCategory.publisher,
        FieldServicePublisherCategory.auxiliaryPioneer,
        FieldServicePublisherCategory.regularPioneer,
        FieldServicePublisherCategory.specialPioneer,
      ]);
      expect(
        _section(
          sections,
          FieldServicePublisherCategory.specialPioneer,
        ).totalHours,
        90,
      );
    });

    test('counts inactive publishers who reported earlier in the year', () {
      final publishers = _section(
        buildMinistryTotals(
          persons: [_person(id: 1, isActive: false)],
          reports: [_report(id: 1, personId: 1, month: 9, bibleStudies: 2)],
          serviceYear: 2026,
        ),
        FieldServicePublisherCategory.publisher,
      );

      expect(publishers.months[0].reportingPublishers, 1);
    });
  });

  test('ministry totals PDF generates bytes', () async {
    final document = generateMinistryTotalsReport(
      persons: [
        _person(id: 1),
        _person(id: 2, pioneerType: PioneerType.regularPioneer),
      ],
      reports: [
        _report(id: 1, personId: 1, month: 9, bibleStudies: 3),
        _report(id: 2, personId: 2, month: 9, bibleStudies: 6, hours: 50),
      ],
      serviceYear: 2026,
    );

    expect(await document.save(), isNotEmpty);
  });

  test('ministry totals Excel lays out each section', () {
    final bytes = buildMinistryTotalsExcel(
      persons: [_person(id: 1)],
      reports: [
        _report(id: 1, personId: 1, month: 9, bibleStudies: 3),
        _report(id: 2, personId: 1, month: 10, bibleStudies: 5),
      ],
      serviceYear: 2026,
    );
    expect(bytes, isNotEmpty);

    final sheet = Excel.decodeBytes(bytes)['Ministry Totals'];
    String? cellText(int col, int row) => sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value
        ?.toString();

    // Title + spacer, then the Publishers section header and column headers.
    expect(cellText(0, 0), contains('Service Year 2026'));
    expect(cellText(0, 2), 'Publishers');
    expect(cellText(2, 3), 'Bible Studies');
    expect(cellText(3, 3), 'Reporting');
    expect(cellText(0, 4), 'September');
    expect(cellText(2, 4), '3');
    expect(cellText(3, 4), '1');
    expect(cellText(0, 16), 'Total');
    expect(cellText(2, 16), '8');
    expect(cellText(0, 17), 'Average');
    expect(cellText(2, 17), '4');
    expect(cellText(3, 17), '1');
    expect(cellText(0, 19), 'Auxiliary Pioneers');
  });
}
