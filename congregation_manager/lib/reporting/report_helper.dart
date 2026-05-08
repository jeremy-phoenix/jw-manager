import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared report formatting utilities.
class ReportHelper {
  ReportHelper._();

  static const PdfColor headerBg = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFBDBDBD);
  static const PdfColor titleColor = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor subtitleColor = PdfColor.fromInt(0xFF616161);
  static const double fontSize = 9;
  static const double headerFontSize = 18;
  static const double sectionFontSize = 12;

  /// Standard table header cell.
  static pw.Widget headerCell(String text, {pw.Alignment? alignment}) {
    return pw.Container(
      color: headerBg,
      padding: const pw.EdgeInsets.all(4),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)),
    );
  }

  /// Standard table data cell.
  static pw.Widget dataCell(String text, {pw.Alignment? alignment}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: alignment ?? pw.Alignment.centerLeft,
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5)),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: fontSize)),
    );
  }

  /// Standard page footer with page numbers, optional left/right text.
  static pw.Widget footer({String? leftText, String? rightText}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (leftText != null)
          pw.Text(leftText, style: const pw.TextStyle(fontSize: 8))
        else
          pw.SizedBox(),
        pw.Builder(
          builder: (context) => pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        if (rightText != null)
          pw.Text(rightText, style: const pw.TextStyle(fontSize: 8))
        else
          pw.SizedBox(),
      ],
    );
  }

  /// Standard report title widget.
  static pw.Widget title(String text) {
    return pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: headerFontSize,
          fontWeight: pw.FontWeight.bold,
          color: titleColor,
        ),
      ),
    );
  }

  /// Standard section header.
  static pw.Widget sectionHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: sectionFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Format a person name as "Last, First".
  static String formatName(String firstName, String lastName) {
    final f = firstName.trim();
    final l = lastName.trim();
    if (l.isEmpty && f.isEmpty) return '—';
    if (l.isEmpty) return f;
    if (f.isEmpty) return l;
    return '$l, $f';
  }
}
