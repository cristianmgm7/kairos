import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:blueprint_app/core/routing/app_routes.dart';

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
    final String location = GoRouterState.of(context).matchedLocation;

    // Map routes to tab indices
    int currentIndex = _getSelectedIndex(location);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (int index) => _onItemTapped(index, context),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: 'Journal',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.journal)) return 1;
    if (location.startsWith(AppRoutes.notifications)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0; // Default to home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.journal);
        break;
      case 2:
        context.go(AppRoutes.notifications);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }
}
