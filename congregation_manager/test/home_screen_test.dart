import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/ui/screens/home/home_screen.dart';

void main() {
  testWidgets(
    'dashboard shows summaries and quick actions on a compact screen',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 900);
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
              name: const drift.Value('Riverside Congregation'),
            ),
          );
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              firstName: const drift.Value('Rita'),
              lastName: const drift.Value('Regular'),
              pioneerType: const drift.Value(PioneerType.regularPioneer),
              congregationId: drift.Value(congregationId),
            ),
          );
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              firstName: const drift.Value('Ian'),
              lastName: const drift.Value('Inactive'),
              isActive: const drift.Value(false),
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
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Congregation Persons'), findsOneWidget);
      expect(find.text('Pioneers'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Add Person'), findsOneWidget);
      expect(find.text('Service Reports'), findsOneWidget);
      expect(find.text('Manage Groups'), findsOneWidget);
      expect(find.text('Baptism Date Overview'), findsOneWidget);
    },
  );
}
