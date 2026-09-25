import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/ui/screens/groups/group_list_screen.dart';

void main() {
  testWidgets('group list includes persons without a group', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 700);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final congregationId = await db
        .into(db.congregations)
        .insert(
          CongregationsCompanion.insert(
            name: const drift.Value('Test Congregation'),
          ),
        );
    await db
        .into(db.persons)
        .insert(
          PersonsCompanion.insert(
            firstName: const drift.Value('Uma'),
            lastName: const drift.Value('Unassigned'),
            congregationId: drift.Value(congregationId),
          ),
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
        child: const MaterialApp(home: GroupListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unassigned Publishers'), findsOneWidget);
    expect(find.text('1 publisher is not assigned.'), findsOneWidget);

    await tester.tap(find.text('Unassigned Publishers'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(
        of: dialog,
        matching: find.text('Unassigned Publishers (1)'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Unassigned, Uma')),
      findsOneWidget,
    );
  });
}
