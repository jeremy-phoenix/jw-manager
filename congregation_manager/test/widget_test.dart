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
import 'package:congregation_manager/ui/screens/settings/settings_screen.dart';

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
}
