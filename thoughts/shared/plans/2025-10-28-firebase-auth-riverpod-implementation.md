# Firebase Authentication with Riverpod Implementation Plan

## Overview

Implementing Firebase Authentication (Google Sign-In + Email/Password) using Riverpod for state management in a Flutter app following Clean Architecture. This implementation serves as a learning project to adopt Riverpod while maintaining the existing GetIt/Injectable infrastructure for core dependencies.

## Current State Analysis

### Existing Infrastructure:
- **DI System**: GetIt + Injectable ([lib/core/di/injection.dart](lib/core/di/injection.dart:1-21))
- **Routing**: GoRouter registered as GetIt singleton ([lib/core/routing/app_router.dart](lib/core/routing/app_router.dart:1-47))
- **Firebase**: Placeholder configuration exists but not initialized ([lib/core/config/firebase_config.dart](lib/core/config/firebase_config.dart:1-25))
- **Error Handling**: Custom Failure classes and Result type ([lib/core/errors/failures.dart](lib/core/errors/failures.dart:1-50), [lib/core/utils/result.dart](lib/core/utils/result.dart:1-47))
- **Architecture**: Clean separation with `/core` and `/features` directories
- **Testing**: Mockito setup with test helpers ([test/helpers/test_helpers.dart](test/helpers/test_helpers.dart:1-21))
- **Placeholder Pages**: Basic login/register pages exist in core/routing/pages (will be replaced)

### Key Discoveries:
- App uses GetIt/Injectable, NOT Riverpod (yet)
- No Firebase packages installed
- No Riverpod packages installed
- Clean Architecture structure ready for feature modules
- Custom Result type for error handling already established

### Architectural Decisions:
1. **Hybrid DI Approach** - Keep GetIt/Injectable for infrastructure (routing, network, Firebase initialization) while adopting Riverpod for feature-level state management starting with auth.
2. **Result-Based Error Handling** - Use existing `Result<T>` type (Success/Error) instead of throwing exceptions. This makes error handling explicit, type-safe, and eliminates hidden control flows.

## Desired End State

After implementation:
- Firebase Authentication fully configured for all flavors (dev/staging/prod)
- Users can sign in with Google and Email/Password
- Session persists across app restarts using Firebase's `authStateChanges()` stream
- GoRouter redirects reactively based on Riverpod auth state
- Auth feature follows Clean Architecture (data/domain/presentation)
- Riverpod providers manage auth state and business logic
- Comprehensive unit tests using Mockito + Riverpod testing utilities
- GetIt infrastructure remains for core services

**Verification:**
- User can sign in with Google on Android/iOS
- User can register/login with email/password
- App redirects to login when unauthenticated
- App redirects to home when authenticated
- Session persists after app restart
- All unit tests pass: `flutter test`
- No linting errors: `flutter analyze`

## What We're NOT Doing

- NOT migrating entire app to Riverpod (only auth feature)
- NOT removing GetIt/Injectable infrastructure
- NOT implementing social auth beyond Google (Apple, Facebook, etc.)
- NOT implementing email verification flow (can be added later)
- NOT implementing password reset UI (only repository method)
- NOT adding user profile management (out of scope)
- NOT implementing biometric authentication
- NOT adding refresh token logic (Firebase handles this)
- NOT creating integration tests (unit and widget tests only for now)

## Implementation Approach

### Strategy:
1. **Foundation First**: Add dependencies, configure Firebase for all flavors
2. **Domain Layer**: Define contracts (entities, repositories, use cases)
3. **Data Layer**: Implement Firebase Auth repository with Result-based error handling
4. **Riverpod Integration**: Create providers, controllers, and state management
5. **Router Integration**: Bridge Riverpod auth state with GoRouter
6. **UI Layer**: Build auth screens following design system
7. **Testing**: Comprehensive unit tests with mocks

### Why This Order:
- Firebase must be configured before any auth code can run
- Domain layer defines contracts that data layer implements
- Riverpod providers depend on repositories being implemented
- Router must be integrated before UI navigation works
- UI is built last to avoid rework
- Tests written alongside each layer

### Result-Based Error Handling Benefits:

**Why Result<T> instead of exceptions:**

1. **Explicit Error Handling** - Errors are part of the type signature, making them visible and forcing handling
   ```dart
   // Clear: caller knows this can fail
   Future<Result<UserEntity>> signInWithEmail(...);

   // Hidden: caller might not know this throws
   Future<UserEntity> signInWithEmail(...);
   ```

2. **Type Safety** - Compiler ensures all error cases are handled
   ```dart
   final result = await repository.signInWithEmail(...);
   result.when(
     success: (user) => // handle success,
     error: (failure) => // MUST handle error,
   );
   ```

3. **No Silent Failures** - Can't accidentally ignore errors
   ```dart
   // This won't compile - must handle both cases
   final user = await repository.signInWithEmail(...);

   // Must do this
   final result = await repository.signInWithEmail(...);
   final user = result.dataOrNull; // Explicit null handling
   ```

4. **Cleaner Control Flow** - No try-catch blocks cluttering business logic
   ```dart
   // Old way: nested try-catch
   try {
     final user = await repository.signInWithEmail(...);
     // success
   } catch (e) {
     // error
   }

   // New way: flat, readable
   final result = await repository.signInWithEmail(...);
   result.when(
     success: (user) => ...,
     error: (failure) => ...,
   );
   ```

5. **Consistent Error Types** - All errors return `Failure` subclasses, not mixed exceptions
   ```dart
   // Consistent: always returns AuthFailure
   Error(AuthFailure.invalidCredentials())
   Error(AuthFailure.network())

   // Inconsistent: different exception types
   throw InvalidCredentialsException();
   throw NetworkException();
   ```

6. **Better Testability** - Easy to test success and error paths
   ```dart
   // Mock returns Result, not throw
   when(repository.signIn(...))
     .thenAnswer((_) async => const Error(AuthFailure.network()));

   // vs
   when(repository.signIn(...))
     .thenThrow(NetworkException());
   ```

---

## Phase 1: Dependencies and Firebase Configuration

### Overview
Set up all required packages and configure Firebase for dev, staging, and production environments.

### Changes Required:

#### 1. Add Dependencies to pubspec.yaml
**File**: `pubspec.yaml`
**Changes**: Add Firebase, Riverpod, and Google Sign-In packages

```yaml
dependencies:
  # ... existing dependencies ...

  # State Management
  flutter_riverpod: ^2.6.1

  # Firebase
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.3
  google_sign_in: ^6.2.2

dev_dependencies:
  # ... existing dev dependencies ...

  # Firebase Tools (for FlutterFire CLI)
  # Run: dart pub global activate flutterfire_cli
```

#### 2. Firebase Project Setup (Manual Steps)
**Platform**: Firebase Console

**Steps to document in README:**
1. Create Firebase project at https://console.firebase.google.com
2. Add Android app (package: `com.blueprint.app.dev`, `com.blueprint.app.staging`, `com.blueprint.app`)
3. Add iOS app (bundle ID: `com.blueprint.app.dev`, `com.blueprint.app.staging`, `com.blueprint.app`)
4. Download `google-services.json` for Android (per flavor)
5. Download `GoogleService-Info.plist` for iOS (per flavor)
6. Enable Authentication providers: Google and Email/Password
7. Configure OAuth consent screen for Google Sign-In

#### 3. Configure FlutterFire CLI
**File**: Terminal commands
**Changes**: Generate Firebase options for all flavors

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure for dev flavor
flutterfire configure \
  --project=your-project-dev \
  --out=lib/core/config/firebase_options_dev.dart \
  --platforms=android,ios

# Configure for staging flavor
flutterfire configure \
  --project=your-project-staging \
  --out=lib/core/config/firebase_options_staging.dart \
  --platforms=android,ios

# Configure for production flavor
flutterfire configure \
  --project=your-project-prod \
  --out=lib/core/config/firebase_options_prod.dart \
  --platforms=android,ios
```

#### 4. Update Firebase Configuration
**File**: `lib/core/config/firebase_config.dart`
**Changes**: Implement actual Firebase initialization per flavor

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:blueprint_app/core/config/flavor_config.dart';
import 'package:blueprint_app/core/config/firebase_options_dev.dart' as dev;
import 'package:blueprint_app/core/config/firebase_options_staging.dart' as staging;
import 'package:blueprint_app/core/config/firebase_options_prod.dart' as prod;
import 'package:injectable/injectable.dart';

@lazySingleton
class FirebaseConfig {
  Future<void> initialize() async {
    final flavor = FlavorConfig.instance.flavor;

    switch (flavor) {
      case Flavor.dev:
        await Firebase.initializeApp(
          options: dev.DefaultFirebaseOptions.currentPlatform,
        );
        break;
      case Flavor.staging:
        await Firebase.initializeApp(
          options: staging.DefaultFirebaseOptions.currentPlatform,
        );
        break;
      case Flavor.prod:
        await Firebase.initializeApp(
          options: prod.DefaultFirebaseOptions.currentPlatform,
        );
        break;
    }
  }
}
```

#### 5. Initialize Firebase in main.dart
**File**: `lib/main.dart` (and main_dev.dart, main_staging.dart, main_prod.dart)
**Changes**: Initialize Firebase before running app

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:blueprint_app/core/config/firebase_config.dart';
// ... existing imports ...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  // Initialize Firebase
  final firebaseConfig = getIt<FirebaseConfig>();
  await firebaseConfig.initialize();

  runApp(const MyApp());
}
```

#### 6. Android Configuration
**File**: `android/app/build.gradle`
**Changes**: Add Google Services plugin

```gradle
// At the top of the file
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // Add this
}

// ... rest of the file ...
```

**File**: `android/build.gradle`
**Changes**: Add Google Services classpath

```gradle
buildscript {
    dependencies {
        // ... existing dependencies ...
        classpath 'com.google.gms:google-services:4.4.2'  // Add this
    }
}
```

**Files**: Place `google-services.json` files
- `android/app/src/dev/google-services.json`
- `android/app/src/staging/google-services.json`
- `android/app/src/prod/google-services.json` (or default location)

#### 7. iOS Configuration
**Files**: Place `GoogleService-Info.plist` files
- Use Xcode to add to appropriate targets/schemes per flavor
- Or use iOS build configurations to select the right plist

**File**: `ios/Runner/Info.plist`
**Changes**: Add URL schemes for Google Sign-In

```xml
<!-- Add inside <dict> -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- This will be from your GoogleService-Info.plist REVERSED_CLIENT_ID -->
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

### Success Criteria:

#### Automated Verification:
- [x] Dependencies install successfully: `flutter pub get`
- [x] No dependency conflicts
- [x] Code generation runs: `flutter packages pub run build_runner build --delete-conflicting-outputs`
- [ ] App builds for Android: `flutter build apk --flavor dev`
- [ ] App builds for iOS: `flutter build ios --flavor dev`
- [x] No analyzer errors: `flutter analyze`

#### Manual Verification:
- [ ] Firebase console shows all apps registered (dev, staging, prod)
- [ ] Google Sign-In OAuth consent screen is configured
- [ ] Email/Password auth is enabled in Firebase Console
- [ ] `google-services.json` files are in correct directories
- [ ] `GoogleService-Info.plist` files are added to iOS project
- [ ] App launches without Firebase initialization errors
- [ ] Firebase initialization completes successfully (check logs)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that Firebase is properly configured in the console and all plist/json files are correctly placed before proceeding to the next phase.

---

## Phase 2: Domain Layer - Entities, Repositories, and Use Cases

### Overview
Define the core business logic layer with entities, repository contracts, and use cases. This layer has no dependencies on external packages (Firebase, Riverpod).

### Changes Required:

#### 1. User Entity
**File**: `lib/features/auth/domain/entities/user_entity.dart`
**Changes**: Create immutable user entity

```dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  @override
  List<Object?> get props => [id, email, displayName, photoUrl];

  @override
  String toString() => 'UserEntity(id: $id, email: $email, displayName: $displayName)';
}
```

#### 2. Auth Repository Interface
**File**: `lib/features/auth/domain/repositories/auth_repository.dart`
**Changes**: Define repository contract using Result pattern

```dart
import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Stream of authentication state changes
  /// Emits UserEntity when authenticated, null when not
  Stream<UserEntity?> authStateChanges();

  /// Get current user synchronously (if available)
  UserEntity? get currentUser;

  /// Sign in with Google
  /// Returns Result<UserEntity> - Success with user or Error with failure
  Future<Result<UserEntity>> signInWithGoogle();

  /// Sign in with email and password
  /// Returns Result<UserEntity> - Success with user or Error with failure
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Register new user with email and password
  /// Returns Result<UserEntity> - Success with user or Error with failure
  Future<Result<UserEntity>> registerWithEmail({
    required String email,
    required String password,
  });

  /// Send password reset email
  /// Returns Result<void> - Success or Error with failure
  Future<Result<void>> sendPasswordReset(String email);

  /// Sign out current user
  /// Returns Result<void> - Success or Error with failure
  Future<Result<void>> signOut();
}
```

#### 3. Auth-Specific Exceptions (Internal Use Only)
**File**: `lib/features/auth/domain/exceptions/auth_exceptions.dart`
**Changes**: Define auth-specific exceptions for internal mapping in data layer

**Note**: These exceptions are used internally in the data layer to convert Firebase errors. They are caught and converted to `AuthFailure` within the repository, never thrown to external callers.

```dart
class AuthException implements Exception {
  const AuthException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException: $message${code != null ? " (code: $code)" : ""}';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([String? code])
      : super('Invalid email or password', code);
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException([String? code])
      : super('User not found', code);
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException([String? code])
      : super('Email already in use', code);
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException([String? code])
      : super('Password is too weak', code);
}

class NetworkException extends AuthException {
  const NetworkException([String? code])
      : super('Network error occurred', code);
}

class GoogleSignInCancelledException extends AuthException {
  const GoogleSignInCancelledException([String? code])
      : super('Google sign-in was cancelled', code);
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException(super.message, [super.code]);
}
```

#### 4. Auth Failure
**File**: `lib/features/auth/domain/failures/auth_failure.dart`
**Changes**: Create auth-specific failure for Result pattern

```dart
import 'package:blueprint_app/core/errors/failures.dart';

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });

  factory AuthFailure.invalidCredentials() => const AuthFailure(
        message: 'Invalid email or password',
        code: 401,
      );

  factory AuthFailure.userNotFound() => const AuthFailure(
        message: 'User not found',
        code: 404,
      );

  factory AuthFailure.emailInUse() => const AuthFailure(
        message: 'Email already in use',
        code: 409,
      );

  factory AuthFailure.weakPassword() => const AuthFailure(
        message: 'Password is too weak',
        code: 400,
      );

  factory AuthFailure.cancelled() => const AuthFailure(
        message: 'Sign-in was cancelled',
        code: 499,
      );

  factory AuthFailure.network() => const AuthFailure(
        message: 'Network error occurred',
        code: 503,
      );

  factory AuthFailure.unknown(String message) => AuthFailure(
        message: message,
        code: 500,
      );
}
```

#### 5. Use Cases (Optional but Recommended)
**File**: `lib/features/auth/domain/usecases/sign_in_with_google.dart`
**Changes**: Encapsulate Google sign-in use case with Result pattern

```dart
import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call() => _repository.signInWithGoogle();
}
```

**File**: `lib/features/auth/domain/usecases/sign_in_with_email.dart`

```dart
import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) =>
      _repository.signInWithEmail(email: email, password: password);
}
```

**File**: `lib/features/auth/domain/usecases/register_with_email.dart`

```dart
import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';

class RegisterWithEmail {
  const RegisterWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) =>
      _repository.registerWithEmail(email: email, password: password);
}
```

**File**: `lib/features/auth/domain/usecases/sign_out.dart`

```dart
import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
```

### Success Criteria:

#### Automated Verification:
- [x] All files compile without errors: `flutter analyze`
- [x] Domain layer has zero external dependencies (no Firebase, no Riverpod)
- [x] Code follows linting rules: `flutter analyze`

#### Manual Verification:
- [x] UserEntity is immutable and uses Equatable
- [x] AuthRepository interface is complete with all required methods
- [x] Exceptions are well-defined and cover common auth errors
- [x] Use cases provide clean abstraction over repository methods
- [x] No implementation details leak into domain layer

**Implementation Note**: The domain layer should be pure Dart with no Flutter/Firebase dependencies. After verification, proceed to implement the data layer.

---

## Phase 3: Data Layer - Firebase Repository Implementation

### Overview
Implement the AuthRepository using Firebase Authentication and Google Sign-In, with proper error handling and mapping.

### Changes Required:

#### 1. User Model (Data Transfer Object)
**File**: `lib/features/auth/data/models/user_model.dart`
**Changes**: Create model for Firebase User mapping

```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.email,
    super.displayName,
    super.photoUrl,
  });

  /// Create UserModel from Firebase User
  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  /// Convert to UserEntity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  /// Create from JSON (if needed for caching)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  /// Convert to JSON (if needed for caching)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
}
```

#### 2. Firebase Auth Repository Implementation
**File**: `lib/features/auth/data/repositories/firebase_auth_repository.dart`
**Changes**: Implement AuthRepository with Firebase using Result pattern

```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:blueprint_app/features/auth/domain/failures/auth_failure.dart';
import 'package:blueprint_app/features/auth/data/models/user_model.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._firebaseAuth, this._googleSignIn);

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<UserEntity?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserModel.fromFirebaseUser(firebaseUser).toEntity();
    });
  }

  @override
  UserEntity? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return UserModel.fromFirebaseUser(firebaseUser).toEntity();
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        return const Error(AuthFailure.cancelled());
      }

      // Obtain auth credentials
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return const Error(
          AuthFailure.unknown('Failed to sign in with Google'),
        );
      }

      final user = UserModel.fromFirebaseUser(userCredential.user!).toEntity();
      return Success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Error(_mapFirebaseException(e));
    } catch (e) {
      return Error(AuthFailure.unknown('Google sign-in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user == null) {
        return const Error(AuthFailure.unknown('Failed to sign in'));
      }

      final user = UserModel.fromFirebaseUser(userCredential.user!).toEntity();
      return Success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Error(_mapFirebaseException(e));
    } catch (e) {
      return Error(AuthFailure.unknown('Sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<UserEntity>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user == null) {
        return const Error(AuthFailure.unknown('Failed to create account'));
      }

      final user = UserModel.fromFirebaseUser(userCredential.user!).toEntity();
      return Success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Error(_mapFirebaseException(e));
    } catch (e) {
      return Error(AuthFailure.unknown('Registration failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const Success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Error(_mapFirebaseException(e));
    } catch (e) {
      return Error(AuthFailure.unknown('Password reset failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Success(null);
    } catch (e) {
      return Error(AuthFailure.unknown('Sign out failed: ${e.toString()}'));
    }
  }

  /// Map Firebase Auth exceptions to AuthFailure
  AuthFailure _mapFirebaseException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.invalidCredentials();
      case 'email-already-in-use':
        return AuthFailure.emailInUse();
      case 'weak-password':
        return AuthFailure.weakPassword();
      case 'network-request-failed':
        return AuthFailure.network();
      case 'user-disabled':
        return const AuthFailure(message: 'This account has been disabled');
      case 'too-many-requests':
        return const AuthFailure(
          message: 'Too many attempts. Please try again later',
        );
      case 'operation-not-allowed':
        return const AuthFailure(message: 'This operation is not allowed');
      default:
        return AuthFailure.unknown(e.message ?? 'Authentication failed');
    }
  }
}
```

#### 3. Register Repository with GetIt
**File**: `lib/core/di/core_module.dart`
**Changes**: Add Firebase and Auth providers to GetIt

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:blueprint_app/features/auth/data/repositories/firebase_auth_repository.dart';
// ... existing imports ...

@module
abstract class CoreModule {
  // ... existing providers ...

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn(
        scopes: ['email', 'profile'],
      );

  @lazySingleton
  AuthRepository authRepository(
    FirebaseAuth firebaseAuth,
    GoogleSignIn googleSignIn,
  ) =>
      FirebaseAuthRepository(firebaseAuth, googleSignIn);
}
```

### Success Criteria:

#### Automated Verification:
- [x] Code compiles without errors: `flutter analyze`
- [x] Repository implements all interface methods
- [x] No linting errors: `flutter analyze`
- [x] Code generation runs successfully: `flutter packages pub run build_runner build --delete-conflicting-outputs`

#### Manual Verification:
- [x] FirebaseAuth and GoogleSignIn are registered in GetIt
- [x] All Firebase exception codes are properly mapped
- [x] UserModel correctly converts Firebase User to UserEntity
- [x] Error messages are user-friendly
- [x] Repository methods handle null cases properly

**Implementation Note**: The data layer bridges Firebase with our domain. After verification, we'll create Riverpod providers to expose this to the UI.

---

## Phase 4: Riverpod Providers and State Management

### Overview
Create Riverpod providers to expose auth state and actions to the UI. This is where Riverpod is introduced to the app for the first time.

### Changes Required:

#### 1. Auth Providers (Core)
**File**: `lib/features/auth/presentation/providers/auth_providers.dart`
**Changes**: Create fundamental auth providers

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blueprint_app/core/di/injection.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';

/// Provider for AuthRepository (bridging GetIt to Riverpod)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return getIt<AuthRepository>();
});

/// Stream provider for authentication state
/// This is the single source of truth for auth state in the app
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

/// Provider to get current user synchronously
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});
```

#### 2. Auth Controller (State Notifier)
**File**: `lib/features/auth/presentation/providers/auth_controller.dart`
**Changes**: Create controller for auth actions using Result pattern

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_providers.dart';

/// State for auth operations (loading, error, etc.)
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  AuthState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller for authentication actions
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.signInWithGoogle();

    result.when(
      success: (_) {
        // Auth state stream will handle navigation
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.registerWithEmail(
      email: email,
      password: password,
    );

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.signOut();

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for auth controller
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
```

### Success Criteria:

#### Automated Verification:
- [x] Code compiles without errors: `flutter analyze`
- [x] All providers are properly typed
- [x] No linting errors: `flutter analyze`

#### Manual Verification:
- [x] authStateProvider correctly streams authentication state
- [x] authControllerProvider exposes all auth actions
- [x] Error handling is comprehensive
- [x] Loading states are properly managed
- [x] GetIt AuthRepository is bridged to Riverpod successfully

**Implementation Note**: Providers are now ready. Next, we'll integrate them with the router for reactive navigation.

---

## Phase 5: Router Integration with Riverpod

### Overview
Refactor the router to reactively respond to authentication state changes using Riverpod's ProviderScope and router provider.

### Changes Required:

#### 1. Create Router Provider
**File**: `lib/core/routing/router_provider.dart`
**Changes**: Create Riverpod provider for GoRouter

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blueprint_app/core/routing/app_routes.dart';
import 'package:blueprint_app/core/routing/pages/splash_page.dart';
import 'package:blueprint_app/core/routing/pages/onboarding_page.dart';
import 'package:blueprint_app/core/routing/pages/error_page.dart';
import 'package:blueprint_app/features/auth/presentation/screens/login_screen.dart';
import 'package:blueprint_app/features/auth/presentation/screens/register_screen.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:blueprint_app/core/routing/pages/dashboard_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isLoading = authState.isLoading;

      // Show splash while loading auth state
      if (isLoading && state.matchedLocation == AppRoutes.splash) {
        return null;
      }

      // Public routes (no auth required)
      final publicRoutes = [
        AppRoutes.splash,
        AppRoutes.onboarding,
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

      // If authenticated and on splash, go to dashboard
      if (isAuthenticated && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.dashboard;
      }

      return null;
    },
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
```

#### 2. Update Main App to Use ProviderScope
**File**: `lib/main.dart`
**Changes**: Wrap app with ProviderScope and use router provider

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blueprint_app/core/di/injection.dart';
import 'package:blueprint_app/core/config/firebase_config.dart';
import 'package:blueprint_app/core/routing/router_provider.dart';
import 'package:blueprint_app/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetIt dependency injection
  await configureDependencies();

  // Initialize Firebase
  final firebaseConfig = getIt<FirebaseConfig>();
  await firebaseConfig.initialize();

  runApp(
    // Wrap with ProviderScope to enable Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Blueprint App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
```

#### 3. Update Other Main Files
**File**: `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`
**Changes**: Apply same ProviderScope wrapper pattern to all flavor entry points

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blueprint_app/core/config/flavor_config.dart';
import 'package:blueprint_app/core/di/injection.dart';
import 'package:blueprint_app/core/config/firebase_config.dart';
import 'package:blueprint_app/main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure flavor (dev/staging/prod)
  FlavorConfig(
    flavor: Flavor.dev, // Change per file
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    enableLogging: true,
    apiTimeout: 30000,
  );

  // Initialize GetIt
  await configureDependencies();

  // Initialize Firebase
  final firebaseConfig = getIt<FirebaseConfig>();
  await firebaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

#### 4. Optional: Keep AppRouter for Backward Compatibility
**File**: `lib/core/routing/app_router.dart`
**Changes**: Mark as deprecated or remove if not needed

```dart
// Option A: Mark deprecated
@Deprecated('Use routerProvider from router_provider.dart instead')
@lazySingleton
class AppRouter {
  // ... existing code ...
}

// Option B: Remove entirely if no longer needed
```

### Success Criteria:

#### Automated Verification:
- [x] App compiles without errors: `flutter analyze`
- [x] No linting errors: `flutter analyze`
- [ ] App builds successfully: `flutter build apk --flavor dev`

#### Manual Verification:
- [ ] App launches and shows splash screen
- [ ] Unauthenticated users are redirected to login
- [ ] Login page is accessible
- [ ] Router updates reactively when auth state changes
- [ ] No navigation loops or errors in console
- [x] ProviderScope is properly wrapping the app

**Implementation Note**: Router now reactively responds to auth state. Next, we'll build the UI screens.

---

## Phase 6: Authentication UI Screens

### Overview
Build login and register screens using the existing design system and Riverpod for state management.

### Changes Required:

#### 1. Login Screen
**File**: `lib/features/auth/presentation/screens/login_screen.dart`
**Changes**: Create full-featured login screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blueprint_app/core/routing/app_routes.dart';
import 'package:blueprint_app/core/widgets/app_button.dart';
import 'package:blueprint_app/core/widgets/app_text_field.dart';
import 'package:blueprint_app/core/theme/app_spacing.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:blueprint_app/features/auth/presentation/widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEmailSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  void _handleGoogleSignIn() {
    ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Show error if present
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Email field
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Password field
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Sign in button
                AppButton(
                  onPressed: authState.isLoading ? null : _handleEmailSignIn,
                  isLoading: authState.isLoading,
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: AppSpacing.md),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Google sign in
                GoogleSignInButton(
                  onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 2. Register Screen
**File**: `lib/features/auth/presentation/screens/register_screen.dart`
**Changes**: Create registration screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blueprint_app/core/widgets/app_button.dart';
import 'package:blueprint_app/core/widgets/app_text_field.dart';
import 'package:blueprint_app/core/theme/app_spacing.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:blueprint_app/features/auth/presentation/widgets/google_sign_in_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).registerWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  void _handleGoogleSignIn() {
    ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Icon(
                  Icons.person_add_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Get Started',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Create your account',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                AppButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  isLoading: authState.isLoading,
                  child: const Text('Create Account'),
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                GoogleSignInButton(
                  onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 3. Google Sign-In Button Widget
**File**: `lib/features/auth/presentation/widgets/google_sign_in_button.dart`
**Changes**: Reusable Google sign-in button

```dart
import 'package:flutter/material.dart';
import 'package:blueprint_app/core/theme/app_spacing.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google_logo.png', // Add Google logo asset
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('Sign in with Google'),
              ],
            ),
    );
  }
}
```

#### 4. Update Dashboard to Show User Info and Sign Out
**File**: `lib/core/routing/pages/dashboard_page.dart`
**Changes**: Add user info and sign-out button

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user?.photoUrl != null)
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
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              if (user?.displayName != null)
                Text(
                  user!.displayName!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (user?.email != null)
                Text(
                  user!.email!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [x] All screens compile without errors: `flutter analyze`
- [x] No linting errors: `flutter analyze`
- [ ] App builds successfully: `flutter build apk --flavor dev`

#### Manual Verification:
- [ ] Login screen displays correctly with all fields
- [ ] Register screen displays correctly with password confirmation
- [ ] Form validation works (email format, password length, password match)
- [ ] Error messages display in SnackBar
- [ ] Loading states show during auth operations
- [ ] Google Sign-In button displays properly
- [ ] Dashboard shows user information after login
- [ ] Sign-out button works and redirects to login

**Implementation Note**: UI is now complete. Next phase will add comprehensive unit tests.

---

## Phase 7: Unit Tests

### Overview
Write comprehensive unit tests for all layers using Mockito and Riverpod's testing utilities.

### Changes Required:

#### 1. Test Helpers for Auth
**File**: `test/features/auth/helpers/auth_test_helpers.dart`
**Changes**: Create test utilities and mocks

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';

// Generate mocks
@GenerateMocks([
  AuthRepository,
  firebase_auth.FirebaseAuth,
  firebase_auth.UserCredential,
  firebase_auth.User,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
])
void main() {}

// Test data
const testUserEntity = UserEntity(
  id: 'test-uid-123',
  email: 'test@example.com',
  displayName: 'Test User',
  photoUrl: 'https://example.com/photo.jpg',
);

const testUserEntityNoPhoto = UserEntity(
  id: 'test-uid-456',
  email: 'test2@example.com',
  displayName: 'Test User 2',
);
```

Run code generation:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### 2. Domain Layer Tests - User Entity
**File**: `test/features/auth/domain/entities/user_entity_test.dart`
**Changes**: Test entity equality and props

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('should be equal when all properties match', () {
      const user1 = UserEntity(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test',
        photoUrl: 'http://example.com/photo.jpg',
      );

      const user2 = UserEntity(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test',
        photoUrl: 'http://example.com/photo.jpg',
      );

      expect(user1, equals(user2));
    });

    test('should not be equal when id differs', () {
      const user1 = UserEntity(id: '123', email: 'test@example.com');
      const user2 = UserEntity(id: '456', email: 'test@example.com');

      expect(user1, isNot(equals(user2)));
    });

    test('should handle null optional fields', () {
      const user = UserEntity(id: '123');

      expect(user.email, isNull);
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
    });

    test('toString should include user information', () {
      const user = UserEntity(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      expect(
        user.toString(),
        contains('123'),
      );
      expect(
        user.toString(),
        contains('test@example.com'),
      );
    });
  });
}
```

#### 3. Data Layer Tests - Firebase Repository
**File**: `test/features/auth/data/repositories/firebase_auth_repository_test.dart`
**Changes**: Test repository implementation

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:blueprint_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:blueprint_app/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import '../../helpers/auth_test_helpers.mocks.dart';

void main() {
  late FirebaseAuthRepository repository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();

    repository = FirebaseAuthRepository(mockFirebaseAuth, mockGoogleSignIn);

    // Default mock user setup
    when(mockUser.uid).thenReturn('test-uid');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.displayName).thenReturn('Test User');
    when(mockUser.photoURL).thenReturn('http://example.com/photo.jpg');
  });

  group('signInWithEmail', () {
    const email = 'test@example.com';
    const password = 'password123';

    test('should return Success<UserEntity> on successful sign in', () async {
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      final result = await repository.signInWithEmail(
        email: email,
        password: password,
      );

      expect(result, isA<Success<UserEntity>>());
      expect(result.isSuccess, true);

      final user = result.dataOrNull!;
      expect(user.id, 'test-uid');
      expect(user.email, email);

      verify(mockFirebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      )).called(1);
    });

    test('should return Error with AuthFailure.invalidCredentials on wrong password', () async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        firebase_auth.FirebaseAuthException(code: 'wrong-password'),
      );

      final result = await repository.signInWithEmail(
        email: email,
        password: password,
      );

      expect(result, isA<Error<UserEntity>>());
      expect(result.isError, true);

      final failure = result.failureOrNull!;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('Invalid email or password'));
    });

    test('should return Error with AuthFailure.userNotFound when user not found', () async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        firebase_auth.FirebaseAuthException(code: 'user-not-found'),
      );

      final result = await repository.signInWithEmail(
        email: email,
        password: password,
      );

      expect(result, isA<Error<UserEntity>>());

      final failure = result.failureOrNull!;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('User not found'));
    });
  });

  group('registerWithEmail', () {
    const email = 'newuser@example.com';
    const password = 'password123';

    test('should return Success<UserEntity> on successful registration', () async {
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      final result = await repository.registerWithEmail(
        email: email,
        password: password,
      );

      expect(result, isA<Success<UserEntity>>());
      expect(result.isSuccess, true);

      verify(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      )).called(1);
    });

    test('should return Error with AuthFailure.emailInUse when email exists', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        firebase_auth.FirebaseAuthException(code: 'email-already-in-use'),
      );

      final result = await repository.registerWithEmail(
        email: email,
        password: password,
      );

      expect(result, isA<Error<UserEntity>>());

      final failure = result.failureOrNull!;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('Email already in use'));
    });

    test('should return Error with AuthFailure.weakPassword for weak password', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        firebase_auth.FirebaseAuthException(code: 'weak-password'),
      );

      final result = await repository.registerWithEmail(
        email: email,
        password: password,
      );

      expect(result, isA<Error<UserEntity>>());

      final failure = result.failureOrNull!;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('Password is too weak'));
    });
  });

  group('signOut', () {
    test('should call signOut on both Firebase and Google', () async {
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await repository.signOut();

      verify(mockFirebaseAuth.signOut()).called(1);
      verify(mockGoogleSignIn.signOut()).called(1);
    });
  });

  group('authStateChanges', () {
    test('should emit UserEntity when user is signed in', () {
      when(mockFirebaseAuth.authStateChanges()).thenAnswer(
        (_) => Stream.value(mockUser),
      );

      expect(
        repository.authStateChanges(),
        emits(isA<UserEntity>()),
      );
    });

    test('should emit null when user is signed out', () {
      when(mockFirebaseAuth.authStateChanges()).thenAnswer(
        (_) => Stream.value(null),
      );

      expect(
        repository.authStateChanges(),
        emits(null),
      );
    });
  });
}
```

#### 4. Riverpod Provider Tests
**File**: `test/features/auth/presentation/providers/auth_controller_test.dart`
**Changes**: Test auth controller

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:blueprint_app/features/auth/domain/exceptions/auth_exceptions.dart';
import '../../helpers/auth_test_helpers.dart';
import '../../helpers/auth_test_helpers.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController - signInWithEmail', () {
    test('should set loading state then success on successful sign in',
        () async {
      when(mockRepository.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Success(testUserEntity));

      final controller = container.read(authControllerProvider.notifier);
      final states = <AuthState>[];

      container.listen(
        authControllerProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'password',
      );

      expect(states[0].isLoading, false); // Initial state
      expect(states[1].isLoading, true); // Loading state
      expect(states[2].isLoading, false); // Success state
      expect(states[2].error, isNull);
    });

    test('should set error state on authentication failure', () async {
      when(mockRepository.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Error(AuthFailure.invalidCredentials()));

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithEmail(
        email: 'test@example.com',
        password: 'wrong',
      );

      final state = container.read(authControllerProvider);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
      expect(state.error, contains('Invalid email or password'));
    });
  });

  group('AuthController - signInWithGoogle', () {
    test('should handle successful Google sign in', () async {
      when(mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Success(testUserEntity));

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithGoogle();

      final state = container.read(authControllerProvider);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should handle cancelled Google sign in gracefully', () async {
      when(mockRepository.signInWithGoogle())
          .thenAnswer((_) async => const Error(AuthFailure.cancelled()));

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithGoogle();

      final state = container.read(authControllerProvider);
      expect(state.isLoading, false);
      expect(state.error, contains('cancelled')); // Error message for cancellation
    });
  });

  group('AuthController - signOut', () {
    test('should successfully sign out', () async {
      when(mockRepository.signOut())
          .thenAnswer((_) async => const Success(null));

      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();

      final state = container.read(authControllerProvider);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(mockRepository.signOut()).called(1);
    });
  });
}
```

#### 5. Widget Tests (Optional but Recommended)
**File**: `test/features/auth/presentation/screens/login_screen_test.dart`
**Changes**: Test login screen widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:blueprint_app/features/auth/presentation/screens/login_screen.dart';
import 'package:blueprint_app/features/auth/presentation/providers/auth_providers.dart';
import '../../helpers/auth_test_helpers.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    when(mockRepository.authStateChanges()).thenAnswer(
      (_) => Stream.value(null),
    );
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('should display all UI elements', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Email and password
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
    });

    testWidgets('should validate email field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should validate password field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter email
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Tap sign in without password
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should call signInWithEmail on valid form submission',
        (tester) async {
      when(mockRepository.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Success(testUserEntity));

      await tester.pumpWidget(createTestWidget());

      // Enter valid credentials
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');

      // Submit form
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      verify(mockRepository.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });
  });
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `flutter test`
- [ ] Test coverage is generated: `flutter test --coverage`
- [ ] No test failures or errors
- [ ] Code analysis passes: `flutter analyze`
- [ ] Mock generation successful: `flutter packages pub run build_runner build --delete-conflicting-outputs`

#### Manual Verification:
- [ ] Domain layer tests cover entity equality
- [ ] Data layer tests cover all auth methods and exception mapping
- [ ] Provider tests verify loading/error/success states
- [ ] Widget tests verify UI behavior and validation
- [ ] All edge cases are tested (cancellation, network errors, etc.)
- [ ] Tests are independent and repeatable

**Implementation Note**: Comprehensive test suite is complete. The feature is now production-ready.

---

## Phase 8: Documentation and Final Polish

### Overview
Add documentation, update README, and ensure the implementation is complete and maintainable.

### Changes Required:

#### 1. Feature README
**File**: `lib/features/auth/README.md`
**Changes**: Document the auth feature architecture

```markdown
# Authentication Feature

Firebase Authentication implementation using Riverpod for state management.

## Architecture

This feature follows Clean Architecture with three layers:

### Domain Layer (`domain/`)
- **Entities**: `UserEntity` - immutable user data
- **Repositories**: `AuthRepository` - auth operations contract
- **Exceptions**: Auth-specific exceptions
- **Use Cases**: (Optional) Individual auth operations

### Data Layer (`data/`)
- **Models**: `UserModel` - Firebase User mapping
- **Repositories**: `FirebaseAuthRepository` - Firebase implementation

### Presentation Layer (`presentation/`)
- **Providers**: Riverpod providers for auth state
- **Controllers**: `AuthController` - auth action handlers
- **Screens**: Login and Register screens
- **Widgets**: Reusable auth UI components

## Usage

### Check Authentication Status

```dart
final authState = ref.watch(authStateProvider);
final isAuthenticated = ref.watch(isAuthenticatedProvider);
final currentUser = ref.watch(currentUserProvider);
```

### Sign In with Email

```dart
ref.read(authControllerProvider.notifier).signInWithEmail(
  email: 'user@example.com',
  password: 'password123',
);
```

### Sign In with Google

```dart
ref.read(authControllerProvider.notifier).signInWithGoogle();
```

### Sign Out

```dart
ref.read(authControllerProvider.notifier).signOut();
```

### Listen to Auth State Changes

```dart
ref.listen<AsyncValue<UserEntity?>>(authStateProvider, (previous, next) {
  next.when(
    data: (user) {
      if (user != null) {
        print('User signed in: ${user.email}');
      } else {
        print('User signed out');
      }
    },
    loading: () => print('Loading...'),
    error: (error, stack) => print('Error: $error'),
  );
});
```

## Testing

Run tests:
```bash
flutter test test/features/auth/
```

Generate test coverage:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Firebase Setup

See main README for Firebase configuration instructions.
```

#### 2. Update Main README
**File**: `README.md`
**Changes**: Add Firebase setup instructions

```markdown
# Blueprint App

A production-ready Flutter application with Firebase Authentication.

## Features

- ✅ Firebase Authentication (Google + Email/Password)
- ✅ Clean Architecture (Data/Domain/Presentation)
- ✅ Riverpod State Management
- ✅ GoRouter with Auth Guards
- ✅ Multi-flavor Support (Dev/Staging/Prod)
- ✅ Comprehensive Testing

## Getting Started

### Prerequisites

- Flutter SDK >= 3.27.0
- Dart SDK >= 3.6.0
- Firebase project (see setup below)
- Xcode (for iOS)
- Android Studio (for Android)

### Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project (or use existing)
   - Create three projects for flavors: `app-dev`, `app-staging`, `app-prod`

2. **Enable Authentication**
   - In each Firebase project, go to Authentication
   - Enable Email/Password provider
   - Enable Google provider
   - Configure OAuth consent screen

3. **Install FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. **Configure Firebase for Each Flavor**
   ```bash
   # Dev
   flutterfire configure \
     --project=your-app-dev \
     --out=lib/core/config/firebase_options_dev.dart \
     --platforms=android,ios

   # Staging
   flutterfire configure \
     --project=your-app-staging \
     --out=lib/core/config/firebase_options_staging.dart \
     --platforms=android,ios

   # Production
   flutterfire configure \
     --project=your-app-prod \
     --out=lib/core/config/firebase_options_prod.dart \
     --platforms=android,ios
   ```

5. **Android Setup**
   - Place `google-services.json` files in:
     - `android/app/src/dev/google-services.json`
     - `android/app/src/staging/google-services.json`
     - `android/app/src/prod/google-services.json`

6. **iOS Setup**
   - Add `GoogleService-Info.plist` files to Xcode per flavor
   - Update `Info.plist` with Google Sign-In URL scheme (see URL in plist)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd kairos
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   # Dev flavor
   flutter run --flavor dev -t lib/main_dev.dart

   # Staging
   flutter run --flavor staging -t lib/main_staging.dart

   # Production
   flutter run --flavor prod -t lib/main_prod.dart
   ```

## Architecture

This project follows **Clean Architecture** with feature-based organization:

```
lib/
├── core/              # Shared infrastructure
│   ├── config/        # App configuration (Firebase, flavors)
│   ├── di/            # Dependency injection (GetIt)
│   ├── routing/       # Navigation (GoRouter + Riverpod)
│   ├── theme/         # App theming
│   └── widgets/       # Shared widgets
└── features/          # Feature modules
    └─�� auth/          # Authentication feature
        ├── data/      # Data sources and repositories
        ├── domain/    # Business logic and entities
        └── presentation/  # UI and Riverpod providers
```

### State Management Strategy

- **GetIt + Injectable**: Infrastructure dependencies (router, network, Firebase)
- **Riverpod**: Feature-level state management (auth, etc.)

This hybrid approach maintains stability while adopting modern patterns.

## Testing

Run all tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/features/auth/domain/entities/user_entity_test.dart
```

Generate coverage:
```bash
flutter test --coverage
```

## Building for Release

### Android
```bash
flutter build apk --flavor prod -t lib/main_prod.dart --release
flutter build appbundle --flavor prod -t lib/main_prod.dart --release
```

### iOS
```bash
flutter build ios --flavor prod -t lib/main_prod.dart --release
```

## Code Generation

When modifying Injectable or Mockito code:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Linting

This project uses `very_good_analysis` for linting:
```bash
flutter analyze
```

## Contributing

1. Follow Clean Architecture principles
2. Write tests for new features
3. Run `flutter analyze` before committing
4. Use conventional commits

## License

[Your License Here]
```

#### 3. Add CHANGELOG Entry
**File**: `CHANGELOG.md`
**Changes**: Document the implementation

```markdown
# Changelog

## [Unreleased]

### Added
- Firebase Authentication with Google Sign-In and Email/Password
- Riverpod state management for auth feature
- Reactive routing with GoRouter and Riverpod
- Clean Architecture implementation for auth feature
- Comprehensive unit and widget tests
- Multi-flavor Firebase configuration (dev/staging/prod)
- User profile display on dashboard
- Auth state persistence across app restarts

### Changed
- Migrated from pure GetIt to hybrid GetIt + Riverpod architecture
- Updated router to use Riverpod providers
- Enhanced main.dart with ProviderScope wrapper

### Security
- Implemented secure authentication flow
- Added proper error handling for auth exceptions
- Protected routes with auth guards
```

### Success Criteria:

#### Automated Verification:
- [ ] README markdown renders correctly
- [ ] All documentation links are valid
- [ ] Code examples in docs compile
- [ ] No broken internal links

#### Manual Verification:
- [ ] README clearly explains Firebase setup
- [ ] Architecture diagram is accurate
- [ ] Feature README documents all providers
- [ ] CHANGELOG is up to date
- [ ] Code examples are correct and tested
- [ ] Installation instructions work from scratch

**Implementation Note**: Documentation is complete. The feature is production-ready and maintainable.

---

## Testing Strategy

### Unit Tests

**Repository Tests:**
- Mock Firebase Auth and Google Sign-In
- Test all auth methods (sign in, register, sign out)
- Verify exception mapping from Firebase codes
- Test auth state stream

**Provider Tests:**
- Use Riverpod's testing utilities
- Override authRepositoryProvider with mock
- Test loading/success/error states
- Verify state transitions

**Domain Tests:**
- Test entity equality
- Verify Equatable implementation
- Test exception creation

### Widget Tests

**Login Screen:**
- Verify UI elements render
- Test form validation
- Verify email/password validation
- Test error display in SnackBar
- Verify navigation to register

**Register Screen:**
- Test password confirmation validation
- Verify form submission
- Test error handling

**Dashboard:**
- Verify user info display
- Test sign-out button

### Integration Tests (Future)
- End-to-end auth flow
- Session persistence
- Navigation after auth state changes

---

## Performance Considerations

### Firebase Optimization
- Use `authStateChanges()` stream (single subscription)
- Avoid frequent auth state checks
- Cache currentUser when appropriate

### Riverpod Best Practices
- Use `autoDispose` for screen-specific providers
- Keep global providers minimal (only auth state)
- Avoid unnecessary rebuilds with proper provider selection

### Memory Management
- Controllers dispose properly
- TextEditingControllers are disposed
- Stream subscriptions are managed by Riverpod

---

## Migration Notes

### From GetIt-Only to Hybrid GetIt + Riverpod

**What Changed:**
- App wrapped with `ProviderScope`
- Router migrated to `routerProvider` (Riverpod)
- Auth state managed by Riverpod providers
- Main.dart now uses `ConsumerWidget`

**What Stayed the Same:**
- GetIt infrastructure (Dio, Logger, Connectivity)
- Core modules still registered with Injectable
- Firebase instances registered via GetIt
- Existing features unaffected

**Bridge Pattern:**
```dart
// AuthRepository registered in GetIt (data layer)
@lazySingleton
AuthRepository authRepository(...) => FirebaseAuthRepository(...);

// Bridged to Riverpod (presentation layer)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return getIt<AuthRepository>();
});
```

This allows gradual migration of features to Riverpod.

---

## References

- Original design document: [Your design file path]
- Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- Riverpod documentation: https://riverpod.dev
- Firebase Auth: https://firebase.google.com/docs/auth
- GoRouter: https://pub.dev/packages/go_router

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
