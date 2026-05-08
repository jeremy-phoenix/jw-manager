import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';

/// Publisher Directory Report — landscape PDF.
/// Columns: #, Full Name, Address, Phone Number(s), Field Service Group
pw.Document generatePublisherDirectoryReport({
  required List<Person> persons,
  required Map<int, List<PhoneNumber>> phonesByPerson,
  required Map<int, FieldServiceGroup> groupsById,
}) {
  final active = persons.where((p) => p.isActive).toList()
    ..sort((a, b) => formatPersonName(a.firstName, a.lastName)
        .compareTo(formatPersonName(b.firstName, b.lastName)));
  final inactive = persons.where((p) => !p.isActive).toList()
    ..sort((a, b) => formatPersonName(a.firstName, a.lastName)
        .compareTo(formatPersonName(b.firstName, b.lastName)));

  final pdf = pw.Document(title: 'Publisher Directory');

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(34),
    header: (context) => context.pageNumber == 1
        ? pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text('Publisher Directory', style: PdfStyles.title(null)),
          )
        : pw.SizedBox(),
    footer: (context) => PdfStyles.pageFooter(context),
    build: (context) => [
      _directoryTable('Active Publishers', active, phonesByPerson, groupsById),
      if (inactive.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _directoryTable(
            'Inactive Publishers', inactive, phonesByPerson, groupsById),
      ],
    ],
  ));

  return pdf;
}

pw.Widget _directoryTable(
  String title,
  List<Person> persons,
  Map<int, List<PhoneNumber>> phonesByPerson,
  Map<int, FieldServiceGroup> groupsById,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(title, style: PdfStyles.sectionTitle(null)),
      pw.SizedBox(height: 6),
      pw.TableHelper.fromTextArray(
        border: null,
        headerStyle:
            pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        headerDecoration: PdfStyles.headerDecoration,
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellDecoration: (index, data, rowNum) =>
            PdfStyles.rowBorder,
        cellPadding: const pw.EdgeInsets.all(4),
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.centerLeft,
          3: pw.Alignment.centerLeft,
          4: pw.Alignment.centerLeft,
        },
        headers: ['#', 'Full Name', 'Address', 'Phone Number(s)', 'Field Service Group'],
        data: List.generate(persons.length, (i) {
          final p = persons[i];
          final phones = phonesByPerson[p.id] ?? [];
          final phoneStr = phones.isEmpty
              ? '—'
              : phones
                  .map((ph) => ph.number)
                  .join(', ');
          final group = p.fieldServiceGroupId != null
              ? groupsById[p.fieldServiceGroupId]?.name ?? '—'
              : '—';
          return [
            '${i + 1}',
            formatPersonName(p.firstName, p.lastName),
            p.address.isEmpty ? '—' : p.address,
            phoneStr,
            group,
          ];
        }),
      ),
    ],
  );
}
