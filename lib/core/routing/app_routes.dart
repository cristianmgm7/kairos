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
  static const String home = '/home';
  static const String journal = '/journal';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  // Error
  static const String error = '/error';
}
