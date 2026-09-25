import 'package:congregation_manager/ui/screens/groups/group_members_screen.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/services/publisher_record_reader.dart';
import 'package:congregation_manager/ui/screens/persons/person_edit_screen.dart';
import 'package:congregation_manager/ui/screens/import/import_persons_screen.dart';
import 'package:congregation_manager/ui/theme/app_theme.dart';

void main() {
  for (final width in [360.0, 840.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'related publisher fields and import actions fit at $width in ${dark ? "dark" : "light"} mode',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 800);
          addTearDown(tester.view.reset);
          SharedPreferences.setMockInitialValues({});
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          final id = await db.insertCongregation(
            CongregationsCompanion.insert(name: const drift.Value('Sample')),
          );
          final groupId = await db
              .into(db.fieldServiceGroups)
              .insert(
                FieldServiceGroupsCompanion.insert(
                  name: const drift.Value('Sample Group'),
                  congregationId: drift.Value(id),
                ),
              );
          await db.insertPerson(
            PersonsCompanion.insert(
              fieldServiceGroupId: drift.Value(groupId),
              congregationRole: const drift.Value(
                CongregationRole.ministerialServant,
              ),
              firstName: const drift.Value('Alexandria Catherine'),
              lastName: const drift.Value('Montgomery-Williams'),
              congregationId: drift.Value(id),
            ),
          );
          final container = ProviderContainer(
            overrides: [
              databaseProvider.overrideWithValue(db),
              initialCongregationIdProvider.overrideWithValue(id),
            ],
          );
          addTearDown(() async {
            container.dispose();
            await db.close();
          });
          Future<void> pump(Widget screen) async {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: dark ? AppTheme.dark() : AppTheme.light(),
                  home: screen,
                ),
              ),
            );
            await tester.pumpAndSettle();
          }

          await pump(const PersonEditScreen(personId: null));
          for (final (tab, label, removeTooltip) in [
            (1, 'Add Phone', 'Remove phone number'),
            (2, 'Add Contact', 'Remove emergency contact'),
            (3, 'Add Period', 'Remove pioneer period'),
          ]) {
            tester
                .widget<TabBar>(find.byType(TabBar))
                .controller!
                .animateTo(tab);
            await tester.pumpAndSettle();
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            // Removing an entry must preserve the remaining entry's input.
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            if (tab == 1) {
              final phoneField = find
                  .widgetWithText(TextFormField, 'Phone Number')
                  .last;
              await tester.ensureVisible(phoneField);
              await tester.enterText(phoneField, '555-0102');
            }
            await tester.ensureVisible(find.byTooltip(removeTooltip).first);
            await tester.tap(find.byTooltip(removeTooltip).first);
            await tester.pumpAndSettle();
            expect(find.byTooltip(removeTooltip), findsOneWidget);
            if (tab == 1) expect(find.text('555-0102'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          await pump(
            const ImportPersonsScreen(
              importedPersons: [
                ImportedPerson(
                  firstName: 'Alexandria Catherine',
                  lastName: 'Montgomery-Williams',
                ),
              ],
            ),
          );
          expect(
            find.text('Montgomery-Williams, Alexandria Catherine'),
            findsOneWidget,
          );
          expect(find.text('Exists'), findsOneWidget);
          expect(find.text('Create'), findsOneWidget);
          expect(find.text('Merge'), findsOneWidget);
          expect(find.text('Skip'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await pump(GroupMembersScreen(groupId: groupId));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
