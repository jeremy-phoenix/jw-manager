import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';

/// Not Shared in Ministry by Group Report — portrait PDF.
/// Same data as the flat report but grouped by field service group,
/// with a summary table at the bottom.
pw.Document generateNotSharedInMinistryByGroupReport({
  required List<ServiceReport> reports,
  required Map<int, Person> personsById,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
  Congregation? congregation,
}) {
  final monthName = DateFormat.MMMM().format(DateTime(year, month));
  final title = 'Not Shared in Ministry';
  final subtitle = '$monthName $year';

  // Build grouped data: groupName → list of (person name)
  final grouped = <String, List<String>>{};
  for (final r in reports) {
    final person = personsById[r.personId];
    final groupName =
        (person?.fieldServiceGroupId != null
            ? groupsById[person!.fieldServiceGroupId]?.name
            : null) ??
        'Unassigned';
    final name = person != null
        ? formatPersonName(person.firstName, person.lastName)
        : '—';
    grouped.putIfAbsent(groupName, () => []).add(name);
  }

  // Sort groups alphabetically, "Unassigned" last
  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) {
      if (a == 'Unassigned') return 1;
      if (b == 'Unassigned') return -1;
      return a.compareTo(b);
    });

  // Sort names within each group
  for (final names in grouped.values) {
    names.sort();
  }

  final pdf = pw.Document(title: '$title by Group - $subtitle');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(34),
      maxPages: PdfStyles.maxPages,
      header: (context) => PdfStyles.reportTitleBlock(
        title: title,
        subtitle: '$subtitle — Grouped by Field Service Group',
        congregation: congregation,
      ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfStyles.footerColor),
          ),
          pw.Text(
            'Total: ${reports.length}',
            style: pw.TextStyle(fontSize: 8, color: PdfStyles.footerColor),
          ),
        ],
      ),
      build: (context) => [
        // Each group section
        for (final groupName in sortedKeys) ...[
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
                  groupName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfStyles.headerColor,
                  ),
                ),
                pw.Text(
                  '(${grouped[groupName]!.length})',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfStyles.footerColor,
                  ),
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
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
              },
              headers: null,
              data: List.generate(grouped[groupName]!.length, (i) {
                return ['${i + 1}', grouped[groupName]![i]];
              }),
            ),
          ),
        ],
        // Summary section
        pw.SizedBox(height: 20),
        pw.Container(
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
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
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
                  // Sort by count descending
                  for (final key
                      in sortedKeys.toList()..sort(
                        (a, b) =>
                            grouped[b]!.length.compareTo(grouped[a]!.length),
                      ))
                    [key, '${grouped[key]!.length}'],
                  // Total row
                  ['Total', '${reports.length}'],
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return pdf;
}
