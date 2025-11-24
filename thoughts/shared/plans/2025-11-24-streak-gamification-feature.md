# Streak Gamification Feature Implementation Plan

## Overview

Implement a comprehensive gamified engagement system that tracks user journaling consistency through daily streaks, weekly goals, milestone achievements, and rich visualizations. The feature will motivate users to maintain regular journaling habits through visual feedback, achievement badges, and motivational messaging.

## Current State Analysis

### Existing Infrastructure
- **Journal Activity Tracking**: Already captures `JournalMessageEntity.createdAt` and `JournalThreadEntity.lastMessageAt` timestamps
- **User Authentication**: Firebase Auth with `currentUserProvider`
- **Local Database**: Isar for offline-first data storage
- **Remote Sync**: Firestore with automatic sync via `SyncController`
- **State Management**: Riverpod providers throughout the app
- **UI Components**: Material Design 3 with established design system (AppSpacing, AppColors, AppTheme)
- **Visualization**: Already using `fl_chart` package for data visualization

### What Exists Now
- Home screen has basic welcome message with user profile (lib/features/home/presentation/screens/home_screen.dart:1-83)
- Journal messages stored with timestamps
- Clean architecture with domain/data/presentation layers
- Card-based UI pattern in Category Insights feature

### What's Missing
- No streak calculation or tracking
- No achievement/milestone system
- No gamification elements
- No calendar visualization of activity
- No motivational messaging system
- No home screen engagement widgets

### Key Constraints
- Must work offline-first (Isar → Firestore sync pattern)
- Must follow existing clean architecture patterns
- Must use Riverpod for state management
- Streak resets at midnight in user's local timezone
- Any message creation counts toward streak (no minimum length)

## Desired End State

A fully functional gamified streak system where:
1. Users see their current streak prominently on the home screen
2. Users can view detailed streak statistics and history
3. Calendar visualizations show daily activity patterns
4. Achievement badges reward milestone streaks
5. Motivational messages encourage continued engagement
6. All data syncs between devices via Firestore
7. Streak calculations update in real-time as users journal

### Verification
- User creates journal entry → streak increments (if eligible)
- User skips a day → streak resets to 0
- User views calendar → sees all active/inactive days
- User hits milestone (7, 30, 100, 365 days) → achievement badge displays
- User switches devices → streak data syncs correctly
- App works offline → streak calculations continue locally

## What We're NOT Doing

- Streak protection/"freeze" tokens (future enhancement)
- Social sharing of streaks (future enhancement)
- Category-specific streaks (future enhancement - Phase 3)
- Push notifications for streak reminders (keeping it passive)
- Streak leaderboards or competitive features
- Integration with external calendar apps
- Custom timezone selection (uses device timezone only)

## Implementation Approach

### High-Level Strategy

1. **Data Layer First**: Create streak entity, models, and datasources following existing journal patterns
2. **Calculation Engine**: Build streak calculation logic that processes journal message timestamps
3. **State Management**: Set up Riverpod providers for reactive streak updates
4. **Home Screen Integration**: Add streak preview card to home screen
5. **Dedicated Dashboard**: Build full-featured streak dashboard screen
6. **Visualizations**: Implement monthly calendar and yearly heatmap views
7. **Achievement System**: Add milestone tracking and badge display
8. **Polish**: Add animations, motivational messages, and edge case handling

### Architecture Pattern
Follow the established clean architecture:
```
lib/features/streak/
├── domain/
│   ├── entities/
│   │   ├── streak_entity.dart
│   │   └── achievement_entity.dart
│   ├── repositories/
│   │   └── streak_repository.dart
│   └── usecases/
│       ├── calculate_streak_usecase.dart
│       ├── get_streak_data_usecase.dart
│       └── check_achievements_usecase.dart
├── data/
│   ├── datasources/
│   │   ├── streak_local_datasource.dart
│   │   └── streak_remote_datasource.dart
│   ├── models/
│   │   ├── streak_model.dart
│   │   └── daily_activity_model.dart
│   └── repositories/
│       └── streak_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── streak_providers.dart
    ├── controllers/
    │   └── streak_controller.dart
    ├── screens/
    │   └── streak_dashboard_screen.dart
    └── widgets/
        ├── streak_preview_card.dart
        ├── streak_calendar_view.dart
        ├── streak_heatmap_view.dart
        ├── streak_stats_card.dart
        ├── achievement_badge_widget.dart
        └── motivational_message_widget.dart
```

## Phase 1: Core Streak Tracking System

### Overview
Establish the foundational data layer, streak calculation engine, and basic UI integration. This phase creates a working streak tracker that displays on the home screen and syncs across devices.

---

### 1.1: Add Required Dependencies

**File**: `pubspec.yaml`

**Changes**: Add calendar visualization packages

```yaml
dependencies:
  # Existing dependencies...

  # Calendar & Visualization
  table_calendar: ^3.1.2           # Monthly calendar view
  flutter_heatmap_calendar: ^1.0.5 # GitHub-style heatmap
```

**Rationale**:
- `table_calendar` is the most mature and customizable calendar package for Flutter
- `flutter_heatmap_calendar` provides GitHub-style contribution charts out of the box

---

### 1.2: Domain Layer - Entities

**File**: `lib/features/streak/domain/entities/streak_entity.dart`

**Changes**: Create core streak entity

```dart
import 'package:equatable/equatable.dart';

/// Represents a user's journaling streak data.
class StreakEntity extends Equatable {
  const StreakEntity({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalActiveDays,
    required this.lastActivityDate,
    required this.createdAt,
    required this.updatedAt,
    this.currentWeekCount = 0,
  });

  /// User ID who owns this streak
  final String userId;

  /// Current consecutive days with journal entries
  final int currentStreak;

  /// Personal record for longest streak
  final int longestStreak;

  /// Lifetime count of days with at least one journal entry
  final int totalActiveDays;

  /// Date of most recent journal entry (local date, not DateTime)
  /// Stored as YYYY-MM-DD string to handle timezone correctly
  final String lastActivityDate;

  /// Number of journal entries created this week (Monday-Sunday)
  final int currentWeekCount;

  /// When this streak record was first created
  final DateTime createdAt;

  /// When this streak record was last updated
  final DateTime updatedAt;

  /// Check if user has journaled today
  bool get hasJournaledToday {
    final now = DateTime.now();
    final today = _dateToString(now);
    return lastActivityDate == today;
  }

  /// Check if streak is active (journaled today or yesterday)
  bool get isActive {
    final now = DateTime.now();
    final today = _dateToString(now);
    final yesterday = _dateToString(now.subtract(const Duration(days: 1)));
    return lastActivityDate == today || lastActivityDate == yesterday;
  }

  /// Get days until streak expires
  int get daysUntilExpiry {
    if (hasJournaledToday) return 1; // Safe for today
    if (isActive) return 0; // Expires today
    return -1; // Already expired
  }

  /// Helper to convert DateTime to YYYY-MM-DD string
  static String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        userId,
        currentStreak,
        longestStreak,
        totalActiveDays,
        lastActivityDate,
        currentWeekCount,
        createdAt,
        updatedAt,
      ];

  StreakEntity copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    int? totalActiveDays,
    String? lastActivityDate,
    int? currentWeekCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StreakEntity(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      currentWeekCount: currentWeekCount ?? this.currentWeekCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

---

**File**: `lib/features/streak/domain/entities/daily_activity_entity.dart`

**Changes**: Create daily activity tracking entity

```dart
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
```

---

**File**: `lib/features/streak/domain/entities/achievement_entity.dart`

**Changes**: Create achievement/milestone entity

```dart
import 'package:equatable/equatable.dart';

/// Types of achievements users can earn
enum AchievementType {
  streak7,    // 7-day streak
  streak30,   // 30-day streak
  streak100,  // 100-day streak
  streak365,  // 365-day streak (1 year!)
  firstEntry, // First journal entry ever
  weekGoal,   // Completed weekly goal
}

/// Represents a user achievement/milestone
class AchievementEntity extends Equatable {
  const AchievementEntity({
    required this.userId,
    required this.type,
    required this.unlockedAt,
    this.id,
  });

  /// Unique ID for this achievement instance
  final String? id;

  /// User who unlocked this achievement
  final String userId;

  /// Type of achievement
  final AchievementType type;

  /// When the achievement was unlocked
  final DateTime unlockedAt;

  /// Display name for the achievement
  String get displayName {
    return switch (type) {
      AchievementType.streak7 => '7 Day Streak',
      AchievementType.streak30 => '30 Day Streak',
      AchievementType.streak100 => '100 Day Streak',
      AchievementType.streak365 => 'Year-Long Streak',
      AchievementType.firstEntry => 'Getting Started',
      AchievementType.weekGoal => 'Weekly Warrior',
    };
  }

  /// Description of the achievement
  String get description {
    return switch (type) {
      AchievementType.streak7 => 'Journaled for 7 consecutive days',
      AchievementType.streak30 => 'Journaled for 30 consecutive days',
      AchievementType.streak100 => 'Journaled for 100 consecutive days',
      AchievementType.streak365 => 'Journaled for 365 consecutive days',
      AchievementType.firstEntry => 'Created your first journal entry',
      AchievementType.weekGoal => 'Completed weekly journaling goal',
    };
  }

  /// Icon emoji for the achievement
  String get icon {
    return switch (type) {
      AchievementType.streak7 => '🔥',
      AchievementType.streak30 => '⭐',
      AchievementType.streak100 => '💎',
      AchievementType.streak365 => '🏆',
      AchievementType.firstEntry => '✨',
      AchievementType.weekGoal => '🎯',
    };
  }

  @override
  List<Object?> get props => [id, userId, type, unlockedAt];

  AchievementEntity copyWith({
    String? id,
    String? userId,
    AchievementType? type,
    DateTime? unlockedAt,
  }) {
    return AchievementEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
```

---

### 1.3: Domain Layer - Repository Interface

**File**: `lib/features/streak/domain/repositories/streak_repository.dart`

**Changes**: Define repository contract

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:kairos/features/streak/domain/entities/daily_activity_entity.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';

/// Repository interface for streak data operations
abstract class StreakRepository {
  /// Watch user's current streak data (reactive stream)
  Stream<StreakEntity?> watchStreak(String userId);

  /// Get current streak data (one-time fetch)
  Future<Result<StreakEntity?>> getStreak(String userId);

  /// Calculate and update streak based on journal activity
  /// Should be called after user creates a journal entry
  Future<Result<StreakEntity>> calculateAndUpdateStreak(String userId);

  /// Get daily activity data for a date range
  Future<Result<List<DailyActivityEntity>>> getDailyActivity(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get user's unlocked achievements
  Future<Result<List<AchievementEntity>>> getAchievements(String userId);

  /// Watch achievements (reactive stream)
  Stream<List<AchievementEntity>> watchAchievements(String userId);

  /// Sync local streak data to remote
  Future<Result<void>> syncStreak(String userId);
}
```

---

### 1.4: Data Layer - Models

**File**: `lib/features/streak/data/models/streak_model.dart`

**Changes**: Create Isar model for streak data

```dart
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
      currentWeekCount: 0,
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
```

---

**File**: `lib/features/streak/data/models/daily_activity_model.dart`

**Changes**: Create Isar model for daily activity cache

```dart
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

  /// Isar auto ID
  Id id = Isar.autoIncrement;

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
}
```

---

**File**: `lib/features/streak/data/models/achievement_model.dart`

**Changes**: Create Isar model for achievements

```dart
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
```

---

### 1.5: Update Isar Schema

**File**: `lib/core/providers/database_provider.dart`

**Changes**: Add new streak models to Isar schema

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:isar_flutter_libs/isar_flutter_libs.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';
import 'package:kairos/features/profile/data/models/user_profile_model.dart';
import 'package:kairos/features/settings/data/models/settings_model.dart';
import 'package:kairos/features/streak/data/models/achievement_model.dart';
import 'package:kairos/features/streak/data/models/daily_activity_model.dart';
import 'package:kairos/features/streak/data/models/streak_model.dart';
import 'package:path_provider/path_provider.dart';

/// Provider that throws by default, will be overridden in main
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar provider must be overridden');
});

/// Initialize Isar database before app starts
Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  return Isar.open(
    [
      UserProfileModelSchema,
      SettingsModelSchema,
      JournalThreadModelSchema,
      JournalMessageModelSchema,
      StreakModelSchema,           // NEW
      DailyActivityModelSchema,    // NEW
      AchievementModelSchema,      // NEW
    ],
    directory: dir.path,
    name: 'kairos_db',
  );
}
```

---

### 1.6: Data Layer - Local Data Source

**File**: `lib/features/streak/data/datasources/streak_local_datasource.dart`

**Changes**: Implement Isar data operations

```dart
import 'package:isar/isar.dart';
import 'package:kairos/features/streak/data/models/achievement_model.dart';
import 'package:kairos/features/streak/data/models/daily_activity_model.dart';
import 'package:kairos/features/streak/data/models/streak_model.dart';

abstract class StreakLocalDataSource {
  Future<void> saveStreak(StreakModel streak);
  Future<StreakModel?> getStreak(String userId);
  Stream<StreakModel?> watchStreak(String userId);
  Future<void> saveDailyActivity(DailyActivityModel activity);
  Future<List<DailyActivityModel>> getDailyActivities(
    String userId,
    String startDate,
    String endDate,
  );
  Future<void> saveAchievement(AchievementModel achievement);
  Future<List<AchievementModel>> getAchievements(String userId);
  Stream<List<AchievementModel>> watchAchievements(String userId);
}

class StreakLocalDataSourceImpl implements StreakLocalDataSource {
  StreakLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveStreak(StreakModel streak) async {
    await isar.writeTxn(() async {
      await isar.streakModels.put(streak);
    });
  }

  @override
  Future<StreakModel?> getStreak(String userId) async {
    return isar.streakModels.filter().userIdEqualTo(userId).findFirst();
  }

  @override
  Stream<StreakModel?> watchStreak(String userId) {
    return isar.streakModels
        .filter()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true)
        .map((streaks) => streaks.isNotEmpty ? streaks.first : null);
  }

  @override
  Future<void> saveDailyActivity(DailyActivityModel activity) async {
    await isar.writeTxn(() async {
      await isar.dailyActivityModels.put(activity);
    });
  }

  @override
  Future<List<DailyActivityModel>> getDailyActivities(
    String userId,
    String startDate,
    String endDate,
  ) async {
    return isar.dailyActivityModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .dateBetween(startDate, endDate, includeLower: true, includeUpper: true)
        .sortByDate()
        .findAll();
  }

  @override
  Future<void> saveAchievement(AchievementModel achievement) async {
    await isar.writeTxn(() async {
      await isar.achievementModels.put(achievement);
    });
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    return isar.achievementModels
        .filter()
        .userIdEqualTo(userId)
        .sortByUnlockedAtMillisDesc()
        .findAll();
  }

  @override
  Stream<List<AchievementModel>> watchAchievements(String userId) {
    return isar.achievementModels
        .filter()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true)
        .map((achievements) => achievements..sort((a, b) => b.unlockedAtMillis.compareTo(a.unlockedAtMillis)));
  }
}
```

---

### 1.7: Data Layer - Remote Data Source

**File**: `lib/features/streak/data/datasources/streak_remote_datasource.dart`

**Changes**: Implement Firestore operations

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/firestore_exception_mapper.dart';
import 'package:kairos/features/streak/data/models/achievement_model.dart';
import 'package:kairos/features/streak/data/models/streak_model.dart';

abstract class StreakRemoteDataSource {
  Future<void> saveStreak(StreakModel streak);
  Future<StreakModel?> getStreak(String userId);
  Future<void> saveAchievement(AchievementModel achievement);
  Future<List<AchievementModel>> getAchievements(String userId);
  Stream<List<AchievementModel>> watchAchievements(String userId);
}

class StreakRemoteDataSourceImpl implements StreakRemoteDataSource {
  StreakRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _streakCollection() =>
      firestore.collection('user_streaks');

  CollectionReference<Map<String, dynamic>> _achievementsCollection(String userId) =>
      firestore.collection('users').doc(userId).collection('achievements');

  @override
  Future<void> saveStreak(StreakModel streak) async {
    try {
      await _streakCollection().doc(streak.userId).set(streak.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to save streak');
    }
  }

  @override
  Future<StreakModel?> getStreak(String userId) async {
    try {
      final doc = await _streakCollection().doc(userId).get();
      if (!doc.exists) return null;
      return StreakModel.fromMap(doc.data()!);
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get streak');
    }
  }

  @override
  Future<void> saveAchievement(AchievementModel achievement) async {
    try {
      await _achievementsCollection(achievement.userId)
          .doc(achievement.id)
          .set(achievement.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to save achievement');
    }
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    try {
      final querySnapshot = await _achievementsCollection(userId)
          .orderBy('unlockedAtMillis', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AchievementModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get achievements');
    }
  }

  @override
  Stream<List<AchievementModel>> watchAchievements(String userId) {
    return _achievementsCollection(userId)
        .orderBy('unlockedAtMillis', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AchievementModel.fromMap(doc.data()))
            .toList());
  }
}
```

---

### Success Criteria - Phase 1.1 to 1.7:

#### Automated Verification:
- [ ] Dependencies installed: `flutter pub get`
- [ ] Isar models generated: `dart run build_runner build --delete-conflicting-outputs`
- [ ] No compilation errors: `flutter analyze`
- [ ] All imports resolve correctly

#### Manual Verification:
- [ ] Models can be instantiated without errors
- [ ] Entity conversion methods work correctly
- [ ] Isar schema includes new collections

**Implementation Note**: After completing automated verification and ensuring no compilation errors, pause here for manual confirmation that the data layer foundation is solid before proceeding to the streak calculation logic.

---

## Phase 2: Streak Calculation Engine

### Overview
Implement the core business logic that calculates streaks from journal message timestamps, handles edge cases, and updates streak data when users create journal entries.

---

### 2.1: Streak Calculation Use Case

**File**: `lib/features/streak/domain/usecases/calculate_streak_usecase.dart`

**Changes**: Core streak calculation logic

```dart
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/streak/data/models/daily_activity_model.dart';
import 'package:kairos/features/streak/data/models/streak_model.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/domain/repositories/streak_repository.dart';

/// Calculates user's current streak based on journal activity.
///
/// Algorithm:
/// 1. Fetch all journal messages for the user
/// 2. Group messages by date (local timezone)
/// 3. Calculate consecutive days working backwards from today
/// 4. Update streak entity with new values
/// 5. Check for new achievements
class CalculateStreakUseCase {
  CalculateStreakUseCase({
    required this.streakRepository,
    required this.journalRepository,
  });

  final StreakRepository streakRepository;
  final JournalThreadRepository journalRepository;

  Future<StreakEntity> call(String userId) async {
    // Get existing streak or create new
    final existingStreakResult = await streakRepository.getStreak(userId);
    final existingStreak = existingStreakResult.dataOrNull;

    // Get all journal threads to find message timestamps
    final threadsResult = await journalRepository.getThreadsByUserId(userId);
    final threads = threadsResult.dataOrNull ?? [];

    if (threads.isEmpty) {
      // No journal activity yet
      return existingStreak ?? StreakEntity(
        userId: userId,
        currentStreak: 0,
        longestStreak: 0,
        totalActiveDays: 0,
        lastActivityDate: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Extract all activity dates from threads
    final activityDates = <String>{};
    DateTime? mostRecentActivity;

    for (final thread in threads) {
      if (thread.lastMessageAt != null) {
        final messageDate = thread.lastMessageAt!;
        final dateString = _dateToString(messageDate);
        activityDates.add(dateString);

        if (mostRecentActivity == null || messageDate.isAfter(mostRecentActivity)) {
          mostRecentActivity = messageDate;
        }
      }
    }

    // Calculate current streak
    final now = DateTime.now();
    final today = _dateToString(now);
    final yesterday = _dateToString(now.subtract(const Duration(days: 1)));

    int currentStreak = 0;
    String lastActivityDate = '';

    if (activityDates.contains(today)) {
      lastActivityDate = today;
      currentStreak = 1;

      // Count backwards from yesterday
      var checkDate = now.subtract(const Duration(days: 1));
      while (activityDates.contains(_dateToString(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else if (activityDates.contains(yesterday)) {
      lastActivityDate = yesterday;
      currentStreak = 1;

      // Count backwards from 2 days ago
      var checkDate = now.subtract(const Duration(days: 2));
      while (activityDates.contains(_dateToString(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      // Streak is broken
      currentStreak = 0;
      lastActivityDate = mostRecentActivity != null ? _dateToString(mostRecentActivity) : '';
    }

    // Calculate longest streak (preserve if current is lower)
    final longestStreak = existingStreak != null
        ? (currentStreak > existingStreak.longestStreak ? currentStreak : existingStreak.longestStreak)
        : currentStreak;

    // Calculate current week count (Monday-Sunday)
    final weekStart = _getWeekStart(now);
    int currentWeekCount = 0;
    for (var i = 0; i < 7; i++) {
      final checkDate = weekStart.add(Duration(days: i));
      if (activityDates.contains(_dateToString(checkDate))) {
        currentWeekCount++;
      }
    }

    // Create updated streak entity
    final updatedStreak = StreakEntity(
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalActiveDays: activityDates.length,
      lastActivityDate: lastActivityDate,
      currentWeekCount: currentWeekCount,
      createdAt: existingStreak?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    logger.i('Calculated streak for $userId: current=$currentStreak, longest=$longestStreak, total=${activityDates.length}');

    return updatedStreak;
  }

  /// Convert DateTime to YYYY-MM-DD string
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get Monday of current week
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1, Sunday = 7
    return date.subtract(Duration(days: weekday - 1));
  }
}
```

---

### 2.2: Repository Implementation

**File**: `lib/features/streak/data/repositories/streak_repository_impl.dart`

**Changes**: Implement repository with local-first pattern

```dart
import 'package:kairos/core/errors/exceptions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:kairos/features/streak/data/datasources/streak_remote_datasource.dart';
import 'package:kairos/features/streak/data/models/achievement_model.dart';
import 'package:kairos/features/streak/data/models/streak_model.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:kairos/features/streak/domain/entities/daily_activity_entity.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/domain/repositories/streak_repository.dart';
import 'package:kairos/features/streak/domain/usecases/calculate_streak_usecase.dart';

class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.journalRepository,
  });

  final StreakLocalDataSource localDataSource;
  final StreakRemoteDataSource remoteDataSource;
  final JournalThreadRepository journalRepository;

  @override
  Stream<StreakEntity?> watchStreak(String userId) {
    return localDataSource.watchStreak(userId).map((model) => model?.toEntity());
  }

  @override
  Future<Result<StreakEntity?>> getStreak(String userId) async {
    try {
      final localStreak = await localDataSource.getStreak(userId);
      return Success(localStreak?.toEntity());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to get streak: $e'));
    }
  }

  @override
  Future<Result<StreakEntity>> calculateAndUpdateStreak(String userId) async {
    try {
      // Calculate new streak using use case
      final calculateUseCase = CalculateStreakUseCase(
        streakRepository: this,
        journalRepository: journalRepository,
      );
      final updatedStreak = await calculateUseCase(userId);

      // Save to local first
      final model = StreakModel.fromEntity(updatedStreak);
      await localDataSource.saveStreak(model);

      // Check for new achievements
      await _checkAndAwardAchievements(updatedStreak);

      // Try to sync to remote (best effort)
      try {
        await remoteDataSource.saveStreak(model);
      } on NetworkException catch (e) {
        logger.i('Network error saving streak (will sync later): ${e.message}');
      } on ServerException catch (e) {
        logger.i('Server error saving streak (will sync later): ${e.message}');
      }

      return Success(updatedStreak);
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to calculate streak: $e'));
    }
  }

  @override
  Future<Result<List<DailyActivityEntity>>> getDailyActivity(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = _dateToString(startDate);
      final endDateStr = _dateToString(endDate);

      final models = await localDataSource.getDailyActivities(
        userId,
        startDateStr,
        endDateStr,
      );

      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to get daily activity: $e'));
    }
  }

  @override
  Future<Result<List<AchievementEntity>>> getAchievements(String userId) async {
    try {
      final models = await localDataSource.getAchievements(userId);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to get achievements: $e'));
    }
  }

  @override
  Stream<List<AchievementEntity>> watchAchievements(String userId) {
    return localDataSource.watchAchievements(userId).map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<Result<void>> syncStreak(String userId) async {
    try {
      final localStreak = await localDataSource.getStreak(userId);
      if (localStreak != null) {
        await remoteDataSource.saveStreak(localStreak);
      }

      final localAchievements = await localDataSource.getAchievements(userId);
      for (final achievement in localAchievements) {
        await remoteDataSource.saveAchievement(achievement);
      }

      return const Success(null);
    } on NetworkException catch (e) {
      return Error(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Error(ServerFailure(message: e.message));
    } catch (e) {
      return Error(ServerFailure(message: 'Failed to sync streak: $e'));
    }
  }

  /// Check if user has earned any new achievements
  Future<void> _checkAndAwardAchievements(StreakEntity streak) async {
    final existingAchievements = await localDataSource.getAchievements(streak.userId);
    final existingTypes = existingAchievements.map((a) => a.typeIndex).toSet();

    // Check streak milestones
    final achievementsToAward = <AchievementType>[];

    if (streak.currentStreak >= 7 && !existingTypes.contains(AchievementType.streak7.index)) {
      achievementsToAward.add(AchievementType.streak7);
    }
    if (streak.currentStreak >= 30 && !existingTypes.contains(AchievementType.streak30.index)) {
      achievementsToAward.add(AchievementType.streak30);
    }
    if (streak.currentStreak >= 100 && !existingTypes.contains(AchievementType.streak100.index)) {
      achievementsToAward.add(AchievementType.streak100);
    }
    if (streak.currentStreak >= 365 && !existingTypes.contains(AchievementType.streak365.index)) {
      achievementsToAward.add(AchievementType.streak365);
    }

    // First entry achievement
    if (streak.totalActiveDays == 1 && !existingTypes.contains(AchievementType.firstEntry.index)) {
      achievementsToAward.add(AchievementType.firstEntry);
    }

    // Award new achievements
    for (final type in achievementsToAward) {
      final achievement = AchievementModel.create(userId: streak.userId, type: type);
      await localDataSource.saveAchievement(achievement);

      try {
        await remoteDataSource.saveAchievement(achievement);
      } catch (e) {
        logger.i('Failed to sync achievement to remote: $e');
      }

      logger.i('🎉 Achievement unlocked for ${streak.userId}: ${type.name}');
    }
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
```

---

### 2.3: Riverpod Providers

**File**: `lib/features/streak/presentation/providers/streak_providers.dart`

**Changes**: Set up provider chain

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/presentation/providers/journal_providers.dart';
import 'package:kairos/features/streak/data/datasources/streak_local_datasource.dart';
import 'package:kairos/features/streak/data/datasources/streak_remote_datasource.dart';
import 'package:kairos/features/streak/data/repositories/streak_repository_impl.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/domain/repositories/streak_repository.dart';

// ============ Data Source Providers ============

final streakLocalDataSourceProvider = Provider<StreakLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return StreakLocalDataSourceImpl(isar);
});

final streakRemoteDataSourceProvider = Provider<StreakRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return StreakRemoteDataSourceImpl(firestore);
});

// ============ Repository Provider ============

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  final localDataSource = ref.watch(streakLocalDataSourceProvider);
  final remoteDataSource = ref.watch(streakRemoteDataSourceProvider);
  final journalRepository = ref.watch(threadRepositoryProvider);

  return StreakRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    journalRepository: journalRepository,
  );
});

// ============ Stream Providers ============

/// Watch current user's streak data
final currentStreakProvider = StreamProvider<StreakEntity?>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;

  if (userId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(streakRepositoryProvider);
  return repository.watchStreak(userId);
});

/// Watch current user's achievements
final currentAchievementsProvider = StreamProvider<List<AchievementEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(streakRepositoryProvider);
  return repository.watchAchievements(userId);
});

// ============ Action Providers ============

/// Trigger streak calculation (call after journal entry created)
final calculateStreakProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final user = ref.read(currentUserProvider);
    final userId = user?.id;

    if (userId == null) {
      logger.w('Cannot calculate streak: no user logged in');
      return;
    }

    final repository = ref.read(streakRepositoryProvider);
    final result = await repository.calculateAndUpdateStreak(userId);

    result.when(
      success: (streak) {
        logger.i('Streak updated: current=${streak.currentStreak}');
      },
      error: (failure) {
        logger.e('Failed to calculate streak: ${failure.message}');
      },
    );
  };
});
```

---

### Success Criteria - Phase 2:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] Repository tests pass (if tests written): `flutter test`
- [ ] Providers can be read without throwing

#### Manual Verification:
- [ ] Create a journal entry → streak calculation triggers
- [ ] Streak calculates correctly for consecutive days
- [ ] Streak resets when day is skipped
- [ ] Longest streak is preserved correctly
- [ ] Weekly count updates properly
- [ ] First entry achievement unlocks

**Implementation Note**: After automated verification passes, manually test the streak calculation logic by creating journal entries on consecutive days and verifying the streak increments correctly. Pause here before proceeding to UI implementation.

---

## Phase 3: Home Screen Integration

### Overview
Add a streak preview card to the home screen that displays current streak, today's status, and weekly progress. This provides immediate visibility and motivation for users.

---

### 3.1: Streak Preview Card Widget

**File**: `lib/features/streak/presentation/widgets/streak_preview_card.dart`

**Changes**: Create home screen preview widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:kairos/features/streak/presentation/providers/streak_providers.dart';
import 'package:kairos/features/streak/presentation/screens/streak_dashboard_screen.dart';

class StreakPreviewCard extends ConsumerWidget {
  const StreakPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(currentStreakProvider);

    return streakAsync.when(
      data: (streak) => _buildCard(context, streak),
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context, error),
    );
  }

  Widget _buildCard(BuildContext context, StreakEntity? streak) {
    final theme = Theme.of(context);
    final currentStreak = streak?.currentStreak ?? 0;
    final hasJournaledToday = streak?.hasJournaledToday ?? false;

    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const StreakDashboardScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with flame icon and streak count
              Row(
                children: [
                  Text(
                    '🔥',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currentStreak Day Streak',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getStatusMessage(hasJournaledToday, currentStreak),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Weekly progress dots
              if (streak != null) _buildWeeklyProgress(context, streak),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, StreakEntity streak) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    // Determine which days this week have activity
    final weekDays = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dateStr = _dateToString(date);
      final isToday = dateStr == _dateToString(now);
      final hasActivity = streak.lastActivityDate == dateStr ||
                         (streak.hasJournaledToday && isToday);

      return (isToday: isToday, hasActivity: hasActivity);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays.map((day) {
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: day.hasActivity
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                border: day.isToday
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: day.hasActivity
                  ? Icon(
                      Icons.check,
                      size: 20,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((label) {
            return SizedBox(
              width: 36,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return const Card(
      margin: EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object error) {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('Error loading streak: $error'),
      ),
    );
  }

  String _getStatusMessage(bool hasJournaledToday, int currentStreak) {
    if (currentStreak == 0) {
      return 'Start your streak today!';
    } else if (hasJournaledToday) {
      return 'Amazing! Keep the momentum going!';
    } else {
      return 'Journal today to continue your streak';
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // Monday = 1
    return date.subtract(Duration(days: weekday - 1));
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
```

---

### 3.2: Update Home Screen

**File**: `lib/features/home/presentation/screens/home_screen.dart`

**Changes**: Add streak preview card after welcome section

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kairos/features/auth/presentation/providers/auth_controller.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/features/streak/presentation/widgets/streak_preview_card.dart';
import 'package:kairos/l10n/app_localizations.dart';

/// Home screen - displays welcome message and user profile info.
/// NOTE: Does not wrap in Scaffold - MainScaffold provides that.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Column(
      children: [
        AppBar(
          title: Text(l10n.home),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        ),
        Expanded(
          child: profileAsync.when(
            data: (profile) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profile?.avatarUrl != null)
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(profile!.avatarUrl!),
                          )
                        else if (user?.photoUrl != null)
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(user!.photoUrl!),
                          )
                        else
                          const CircleAvatar(
                            radius: 40,
                            child: Icon(Icons.person, size: 40),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome back, ${profile?.name ?? user?.displayName ?? 'User'}!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your journaling companion',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Streak preview card (NEW)
                  const StreakPreviewCard(),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}
```

---

### 3.3: Trigger Streak Calculation on Journal Entry

**File**: `lib/features/journal/presentation/controllers/message_controller.dart`

**Changes**: Add streak recalculation after message creation

**Note**: You'll need to locate this file and add the streak calculation trigger. Here's the pattern to follow:

```dart
// After successfully creating a message, trigger streak recalculation
Future<void> createMessage(...) async {
  // ... existing message creation logic ...

  final result = await createMessageUseCase(...);

  result.when(
    success: (message) {
      state = MessageCreateSuccess(message);

      // Trigger streak calculation (NEW)
      ref.read(calculateStreakProvider)();
    },
    error: (failure) {
      state = MessageCreateError(_getErrorMessage(failure));
    },
  );
}
```

---

### Success Criteria - Phase 3:

#### Automated Verification:
- [ ] Home screen compiles without errors: `flutter analyze`
- [ ] Widget tree renders without exceptions: `flutter run`
- [ ] No import errors or missing dependencies

#### Manual Verification:
- [ ] Home screen displays streak preview card
- [ ] Card shows "0 Day Streak" for new users
- [ ] Weekly progress shows correct days (Monday-Sunday)
- [ ] Tapping card navigates to streak dashboard (placeholder for now)
- [ ] Create journal entry → streak updates automatically on home screen
- [ ] "Journal today" message changes to "Keep going!" after journaling
- [ ] Weekly dots update when journal entry created

**Implementation Note**: After verifying the home screen integration works correctly and streak updates are triggered automatically, pause here before proceeding to build the full dashboard.

---

## Phase 4: Streak Dashboard Screen

### Overview
Build the dedicated streak dashboard with detailed statistics, monthly calendar view, yearly heatmap, and achievement badges.

---

### 4.1: Motivational Message Widget

**File**: `lib/features/streak/presentation/widgets/motivational_message_widget.dart`

**Changes**: Create dynamic motivational messages

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';

class MotivationalMessageWidget extends StatelessWidget {
  const MotivationalMessageWidget({
    required this.streak,
    super.key,
  });

  final StreakEntity? streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _getMessage();
    final icon = _getIcon();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMessage() {
    if (streak == null || streak!.currentStreak == 0) {
      return 'Start your journey today! Every great streak begins with a single entry.';
    }

    final currentStreak = streak!.currentStreak;
    final hasJournaledToday = streak!.hasJournaledToday;

    if (!hasJournaledToday) {
      if (currentStreak == 1) {
        return 'Don\'t break your streak! Journal today to keep the momentum going.';
      } else {
        return 'You\'re on a $currentStreak-day streak! Keep it alive by journaling today.';
      }
    }

    // Has journaled today
    if (currentStreak == 1) {
      return 'Great start! You\'ve begun your streak. Come back tomorrow to keep it going!';
    } else if (currentStreak < 7) {
      return 'You\'re building momentum! $currentStreak days and counting. Keep it up!';
    } else if (currentStreak < 30) {
      return 'Incredible! You\'ve hit $currentStreak consecutive days. You\'re on fire!';
    } else if (currentStreak < 100) {
      return 'Phenomenal dedication! $currentStreak days of consistent journaling. You\'re unstoppable!';
    } else {
      return 'Legendary! $currentStreak days shows true commitment. You\'re an inspiration!';
    }
  }

  String _getIcon() {
    if (streak == null || streak!.currentStreak == 0) {
      return '✨';
    }

    final currentStreak = streak!.currentStreak;

    if (currentStreak < 7) {
      return '🔥';
    } else if (currentStreak < 30) {
      return '⭐';
    } else if (currentStreak < 100) {
      return '💎';
    } else {
      return '🏆';
    }
  }
}
```

---

### 4.2: Stats Card Widget

**File**: `lib/features/streak/presentation/widgets/streak_stats_card.dart`

**Changes**: Create reusable stat display cards

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';

class StreakStatsCard extends StatelessWidget {
  const StreakStatsCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: displayColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 4.3: Monthly Calendar View Widget

**File**: `lib/features/streak/presentation/widgets/streak_calendar_view.dart`

**Changes**: Implement calendar using table_calendar

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakCalendarView extends ConsumerStatefulWidget {
  const StreakCalendarView({
    required this.streak,
    super.key,
  });

  final StreakEntity? streak;

  @override
  ConsumerState<StreakCalendarView> createState() => _StreakCalendarViewState();
}

class _StreakCalendarViewState extends ConsumerState<StreakCalendarView> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Calendar',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium!,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, isToday: false);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, isToday: true);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLegend(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, {required bool isToday}) {
    final theme = Theme.of(context);
    final dateStr = _dateToString(day);
    final hasActivity = widget.streak?.lastActivityDate == dateStr ||
        (widget.streak?.hasJournaledToday == true && isToday);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasActivity
            ? theme.colorScheme.primary
            : (isToday ? theme.colorScheme.secondary.withOpacity(0.2) : null),
        border: isToday
            ? Border.all(color: theme.colorScheme.secondary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: hasActivity
                ? theme.colorScheme.onPrimary
                : (isToday ? theme.colorScheme.onSecondaryContainer : null),
            fontWeight: isToday ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          theme,
          color: theme.colorScheme.primary,
          label: 'Active',
        ),
        const SizedBox(width: AppSpacing.lg),
        _buildLegendItem(
          theme,
          color: theme.colorScheme.surfaceContainerHighest,
          label: 'Inactive',
        ),
        const SizedBox(width: AppSpacing.lg),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.secondary, width: 2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Today',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLegendItem(ThemeData theme, {required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
```

---

### 4.4: Yearly Heatmap View Widget

**File**: `lib/features/streak/presentation/widgets/streak_heatmap_view.dart`

**Changes**: Implement GitHub-style heatmap

```dart
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/streak_entity.dart';

class StreakHeatmapView extends ConsumerWidget {
  const StreakHeatmapView({
    required this.streak,
    super.key,
  });

  final StreakEntity? streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // For now, create sample data
    // TODO: Load actual activity data from repository
    final datasets = _buildDatasets();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Year Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HeatMap(
              datasets: datasets,
              colorMode: ColorMode.opacity,
              showText: false,
              scrollable: true,
              colorsets: {
                1: theme.colorScheme.primary,
              },
              defaultColor: theme.colorScheme.surfaceContainerHighest,
              textColor: theme.colorScheme.onSurface,
              size: 30,
              fontSize: 10,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildHeatmapLegend(theme),
          ],
        ),
      ),
    );
  }

  Map<DateTime, int> _buildDatasets() {
    // TODO: Replace with actual activity data from DailyActivityEntity
    // For now, return sample data based on streak
    final datasets = <DateTime, int>{};

    if (streak != null && streak!.currentStreak > 0) {
      final now = DateTime.now();
      for (var i = 0; i < streak!.currentStreak; i++) {
        final date = now.subtract(Duration(days: i));
        datasets[DateTime(date.year, date.month, date.day)] = 1;
      }
    }

    return datasets;
  }

  Widget _buildHeatmapLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        ...List.generate(5, (index) {
          final opacity = (index + 1) / 5;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(opacity),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'More',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

---

### 4.5: Achievement Badge Widget

**File**: `lib/features/streak/presentation/widgets/achievement_badge_widget.dart`

**Changes**: Create achievement display widget

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';

class AchievementBadgeWidget extends StatelessWidget {
  const AchievementBadgeWidget({
    required this.achievement,
    super.key,
  });

  final AchievementEntity achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              achievement.displayName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatDate(achievement.unlockedAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
```

---

### 4.6: Streak Dashboard Screen

**File**: `lib/features/streak/presentation/screens/streak_dashboard_screen.dart`

**Changes**: Assemble full dashboard

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/presentation/providers/streak_providers.dart';
import 'package:kairos/features/streak/presentation/widgets/achievement_badge_widget.dart';
import 'package:kairos/features/streak/presentation/widgets/motivational_message_widget.dart';
import 'package:kairos/features/streak/presentation/widgets/streak_calendar_view.dart';
import 'package:kairos/features/streak/presentation/widgets/streak_heatmap_view.dart';
import 'package:kairos/features/streak/presentation/widgets/streak_stats_card.dart';

class StreakDashboardScreen extends ConsumerStatefulWidget {
  const StreakDashboardScreen({super.key});

  @override
  ConsumerState<StreakDashboardScreen> createState() => _StreakDashboardScreenState();
}

class _StreakDashboardScreenState extends ConsumerState<StreakDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streakAsync = ref.watch(currentStreakProvider);
    final achievementsAsync = ref.watch(currentAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Streak'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: streakAsync.when(
        data: (streak) => TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context, streak),
            _buildAchievementsTab(context, achievementsAsync),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, streak) {
    final theme = Theme.of(context);
    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;
    final totalDays = streak?.totalActiveDays ?? 0;
    final weekCount = streak?.currentWeekCount ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with large flame and streak count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '🔥',
                  style: TextStyle(
                    fontSize: 80,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$currentStreak',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Day Streak',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Motivational message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: MotivationalMessageWidget(streak: streak),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Stats grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.2,
              children: [
                StreakStatsCard(
                  label: 'Longest Streak',
                  value: '$longestStreak',
                  icon: Icons.emoji_events,
                  color: theme.colorScheme.tertiary,
                ),
                StreakStatsCard(
                  label: 'Total Active Days',
                  value: '$totalDays',
                  icon: Icons.calendar_today,
                  color: theme.colorScheme.secondary,
                ),
                StreakStatsCard(
                  label: 'This Week',
                  value: '$weekCount/7',
                  icon: Icons.date_range,
                  color: theme.colorScheme.primary,
                ),
                StreakStatsCard(
                  label: 'Current Month',
                  value: '${_getMonthDays(streak)}',
                  icon: Icons.calendar_month,
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Calendar views
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: StreakCalendarView(streak: streak),
          ),

          const SizedBox(height: AppSpacing.lg),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: StreakHeatmapView(streak: streak),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(BuildContext context, achievementsAsync) {
    return achievementsAsync.when(
      data: (achievements) {
        if (achievements.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🏆',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No Achievements Yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Start journaling to unlock achievements!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.8,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            return AchievementBadgeWidget(achievement: achievements[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading achievements: $error')),
    );
  }

  int _getMonthDays(streak) {
    // TODO: Calculate days active in current month
    // For now, just return a placeholder
    return streak?.totalActiveDays ?? 0;
  }
}
```

---

### Success Criteria - Phase 4:

#### Automated Verification:
- [ ] All widgets compile: `flutter analyze`
- [ ] Dashboard screen renders: `flutter run`
- [ ] Tab navigation works without errors
- [ ] No widget overflow or rendering issues

#### Manual Verification:
- [ ] Dashboard displays all sections correctly
- [ ] Large flame icon and streak count visible
- [ ] Motivational message changes based on streak status
- [ ] Stats cards show correct values
- [ ] Monthly calendar displays with correct active/inactive days
- [ ] Today's date has border highlight
- [ ] Yearly heatmap renders (even with sample data)
- [ ] Tab navigation between Overview and Achievements works
- [ ] Achievements tab shows "No achievements" for new users
- [ ] Achievements display correctly after unlocking
- [ ] Scroll performance is smooth

**Implementation Note**: After verifying the dashboard displays correctly and all widgets render properly, the core streak feature is complete! The remaining phases add polish and optimizations.

---

## Phase 5: Polish & Enhancements

### Overview
Add animations, improve performance, handle edge cases, and polish the user experience.

---

### 5.1: Add Milestone Celebration Animation

**File**: `lib/features/streak/presentation/widgets/milestone_celebration_dialog.dart`

**Changes**: Create celebration dialog for achievements

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/streak/domain/entities/achievement_entity.dart';

class MilestoneCelebrationDialog extends StatefulWidget {
  const MilestoneCelebrationDialog({
    required this.achievement,
    super.key,
  });

  final AchievementEntity achievement;

  @override
  State<MilestoneCelebrationDialog> createState() => _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(AppSpacing.xl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.achievement.icon,
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Achievement Unlocked!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.achievement.displayName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.achievement.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show celebration dialog
void showMilestoneCelebration(BuildContext context, AchievementEntity achievement) {
  showDialog<void>(
    context: context,
    builder: (context) => MilestoneCelebrationDialog(achievement: achievement),
  );
}
```

---

### 5.2: Update Repository to Trigger Celebrations

**File**: `lib/features/streak/data/repositories/streak_repository_impl.dart`

**Changes**: Add callback for new achievements (update `_checkAndAwardAchievements` method)

```dart
// Add this field to StreakRepositoryImpl class
final void Function(AchievementEntity)? onAchievementUnlocked;

// Update constructor
StreakRepositoryImpl({
  required this.localDataSource,
  required this.remoteDataSource,
  required this.journalRepository,
  this.onAchievementUnlocked,
});

// Update _checkAndAwardAchievements method to call callback
Future<void> _checkAndAwardAchievements(StreakEntity streak) async {
  // ... existing code ...

  // Award new achievements
  for (final type in achievementsToAward) {
    final achievement = AchievementModel.create(userId: streak.userId, type: type);
    await localDataSource.saveAchievement(achievement);

    try {
      await remoteDataSource.saveAchievement(achievement);
    } catch (e) {
      logger.i('Failed to sync achievement to remote: $e');
    }

    logger.i('🎉 Achievement unlocked for ${streak.userId}: ${type.name}');

    // Trigger celebration callback (NEW)
    onAchievementUnlocked?.call(achievement.toEntity());
  }
}
```

---

### 5.3: Improve Streak Calculation Trigger

**File**: `lib/features/journal/presentation/controllers/message_controller.dart` (or equivalent)

**Changes**: Add achievement celebration trigger

```dart
// After streak calculation succeeds
final result = await repository.calculateAndUpdateStreak(userId);

result.when(
  success: (updatedStreak) {
    // Check if new achievements were unlocked
    // This will be handled by the repository callback
    logger.i('Streak updated successfully');
  },
  error: (failure) {
    logger.e('Streak calculation failed: ${failure.message}');
  },
);
```

---

### 5.4: Add Loading States to Preview Card

**File**: `lib/features/streak/presentation/widgets/streak_preview_card.dart`

**Changes**: Improve loading and error states

```dart
// Update _buildLoadingCard method
Widget _buildLoadingCard(BuildContext context) {
  final theme = Theme.of(context);
  return Card(
    margin: const EdgeInsets.all(AppSpacing.lg),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Loading your streak...',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

// Update _buildErrorCard method
Widget _buildErrorCard(BuildContext context, Object error) {
  final theme = Theme.of(context);
  return Card(
    margin: const EdgeInsets.all(AppSpacing.lg),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Unable to load streak',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Please try again later',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

### 5.5: Add Refresh Capability to Dashboard

**File**: `lib/features/streak/presentation/screens/streak_dashboard_screen.dart`

**Changes**: Add pull-to-refresh

```dart
// Wrap overview tab in RefreshIndicator
Widget _buildOverviewTab(BuildContext context, streak) {
  return RefreshIndicator(
    onRefresh: () async {
      // Trigger streak recalculation
      await ref.read(calculateStreakProvider)();
    },
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        // ... existing content ...
      ),
    ),
  );
}
```

---

### Success Criteria - Phase 5:

#### Automated Verification:
- [ ] All animations compile: `flutter analyze`
- [ ] No performance warnings: `flutter run --profile`

#### Manual Verification:
- [ ] Milestone dialog appears when achievement unlocked
- [ ] Dialog animation is smooth and engaging
- [ ] Loading states show proper feedback
- [ ] Error states display user-friendly messages
- [ ] Pull-to-refresh works on dashboard
- [ ] Refresh recalculates streak correctly
- [ ] No janky animations or frame drops
- [ ] Celebration dialog dismisses properly

**Implementation Note**: After verifying animations and polish features work smoothly, the streak feature is fully functional and ready for user testing!

---

## Testing Strategy

### Unit Tests

**Files to test**:
- `calculate_streak_usecase.dart` - Core streak calculation logic
- `streak_entity.dart` - Entity helper methods
- `achievement_entity.dart` - Achievement display methods
- `streak_repository_impl.dart` - Repository logic

**Key test cases**:
```dart
// calculate_streak_usecase_test.dart
test('calculates 0 streak for no journal entries', () {});
test('calculates 1 streak for single day', () {});
test('calculates consecutive days correctly', () {});
test('resets streak when day is skipped', () {});
test('preserves longest streak when current is lower', () {});
test('calculates week count correctly across week boundaries', () {});
test('handles timezone edge cases', () {});
```

### Integration Tests

**Scenarios to test**:
1. New user journey:
   - Opens app → sees 0 streak
   - Creates first entry → streak becomes 1
   - First entry achievement unlocks

2. Streak continuation:
   - User with 5-day streak creates entry today
   - Streak increments to 6
   - Stats update correctly

3. Streak break:
   - User with 10-day streak skips a day
   - Streak resets to 0
   - Longest streak remains 10

4. Achievement unlocking:
   - User hits 7-day streak → achievement unlocks
   - Celebration dialog appears
   - Achievement persists across app restarts

5. Offline behavior:
   - Create entry offline
   - Streak updates locally
   - Syncs to Firestore when online

### Manual Testing Steps

1. **First-time user**:
   - Install app, create account
   - Verify 0 streak shows on home screen
   - Create journal entry
   - Verify streak becomes 1
   - Verify "First Entry" achievement unlocks

2. **Consecutive days**:
   - Create entries for 7 consecutive days
   - Verify streak increments each day
   - Verify 7-day achievement unlocks on day 7

3. **Streak break**:
   - Skip a day (wait 48+ hours without journaling)
   - Open app → verify streak reset to 0
   - Verify longest streak preserved

4. **Calendar visualization**:
   - View monthly calendar
   - Verify active days show filled circles
   - Verify inactive days show empty circles
   - Verify today has border highlight

5. **Heatmap visualization**:
   - View yearly heatmap
   - Verify recent streak shows as filled squares
   - Verify heatmap scrolls horizontally

6. **Cross-device sync**:
   - Create streak on Device A
   - Log in on Device B
   - Verify streak syncs correctly

7. **Edge cases**:
   - Create entry at 11:59 PM
   - Create another at 12:01 AM
   - Verify both days count toward streak
   - Test across daylight saving time changes

---

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading**:
   - Load only current month's calendar data by default
   - Load heatmap data on tab switch
   - Paginate achievement list if user has many

2. **Caching**:
   - Cache daily activity data in Isar
   - Only recalculate streak when journal entries change
   - Use `watch()` streams for reactive updates

3. **Efficient Queries**:
   - Index `userId` and `date` fields in Isar
   - Use date range queries for calendar views
   - Limit Firestore reads with proper indexing

4. **Widget Optimization**:
   - Use `const` constructors where possible
   - Memoize expensive calculations
   - Avoid rebuilding entire dashboard on small changes

### Memory Management

- Dispose animation controllers properly
- Cancel stream subscriptions when widgets unmount
- Limit calendar date range to avoid loading years of data
- Use `ListView.builder` for long achievement lists

### Battery & Network

- Sync to Firestore on WiFi only (optional setting)
- Batch achievement syncs
- Avoid frequent recalculations (debounce if needed)

---

## Migration Notes

### Database Migration

No migration needed - this is a net-new feature. Isar will create new collections on first run:
- `streak_models`
- `daily_activity_models`
- `achievement_models`

### Data Backfill

For existing users with journal history:
- On first launch after update, trigger `calculateStreakUseCase`
- Will scan all existing journal entries
- Builds initial streak based on historical data
- Awards achievements retroactively if eligible

### Firestore Structure

New collections:
```
user_streaks/{userId}
  - currentStreak: int
  - longestStreak: int
  - totalActiveDays: int
  - lastActivityDate: string (YYYY-MM-DD)
  - currentWeekCount: int
  - createdAtMillis: int
  - updatedAtMillis: int

users/{userId}/achievements/{achievementId}
  - id: string
  - userId: string
  - typeIndex: int
  - unlockedAtMillis: int
```

### Backward Compatibility

- Feature is additive only - no breaking changes
- Existing journal functionality unchanged
- Can be rolled out gradually via feature flag if desired

---

## References

### Research & Documentation
- Flutter table_calendar package: [pub.dev/packages/table_calendar](https://pub.dev/packages/table_calendar)
- Flutter heatmap calendar: [pub.dev/packages/flutter_heatmap_calendar](https://pub.dev/packages/flutter_heatmap_calendar)
- GitHub contributions chart inspiration
- Material Design 3 guidelines for cards and visualization

### Related Code
- Journal message creation: `lib/features/journal/domain/entities/journal_message_entity.dart`
- Category Insights feature: `lib/features/category_insights/` (similar engagement tracking)
- Home screen: `lib/features/home/presentation/screens/home_screen.dart:1-83`
- Existing architecture patterns: All other features follow same clean architecture

### External Resources
- [GitHub: flutter_heatmap_calendar](https://github.com/devappmin/flutter_heatmap_calendar)
- [GitHub: table_calendar](https://github.com/aleksanderwozniak/table_calendar)
- [Flutter Gems: Calendar Packages](https://fluttergems.dev/calendar/)

---

## Implementation Checklist

### Phase 1: Core Streak Tracking System
- [ ] Add dependencies to pubspec.yaml
- [ ] Create domain entities (StreakEntity, DailyActivityEntity, AchievementEntity)
- [ ] Create repository interface
- [ ] Create Isar models (StreakModel, DailyActivityModel, AchievementModel)
- [ ] Update Isar schema in database_provider.dart
- [ ] Implement local datasource
- [ ] Implement remote datasource
- [ ] Run build_runner to generate Isar code
- [ ] Verify compilation

### Phase 2: Streak Calculation Engine
- [ ] Implement CalculateStreakUseCase
- [ ] Implement StreakRepositoryImpl
- [ ] Create Riverpod providers
- [ ] Test streak calculation logic
- [ ] Verify achievement awarding works

### Phase 3: Home Screen Integration
- [ ] Create StreakPreviewCard widget
- [ ] Add preview card to HomeScreen
- [ ] Trigger streak calculation after journal entry
- [ ] Test home screen integration
- [ ] Verify auto-updates work

### Phase 4: Streak Dashboard Screen
- [ ] Create MotivationalMessageWidget
- [ ] Create StreakStatsCard widget
- [ ] Create StreakCalendarView widget
- [ ] Create StreakHeatmapView widget
- [ ] Create AchievementBadgeWidget
- [ ] Assemble StreakDashboardScreen
- [ ] Add tab navigation
- [ ] Test dashboard rendering

### Phase 5: Polish & Enhancements
- [ ] Create milestone celebration dialog
- [ ] Add celebration animation
- [ ] Improve loading/error states
- [ ] Add pull-to-refresh
- [ ] Test animations and polish features

### Testing & Deployment
- [ ] Write unit tests for core logic
- [ ] Write integration tests for user flows
- [ ] Perform manual testing on real devices
- [ ] Test cross-device sync
- [ ] Test edge cases (timezone, midnight, etc.)
- [ ] Performance testing
- [ ] Deploy to staging environment
- [ ] User acceptance testing
- [ ] Deploy to production

---

## Next Steps After Implementation

1. **User Feedback**: Monitor how users engage with the streak feature
2. **Analytics**: Track streak retention rates and achievement unlock rates
3. **Iteration**: Add requested features based on feedback
4. **Phase 3 Enhancements** (Future):
   - Category-specific streaks
   - Streak protection/freeze tokens
   - Social sharing
   - Weekly goals with custom targets
   - Streak recovery (grace period)
   - Custom streak themes/icons

---

## Estimated Complexity

- **Phase 1**: 4-6 hours (data layer foundation)
- **Phase 2**: 3-4 hours (calculation engine)
- **Phase 3**: 2-3 hours (home screen integration)
- **Phase 4**: 6-8 hours (full dashboard with visualizations)
- **Phase 5**: 2-3 hours (polish and animations)
- **Testing**: 3-4 hours (unit + integration tests)

**Total**: ~20-28 hours for complete implementation

---

## Success Metrics

Post-launch, track:
- **Engagement**: % of users with active streaks
- **Retention**: Streak lengths distribution
- **Achievements**: Most/least unlocked achievements
- **Feature Usage**: Dashboard view frequency
- **Motivation Impact**: Correlation between streaks and overall journaling frequency

---

**End of Implementation Plan**
