import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/excel_report_header.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';

/// Generates a Publisher Contact List as an Excel (.xlsx) workbook.
class PublisherContactListExcelReport {
  final List<Person> persons;
  final Map<int, List<PhoneNumber>> phonesByPerson;
  final Map<int, FieldServiceGroup> groupsById;
  final Congregation? congregation;

  PublisherContactListExcelReport({
    required this.persons,
    required this.phonesByPerson,
    required this.groupsById,
    this.congregation,
  });

  static const _headers = [
    '#',
    'Name of Publisher',
    'Address',
    'Phone Number(s)',
    'Email',
    'Field Service Group',
  ];

  Uint8List buildBytes() {
    final excel = Excel.createExcel();
    final sheetName = 'Publisher Contact List';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    final firstFreeRow = writeExcelReportHeader(
      sheet,
      title: 'Publisher Contact List',
      columnSpan: _headers.length,
      congregation: congregation,
      circuitOverseerLine: PdfStyles.circuitOverseerSummary(congregation),
    );

    final active = persons.where((p) => p.isActive).toList()
      ..sort((a, b) => _fullName(a).compareTo(_fullName(b)));
    final inactive = persons.where((p) => !p.isActive).toList()
      ..sort((a, b) => _fullName(a).compareTo(_fullName(b)));

    var currentRow = firstFreeRow;
    currentRow = _addSection(sheet, 'Active Publishers', active, currentRow);

    if (inactive.isNotEmpty) {
      currentRow += 2;
      _addSection(sheet, 'Inactive Publishers', inactive, currentRow);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to generate Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> save(String filePath) async {
    await File(filePath).writeAsBytes(buildBytes());
  }

  int _addSection(
    Sheet sheet,
    String title,
    List<Person> people,
    int startRow,
  ) {
    // Section title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow))
      ..value = TextCellValue(title)
      ..cellStyle = CellStyle(bold: true, fontSize: 12);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow),
      CellIndex.indexByColumnRow(
        columnIndex: _headers.length - 1,
        rowIndex: startRow,
      ),
    );

    // Headers
    final headerRow = startRow + 1;
    for (var col = 0; col < _headers.length; col++) {
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow),
        )
        ..value = TextCellValue(_headers[col])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
          horizontalAlign: HorizontalAlign.Center,
        );
    }

    // Data rows
    for (var i = 0; i < people.length; i++) {
      final row = headerRow + 1 + i;
      final person = people[i];

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(
        i + 1,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(
        _fullName(person),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(
        person.address.isEmpty ? '\u2014' : person.address,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(
        _formatPhones(person.id),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(
        person.email.isEmpty ? '\u2014' : person.email,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(
        groupsById[person.fieldServiceGroupId]?.name ?? '\u2014',
      );
    }

    return headerRow + people.length;
  }

  String _fullName(Person p) {
    final last = p.lastName;
    final first = p.firstName;
    if (last.isNotEmpty && first.isNotEmpty) return '$last, $first';
    return last.isNotEmpty ? last : first;
  }

  String _formatPhones(int personId) {
    final phones = phonesByPerson[personId];
    if (phones == null || phones.isEmpty) return '\u2014';
    return phones.map((p) => p.number).join(' / ');
  }
}
