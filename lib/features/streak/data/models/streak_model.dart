import 'package:isar/isar.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';

part 'streak_model.g.dart';

@collection
class StreakModel {
  StreakModel({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalActiveDays,
    required this.lastActivityDate,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.currentWeekCount = 0,
  });

  /// Factory constructor for new streak
  factory StreakModel.create({
    required String userId,
  }) {
    final now = DateTime.now().toUtc();
    return StreakModel(
      userId: userId,
      currentStreak: 0,
      longestStreak: 0,
      totalActiveDays: 0,
      lastActivityDate: '',
      createdAtMillis: now.millisecondsSinceEpoch,
      updatedAtMillis: now.millisecondsSinceEpoch,
    );
  }

  /// Convert from domain entity
  factory StreakModel.fromEntity(StreakEntity entity) {
    return StreakModel(
      userId: entity.userId,
      currentStreak: entity.currentStreak,
      longestStreak: entity.longestStreak,
      totalActiveDays: entity.totalActiveDays,
      lastActivityDate: entity.lastActivityDate,
      currentWeekCount: entity.currentWeekCount,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: entity.updatedAt.millisecondsSinceEpoch,
    );
  }

  /// Convert from Firestore
  factory StreakModel.fromMap(Map<String, dynamic> map) {
    return StreakModel(
      userId: map['userId'] as String,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      totalActiveDays: map['totalActiveDays'] as int? ?? 0,
      lastActivityDate: map['lastActivityDate'] as String? ?? '',
      currentWeekCount: map['currentWeekCount'] as int? ?? 0,
      createdAtMillis: map['createdAtMillis'] as int,
      updatedAtMillis: map['updatedAtMillis'] as int,
    );
  }

  @Index(unique: true)
  final String userId;

  final int currentStreak;
  final int longestStreak;
  final int totalActiveDays;
  final String lastActivityDate;
  final int currentWeekCount;
  final int createdAtMillis;
  final int updatedAtMillis;

  /// Isar ID generation
  Id get isarId => fastHash(userId);

  /// Convert to Firestore format
  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalActiveDays': totalActiveDays,
      'lastActivityDate': lastActivityDate,
      'currentWeekCount': currentWeekCount,
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis,
    };
  }

  /// Convert to entity
  StreakEntity toEntity() {
    return StreakEntity(
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalActiveDays: totalActiveDays,
      lastActivityDate: lastActivityDate,
      currentWeekCount: currentWeekCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis, isUtc: true),
    );
  }

  StreakModel copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    int? totalActiveDays,
    String? lastActivityDate,
    int? currentWeekCount,
    int? createdAtMillis,
    int? updatedAtMillis,
  }) {
    return StreakModel(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      currentWeekCount: currentWeekCount ?? this.currentWeekCount,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
    );
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
