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
      final querySnapshot =
          await _achievementsCollection(userId).orderBy('unlockedAtMillis', descending: true).get();

      return querySnapshot.docs.map((doc) => AchievementModel.fromMap(doc.data())).toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get achievements');
    }
  }

  @override
  Stream<List<AchievementModel>> watchAchievements(String userId) {
    return _achievementsCollection(userId)
        .orderBy('unlockedAtMillis', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => AchievementModel.fromMap(doc.data())).toList(),
        );
  }
}
