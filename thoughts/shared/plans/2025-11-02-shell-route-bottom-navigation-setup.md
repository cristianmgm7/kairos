# Shell Route & Bottom Navigation Setup Implementation Plan

## Overview

Implement a persistent bottom navigation structure for the Kairos app using GoRouter's ShellRoute with a MainScaffold that includes a BottomNavigationBar. The app will have 4 main tabs (Home, Journal, Notifications, Profile) with clean navigation that doesn't rebuild the entire UI on tab switches. This plan also includes updating the package name from `blueprint_app` to `kairos` and implementing a profile onboarding flow that runs after authentication.

## Current State Analysis

**Existing Setup:**
- GoRouter v14.6.2 installed and configured in [router_provider.dart](lib/core/routing/router_provider.dart:13)
- Basic flat routing: `/login`, `/register`, `/dashboard`
- Auth state watching with redirect logic working
- Profile creation screen exists but not integrated into onboarding flow
- Package name is currently `blueprint_app` (needs renaming to `kairos`)
- Clean architecture in place with Riverpod for state management

**Key Discoveries:**
- Profile state provider `hasCompletedProfileProvider` exists at [user_profile_providers.dart:61](lib/features/profile/presentation/providers/user_profile_providers.dart:61)
- Auth redirect logic is in [router_provider.dart:20-48](lib/core/routing/router_provider.dart:20-48)
- Theme system uses Material 3 with design tokens (spacing, colors, typography)
- Existing widget patterns: `AppButton`, `AppTextField`, `AppText`, `AppErrorView`

## Desired End State

A Flutter app with:
1. Package name changed from `blueprint_app` to `kairos` across all files
2. GoRouter ShellRoute containing all authenticated routes
3. Persistent MainScaffold with BottomNavigationBar (4 tabs)
4. Tab navigation that preserves state and doesn't rebuild unnecessarily
5. Profile onboarding flow: Auth → Profile Creation → Main App
6. Placeholder screens for Journal and Notifications
7. Home tab replacing the current Dashboard

**Verification:**
- User can sign in and is redirected to profile creation if no profile exists
- After profile creation, user lands on Home tab in main app
- Tab switching is smooth without rebuilding scaffold
- Bottom navigation highlights the active tab
- Back button behavior works correctly (doesn't navigate between tabs)
- All imports use `package:kairos/` instead of `package:blueprint_app/`

## What We're NOT Doing

- Implementing actual Journal functionality (placeholder only)
- Implementing actual Notifications functionality (placeholder only)
- Implementing Profile editing (just placeholder linking to future feature)
- Adding animations or transitions (using GoRouter defaults)
- Implementing deep linking or URL strategies
- Adding tablet/desktop adaptive layouts
- Implementing state restoration for tabs

## Implementation Approach

This will be a 5-phase implementation:
1. **Package Renaming**: Update all references from blueprint_app to kairos
2. **Route Structure Setup**: Define routes, create MainScaffold, configure ShellRoute
3. **Tab Screens Creation**: Build Home, Journal, Notifications, Profile screens
4. **Navigation State Management**: Wire up bottom nav with routing
5. **Onboarding Flow Integration**: Update redirects for profile creation flow

Each phase builds on the previous and includes both automated and manual verification steps.

---

## Phase 1: Package Renaming (blueprint_app → kairos)

### Overview
Update the package name from `blueprint_app` to `kairos` across all Dart files, platform-specific configurations, and build files.

### Changes Required:

#### 1. Update pubspec.yaml
**File**: `pubspec.yaml`
**Changes**: Change package name from `blueprint_app` to `kairos`

```yaml
name: kairos
description: A personal journaling and mindfulness app
```

#### 2. Update All Dart Import Statements
**Files**: All `.dart` files in `lib/` and `test/` directories (70 files identified)
**Changes**: Replace all import statements

```dart
// OLD
import 'package:blueprint_app/...';

// NEW
import 'package:kairos/...';
```

**Note**: This affects all files with imports. Use find-and-replace across the entire codebase.

#### 3. Update Android Package Name
**File**: `android/app/build.gradle.kts`
**Changes**: Update application ID

```kotlin
// OLD
applicationId = "com.blueprint.blueprint_app"

// NEW
applicationId = "com.kairos.app"
```

**File**: `android/app/src/main/AndroidManifest.xml`
**Changes**: Update package attribute

```xml
<!-- OLD -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.blueprint.blueprint_app">

<!-- NEW -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.kairos.app">
```

**File**: `android/app/src/main/kotlin/com/blueprint/blueprint_app/MainActivity.kt`
**Changes**:
1. Move file to `android/app/src/main/kotlin/com/kairos/app/MainActivity.kt`
2. Update package declaration

```kotlin
// OLD
package com.blueprint.blueprint_app

// NEW
package com.kairos.app
```

#### 4. Update iOS Bundle Identifier
**File**: `ios/Runner/Info.plist`
**Changes**: Update CFBundleIdentifier

```xml
<!-- OLD -->
<key>CFBundleIdentifier</key>
<string>com.blueprint.blueprintApp</string>

<!-- NEW -->
<key>CFBundleIdentifier</key>
<string>com.kairos.app</string>
```

#### 5. Update macOS Bundle Identifier
**File**: `macos/Runner/Configs/AppInfo.xcconfig`
**Changes**: Update PRODUCT_BUNDLE_IDENTIFIER

```
// OLD
PRODUCT_BUNDLE_IDENTIFIER = com.blueprint.blueprintApp

// NEW
PRODUCT_BUNDLE_IDENTIFIER = com.kairos.app
```

#### 6. Update Linux Application ID
**File**: `linux/CMakeLists.txt`
**Changes**: Update APPLICATION_ID

```cmake
# OLD
set(APPLICATION_ID "com.blueprint.blueprint_app")

# NEW
set(APPLICATION_ID "com.kairos.app")
```

**File**: `linux/runner/my_application.cc`
**Changes**: Update application ID in code

```cpp
// OLD
g_application_id_open(application, "com.blueprint.blueprint_app");

// NEW
g_application_id_open(application, "com.kairos.app");
```

#### 7. Update Windows Application
**File**: `windows/CMakeLists.txt`
**Changes**: Update BINARY_NAME

```cmake
# OLD
set(BINARY_NAME "blueprint_app")

# NEW
set(BINARY_NAME "kairos")
```

#### 8. Update Web Manifest
**File**: `web/manifest.json`
**Changes**: Update name and short_name

```json
{
  "name": "kairos",
  "short_name": "kairos",
  ...
}
```

**File**: `web/index.html`
**Changes**: Update title and meta description

```html
<title>Kairos</title>
<meta name="description" content="A personal journaling and mindfulness app">
```

### Success Criteria:

#### Automated Verification:
- [ ] Dependencies install successfully: `flutter pub get`
- [ ] No import errors: `flutter analyze`
- [ ] Code generation runs: `flutter packages pub run build_runner build --delete-conflicting-outputs`
- [ ] App builds for development: `flutter build apk --debug` (Android) or `flutter build ios --debug` (iOS)

#### Manual Verification:
- [ ] Search codebase confirms no remaining `blueprint_app` references: `grep -r "blueprint_app" lib/ test/`
- [ ] App launches with new package name on device/simulator
- [ ] Firebase still connects properly (using existing Firebase config)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the app still runs correctly with the new package name before proceeding to Phase 2.

---

## Phase 2: Route Structure & Navigation Setup

### Overview
Define new route constants, create the MainScaffold widget with BottomNavigationBar, and configure GoRouter's ShellRoute to wrap all authenticated routes with the persistent scaffold.

### Changes Required:

#### 1. Update Route Constants
**File**: `lib/core/routing/app_routes.dart`
**Changes**: Add new route paths for tabs and profile creation

```dart
class AppRoutes {
  AppRoutes._();

  // Authentication routes (outside shell)
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';

  // Onboarding route
  static const String createProfile = '/create-profile';

  // Main app routes (inside shell)
  static const String home = '/home';
  static const String journal = '/journal';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // Error
  static const String error = '/error';
}
```

#### 2. Create MainScaffold Widget
**File**: `lib/core/widgets/main_scaffold.dart` (NEW FILE)
**Changes**: Create the persistent scaffold with bottom navigation

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kairos/core/routing/app_routes.dart';

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
```

#### 3. Update Router Configuration with ShellRoute
**File**: `lib/core/routing/router_provider.dart`
**Changes**: Replace flat routes with ShellRoute structure

```dart
import 'package:kairos/core/routing/app_routes.dart';
import 'package:kairos/core/routing/pages/error_page.dart';
import 'package:kairos/core/widgets/main_scaffold.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/auth/presentation/screens/login_screen.dart';
import 'package:kairos/features/auth/presentation/screens/register_screen.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/features/profile/presentation/screens/create_profile_screen.dart';
import 'package:kairos/features/home/presentation/screens/home_screen.dart';
import 'package:kairos/features/journal/presentation/screens/journal_screen.dart';
import 'package:kairos/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:kairos/features/profile/presentation/screens/profile_screen.dart';
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
      // If still loading auth state, don't redirect
      if (authState.isLoading || !authState.hasValue) {
        return null;
      }

      final isAuthenticated = authState.valueOrNull != null;
      final location = state.matchedLocation;

      // Public routes (no auth required)
      final publicRoutes = [
        AppRoutes.login,
        AppRoutes.register,
      ];
      final isPublicRoute = publicRoutes.contains(location);

      // Profile creation route (authenticated but no profile)
      final isProfileCreationRoute = location == AppRoutes.createProfile;

      // Protected routes (inside shell)
      final protectedRoutes = [
        AppRoutes.home,
        AppRoutes.journal,
        AppRoutes.notifications,
        AppRoutes.profile,
      ];
      final isProtectedRoute = protectedRoutes.any((route) => location.startsWith(route));

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

      return null;
    },
    routes: [
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
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
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
```

### Success Criteria:

#### Automated Verification:
- [ ] No compilation errors: `flutter analyze`
- [ ] App builds successfully: `flutter run`

#### Manual Verification:
- [ ] Login flow redirects correctly (login → profile creation if no profile, or home if profile exists)
- [ ] Cannot access protected routes without authentication
- [ ] Bottom navigation bar appears on all shell routes
- [ ] Tab switching works without errors (even though screens don't exist yet)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the routing logic and scaffold structure work correctly before proceeding to Phase 3.

---

## Phase 3: Tab Screens Creation

### Overview
Create the four main tab screens: Home (migrating Dashboard content), Journal (placeholder), Notifications (placeholder), and Profile (placeholder).

### Changes Required:

#### 1. Create Feature Folder Structure

Create the following folder structure:
```
lib/features/
  ├── home/
  │   └── presentation/
  │       └── screens/
  │           └── home_screen.dart
  ├── journal/
  │   └── presentation/
  │       └── screens/
  │           └── journal_screen.dart
  └── notifications/
      └── presentation/
          └── screens/
              └── notifications_screen.dart
```

#### 2. Create Home Screen (Migrate Dashboard)
**File**: `lib/features/home/presentation/screens/home_screen.dart` (NEW FILE)
**Changes**: Create home screen by migrating dashboard content

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: profileAsync.when(
            data: (profile) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (profile?.avatarUrl != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(profile!.avatarUrl!),
                  )
                else if (user?.photoUrl != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user!.photoUrl!),
                  )
                else
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                if (profile?.name != null)
                  Text(
                    profile!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                if (user?.email != null)
                  Text(
                    user!.email!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 32),
                Text(
                  'Your journaling journey starts here',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
```

#### 3. Create Journal Screen (Placeholder)
**File**: `lib/features/journal/presentation/screens/journal_screen.dart` (NEW FILE)
**Changes**: Create placeholder screen for journal feature

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Journal',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your journal entries will appear here',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Coming soon...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create journal entry
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create journal entry - Coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

#### 4. Create Notifications Screen (Placeholder)
**File**: `lib/features/notifications/presentation/screens/notifications_screen.dart` (NEW FILE)
**Changes**: Create placeholder screen for notifications feature

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your notifications will appear here',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Coming soon...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 5. Create Profile Screen (Placeholder)
**File**: `lib/features/profile/presentation/screens/profile_screen.dart` (NEW FILE)
**Changes**: Create placeholder screen for profile viewing/editing

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Avatar
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Name
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Profile details
                _ProfileDetailTile(
                  icon: Icons.calendar_today,
                  title: 'Date of Birth',
                  value: profile.dateOfBirth != null
                      ? '${profile.dateOfBirth!.month}/${profile.dateOfBirth!.day}/${profile.dateOfBirth!.year}'
                      : 'Not set',
                ),
                _ProfileDetailTile(
                  icon: Icons.public,
                  title: 'Country',
                  value: profile.country ?? 'Not set',
                ),
                _ProfileDetailTile(
                  icon: Icons.person_outline,
                  title: 'Gender',
                  value: profile.gender ?? 'Not set',
                ),
                _ProfileDetailTile(
                  icon: Icons.flag,
                  title: 'Main Goal',
                  value: profile.mainGoal ?? 'Not set',
                ),
                _ProfileDetailTile(
                  icon: Icons.star,
                  title: 'Experience Level',
                  value: profile.experienceLevel ?? 'Not set',
                ),
                if (profile.interests != null && profile.interests!.isNotEmpty)
                  _ProfileDetailTile(
                    icon: Icons.favorite,
                    title: 'Interests',
                    value: profile.interests!.join(', '),
                  ),
                const SizedBox(height: AppSpacing.xxl),
                // Edit button placeholder
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit profile - Coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  const _ProfileDetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] No compilation errors: `flutter analyze`
- [ ] App builds successfully: `flutter run`

#### Manual Verification:
- [ ] All four tab screens display correctly
- [ ] Home screen shows user/profile data
- [ ] Journal screen shows placeholder with FAB
- [ ] Notifications screen shows placeholder
- [ ] Profile screen shows user profile details
- [ ] Navigation between tabs works smoothly

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that all screens display correctly and navigation works before proceeding to Phase 4.

---

## Phase 4: Profile Creation Integration & Flow Testing

### Overview
Ensure the profile creation screen properly navigates to the home screen after successful profile creation, and verify the entire authentication and onboarding flow works end-to-end.

### Changes Required:

#### 1. Update Profile Controller to Navigate After Creation
**File**: `lib/features/profile/presentation/controllers/profile_controller.dart`
**Changes**: Add navigation callback after successful profile creation

**Note**: The controller already invalidates providers after creation. We need to add GoRouter navigation in the screen that watches the state.

#### 2. Update Create Profile Screen with Navigation
**File**: `lib/features/profile/presentation/screens/create_profile_screen.dart`
**Changes**: Add listener to navigate after successful profile creation

```dart
// Add this import at the top
import 'package:go_router/go_router.dart';
import 'package:kairos/core/routing/app_routes.dart';

// Update the build method to add a listener for navigation
@override
Widget build(BuildContext context) {
  final profileState = ref.watch(profileControllerProvider);
  final profileController = ref.read(profileControllerProvider.notifier);

  // Listen for successful profile creation
  ref.listen<ProfileState>(profileControllerProvider, (previous, next) {
    if (next is ProfileSuccess) {
      // Navigate to home after successful profile creation
      context.go(AppRoutes.home);
    }
  });

  return Scaffold(
    // ... rest of the screen implementation stays the same
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] No compilation errors: `flutter analyze`
- [ ] App builds successfully: `flutter run`

#### Manual Verification:
- [ ] New user flow: Sign up → Profile creation → Home screen
- [ ] Existing user with profile: Sign in → Home screen (skip profile creation)
- [ ] Existing user without profile: Sign in → Profile creation → Home screen
- [ ] After profile creation, user lands on Home tab in main app
- [ ] Cannot navigate back to profile creation after completing it
- [ ] Profile data persists and displays correctly on Profile tab

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the entire onboarding flow works correctly before proceeding to Phase 5.

---

## Phase 5: Cleanup & Final Verification

### Overview
Remove the old dashboard route, verify all navigation flows work correctly, and ensure the app is in a clean, production-ready state.

### Changes Required:

#### 1. Delete Old Dashboard Page
**File**: `lib/core/routing/pages/dashboard_page.dart`
**Changes**: Delete this file entirely (no longer needed)

#### 2. Remove Dashboard Route from AppRoutes
**File**: `lib/core/routing/app_routes.dart`
**Changes**: Remove the dashboard constant

```dart
class AppRoutes {
  AppRoutes._();

  // Authentication routes (outside shell)
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';

  // Onboarding route
  static const String createProfile = '/create-profile';

  // Main app routes (inside shell)
  static const String home = '/home';
  static const String journal = '/journal';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // Error
  static const String error = '/error';

  // REMOVED: static const String dashboard = '/dashboard';
}
```

#### 3. Update Main App Title
**File**: `lib/main.dart`
**Changes**: Update app title from "Blueprint App" to "Kairos"

```dart
return MaterialApp.router(
  title: 'Kairos',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  routerConfig: router,
);
```

#### 4. Final Code Cleanup
**Changes**: Run code formatting and linting

- Format all code: `dart format lib/ test/`
- Run analyzer: `flutter analyze`
- Fix any warnings or info messages

### Success Criteria:

#### Automated Verification:
- [ ] No remaining references to dashboard: `grep -r "dashboard" lib/`
- [ ] No remaining references to blueprint_app: `grep -r "blueprint_app" lib/ test/`
- [ ] No linting errors: `flutter analyze`
- [ ] Code is formatted: `dart format --set-exit-if-changed lib/`
- [ ] All tests pass: `flutter test` (if any tests exist)
- [ ] App builds for release: `flutter build apk --release` (Android)

#### Manual Verification:
- [ ] Fresh install flow: Uninstall app, reinstall, complete full onboarding
- [ ] Sign out and sign back in works correctly
- [ ] Tab navigation is smooth and doesn't rebuild unnecessarily
- [ ] Active tab is correctly highlighted in bottom navigation
- [ ] Back button doesn't navigate between tabs (only within tab content)
- [ ] Deep link to `/home` works (if applicable)
- [ ] App title shows "Kairos" in app switcher and launcher
- [ ] No console warnings or errors during normal usage
- [ ] Profile data displays correctly on both Home and Profile screens

**Implementation Note**: This is the final phase. After all automated and manual verification passes, the implementation is complete and ready for production use.

---

## Testing Strategy

### Unit Tests:
- MainScaffold widget tests (verify correct tab highlighting)
- Route redirection logic tests (auth → profile → home flows)
- Bottom navigation index calculation tests

### Integration Tests:
- End-to-end authentication and onboarding flow
- Tab navigation persistence across app lifecycle
- Profile creation and data synchronization

### Manual Testing Steps:
1. **New User Flow**:
   - Launch app
   - Sign up with email
   - Complete profile creation
   - Verify landing on Home tab
   - Navigate through all tabs
   - Sign out and sign back in

2. **Existing User Flow**:
   - Sign in with existing account (has profile)
   - Verify landing on Home tab
   - Check profile data displays correctly
   - Test all tab switches

3. **Edge Cases**:
   - Sign up, skip profile (should redirect back)
   - Delete profile data manually (should redirect to creation)
   - Network offline during profile creation
   - Kill app during onboarding (should resume correctly)

4. **Navigation Behavior**:
   - Back button should exit app from Home tab, not switch tabs
   - Tab switching should be instant without rebuilds
   - Active tab indicator should always match current route

## Performance Considerations

- **ShellRoute Efficiency**: Using `NoTransitionPage` prevents unnecessary animations between tabs, improving perceived performance
- **Widget Rebuild Optimization**: MainScaffold only rebuilds when location changes, not on every tab switch
- **State Preservation**: Each tab screen maintains its own state when switching between tabs
- **Image Loading**: Profile avatars use `NetworkImage` with implicit caching (consider adding `cached_network_image` in future)

## Migration Notes

**For Users Upgrading**:
- Existing users will see no change if they already have a profile
- New users will be prompted to create a profile after authentication
- Dashboard route is replaced by Home tab (equivalent functionality)

**Data Migration**:
- No data migration needed (profile structure unchanged)
- Existing Firebase Auth sessions remain valid
- Isar database structure unchanged

## Folder Structure Summary

After implementation, the complete structure will be:

```
lib/
├── core/
│   ├── routing/
│   │   ├── app_routes.dart (UPDATED)
│   │   ├── router_provider.dart (UPDATED)
│   │   └── pages/
│   │       ├── error_page.dart
│   │       └── dashboard_page.dart (DELETED in Phase 5)
│   └── widgets/
│       ├── main_scaffold.dart (NEW)
│       ├── app_button.dart
│       ├── app_text_field.dart
│       └── ...
├── features/
│   ├── auth/
│   │   └── ...
│   ├── home/ (NEW)
│   │   └── presentation/
│   │       └── screens/
│   │           └── home_screen.dart
│   ├── journal/ (NEW)
│   │   └── presentation/
│   │       └── screens/
│   │           └── journal_screen.dart
│   ├── notifications/ (NEW)
│   │   └── presentation/
│   │       └── screens/
│   │           └── notifications_screen.dart
│   └── profile/
│       ├── presentation/
│       │   ├── screens/
│       │   │   ├── create_profile_screen.dart (UPDATED)
│       │   │   └── profile_screen.dart (NEW)
│       │   └── ...
│       └── ...
└── main.dart (UPDATED)
```

## References

- GoRouter ShellRoute documentation: https://pub.dev/documentation/go_router/latest/topics/Shell%20routes-topic.html
- Material 3 NavigationBar: https://m3.material.io/components/navigation-bar
- Flutter clean architecture: https://github.com/ResoCoder/flutter-tdd-clean-architecture-course
- Riverpod state management: https://riverpod.dev/docs/introduction/why_riverpod
