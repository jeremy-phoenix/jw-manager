// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:congregation_manager/main.dart';
import 'package:congregation_manager/ui/dialogs/export_records_dialog.dart';
import 'package:congregation_manager/ui/screens/settings/settings_screen.dart';
import 'package:congregation_manager/ui/widgets/search_text_field.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CongregationManagerApp()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Congregation Manager'), findsOneWidget);
  });

  testWidgets('Settings hub renders without loading async sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );

    expect(find.text('Congregations'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Search field clear button clears visible text', (
    WidgetTester tester,
  ) async {
    var query = 'smith';
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SearchTextField(
              query: query,
              hintText: 'Search...',
              onChanged: (value) => setState(() => query = value),
              onClear: () => setState(() {
                cleared = true;
                query = '';
              }),
            ),
          ),
        ),
      ),
    );

    EditableText editableText() => tester.widget(find.byType(EditableText));

    expect(editableText().controller.text, 'smith');

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(cleared, isTrue);
    expect(editableText().controller.text, isEmpty);
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets('Export records dialog scrolls on short screens', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => ExportRecordsDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Export Publisher Records'), findsOneWidget);
  });
}
