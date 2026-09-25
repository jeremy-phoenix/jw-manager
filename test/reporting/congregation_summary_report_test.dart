import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/reporting/congregation_summary_report.dart';
import 'package:congregation_manager/reporting/report_service.dart';
import 'package:congregation_manager/services/export_progress.dart';

void main() {
  test(
    'summary export uses the same period and overlapping categories',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      for (final (id, name, active) in [
        (1, 'Resumed', true),
        (2, 'Stopped', false),
      ]) {
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                id: Value(id),
                firstName: Value(name),
                isActive: Value(active),
              ),
            );
        await db
            .into(db.serviceReports)
            .insert(
              ServiceReportsCompanion.insert(
                personId: id,
                year: 2025,
                month: 8,
                sharedInMinistry: const Value(true),
              ),
            );
      }
      await db
          .into(db.serviceReports)
          .insert(
            ServiceReportsCompanion.insert(
              personId: 1,
              year: 2026,
              month: 3,
              sharedInMinistry: const Value(true),
            ),
          );
      final document = await ReportService(
        db,
      ).buildCongregationSummary(serviceYear: 2026);
      final pdf = sf.PdfDocument(inputBytes: await document.save());
      addTearDown(pdf.dispose);
      final text = sf.PdfTextExtractor(
        pdf,
      ).extractText().replaceAll(RegExp(r'\s+'), ' ');
      expect(text, contains('Service year 2026: September 2025 - August 2026'));
      final active = text
          .split('All Active Publishers')[1]
          .split('New Inactive Publishers')[0];
      final inactive = text
          .split('New Inactive Publishers')[1]
          .split('Reactivated Publishers')[0];
      final reactivated = text.split('Reactivated Publishers')[1];
      expect(active, contains('1 record(s)'));
      expect(active, contains('Resumed'));
      expect(inactive, contains('2 record(s)'));
      expect(inactive, contains('Stopped'));
      expect(inactive, contains('Resumed'));
      expect(reactivated, contains('1 record(s)'));
      expect(reactivated, contains('Resumed'));
    },
  );

  test('large congregation summary can span multiple pages', () async {
    final now = DateTime(2026, 8, 24);
    final people = List.generate(
      200,
      (index) => Person(
        id: index + 1,
        firstName: 'Publisher',
        lastName: 'Number ${index + 1}',
        otherNames: '',
        birthDate: null,
        baptismDate: DateTime(2000, 1, 1),
        gender: Gender.unknown,
        hopeClass: HopeClass.unknown,
        congregationRole: CongregationRole.none,
        pioneerType: PioneerType.none,
        address: '',
        email: '',
        isActive: true,
        recordStatus: PersonRecordStatus.current,
        congregationId: 1,
        fieldServiceGroupId: null,
        serverVersion: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final document = generateCongregationSummaryReport(
      allActive: people,
      newInactive: const [],
      reactivated: const [],
    );

    expect(await document.save(), isNotEmpty);
  });

  test(
    'export all completes the final report for a large congregation',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final congregationId = await db.insertCongregation(
        CongregationsCompanion.insert(name: const Value('Large Congregation')),
      );
      await db.batch((batch) {
        batch.insertAll(
          db.persons,
          List.generate(
            200,
            (index) => PersonsCompanion.insert(
              id: Value(index + 1),
              firstName: const Value('Publisher'),
              lastName: Value('Number ${index + 1}'),
              congregationId: Value(congregationId),
            ),
          ),
        );
        batch.insertAll(
          db.serviceReports,
          List.generate(
            200,
            (index) => ServiceReportsCompanion.insert(
              year: 2026,
              month: 8,
              personId: index + 1,
              sharedInMinistry: const Value(true),
            ),
          ),
        );
      });

      final outputDirectory = await Directory.systemTemp.createTemp(
        'congregation_manager_reports_',
      );
      addTearDown(() async {
        if (await outputDirectory.exists()) {
          await outputDirectory.delete(recursive: true);
        }
      });

      final progress = <ExportProgress>[];
      await ReportService(
        db,
        congregationId: congregationId,
      ).exportAllReports(outputDirectory.path, onProgress: progress.add);

      final exportedNames = outputDirectory
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toSet();
      expect(exportedNames, {
        'Publisher_Directory.pdf',
        'Publisher_List.pdf',
        'Publisher_Contact_List.pdf',
        'Emergency_Contact_List.pdf',
        'Congregation_Summary_All_Categories.pdf',
      });
      expect(progress.last.current, 5);
      expect(progress.last.message, 'Export complete');
    },
  );
}
