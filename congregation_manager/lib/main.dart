import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/sync_providers.dart';
import 'package:congregation_manager/routing/app_router.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/theme/app_theme.dart';

SystemUiOverlayStyle _systemUiOverlayStyle(ColorScheme colorScheme) {
  final isDark = colorScheme.brightness == Brightness.dark;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: colorScheme.surfaceContainer,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: isDark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final initialCongId = prefs.getInt('currentCongregationId');
  final container = ProviderContainer(
    overrides: [initialCongregationIdProvider.overrideWithValue(initialCongId)],
  );
  container.read(syncSchedulerProvider).start();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CongregationManagerApp(),
    ),
  );
}

class CongregationManagerApp extends ConsumerWidget {
  const CongregationManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync can add congregations (e.g. a background download after joining)
    // or delete the selected one: keep a valid selection, falling back to
    // the welcome screen when none are left.
    ref.listen<AsyncValue<List<Congregation>>>(congregationsProvider, (
      _,
      next,
    ) {
      final congregations = next.value;
      final current = ref.read(currentCongregationIdProvider);
      if (congregations == null || congregations.any((c) => c.id == current)) {
        return;
      }
      final selection = ref.read(currentCongregationIdProvider.notifier);
      if (congregations.isNotEmpty) {
        selection.set(congregations.first.id);
      } else if (current != null) {
        selection.clear();
      }
    });
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Congregation Manager',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _systemUiOverlayStyle(colorScheme),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
