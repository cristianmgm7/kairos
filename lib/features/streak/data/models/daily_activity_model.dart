import 'package:isar/isar.dart';
import 'package:kairos/features/streak/domain/entities/daily_activity_entity.dart';

part 'daily_activity_model.g.dart';

@collection
class DailyActivityModel {
  DailyActivityModel({
    required this.userId,
    required this.date,
    required this.entryCount,
    required this.firstEntryAtMillis,
    required this.lastEntryAtMillis,
  });

  /// Convert from entity
  factory DailyActivityModel.fromEntity(DailyActivityEntity entity) {
    return DailyActivityModel(
      userId: entity.userId,
      date: entity.date,
      entryCount: entity.entryCount,
      firstEntryAtMillis: entity.firstEntryAt.millisecondsSinceEpoch,
      lastEntryAtMillis: entity.lastEntryAt.millisecondsSinceEpoch,
    );
  }

  /// Isar auto ID
  Id id = Isar.autoIncrement;

  /// Composite ID: userId + date
  @Index(unique: true, composite: [CompositeIndex('date')])
  final String userId;

  /// Date in YYYY-MM-DD format
  final String date;

  /// Number of entries on this day
  final int entryCount;

  /// Timestamp of first entry
  final int firstEntryAtMillis;

  /// Timestamp of last entry
  final int lastEntryAtMillis;

  /// Convert to entity
  DailyActivityEntity toEntity() {
    return DailyActivityEntity(
      userId: userId,
      date: date,
      entryCount: entryCount,
      firstEntryAt: DateTime.fromMillisecondsSinceEpoch(firstEntryAtMillis, isUtc: true),
      lastEntryAt: DateTime.fromMillisecondsSinceEpoch(lastEntryAtMillis, isUtc: true),
    );
  }

  /// Convert to JSON for external use (like repository streams)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date,
      'entryCount': entryCount,
      'firstEntryAt': DateTime.fromMillisecondsSinceEpoch(firstEntryAtMillis, isUtc: true),
      'lastEntryAt': DateTime.fromMillisecondsSinceEpoch(lastEntryAtMillis, isUtc: true),
    };
  }
}
