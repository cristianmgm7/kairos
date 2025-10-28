import 'package:blueprint_app/core/routing/app_routes.dart';
import 'package:blueprint_app/core/routing/pages/dashboard_page.dart';
import 'package:blueprint_app/core/routing/pages/error_page.dart';
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
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
        ],
        errorBuilder: (context, state) => ErrorPage(
          error: state.error?.toString(),
        ),
      );
}
