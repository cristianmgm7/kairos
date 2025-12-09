import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
// ignore: unused_import
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
      StreakModelSchema, // NEW
      DailyActivityModelSchema, // NEW
      AchievementModelSchema, // NEW
    ],
    directory: dir.path,
    name: 'kairos_db',
  );
}
