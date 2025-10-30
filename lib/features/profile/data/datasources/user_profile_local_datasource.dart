import 'package:blueprint_app/features/profile/data/models/user_profile_model.dart';
import 'package:isar/isar.dart';

/// Local data source using Isar for offline storage
abstract class UserProfileLocalDataSource {
  /// Save profile to local database
  Future<void> saveProfile(UserProfileModel profile);

  /// Get profile by user ID
  Future<UserProfileModel?> getProfileByUserId(String userId);

  /// Get profile by profile ID
  Future<UserProfileModel?> getProfileById(String profileId);

  /// Update existing profile
  Future<void> updateProfile(UserProfileModel profile);

  /// Delete profile (soft delete)
  Future<void> deleteProfile(String profileId);

  /// Watch profile changes for reactive UI
  Stream<UserProfileModel?> watchProfileByUserId(String userId);

  /// Get all profiles (for debugging/admin)
  Future<List<UserProfileModel>> getAllProfiles();
}

class UserProfileLocalDataSourceImpl implements UserProfileLocalDataSource {
  UserProfileLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveProfile(UserProfileModel profile) async {
    await isar.writeTxn(() async {
      await isar.userProfileModels.put(profile);
    });
  }

  @override
  Future<UserProfileModel?> getProfileByUserId(String userId) async {
    return await isar.userProfileModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<UserProfileModel?> getProfileById(String profileId) async {
    return await isar.userProfileModels
        .where()
        .idEqualTo(profileId)
        .findFirst();
  }

  @override
  Future<void> updateProfile(UserProfileModel profile) async {
    final updated = profile.copyWith(
      modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      version: profile.version + 1,
    );

    await isar.writeTxn(() async {
      await isar.userProfileModels.put(updated);
    });
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    final profile = await getProfileById(profileId);
    if (profile != null) {
      final deleted = profile.copyWith(
        isDeleted: true,
        modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      );
      await isar.writeTxn(() async {
        await isar.userProfileModels.put(deleted);
      });
    }
  }

  @override
  Stream<UserProfileModel?> watchProfileByUserId(String userId) {
    return isar.userProfileModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((profiles) => profiles.isNotEmpty ? profiles.first : null);
  }

  @override
  Future<List<UserProfileModel>> getAllProfiles() async {
    return await isar.userProfileModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
  }
}
