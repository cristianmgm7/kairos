import 'package:equatable/equatable.dart';

/// Represents user activity for a single day.
/// Used to build calendar visualizations and calculate streaks.
class DailyActivityEntity extends Equatable {
  const DailyActivityEntity({
    required this.userId,
    required this.date,
    required this.entryCount,
    required this.firstEntryAt,
    required this.lastEntryAt,
  });

  /// User ID who owns this activity
  final String userId;

  /// Date in YYYY-MM-DD format
  final String date;

  /// Number of journal entries created on this day
  final int entryCount;

  /// Timestamp of first entry on this day
  final DateTime firstEntryAt;

  /// Timestamp of last entry on this day
  final DateTime lastEntryAt;

  /// Check if this day had any activity
  bool get isActive => entryCount > 0;

  @override
  List<Object?> get props => [userId, date, entryCount, firstEntryAt, lastEntryAt];

  DailyActivityEntity copyWith({
    String? userId,
    String? date,
    int? entryCount,
    DateTime? firstEntryAt,
    DateTime? lastEntryAt,
  }) {
    return DailyActivityEntity(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      entryCount: entryCount ?? this.entryCount,
      firstEntryAt: firstEntryAt ?? this.firstEntryAt,
      lastEntryAt: lastEntryAt ?? this.lastEntryAt,
    );
  }
}
