import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/services/export_progress.dart';

/// Writes publisher data into S-21 PDF forms.
/// Uses the bundled S-21_E.pdf template and fills form fields via Syncfusion.
class PublisherRecordWriter {
  // Field names matching the S-21 form
  static const _nameField = '900_1_Text_SanSerif';
  static const _dobField = '900_2_Text_SanSerif';
  static const _baptismField = '900_5_Text_SanSerif';
  static const _serviceYearField = '900_13_Text_C_SanSerif';

  static const _maleCheckbox = '900_3_CheckBox';
  static const _femaleCheckbox = '900_4_CheckBox';
  static const _otherSheepCheckbox = '900_6_CheckBox';
  static const _anointedCheckbox = '900_7_CheckBox';
  static const _elderCheckbox = '900_8_CheckBox';
  static const _msCheckbox = '900_9_CheckBox';
  static const _rpCheckbox = '900_10_CheckBox';
  static const _spCheckbox = '900_11_CheckBox';
  static const _fmCheckbox = '900_12_CheckBox';
  static const _totalHoursField = '904_32_S21_Value';

  // Month row indices (Sept=20 .. Aug=31)
  static const _monthRows = <int, int>{
    9: 20, 10: 21, 11: 22, 12: 23, // Sept-Dec
    1: 24, 2: 25, 3: 26, 4: 27, 5: 28, 6: 29, 7: 30, 8: 31, // Jan-Aug
  };

  static String _sharedField(int row) => '901_${row}_CheckBox';
  static String _studiesField(int row) => '902_${row}_Text_C_SanSerif';
  static String _auxPioneerField(int row) => '903_${row}_CheckBox';
  static String _hoursField(int row) => '904_${row}_S21_Value';
  static String _remarksField(int row) => '905_${row}_Text_SanSerif';

  static _TemplateBounds? _templateBounds;

  /// Load the bundled S-21_E.pdf template bytes.
  static Future<Uint8List> getTemplateBytes() async {
    final data = await rootBundle.load('assets/forms/S-21_E.pdf');
    return data.buffer.asUint8List();
  }

  /// Get the current service year (Sept starts new year).
  static int getCurrentServiceYear() {
    final now = DateTime.now();
    return now.month >= 9 ? now.year + 1 : now.year;
  }

  /// Write a single person's S-21 record for a service year.
  static Future<void> writePersonRecord({
    required Person person,
    required int serviceYear,
    required List<ServiceReport> reports,
    required String outputPath,
    bool flatten = false,
    bool onlyUpToPreviousMonth = false,
  }) async {
    final templateBytes = await getTemplateBytes();
    final pdfDoc = sf.PdfDocument(inputBytes: templateBytes);

    _fillPersonFields(
      pdfDoc,
      person,
      serviceYear,
      reports,
      onlyUpToPreviousMonth,
    );

    if (flatten) {
      pdfDoc.form.flattenAllFields();
    }

    final bytes = await pdfDoc.save();
    pdfDoc.dispose();
    await File(outputPath).writeAsBytes(bytes);
  }

  /// Write the selected and previous service years onto a single S-21 page.
  static Future<void> writePersonRecordTwoYears({
    required Person person,
    required int serviceYear,
    required List<ServiceReport> reports,
    required String outputPath,
    bool onlyUpToPreviousMonth = false,
  }) async {
    final bounds = await _getTemplateBounds();
    final previousBytes = await _fillTemplateToBytes(
      person: person,
      serviceYear: serviceYear - 1,
      reports: reports,
      onlyUpToPreviousMonth: onlyUpToPreviousMonth,
    );
    final currentBytes = await _fillTemplateToBytes(
      person: person,
      serviceYear: serviceYear,
      reports: reports,
      onlyUpToPreviousMonth: onlyUpToPreviousMonth,
    );

    final previousDoc = sf.PdfDocument(inputBytes: previousBytes);
    final currentDoc = sf.PdfDocument(inputBytes: currentBytes);
    final outputDoc = sf.PdfDocument();
    outputDoc.pageSettings
      ..size = ui.Size(bounds.pageWidth, bounds.pageHeight)
      ..setMargins(0);

    final page = outputDoc.pages.add();
    final graphics = page.graphics;
    final previousTemplate = previousDoc.pages[0].createTemplate();
    final currentTemplate = currentDoc.pages[0].createTemplate();

    final headerHeight = bounds.tableTopY;
    final tableHeight = bounds.tableBottomY - bounds.tableTopY;
    const tableGap = 10.0;
    const footerHeight = 15.0;
    final available =
        bounds.pageHeight - headerHeight - footerHeight - tableGap;
    final scale = math.min(1.0, available / (2 * tableHeight));
    final scaledTableHeight = tableHeight * scale;
    final scaledPageSize = ui.Size(bounds.pageWidth, bounds.pageHeight * scale);

    _drawClippedTemplate(
      graphics,
      previousTemplate,
      clip: ui.Rect.fromLTWH(0, 0, bounds.pageWidth, headerHeight),
      offset: ui.Offset.zero,
      size: ui.Size(bounds.pageWidth, bounds.pageHeight),
    );

    final firstTableTop = headerHeight;
    _drawClippedTemplate(
      graphics,
      previousTemplate,
      clip: ui.Rect.fromLTWH(
        0,
        firstTableTop,
        bounds.pageWidth,
        scaledTableHeight,
      ),
      offset: ui.Offset(0, firstTableTop - bounds.tableTopY * scale),
      size: scaledPageSize,
    );

    final secondTableTop = firstTableTop + scaledTableHeight + tableGap;
    _drawClippedTemplate(
      graphics,
      currentTemplate,
      clip: ui.Rect.fromLTWH(
        0,
        secondTableTop,
        bounds.pageWidth,
        scaledTableHeight,
      ),
      offset: ui.Offset(0, secondTableTop - bounds.tableTopY * scale),
      size: scaledPageSize,
    );

    graphics.drawString(
      'S-21 11/23',
      sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 7),
      bounds: ui.Rect.fromLTWH(10, bounds.pageHeight - 12, 100, 10),
    );

    final bytes = await outputDoc.save();
    previousDoc.dispose();
    currentDoc.dispose();
    outputDoc.dispose();
    await File(outputPath).writeAsBytes(bytes);
  }

  static void _drawClippedTemplate(
    sf.PdfGraphics graphics,
    sf.PdfTemplate template, {
    required ui.Rect clip,
    required ui.Offset offset,
    required ui.Size size,
  }) {
    final state = graphics.save();
    graphics.setClip(bounds: clip);
    graphics.drawPdfTemplate(template, offset, size);
    graphics.restore(state);
  }

  static Future<_TemplateBounds> _getTemplateBounds() async {
    final cached = _templateBounds;
    if (cached != null) return cached;

    final templateBytes = await getTemplateBytes();
    final pdfDoc = sf.PdfDocument(inputBytes: templateBytes);
    final page = pdfDoc.pages[0];
    final pageSize = page.size;
    final serviceYearField = _findField(pdfDoc.form, _serviceYearField);
    final totalHoursField = _findField(pdfDoc.form, _totalHoursField);

    if (serviceYearField == null || totalHoursField == null) {
      pdfDoc.dispose();
      final fallback = _TemplateBounds(
        pageWidth: pageSize.width,
        pageHeight: pageSize.height,
        tableTopY: pageSize.height * 0.28,
        tableBottomY: pageSize.height * 0.92,
      );
      _templateBounds = fallback;
      return fallback;
    }

    final tableTopY = math.max(0.0, serviceYearField.bounds.top - 30);
    final tableBottomY = math.min(
      pageSize.height,
      totalHoursField.bounds.bottom + 5,
    );
    final bounds = _TemplateBounds(
      pageWidth: pageSize.width,
      pageHeight: pageSize.height,
      tableTopY: tableTopY,
      tableBottomY: tableBottomY,
    );
    pdfDoc.dispose();
    _templateBounds = bounds;
    return bounds;
  }

  /// Generate S-21 PDF bytes in memory (for two-year mode).
  static Future<Uint8List> _fillTemplateToBytes({
    required Person person,
    required int serviceYear,
    required List<ServiceReport> reports,
    bool onlyUpToPreviousMonth = false,
  }) async {
    final templateBytes = await getTemplateBytes();
    final pdfDoc = sf.PdfDocument(inputBytes: templateBytes);

    _fillPersonFields(
      pdfDoc,
      person,
      serviceYear,
      reports,
      onlyUpToPreviousMonth,
    );
    pdfDoc.form.flattenAllFields();

    final bytes = await pdfDoc.save();
    pdfDoc.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Export all active persons as individual S-21 PDFs to a directory.
  static Future<List<String>> exportAllPersonRecords({
    required List<Person> persons,
    required Map<int, List<ServiceReport>> reportsByPerson,
    required int serviceYear,
    required String outputDir,
    bool flatten = false,
    bool onlyUpToPreviousMonth = false,
    bool groupByRole = false,
    bool twoYearsPerPage = false,
    String Function(Person)? fileNameFormatter,
    ExportProgressCallback? onProgress,
  }) async {
    final errors = <String>[];
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    if (persons.isEmpty) {
      onProgress?.call(
        const ExportProgress(
          current: 0,
          total: 0,
          message: 'No active publishers to export',
        ),
      );
      return errors;
    }

    for (var i = 0; i < persons.length; i++) {
      final person = persons[i];
      final displayName = '${person.lastName}, ${person.firstName}';
      onProgress?.call(
        ExportProgress(
          current: i,
          total: persons.length,
          message: 'Exporting S-21 records',
          detail: displayName,
        ),
      );

      try {
        final reports = reportsByPerson[person.id] ?? [];
        final yearReports = reports
            .where((r) => r.year == serviceYear)
            .toList();

        String subDir = outputDir;
        if (groupByRole) {
          final roleName = _getRoleFolderName(person);
          subDir = '$outputDir/$roleName';
          final roleDir = Directory(subDir);
          if (!await roleDir.exists()) {
            await roleDir.create(recursive: true);
          }
        }

        final fileName = fileNameFormatter != null
            ? fileNameFormatter(person)
            : '${person.lastName}, ${person.firstName}';
        final safeName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        final filePath = '$subDir/$safeName.pdf';

        if (twoYearsPerPage) {
          await writePersonRecordTwoYears(
            person: person,
            serviceYear: serviceYear,
            reports: reports,
            outputPath: filePath,
            onlyUpToPreviousMonth: onlyUpToPreviousMonth,
          );
        } else {
          await writePersonRecord(
            person: person,
            serviceYear: serviceYear,
            reports: yearReports,
            outputPath: filePath,
            flatten: flatten,
            onlyUpToPreviousMonth: onlyUpToPreviousMonth,
          );
        }
      } catch (e) {
        errors.add('$displayName: ${e.toString()}');
      }

      onProgress?.call(
        ExportProgress(
          current: i + 1,
          total: persons.length,
          message: 'Exporting S-21 records',
          detail: displayName,
        ),
      );
    }

    onProgress?.call(
      ExportProgress(
        current: persons.length,
        total: persons.length,
        message: 'Export complete',
      ),
    );

    return errors;
  }

  static String _getRoleFolderName(Person person) {
    if (person.pioneerType == PioneerType.regularPioneer) {
      return 'Regular Pioneers';
    }
    if (person.pioneerType == PioneerType.specialPioneer) {
      return 'Special Pioneers';
    }
    if (person.pioneerType == PioneerType.fieldMissionary) {
      return 'Field Missionaries';
    }
    if (person.congregationRole == CongregationRole.elder) return 'Elders';
    if (person.congregationRole == CongregationRole.ministerialServant) {
      return 'Ministerial Servants';
    }
    return 'Publishers';
  }

  static void _fillPersonFields(
    sf.PdfDocument pdfDoc,
    Person person,
    int serviceYear,
    List<ServiceReport> reports,
    bool onlyUpToPreviousMonth,
  ) {
    final form = pdfDoc.form;

    _setTextField(form, _nameField, '${person.lastName}, ${person.firstName}');

    if (person.birthDate != null) {
      _setTextField(form, _dobField, _formatDate(person.birthDate!));
    }
    if (person.baptismDate != null) {
      _setTextField(form, _baptismField, _formatDate(person.baptismDate!));
    }

    // Gender
    if (person.gender == Gender.male) {
      _setCheckbox(form, _maleCheckbox, true);
    } else if (person.gender == Gender.female) {
      _setCheckbox(form, _femaleCheckbox, true);
    }

    // Hope
    if (person.hopeClass == HopeClass.otherSheep) {
      _setCheckbox(form, _otherSheepCheckbox, true);
    } else if (person.hopeClass == HopeClass.anointed) {
      _setCheckbox(form, _anointedCheckbox, true);
    }

    // Congregation role
    if (person.congregationRole == CongregationRole.elder) {
      _setCheckbox(form, _elderCheckbox, true);
    } else if (person.congregationRole == CongregationRole.ministerialServant) {
      _setCheckbox(form, _msCheckbox, true);
    }

    // Pioneer type
    if (person.pioneerType == PioneerType.regularPioneer) {
      _setCheckbox(form, _rpCheckbox, true);
    } else if (person.pioneerType == PioneerType.specialPioneer) {
      _setCheckbox(form, _spCheckbox, true);
    } else if (person.pioneerType == PioneerType.fieldMissionary) {
      _setCheckbox(form, _fmCheckbox, true);
    }

    // Service year
    _setTextField(form, _serviceYearField, serviceYear.toString());

    // Monthly rows
    final reportsByMonth = <int, ServiceReport>{};
    for (final r in reports) {
      if (r.year == serviceYear) reportsByMonth[r.month] = r;
    }

    final now = DateTime.now();
    double totalHours = 0;

    for (final entry in _monthRows.entries) {
      final month = entry.key;
      final rowIndex = entry.value;
      final report = reportsByMonth[month];
      if (report == null) continue;

      // Skip current and future months if requested
      if (onlyUpToPreviousMonth) {
        final calendarYear = month >= 9 ? serviceYear - 1 : serviceYear;
        if (calendarYear > now.year ||
            (calendarYear == now.year && month >= now.month)) {
          continue;
        }
      }

      if (report.sharedInMinistry) {
        _setCheckbox(form, _sharedField(rowIndex), true);
      }
      if (report.bibleStudies > 0) {
        _setTextField(
          form,
          _studiesField(rowIndex),
          report.bibleStudies.toString(),
        );
      }
      if (report.isAuxiliaryPioneer) {
        _setCheckbox(form, _auxPioneerField(rowIndex), true);
      }
      if (report.hours > 0) {
        final h = report.hours;
        _setTextField(
          form,
          _hoursField(rowIndex),
          h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1),
        );
        totalHours += h;
      }
      if (report.note.isNotEmpty) {
        _setTextField(form, _remarksField(rowIndex), report.note);
      }
    }

    if (totalHours > 0) {
      _setTextField(
        form,
        _totalHoursField,
        totalHours == totalHours.roundToDouble()
            ? totalHours.toInt().toString()
            : totalHours.toStringAsFixed(1),
      );
    }
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static void _setTextField(sf.PdfForm form, String name, String value) {
    final field = _findField(form, name);
    if (field is sf.PdfTextBoxField) {
      field.text = value;
    }
  }

  static void _setCheckbox(sf.PdfForm form, String name, bool checked) {
    final field = _findField(form, name);
    if (field is sf.PdfCheckBoxField) {
      field.isChecked = checked;
    }
  }

  static sf.PdfField? _findField(sf.PdfForm form, String name) {
    for (var i = 0; i < form.fields.count; i++) {
      if (form.fields[i].name == name) return form.fields[i];
    }
    return null;
  }
}

class _TemplateBounds {
  final double pageWidth;
  final double pageHeight;
  final double tableTopY;
  final double tableBottomY;

  const _TemplateBounds({
    required this.pageWidth,
    required this.pageHeight,
    required this.tableTopY,
    required this.tableBottomY,
  });
}
