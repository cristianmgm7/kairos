import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/profile/domain/entities/user_profile_entity.dart';

/// Repository interface for user profile operations
abstract class UserProfileRepository {
  /// Create a new user profile
  Future<Result<UserProfileEntity>> createProfile(UserProfileEntity profile);

  /// Get profile by user ID (Firebase Auth UID)
  Future<Result<UserProfileEntity?>> getProfileByUserId(String userId);

  /// Get profile by profile ID
  Future<Result<UserProfileEntity?>> getProfileById(String profileId);

  /// Update existing profile
  Future<Result<UserProfileEntity>> updateProfile(UserProfileEntity profile);

  /// Delete profile (soft delete)
  Future<Result<void>> deleteProfile(String profileId);

  /// Watch profile changes for a user (reactive stream)
  Stream<UserProfileEntity?> watchProfileByUserId(String userId);

  /// Manually trigger sync
  Future<Result<void>> syncProfile();
}










