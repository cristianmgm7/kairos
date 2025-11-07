import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// MainScaffold provides a persistent bottom navigation bar for the main app.
/// This widget wraps all tab screens via GoRouter's ShellRoute.
///
/// TODO: If you need nested navigation within tabs (e.g., deep stacks per tab),
/// consider using StatefulShellRoute and passing navigatorKeys to each tab's Navigator.
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _MainBottomNavigationBar(),
    );
  }
}

class _MainBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).matchedLocation;

    // Map routes to tab indices
    final currentIndex = _getSelectedIndex(location);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (int index) => _onItemTapped(index, context),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.book_outlined),
          selectedIcon: const Icon(Icons.book),
          label: l10n.journal,
        ),
        NavigationDestination(
          icon: const Icon(Icons.notifications_outlined),
          selectedIcon: const Icon(Icons.notifications),
          label: l10n.notifications,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settings,
        ),
      ],
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.journal)) return 1;
    if (location.startsWith(AppRoutes.notifications)) return 2;
    if (location.startsWith(AppRoutes.settings)) return 3;
    return 0; // Default to home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.journal);
      case 2:
        context.go(AppRoutes.notifications);
      case 3:
        context.go(AppRoutes.settings);
    }
  }
}
