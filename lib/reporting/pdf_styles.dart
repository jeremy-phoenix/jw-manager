import 'package:congregation_manager/data/database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared PDF styling constants and helpers for all reports.
class PdfStyles {
  static final headerColor = PdfColor.fromInt(0xFF1565C0); // blue darken2
  static final headerBg = PdfColor.fromInt(0xFFE0E0E0); // grey lighten3
  static final borderColor = PdfColor.fromInt(0xFFEEEEEE); // grey lighten2
  static final footerColor = PdfColor.fromInt(0xFF757575); // grey darken1
  static final calloutBg = PdfColor.fromInt(0xFFE8F1FB); // blue lighten5
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

  /// Report title block: title, optional subtitle, congregation identity, and
  /// optionally the circuit overseer contact callout.
  static pw.Widget reportTitleBlock({
    required String title,
    String? subtitle,
    Congregation? congregation,
    bool showCircuitOverseer = false,
  }) {
    final identity = congregationIdentityLine(congregation);
    final overseer = showCircuitOverseer
        ? circuitOverseerBlock(congregation)
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
        if (identity != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            identity,
            style: pw.TextStyle(fontSize: 9, color: footerColor),
          ),
        ],
        if (overseer != null) ...[pw.SizedBox(height: 8), overseer],
        pw.SizedBox(height: 12),
      ],
    );
  }

  /// "`name` Congregation (No. `number`)", omitting blank segments.
  /// Returns null when no congregation identity is available.
  static String? congregationIdentityLine(Congregation? congregation) {
    final name = congregation?.name.trim() ?? '';
    final number = congregation?.number.trim() ?? '';
    if (name.isEmpty && number.isEmpty) return null;
    return [
      if (name.isNotEmpty) '$name Congregation',
      if (number.isNotEmpty) '(No. $number)',
    ].join(' ');
  }

  /// Circuit overseer contact callout: an accent-barred, tinted block naming
  /// the overseer and listing every contact detail on file. Used instead of a
  /// metadata line so the contact reads as a field of the report rather than a
  /// footnote. Returns null when every overseer field is blank.
  static pw.Widget? circuitOverseerBlock(Congregation? congregation) {
    if (congregation == null) return null;
    final namePart = _overseerName(congregation);
    final fields = <List<String>>[
      for (final field in [
        ['Phone', congregation.circuitOverseerPhone],
        ['Email', congregation.circuitOverseerEmail],
        ['Address', congregation.circuitOverseerAddress],
      ])
        if (field[1].trim().isNotEmpty) [field[0], field[1].trim()],
    ];
    if (namePart.isEmpty && fields.isEmpty) return null;

    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 7),
            decoration: pw.BoxDecoration(
              color: calloutBg,
              border: pw.Border(
                left: pw.BorderSide(color: headerColor, width: 3),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CIRCUIT OVERSEER',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                    color: headerColor,
                  ),
                ),
                if (namePart.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    namePart,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
                if (fields.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Wrap(
                    spacing: 20,
                    runSpacing: 3,
                    children: [
                      for (final field in fields)
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              field[0],
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: footerColor,
                              ),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Text(
                              field[1],
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// "Circuit Overseer: John Smith & Jane Smith · (555) 123-4567 · j@x.com
  /// · 1 Circuit Way", omitting blank segments. Single-line form used where a
  /// callout cannot be drawn, such as the Excel header.
  /// Returns null when every overseer field is blank.
  static String? circuitOverseerSummary(Congregation? congregation) {
    if (congregation == null) return null;
    final namePart = _overseerName(congregation);
    final parts = [
      if (namePart.isNotEmpty) namePart,
      for (final value in [
        congregation.circuitOverseerPhone,
        congregation.circuitOverseerEmail,
        congregation.circuitOverseerAddress,
      ])
        if (value.trim().isNotEmpty) value.trim(),
    ];
    if (parts.isEmpty) return null;
    return 'Circuit Overseer: ${parts.join(' · ')}';
  }

  /// "John Smith & Jane Smith", or an empty string when both names are blank.
  static String _overseerName(Congregation congregation) {
    final name = congregation.circuitOverseerName.trim();
    final spouse = congregation.circuitOverseerSpouseName.trim();
    return [
      if (name.isNotEmpty) name,
      if (spouse.isNotEmpty) spouse,
    ].join(' & ');
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
  if (l.isEmpty && f.isEmpty) return '';
  if (l.isEmpty) return f;
  if (f.isEmpty) return l;
  return '$l, $f';
}
