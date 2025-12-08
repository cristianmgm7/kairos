import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/widgets/main_scaffold.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/presentation/screens/category_insight_detail_screen.dart';
import 'package:kairos/features/category_insights/presentation/screens/category_insights_screen.dart';
import 'package:kairos/features/home/presentation/screens/home_screen.dart';
import 'package:kairos/features/journal/presentation/screens/thread_list_screen.dart';
import 'package:kairos/features/settings/presentation/screens/settings_screen.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

abstract class MainAppShell {
  const MainAppShell._();

  static RouteBase get _home => GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomeScreen(),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.insightDetailsRelative,
            builder: (context, state) => CategoryInsightDetailScreen(
              category: state.extra! as InsightCategory,
            ),
          ),
        ],
      );

  static RouteBase get _journal => GoRoute(
        path: AppRoutes.journal,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ThreadListScreen(),
        ),
      );

  static RouteBase get _insights => GoRoute(
        path: AppRoutes.insights,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CategoryInsightsScreen(),
        ),
      );

  static RouteBase get _settings => GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SettingsScreen(),
        ),
      );

  static RouteBase create() {
    return StatefulShellRoute.indexedStack(
      builder: (_, __, navigationShell) => MainScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          preload: true,
          routes: [_home],
        ),
        StatefulShellBranch(
          preload: true,
          routes: [_journal],
        ),
        StatefulShellBranch(
          preload: true,
          routes: [_insights],
        ),
        StatefulShellBranch(
          preload: true,
          routes: [_settings],
        ),
      ],
    );
  }
}
