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
