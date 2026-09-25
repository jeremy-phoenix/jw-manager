import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/ui/dialogs/export_records_dialog.dart';

void main() {
  late ExportRecordsOptions? options;

  Future<void> openDialog(WidgetTester tester, {int? selectionCount}) async {
    options = null;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                options = await ExportRecordsDialog.show(
                  context,
                  selectionCount: selectionCount,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('excludes inactive publishers by default', (tester) async {
    await openDialog(tester);

    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Include inactive publishers'),
    );
    expect(tile.value, isFalse);

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(options?.includeInactive, isFalse);
  });

  testWidgets('returns includeInactive when the option is checked', (
    tester,
  ) async {
    await openDialog(tester);

    final tile = find.widgetWithText(
      CheckboxListTile,
      'Include inactive publishers',
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(options?.includeInactive, isTrue);
  });

  testWidgets('selection mode shows the count and hides the inactive option', (
    tester,
  ) async {
    await openDialog(tester, selectionCount: 3);

    expect(find.text('Exporting 3 selected publisher(s).'), findsOneWidget);
    expect(find.text('Include inactive publishers'), findsNothing);
  });
}
