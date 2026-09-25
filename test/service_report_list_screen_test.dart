import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
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

    final period = defaultServiceReportPeriod();
    final selectedYear = period.serviceYear;
    final selectedMonth = period.month;

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

      final period = defaultServiceReportPeriod();
      final selectedYear = period.serviceYear;
      final selectedMonth = period.month;

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

    final period = defaultServiceReportPeriod();
    final selectedYear = period.serviceYear;
    final selectedMonth = period.month;

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

      final period = defaultServiceReportPeriod();
      final selectedYear = period.serviceYear;
      final selectedMonth = period.month;

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

  testWidgets('shows a read-only pioneer indicator and links to the person', (
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

    final period = defaultServiceReportPeriod();
    final selectedYear = period.serviceYear;
    final selectedMonth = period.month;
    final congregationId = await db
        .into(db.congregations)
        .insert(
          CongregationsCompanion.insert(
            name: const drift.Value('Test Congregation'),
          ),
        );
    final personId = await _insertPerson(
      db,
      congregationId,
      firstName: 'Sally',
      lastName: 'Special',
      pioneerType: PioneerType.specialPioneer,
    );
    final reportId = await _insertReport(
      db,
      personId: personId,
      year: selectedYear,
      month: selectedMonth,
      hours: 20,
      isAuxiliaryPioneer: true,
    );
    final publisherId = await _insertPerson(
      db,
      congregationId,
      firstName: 'Paul',
      lastName: 'Publisher',
    );
    await _insertReport(
      db,
      personId: publisherId,
      year: selectedYear,
      month: selectedMonth,
      hours: 0,
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialCongregationIdProvider.overrideWithValue(congregationId),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/reports',
      routes: [
        GoRoute(
          path: '/reports',
          builder: (_, _) => const ServiceReportListScreen(),
        ),
        GoRoute(
          path: '/persons/edit/:id',
          builder: (_, state) => Scaffold(
            body: Text('Person record ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SP'), findsOneWidget);
    expect(find.text('Pub'), findsNothing);
    expect(find.byType(PopupMenuButton<PioneerType>), findsNothing);
    final auxCheckbox = find.descendant(
      of: find.byKey(ValueKey('service-report-$reportId-auxiliary')),
      matching: find.byType(Checkbox),
    );
    expect(tester.widget<Checkbox>(auxCheckbox).value, isTrue);

    final person = await db.getPerson(personId);
    final report = (await db.getServiceReports(personId: personId)).single;
    expect(person.pioneerType, PioneerType.specialPioneer);
    expect(report.isAuxiliaryPioneer, isTrue);
    expect(find.text('SP'), findsOneWidget);
    expect(tester.widget<Checkbox>(auxCheckbox).value, isTrue);

    await tester.tap(find.byTooltip("Month's Statistics"));
    await tester.pumpAndSettle();
    expect(find.text('Auxiliary Pioneers'), findsOneWidget);
    expect(find.text('Regular Pioneers'), findsOneWidget);
    expect(find.text('Special Pioneers'), findsOneWidget);
    expect(find.text('Field Missionaries'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Special, Sally'));
    await tester.pumpAndSettle();
    expect(find.text('Person record $personId'), findsOneWidget);
  });
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
  PioneerType pioneerType = PioneerType.none,
}) {
  return db
      .into(db.persons)
      .insert(
        PersonsCompanion.insert(
          firstName: drift.Value(firstName),
          lastName: drift.Value(lastName),
          congregationId: drift.Value(congregationId),
          isActive: drift.Value(isActive),
          pioneerType: drift.Value(pioneerType),
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
  bool isAuxiliaryPioneer = false,
}) {
  return db
      .into(db.serviceReports)
      .insert(
        ServiceReportsCompanion.insert(
          year: year,
          month: month,
          personId: personId,
          isAuxiliaryPioneer: drift.Value(isAuxiliaryPioneer),
          bibleStudies: drift.Value(bibleStudies),
          hours: drift.Value(hours),
          note: drift.Value(note),
          isActive: drift.Value(isActive),
        ),
      );
}
