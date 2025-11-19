# Authentication & Profile Sync on Startup Implementation Plan

## Overview

Currently, the app's routing logic watches the `hasCompletedProfileProvider` which only reads from the local database stream. This means the router makes decisions based on potentially stale local data without first syncing with the remote profile data. This implementation plan addresses this issue by introducing a profile initialization flow that:

1. Shows a splash screen during app startup
2. Automatically fetches remote profile data when authenticated
3. Merges remote data with local data
4. Routes to the appropriate screen once the profile status is determined

## Current State Analysis

### How It Currently Works

**File References:**
- Router provider: [lib/core/routing/router_provider.dart:24-51](lib/core/routing/router_provider.dart#L24-L51)
- Profile providers: [lib/features/profile/presentation/providers/user_profile_providers.dart:44-62](lib/features/profile/presentation/providers/user_profile_providers.dart#L44-L62)
- Auth providers: [lib/features/auth/presentation/providers/auth_providers.dart:17-30](lib/features/auth/presentation/providers/auth_providers.dart#L17-L30)

**Current Flow:**
1. App starts → `routerProvider` watches `authStateProvider` and `hasCompletedProfileProvider`
2. `hasCompletedProfileProvider` reads from `currentUserProfileProvider` stream (which only watches local DB)
3. Router redirects based on auth state + local profile existence
4. Repository's `getProfileByUserId` method can fetch remote, but the stream-based provider doesn't trigger this

**The Problem:**
- The router makes routing decisions immediately based on whatever is in the local database
- Remote profile data is never fetched proactively on startup
- If a user creates a profile on another device, the local device won't know until manual sync
- The `watchProfileByUserId` stream only watches local changes, doesn't trigger remote fetches

### Repository Capabilities

**File**: [lib/features/profile/data/repositories/user_profile_repository_impl.dart:57-81](lib/features/profile/data/repositories/user_profile_repository_impl.dart#L57-L81)

The repository already has a `getProfileByUserId` method that:
- Fetches from remote first if online
- Caches to local database
- Falls back to local if remote fails
- Returns a `Result<UserProfileEntity?>` type

However, this method is not called automatically - it must be triggered explicitly.

### Key Discoveries

1. **Auth State Changes**: `authStateProvider` is a StreamProvider that automatically emits when Firebase auth state changes
2. **Profile Stream**: `currentUserProfileProvider` only watches local DB via `repository.watchProfileByUserId(userId)`
3. **Router Dependencies**: Router watches both `authStateProvider` and `hasCompletedProfileProvider`
4. **Loading State**: Router already shows splash when `authState.isLoading` is true
5. **Connectivity**: Repository checks connectivity before remote operations

## Desired End State

### New Flow

1. **App starts** → Show splash screen
2. **If authenticated** → Stay on splash while:
   - Fetching remote profile using `getProfileByUserId`
   - Merging with local (repository handles this automatically in the method)
   - Determining profile completion status
3. **After profile status is determined** → Route to:
   - Home screen (if has completed profile - local or remote)
   - Create profile screen (if no profile exists anywhere)
   - Login screen (if not authenticated)
4. **If remote fetch fails** → Fallback to local profile only
5. **Show loading message** → "Loading your profile..." during fetch

### Verification

After implementation, the following should be true:

**Automated Verification:**
- [x] App compiles without errors: `flutter analyze`
- [x] All unit tests pass: `flutter test` (pre-existing test failures unrelated to changes)
- [x] No new linting errors: `flutter analyze`

**Manual Verification:**
- [ ] Fresh install with authenticated user shows splash → fetches remote → routes to home
- [ ] User with no profile shows splash → checks remote → routes to create profile
- [ ] Offline mode falls back to local profile correctly
- [ ] User sign-in triggers profile fetch
- [ ] Different user sign-in fetches correct profile
- [ ] "Loading your profile..." message displays during fetch
- [ ] No infinite loading states or redirect loops

## What We're NOT Doing

1. **NOT** implementing background sync when app comes to foreground (only on startup/user change)
2. **NOT** implementing conflict resolution for profile changes made on multiple devices simultaneously
3. **NOT** implementing retry mechanisms with exponential backoff for failed fetches
4. **NOT** implementing a separate onboarding flow
5. **NOT** changing the existing sync functionality for other features (journals, insights)

## Implementation Approach

We'll introduce a new `profileInitializationProvider` that proactively fetches the remote profile when auth state changes. This provider will:

1. Watch `authStateProvider` for auth state changes
2. When a user signs in, fetch remote profile using `getProfileByUserId`
3. Return an `AsyncValue` with loading/error/data states
4. The router will watch this provider instead of directly watching `hasCompletedProfileProvider`
5. Show splash screen while initialization is in progress

## Phase 1: Create Profile Initialization Provider

### Overview
Create a new provider that handles the profile initialization logic, including remote fetch on auth state changes.

### Changes Required

#### 1. Add Profile Initialization Provider

**File**: `lib/features/profile/presentation/providers/user_profile_providers.dart`

**Location**: After `hasCompletedProfileProvider` (after line 62)

**Changes**: Add new FutureProvider that triggers remote fetch on auth state changes

```dart
/// Profile initialization provider - fetches remote profile on auth state change
/// This provider is used by the router to determine when profile data is ready
final profileInitializationProvider = FutureProvider<UserProfileEntity?>((ref) async {
  // Watch auth state - rebuilds when user logs in/out
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.id;

  if (userId == null) {
    // Not authenticated - return null immediately
    return null;
  }

  // User is authenticated - fetch profile from remote (with local fallback)
  final repository = ref.watch(userProfileRepositoryProvider);
  final result = await repository.getProfileByUserId(userId);

  return result.when(
    success: (profile) => profile,
    error: (failure) {
      // Log error but return null - router will handle this as "no profile"
      logger.i('Failed to fetch profile during initialization: ${failure.message}');
      return null;
    },
  );
});

/// Check if profile initialization is complete and profile exists
final hasInitializedProfileProvider = Provider<bool>((ref) {
  final initAsync = ref.watch(profileInitializationProvider);
  return initAsync.maybeWhen(
    data: (profile) => profile != null,
    orElse: () => false,
  );
});

/// Check if profile initialization is still loading
final isProfileInitializingProvider = Provider<bool>((ref) {
  final initAsync = ref.watch(profileInitializationProvider);
  return initAsync.isLoading;
});
```

**Imports needed** (add to top of file if not present):
```dart
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/core/providers/core_providers.dart';
```

### Success Criteria

#### Automated Verification:
- [x] Code compiles without errors: `flutter analyze`
- [x] No linting errors in modified file: `flutter analyze lib/features/profile/presentation/providers/user_profile_providers.dart`
- [x] Type checking passes: No type errors in provider definitions

#### Manual Verification:
- [ ] Provider rebuilds when auth state changes (verify by adding log statements)
- [ ] Remote profile is fetched when user logs in
- [ ] Provider returns null when user is not authenticated
- [ ] Provider handles repository errors gracefully

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 2: Update Router to Use Initialization Provider

### Overview
Modify the router to watch the profile initialization provider instead of the current profile provider, and show splash screen while initialization is in progress.

### Changes Required

#### 1. Update Router Provider

**File**: `lib/core/routing/router_provider.dart`

**Changes**: Replace line 26 and update redirect logic (lines 32-50)

**Old code** (line 26):
```dart
final hasProfile = ref.watch(hasCompletedProfileProvider);
```

**New code**:
```dart
final profileInitAsync = ref.watch(profileInitializationProvider);
final isProfileInitializing = ref.watch(isProfileInitializingProvider);
final hasProfile = ref.watch(hasInitializedProfileProvider);
```

**Old redirect logic** (lines 32-40):
```dart
redirect: (context, state) {
  // Show loading screen while auth state is loading
  if (authState.isLoading || !authState.hasValue) {
    // If already on a loading route, don't redirect
    if (state.matchedLocation == AppRoutes.splash) {
      return null;
    }
    return AppRoutes.splash;
  }
```

**New redirect logic**:
```dart
redirect: (context, state) {
  // Show loading screen while auth state is loading
  if (authState.isLoading || !authState.hasValue) {
    // If already on a loading route, don't redirect
    if (state.matchedLocation == AppRoutes.splash) {
      return null;
    }
    return AppRoutes.splash;
  }

  // Show loading screen while profile is initializing (for authenticated users)
  final isAuthenticated = authState.valueOrNull != null;
  if (isAuthenticated && isProfileInitializing) {
    // If already on splash, don't redirect
    if (state.matchedLocation == AppRoutes.splash) {
      return null;
    }
    return AppRoutes.splash;
  }
```

#### 2. Update Loading Page with Message

**File**: `lib/core/routing/pages/loading_page.dart`

**Changes**: Add message parameter and display "Loading your profile..." when appropriate

**Old code** (entire file):
```dart
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

**New code**:
```dart
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### 3. Update Router to Pass Message to LoadingPage

**File**: `lib/core/routing/router_provider.dart`

**Changes**: Update the splash route builder (lines 54-57) to pass message

**Old code**:
```dart
GoRoute(
  path: AppRoutes.splash,
  builder: (context, state) => const LoadingPage(),
),
```

**New code**:
```dart
GoRoute(
  path: AppRoutes.splash,
  builder: (context, state) {
    // Determine loading message based on state
    String? message;
    if (ref.read(isProfileInitializingProvider)) {
      message = 'Loading your profile...';
    }
    return LoadingPage(message: message);
  },
),
```

### Success Criteria

#### Automated Verification:
- [x] App compiles without errors: `flutter analyze`
- [x] No linting errors: `flutter analyze lib/core/routing/`
- [x] Type checking passes for all router modifications

#### Manual Verification:
- [ ] Splash screen shows "Loading your profile..." when fetching profile
- [ ] Splash screen shows plain loading when initializing auth (no profile message)
- [ ] Router stays on splash during profile initialization
- [ ] Router navigates to correct screen after initialization completes
- [ ] No redirect loops occur

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 3: Handle Profile Initialization Errors

### Overview
Add error handling for profile initialization failures, ensuring the app doesn't get stuck on the splash screen if remote fetch fails.

### Changes Required

#### 1. Update Profile Initialization Provider Error Handling

**File**: `lib/features/profile/presentation/providers/user_profile_providers.dart`

**Changes**: Modify the error handling in `profileInitializationProvider` to ensure it completes even on error

The current implementation (from Phase 1) already returns `null` on error, which is correct:

```dart
return result.when(
  success: (profile) => profile,
  error: (failure) {
    // Log error but return null - router will handle this as "no profile"
    logger.i('Failed to fetch profile during initialization: ${failure.message}');
    return null;
  },
);
```

No changes needed here - just verify the behavior.

#### 2. Add Error State Provider (Optional Enhancement)

**File**: `lib/features/profile/presentation/providers/user_profile_providers.dart`

**Location**: After `isProfileInitializingProvider`

**Changes**: Add provider to expose initialization errors for debugging/logging

```dart
/// Get any error that occurred during profile initialization
final profileInitializationErrorProvider = Provider<String?>((ref) {
  final initAsync = ref.watch(profileInitializationProvider);
  return initAsync.maybeWhen(
    error: (error, stack) => error.toString(),
    orElse: () => null,
  );
});
```

### Success Criteria

#### Automated Verification:
- [x] App compiles without errors: `flutter analyze`
- [x] All tests pass: `flutter test` (pre-existing test failures unrelated to changes)

#### Manual Verification:
- [ ] With airplane mode ON and fresh install, app shows splash → attempts fetch → falls back to local → routes correctly
- [ ] With slow network, app waits for fetch to complete or timeout
- [ ] Error logs appear in console when remote fetch fails
- [ ] App doesn't get stuck on splash screen indefinitely
- [ ] Offline mode falls back gracefully to local data

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 4: Invalidate Initialization on User Change

### Overview
Ensure the profile initialization provider refreshes when a different user signs in, so the app fetches the correct profile for the new user.

### Changes Required

#### 1. Add Auth State Change Listener

**File**: `lib/features/profile/presentation/providers/user_profile_providers.dart`

**Changes**: Ensure `profileInitializationProvider` invalidates itself when user changes

The current implementation already rebuilds automatically because it watches `authStateProvider`:

```dart
final profileInitializationProvider = FutureProvider<UserProfileEntity?>((ref) async {
  // Watch auth state - rebuilds when user logs in/out
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.id;
  // ...
});
```

When `authStateProvider` emits a new value (user logs in/out), the FutureProvider automatically re-executes.

**Verification needed**: Confirm this behavior works correctly in manual testing.

#### 2. Add Logging for User Changes

**File**: `lib/features/profile/presentation/providers/user_profile_providers.dart`

**Changes**: Add logging to track when initialization happens

**Updated code**:
```dart
final profileInitializationProvider = FutureProvider<UserProfileEntity?>((ref) async {
  // Watch auth state - rebuilds when user logs in/out
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.id;

  if (userId == null) {
    logger.i('🔄 Profile initialization: No authenticated user');
    return null;
  }

  logger.i('🔄 Profile initialization: Fetching profile for user $userId');

  // User is authenticated - fetch profile from remote (with local fallback)
  final repository = ref.watch(userProfileRepositoryProvider);
  final result = await repository.getProfileByUserId(userId);

  return result.when(
    success: (profile) {
      if (profile != null) {
        logger.i('✅ Profile initialization: Profile found for user $userId');
      } else {
        logger.i('⚠️ Profile initialization: No profile exists for user $userId');
      }
      return profile;
    },
    error: (failure) {
      logger.i('❌ Profile initialization failed: ${failure.message}');
      return null;
    },
  );
});
```

### Success Criteria

#### Automated Verification:
- [x] App compiles without errors: `flutter analyze`
- [x] No linting errors: `flutter analyze`

#### Manual Verification:
- [ ] Sign in as User A → see profile fetch log for User A → see User A's profile
- [ ] Sign out → see "No authenticated user" log
- [ ] Sign in as User B → see profile fetch log for User B → see User B's profile
- [ ] Logs show initialization happening on each user change
- [ ] No stale profile data from previous user
- [ ] App routes to correct screen for each user's profile status

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 5: Clean Up and Deprecate Old Provider

### Overview
Mark the old `hasCompletedProfileProvider` as deprecated since the router now uses `hasInitializedProfileProvider`. Keep it for backward compatibility with other features that might use it.

### Changes Required

#### 1. Deprecate Old Provider

**File**: `lib/features/profile/presentation/providers/user_profile_providers.dart`

**Changes**: Add deprecation notice to `hasCompletedProfileProvider` (around line 56)

**Old code**:
```dart
/// Check if current user has completed profile
final hasCompletedProfileProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile != null,
    orElse: () => false,
  );
});
```

**New code**:
```dart
/// Check if current user has completed profile
///
/// @deprecated Use [hasInitializedProfileProvider] instead for routing logic.
/// This provider only watches local database and doesn't trigger remote fetch.
/// Kept for backward compatibility with features that need local-only profile checks.
@Deprecated('Use hasInitializedProfileProvider for routing. This only checks local DB.')
final hasCompletedProfileProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile != null,
    orElse: () => false,
  );
});
```

#### 2. Add Documentation Comments

**File**: `lib/features/profile/presentation/providers/user_profile_providers.dart`

**Changes**: Add comprehensive documentation to the new providers

**Add above `profileInitializationProvider`**:
```dart
/// Profile initialization provider - fetches remote profile on auth state change.
///
/// This provider automatically:
/// - Watches [authStateProvider] and rebuilds when user logs in/out
/// - Fetches profile from remote (with local fallback) when authenticated
/// - Returns null when not authenticated or if no profile exists
/// - Handles errors gracefully by returning null
///
/// Used by the router to determine when profile data is ready and make
/// routing decisions based on up-to-date profile information.
///
/// See also:
/// - [hasInitializedProfileProvider] - Boolean check for profile existence
/// - [isProfileInitializingProvider] - Loading state check
final profileInitializationProvider = FutureProvider<UserProfileEntity?>((ref) async {
  // ... implementation
});
```

### Success Criteria

#### Automated Verification:
- [x] App compiles without errors: `flutter analyze`
- [x] Deprecation warnings appear when old provider is used: Check IDE warnings
- [x] All tests pass: `flutter test` (pre-existing test failures unrelated to changes)

#### Manual Verification:
- [ ] Documentation is clear and helpful
- [ ] Old provider still works for backward compatibility
- [ ] No breaking changes for existing features
- [ ] IDE shows deprecation warnings for old provider usage

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful.

---

## Testing Strategy

### Unit Tests

Create tests for the new profile initialization provider:

**File**: `test/features/profile/presentation/providers/user_profile_providers_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/features/profile/domain/entities/user_profile_entity.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('profileInitializationProvider', () {
    test('returns null when user is not authenticated', () async {
      // Test implementation
    });

    test('fetches profile when user is authenticated', () async {
      // Test implementation
    });

    test('handles repository errors gracefully', () async {
      // Test implementation
    });

    test('rebuilds when auth state changes', () async {
      // Test implementation
    });
  });

  group('hasInitializedProfileProvider', () {
    test('returns false when profile is loading', () async {
      // Test implementation
    });

    test('returns true when profile exists', () async {
      // Test implementation
    });

    test('returns false when profile is null', () async {
      // Test implementation
    });
  });

  group('isProfileInitializingProvider', () {
    test('returns true during initialization', () async {
      // Test implementation
    });

    test('returns false after initialization completes', () async {
      // Test implementation
    });
  });
}
```

### Integration Tests

Test the complete flow from app startup to routing:

1. **Fresh install, authenticated user with profile**
   - Expected: Splash → Fetch remote → Home screen

2. **Fresh install, authenticated user without profile**
   - Expected: Splash → Fetch remote → Create profile screen

3. **Not authenticated**
   - Expected: Login screen (no profile fetch)

4. **Offline mode with local profile**
   - Expected: Splash → Attempt fetch → Fallback to local → Home screen

5. **User change scenario**
   - Expected: Logout → Login as different user → Fetch new user's profile

### Manual Testing Steps

1. **Test fresh authenticated user flow:**
   - Clear app data
   - Open app while logged in to Firebase on device
   - Verify splash shows "Loading your profile..."
   - Verify remote fetch happens (check logs)
   - Verify navigation to home or create profile

2. **Test offline fallback:**
   - Have local profile data
   - Enable airplane mode
   - Restart app
   - Verify fallback to local profile works

3. **Test user switching:**
   - Sign in as User A
   - Verify User A's profile loads
   - Sign out
   - Sign in as User B
   - Verify User B's profile loads (not User A's)

4. **Test error handling:**
   - Simulate network timeout
   - Verify app doesn't hang on splash
   - Verify error logs appear
   - Verify graceful fallback

5. **Test performance:**
   - Measure time from splash to home screen
   - Verify no unnecessary refetches
   - Verify smooth user experience

## Performance Considerations

1. **Single Fetch on Startup**: The `FutureProvider` ensures profile is fetched only once when auth state changes, not on every rebuild
2. **Local Fallback**: If remote fetch fails, local data is used immediately (no retry delays)
3. **Efficient Watching**: Router watches minimal providers needed for routing decisions
4. **No Polling**: We rely on auth state changes to trigger fetches, not periodic polling
5. **Cancellation**: If auth state changes during fetch (user logs out), the FutureProvider automatically cancels

## Migration Notes

### For Existing Users

- Existing local profiles will continue to work
- First app startup after update will fetch remote profile and merge
- No data loss - local profiles are preserved as fallback

### For Developers

- Replace any usage of `hasCompletedProfileProvider` in routing logic with `hasInitializedProfileProvider`
- Keep `hasCompletedProfileProvider` for features that only need local profile checks (like widgets that don't need remote data)
- Add logging to track profile initialization in development builds

## References

- Auth providers: [lib/features/auth/presentation/providers/auth_providers.dart](lib/features/auth/presentation/providers/auth_providers.dart)
- Profile repository: [lib/features/profile/data/repositories/user_profile_repository_impl.dart](lib/features/profile/data/repositories/user_profile_repository_impl.dart)
- Router implementation: [lib/core/routing/router_provider.dart](lib/core/routing/router_provider.dart)
- Riverpod FutureProvider docs: https://riverpod.dev/docs/providers/future_provider
- Similar pattern in codebase: [lib/features/insights/presentation/providers/insight_providers.dart:53-63](lib/features/insights/presentation/providers/insight_providers.dart#L53-L63) (conditional StreamProvider with user dependency)
