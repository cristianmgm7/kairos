import 'package:isar/isar.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:uuid/uuid.dart';

part 'achievement_model.g.dart';

@collection
class AchievementModel {
  AchievementModel({
    required this.id,
    required this.userId,
    required this.typeIndex,
    required this.unlockedAtMillis,
  });

  /// Factory constructor for new achievement
  factory AchievementModel.create({
    required String userId,
    required AchievementType type,
  }) {
    final now = DateTime.now().toUtc();
    return AchievementModel(
      id: const Uuid().v4(),
      userId: userId,
      typeIndex: type.index,
      unlockedAtMillis: now.millisecondsSinceEpoch,
    );
  }

  /// Convert from entity
  factory AchievementModel.fromEntity(AchievementEntity entity) {
    return AchievementModel(
      id: entity.id ?? const Uuid().v4(),
      userId: entity.userId,
      typeIndex: entity.type.index,
      unlockedAtMillis: entity.unlockedAt.millisecondsSinceEpoch,
    );
  }

  /// Convert from Firestore
  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      typeIndex: map['typeIndex'] as int,
      unlockedAtMillis: map['unlockedAtMillis'] as int,
    );
  }

  @Index(unique: true)
  final String id;

  @Index()
  final String userId;

  final int typeIndex;
  final int unlockedAtMillis;

  /// Isar ID
  Id get isarId => fastHash(id);

  /// Convert to entity
  AchievementEntity toEntity() {
    return AchievementEntity(
      id: id,
      userId: userId,
      type: AchievementType.values[typeIndex],
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(unlockedAtMillis, isUtc: true),
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'typeIndex': typeIndex,
      'unlockedAtMillis': unlockedAtMillis,
    };
  }

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
}
