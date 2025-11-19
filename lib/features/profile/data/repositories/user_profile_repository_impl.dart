import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:kairos/features/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:kairos/features/profile/data/models/user_profile_model.dart';
import 'package:kairos/features/profile/domain/entities/user_profile_entity.dart';
import 'package:kairos/features/profile/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  final UserProfileLocalDataSource localDataSource;
  final UserProfileRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  /// Check if device is online
  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<UserProfileEntity>> createProfile(
    UserProfileEntity profile,
  ) async {
    try {
      final model = UserProfileModel.fromEntity(profile);

      // 1. Save locally first (offline-first approach)
      await localDataSource.saveProfile(model);

      // 2. Try to sync to remote if online
      if (await _isOnline) {
        try {
          await remoteDataSource.saveProfile(model);
        } catch (remoteError) {
          // Log error but don't fail - profile is saved locally
          logger.i('Failed to sync profile to remote: $remoteError');
          // Could add to sync queue here for retry later
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create profile: $e'));
    }
  }

  @override
  Future<Result<UserProfileEntity?>> getProfileByUserId(String userId) async {
    try {
      final localProfile = await localDataSource.getProfileByUserId(userId);

      return Success(localProfile?.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get profile: $e'));
    }
  }

  @override
  Future<Result<UserProfileEntity?>> getProfileById(String profileId) async {
    try {
      // 1. Try to fetch from remote if online
      if (await _isOnline) {
        try {
          final remoteProfile = await remoteDataSource.getProfileById(profileId);
          if (remoteProfile != null) {
            // Save to local cache
            await localDataSource.saveProfile(remoteProfile);
            return Success(remoteProfile.toEntity());
          }
        } catch (remoteError) {
          logger.i(
            'Failed to fetch from remote, falling back to local: $remoteError',
          );
        }
      }

      // 2. Fallback to local
      final localProfile = await localDataSource.getProfileById(profileId);
      return Success(localProfile?.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get profile: $e'));
    }
  }

  @override
  Future<Result<UserProfileEntity>> updateProfile(
    UserProfileEntity profile,
  ) async {
    try {
      final model = UserProfileModel.fromEntity(profile);

      // 1. Update locally
      await localDataSource.updateProfile(model);

      // 2. Sync to remote if online
      if (await _isOnline) {
        try {
          await remoteDataSource.updateProfile(model);
        } catch (remoteError) {
          logger.i('Failed to sync update to remote: $remoteError');
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to update profile: $e'));
    }
  }

  @override
  Future<Result<void>> deleteProfile(String profileId) async {
    try {
      // 1. Delete locally (soft delete)
      await localDataSource.deleteProfile(profileId);

      // 2. Delete remotely if online
      if (await _isOnline) {
        try {
          await remoteDataSource.deleteProfile(profileId);
        } catch (remoteError) {
          logger.i('Failed to sync delete to remote: $remoteError');
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to delete profile: $e'));
    }
  }

  @override
  Stream<UserProfileEntity?> watchProfileByUserId(String userId) {
    return localDataSource.watchProfileByUserId(userId).map((model) => model?.toEntity());
  }

  @override
  Future<Result<void>> syncProfile() async {
    try {
      if (!await _isOnline) {
        return const Error(
          UnknownFailure(message: 'Cannot sync: device is offline'),
        );
      }

      // Get all local profiles and sync them
      final localProfiles = await localDataSource.getAllProfiles();

      for (final localProfile in localProfiles) {
        try {
          // Fetch remote version
          final remoteProfile = await remoteDataSource.getProfileByUserId(localProfile.userId);

          if (remoteProfile == null) {
            // No remote version, push local to remote
            await remoteDataSource.saveProfile(localProfile);
          } else {
            // Both exist - use simple last-write-wins strategy
            if (localProfile.modifiedAtMillis > remoteProfile.modifiedAtMillis) {
              // Local is newer, push to remote
              await remoteDataSource.updateProfile(localProfile);
            } else if (remoteProfile.modifiedAtMillis > localProfile.modifiedAtMillis) {
              // Remote is newer, pull to local
              await localDataSource.updateProfile(remoteProfile);
            }
            // If equal, they're in sync - do nothing
          }
        } catch (profileSyncError) {
          logger.i(
            'Failed to sync profile ${localProfile.id}: $profileSyncError',
          );
          // Continue with other profiles
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to sync profile: $e'));
    }
  }
}
