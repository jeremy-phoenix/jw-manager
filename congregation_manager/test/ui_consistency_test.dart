import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';
import 'package:congregation_manager/routing/app_router.dart';
import 'package:congregation_manager/ui/theme/app_theme.dart';
import 'package:congregation_manager/ui/dialogs/congregation_analysis_dialog.dart';
import 'package:congregation_manager/ui/dialogs/export_records_dialog.dart';
import 'package:congregation_manager/ui/dialogs/publisher_contact_list_options_dialog.dart';
import 'package:congregation_manager/ui/screens/import/import_persons_screen.dart';
import 'package:congregation_manager/ui/screens/import/csv_sync_preview_screen.dart';
import 'package:congregation_manager/ui/screens/welcome/welcome_screen.dart';
import 'package:congregation_manager/services/publisher_record_reader.dart';
import 'package:congregation_manager/ui/screens/settings/sync/sync_setup_dialogs.dart';
import 'package:congregation_manager/ui/screens/settings/sync/sync_manage_dialogs.dart';
import 'package:congregation_manager/ui/screens/settings/sync/recovery_code_dialog.dart';

// Optional local visual review: --dart-define=UI_CAPTURE=true. Images use
// disposable sample records, never the application's database.
const _capture = bool.fromEnvironment('UI_CAPTURE');

void main() {
  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(600, 800), 1.0),
    (const Size(1280, 800), 1.0),
    (const Size(360, 800), 1.5),
    (const Size(840, 320), 1.0),
    (const Size(320, 740), 1.0),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('screens fit at $size, text $scale, dark $dark', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
        PackageInfo.setMockInitialValues(
          appName: 'Congregation Manager',
          packageName: 'test',
          version: '1.0.1',
          buildNumber: '2',
          buildSignature: '',
        );
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final congregation = await db.insertCongregation(
          CongregationsCompanion.insert(
            name: const drift.Value('Riverside Congregation'),
          ),
        );
        final person = await db.insertPerson(
          PersonsCompanion.insert(
            congregationId: drift.Value(congregation),
            firstName: const drift.Value('Alexandria Catherine'),
            lastName: const drift.Value('Montgomery-Williams'),
          ),
        );
        final group = await db
            .into(db.fieldServiceGroups)
            .insert(
              FieldServiceGroupsCompanion.insert(
                name: const drift.Value('Riverside North Field Service Group'),
                congregationId: drift.Value(congregation),
                groupOverseerId: drift.Value(person),
                assistantId: drift.Value(person),
              ),
            );
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            initialCongregationIdProvider.overrideWithValue(congregation),
          ],
        );
        await (db.update(db.persons)..where((p) => p.id.equals(person))).write(
          PersonsCompanion(fieldServiceGroupId: drift.Value(group)),
        );
        final router = container.read(appRouterProvider);
        addTearDown(() async {
          router.dispose();
          container.dispose();
          await db.close();
        });
        await db.getOrCreateReportsForPeriod(
          container.read(selectedYearProvider),
          container.read(selectedMonthProvider),
          congregationId: congregation,
        );
        final boundaryKey = GlobalKey();
        var theme = dark ? AppTheme.dark() : AppTheme.light();
        if (_capture && Platform.isWindows) {
          await tester.runAsync(() async {
            final loader = FontLoader('ReviewFont')
              ..addFont(
                File(
                  'C:/Windows/Fonts/segoeui.ttf',
                ).readAsBytes().then(ByteData.sublistView),
              );
            await loader.load();
            await (FontLoader('MaterialIcons')
                  ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
                .load();
          });
          final originalTheme = theme;
          theme = theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: 'ReviewFont'),
            primaryTextTheme: theme.primaryTextTheme.apply(
              fontFamily: 'ReviewFont',
            ),
            appBarTheme: theme.appBarTheme.copyWith(
              titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                fontFamily: 'ReviewFont',
              ),
            ),
            navigationBarTheme: theme.navigationBarTheme.copyWith(
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => originalTheme.navigationBarTheme.labelTextStyle
                    ?.resolve(states)
                    ?.copyWith(fontFamily: 'ReviewFont'),
              ),
            ),
            navigationRailTheme: theme.navigationRailTheme.copyWith(
              selectedLabelTextStyle: theme
                  .navigationRailTheme
                  .selectedLabelTextStyle
                  ?.copyWith(fontFamily: 'ReviewFont'),
              unselectedLabelTextStyle: theme
                  .navigationRailTheme
                  .unselectedLabelTextStyle
                  ?.copyWith(fontFamily: 'ReviewFont'),
            ),
            dataTableTheme: theme.dataTableTheme.copyWith(
              headingTextStyle: theme.dataTableTheme.headingTextStyle?.copyWith(
                fontFamily: 'ReviewFont',
              ),
            ),
          );
        }
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: boundaryKey,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: theme,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          ),
        );
        final failures = <String>[];
        Future<void> review(String name) async {
          await tester.pumpAndSettle();
          final exception = tester.takeException();
          if (exception != null) failures.add('$name: $exception');
          if (!_capture) return;
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/ui-review/${size.width.toInt()}-${size.height.toInt()}-$scale-${dark ? "dark" : "light"}${name.replaceAll('/', '_')}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        for (final route in [
          '/home',
          '/persons',
          '/groups',
          '/reports',
          '/settings',
          '/settings/appearance',
          '/settings/data',
          '/settings/sync',
          '/settings/congregations',
          '/settings/about',
          '/persons/archive',
          '/persons/trash',
          '/persons/edit/$person',
          '/groups/edit/$group',
          '/groups/$group/persons',
          '/congregations/edit/$congregation',
        ]) {
          debugPrint('Reviewing $route');
          await tester.runAsync(() async {
            router.go(route);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });
          await review(route);
          if (route == '/persons/edit/$person') {
            tester.widget<TabBar>(find.byType(TabBar)).controller!.animateTo(4);
            await review('/publisher-reports');
          }
          if (route == '/reports') {
            for (final tooltip in [
              "Month's Statistics",
              'Generate Reports for Period',
            ]) {
              await tester.tap(find.byTooltip(tooltip));
              await review('/dialog-$tooltip');
              router.routerDelegate.navigatorKey.currentState!.pop();
              await tester.pumpAndSettle();
            }
            await tester.tap(find.byTooltip('More actions'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Delete Reports...'));
            await review('/dialog-delete-reports');
            router.routerDelegate.navigatorKey.currentState!.pop();
            await tester.pumpAndSettle();
          }
        }
        final csv = File('build/ui-review/sample-import.csv');
        await tester.runAsync(() async {
          await csv.parent.create(recursive: true);
          await csv.writeAsString(
            'Sample congregation\nPublishers\nNumber,Name,Address,Phone\n1,"Montgomery-Williams, Alexandria Catherine","123 Riverside Avenue",555-0102\n',
          );
        });
        for (final (name, screen) in [
          ('welcome', const WelcomeScreen()),
          ('csv-import', CsvSyncPreviewScreen(csvFilePath: csv.path)),
          (
            'import',
            const ImportPersonsScreen(
              importedPersons: [
                ImportedPerson(
                  firstName: 'Alexandria Catherine',
                  lastName: 'Montgomery-Williams',
                ),
              ],
            ),
          ),
        ]) {
          router.routerDelegate.navigatorKey.currentState!.push(
            MaterialPageRoute<void>(builder: (_) => screen),
          );
          await review('/$name');
          router.routerDelegate.navigatorKey.currentState!.pop();
          await tester.pumpAndSettle();
        }
        final dialogs = <String, void Function(BuildContext)>{
          'export': (context) {
            ExportRecordsDialog.show(context);
          },
          'contact': (context) {
            PublisherContactListOptionsDialog.show(context);
          },
          'analysis': (context) {
            showDialog<void>(
              context: context,
              builder: (_) => CongregationAnalysisDialog(
                serviceYear: container.read(selectedYearProvider),
                throughMonth: container.read(selectedMonthProvider),
              ),
            );
          },
          'create-vault': (context) {
            showCreateVaultDialog(context);
          },
          'join-vault': (context) {
            showJoinWithInviteDialog(context);
          },
          'recover-vault': (context) {
            showRecoverWithCodeDialog(context);
          },
          'invite': showInviteDeviceDialog,
          'rotate-key': (context) {
            showRotateKeyDialog(context, serverUrl: 'https://example.test');
          },
          'unlock': showUnlockDialog,
          'delete-vault': showDeleteVaultDialog,
          'recovery-code': (context) {
            showRecoveryCodeDialog(
              context,
              code: 'SAMPLE-CODE-FOR-LAYOUT-REVIEW-ONLY',
              serverUrl: 'https://example.test',
            );
          },
        };
        for (final entry in dialogs.entries) {
          debugPrint('Reviewing dialog ${entry.key}');
          entry.value(router.routerDelegate.navigatorKey.currentContext!);
          await review('/dialog-${entry.key}');
          router.routerDelegate.navigatorKey.currentState!.pop();
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  }
}
