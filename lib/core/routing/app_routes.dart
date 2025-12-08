class AppRoutes {
  AppRoutes._();

  // Authentication routes (outside shell)
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';

  // Onboarding route (authenticated but outside shell)
  static const String createProfile = '/create-profile';

  // Main app routes (inside shell)

  static const String homeRelative = 'home';
  static const String home = '/$homeRelative';
  static const String insightDetailsRelative = 'insights';
  static const String insightDetails = '/$homeRelative/$insightDetailsRelative';

  static const String journal = '/journal';
  static const String insights = '/insights';
  static const String settings = '/settings';

  // Settings sub-routes
  static const String themeSettings = '/settings/theme';
  static const String languageSettings = '/settings/language';
  static const String manageData = '/settings/manage-data';
  static const String pushNotifications = '/settings/push-notifications';

  // Streak route (authenticated but outside shell)
  static const String streakDashboard = '/streak/dashboard';

  // Error
  static const String error = '/error';
}
