import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';

/// Congregation Summary Report — portrait PDF.
/// Three sections: All Active Publishers, New Inactive Publishers, Reactivated Publishers.
/// Columns per section: #, First Name, Last Name, Baptism Date
pw.Document generateCongregationSummaryReport({
  required List<Person> allActive,
  required List<Person> newInactive,
  required List<Person> reactivated,
}) {
  final generatedAt =
      'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';

  final pdf = pw.Document(title: 'Congregation Summary');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      maxPages: PdfStyles.maxPages,
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Congregation Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfStyles.headerColor,
            ),
          ),
          pw.Text(
            generatedAt,
            style: pw.TextStyle(fontSize: 9, color: PdfStyles.footerColor),
          ),
          pw.SizedBox(height: 10),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (context) => [
        _summarySection('All Active Publishers', allActive),
        pw.SizedBox(height: 10),
        _summarySection('New Inactive Publishers', newInactive),
        pw.SizedBox(height: 10),
        _summarySection('Reactivated Publishers', reactivated),
      ],
    ),
  );

  return pdf;
}

pw.Widget _summarySection(String title, List<Person> people) {
  final sorted = List<Person>.from(people)
    ..sort(
      (a, b) => formatPersonName(
        a.firstName,
        a.lastName,
      ).compareTo(formatPersonName(b.firstName, b.lastName)),
    );

  final dateFormat = DateFormat.yMMMd();

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        '${sorted.length} record(s)',
        style: pw.TextStyle(fontSize: 10, color: PdfStyles.footerColor),
      ),
      pw.SizedBox(height: 5),
      if (sorted.isEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Text(
            'No records in this category.',
            style: pw.TextStyle(
              fontStyle: pw.FontStyle.italic,
              color: PdfStyles.footerColor,
            ),
          ),
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
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
          },
          headers: ['#', 'First Name', 'Last Name', 'Baptism Date'],
          data: List.generate(sorted.length, (i) {
            final p = sorted[i];
            return [
              '${i + 1}',
              p.firstName,
              p.lastName,
              p.baptismDate != null ? dateFormat.format(p.baptismDate!) : '—',
            ];
          }),
        ),
    ],
  );
}
