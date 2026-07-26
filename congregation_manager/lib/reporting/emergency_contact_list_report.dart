import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';

/// Emergency Contact List Report — landscape PDF.
/// Columns: #, Full Name, Phone Number(s), Email, Emergency Contact,
/// Emergency Phone, Relationship
pw.Document generateEmergencyContactListReport({
  required List<Person> persons,
  required Map<int, List<PhoneNumber>> phonesByPerson,
  required Map<int, List<EmergencyContact>> emergencyContactsByPerson,
  Congregation? congregation,
}) {
  final sorted = List<Person>.from(persons)
    ..sort(
      (a, b) => formatPersonName(
        a.firstName,
        a.lastName,
      ).compareTo(formatPersonName(b.firstName, b.lastName)),
    );

  final pdf = pw.Document(title: 'Emergency Contact List');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(34),
      maxPages: PdfStyles.maxPages,
      header: (context) => context.pageNumber == 1
          ? PdfStyles.reportTitleBlock(
              title: 'Emergency Contact List',
              congregation: congregation,
              showCircuitOverseer: true,
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
          columnWidths: {
            0: const pw.FixedColumnWidth(22),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.8),
            3: const pw.FlexColumnWidth(2.2),
            4: const pw.FlexColumnWidth(2),
            5: const pw.FlexColumnWidth(1.8),
            6: const pw.FlexColumnWidth(1.2),
          },
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
            4: pw.Alignment.centerLeft,
            5: pw.Alignment.centerLeft,
            6: pw.Alignment.centerLeft,
          },
          headers: [
            '#',
            'Full Name',
            'Phone Number(s)',
            'Email',
            'Emergency Contact',
            'Emergency Phone',
            'Relationship',
          ],
          data: List.generate(sorted.length, (i) {
            final p = sorted[i];
            final phones = phonesByPerson[p.id] ?? [];
            final phoneStr = phones.isEmpty
                ? '—'
                : phones.map((ph) => ph.number).join(', ');

            final ecs = emergencyContactsByPerson[p.id] ?? [];
            final primary = _getPrimaryEmergencyContact(ecs);

            return [
              '${i + 1}',
              formatPersonName(p.firstName, p.lastName),
              phoneStr,
              p.email.isEmpty ? '—' : p.email,
              primary?.name ?? '—',
              primary?.phoneNumber ?? '—',
              primary != null
                  ? Relationship.values[primary.relationship.index].displayName
                  : '—',
            ];
          }),
        ),
      ],
    ),
  );

  return pdf;
}

EmergencyContact? _getPrimaryEmergencyContact(List<EmergencyContact> contacts) {
  if (contacts.isEmpty) return null;
  return contacts.cast<EmergencyContact?>().firstWhere(
    (c) => c!.isPrimary,
    orElse: () => contacts.first,
  );
}
