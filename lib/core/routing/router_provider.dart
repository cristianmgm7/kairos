import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/routing/auth_redirect.dart';
import 'package:kairos/core/routing/pages/error_page.dart';
import 'package:kairos/core/routing/pages/splash_screen.dart';
import 'package:kairos/core/widgets/main_scaffold.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/auth/presentation/screens/login_screen.dart';
import 'package:kairos/features/auth/presentation/screens/register_screen.dart';
import 'package:kairos/features/home/presentation/screens/home_screen.dart';
import 'package:kairos/features/journal/presentation/screens/thread_detail_screen.dart';
import 'package:kairos/features/journal/presentation/screens/thread_list_screen.dart';
import 'package:kairos/features/profile/presentation/screens/create_profile_screen.dart';
import 'package:kairos/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:kairos/features/settings/presentation/screens/manage_data_screen.dart';
import 'package:kairos/features/settings/presentation/screens/push_notifications_screen.dart';
import 'package:kairos/features/settings/presentation/screens/settings_screen.dart';
import 'package:kairos/features/settings/presentation/screens/theme_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final currentStatus = ref.watch(userStatusProvider);

  final authState = currentStatus.authStatus;
  final hasProfile = currentStatus.hasProfile;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (authState == AuthStatus.unknown) return AppRoutes.splash;

      final location = state.matchedLocation;

      // Use helper function for redirect logic
      return authRedirectLogic(
        isAuthenticated: authState == AuthStatus.authenticated,
        hasProfile: hasProfile,
        currentLocation: location,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(title: 'getting ready'),
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

      // Thread detail route (authenticated but outside shell)
      GoRoute(
        path: '/journal/thread/:threadId',
        builder: (context, state) {
          final threadId = state.pathParameters['threadId'];
          return ThreadDetailScreen(threadId: threadId);
        },
      ),
      GoRoute(
        path: '/journal/thread',
        builder: (context, state) => const ThreadDetailScreen(),
      ),

      // Settings sub-routes (authenticated but outside shell)
      GoRoute(
        path: AppRoutes.themeSettings,
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.languageSettings,
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageData,
        builder: (context, state) => const ManageDataScreen(),
      ),
      GoRoute(
        path: AppRoutes.pushNotifications,
        builder: (context, state) => const PushNotificationsScreen(),
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
              child: ThreadListScreen(),
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
