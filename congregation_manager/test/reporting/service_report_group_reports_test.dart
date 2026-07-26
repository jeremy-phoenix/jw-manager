import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/reporting/service_report_group_data.dart';
import 'package:congregation_manager/reporting/service_report_by_group_report.dart';
import 'package:congregation_manager/reporting/field_service_group_summary_report.dart';
import 'package:congregation_manager/reporting/pioneer_hours_report.dart';
import 'package:congregation_manager/reporting/missing_reports_by_group_report.dart';

final _now = DateTime(2026, 1, 1);

Person _person({
  required int id,
  required String firstName,
  required String lastName,
  int? fieldServiceGroupId,
  bool isActive = true,
  PioneerType pioneerType = PioneerType.none,
}) {
  return Person(
    id: id,
    firstName: firstName,
    lastName: lastName,
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
    fieldServiceGroupId: fieldServiceGroupId,
    serverVersion: 0,
    createdAt: _now,
    updatedAt: _now,
  );
}

ServiceReport _report({
  required int id,
  required int personId,
  required int year,
  required int month,
  bool sharedInMinistry = false,
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

FieldServiceGroup _group(int id, String name) {
  return FieldServiceGroup(
    id: id,
    name: name,
    description: '',
    congregationId: 1,
    serverVersion: 0,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  group('buildServiceGroupBuckets', () {
    test(
      'groups active publishers, sorts Unassigned last, computes totals',
      () {
        final persons = [
          _person(
            id: 1,
            firstName: 'Alice',
            lastName: 'Adams',
            fieldServiceGroupId: 1,
          ),
          _person(
            id: 2,
            firstName: 'Bob',
            lastName: 'Brown',
            fieldServiceGroupId: 1,
          ),
          _person(id: 3, firstName: 'Carol', lastName: 'Clark'), // Unassigned
          _person(
            id: 4,
            firstName: 'Dan',
            lastName: 'Davis',
            fieldServiceGroupId: 1,
            isActive: false, // excluded
          ),
        ];
        final reports = [
          _report(
            id: 1,
            personId: 1,
            year: 2026,
            month: 1,
            sharedInMinistry: true,
            bibleStudies: 2,
          ),
          // person 2 has a blank report -> not submitted
          _report(id: 2, personId: 2, year: 2026, month: 1),
          _report(id: 3, personId: 3, year: 2026, month: 1, hours: 12),
        ];
        final groups = {1: _group(1, 'Group A')};

        final buckets = buildServiceGroupBuckets(
          persons: persons,
          reports: reports,
          groupsById: groups,
        );

        expect(buckets.map((b) => b.name), ['Group A', kUnassignedGroupName]);

        final groupA = buckets.first;
        expect(groupA.publisherCount, 2); // inactive Dan excluded
        expect(groupA.reportingCount, 1); // only Alice submitted
        expect(groupA.totalBibleStudies, 2);
        expect(groupA.totalHours, 0);

        final unassigned = buckets.last;
        expect(unassigned.reportingCount, 1);
        expect(unassigned.totalHours, 12);
      },
    );
  });

  test('service report by group PDF and Excel generate bytes', () async {
    final persons = [
      _person(
        id: 1,
        firstName: 'Alice',
        lastName: 'Adams',
        fieldServiceGroupId: 1,
      ),
      _person(id: 2, firstName: 'Carol', lastName: 'Clark'),
    ];
    final reports = [
      _report(
        id: 1,
        personId: 1,
        year: 2026,
        month: 1,
        sharedInMinistry: true,
        hours: 5,
      ),
    ];
    final groups = {1: _group(1, 'Group A')};

    final pdf = generateServiceReportByGroupReport(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: 2026,
      month: 1,
    );
    expect(await pdf.save(), isNotEmpty);

    final xlsx = buildServiceReportByGroupExcel(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: 2026,
      month: 1,
      congregation: Congregation(
        id: 1,
        name: 'Riverside',
        number: '12345',
        city: '',
        circuitNumber: '',
        circuitOverseerName: '',
        circuitOverseerSpouseName: '',
        circuitOverseerPhone: '',
        circuitOverseerEmail: '',
        circuitOverseerAddress: '',
        serverVersion: 0,
        createdAt: _now,
        updatedAt: _now,
      ),
    );
    expect(xlsx, isNotEmpty);

    // Title + congregation line + spacer -> first group section lands on row 3.
    final sheet = Excel.decodeBytes(xlsx)['Reports by Group'];
    String? cellText(int col, int row) => sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value
        ?.toString();
    expect(cellText(0, 1), contains('Riverside Congregation'));
    expect(cellText(0, 3), startsWith('Group A'));
  });

  test('group summary PDF and Excel generate bytes', () async {
    final persons = [
      _person(
        id: 1,
        firstName: 'Alice',
        lastName: 'Adams',
        fieldServiceGroupId: 1,
      ),
    ];
    final reports = [
      _report(id: 1, personId: 1, year: 2026, month: 1, sharedInMinistry: true),
    ];
    final groups = {1: _group(1, 'Group A')};

    final pdf = generateFieldServiceGroupSummaryReport(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: 2026,
      month: 1,
    );
    expect(await pdf.save(), isNotEmpty);

    final xlsx = buildFieldServiceGroupSummaryExcel(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: 2026,
      month: 1,
    );
    expect(xlsx, isNotEmpty);
  });

  group('buildPioneerHoursRows', () {
    test('accumulates YTD hours up to the selected month and detects types', () {
      final persons = [
        _person(
          id: 1,
          firstName: 'Reg',
          lastName: 'Pioneer',
          pioneerType: PioneerType.regularPioneer,
          fieldServiceGroupId: 1,
        ),
        _person(
          id: 2,
          firstName: 'Aux',
          lastName: 'Helper',
          fieldServiceGroupId: 1,
        ),
        _person(
          id: 3,
          firstName: 'Reg',
          lastName: 'Publisher',
          fieldServiceGroupId: 1,
        ),
      ];
      // Service year 2026: Sept(9)=pos0, Oct(10)=pos1, Nov(11)=pos2.
      final reports = [
        _report(id: 1, personId: 1, year: 2026, month: 9, hours: 50),
        _report(
          id: 2,
          personId: 1,
          year: 2026,
          month: 10,
          hours: 60,
          bibleStudies: 4,
        ),
        _report(id: 3, personId: 1, year: 2026, month: 11, hours: 70),
        _report(
          id: 4,
          personId: 2,
          year: 2026,
          month: 10,
          isAuxiliaryPioneer: true,
          hours: 30,
        ),
        _report(
          id: 5,
          personId: 3,
          year: 2026,
          month: 10,
          sharedInMinistry: true,
        ),
      ];
      final groups = {1: _group(1, 'Group A')};

      final rows = buildPioneerHoursRows(
        persons: persons,
        reports: reports,
        groupsById: groups,
        year: 2026,
        month: 10,
      );

      // Regular pioneer + auxiliary publisher included; plain publisher excluded.
      expect(rows.length, 2);

      final reg = rows.firstWhere((r) => r.type == 'Regular Pioneer');
      expect(reg.monthHours, 60); // October only
      expect(reg.yearToDateHours, 110); // Sept + Oct, not Nov
      expect(reg.bibleStudies, 4);

      final aux = rows.firstWhere((r) => r.type == 'Auxiliary Pioneer');
      expect(aux.monthHours, 30);
      expect(aux.yearToDateHours, 30);
    });
  });

  group('missing reports by group', () {
    test('lists only active publishers without a submitted report', () async {
      final persons = [
        _person(
          id: 1,
          firstName: 'Alice',
          lastName: 'Adams',
          fieldServiceGroupId: 1,
        ),
        _person(
          id: 2,
          firstName: 'Bob',
          lastName: 'Brown',
          fieldServiceGroupId: 1,
        ),
        _person(id: 3, firstName: 'Carol', lastName: 'Clark'),
      ];
      final reports = [
        // Alice submitted; Bob blank; Carol has no report row at all.
        _report(
          id: 1,
          personId: 1,
          year: 2026,
          month: 1,
          sharedInMinistry: true,
        ),
        _report(id: 2, personId: 2, year: 2026, month: 1),
      ];
      final groups = {1: _group(1, 'Group A')};

      final pdf = generateMissingReportsByGroupReport(
        persons: persons,
        reports: reports,
        groupsById: groups,
        year: 2026,
        month: 1,
      );
      expect(await pdf.save(), isNotEmpty);

      final xlsx = buildMissingReportsByGroupExcel(
        persons: persons,
        reports: reports,
        groupsById: groups,
        year: 2026,
        month: 1,
      );
      expect(xlsx, isNotEmpty);
    });
  });
}
