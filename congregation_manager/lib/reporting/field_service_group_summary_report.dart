import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/excel_report_header.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';
import 'package:congregation_manager/reporting/service_report_group_data.dart';

/// Field Service Group Totals — portrait PDF.
///
/// One row per group with publisher count, number reporting, percent reporting,
/// total hours and total Bible studies, plus a totals row.
pw.Document generateFieldServiceGroupSummaryReport({
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
  final totalPercent = totalPublishers == 0
      ? 0
      : totalReporting * 100 / totalPublishers;

  final pdf = pw.Document(title: 'Field Service Group Totals - $subtitle');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(34),
      maxPages: PdfStyles.maxPages,
      header: (context) => context.pageNumber == 1
          ? PdfStyles.reportTitleBlock(
              title: 'Field Service Group Totals',
              subtitle: subtitle,
              congregation: congregation,
            )
          : pw.SizedBox(),
      footer: (context) => PdfStyles.pageFooter(context),
      build: (context) => [
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
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
          },
          headers: [
            'Field Service Group',
            'Publishers',
            'Reporting',
            '% Reporting',
            'Hours',
            'Bible Studies',
          ],
          data: [
            for (final bucket in buckets)
              [
                bucket.name,
                '${bucket.publisherCount}',
                '${bucket.reportingCount}',
                '${bucket.reportingPercent.round()}%',
                formatHours(bucket.totalHours),
                '${bucket.totalBibleStudies}',
              ],
            [
              'Total',
              '$totalPublishers',
              '$totalReporting',
              '${totalPercent.round()}%',
              formatHours(totalHours),
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
Uint8List buildFieldServiceGroupSummaryExcel({
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

  const headers = [
    'Field Service Group',
    'Publishers',
    'Reporting',
    '% Reporting',
    'Hours',
    'Bible Studies',
  ];

  final excel = Excel.createExcel();
  const sheetName = 'Group Totals';
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
    title: 'Field Service Group Totals — $subtitle',
    columnSpan: headers.length,
    congregation: congregation,
  );

  for (var col = 0; col < headers.length; col++) {
    put(col, headerRow, TextCellValue(headers[col]), style: headerStyle);
  }

  var row = headerRow + 1;
  var totalPublishers = 0;
  var totalReporting = 0;
  var totalStudies = 0;
  var totalHours = 0.0;

  for (final bucket in buckets) {
    totalPublishers += bucket.publisherCount;
    totalReporting += bucket.reportingCount;
    totalStudies += bucket.totalBibleStudies;
    totalHours += bucket.totalHours;

    put(0, row, TextCellValue(bucket.name));
    put(1, row, IntCellValue(bucket.publisherCount));
    put(2, row, IntCellValue(bucket.reportingCount));
    put(3, row, TextCellValue('${bucket.reportingPercent.round()}%'));
    put(4, row, DoubleCellValue(bucket.totalHours));
    put(5, row, IntCellValue(bucket.totalBibleStudies));
    row++;
  }

  final totalPercent = totalPublishers == 0
      ? 0
      : (totalReporting * 100 / totalPublishers).round();
  put(0, row, TextCellValue('Total'), style: totalStyle);
  put(1, row, IntCellValue(totalPublishers), style: totalStyle);
  put(2, row, IntCellValue(totalReporting), style: totalStyle);
  put(3, row, TextCellValue('$totalPercent%'), style: totalStyle);
  put(4, row, DoubleCellValue(totalHours), style: totalStyle);
  put(5, row, IntCellValue(totalStudies), style: totalStyle);

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to generate Excel file.');
  }
  return Uint8List.fromList(bytes);
}
