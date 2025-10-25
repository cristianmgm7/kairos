import 'package:blueprint_app/core/routing/app_routes.dart';
import 'package:blueprint_app/core/routing/pages/dashboard_page.dart';
import 'package:blueprint_app/core/routing/pages/error_page.dart';
import 'package:blueprint_app/core/routing/pages/login_page.dart';
import 'package:blueprint_app/core/routing/pages/onboarding_page.dart';
import 'package:blueprint_app/core/routing/pages/register_page.dart';
import 'package:blueprint_app/core/routing/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  GoRouter get router => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: AppRoutes.splash,
        debugLogDiagnostics: true,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => const OnboardingPage(),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: AppRoutes.register,
            builder: (context, state) => const RegisterPage(),
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
}
