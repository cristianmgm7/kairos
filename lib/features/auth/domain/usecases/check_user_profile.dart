import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/profile/domain/repositories/user_profile_repository.dart';

class CheckUserProfileUseCase {
  CheckUserProfileUseCase(this._profileRepository);

  final UserProfileRepository _profileRepository;

  Stream<bool> call(String userId) async* {
    final profile = await _profileRepository.getProfileByUserId(userId);

    if (profile.dataOrNull == null) {
      await _profileRepository.fetchProfile(userId);
    }

    yield* _profileRepository
        .watchProfileByUserId(userId)
        .distinct()
        .map((profile) => profile != null);
  }
}
