import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/ui/screens/persons/person_list_screen.dart';
import 'package:congregation_manager/ui/screens/persons/person_edit_screen.dart';
import 'package:congregation_manager/ui/screens/congregations/congregation_edit_screen.dart';
import 'package:congregation_manager/ui/screens/groups/group_list_screen.dart';
import 'package:congregation_manager/ui/screens/groups/group_edit_screen.dart';
import 'package:congregation_manager/ui/screens/groups/group_members_screen.dart';
import 'package:congregation_manager/ui/screens/reports/service_report_list_screen.dart';
import 'package:congregation_manager/ui/screens/settings/settings_screen.dart';
import 'package:congregation_manager/ui/screens/home/home_screen.dart';
import 'package:congregation_manager/ui/screens/welcome/welcome_screen.dart';
import 'package:congregation_manager/ui/shell/app_shell.dart';

/// Listenable that notifies when the congregation selection changes.
class CongregationChangeNotifier extends ChangeNotifier {
  int? _congId;
  int? get congId => _congId;
  set congId(int? value) {
    if (_congId != value) {
      _congId = value;
      notifyListeners();
    }
  }
}

final _congChangeNotifier = CongregationChangeNotifier();

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Seed with current value — ref.listen only fires on changes, not the initial value
  _congChangeNotifier.congId = ref.read(currentCongregationIdProvider);
  ref.listen(currentCongregationIdProvider, (prev, next) {
    _congChangeNotifier.congId = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _congChangeNotifier,
    redirect: (context, state) {
      final congId = _congChangeNotifier.congId;
      final isWelcome = state.uri.path == '/welcome';
      if (congId == null) {
        return isWelcome ? null : '/welcome';
      }
      if (isWelcome) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/persons',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PersonListScreen()),
          ),
          GoRoute(
            path: '/groups',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GroupListScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ServiceReportListScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/settings/appearance',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const AppearanceSettingsScreen(),
          ),
          GoRoute(
            path: '/settings/data',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const DataManagementSettingsScreen(),
          ),
          GoRoute(
            path: '/settings/sync',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const OnlineSyncSettingsScreen(),
          ),
          GoRoute(
            path: '/settings/congregations',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const CongregationSettingsScreen(),
          ),
          GoRoute(
            path: '/settings/about',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => const AboutSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/persons/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return PersonEditScreen(personId: id);
        },
      ),
      GoRoute(
        path: '/persons/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PersonEditScreen(personId: null),
      ),
      GoRoute(
        path: '/groups/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return GroupEditScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/groups/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GroupEditScreen(groupId: null),
      ),
      GoRoute(
        path: '/groups/:id/persons',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return GroupMembersScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/congregations/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return CongregationEditScreen(congregationId: id);
        },
      ),
      GoRoute(
        path: '/congregations/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const CongregationEditScreen(congregationId: null),
      ),
    ],
  );
});
