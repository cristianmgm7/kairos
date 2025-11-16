import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:kairos/features/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:kairos/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:kairos/features/profile/domain/entities/user_profile_entity.dart';
import 'package:kairos/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:kairos/features/profile/domain/usecases/create_user_profile_usecase.dart';
import 'package:kairos/features/profile/domain/usecases/get_user_profile_usecase.dart';

/// Connectivity provider
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// Local data source provider
final userProfileLocalDataSourceProvider = Provider<UserProfileLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return UserProfileLocalDataSourceImpl(isar);
});

/// Remote data source provider
final userProfileRemoteDataSourceProvider = Provider<UserProfileRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserProfileRemoteDataSourceImpl(firestore);
});

/// Repository provider
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final localDataSource = ref.watch(userProfileLocalDataSourceProvider);
  final remoteDataSource = ref.watch(userProfileRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityProvider);

  return UserProfileRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    connectivity: connectivity,
  );
});

/// Current user profile stream provider (single source of truth)
final currentUserProfileProvider = StreamProvider<UserProfileEntity?>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return Stream.value(null);
  }

  return repository.watchProfileByUserId(userId);
});

/// Check if current user has completed profile
final hasCompletedProfileProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile != null,
    orElse: () => false,
  );
});

/// Create user profile use case provider
final createUserProfileUseCaseProvider = Provider<CreateUserProfileUseCase>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return CreateUserProfileUseCase(repository);
});

/// Get user profile use case provider
final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return GetUserProfileUseCase(repository);
});
