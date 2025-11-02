import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/profile/domain/entities/user_profile_entity.dart';
import 'package:kairos/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:uuid/uuid.dart';

/// Parameters for creating a user profile
class CreateUserProfileParams {
  const CreateUserProfileParams({
    required this.userId,
    required this.name,
    this.dateOfBirth,
    this.country,
    this.gender,
    this.avatarUrl,
    this.mainGoal,
    this.experienceLevel,
    this.interests,
  });

  final String userId;
  final String name;
  final DateTime? dateOfBirth;
  final String? country;
  final String? gender;
  final String? avatarUrl;
  final String? mainGoal;
  final String? experienceLevel;
  final List<String>? interests;
}

/// Use case for creating a new user profile
class CreateUserProfileUseCase {
  CreateUserProfileUseCase(this.repository);

  final UserProfileRepository repository;

  Future<Result<UserProfileEntity>> call(CreateUserProfileParams params) async {
    // 1. Validate required fields
    if (params.name.trim().isEmpty) {
      return const Error(
        ValidationFailure(message: 'Name cannot be empty'),
      );
    }

    if (params.userId.trim().isEmpty) {
      return const Error(
        ValidationFailure(message: 'User ID cannot be empty'),
      );
    }

    // 2. Generate UUID for profile ID
    const uuid = Uuid();
    final profileId = uuid.v4();

    // 3. Create profile entity
    final now = DateTime.now();
    final profile = UserProfileEntity(
      id: profileId,
      userId: params.userId,
      name: params.name.trim(),
      dateOfBirth: params.dateOfBirth,
      country: params.country,
      gender: params.gender,
      avatarUrl: params.avatarUrl,
      mainGoal: params.mainGoal,
      experienceLevel: params.experienceLevel,
      interests: params.interests,
      createdAt: now,
      updatedAt: now,
    );

    // 4. Call repository to create profile
    return repository.createProfile(profile);
  }
}
