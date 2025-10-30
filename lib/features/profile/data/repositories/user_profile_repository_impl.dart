import 'package:blueprint_app/core/errors/failures.dart';
import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/profile/data/models/user_profile_model.dart';
import 'package:blueprint_app/features/profile/domain/entities/user_profile_entity.dart';
import 'package:blueprint_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:datum/datum.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final DatumManager<UserProfileModel> datumManager;

  UserProfileRepositoryImpl(this.datumManager);

  @override
  Future<Result<UserProfileEntity>> createProfile(
    UserProfileEntity profile,
  ) async {
    try {
      final model = UserProfileModel.fromEntity(profile);
      final created = await datumManager.create(model);
      return Success(created.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create profile: $e'));
    }
  }

  @override
  Future<Result<UserProfileEntity?>> getProfileByUserId(String userId) async {
    try {
      final profiles = await datumManager
          .query()
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .find();

      if (profiles.isEmpty) {
        return const Success(null);
      }

      return Success(profiles.first.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get profile: $e'));
    }
  }

  @override
  Future<Result<UserProfileEntity?>> getProfileById(String profileId) async {
    try {
      final profile = await datumManager.read(profileId);
      return Success(profile?.toEntity());
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
      final updated = await datumManager.update(model);
      return Success(updated.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to update profile: $e'));
    }
  }

  @override
  Future<Result<void>> deleteProfile(String profileId) async {
    try {
      await datumManager.delete(profileId);
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to delete profile: $e'));
    }
  }

  @override
  Stream<UserProfileEntity?> watchProfileByUserId(String userId) {
    return datumManager.watchAll().map((profiles) {
      try {
        final profile = profiles.firstWhere(
          (p) => p.userId == userId && !p.isDeleted,
        );
        return profile.toEntity();
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<Result<void>> syncProfile() async {
    try {
      await datumManager.sync();
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to sync profile: $e'));
    }
  }
}

