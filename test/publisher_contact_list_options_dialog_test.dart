import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/ui/dialogs/publisher_contact_list_options_dialog.dart';

void main() {
  testWidgets('returns the inactive-publishers page-break option', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await PublisherContactListOptionsDialog.show(context);
              },
              child: const Text('Open options'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open options'));
    await tester.pumpAndSettle();

    expect(
      find.text('Start inactive publishers on a new page'),
      findsOneWidget,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(find.text('Start inactive publishers on a new page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
