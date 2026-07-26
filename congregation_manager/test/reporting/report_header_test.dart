import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/reporting/emergency_contact_list_report.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';
import 'package:congregation_manager/reporting/publisher_contact_list_excel_report.dart';
import 'package:congregation_manager/reporting/publisher_contact_list_report.dart';
import 'package:congregation_manager/reporting/publisher_directory_report.dart';

final _now = DateTime(2026, 1, 1);

Congregation _congregation({
  String coName = 'John Smith',
  String coSpouse = 'Jane Smith',
  String coPhone = '(555) 123-4567',
  String coEmail = 'jsmith@example.com',
  String coAddress = '1 Circuit Way',
}) {
  return Congregation(
    id: 1,
    name: 'Riverside',
    number: '12345',
    city: 'Springfield',
    circuitNumber: 'C-7',
    circuitOverseerName: coName,
    circuitOverseerSpouseName: coSpouse,
    circuitOverseerPhone: coPhone,
    circuitOverseerEmail: coEmail,
    circuitOverseerAddress: coAddress,
    serverVersion: 0,
    createdAt: _now,
    updatedAt: _now,
  );
}

Person _person({required int id, String email = ''}) {
  return Person(
    id: id,
    firstName: 'Alice',
    lastName: 'Adams $id',
    otherNames: '',
    birthDate: null,
    baptismDate: null,
    gender: Gender.unknown,
    hopeClass: HopeClass.unknown,
    congregationRole: CongregationRole.none,
    pioneerType: PioneerType.none,
    address: '12 Oak St',
    email: email,
    isActive: true,
    recordStatus: PersonRecordStatus.current,
    congregationId: 1,
    fieldServiceGroupId: 1,
    serverVersion: 0,
    createdAt: _now,
    updatedAt: _now,
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

String? _cellText(Sheet sheet, int col, int row) => sheet
    .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
    .value
    ?.toString();

void main() {
  group('PdfStyles.circuitOverseerSummary', () {
    test('returns null for null congregation or all-blank fields', () {
      expect(PdfStyles.circuitOverseerSummary(null), isNull);
      expect(
        PdfStyles.circuitOverseerSummary(
          _congregation(coName: '', coSpouse: '', coPhone: '', coEmail: ''),
        ),
        isNull,
      );
    });

    test('joins name, spouse, phone and email', () {
      expect(
        PdfStyles.circuitOverseerSummary(_congregation()),
        'Circuit Overseer: John Smith & Jane Smith · (555) 123-4567 · '
        'jsmith@example.com',
      );
    });

    test('omits blank parts', () {
      expect(
        PdfStyles.circuitOverseerSummary(
          _congregation(coSpouse: '', coEmail: ''),
        ),
        'Circuit Overseer: John Smith · (555) 123-4567',
      );
      expect(
        PdfStyles.circuitOverseerSummary(
          _congregation(coSpouse: '', coPhone: '', coEmail: ''),
        ),
        'Circuit Overseer: John Smith',
      );
    });
  });

  group('PdfStyles.congregationIdentityLine', () {
    final generatedAt = DateTime(2026, 7, 9, 10, 30);

    test('includes congregation name, number and generated timestamp', () {
      expect(
        PdfStyles.congregationIdentityLine(_congregation(), generatedAt),
        'Riverside Congregation (No. 12345) — Generated: 2026-07-09 10:30',
      );
    });

    test('falls back to generated timestamp only', () {
      expect(
        PdfStyles.congregationIdentityLine(null, generatedAt),
        'Generated: 2026-07-09 10:30',
      );
    });
  });

  group('contact report PDFs', () {
    final persons = [_person(id: 1, email: 'alice@example.com')];
    final phones = {
      1: [
        PhoneNumber(
          id: 1,
          number: '555-0101',
          phoneType: PhoneType.mobile,
          isPrimary: true,
          personId: 1,
          serverVersion: 0,
        ),
      ],
    };
    final groups = {1: _group(1, 'Group A')};

    test('generate bytes with and without a congregation', () async {
      for (final congregation in [_congregation(), null]) {
        final directory = generatePublisherDirectoryReport(
          persons: persons,
          phonesByPerson: phones,
          groupsById: groups,
          congregation: congregation,
        );
        expect(await directory.save(), isNotEmpty);

        final contactList = generatePublisherContactListReport(
          persons: persons,
          phonesByPerson: phones,
          groupsById: groups,
          congregation: congregation,
        );
        expect(await contactList.save(), isNotEmpty);

        final emergency = generateEmergencyContactListReport(
          persons: persons,
          phonesByPerson: phones,
          emergencyContactsByPerson: {
            1: [
              EmergencyContact(
                id: 1,
                name: 'Bob Adams',
                phoneNumber: '555-0202',
                relationship: Relationship.values.first,
                isPrimary: true,
                personId: 1,
                serverVersion: 0,
              ),
            ],
          },
          congregation: congregation,
        );
        expect(await emergency.save(), isNotEmpty);
      }
    });
  });

  group('publisher contact list Excel', () {
    final persons = [_person(id: 1, email: 'alice@example.com')];
    final phones = {
      1: [
        PhoneNumber(
          id: 1,
          number: '555-0101',
          phoneType: PhoneType.mobile,
          isPrimary: true,
          personId: 1,
          serverVersion: 0,
        ),
      ],
    };
    final groups = {1: _group(1, 'Group A')};

    test('writes header block, CO line and email column', () {
      final bytes = PublisherContactListExcelReport(
        persons: persons,
        phonesByPerson: phones,
        groupsById: groups,
        congregation: _congregation(),
      ).buildBytes();
      final sheet = Excel.decodeBytes(bytes)['Publisher Contact List'];

      expect(_cellText(sheet, 0, 0), 'Publisher Contact List');
      expect(_cellText(sheet, 0, 1), contains('Riverside Congregation'));
      expect(_cellText(sheet, 0, 1), contains('Generated:'));
      expect(
        _cellText(sheet, 0, 2),
        'Circuit Overseer: John Smith & Jane Smith · (555) 123-4567 · '
        'jsmith@example.com',
      );
      // Header rows 0-2 + spacer -> section title at 4, headers at 5, data at 6.
      expect(_cellText(sheet, 0, 4), 'Active Publishers');
      expect(_cellText(sheet, 4, 5), 'Email');
      expect(_cellText(sheet, 5, 5), 'Field Service Group');
      expect(_cellText(sheet, 4, 6), 'alice@example.com');
      expect(_cellText(sheet, 5, 6), 'Group A');
    });

    test('omits the CO line when no congregation is given', () {
      final bytes = PublisherContactListExcelReport(
        persons: persons,
        phonesByPerson: phones,
        groupsById: groups,
      ).buildBytes();
      final sheet = Excel.decodeBytes(bytes)['Publisher Contact List'];

      expect(_cellText(sheet, 0, 0), 'Publisher Contact List');
      expect(_cellText(sheet, 0, 1), contains('Generated:'));
      // No CO line -> everything shifts up one row.
      expect(_cellText(sheet, 0, 3), 'Active Publishers');
      expect(_cellText(sheet, 4, 4), 'Email');
      expect(_cellText(sheet, 4, 5), 'alice@example.com');
    });
  });
}
