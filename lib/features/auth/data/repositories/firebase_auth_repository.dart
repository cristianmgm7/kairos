import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/data/models/user_model.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/failures/auth_failure.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';


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
        return Error(AuthFailure.cancelled());
      }

      // Obtain auth credentials
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return Error(
          AuthFailure.unknown('Failed to sign in with Google'),
        );
      }

      final user = UserModel.fromFirebaseUser(userCredential.user!).toEntity();
      return Success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Error(_mapFirebaseException(e));
    } catch (e) {
      return Error(AuthFailure.unknown('Google sign-in failed: $e'));
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
        return Error(AuthFailure.unknown('Failed to sign in'));
      }

      final user = UserModel.fromFirebaseUser(userCredential.user!).toEntity();
      return Success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Error(_mapFirebaseException(e));
    } catch (e) {
      return Error(AuthFailure.unknown('Sign in failed: $e'));
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
        return Error(AuthFailure.unknown('Failed to create account'));
      }

      final user = UserModel.fromFirebaseUser(userCredential.user!).toEntity();
      return Success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Error(_mapFirebaseException(e));
    } catch (e) {
      return Error(AuthFailure.unknown('Registration failed: $e'));
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
      return Error(AuthFailure.unknown('Password reset failed: $e'));
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
      return Error(AuthFailure.unknown('Sign out failed: $e'));
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
