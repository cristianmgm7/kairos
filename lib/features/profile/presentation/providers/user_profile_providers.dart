import 'package:blueprint_app/core/providers/datum_provider.dart';
import 'package:blueprint_app/features/profile/data/models/user_profile_model.dart';
import 'package:blueprint_app/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:blueprint_app/features/profile/domain/entities/user_profile_entity.dart';
import 'package:blueprint_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:datum/datum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository provider
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final datum = ref.watch(datumProvider);
  final manager = datum.manager<UserProfileModel>();
  return UserProfileRepositoryImpl(manager);
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

