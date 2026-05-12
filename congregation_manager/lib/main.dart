import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/routing/app_router.dart';
import 'package:congregation_manager/providers/settings_providers.dart';

ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: brightness,
  );
  final navigationBarColor = colorScheme.surfaceContainerHigh;

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      elevation: 3,
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navigationBarColor,
      elevation: 2,
    ),
  );
}

SystemUiOverlayStyle _systemUiOverlayStyle(ColorScheme colorScheme) {
  final isDark = colorScheme.brightness == Brightness.dark;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: colorScheme.surfaceContainerHigh,
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
  runApp(
    ProviderScope(
      overrides: [
        initialCongregationIdProvider.overrideWithValue(initialCongId),
      ],
      child: const CongregationManagerApp(),
    ),
  );
}

class CongregationManagerApp extends ConsumerWidget {
  const CongregationManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    final lightTheme = _buildTheme(Brightness.light);
    final darkTheme = _buildTheme(Brightness.dark);

    return MaterialApp.router(
      title: 'Congregation Manager',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
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
