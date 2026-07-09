import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';
import 'package:congregation_manager/reporting/service_report_group_data.dart';

/// Per-group list of active publishers with no submitted report for the period.
List<ServiceGroupBucket> _missingBuckets({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
}) {
  final buckets = buildServiceGroupBuckets(
    persons: persons,
    reports: reports,
    groupsById: groupsById,
  );
  return [
    for (final bucket in buckets)
      ServiceGroupBucket(
        name: bucket.name,
        lines: bucket.lines.where((l) => !l.submitted).toList(),
      ),
  ].where((b) => b.lines.isNotEmpty).toList();
}

/// Missing Reports by Group — portrait PDF.
///
/// Lists, per field service group, the active publishers who have not yet
/// submitted a report for the period (no report row, or a blank one).
pw.Document generateMissingReportsByGroupReport({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
}) {
  final monthName = DateFormat.MMMM().format(DateTime(year, month));
  final subtitle = '$monthName $year';
  final generatedAt =
      'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';

  final buckets = _missingBuckets(
    persons: persons,
    reports: reports,
    groupsById: groupsById,
  );
  final totalMissing = buckets.fold(0, (s, b) => s + b.lines.length);

  final pdf = pw.Document(title: 'Missing Reports by Group - $subtitle');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(34),
      maxPages: PdfStyles.maxPages,
      header: (context) => pw.Column(
        children: [
          pw.Text('Missing Reports', style: PdfStyles.title(null)),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 12, color: PdfStyles.footerColor),
          ),
          pw.Text(
            'Active publishers with no report submitted',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              color: PdfStyles.footerColor,
            ),
          ),
          pw.SizedBox(height: 15),
        ],
      ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            generatedAt,
            style: pw.TextStyle(fontSize: 8, color: PdfStyles.footerColor),
          ),
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfStyles.footerColor),
          ),
          pw.Text(
            'Total missing: $totalMissing',
            style: pw.TextStyle(fontSize: 8, color: PdfStyles.footerColor),
          ),
        ],
      ),
      build: (context) => [
        if (buckets.isEmpty)
          pw.Text(
            'All active publishers have submitted a report for this period.',
            style: const pw.TextStyle(fontSize: 11),
          )
        else ...[
          for (final bucket in buckets) ..._groupSection(bucket),
          pw.SizedBox(height: 20),
          _summary(buckets, totalMissing),
        ],
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
            '(${bucket.lines.length})',
            style: pw.TextStyle(fontSize: 10, color: PdfStyles.footerColor),
          ),
        ],
      ),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10),
      child: pw.TableHelper.fromTextArray(
        border: null,
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellDecoration: (index, data, rowNum) => PdfStyles.rowBorder,
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        columnWidths: {
          0: const pw.FixedColumnWidth(28),
          1: const pw.FlexColumnWidth(),
        },
        cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.centerLeft},
        headers: null,
        data: List.generate(
          bucket.lines.length,
          (i) => ['${i + 1}', bucket.lines[i].name],
        ),
      ),
    ),
  ];
}

pw.Widget _summary(List<ServiceGroupBucket> buckets, int totalMissing) {
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
          'Summary',
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
            for (final bucket in buckets)
              [bucket.name, '${bucket.lines.length}'],
            ['Total', '$totalMissing'],
          ],
        ),
      ],
    ),
  );
}

/// Build the same report as an Excel (.xlsx) workbook.
Uint8List buildMissingReportsByGroupExcel({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
}) {
  final monthName = DateFormat.MMMM().format(DateTime(year, month));
  final subtitle = '$monthName $year';

  final buckets = _missingBuckets(
    persons: persons,
    reports: reports,
    groupsById: groupsById,
  );

  final excel = Excel.createExcel();
  const sheetName = 'Missing Reports';
  excel.rename(excel.getDefaultSheet()!, sheetName);
  final sheet = excel[sheetName];

  void put(int col, int row, CellValue value, {CellStyle? style}) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }

  final titleStyle = CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: ExcelColor.fromHexString('#2196F3'),
  );
  final headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
    horizontalAlign: HorizontalAlign.Center,
  );

  put(0, 0, TextCellValue('Missing Reports — $subtitle'), style: titleStyle);
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
  );

  const headers = ['Field Service Group', 'Publisher'];
  for (var col = 0; col < headers.length; col++) {
    put(col, 2, TextCellValue(headers[col]), style: headerStyle);
  }

  var row = 3;
  for (final bucket in buckets) {
    for (final line in bucket.lines) {
      put(0, row, TextCellValue(bucket.name));
      put(1, row, TextCellValue(line.name));
      row++;
    }
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to generate Excel file.');
  }
  return Uint8List.fromList(bytes);
}
