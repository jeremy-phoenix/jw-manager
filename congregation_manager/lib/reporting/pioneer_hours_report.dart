import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/reporting/excel_report_header.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';
import 'package:congregation_manager/reporting/service_report_group_data.dart';

/// A single pioneer's hours line for a period.
class PioneerHoursRow {
  final String name;
  final String type;
  final String groupName;
  final double monthHours;
  final double yearToDateHours;
  final int bibleStudies;

  const PioneerHoursRow({
    required this.name,
    required this.type,
    required this.groupName,
    required this.monthHours,
    required this.yearToDateHours,
    required this.bibleStudies,
  });
}

/// Position of a calendar month within the service year (September = 0).
int _serviceMonthPosition(int month) => month >= 9 ? month - 9 : month + 3;

int _pioneerTypeRank(String type) {
  switch (type) {
    case 'Special Pioneer':
      return 0;
    case 'Field Missionary':
      return 1;
    case 'Regular Pioneer':
      return 2;
    default:
      return 3; // Auxiliary Pioneer
  }
}

/// Build the pioneer rows for [year]/[month].
///
/// [reports] should contain every report for the service [year] (all months)
/// so year-to-date hours can be accumulated up to and including [month].
List<PioneerHoursRow> buildPioneerHoursRows({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
}) {
  final selectedPos = _serviceMonthPosition(month);

  final reportsByPerson = <int, List<ServiceReport>>{};
  for (final r in reports) {
    if (r.year != year) continue;
    reportsByPerson.putIfAbsent(r.personId, () => []).add(r);
  }

  final rows = <PioneerHoursRow>[];
  for (final person in persons.where((p) => p.isActive)) {
    final personReports = reportsByPerson[person.id] ?? const <ServiceReport>[];
    ServiceReport? monthReport;
    for (final r in personReports) {
      if (r.month == month) {
        monthReport = r;
        break;
      }
    }

    final permanentType = person.pioneerType;
    final auxThisMonth = monthReport?.isAuxiliaryPioneer ?? false;

    final String type;
    if (permanentType == PioneerType.regularPioneer) {
      type = 'Regular Pioneer';
    } else if (permanentType == PioneerType.specialPioneer) {
      type = 'Special Pioneer';
    } else if (permanentType == PioneerType.fieldMissionary) {
      type = 'Field Missionary';
    } else if (auxThisMonth) {
      type = 'Auxiliary Pioneer';
    } else {
      continue; // Not a pioneer this month.
    }

    final ytdHours = personReports
        .where((r) => _serviceMonthPosition(r.month) <= selectedPos)
        .fold(0.0, (sum, r) => sum + r.hours);

    rows.add(
      PioneerHoursRow(
        name: formatPersonName(person.firstName, person.lastName),
        type: type,
        groupName: groupNameForPerson(person, groupsById),
        monthHours: monthReport?.hours ?? 0,
        yearToDateHours: ytdHours,
        bibleStudies: monthReport?.bibleStudies ?? 0,
      ),
    );
  }

  rows.sort((a, b) {
    final byType = _pioneerTypeRank(a.type).compareTo(_pioneerTypeRank(b.type));
    if (byType != 0) return byType;
    return a.name.compareTo(b.name);
  });
  return rows;
}

/// Pioneer Hours — portrait PDF.
pw.Document generatePioneerHoursReport({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
  Congregation? congregation,
}) {
  final monthName = DateFormat.MMMM().format(DateTime(year, month));
  final subtitle = '$monthName $year';

  final rows = buildPioneerHoursRows(
    persons: persons,
    reports: reports,
    groupsById: groupsById,
    year: year,
    month: month,
  );

  final totalMonth = rows.fold(0.0, (s, r) => s + r.monthHours);
  final totalYtd = rows.fold(0.0, (s, r) => s + r.yearToDateHours);
  final totalStudies = rows.fold(0, (s, r) => s + r.bibleStudies);

  final pdf = pw.Document(title: 'Pioneer Hours - $subtitle');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(34),
      maxPages: PdfStyles.maxPages,
      header: (context) => context.pageNumber == 1
          ? PdfStyles.reportTitleBlock(
              title: 'Pioneer Hours',
              subtitle: subtitle,
              congregation: congregation,
            )
          : pw.SizedBox(),
      footer: (context) => PdfStyles.pageFooter(context),
      build: (context) => [
        if (rows.isEmpty)
          pw.Text(
            'No pioneers reported for this period.',
            style: const pw.TextStyle(fontSize: 11),
          )
        else
          pw.TableHelper.fromTextArray(
            border: null,
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: PdfStyles.headerDecoration,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellDecoration: (index, data, rowNum) => PdfStyles.rowBorder,
            cellPadding: const pw.EdgeInsets.all(4),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            headers: [
              'Name',
              'Type',
              'Group',
              'Month Hours',
              'YTD Hours',
              'Studies',
            ],
            data: [
              for (final r in rows)
                [
                  r.name,
                  r.type,
                  r.groupName,
                  formatHours(r.monthHours),
                  formatHours(r.yearToDateHours),
                  r.bibleStudies > 0 ? '${r.bibleStudies}' : '—',
                ],
              [
                'Total (${rows.length})',
                '',
                '',
                formatHours(totalMonth),
                formatHours(totalYtd),
                '$totalStudies',
              ],
            ],
          ),
      ],
    ),
  );

  return pdf;
}

/// Build the same report as an Excel (.xlsx) workbook.
Uint8List buildPioneerHoursExcel({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
  Congregation? congregation,
}) {
  final monthName = DateFormat.MMMM().format(DateTime(year, month));
  final subtitle = '$monthName $year';

  final rows = buildPioneerHoursRows(
    persons: persons,
    reports: reports,
    groupsById: groupsById,
    year: year,
    month: month,
  );

  const headers = [
    'Name',
    'Type',
    'Group',
    'Month Hours',
    'YTD Hours',
    'Bible Studies',
  ];

  final excel = Excel.createExcel();
  const sheetName = 'Pioneer Hours';
  excel.rename(excel.getDefaultSheet()!, sheetName);
  final sheet = excel[sheetName];

  void put(int col, int row, CellValue value, {CellStyle? style}) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }

  final headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
    horizontalAlign: HorizontalAlign.Center,
  );
  final totalStyle = CellStyle(bold: true);

  final headerRow = writeExcelReportHeader(
    sheet,
    title: 'Pioneer Hours — $subtitle',
    columnSpan: headers.length,
    congregation: congregation,
  );

  for (var col = 0; col < headers.length; col++) {
    put(col, headerRow, TextCellValue(headers[col]), style: headerStyle);
  }

  var row = headerRow + 1;
  var totalMonth = 0.0;
  var totalYtd = 0.0;
  var totalStudies = 0;
  for (final r in rows) {
    totalMonth += r.monthHours;
    totalYtd += r.yearToDateHours;
    totalStudies += r.bibleStudies;
    put(0, row, TextCellValue(r.name));
    put(1, row, TextCellValue(r.type));
    put(2, row, TextCellValue(r.groupName));
    put(3, row, DoubleCellValue(r.monthHours));
    put(4, row, DoubleCellValue(r.yearToDateHours));
    put(5, row, IntCellValue(r.bibleStudies));
    row++;
  }

  put(0, row, TextCellValue('Total (${rows.length})'), style: totalStyle);
  put(3, row, DoubleCellValue(totalMonth), style: totalStyle);
  put(4, row, DoubleCellValue(totalYtd), style: totalStyle);
  put(5, row, IntCellValue(totalStudies), style: totalStyle);

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to generate Excel file.');
  }
  return Uint8List.fromList(bytes);
}
