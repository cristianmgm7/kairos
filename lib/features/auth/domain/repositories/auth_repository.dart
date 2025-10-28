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
