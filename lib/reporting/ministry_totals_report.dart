import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/data/statistics.dart';
import 'package:congregation_manager/reporting/excel_report_header.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';
import 'package:congregation_manager/reporting/service_report_group_data.dart';

/// Report title, shared by the PDF, the Excel workbook and the menu entries.
const String kMinistryTotalsTitle = 'Congregation Ministry Totals';

/// One month of one publisher category within a service year.
class MinistryTotalsMonth {
  final ServiceMonth month;
  final int reportingPublishers;
  final int bibleStudies;
  final double hours;

  const MinistryTotalsMonth({
    required this.month,
    this.reportingPublishers = 0,
    this.bibleStudies = 0,
    this.hours = 0,
  });

  /// Months nobody has reported yet are left blank rather than shown as zero.
  bool get hasReports => reportingPublishers > 0;
}

/// One category block of the ministry totals report: the twelve service-year
/// months, with the total and average lines beneath them.
class MinistryTotalsSection {
  final FieldServicePublisherCategory category;
  final String title;

  /// Publishers do not report hours, so their section omits the column.
  final bool showsHours;

  /// The twelve months in service-year order, September first.
  final List<MinistryTotalsMonth> months;

  const MinistryTotalsSection({
    required this.category,
    required this.title,
    required this.showsHours,
    required this.months,
  });

  /// Months with at least one report — the divisor for the averages, so a
  /// service year still under way averages only the months reported so far.
  int get reportedMonthCount => months.where((m) => m.hasReports).length;

  bool get hasReports => reportedMonthCount > 0;

  int get totalBibleStudies => months.fold(0, (sum, m) => sum + m.bibleStudies);
  double get totalHours =>
      _roundHours(months.fold(0.0, (sum, m) => sum + m.hours));
  int get totalReportingPublishers =>
      months.fold(0, (sum, m) => sum + m.reportingPublishers);

  int get averageBibleStudies => _average(totalBibleStudies.toDouble());
  int get averageHours => _average(totalHours);
  int get averageReportingPublishers =>
      _average(totalReportingPublishers.toDouble());

  int _average(double total) =>
      reportedMonthCount == 0 ? 0 : (total / reportedMonthCount).round();
}

/// Build the ministry totals sections for [serviceYear].
///
/// [reports] may hold any months; only rows stored under [serviceYear] count.
/// A report counts once the publisher indicated activity, matching the app's
/// month-statistics definition, and is classified from the publisher's current
/// pioneer type together with that month's auxiliary pioneer flag.
///
/// Publishers, auxiliary pioneers and regular pioneers always get a section so
/// the sheet keeps its familiar shape; special pioneers and field missionaries
/// appear only when the congregation has any.
List<MinistryTotalsSection> buildMinistryTotals({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required int serviceYear,
}) {
  final pioneerTypeByPerson = {for (final p in persons) p.id: p.pioneerType};
  final tallies = {
    for (final category in FieldServicePublisherCategory.values)
      category: <int, _MonthTally>{},
  };

  for (final report in reports) {
    if (report.year != serviceYear) continue;
    if (!report.sharedInMinistry &&
        report.hours <= 0 &&
        report.bibleStudies <= 0) {
      continue;
    }
    final category = classifyFieldServicePublisher(
      pioneerType: pioneerTypeByPerson[report.personId] ?? PioneerType.none,
      isAuxiliaryPioneer: report.isAuxiliaryPioneer,
    );
    final tally = tallies[category]!.putIfAbsent(report.month, _MonthTally.new);
    tally.reportingPublishers++;
    tally.bibleStudies += report.bibleStudies;
    tally.hours += report.hours;
  }

  final sections = <MinistryTotalsSection>[];
  for (final entry in _sectionSpecs.entries) {
    final spec = entry.value;
    final byMonth = tallies[entry.key]!;
    final section = MinistryTotalsSection(
      category: entry.key,
      title: spec.title,
      showsHours: spec.showsHours,
      months: [
        for (final month in ServiceMonth.values)
          _monthTotals(month, byMonth[month.monthNumber]),
      ],
    );
    if (spec.alwaysShown || section.hasReports) sections.add(section);
  }
  return sections;
}

class _MonthTally {
  int reportingPublishers = 0;
  int bibleStudies = 0;
  double hours = 0;
}

class _SectionSpec {
  final String title;
  final bool showsHours;

  /// Whether the section is printed even with nothing to show in it.
  final bool alwaysShown;

  const _SectionSpec(
    this.title, {
    this.showsHours = true,
    this.alwaysShown = false,
  });
}

const _sectionSpecs = <FieldServicePublisherCategory, _SectionSpec>{
  FieldServicePublisherCategory.publisher: _SectionSpec(
    'Publishers',
    showsHours: false,
    alwaysShown: true,
  ),
  FieldServicePublisherCategory.auxiliaryPioneer: _SectionSpec(
    'Auxiliary Pioneers',
    alwaysShown: true,
  ),
  FieldServicePublisherCategory.regularPioneer: _SectionSpec(
    'Regular Pioneers',
    alwaysShown: true,
  ),
  FieldServicePublisherCategory.specialPioneer: _SectionSpec(
    'Special Pioneers',
  ),
  FieldServicePublisherCategory.fieldMissionary: _SectionSpec(
    'Field Missionaries',
  ),
};

MinistryTotalsMonth _monthTotals(ServiceMonth month, _MonthTally? tally) {
  if (tally == null) return MinistryTotalsMonth(month: month);
  return MinistryTotalsMonth(
    month: month,
    reportingPublishers: tally.reportingPublishers,
    bibleStudies: tally.bibleStudies,
    hours: _roundHours(tally.hours),
  );
}

/// Summing a congregation's worth of hours leaves floating-point drift that
/// would print as "329.0" instead of "329". Hours are reported in whole or
/// half hours, so a single decimal is the real precision of the figure.
double _roundHours(double hours) => (hours * 10).round() / 10;

/// Hours for a month that was reported: a genuine zero still prints, so blank
/// cells only ever mean "not reported".
String _hoursFigure(double hours) {
  final text = formatHours(hours);
  return text.isEmpty ? '0' : text;
}

/// Congregation Ministry Totals — portrait PDF, one table per publisher
/// category, each kept whole on a page.
pw.Document generateMinistryTotalsReport({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required int serviceYear,
  Congregation? congregation,
}) {
  final sections = buildMinistryTotals(
    persons: persons,
    reports: reports,
    serviceYear: serviceYear,
  );
  final subtitle = 'Service Year $serviceYear';
  final pdf = pw.Document(title: '$kMinistryTotalsTitle - $subtitle');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(34),
      maxPages: PdfStyles.maxPages,
      header: (context) => context.pageNumber == 1
          ? PdfStyles.reportTitleBlock(
              title: kMinistryTotalsTitle,
              subtitle: subtitle,
              congregation: congregation,
            )
          : pw.SizedBox(),
      footer: (context) => PdfStyles.pageFooter(context),
      build: (context) => [
        for (var i = 0; i < sections.length; i++) ...[
          // Break early rather than split a section's title off its table.
          if (i > 0) pw.NewPage(freeSpace: _estimatedSectionHeight),
          _sectionBlock(sections[i]),
          pw.SizedBox(height: 22),
        ],
      ],
    ),
  );

  return pdf;
}

/// Roughly the height of one section: the column header, twelve month rows,
/// the total and average rows, and the section title above them.
const double _estimatedSectionHeight = 320;

pw.Widget _sectionBlock(MinistryTotalsSection section) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        section.title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1.2,
          color: PdfStyles.headerColor,
        ),
      ),
      pw.SizedBox(height: 6),
      // Held to a fixed width: stretched across the page, four short numeric
      // columns leave gaps wide enough to read as missing data.
      pw.SizedBox(width: _tableWidth, child: _sectionTable(section)),
    ],
  );
}

/// Width of every section table, so the blocks line up down the page.
const double _tableWidth = 430;

pw.Widget _sectionTable(MinistryTotalsSection section) {
  const right = pw.Alignment.centerRight;
  final hasReports = section.hasReports;

  List<pw.Widget> row(
    String month,
    String hours,
    String studies,
    String reporting, {
    PdfColor? monthColor,
    bool bold = false,
  }) => [
    _cell(month, color: monthColor, bold: bold),
    if (section.showsHours) _cell(hours, alignment: right, bold: bold),
    _cell(studies, alignment: right, bold: bold),
    _cell(reporting, alignment: right, bold: bold),
  ];

  // Backgrounds belong to the row: a per-cell fill leaves a white seam at
  // every column boundary, breaking the header band and the total rows up.
  final summaryDecoration = pw.BoxDecoration(color: PdfStyles.calloutBg);

  return pw.Table(
    // Likewise the rules, which otherwise seam at each column and read as
    // broken across the empty months.
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
      bottom: pw.BorderSide(color: PdfStyles.borderColor, width: 0.5),
    ),
    columnWidths: section.showsHours
        ? const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.3),
          }
        : const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1.3),
          },
    children: [
      pw.TableRow(
        decoration: PdfStyles.headerDecoration,
        children: row(
          'Month',
          'Hours',
          'Bible Studies',
          'Reporting',
          bold: true,
        ),
      ),
      for (final month in section.months)
        pw.TableRow(
          children: row(
            month.month.displayName,
            month.hasReports ? _hoursFigure(month.hours) : '',
            month.hasReports ? '${month.bibleStudies}' : '',
            month.hasReports ? '${month.reportingPublishers}' : '',
            // Months still to come recede so the reported ones carry the eye.
            monthColor: month.hasReports ? null : PdfStyles.footerColor,
          ),
        ),
      pw.TableRow(
        decoration: summaryDecoration,
        children: row(
          'Total',
          hasReports ? _hoursFigure(section.totalHours) : '',
          hasReports ? '${section.totalBibleStudies}' : '',
          // Summing monthly head counts would be meaningless.
          '',
          bold: true,
        ),
      ),
      pw.TableRow(
        decoration: summaryDecoration,
        children: row(
          'Average',
          hasReports ? '${section.averageHours}' : '',
          hasReports ? '${section.averageBibleStudies}' : '',
          hasReports ? '${section.averageReportingPublishers}' : '',
          bold: true,
        ),
      ),
    ],
  );
}

pw.Widget _cell(
  String text, {
  pw.Alignment alignment = pw.Alignment.centerLeft,
  PdfColor? color,
  bool bold = false,
}) => pw.Container(
  padding: const pw.EdgeInsets.all(4),
  alignment: alignment,
  child: pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: PdfStyles.fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    ),
  ),
);

/// Build the same report as an Excel (.xlsx) workbook.
///
/// Every section keeps the same four columns, the Hours column simply staying
/// empty for publishers, so the sheet reads consistently from top to bottom.
Uint8List buildMinistryTotalsExcel({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required int serviceYear,
  Congregation? congregation,
}) {
  final sections = buildMinistryTotals(
    persons: persons,
    reports: reports,
    serviceYear: serviceYear,
  );

  final excel = Excel.createExcel();
  const sheetName = 'Ministry Totals';
  excel.rename(excel.getDefaultSheet()!, sheetName);
  final sheet = excel[sheetName];
  const columnSpan = 4;

  void put(int col, int row, CellValue value, {CellStyle? style}) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    if (style != null) cell.cellStyle = style;
  }

  final sectionStyle = CellStyle(bold: true, fontSize: 12);
  final headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
    horizontalAlign: HorizontalAlign.Center,
  );
  final totalStyle = CellStyle(bold: true);

  var row = writeExcelReportHeader(
    sheet,
    title: '$kMinistryTotalsTitle - Service Year $serviceYear',
    columnSpan: columnSpan,
    congregation: congregation,
  );

  for (final section in sections) {
    put(0, row, TextCellValue(section.title), style: sectionStyle);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: columnSpan - 1, rowIndex: row),
    );
    row++;

    const headers = ['Month', 'Hours', 'Bible Studies', 'Reporting'];
    for (var col = 0; col < headers.length; col++) {
      put(col, row, TextCellValue(headers[col]), style: headerStyle);
    }
    row++;

    for (final month in section.months) {
      put(0, row, TextCellValue(month.month.displayName));
      if (month.hasReports) {
        if (section.showsHours) put(1, row, DoubleCellValue(month.hours));
        put(2, row, IntCellValue(month.bibleStudies));
        put(3, row, IntCellValue(month.reportingPublishers));
      }
      row++;
    }

    put(0, row, TextCellValue('Total'), style: totalStyle);
    if (section.hasReports) {
      if (section.showsHours) {
        put(1, row, DoubleCellValue(section.totalHours), style: totalStyle);
      }
      put(2, row, IntCellValue(section.totalBibleStudies), style: totalStyle);
    }
    row++;

    put(0, row, TextCellValue('Average'), style: totalStyle);
    if (section.hasReports) {
      if (section.showsHours) {
        put(1, row, IntCellValue(section.averageHours), style: totalStyle);
      }
      put(2, row, IntCellValue(section.averageBibleStudies), style: totalStyle);
      put(
        3,
        row,
        IntCellValue(section.averageReportingPublishers),
        style: totalStyle,
      );
    }
    row += 2;
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to generate Excel file.');
  }
  return Uint8List.fromList(bytes);
}
