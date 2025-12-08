import 'package:isar/isar.dart';
import 'package:kairos/core/common/base_classes.dart';
import 'package:kairos/features/profile/domain/entities/user_profile_entity.dart';
import 'package:uuid/uuid.dart';

part 'user_profile_model.g.dart';

/// Data model for user profile with Isar persistence
/// Note: Does not extend DatumEntity due to Isar incompatibility with Equatable
@collection
class UserProfileModel implements HasTimestamps {
  UserProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    required this.synced,
    this.dateOfBirthMillis,
    this.country,
    this.gender,
    this.avatarUrl,
    this.avatarLocalPath,
    this.mainGoal,
    this.experienceLevel,
    this.interests,
    this.isDeleted = false,
    this.version = 1,
  });

  /// Factory constructor for creating new profiles
  factory UserProfileModel.create({
    required String userId,
    required String name,
    DateTime? dateOfBirth,
    String? country,
    String? gender,
    String? avatarUrl,
    String? mainGoal,
    String? experienceLevel,
    List<String>? interests,
  }) {
    final now = DateTime.now();
    return UserProfileModel(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      dateOfBirthMillis: dateOfBirth?.millisecondsSinceEpoch,
      country: country,
      gender: gender,
      avatarUrl: avatarUrl,
      mainGoal: mainGoal,
      experienceLevel: experienceLevel,
      interests: interests,
      synced: false,
      createdAtMillis: now.millisecondsSinceEpoch,
      updatedAtMillis: now.millisecondsSinceEpoch,
    );
  }

  /// Create from domain entity
  factory UserProfileModel.fromEntity(UserProfileEntity entity, {bool synced = false}) {
    return UserProfileModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      dateOfBirthMillis: entity.dateOfBirth?.millisecondsSinceEpoch,
      country: entity.country,
      gender: entity.gender,
      avatarUrl: entity.avatarUrl,
      mainGoal: entity.mainGoal,
      experienceLevel: entity.experienceLevel,
      interests: entity.interests,
      synced: synced,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: entity.updatedAt.millisecondsSinceEpoch,
    );
  }

  /// Create from Map (for Firestore deserialization)
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      dateOfBirthMillis: map['dateOfBirthMillis'] as int?,
      country: map['country'] as String?,
      gender: map['gender'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      avatarLocalPath: map['avatarLocalPath'] as String?,
      mainGoal: map['mainGoal'] as String?,
      experienceLevel: map['experienceLevel'] as String?,
      interests: map['interests'] != null ? List<String>.from(map['interests'] as List) : null,
      createdAtMillis: map['createdAtMillis'] as int,
      updatedAtMillis: map['modifiedAtMillis'] as int,
      isDeleted: map['isDeleted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
      synced: true,
    );
  }

  /// Unique profile ID (UUID)
  @Index(unique: true)
  final String id;

  /// Firebase Auth user ID
  @Index()
  final String userId;

  /// Display name
  @Index()
  final String name;

  /// Date of birth (stored as milliseconds since epoch)
  final int? dateOfBirthMillis;

  /// Country
  final String? country;

  /// Gender
  final String? gender;

  /// Avatar URL (Firebase Storage or Google photo URL)
  final String? avatarUrl;

  /// Local avatar path (for offline display while upload pending)
  final String? avatarLocalPath;

  /// Main goal
  final String? mainGoal;

  /// Experience level
  final String? experienceLevel;

  /// Interests (stored as list)
  final List<String>? interests;

  /// Created at timestamp (milliseconds since epoch)
  @override
  final int createdAtMillis;

  /// Updated at timestamp (milliseconds since epoch)
  @override
  final int updatedAtMillis;

  /// Soft delete flag (Datum requirement)
  final bool isDeleted;

  /// Version for optimistic locking (Datum requirement)
  final int version;

  /// Synced flag
  final bool synced;

  /// Isar ID (required for Isar collections)
  Id get isarId => fastHash(id);

  /// Convert to Map for Datum sync
  Map<String, dynamic> toDatumMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'dateOfBirthMillis': dateOfBirthMillis,
      'country': country,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'avatarLocalPath': avatarLocalPath,
      'mainGoal': mainGoal,
      'experienceLevel': experienceLevel,
      'interests': interests,
      'createdAtMillis': createdAtMillis,
      'modifiedAtMillis': updatedAtMillis,
      'isDeleted': isDeleted,
      'version': version,
    };
  }

  /// Convert to domain entity
  UserProfileEntity toEntity() {
    return UserProfileEntity(
      id: id,
      userId: userId,
      name: name,
      dateOfBirth: dateOfBirthMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(dateOfBirthMillis!)
          : null,
      country: country,
      gender: gender,
      avatarUrl: avatarUrl,
      mainGoal: mainGoal,
      experienceLevel: experienceLevel,
      interests: interests,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
    );
  }

  /// Create a copy with updated fields
  UserProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    int? dateOfBirthMillis,
    String? country,
    String? gender,
    String? avatarUrl,
    String? avatarLocalPath,
    String? mainGoal,
    String? experienceLevel,
    List<String>? interests,
    bool? synced,
    int? createdAtMillis,
    int? modifiedAtMillis,
    bool? isDeleted,
    int? version,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dateOfBirthMillis: dateOfBirthMillis ?? this.dateOfBirthMillis,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      mainGoal: mainGoal ?? this.mainGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      interests: interests ?? this.interests,
      synced: synced ?? this.synced,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: modifiedAtMillis ?? updatedAtMillis,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }

  /// Fast hash for Isar ID
  int fastHash(String string) {
    var hash = 0xcbf29ce4;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x1000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x1000001b3;
    }
    return hash;
  }

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMillis);

  DateTime get modifiedAt => DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);
}
