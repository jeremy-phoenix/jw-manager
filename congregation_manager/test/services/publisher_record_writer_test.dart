import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/services/publisher_record_writer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes custom record name and explicit text field fonts', () async {
    final tempDir = await Directory.systemTemp.createTemp('s21_writer_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final outputPath = '${tempDir.path}${Platform.pathSeparator}s21.pdf';
    final now = DateTime(2026, 6, 11);
    final person = Person(
      id: 1,
      firstName: 'John',
      lastName: 'Doe',
      otherNames: '',
      birthDate: DateTime(1990, 1, 2),
      baptismDate: DateTime(2010, 3, 4),
      gender: Gender.male,
      hopeClass: HopeClass.otherSheep,
      congregationRole: CongregationRole.none,
      pioneerType: PioneerType.none,
      address: '',
      email: '',
      isActive: true,
      recordStatus: PersonRecordStatus.current,
      congregationId: 1,
      serverVersion: 0,
      createdAt: now,
      updatedAt: now,
    );
    final reports = [
      ServiceReport(
        id: 1,
        year: 2026,
        month: 9,
        isAuxiliaryPioneer: false,
        isActive: true,
        sharedInMinistry: true,
        bibleStudies: 2,
        hours: 12.5,
        note: 'Encouraging note',
        personId: person.id,
        serverVersion: 0,
      ),
    ];

    await PublisherRecordWriter.writePersonRecord(
      person: person,
      serviceYear: 2026,
      reports: reports,
      outputPath: outputPath,
      nameFormatter: (person) => '${person.firstName} ${person.lastName}',
    );

    final document = sf.PdfDocument(
      inputBytes: await File(outputPath).readAsBytes(),
    );
    try {
      final form = document.form;
      final nameField = _textField(form, '900_1_Text_SanSerif');
      final birthDateField = _textField(form, '900_2_Text_SanSerif');
      final baptismDateField = _textField(form, '900_5_Text_SanSerif');
      final studiesField = _textField(form, '902_20_Text_C_SanSerif');
      final hoursField = _textField(form, '904_20_S21_Value');
      final remarksField = _textField(form, '905_20_Text_SanSerif');

      expect(nameField.text, 'John Doe');
      expect(birthDateField.text, '1990-01-02');
      expect(baptismDateField.text, '2010-03-04');
      expect(studiesField.text, '2');
      expect(hoursField.text, '12.5');
      expect(remarksField.text, 'Encouraging note');

      for (final field in [
        nameField,
        birthDateField,
        baptismDateField,
        studiesField,
        hoursField,
        remarksField,
      ]) {
        expect(field.font.size, closeTo(10.5, 0.001));
      }
    } finally {
      document.dispose();
    }
  });

  test('places inactive publishers in a separate Inactive folder', () async {
    final tempDir = await Directory.systemTemp.createTemp('s21_inactive_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final active = _person(id: 1, lastName: 'Active', isActive: true);
    final inactive = _person(id: 2, lastName: 'Inactive', isActive: false);

    final errors = await PublisherRecordWriter.exportAllPersonRecords(
      persons: [active, inactive],
      reportsByPerson: const {},
      serviceYear: 2026,
      outputDir: tempDir.path,
      groupByRole: true,
    );

    expect(errors, isEmpty);
    expect(
      File('${tempDir.path}/Publishers/Active, John.pdf').existsSync(),
      isTrue,
    );
    expect(
      File(
        '${tempDir.path}/Inactive/Publishers/Inactive, John.pdf',
      ).existsSync(),
      isTrue,
    );
  });
}

Person _person({
  required int id,
  required String lastName,
  required bool isActive,
}) {
  final now = DateTime(2026, 6, 11);
  return Person(
    id: id,
    firstName: 'John',
    lastName: lastName,
    otherNames: '',
    gender: Gender.male,
    hopeClass: HopeClass.otherSheep,
    congregationRole: CongregationRole.none,
    pioneerType: PioneerType.none,
    address: '',
    email: '',
    isActive: isActive,
    recordStatus: PersonRecordStatus.current,
    congregationId: 1,
    serverVersion: 0,
    createdAt: now,
    updatedAt: now,
  );
}

sf.PdfTextBoxField _textField(sf.PdfForm form, String name) {
  final field = _findField(form, name);
  expect(field, isNotNull, reason: 'Expected PDF field $name to exist.');
  expect(field, isA<sf.PdfTextBoxField>());
  return field! as sf.PdfTextBoxField;
}

sf.PdfField? _findField(sf.PdfForm form, String name) {
  for (var index = 0; index < form.fields.count; index++) {
    if (form.fields[index].name == name) return form.fields[index];
  }
  return null;
}
