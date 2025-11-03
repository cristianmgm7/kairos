import 'package:equatable/equatable.dart';

/// Domain entity representing user profile data
/// Separate from auth user entity (UserEntity) which only manages authentication
class UserProfileEntity extends Equatable {
  const UserProfileEntity({
    required this.id,
    required this.userId, // Links to Firebase Auth UID
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.dateOfBirth,
    this.country,
    this.gender,
    this.avatarUrl,
    this.mainGoal,
    this.experienceLevel,
    this.interests,
  });

  /// Unique profile ID (UUID)
  final String id;

  /// Firebase Auth user ID (links to auth session)
  final String userId;

  /// User's display name (required)
  final String name;

  /// Date of birth (optional, for personalized insights)
  final DateTime? dateOfBirth;

  /// Country (optional)
  final String? country;

  /// Gender (optional, for tone/perspective)
  final String? gender;

  /// Avatar image URL (from Firebase Storage or Google)
  final String? avatarUrl;

  /// Main journaling goal (e.g., "reduce stress", "improve focus")
  final String? mainGoal;

  /// Experience level in journaling/mindfulness
  final String? experienceLevel;

  /// User interests (e.g., "gratitude", "motivation", "sleep")
  final List<String>? interests;

  /// Profile creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        dateOfBirth,
        country,
        gender,
        avatarUrl,
        mainGoal,
        experienceLevel,
        interests,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserProfileEntity(id: $id, userId: $userId, name: $name)';
  }
}

