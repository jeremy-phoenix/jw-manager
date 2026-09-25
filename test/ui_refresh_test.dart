import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/main.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';
import 'package:congregation_manager/routing/app_router.dart';
import 'package:congregation_manager/ui/widgets/search_text_field.dart';

Future<void> command(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  Future<(ProviderContainer, AppDatabase)> setup(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Congregation Manager',
      packageName: 'test',
      version: '1.0.1',
      buildNumber: '2',
      buildSignature: '',
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.reset);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final cong = await db.insertCongregation(
      CongregationsCompanion.insert(name: const drift.Value('Test')),
    );
    for (final name in ['Alice', 'Bob', 'Carol']) {
      await db.insertPerson(
        PersonsCompanion.insert(
          firstName: drift.Value(name),
          lastName: const drift.Value('Publisher'),
          congregationId: drift.Value(cong),
        ),
      );
    }
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialCongregationIdProvider.overrideWithValue(cong),
      ],
    );
    addTearDown(() async {
      container.read(appRouterProvider).dispose();
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CongregationManagerApp(),
      ),
    );
    await tester.pumpAndSettle();
    return (container, db);
  }

  testWidgets(
    'tab switching preserves selection and directs shortcuts to the active tab',
    (tester) async {
      final (container, _) = await setup(tester);
      final router = container.read(appRouterProvider);
      router.go('/persons');
      await tester.pumpAndSettle();
      await command(tester, LogicalKeyboardKey.keyA);
      expect(find.text('3 selected'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Groups'),
        ),
      );
      await tester.pumpAndSettle();
      await command(tester, LogicalKeyboardKey.keyF);
      final groupSearch = tester.widget<TextField>(
        find.descendant(
          of: find.byType(SearchTextField),
          matching: find.byType(TextField),
        ),
      );
      expect(groupSearch.focusNode!.hasFocus, isTrue);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Publishers'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 selected'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('3 selected'), findsNothing);
      await command(tester, LogicalKeyboardKey.keyF);
      final search = find.descendant(
        of: find.byType(SearchTextField),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'Publisher');
      await command(tester, LogicalKeyboardKey.keyA);
      expect(
        tester.widget<TextField>(search).controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 9),
      );
      expect(find.text('3 selected'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Enter saves a report cell and focuses the same column in the next visible row',
    (tester) async {
      final (container, db) = await setup(tester);
      final year = container.read(selectedYearProvider);
      final month = container.read(selectedMonthProvider);
      final reports = await db.getOrCreateReportsForPeriod(
        year,
        month,
        congregationId: container.read(currentCongregationIdProvider),
      );
      container.read(appRouterProvider).go('/reports');
      await tester.pumpAndSettle();
      Finder field(int id) => find.descendant(
        of: find.byKey(ValueKey('service-report-$id-studies')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field(reports[0].id), '7');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field(reports[1].id)).focusNode!.hasFocus,
        isTrue,
      );
      final saved = await db.getServiceReports(personId: reports[0].personId);
      expect(saved.single.bibleStudies, 7);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Ctrl+S saves the publisher form and About displays package metadata',
    (tester) async {
      final (container, db) = await setup(tester);
      final router = container.read(appRouterProvider);
      router.push('/persons/new');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First Name'),
        'Diana',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last Name'),
        'Delta',
      );
      await command(tester, LogicalKeyboardKey.keyS);
      expect(
        (await db.getAllPersons()).any((person) => person.firstName == 'Diana'),
        isTrue,
      );
      router.go('/settings/about');
      await tester.pumpAndSettle();
      expect(find.text('Version 1.0.1 (2)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
