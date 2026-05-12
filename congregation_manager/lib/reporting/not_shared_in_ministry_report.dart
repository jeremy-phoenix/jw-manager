import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';

/// Not Shared in Ministry Report — portrait PDF.
/// Lists all publishers who did not share in ministry for a given month.
/// Columns: #, Full Name, Field Service Group
pw.Document generateNotSharedInMinistryReport({
  required List<ServiceReport> reports,
  required Map<int, Person> personsById,
  required Map<int, FieldServiceGroup> groupsById,
  required int year,
  required int month,
}) {
  final monthName = DateFormat.MMMM().format(DateTime(year, month));
  final title = 'Not Shared in Ministry';
  final subtitle = '$monthName $year';
  final generatedAt =
      'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';

  // Sort by person name
  final sorted = List<ServiceReport>.from(reports)
    ..sort((a, b) {
      final pa = personsById[a.personId];
      final pb = personsById[b.personId];
      final nameA = pa != null
          ? formatPersonName(pa.firstName, pa.lastName)
          : '—';
      final nameB = pb != null
          ? formatPersonName(pb.firstName, pb.lastName)
          : '—';
      return nameA.compareTo(nameB);
    });

  final pdf = pw.Document(title: '$title - $subtitle');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(34),
      maxPages: PdfStyles.maxPages,
      header: (context) => pw.Column(
        children: [
          pw.Text(title, style: PdfStyles.title(null)),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 12, color: PdfStyles.footerColor),
          ),
          pw.SizedBox(height: 10),
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
            'Total: ${sorted.length}',
            style: pw.TextStyle(fontSize: 8, color: PdfStyles.footerColor),
          ),
        ],
      ),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          border: null,
          headerStyle: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: PdfStyles.headerDecoration,
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellDecoration: (index, data, rowNum) => PdfStyles.rowBorder,
          cellPadding: const pw.EdgeInsets.all(4),
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
          },
          headers: ['#', 'Full Name', 'Field Service Group'],
          data: List.generate(sorted.length, (i) {
            final r = sorted[i];
            final person = personsById[r.personId];
            final name = person != null
                ? formatPersonName(person.firstName, person.lastName)
                : '—';
            final group = person?.fieldServiceGroupId != null
                ? groupsById[person!.fieldServiceGroupId]?.name ?? '—'
                : '—';
            return ['${i + 1}', name, group];
          }),
        ),
      ],
    ),
  );

  return pdf;
}
