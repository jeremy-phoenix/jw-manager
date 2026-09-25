import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:congregation_manager/ui/theme/layout.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _destinations =
      <({IconData icon, IconData selectedIcon, String label})>[
        (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
        (
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Publishers',
        ),
        (
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          label: 'Groups',
        ),
        (
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: 'Reports',
        ),
        (
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: 'Settings',
        ),
      ];

  void _goBranch(int index) {
    // Choosing the current tab again returns it to its first page.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final selectedIndex = navigationShell.currentIndex;

    if (width >= AppBreakpoints.medium) {
      final extended = width >= AppBreakpoints.large;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              scrollable: true,
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: const SizedBox(height: AppSpacing.sm),
              selectedIndex: selectedIndex,
              onDestinationSelected: _goBranch,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      // Like Material's built-in label scaling cap, keep fixed-width navigation
      // labels on one line. Page content retains the user's full text scale.
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: width < 360 ? 1 : 1.2,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Keeps every tab's navigator alive, like go_router's indexed stack, so each
/// tab keeps its scroll position, sorting and selection. It also moves
/// keyboard focus to the visible tab, so typing never lands in a hidden one.
class ShellBranchContainer extends StatefulWidget {
  const ShellBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<ShellBranchContainer> createState() => _ShellBranchContainerState();
}

class _ShellBranchContainerState extends State<ShellBranchContainer> {
  final List<FocusScopeNode> _scopes = [];

  FocusScopeNode _scope(int index) {
    while (_scopes.length <= index) {
      _scopes.add(FocusScopeNode(debugLabel: 'Tab ${_scopes.length}'));
    }
    return _scopes[index];
  }

  @override
  void didUpdateWidget(covariant ShellBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    final scope = _scope(widget.currentIndex);
    // After the frame, so a tab opened for the first time is attached. Focus
    // returns to whatever last had it inside the tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scope.context != null) scope.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final scope in _scopes) {
      scope.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentIndex,
      children: [
        for (final (index, child) in widget.children.indexed)
          Offstage(
            offstage: index != widget.currentIndex,
            child: TickerMode(
              enabled: index == widget.currentIndex,
              child: ExcludeFocus(
                excluding: index != widget.currentIndex,
                child: FocusScope(node: _scope(index), child: child),
              ),
            ),
          ),
      ],
    );
  }
}
