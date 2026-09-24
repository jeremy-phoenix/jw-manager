import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int congregationId;
  late Directory outputDirectory;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    congregationId = await db.insertCongregation(
      CongregationsCompanion.insert(name: const Value('Test Congregation')),
    );
    await db.batch((batch) {
      batch.insertAll(db.persons, [
        PersonsCompanion.insert(
          id: const Value(1),
          firstName: const Value('Ann'),
          lastName: const Value('Active'),
          congregationId: Value(congregationId),
        ),
        PersonsCompanion.insert(
          id: const Value(2),
          firstName: const Value('Bob'),
          lastName: const Value('Lapsed'),
          isActive: const Value(false),
          congregationId: Value(congregationId),
        ),
        PersonsCompanion.insert(
          id: const Value(3),
          firstName: const Value('Cara'),
          lastName: const Value('Current'),
          congregationId: Value(congregationId),
        ),
      ]);
    });

    outputDirectory = await Directory.systemTemp.createTemp('s21_export_test_');
  });

  tearDown(() async {
    await db.close();
    if (await outputDirectory.exists()) {
      await outputDirectory.delete(recursive: true);
    }
  });

  Set<String> exportedNames([String subPath = '']) {
    final dir = Directory('${outputDirectory.path}/$subPath');
    if (!dir.existsSync()) return {};
    return dir
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toSet();
  }

  Future<List<String>> export({
    bool includeInactive = false,
    Set<int>? personIds,
  }) {
    return ReportService(
      db,
      congregationId: congregationId,
    ).exportPublisherRecords(
      dirPath: outputDirectory.path,
      serviceYear: 2026,
      includeInactive: includeInactive,
      personIds: personIds,
    );
  }

  test('exports only active publishers by default', () async {
    expect(await export(), isEmpty);

    expect(exportedNames(), {'Active, Ann.pdf', 'Current, Cara.pdf'});
    expect(Directory('${outputDirectory.path}/Inactive').existsSync(), isFalse);
  });

  test('includeInactive adds inactive publishers under Inactive', () async {
    expect(await export(includeInactive: true), isEmpty);

    expect(exportedNames(), {'Active, Ann.pdf', 'Current, Cara.pdf'});
    expect(exportedNames('Inactive'), {'Lapsed, Bob.pdf'});
  });

  test('personIds limits the export to the selected publishers', () async {
    expect(await export(personIds: {2, 3}), isEmpty);

    expect(exportedNames(), {'Current, Cara.pdf'});
    expect(exportedNames('Inactive'), {'Lapsed, Bob.pdf'});
  });
}
