import 'package:kairos/core/routing/app_routes.dart';

/// Helper function to handle authentication-based redirects.
/// Returns the route to redirect to, or null if no redirect is needed.
String? authRedirectLogic({
  required bool isAuthenticated,
  required bool hasProfile,
  required String currentLocation,
}) {
  if (!isAuthenticated && currentLocation == AppRoutes.splash) return AppRoutes.login;

  // Public routes (no auth required)
  final publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
  ];
  final isPublicRoute = publicRoutes.contains(currentLocation);

  // Profile creation route (authenticated but no profile)
  final isProfileCreationRoute = currentLocation == AppRoutes.createProfile;

  // Protected routes (inside shell)
  final protectedRoutes = [
    AppRoutes.home,
    AppRoutes.journal,
    AppRoutes.settings,
  ];
  final isProtectedRoute = protectedRoutes.any(
    (route) => currentLocation.startsWith(route),
  );

  // Not authenticated → redirect to login
  if (!isAuthenticated && !isPublicRoute) {
    return AppRoutes.login;
  }

  // Authenticated but trying to access login/register → redirect based on profile
  if (isAuthenticated && isPublicRoute) {
    return hasProfile ? AppRoutes.home : AppRoutes.createProfile;
  }

  // Authenticated without profile trying to access protected route → redirect to profile creation
  if (isAuthenticated && !hasProfile && isProtectedRoute) {
    return AppRoutes.createProfile;
  }

  // Authenticated with profile trying to access profile creation → redirect to home
  if (isAuthenticated && hasProfile && isProfileCreationRoute) {
    return AppRoutes.home;
  }

  return null; // No redirect needed
}
