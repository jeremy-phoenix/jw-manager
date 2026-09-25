import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/screens/settings/settings_screen.dart';
import 'package:congregation_manager/ui/theme/app_theme.dart';

void main() {
  for (final (width, scale) in [(360.0, 1.5), (1280.0, 1.0)]) {
    testWidgets('appearance choices apply and persist at $width, text $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: ref.watch(themeModeProvider),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const AppearanceSettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
        final choice = find.byKey(ValueKey('theme-${mode.name}'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(container.read(themeModeProvider), mode);
        expect(prefs.getString('themeMode'), mode.name);
        if (mode != ThemeMode.system) {
          expect(
            Theme.of(tester.element(find.byType(Scaffold))).brightness,
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          );
        }
        expect(tester.takeException(), isNull);
      }
      final firstLast = find.byKey(const ValueKey('name-order-firstLast'));
      await tester.ensureVisible(firstLast);
      await tester.pumpAndSettle();
      await tester.tap(firstLast);
      await tester.pumpAndSettle();
      expect(container.read(nameOrderProvider), NameOrder.firstLast);
      expect(prefs.getString('nameOrder'), 'firstLast');
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // A fresh provider scope restores the saved choices and the hub summary.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('System theme · First name first'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('theme choices can be activated from the keyboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppearanceSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.system);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
