import 'package:excel/excel.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';

/// Writes the shared report header (title, optional congregation identity and
/// circuit overseer line) starting at row 0,
/// each line merged across [columnSpan] columns.
///
/// Returns the first free row after a blank spacer row. Header height varies
/// (the circuit overseer line may be absent), so callers must seed their row
/// counters from the return value.
int writeExcelReportHeader(
  Sheet sheet, {
  required String title,
  required int columnSpan,
  Congregation? congregation,
  String? circuitOverseerLine,
}) {
  var row = 0;

  void writeMergedLine(String text, CellStyle style) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(text)
      ..cellStyle = style;
    if (columnSpan > 1) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: columnSpan - 1, rowIndex: row),
      );
    }
    row++;
  }

  writeMergedLine(
    title,
    CellStyle(
      bold: true,
      fontSize: 18,
      fontColorHex: ExcelColor.fromHexString('#2196F3'),
      horizontalAlign: HorizontalAlign.Center,
    ),
  );

  final metaStyle = CellStyle(
    fontSize: 9,
    fontColorHex: ExcelColor.fromHexString('#757575'),
    horizontalAlign: HorizontalAlign.Center,
  );
  final identity = PdfStyles.congregationIdentityLine(congregation);
  if (identity != null) {
    writeMergedLine(identity, metaStyle);
  }
  if (circuitOverseerLine != null && circuitOverseerLine.isNotEmpty) {
    // Emphasised rather than metadata-grey: the overseer contact is a field of
    // the report, not a caption for it.
    writeMergedLine(
      circuitOverseerLine,
      CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#1565C0'),
        horizontalAlign: HorizontalAlign.Center,
      ),
    );
  }

  return row + 1;
}
