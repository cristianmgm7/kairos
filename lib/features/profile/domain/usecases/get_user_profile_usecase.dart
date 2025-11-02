import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/profile/domain/entities/user_profile_entity.dart';
import 'package:blueprint_app/features/profile/domain/repositories/user_profile_repository.dart';

/// Parameters for getting a user profile
class GetUserProfileParams {
  const GetUserProfileParams({required this.userId});

  final String userId;
}

/// Use case for retrieving a user profile by user ID
class GetUserProfileUseCase {
  GetUserProfileUseCase(this.repository);

  final UserProfileRepository repository;

  Future<Result<UserProfileEntity?>> call(GetUserProfileParams params) async {
    return repository.getProfileByUserId(params.userId);
  }
}




