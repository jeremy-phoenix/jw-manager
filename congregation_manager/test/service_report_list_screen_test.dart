import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';
import 'package:congregation_manager/ui/screens/reports/service_report_list_screen.dart';

void main() {
  testWidgets('editing a filtered report keeps the edit with the same report', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 700);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.now();
    final selectedYear = now.month >= 9 ? now.year + 1 : now.year;
    final selectedMonth = now.day <= 20
        ? DateTime(now.year, now.month - 1).month
        : now.month;

    final congregationId = await db
        .into(db.congregations)
        .insert(
          CongregationsCompanion.insert(
            name: const drift.Value('Test Congregation'),
          ),
        );
    final firstPersonId = await _insertPerson(
      db,
      congregationId,
      firstName: 'Alice',
      lastName: 'Alpha',
    );
    final secondPersonId = await _insertPerson(
      db,
      congregationId,
      firstName: 'Bob',
      lastName: 'Beta',
    );
    final searchedPersonId = await _insertPerson(
      db,
      congregationId,
      firstName: 'Carol',
      lastName: 'Gamma',
    );

    await _insertReport(
      db,
      personId: firstPersonId,
      year: selectedYear,
      month: selectedMonth,
      hours: 1,
    );
    await _insertReport(
      db,
      personId: secondPersonId,
      year: selectedYear,
      month: selectedMonth,
      hours: 2,
    );
    await _insertReport(
      db,
      personId: searchedPersonId,
      year: selectedYear,
      month: selectedMonth,
      hours: 3,
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialCongregationIdProvider.overrideWithValue(congregationId),
      ],
    );
    addTearDown(container.dispose);
    container.read(serviceReportSearchQueryProvider.notifier).set('Gamma');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ServiceReportListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gamma, Carol'), findsOneWidget);
    expect(find.text('Alpha, Alice'), findsNothing);

    await tester.tap(_editableTextWithValue('3'));
    await tester.enterText(_editableTextWithValue('3'), '9');
    await tester.pump();

    container.read(serviceReportSearchQueryProvider.notifier).set('');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final reports = await db.getServiceReports(
      year: selectedYear,
      month: selectedMonth,
      congregationId: congregationId,
    );
    final hoursByPerson = {
      for (final report in reports) report.personId: report.hours,
    };

    expect(hoursByPerson[firstPersonId], 1);
    expect(hoursByPerson[secondPersonId], 2);
    expect(hoursByPerson[searchedPersonId], 9);
  });

  testWidgets(
    'editing studies saves when search field is focused then cleared',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 700);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final now = DateTime.now();
      final selectedYear = now.month >= 9 ? now.year + 1 : now.year;
      final selectedMonth = now.day <= 20
          ? DateTime(now.year, now.month - 1).month
          : now.month;

      final congregationId = await db
          .into(db.congregations)
          .insert(
            CongregationsCompanion.insert(
              name: const drift.Value('Test Congregation'),
            ),
          );
      final firstPersonId = await _insertPerson(
        db,
        congregationId,
        firstName: 'Alice',
        lastName: 'Alpha',
      );
      final searchedPersonId = await _insertPerson(
        db,
        congregationId,
        firstName: 'Carol',
        lastName: 'Gamma',
      );

      await _insertReport(
        db,
        personId: firstPersonId,
        year: selectedYear,
        month: selectedMonth,
        bibleStudies: 1,
        hours: 1,
      );
      final searchedReportId = await _insertReport(
        db,
        personId: searchedPersonId,
        year: selectedYear,
        month: selectedMonth,
        bibleStudies: 3,
        hours: 3,
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialCongregationIdProvider.overrideWithValue(congregationId),
        ],
      );
      addTearDown(container.dispose);
      container.read(serviceReportSearchQueryProvider.notifier).set('Gamma');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ServiceReportListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final studiesField = _editableTextIn(
        ValueKey('service-report-$searchedReportId-studies'),
      );
      await tester.tap(studiesField);
      await tester.enterText(studiesField, '7');
      await tester.pump();

      await tester.tap(_editableTextWithValue('Gamma'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      final reports = await db.getServiceReports(
        year: selectedYear,
        month: selectedMonth,
        congregationId: congregationId,
      );
      final studiesByPerson = {
        for (final report in reports) report.personId: report.bibleStudies,
      };

      expect(studiesByPerson[firstPersonId], 1);
      expect(studiesByPerson[searchedPersonId], 7);
    },
  );

  testWidgets('editing notes saves from the service reports table', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 700);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.now();
    final selectedYear = now.month >= 9 ? now.year + 1 : now.year;
    final selectedMonth = now.day <= 20
        ? DateTime(now.year, now.month - 1).month
        : now.month;

    final congregationId = await db
        .into(db.congregations)
        .insert(
          CongregationsCompanion.insert(
            name: const drift.Value('Test Congregation'),
          ),
        );
    final searchedPersonId = await _insertPerson(
      db,
      congregationId,
      firstName: 'Carol',
      lastName: 'Gamma',
    );
    final searchedReportId = await _insertReport(
      db,
      personId: searchedPersonId,
      year: selectedYear,
      month: selectedMonth,
      hours: 3,
      note: 'Initial',
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialCongregationIdProvider.overrideWithValue(congregationId),
      ],
    );
    addTearDown(container.dispose);
    container.read(serviceReportSearchQueryProvider.notifier).set('Gamma');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ServiceReportListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final noteField = _editableTextIn(
      ValueKey('service-report-$searchedReportId-note'),
    );
    await tester.tap(noteField);
    await tester.enterText(noteField, 'Return visit requested');
    await tester.pump();

    await tester.tap(_editableTextWithValue('Gamma'));
    await tester.pumpAndSettle();

    final reports = await db.getServiceReports(
      personId: searchedPersonId,
      year: selectedYear,
      month: selectedMonth,
      congregationId: congregationId,
    );
    final report = reports.singleWhere((r) => r.id == searchedReportId);
    expect(report.note, 'Return visit requested');
  });

  testWidgets(
    'inactive publishers are hidden until enabled from more filters',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 700);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final now = DateTime.now();
      final selectedYear = now.month >= 9 ? now.year + 1 : now.year;
      final selectedMonth = now.day <= 20
          ? DateTime(now.year, now.month - 1).month
          : now.month;

      final congregationId = await db
          .into(db.congregations)
          .insert(
            CongregationsCompanion.insert(
              name: const drift.Value('Test Congregation'),
            ),
          );
      final activePersonId = await _insertPerson(
        db,
        congregationId,
        firstName: 'Alice',
        lastName: 'Alpha',
      );
      final inactivePersonId = await _insertPerson(
        db,
        congregationId,
        firstName: 'Bob',
        lastName: 'Beta',
        isActive: false,
      );
      final inactiveReportPersonId = await _insertPerson(
        db,
        congregationId,
        firstName: 'Carol',
        lastName: 'Delta',
      );

      await _insertReport(
        db,
        personId: activePersonId,
        year: selectedYear,
        month: selectedMonth,
        hours: 1,
      );
      await _insertReport(
        db,
        personId: inactivePersonId,
        year: selectedYear,
        month: selectedMonth,
        hours: 2,
      );
      await _insertReport(
        db,
        personId: inactiveReportPersonId,
        year: selectedYear,
        month: selectedMonth,
        hours: 3,
        isActive: false,
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialCongregationIdProvider.overrideWithValue(congregationId),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ServiceReportListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha, Alice'), findsOneWidget);
      expect(find.textContaining('Beta, Bob'), findsNothing);
      expect(find.textContaining('Delta, Carol'), findsNothing);
      expect(find.text('Rows: 1'), findsOneWidget);

      await tester.tap(find.byTooltip('More filters'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(PopupMenuItem<String>, 'Show inactive publishers'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha, Alice'), findsOneWidget);
      expect(find.text('Beta, Bob (Inactive)'), findsOneWidget);
      expect(find.text('Delta, Carol (Inactive)'), findsOneWidget);
      expect(find.text('Rows: 3'), findsOneWidget);
    },
  );
}

Finder _editableTextWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
  );
}

Finder _editableTextIn(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
}

Future<int> _insertPerson(
  AppDatabase db,
  int congregationId, {
  required String firstName,
  required String lastName,
  bool isActive = true,
}) {
  return db
      .into(db.persons)
      .insert(
        PersonsCompanion.insert(
          firstName: drift.Value(firstName),
          lastName: drift.Value(lastName),
          congregationId: drift.Value(congregationId),
          isActive: drift.Value(isActive),
        ),
      );
}

Future<int> _insertReport(
  AppDatabase db, {
  required int personId,
  required int year,
  required int month,
  int bibleStudies = 0,
  required double hours,
  String note = '',
  bool isActive = true,
}) {
  return db
      .into(db.serviceReports)
      .insert(
        ServiceReportsCompanion.insert(
          year: year,
          month: month,
          personId: personId,
          bibleStudies: drift.Value(bibleStudies),
          hours: drift.Value(hours),
          note: drift.Value(note),
          isActive: drift.Value(isActive),
        ),
      );
}
