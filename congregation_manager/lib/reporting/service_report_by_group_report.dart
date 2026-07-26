import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/excel_report_header.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';
import 'package:congregation_manager/reporting/service_report_group_data.dart';

/// Field Service Reports by Group — portrait PDF.
///
/// Each field service group lists its active publishers with the figures for
/// the period (shared, auxiliary pioneer, Bible studies, hours), followed by
/// per-group subtotals and a grand total.
pw.Document generateServiceReportByGroupReport({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
  Congregation? congregation,
}) {
  final monthName = DateFormat.MMMM().format(DateTime(year, month));
  final subtitle = '$monthName $year';

  final buckets = buildServiceGroupBuckets(
    persons: persons,
    reports: reports,
    groupsById: groupsById,
  );

  final totalPublishers = buckets.fold(0, (s, b) => s + b.publisherCount);
  final totalReporting = buckets.fold(0, (s, b) => s + b.reportingCount);
  final totalStudies = buckets.fold(0, (s, b) => s + b.totalBibleStudies);
  final totalHours = buckets.fold(0.0, (s, b) => s + b.totalHours);

  final pdf = pw.Document(title: 'Field Service Reports by Group - $subtitle');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(34),
      maxPages: PdfStyles.maxPages,
      header: (context) => PdfStyles.reportTitleBlock(
        title: 'Field Service Reports',
        subtitle: '$subtitle — Grouped by Field Service Group',
        congregation: congregation,
      ),
      footer: (context) => PdfStyles.pageFooter(context),
      build: (context) => [
        for (final bucket in buckets) ..._groupSection(bucket),
        pw.SizedBox(height: 20),
        _grandTotal(
          publishers: totalPublishers,
          reporting: totalReporting,
          studies: totalStudies,
          hours: totalHours,
        ),
      ],
    ),
  );

  return pdf;
}

List<pw.Widget> _groupSection(ServiceGroupBucket bucket) {
  return [
    pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfStyles.headerColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            bucket.name,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.headerColor,
            ),
          ),
          pw.Text(
            'Reporting ${bucket.reportingCount}/${bucket.publisherCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfStyles.footerColor),
          ),
        ],
      ),
    ),
    pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      headerDecoration: PdfStyles.headerDecoration,
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellDecoration: (index, data, rowNum) => PdfStyles.rowBorder,
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(50),
        4: const pw.FixedColumnWidth(55),
        5: const pw.FixedColumnWidth(45),
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
      headers: ['#', 'Name', 'Shared', 'Aux', 'Studies', 'Hours'],
      data: List.generate(bucket.lines.length, (i) {
        final line = bucket.lines[i];
        return [
          '${i + 1}',
          line.name,
          line.sharedInMinistry ? 'Y' : '—',
          line.isAuxiliaryPioneer ? 'Y' : '—',
          line.bibleStudies > 0 ? '${line.bibleStudies}' : '—',
          formatHours(line.hours),
        ];
      }),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Subtotal — Studies: ${bucket.totalBibleStudies}    '
            'Hours: ${formatHours(bucket.totalHours)}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    ),
  ];
}

pw.Widget _grandTotal({
  required int publishers,
  required int reporting,
  required int studies,
  required double hours,
}) {
  return pw.Container(
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: PdfColor.fromInt(0xFF9E9E9E)),
      ),
    ),
    padding: const pw.EdgeInsets.only(top: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Grand Total',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          border: null,
          cellPadding: const pw.EdgeInsets.symmetric(vertical: 2),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
          },
          headers: null,
          data: [
            ['Reporting', '$reporting / $publishers'],
            ['Total Bible Studies', '$studies'],
            ['Total Hours', formatHours(hours)],
          ],
        ),
      ],
    ),
  );
}

/// Build the same report as an Excel (.xlsx) workbook.
Uint8List buildServiceReportByGroupExcel({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
  Congregation? congregation,
}) {
  final monthName = DateFormat.MMMM().format(DateTime(year, month));
  final subtitle = '$monthName $year';

  final buckets = buildServiceGroupBuckets(
    persons: persons,
    reports: reports,
    groupsById: groupsById,
  );

  const headers = ['#', 'Name', 'Shared', 'Aux', 'Bible Studies', 'Hours'];

  final excel = Excel.createExcel();
  const sheetName = 'Reports by Group';
  excel.rename(excel.getDefaultSheet()!, sheetName);
  final sheet = excel[sheetName];

  void put(int col, int row, CellValue value, {CellStyle? style}) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }

  final groupStyle = CellStyle(bold: true, fontSize: 12);
  final headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
    horizontalAlign: HorizontalAlign.Center,
  );
  final subtotalStyle = CellStyle(bold: true);

  var row = writeExcelReportHeader(
    sheet,
    title: 'Field Service Reports — $subtitle',
    columnSpan: headers.length,
    congregation: congregation,
  );
  var totalPublishers = 0;
  var totalReporting = 0;
  var totalStudies = 0;
  var totalHours = 0.0;

  for (final bucket in buckets) {
    totalPublishers += bucket.publisherCount;
    totalReporting += bucket.reportingCount;
    totalStudies += bucket.totalBibleStudies;
    totalHours += bucket.totalHours;

    put(
      0,
      row,
      TextCellValue(
        '${bucket.name}  (reporting ${bucket.reportingCount}/'
        '${bucket.publisherCount})',
      ),
      style: groupStyle,
    );
    row++;

    for (var col = 0; col < headers.length; col++) {
      put(col, row, TextCellValue(headers[col]), style: headerStyle);
    }
    row++;

    for (var i = 0; i < bucket.lines.length; i++) {
      final line = bucket.lines[i];
      put(0, row, IntCellValue(i + 1));
      put(1, row, TextCellValue(line.name));
      put(2, row, TextCellValue(line.sharedInMinistry ? 'Yes' : ''));
      put(3, row, TextCellValue(line.isAuxiliaryPioneer ? 'Yes' : ''));
      put(4, row, IntCellValue(line.bibleStudies));
      put(5, row, DoubleCellValue(line.hours));
      row++;
    }

    put(1, row, TextCellValue('Subtotal'), style: subtotalStyle);
    put(4, row, IntCellValue(bucket.totalBibleStudies), style: subtotalStyle);
    put(5, row, DoubleCellValue(bucket.totalHours), style: subtotalStyle);
    row += 2;
  }

  put(1, row, TextCellValue('Grand Total'), style: subtotalStyle);
  put(
    2,
    row,
    TextCellValue('$totalReporting/$totalPublishers'),
    style: subtotalStyle,
  );
  put(4, row, IntCellValue(totalStudies), style: subtotalStyle);
  put(5, row, DoubleCellValue(totalHours), style: subtotalStyle);

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to generate Excel file.');
  }
  return Uint8List.fromList(bytes);
}
