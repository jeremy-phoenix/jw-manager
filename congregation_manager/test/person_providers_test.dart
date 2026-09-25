import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/ui/screens/persons/person_list_screen.dart';

void main() {
  testWidgets('publisher list shows inactive publishers until disabled', (
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
    final congregationId = await _insertCongregation(db);
    await _insertPerson(
      db,
      congregationId,
      firstName: 'Alice',
      lastName: 'Zephyr',
    );
    await _insertPerson(
      db,
      congregationId,
      firstName: 'Ian',
      lastName: 'Dormant',
      isActive: false,
    );
    final container = _containerFor(db, congregationId);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PersonListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Publishers'), findsOneWidget);
    expect(find.text('Zephyr'), findsOneWidget);
    expect(find.text('Dormant'), findsOneWidget);
    expect(find.text('Rows: 2'), findsOneWidget);
    expect(find.text('Active: 1'), findsOneWidget);
    expect(find.text('Inactive: 1'), findsOneWidget);

    await tester.tap(find.byTooltip('More filters'));
    await tester.pumpAndSettle();
    expect(find.text('Filter and Sort Publishers'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('person-list-include-inactive')))
          .width,
      tester
          .getSize(find.byKey(const ValueKey('person-list-options-content')))
          .width,
    );
    await tester.tap(find.byType(Switch).first);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Zephyr'), findsOneWidget);
    expect(find.text('Dormant'), findsNothing);
    expect(find.text('Rows: 1'), findsOneWidget);
    expect(find.text('Inactive: 0'), findsOneWidget);
  });

  testWidgets('publisher list search matches other names', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 700);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final congregationId = await _insertCongregation(db);
    await _insertPerson(
      db,
      congregationId,
      firstName: 'Alice',
      lastName: 'Anderson',
    );
    await _insertPerson(
      db,
      congregationId,
      firstName: 'James',
      lastName: 'Smith',
      otherNames: 'Jimmy',
    );
    final container = _containerFor(db, congregationId);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PersonListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'jimmy');
    await tester.pumpAndSettle();

    expect(find.text('Anderson'), findsNothing);
    expect(find.text('Smith'), findsOneWidget);
    expect(find.text('Jimmy'), findsOneWidget);
    expect(find.text('Rows: 1'), findsOneWidget);
  });

  testWidgets('selected publisher can be archived with a reason and date', (
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
    final congregationId = await _insertCongregation(db);
    final personId = await _insertPerson(
      db,
      congregationId,
      firstName: 'Alice',
      lastName: 'Archive',
    );
    final container = _containerFor(db, congregationId);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PersonListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Archive Publishers'), findsOneWidget);
    expect(find.text('Transferred out'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Archive'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Archive'), findsNothing);
    expect(find.text('No publishers'), findsOneWidget);
    final person = await db.getPerson(personId);
    expect(person.recordStatus, PersonRecordStatus.archived);
    expect(person.archiveReason, PersonArchiveReason.transferredOut);
    expect(person.archivedAt, isNotNull);
  });

  testWidgets('persons can be filtered and sorted by baptism date', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final congregationId = await _insertCongregation(db);
    await _insertPerson(
      db,
      congregationId,
      firstName: 'Mia',
      lastName: 'Missing',
    );
    await _insertPerson(
      db,
      congregationId,
      firstName: 'Lena',
      lastName: 'Later',
      baptismDate: DateTime(2018, 6, 2),
    );
    await _insertPerson(
      db,
      congregationId,
      firstName: 'Eli',
      lastName: 'Early',
      baptismDate: DateTime(2005, 1, 15),
    );
    final container = _containerFor(db, congregationId);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PersonListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More filters'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<BaptismDateFilter>, 'Any'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Date recorded').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<PersonSortField>, 'Name'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baptism Date').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Missing'), findsNothing);
    expect(find.text('Early'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Early')).dy,
      lessThan(tester.getTopLeft(find.text('Later')).dy),
    );

    await tester.tap(find.byTooltip('More filters'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        DropdownButtonFormField<BaptismDateFilter>,
        'Date recorded',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Date missing').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Missing'), findsOneWidget);
    expect(find.text('Early'), findsNothing);
    expect(find.text('Later'), findsNothing);
  });

  testWidgets('persons table checkboxes use dark theme colors', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 700);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final congregationId = await _insertCongregation(db);
    await _insertPerson(
      db,
      congregationId,
      firstName: 'Dara',
      lastName: 'Dark',
    );
    final container = _containerFor(db, congregationId);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const PersonListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final checkbox = find.byType(Checkbox).last;
    final checkboxContext = tester.element(checkbox);
    final checkboxTheme = CheckboxTheme.of(checkboxContext);
    final colors = Theme.of(
      tester.element(find.byType(PersonListScreen)),
    ).colorScheme;
    expect(
      checkboxTheme.fillColor?.resolve({}),
      colors.surfaceContainerHighest,
    );
    expect(
      checkboxTheme.fillColor?.resolve({WidgetState.selected}),
      colors.primary,
    );

    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
  });
}

ProviderContainer _containerFor(AppDatabase db, int congregationId) {
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      initialCongregationIdProvider.overrideWithValue(congregationId),
    ],
  );
}

Future<int> _insertCongregation(AppDatabase db) {
  return db
      .into(db.congregations)
      .insert(
        CongregationsCompanion.insert(
          name: const drift.Value('Test Congregation'),
        ),
      );
}

Future<int> _insertPerson(
  AppDatabase db,
  int congregationId, {
  required String firstName,
  required String lastName,
  String otherNames = '',
  bool isActive = true,
  DateTime? baptismDate,
}) {
  return db
      .into(db.persons)
      .insert(
        PersonsCompanion.insert(
          firstName: drift.Value(firstName),
          lastName: drift.Value(lastName),
          otherNames: drift.Value(otherNames),
          congregationId: drift.Value(congregationId),
          isActive: drift.Value(isActive),
          baptismDate: drift.Value(baptismDate),
        ),
      );
}
