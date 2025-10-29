import 'package:blueprint_app/core/routing/app_routes.dart';
import 'package:blueprint_app/core/routing/pages/dashboard_page.dart';
import 'package:blueprint_app/core/routing/pages/error_page.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:blueprint_app/features/auth/presentation/screens/login_screen.dart';
import 'package:blueprint_app/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // If still loading auth state, don't redirect
      if (authState.isLoading || !authState.hasValue) {
        return null;
      }

      final isAuthenticated = authState.valueOrNull != null;

      // Public routes (no auth required)
      final publicRoutes = [
        AppRoutes.login,
        AppRoutes.register,
      ];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      // If authenticated and trying to access login/register
      if (isAuthenticated &&
          (state.matchedLocation == AppRoutes.login ||
              state.matchedLocation == AppRoutes.register)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(
      error: state.error?.toString(),
    ),
  );
});
