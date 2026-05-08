import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/routing/app_router.dart';
import 'package:congregation_manager/providers/settings_providers.dart';

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

    return MaterialApp.router(
      title: 'Congregation Manager',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
