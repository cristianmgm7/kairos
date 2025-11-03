import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/routing/auth_redirect.dart';
import 'package:kairos/core/routing/pages/error_page.dart';
import 'package:kairos/core/routing/pages/loading_page.dart';
import 'package:kairos/core/widgets/main_scaffold.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/auth/presentation/screens/login_screen.dart';
import 'package:kairos/features/auth/presentation/screens/register_screen.dart';
import 'package:kairos/features/home/presentation/screens/home_screen.dart';
import 'package:kairos/features/journal/presentation/screens/journal_screen.dart';
import 'package:kairos/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/features/profile/presentation/screens/create_profile_screen.dart';
import 'package:kairos/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasProfile = ref.watch(hasCompletedProfileProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Show loading screen while auth state is loading
      if (authState.isLoading || !authState.hasValue) {
        // If already on a loading route, don't redirect
        if (state.matchedLocation == AppRoutes.splash) {
          return null;
        }
        return AppRoutes.splash;
      }

      final isAuthenticated = authState.valueOrNull != null;
      final location = state.matchedLocation;

      // Use helper function for redirect logic
      return authRedirectLogic(
        isAuthenticated: isAuthenticated,
        hasProfile: hasProfile,
        currentLocation: location,
      );
    },
    routes: [
      // Loading/splash route
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const LoadingPage(),
      ),

      // Public routes (outside shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Profile creation (authenticated but outside shell)
      GoRoute(
        path: AppRoutes.createProfile,
        builder: (context, state) => const CreateProfileScreen(),
      ),

      // Shell route (persistent bottom navigation for all main app routes)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.journal,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(
      error: state.error?.toString(),
    ),
  );
});
