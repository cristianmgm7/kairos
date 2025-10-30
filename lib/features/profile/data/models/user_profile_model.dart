import 'package:blueprint_app/features/profile/domain/entities/user_profile_entity.dart';
import 'package:datum/datum.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'user_profile_model.g.dart';

/// Data model for user profile with Isar persistence and Datum sync
@collection
class UserProfileModel extends DatumEntity {
  /// Isar ID (required for Isar collections)
  @override
  Id get isarId => fastHash(id);

  /// Unique profile ID (UUID)
  @Index(unique: true)
  @override
  final String id;

  /// Firebase Auth user ID
  @Index()
  @override
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
  final int modifiedAtMillis;

  /// Soft delete flag (Datum requirement)
  @override
  final bool isDeleted;

  /// Version for optimistic locking (Datum requirement)
  @override
  final int version;

  UserProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.dateOfBirthMillis,
    this.country,
    this.gender,
    this.avatarUrl,
    this.avatarLocalPath,
    this.mainGoal,
    this.experienceLevel,
    this.interests,
    required this.createdAtMillis,
    required this.modifiedAtMillis,
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
      createdAtMillis: now.millisecondsSinceEpoch,
      modifiedAtMillis: now.millisecondsSinceEpoch,
      version: 1,
      isDeleted: false,
    );
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
      updatedAt: DateTime.fromMillisecondsSinceEpoch(modifiedAtMillis),
    );
  }

  /// Create from domain entity
  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
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
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      modifiedAtMillis: entity.updatedAt.millisecondsSinceEpoch,
    );
  }

  /// Convert to Map for Datum sync
  @override
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
      'modifiedAtMillis': modifiedAtMillis,
      'isDeleted': isDeleted,
      'version': version,
    };
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
      interests: map['interests'] != null
          ? List<String>.from(map['interests'] as List)
          : null,
      createdAtMillis: map['createdAtMillis'] as int,
      modifiedAtMillis: map['modifiedAtMillis'] as int,
      isDeleted: map['isDeleted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
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
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      modifiedAtMillis: modifiedAtMillis ?? this.modifiedAtMillis,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }

  /// Fast hash for Isar ID
  int fastHash(String string) {
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }
    return hash;
  }

  @override
  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMillis);

  @override
  DateTime get modifiedAt =>
      DateTime.fromMillisecondsSinceEpoch(modifiedAtMillis);
}

