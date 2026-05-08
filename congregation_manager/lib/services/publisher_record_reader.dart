import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:congregation_manager/data/enums.dart';

/// Reads publisher data from S-21 PDF form files.
/// Supports both form-fillable and flattened PDFs.
class PublisherRecordReader {
  // Form field names
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

  // Month row indices (Sept=20 .. Aug=31)
  static const _monthRows = <int, int>{
    9: 20,
    10: 21,
    11: 22,
    12: 23,
    1: 24,
    2: 25,
    3: 26,
    4: 27,
    5: 28,
    6: 29,
    7: 30,
    8: 31,
  };

  static String _sharedField(int row) => '901_${row}_CheckBox';
  static String _studiesField(int row) => '902_${row}_Text_C_SanSerif';
  static String _auxPioneerField(int row) => '903_${row}_CheckBox';
  static String _hoursField(int row) => '904_${row}_S21_Value';
  static String _remarksField(int row) => '905_${row}_Text_SanSerif';

  /// Read a person and their service reports from an S-21 PDF file.
  static Future<ImportedPerson?> readFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final pdfDoc = sf.PdfDocument(inputBytes: bytes);

    final form = pdfDoc.form;
    if (form.fields.count == 0) {
      // Flattened PDF — try text extraction
      final result = _parseFromFlattenedPdf(pdfDoc);
      pdfDoc.dispose();
      return result;
    }

    final result = _parseFromFormFields(pdfDoc);
    pdfDoc.dispose();
    return result;
  }

  static ImportedPerson? _parseFromFormFields(sf.PdfDocument pdfDoc) {
    final form = pdfDoc.form;

    final rawName = _getTextField(form, _nameField);
    final (nameOnly, address, phone) = _parseNameField(rawName);

    String? firstName;
    String? lastName;
    if (nameOnly != null && nameOnly.isNotEmpty) {
      // Try "LastName, FirstName" format first
      if (nameOnly.contains(',')) {
        final parts = nameOnly.split(',');
        lastName = parts[0].trim();
        firstName = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
      } else {
        final parts = nameOnly.split(' ');
        if (parts.length > 1) {
          firstName = parts[0];
          lastName = parts.last;
        } else {
          firstName = parts[0];
        }
      }
    }

    if ((firstName == null || firstName.isEmpty) &&
        (lastName == null || lastName.isEmpty)) {
      return null;
    }

    final gender = _resolveGender(form);
    final hope = _resolveHope(form);
    final congRole = _resolveCongregationRole(form);
    final pioneerType = _resolvePioneerType(form);
    final serviceYear = _extractServiceYear(form);

    final reports = <ImportedServiceReport>[];
    for (final entry in _monthRows.entries) {
      final month = entry.key;
      final rowIndex = entry.value;

      final hoursText = _getTextField(form, _hoursField(rowIndex));
      double? hours;
      if (hoursText != null) {
        hours = double.tryParse(hoursText);
      }

      final studiesText = _getTextField(form, _studiesField(rowIndex));
      final studies = studiesText != null
          ? (int.tryParse(studiesText) ?? 0)
          : 0;
      final isAuxPioneer = _getCheckbox(form, _auxPioneerField(rowIndex));

      reports.add(
        ImportedServiceReport(
          year: serviceYear,
          month: month,
          sharedInMinistry: _getCheckbox(form, _sharedField(rowIndex)),
          bibleStudies: studies,
          isAuxiliaryPioneer: isAuxPioneer,
          hours: hours,
          note: _getTextField(form, _remarksField(rowIndex)),
        ),
      );
    }

    return ImportedPerson(
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      address: address,
      phoneNumber: phone,
      birthDate: _parseDateFlexible(_getTextField(form, _dobField)),
      baptismDate: _parseDateFlexible(_getTextField(form, _baptismField)),
      gender: gender,
      hopeClass: hope,
      congregationRole: congRole,
      pioneerType: pioneerType,
      serviceReports: reports,
    );
  }

  static ImportedPerson? _parseFromFlattenedPdf(sf.PdfDocument pdfDoc) {
    // Extract text from all pages
    final extractor = sf.PdfTextExtractor(pdfDoc);
    final fullText = extractor.extractText();
    final lines = fullText.split('\n').map((l) => l.trim()).toList();

    // Try to extract name
    final rawName = _extractAfterLabel(lines, 'Name:');
    if (rawName == null) return null;

    final (nameOnly, address, phone) = _parseNameField(rawName);

    String? firstName;
    String? lastName;
    if (nameOnly != null && nameOnly.isNotEmpty) {
      if (nameOnly.contains(',')) {
        final parts = nameOnly.split(',');
        lastName = parts[0].trim();
        firstName = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
      } else {
        final parts = nameOnly.split(' ');
        if (parts.length > 1) {
          firstName = parts[0];
          lastName = parts.last;
        } else {
          firstName = parts[0];
        }
      }
    }

    if ((firstName == null || firstName.isEmpty) &&
        (lastName == null || lastName.isEmpty)) {
      return null;
    }

    // Extract DOB
    final dobLine = _findLineContaining(lines, 'Date of birth:');
    String? dobText;
    if (dobLine != null) {
      final match = RegExp(r'Date of birth:\s*(\S+)').firstMatch(dobLine);
      if (match != null) dobText = match.group(1);
    }

    // Extract baptism date
    final baptismLine = _findLineContaining(lines, 'Date of Baptism:');
    String? baptismText;
    if (baptismLine != null) {
      final match = RegExp(r'Date of Baptism:\s*(\S+)').firstMatch(baptismLine);
      if (match != null) baptismText = match.group(1);
    }

    return ImportedPerson(
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      address: address,
      phoneNumber: phone,
      birthDate: _parseDateFlexible(dobText),
      baptismDate: _parseDateFlexible(baptismText),
      gender: Gender.unknown,
      hopeClass: HopeClass.unknown,
      congregationRole: CongregationRole.none,
      pioneerType: PioneerType.none,
      serviceReports: [],
    );
  }

  static (String? nameOnly, String? address, String? phone) _parseNameField(
    String? rawName,
  ) {
    if (rawName == null || rawName.isEmpty) return (null, null, null);

    String? address;
    String? phone;
    var nameOnly = rawName;

    final parenIndex = rawName.indexOf('(');
    if (parenIndex >= 0) {
      nameOnly = rawName.substring(0, parenIndex).trim();
      final closeIndex = rawName.indexOf(')', parenIndex + 1);
      if (closeIndex > parenIndex) {
        final inside = rawName.substring(parenIndex + 1, closeIndex).trim();
        final phoneMatch = RegExp(
          r'\b\d{3}-\d{4}(?:/\d{3}-\d{4})?\b',
        ).firstMatch(inside);
        if (phoneMatch != null) {
          phone = phoneMatch.group(0);
          final parsedAddress = inside
              .replaceAll(phone!, '')
              .replaceAll(RegExp(r'[, -]+$'), '')
              .trim();
          address = parsedAddress.isEmpty ? null : parsedAddress;
        } else {
          address = inside;
        }
      }
    }

    return (nameOnly, address, phone);
  }

  static String? _getTextField(sf.PdfForm form, String name) {
    final field = _findField(form, name);
    if (field is sf.PdfTextBoxField) {
      final text = field.text;
      return (text.isEmpty) ? null : text.trim();
    }
    return null;
  }

  static bool _getCheckbox(sf.PdfForm form, String name) {
    final field = _findField(form, name);
    if (field is sf.PdfCheckBoxField) {
      return field.isChecked;
    }
    return false;
  }

  static sf.PdfField? _findField(sf.PdfForm form, String name) {
    for (var i = 0; i < form.fields.count; i++) {
      if (form.fields[i].name == name) return form.fields[i];
    }
    return null;
  }

  static Gender _resolveGender(sf.PdfForm form) {
    final male = _getCheckbox(form, _maleCheckbox);
    final female = _getCheckbox(form, _femaleCheckbox);
    if (male && !female) return Gender.male;
    if (female && !male) return Gender.female;
    return Gender.unknown;
  }

  static HopeClass _resolveHope(sf.PdfForm form) {
    final otherSheep = _getCheckbox(form, _otherSheepCheckbox);
    final anointed = _getCheckbox(form, _anointedCheckbox);
    if (otherSheep && !anointed) return HopeClass.otherSheep;
    if (anointed && !otherSheep) return HopeClass.anointed;
    return HopeClass.unknown;
  }

  static CongregationRole _resolveCongregationRole(sf.PdfForm form) {
    if (_getCheckbox(form, _elderCheckbox)) return CongregationRole.elder;
    if (_getCheckbox(form, _msCheckbox)) {
      return CongregationRole.ministerialServant;
    }
    return CongregationRole.none;
  }

  static PioneerType _resolvePioneerType(sf.PdfForm form) {
    if (_getCheckbox(form, _rpCheckbox)) return PioneerType.regularPioneer;
    if (_getCheckbox(form, _spCheckbox)) return PioneerType.specialPioneer;
    if (_getCheckbox(form, _fmCheckbox)) return PioneerType.fieldMissionary;
    return PioneerType.none;
  }

  static int _extractServiceYear(sf.PdfForm form) {
    final text = _getTextField(form, _serviceYearField);
    if (text != null) {
      final year = int.tryParse(text);
      if (year != null) return year;
    }
    return DateTime.now().year;
  }

  static DateTime? _parseDateFlexible(String? s) {
    if (s == null || s.isEmpty) return null;

    final formats = [
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'), // yyyy-MM-dd
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'), // MM/dd/yyyy or dd/MM/yyyy
      RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$'), // dd.MM.yyyy
      RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$'), // dd-MM-yyyy
    ];

    // Try yyyy-MM-dd first
    final m1 = formats[0].firstMatch(s.trim());
    if (m1 != null) {
      return DateTime.tryParse(s.trim());
    }

    // Try other formats
    for (var i = 1; i < formats.length; i++) {
      final m = formats[i].firstMatch(s.trim());
      if (m != null) {
        final p1 = int.tryParse(m.group(1)!);
        final p2 = int.tryParse(m.group(2)!);
        final p3 = int.tryParse(m.group(3)!);
        if (p1 != null && p2 != null && p3 != null) {
          // Assume MM/dd/yyyy for slash format
          if (i == 1) {
            return DateTime.tryParse(
              '$p3-${p1.toString().padLeft(2, '0')}-${p2.toString().padLeft(2, '0')}',
            );
          }
          // dd.MM.yyyy or dd-MM-yyyy
          return DateTime.tryParse(
            '$p3-${p2.toString().padLeft(2, '0')}-${p1.toString().padLeft(2, '0')}',
          );
        }
      }
    }

    return DateTime.tryParse(s.trim());
  }

  static String? _extractAfterLabel(List<String> lines, String label) {
    for (final line in lines) {
      final idx = line.indexOf(label);
      if (idx >= 0) {
        return line.substring(idx + label.length).trim();
      }
    }
    return null;
  }

  static String? _findLineContaining(List<String> lines, String search) {
    for (final line in lines) {
      if (line.contains(search)) return line;
    }
    return null;
  }
}

/// A parsed person from an S-21 PDF (not yet in the database).
class ImportedPerson {
  final String firstName;
  final String lastName;
  final String? address;
  final String? phoneNumber;
  final DateTime? birthDate;
  final DateTime? baptismDate;
  final Gender gender;
  final HopeClass hopeClass;
  final CongregationRole congregationRole;
  final PioneerType pioneerType;
  final List<ImportedServiceReport> serviceReports;

  const ImportedPerson({
    required this.firstName,
    required this.lastName,
    this.address,
    this.phoneNumber,
    this.birthDate,
    this.baptismDate,
    this.gender = Gender.unknown,
    this.hopeClass = HopeClass.unknown,
    this.congregationRole = CongregationRole.none,
    this.pioneerType = PioneerType.none,
    this.serviceReports = const [],
  });

  String get fullName => '$lastName, $firstName';
}

class ImportedServiceReport {
  final int year;
  final int month;
  final bool sharedInMinistry;
  final int bibleStudies;
  final bool isAuxiliaryPioneer;
  final double? hours;
  final String? note;

  const ImportedServiceReport({
    required this.year,
    required this.month,
    this.sharedInMinistry = false,
    this.bibleStudies = 0,
    this.isAuxiliaryPioneer = false,
    this.hours,
    this.note,
  });
}
