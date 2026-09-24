import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';
import 'package:congregation_manager/ui/screens/reports/service_report_list_screen.dart';

void main() {
  const capture = bool.fromEnvironment('CAPTURE_ANALYSIS');
  final captureKey = GlobalKey();

  Future<ProviderContainer> openAnalysis(
    WidgetTester tester, {
    Size size = const Size(1100, 900),
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final congregation = await db
        .into(db.congregations)
        .insert(
          CongregationsCompanion.insert(name: const drift.Value('Riverside')),
        );
    for (final (id, first, last, active) in [
      (1, 'Anna', 'Rivera', true),
      (2, 'Daniel', 'Ortiz', false),
      (3, 'Ruth', 'Miller', true),
    ]) {
      await db
          .into(db.persons)
          .insert(
            PersonsCompanion.insert(
              id: drift.Value(id),
              firstName: drift.Value(first),
              lastName: drift.Value(last),
              congregationId: drift.Value(congregation),
              isActive: drift.Value(active),
            ),
          );
    }
    // Anna remained active, Daniel stopped in November, Ruth resumed in March.
    for (final (id, year, month) in [
      (1, 2026, 8),
      (2, 2026, 11),
      (3, 2025, 8),
      (3, 2026, 3),
    ]) {
      await db
          .into(db.serviceReports)
          .insert(
            ServiceReportsCompanion.insert(
              personId: id,
              year: year,
              month: month,
              sharedInMinistry: const drift.Value(true),
            ),
          );
    }
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialCongregationIdProvider.overrideWithValue(congregation),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedYearProvider.notifier).set(2026);
    container.read(selectedMonthProvider.notifier).set(8);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: capture ? 'Roboto' : null,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: brightness,
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const ServiceReportListScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Congregation Analysis'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> captureView(WidgetTester tester, String name) async {
    if (!capture) return;
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/analysis-review');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  setUpAll(() async {
    if (capture) {
      final sdk = Platform.environment['FLUTTER_ROOT']!;
      final font = FontLoader('Roboto')
        ..addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await icons.load();
    }
  });

  testWidgets('uses selected period and lets users inspect each total', (
    tester,
  ) async {
    await openAnalysis(tester);
    expect(
      find.text('Full service year · Sep 2025 – Aug 2026'),
      findsOneWidget,
    );
    expect(find.textContaining('Mar 2026 – Aug 2026'), findsOneWidget);
    expect(find.text('All Active Publishers (2)'), findsOneWidget);
    expect(find.text('Miller, Ruth'), findsOneWidget);
    await captureView(tester, 'desktop');

    await tester.tap(find.text('New Inactive Publishers'));
    await tester.pumpAndSettle();
    expect(find.text('New Inactive Publishers (2)'), findsOneWidget);
    expect(find.text('Ortiz, Daniel'), findsOneWidget);
    expect(find.text('Miller, Ruth'), findsOneWidget);

    await tester.tap(find.text('Reactivated Publishers'));
    await tester.pumpAndSettle();
    expect(find.text('Reactivated Publishers (1)'), findsOneWidget);
    expect(find.text('Miller, Ruth'), findsOneWidget);
    expect(find.text('Ortiz, Daniel'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'changing the cutoff reloads totals without changing the report list',
    (tester) async {
      final container = await openAnalysis(tester);
      await tester.tap(find.byKey(const ValueKey('analysis-month-8')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('February 2026').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Service year to date · Sep 2025 – Feb 2026'),
        findsOneWidget,
      );
      expect(find.text('All Active Publishers (1)'), findsOneWidget);
      expect(
        find.text('Select August for the full service-year totals.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reactivated Publishers'));
      await tester.pumpAndSettle();
      expect(find.text('Reactivated Publishers (0)'), findsOneWidget);
      expect(
        find.text(
          'No publishers meet this definition for the selected period.',
        ),
        findsOneWidget,
      );
      expect(container.read(selectedMonthProvider), 8);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.5]) {
    testWidgets('narrow dialog scrolls without overflow at text scale $scale', (
      tester,
    ) async {
      await openAnalysis(tester, size: const Size(390, 844), textScale: scale);
      await captureView(tester, 'mobile-$scale');
      await tester.ensureVisible(find.text('How totals are counted'));
      await tester.tap(find.text('How totals are counted'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Missing months after the first recorded ministry participation',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('How totals are counted'), findsNothing);
    });
  }

  testWidgets('dark theme keeps the analysis readable', (tester) async {
    await openAnalysis(tester, brightness: Brightness.dark);
    await captureView(tester, 'desktop-dark');
    expect(find.text('All Active Publishers (2)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
