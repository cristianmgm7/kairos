# Riverpod Migration: From GetIt Hybrid to Pure Riverpod

## Overview

Migrate the Flutter blueprint app from its current hybrid GetIt + Riverpod architecture to pure Riverpod state management. The auth feature is already implemented with Riverpod, but core infrastructure (networking, logging, Firebase configuration) still uses GetIt + Injectable. This migration will create a unified, modern state management approach while preserving all existing functionality.

## Current State Analysis

### Existing Hybrid Architecture:
- **GetIt + Injectable**: Core infrastructure (Dio, Logger, Connectivity, Firebase, ApiClient, NetworkInfo)
- **Riverpod**: Auth feature state management (auth providers, controllers, reactive routing)
- **Mixed Routing**: Both old `AppRouter` (GetIt) and new `routerProvider` (Riverpod)
- **Working Auth**: Full Firebase auth with Google + Email/Password already implemented

### Components to Migrate:
1. **Core Infrastructure**: Logger, Dio, Connectivity, FirebaseConfig, FirebaseAuth
2. **Network Layer**: ApiClient, NetworkInfo
3. **Routing**: Remove old AppRouter, fully adopt routerProvider
4. **Auth Integration**: Remove GetIt bridging in auth providers
5. **Dependencies**: Remove get_it, injectable packages

### Key Dependencies Found:
- `lib/core/di/injection.dart` - GetIt initialization
- `lib/core/di/core_module.dart` - Injectable registrations
- `lib/core/network/network_info.dart` - Injectable NetworkInfo
- `lib/core/network/api_client.dart` - Injectable ApiClient
- `lib/core/config/firebase_config.dart` - Injectable FirebaseConfig
- `lib/core/routing/app_router.dart` - Injectable AppRouter (deprecated)

## Desired End State

After migration:
- **Pure Riverpod**: All state management unified under Riverpod
- **No GetIt**: Complete removal of GetIt and Injectable dependencies
- **Preserved Functionality**: Auth, routing, and all features work identically
- **Better Performance**: Riverpod's optimized provider system
- **Type Safety**: Full compile-time safety with Riverpod
- **Testability**: Improved testing with Riverpod's testing utilities
- **Maintainability**: Single, consistent state management pattern

**Verification:**
- App launches and builds successfully: `flutter run --flavor dev -t lib/main_dev.dart`
- Auth flow works: Sign in/out, Google auth, email/password
- Network requests work: API calls function properly
- Routing works: Navigation and auth guards functional
- No runtime errors: Clean console output
- Tests pass: `flutter test`
- No linting errors: `flutter analyze`

## What We're NOT Doing

- NOT changing the UI or user experience
- NOT modifying the auth business logic
- NOT changing the Clean Architecture structure
- NOT removing Firebase or network dependencies
- NOT changing the routing paths or navigation flow
- NOT modifying the existing working auth implementation

## Implementation Approach

### Strategy:
1. **Incremental Migration**: Migrate infrastructure components one by one
2. **Preserve Auth**: Keep working auth feature untouched until final integration
3. **Bridge Pattern**: Temporarily bridge GetIt to Riverpod during transition
4. **Parallel Testing**: Test each migration step independently
5. **Safe Rollback**: Each step can be reverted if issues arise

### Why This Order:
- Core providers first (Logger, Dio) - needed by other services
- Network layer next - depends on core providers
- Firebase config - depends on network and core
- Routing system - depends on auth providers
- Auth integration - final step to remove GetIt bridging
- Cleanup - remove old dependencies last

---

## Phase 1: Design Pure Riverpod Architecture

### Overview
Design the new Riverpod provider hierarchy to replace GetIt infrastructure. This phase focuses on planning without code changes.

### Changes Required:

#### 1. Core Providers Design
**Analysis**: Current GetIt registrations in `core_module.dart`

```dart
// Current GetIt (to be replaced):
@lazySingleton
Logger get logger => Logger(...);

@lazySingleton
Dio get dio => Dio(...);

@lazySingleton
Connectivity get connectivity => Connectivity();

@lazySingleton
FirebaseConfig get firebaseConfig => FirebaseConfig();

@lazySingleton
FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

@lazySingleton
GoogleSignIn get googleSignIn => GoogleSignIn(scopes: ['email', 'profile']);
```

**New Riverpod Design:**
```dart
// Core Infrastructure Providers
final loggerProvider = Provider<Logger>((ref) {
  return Logger(...);
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(flavorConfigProvider);
  final logger = ref.watch(loggerProvider);

  final dio = Dio(BaseOptions(...));

  if (config.enableLogging) {
    dio.interceptors.add(PrettyDioLogger());
  }

  return dio;
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final firebaseConfigProvider = Provider<FirebaseConfig>((ref) {
  return FirebaseConfig();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(scopes: ['email', 'profile']);
});
```

#### 2. Network Layer Providers
**Analysis**: Current injectable classes

```dart
// New Riverpod providers:
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfoImpl(connectivity);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
```

#### 3. Auth Repository Provider
**Current**: Bridged from GetIt
```dart
// Current bridging (to be replaced):
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return getIt<AuthRepository>(); // Remove this bridge
});

// New direct provider:
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  return FirebaseAuthRepository(firebaseAuth, googleSignIn);
});
```

### Success Criteria:

#### Automated Verification:
- [ ] Provider hierarchy design is sound
- [ ] No circular dependencies identified
- [ ] All dependencies properly scoped (singletons vs scoped)

#### Manual Verification:
- [ ] Provider relationships diagrammed and approved
- [ ] Migration order validated
- [ ] No breaking changes to auth flow identified

**Implementation Note**: This phase is planning-only. No code changes yet.

---

## Phase 2: Create Core Infrastructure Providers

### Overview
Create Riverpod providers for Logger, Dio, Connectivity, and Firebase services. Start with the foundation that other providers depend on.

### Changes Required:

#### 1. Create Core Providers File
**File**: `lib/core/providers/core_providers.dart`
**Changes**: Create fundamental Riverpod providers

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:blueprint_app/core/config/firebase_config.dart';
import 'package:blueprint_app/core/config/flavor_config.dart';

/// Logger provider - foundational logging service
final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
    ),
    level: FlavorConfig.instance.enableLogging ? Level.debug : Level.error,
  );
});

/// Connectivity provider - network connectivity monitoring
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Firebase Auth provider - Firebase authentication instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Google Sign-In provider - Google authentication service
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: ['email', 'profile'],
  );
});

/// Firebase config provider - Firebase initialization service
final firebaseConfigProvider = Provider<FirebaseConfig>((ref) {
  return FirebaseConfig();
});

/// Dio provider - HTTP client with logging and configuration
final dioProvider = Provider<Dio>((ref) {
  final config = FlavorConfig.instance;
  final logger = ref.watch(loggerProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: Duration(milliseconds: config.apiTimeout),
      receiveTimeout: Duration(milliseconds: config.apiTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  if (config.enableLogging) {
    dio.interceptors.add(PrettyDioLogger());
  }

  return dio;
});
```

#### 2. Update Flavor Config Access
**Consideration**: FlavorConfig is currently a singleton. For Riverpod, we should consider if it needs to be a provider too.

**Decision**: Keep FlavorConfig as singleton since it's truly global and set at app startup.

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] All providers are properly typed
- [ ] No circular dependencies

#### Manual Verification:
- [ ] Providers can be instantiated without errors
- [ ] Logger provider creates logger correctly
- [ ] Dio provider includes proper interceptors

**Implementation Note**: Core providers created. Next phase migrates network layer.

---

## Phase 3: Migrate Network Layer to Riverpod

### Overview
Migrate NetworkInfo and ApiClient from Injectable to Riverpod providers.

### Changes Required:

#### 1. Update NetworkInfo
**File**: `lib/core/network/network_info.dart`
**Changes**: Remove Injectable, create Riverpod provider

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }
}

/// NetworkInfo provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfoImpl(connectivity);
});
```

#### 2. Update ApiClient
**File**: `lib/core/network/api_client.dart`
**Changes**: Remove Injectable, create Riverpod provider

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blueprint_app/core/errors/exceptions.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(...) async { /* existing implementation */ }
  Future<T> post<T>(...) async { /* existing implementation */ }
  Future<T> put<T>(...) async { /* existing implementation */ }
  Future<T> delete<T>(...) async { /* existing implementation */ }

  Exception _handleError(DioException error) { /* existing implementation */ }
}

/// ApiClient provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
```

#### 3. Update Imports in Core Providers
**File**: `lib/core/providers/core_providers.dart`
**Changes**: Add network provider exports

```dart
// Add to exports
export 'package:blueprint_app/core/network/network_info.dart';
export 'package:blueprint_app/core/network/api_client.dart';
```

### Success Criteria:

#### Automated Verification:
- [ ] Network layer compiles: `flutter analyze`
- [ ] NetworkInfo provider works with connectivity
- [ ] ApiClient provider works with dio

#### Manual Verification:
- [ ] Network connectivity detection works
- [ ] API client can make HTTP requests

**Implementation Note**: Network layer migrated. Next phase handles Firebase config.

---

## Phase 4: Migrate Firebase Configuration

### Overview
Migrate FirebaseConfig and update auth repository provider to use Riverpod directly.

### Changes Required:

#### 1. Update Auth Repository Provider
**File**: `lib/features/auth/presentation/providers/auth_providers.dart`
**Changes**: Remove GetIt bridging, use Riverpod providers directly

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blueprint_app/core/providers/core_providers.dart';
import 'package:blueprint_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';

/// AuthRepository provider (direct Riverpod, no GetIt bridging)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  return FirebaseAuthRepository(firebaseAuth, googleSignIn);
});

// ... existing auth state providers remain unchanged ...
```

#### 2. Update Firebase Config (Optional)
**File**: `lib/core/config/firebase_config.dart`
**Changes**: Remove Injectable annotation

```dart
import 'package:firebase_core/firebase_core.dart';
// Remove: import 'package:injectable/injectable.dart';

class FirebaseConfig {
  Future<void> initialize() async {
    // ... existing implementation ...
  }
}

// Remove @lazySingleton annotation
```

### Success Criteria:

#### Automated Verification:
- [ ] Auth providers compile: `flutter analyze`
- [ ] Auth repository instantiates correctly

#### Manual Verification:
- [ ] Auth functionality works (sign in/out)
- [ ] Firebase auth state streams properly

**Implementation Note**: Firebase and auth providers migrated. Next phase updates routing.

---

## Phase 5: Complete Routing Migration

### Overview
Remove the old GetIt-based AppRouter and ensure routerProvider is fully functional.

### Changes Required:

#### 1. Remove Old AppRouter
**File**: `lib/core/routing/app_router.dart`
**Changes**: Delete or mark as deprecated

**Decision**: Since routerProvider already exists and works, remove the old AppRouter entirely.

#### 2. Verify Router Provider
**File**: `lib/core/routing/router_provider.dart`
**Changes**: Ensure it works without GetIt dependencies

The router_provider.dart already exists and should work with the new auth providers.

#### 3. Update Main App
**File**: `lib/main.dart`
**Changes**: Ensure ProviderScope is properly configured

The main.dart already has ProviderScope and uses ConsumerWidget with router provider.

### Success Criteria:

#### Automated Verification:
- [ ] App builds without routing errors
- [ ] Navigation works correctly

#### Manual Verification:
- [ ] Auth-based routing works (login → dashboard)
- [ ] Public routes accessible when not authenticated
- [ ] Protected routes redirect properly

**Implementation Note**: Routing fully migrated to Riverpod. Next phase removes GetIt dependencies.

---

## Phase 6: Remove GetIt Dependencies

### Overview
Remove GetIt and Injectable from pubspec.yaml and clean up related files.

### Changes Required:

#### 1. Update pubspec.yaml
**File**: `pubspec.yaml`
**Changes**: Remove GetIt and Injectable dependencies

```yaml
dependencies:
  # Remove these:
  # get_it: ^8.2.0
  # injectable: ^2.5.2

  # Keep these:
  flutter_riverpod: ^2.6.1
  # ... other dependencies ...

dev_dependencies:
  # Remove these:
  # injectable_generator: ^2.6.2

  # Keep these:
  build_runner: ^2.4.0
  # ... other dev dependencies ...
```

#### 2. Remove DI Files
**Files to Remove**:
- `lib/core/di/injection.dart`
- `lib/core/di/injection.config.dart`
- `lib/core/di/core_module.dart`

#### 3. Update Main Files
**Files**: `lib/main.dart`, `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`
**Changes**: Remove GetIt initialization

```dart
// Remove these imports:
// import 'package:get_it/get_it.dart';
// import 'package:blueprint_app/core/di/injection.dart';

// Remove this code:
// await configureDependencies();

// Keep Firebase initialization:
final firebaseConfig = FirebaseConfig(); // No longer from getIt
await firebaseConfig.initialize();
```

### Success Criteria:

#### Automated Verification:
- [ ] Dependencies install: `flutter pub get`
- [ ] App builds successfully: `flutter build apk --flavor dev`
- [ ] No import errors

#### Manual Verification:
- [ ] App launches without GetIt errors
- [ ] Firebase initializes correctly
- [ ] All functionality works

**Implementation Note**: GetIt removed. Next phase updates remaining imports.

---

## Phase 7: Update Imports and References

### Overview
Find and update all remaining GetIt references throughout the codebase.

### Changes Required:

#### 1. Search for GetIt Usage
**Command**: `grep -r "getIt\|GetIt" lib/ --exclude-dir=build`

**Expected Results**:
- `lib/main.dart` - remove getIt references
- `lib/features/auth/presentation/providers/auth_providers.dart` - remove getIt import (already done)
- Any other files using getIt

#### 2. Update Firebase Config Import
**File**: `lib/main.dart` and flavor main files
**Changes**: Import FirebaseConfig directly

```dart
// Change from:
// import 'package:get_it/get_it.dart';
// final firebaseConfig = getIt<FirebaseConfig>();

// To:
import 'package:blueprint_app/core/config/firebase_config.dart';
final firebaseConfig = FirebaseConfig();
```

### Success Criteria:

#### Automated Verification:
- [ ] No compilation errors: `flutter analyze`
- [ ] All imports resolve correctly

#### Manual Verification:
- [ ] App runs without errors
- [ ] All features work as expected

**Implementation Note**: Imports updated. Next phase handles tests.

---

## Phase 8: Update Tests

### Overview
Update test files to work with the new Riverpod-only architecture.

### Changes Required:

#### 1. Update Auth Tests
**Files**: All test files in `test/features/auth/`
**Changes**: Update provider overrides to use new Riverpod providers

```dart
// Before (with GetIt bridging):
overrides: [
  authRepositoryProvider.overrideWithValue(mockRepository),
]

// After (direct Riverpod):
overrides: [
  firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
  googleSignInProvider.overrideWithValue(mockGoogleSignIn),
  // authRepositoryProvider will automatically use the mocks
]
```

#### 2. Update Test Helpers
**File**: `test/helpers/test_helpers.dart` or similar
**Changes**: Update to work with Riverpod providers

#### 3. Add Core Provider Tests (Optional but Recommended)
**File**: `test/core/providers/core_providers_test.dart`
**Changes**: Test the new core providers

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `flutter test`
- [ ] Test coverage maintained

#### Manual Verification:
- [ ] Auth tests work with new provider structure
- [ ] No test failures

**Implementation Note**: Tests updated. Final phase is verification.

---

## Phase 9: Final Verification

### Overview
Comprehensive testing to ensure the migration was successful and all functionality works.

### Changes Required:

#### 1. Full App Testing
**Commands**:
```bash
# Build all flavors
flutter build apk --flavor dev -t lib/main_dev.dart
flutter build apk --flavor staging -t lib/main_staging.dart
flutter build apk --flavor prod -t lib/main_prod.dart

# Run all tests
flutter test

# Run analysis
flutter analyze
```

#### 2. Manual Testing Checklist
- [ ] App launches on Android/iOS
- [ ] Firebase initializes without errors
- [ ] Sign in with Google works
- [ ] Sign in with Email/Password works
- [ ] Sign out works
- [ ] Auth state persists across app restarts
- [ ] Routing works correctly (auth guards, redirects)
- [ ] Network requests work (if any API calls exist)
- [ ] No console errors or warnings

#### 3. Performance Verification
- [ ] App startup time acceptable
- [ ] No memory leaks
- [ ] Provider rebuilds are efficient

### Success Criteria:

#### Automated Verification:
- [ ] All builds successful
- [ ] All tests pass
- [ ] No linting errors
- [ ] No analyzer warnings

#### Manual Verification:
- [ ] Complete feature verification checklist passes
- [ ] Performance acceptable
- [ ] User experience unchanged

**Implementation Note**: Migration complete and verified.

---

## Testing Strategy

### Unit Tests
- **Provider Tests**: Test core providers instantiate correctly
- **Auth Tests**: Verify auth flow with mocked Firebase services
- **Network Tests**: Test API client and network info providers

### Integration Tests
- **Auth Flow**: End-to-end sign in/sign out flow
- **Navigation**: Auth-based routing works correctly
- **Persistence**: Auth state survives app restarts

### Manual Testing
- **UI Testing**: All screens work as before
- **Error Handling**: Error states display correctly
- **Edge Cases**: Network failures, invalid credentials, etc.

---

## Performance Considerations

### Riverpod Benefits
- **Optimized Rebuilds**: Only dependent widgets rebuild
- **Automatic Disposal**: Providers dispose when no longer needed
- **Memory Efficient**: Better than manual singleton management

### Migration Impact
- **Bundle Size**: Removed get_it and injectable packages (~200KB smaller)
- **Runtime Performance**: Riverpod's provider system is optimized
- **Development Experience**: Better debugging and hot reload support

---

## Migration Notes

### Key Changes Made
1. **Provider Hierarchy**: Created comprehensive Riverpod provider tree
2. **Dependency Removal**: Eliminated GetIt and Injectable completely
3. **Auth Preservation**: Kept working auth feature intact
4. **Gradual Migration**: Each component migrated systematically

### Breaking Changes
- **None for Users**: UI and functionality unchanged
- **Internal Only**: Provider structure changed, but APIs remain the same

### Rollback Plan
If issues arise:
1. Restore GetIt dependencies to pubspec.yaml
2. Restore DI files from git
3. Revert main files to use GetIt initialization
4. Auth providers can bridge back to GetIt temporarily

### Future Improvements
- **Code Generation**: Consider Riverpod code generation for complex providers
- **Testing**: Expand integration tests for full auth flows
- **Monitoring**: Add Riverpod observer for debugging in development

---

## References

- Current auth implementation: `lib/features/auth/`
- Existing auth plan: `thoughts/shared/plans/2025-10-28-firebase-auth-riverpod-implementation.md`
- Riverpod documentation: https://riverpod.dev
- Flutter architecture: Clean Architecture with Riverpod

---

🤖 Generated for Riverpod migration planning
