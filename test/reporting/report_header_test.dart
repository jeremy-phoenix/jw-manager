import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
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

Person _person({required int id, String email = '', bool isActive = true}) {
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
    isActive: isActive,
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

/// The PDF text extractor emits one word per line, so collapse all whitespace
/// before matching phrases.
String _flatten(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

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
          _congregation(
            coName: '',
            coSpouse: '',
            coPhone: '',
            coEmail: '',
            coAddress: '',
          ),
        ),
        isNull,
      );
    });

    test('joins name, spouse, phone, email and address', () {
      expect(
        PdfStyles.circuitOverseerSummary(_congregation()),
        'Circuit Overseer: John Smith & Jane Smith · (555) 123-4567 · '
        'jsmith@example.com · 1 Circuit Way',
      );
    });

    test('omits blank parts', () {
      expect(
        PdfStyles.circuitOverseerSummary(
          _congregation(coSpouse: '', coEmail: '', coAddress: ''),
        ),
        'Circuit Overseer: John Smith · (555) 123-4567',
      );
      expect(
        PdfStyles.circuitOverseerSummary(
          _congregation(coSpouse: '', coPhone: '', coEmail: '', coAddress: ''),
        ),
        'Circuit Overseer: John Smith',
      );
    });
  });

  group('PdfStyles.circuitOverseerBlock', () {
    test('returns null for null congregation or all-blank fields', () {
      expect(PdfStyles.circuitOverseerBlock(null), isNull);
      expect(
        PdfStyles.circuitOverseerBlock(
          _congregation(
            coName: '',
            coSpouse: '',
            coPhone: '',
            coEmail: '',
            coAddress: '',
          ),
        ),
        isNull,
      );
    });

    test('builds a widget when any overseer field is set', () {
      expect(
        PdfStyles.circuitOverseerBlock(
          _congregation(coName: '', coSpouse: '', coPhone: '', coEmail: ''),
        ),
        isNotNull,
      );
    });
  });

  group('PdfStyles.congregationIdentityLine', () {
    test('includes the congregation name and number without a timestamp', () {
      expect(
        PdfStyles.congregationIdentityLine(_congregation()),
        'Riverside Congregation (No. 12345)',
      );
    });

    test('returns null when no congregation is provided', () {
      expect(PdfStyles.congregationIdentityLine(null), isNull);
    });
  });

  test('empty person names render as a blank report cell', () {
    expect(formatPersonName('', ''), isEmpty);
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

    test('renders the circuit overseer callout with every contact', () async {
      final report = generatePublisherContactListReport(
        persons: persons,
        phonesByPerson: phones,
        groupsById: groups,
        congregation: _congregation(),
      );
      final document = sf.PdfDocument(inputBytes: await report.save());
      try {
        final text = _flatten(sf.PdfTextExtractor(document).extractText());
        expect(text, contains('CIRCUIT OVERSEER'));
        expect(text, contains('John Smith & Jane Smith'));
        expect(text, contains('Phone (555) 123-4567'));
        expect(text, contains('Email jsmith@example.com'));
        expect(text, contains('Address 1 Circuit Way'));
      } finally {
        document.dispose();
      }
    });

    test(
      'omits email and can start inactive publishers on a new page',
      () async {
        final reportPersons = [
          _person(id: 1, email: 'active@example.com'),
          _person(id: 2, email: 'inactive@example.com', isActive: false),
        ];

        final continuous = generatePublisherContactListReport(
          persons: reportPersons,
          phonesByPerson: phones,
          groupsById: groups,
        );
        final continuousPdf = sf.PdfDocument(
          inputBytes: await continuous.save(),
        );
        try {
          expect(continuousPdf.pages.count, 1);
          final text = sf.PdfTextExtractor(continuousPdf).extractText();
          expect(text, isNot(contains('Email')));
          expect(text, isNot(contains('active@example.com')));
          expect(text, isNot(contains('inactive@example.com')));
        } finally {
          continuousPdf.dispose();
        }

        final separated = generatePublisherContactListReport(
          persons: reportPersons,
          phonesByPerson: phones,
          groupsById: groups,
          startInactiveOnNewPage: true,
        );
        final separatedPdf = sf.PdfDocument(inputBytes: await separated.save());
        try {
          expect(separatedPdf.pages.count, 2);
        } finally {
          separatedPdf.dispose();
        }
      },
    );
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

    test('writes header block, CO line and contact columns', () {
      final bytes = PublisherContactListExcelReport(
        persons: persons,
        phonesByPerson: phones,
        groupsById: groups,
        congregation: _congregation(),
      ).buildBytes();
      final sheet = Excel.decodeBytes(bytes)['Publisher Contact List'];

      expect(_cellText(sheet, 0, 0), 'Publisher Contact List');
      expect(_cellText(sheet, 0, 1), 'Riverside Congregation (No. 12345)');
      expect(
        _cellText(sheet, 0, 2),
        'Circuit Overseer: John Smith & Jane Smith · (555) 123-4567 · '
        'jsmith@example.com · 1 Circuit Way',
      );
      // Header rows 0-2 + spacer -> section title at 4, headers at 5, data at 6.
      expect(_cellText(sheet, 0, 4), 'Active Publishers');
      expect(_cellText(sheet, 4, 5), 'Field Service Group');
      expect(_cellText(sheet, 5, 5), isNull);
      expect(_cellText(sheet, 4, 6), 'Group A');
      expect(_cellText(sheet, 5, 6), isNull);
      expect(sheet.getColumnWidth(0), 6);
    });

    test('omits the CO line when no congregation is given', () {
      final bytes = PublisherContactListExcelReport(
        persons: persons,
        phonesByPerson: phones,
        groupsById: groups,
      ).buildBytes();
      final sheet = Excel.decodeBytes(bytes)['Publisher Contact List'];

      expect(_cellText(sheet, 0, 0), 'Publisher Contact List');
      expect(_cellText(sheet, 0, 1), isNull);
      // No congregation metadata -> everything shifts up two rows.
      expect(_cellText(sheet, 0, 2), 'Active Publishers');
      expect(_cellText(sheet, 4, 3), 'Field Service Group');
      expect(_cellText(sheet, 4, 4), 'Group A');
      expect(_cellText(sheet, 5, 4), isNull);
    });
  });
}
