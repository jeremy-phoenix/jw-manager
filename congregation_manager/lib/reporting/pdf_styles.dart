import 'package:congregation_manager/data/database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared PDF styling constants and helpers for all reports.
class PdfStyles {
  static final headerColor = PdfColor.fromInt(0xFF1565C0); // blue darken2
  static final headerBg = PdfColor.fromInt(0xFFE0E0E0); // grey lighten3
  static final borderColor = PdfColor.fromInt(0xFFEEEEEE); // grey lighten2
  static final footerColor = PdfColor.fromInt(0xFF757575); // grey darken1
  static const double fontSize = 9;
  static const double titleFontSize = 18;
  static const double sectionTitleFontSize = 12;
  static const int maxPages = 500;

  static pw.TextStyle title(pw.Font? fontBold) => pw.TextStyle(
    fontSize: titleFontSize,
    fontWeight: pw.FontWeight.bold,
    color: headerColor,
    font: fontBold,
  );

  static pw.TextStyle sectionTitle(pw.Font? fontBold) => pw.TextStyle(
    fontSize: sectionTitleFontSize,
    fontWeight: pw.FontWeight.bold,
    font: fontBold,
  );

  static pw.BoxDecoration get headerDecoration =>
      pw.BoxDecoration(color: headerBg);

  static pw.BoxDecoration get rowBorder => pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: borderColor)),
  );

  static pw.Widget headerCell(String text, {pw.Alignment? alignment}) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: headerDecoration,
        alignment: alignment ?? pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

  static pw.Widget dataCell(String text, {pw.Alignment? alignment}) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: rowBorder,
        alignment: alignment ?? pw.Alignment.centerLeft,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: fontSize)),
      );

  /// Report title block: title, optional subtitle, congregation identity with
  /// generated-on timestamp, and optionally the circuit overseer contact line.
  static pw.Widget reportTitleBlock({
    required String title,
    String? subtitle,
    Congregation? congregation,
    bool showCircuitOverseer = false,
    DateTime? generatedAt,
  }) {
    final identity = congregationIdentityLine(congregation, generatedAt);
    final overseer = showCircuitOverseer
        ? circuitOverseerSummary(congregation)
        : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: PdfStyles.title(null)),
        if (subtitle != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 12, color: footerColor),
          ),
        ],
        pw.SizedBox(height: 2),
        pw.Text(
          identity,
          style: pw.TextStyle(fontSize: 9, color: footerColor),
        ),
        if (overseer != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            overseer,
            style: pw.TextStyle(fontSize: 9, color: footerColor),
          ),
        ],
        pw.SizedBox(height: 12),
      ],
    );
  }

  /// "`name` Congregation (No. `number`) — Generated: yyyy-MM-dd HH:mm",
  /// omitting blank segments; only the generated part when no congregation.
  static String congregationIdentityLine(
    Congregation? congregation,
    DateTime? generatedAt,
  ) {
    final generated =
        'Generated: '
        '${DateFormat('yyyy-MM-dd HH:mm').format(generatedAt ?? DateTime.now())}';
    final name = congregation?.name.trim() ?? '';
    final number = congregation?.number.trim() ?? '';
    if (name.isEmpty && number.isEmpty) return generated;
    final identity = [
      if (name.isNotEmpty) '$name Congregation',
      if (number.isNotEmpty) '(No. $number)',
    ].join(' ');
    return '$identity — $generated';
  }

  /// "Circuit Overseer: John Smith & Jane Smith · (555) 123-4567 · j@x.com".
  /// Returns null when name, spouse, phone and email are all blank.
  static String? circuitOverseerSummary(Congregation? congregation) {
    if (congregation == null) return null;
    final name = congregation.circuitOverseerName.trim();
    final spouse = congregation.circuitOverseerSpouseName.trim();
    final phone = congregation.circuitOverseerPhone.trim();
    final email = congregation.circuitOverseerEmail.trim();
    final namePart = [
      if (name.isNotEmpty) name,
      if (spouse.isNotEmpty) spouse,
    ].join(' & ');
    final parts = [
      if (namePart.isNotEmpty) namePart,
      if (phone.isNotEmpty) phone,
      if (email.isNotEmpty) email,
    ];
    if (parts.isEmpty) return null;
    return 'Circuit Overseer: ${parts.join(' · ')}';
  }

  static pw.Widget pageFooter(pw.Context context, {String? leftText}) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      if (leftText != null)
        pw.Text(leftText, style: pw.TextStyle(fontSize: 8, color: footerColor)),
      if (leftText == null) pw.SizedBox(),
      pw.Text(
        'Page ${context.pageNumber} / ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 8, color: footerColor),
      ),
    ],
  );
}

/// Formats a person name as "LastName, FirstName".
String formatPersonName(String firstName, String lastName) {
  final f = firstName.trim();
  final l = lastName.trim();
  if (l.isEmpty && f.isEmpty) return '—';
  if (l.isEmpty) return f;
  if (f.isEmpty) return l;
  return '$l, $f';
}
