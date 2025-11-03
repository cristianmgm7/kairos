import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/services/firebase_image_storage_service.dart';
import 'package:kairos/core/services/image_picker_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/profile/domain/usecases/create_user_profile_usecase.dart';
import 'package:kairos/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';

/// State for the profile creation flow
sealed class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {}

class ProfileError extends ProfileState {
  ProfileError(this.message);
  final String message;
}

/// Controller for profile creation and management
class ProfileController extends StateNotifier<ProfileState> {
  ProfileController({
    required this.createProfileUseCase,
    required this.getProfileUseCase,
    required this.imagePickerService,
    required this.storageService,
    required this.ref,
  }) : super(ProfileInitial());

  final CreateUserProfileUseCase createProfileUseCase;
  final GetUserProfileUseCase getProfileUseCase;
  final ImagePickerService imagePickerService;
  final FirebaseImageStorageService storageService;
  final Ref ref;

  File? _selectedAvatar;

  /// Get the current user ID from auth state
  String? get _currentUserId {
    final authState = ref.read(authStateProvider);
    return authState.valueOrNull?.id;
  }

  /// Pick avatar from gallery
  Future<void> pickAvatarFromGallery() async {
    final result = await imagePickerService.pickImageFromGallery();

    result.when(
      success: (file) {
        _selectedAvatar = file;
        state = ProfileInitial(); // Reset any error state
      },
      error: (failure) {
        state = ProfileError(_getErrorMessage(failure));
      },
    );
  }

  /// Pick avatar from camera
  Future<void> pickAvatarFromCamera() async {
    final result = await imagePickerService.pickImageFromCamera();

    result.when(
      success: (file) {
        _selectedAvatar = file;
        state = ProfileInitial(); // Reset any error state
      },
      error: (failure) {
        state = ProfileError(_getErrorMessage(failure));
      },
    );
  }

  /// Create a new user profile
  Future<void> createProfile({
    required String name,
    DateTime? dateOfBirth,
    String? country,
    String? gender,
    String? mainGoal,
    String? experienceLevel,
    List<String>? interests,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      state = ProfileError('User not authenticated');
      return;
    }

    state = ProfileLoading();

    try {
      // Upload avatar first if selected
      String? avatarUrl;
      if (_selectedAvatar != null) {
        final uploadResult = await storageService.uploadProfileAvatar(
          imageFile: _selectedAvatar!,
          userId: userId,
        );

        uploadResult.when(
          success: (url) => avatarUrl = url,
          error: (failure) {
            state = ProfileError(
              'Failed to upload avatar: ${_getErrorMessage(failure)}',
            );
            return;
          },
        );
      }

      // Create profile
      final params = CreateUserProfileParams(
        userId: userId,
        name: name,
        dateOfBirth: dateOfBirth,
        country: country,
        gender: gender,
        avatarUrl: avatarUrl,
        mainGoal: mainGoal,
        experienceLevel: experienceLevel,
        interests: interests,
      );

      final result = await createProfileUseCase.call(params);

      result.when(
        success: (profile) {
          state = ProfileSuccess();
          // Invalidate profile providers to refresh data
          ref
            ..invalidate(currentUserProfileProvider)
            ..invalidate(hasCompletedProfileProvider);
        },
        error: (failure) {
          state = ProfileError(_getErrorMessage(failure));
        },
      );
    } catch (e) {
      state = ProfileError('An unexpected error occurred: $e');
    }
  }

  /// Reset the controller state
  void reset() {
    state = ProfileInitial();
    _selectedAvatar = null;
  }

  /// Get selected avatar file (for UI display)
  File? get selectedAvatar => _selectedAvatar;

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error: ${failure.message}',
      StorageFailure() => 'Storage error: ${failure.message}',
      PermissionFailure() => 'Permission error: ${failure.message}',
      UserCancelledFailure() => failure.message,
      _ => 'An error occurred: ${failure.message}',
    };
  }
}

/// Provider for the profile controller
final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final createProfileUseCase = ref.watch(createUserProfileUseCaseProvider);
  final getProfileUseCase = ref.watch(getUserProfileUseCaseProvider);
  final imagePickerService = ref.watch(imagePickerServiceProvider);
  final storageService = ref.watch(firebaseImageStorageServiceProvider);

  return ProfileController(
    createProfileUseCase: createProfileUseCase,
    getProfileUseCase: getProfileUseCase,
    imagePickerService: imagePickerService,
    storageService: storageService,
    ref: ref,
  );
});
