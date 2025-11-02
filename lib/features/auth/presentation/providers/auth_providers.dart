import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:kairos/features/auth/domain/entities/user_entity.dart';
import 'package:kairos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AuthRepository provider (direct Riverpod, no GetIt bridging)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  return FirebaseAuthRepository(firebaseAuth, googleSignIn);
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
