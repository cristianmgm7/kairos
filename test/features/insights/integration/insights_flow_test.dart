import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';

void main() {
  group('Insights Integration Tests', () {
    test('InsightEntity serialization round-trip', () {
      final now = DateTime.now();
      final entity = InsightEntity(
        id: 'test_id',
        userId: 'user_123',
        type: InsightType.thread,
        threadId: 'thread_456',
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 0.75,
        dominantEmotion: EmotionType.joy,
        keywords: const ['happy', 'productive', 'grateful'],
        aiThemes: const ['Positive outlook', 'Growth mindset'],
        summary: 'You had a positive week.',
        messageCount: 12,
        createdAt: now,
        updatedAt: now,
      );

      final model = InsightModel.fromEntity(entity);
      final backToEntity = model.toEntity();

      expect(backToEntity.id, entity.id);
      expect(backToEntity.moodScore, entity.moodScore);
      expect(backToEntity.dominantEmotion, entity.dominantEmotion);
      expect(backToEntity.keywords, entity.keywords);
      expect(backToEntity.aiThemes, entity.aiThemes);
    });

    test('InsightModel Firestore serialization', () {
      final now = DateTime.now();
      final model = InsightModel.create(
        userId: 'user_123',
        threadId: 'thread_456',
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 0.65,
        dominantEmotion: EmotionType.calm.index,
        keywords: const ['peaceful', 'centered'],
        aiThemes: const ['Mindfulness'],
        summary: 'You maintained calm.',
        messageCount: 8,
      );

      final map = model.toFirestoreMap();
      final deserialized = InsightModel.fromMap(map);

      expect(deserialized.moodScore, model.moodScore);
      expect(deserialized.dominantEmotion, model.dominantEmotion);
      expect(deserialized.keywords, model.keywords);
    });

    test('InsightModel ID generation for thread insights', () {
      final now = DateTime.now();
      final model = InsightModel.create(
        userId: 'user_123',
        threadId: 'thread_456',
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 0.5,
        dominantEmotion: EmotionType.neutral.index,
        keywords: const ['work', 'progress'],
        aiThemes: const ['Steady state'],
        summary: 'You maintained a steady pace.',
        messageCount: 5,
      );

      expect(model.id, startsWith('user_123_thread_456_'));
      expect(model.type, 0); // thread type
    });

    test('InsightModel ID generation for global insights', () {
      final now = DateTime.now();
      final model = InsightModel.create(
        userId: 'user_123',
        threadId: null, // Global insight
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 0.6,
        dominantEmotion: EmotionType.calm.index,
        keywords: const ['balance', 'reflection'],
        aiThemes: const ['Overall progress'],
        summary: 'Your overall mood has been balanced.',
        messageCount: 15,
      );

      expect(model.id, startsWith('user_123_global_'));
      expect(model.type, 1); // global type
      expect(model.threadId, isNull);
    });

    test('Mood score clamping in entity', () {
      final now = DateTime.now();
      
      // Test that entity can store boundary values
      final highEntity = InsightEntity(
        id: 'test_high',
        userId: 'user_123',
        type: InsightType.thread,
        threadId: 'thread_456',
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 1.0,
        dominantEmotion: EmotionType.joy,
        keywords: const ['excellent'],
        aiThemes: const ['Peak performance'],
        summary: 'Great week!',
        messageCount: 10,
        createdAt: now,
        updatedAt: now,
      );

      expect(highEntity.moodScore, 1.0);

      final lowEntity = InsightEntity(
        id: 'test_low',
        userId: 'user_123',
        type: InsightType.thread,
        threadId: 'thread_456',
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 0.0,
        dominantEmotion: EmotionType.sadness,
        keywords: const ['difficult'],
        aiThemes: const ['Challenging times'],
        summary: 'Tough week.',
        messageCount: 8,
        createdAt: now,
        updatedAt: now,
      );

      expect(lowEntity.moodScore, 0.0);
    });

    test('Emotion enum mapping consistency', () {
      // Verify that EmotionType enum values match expected indices
      expect(EmotionType.joy.index, 0);
      expect(EmotionType.calm.index, 1);
      expect(EmotionType.neutral.index, 2);
      expect(EmotionType.sadness.index, 3);
      expect(EmotionType.stress.index, 4);
      expect(EmotionType.anger.index, 5);
      expect(EmotionType.fear.index, 6);
      expect(EmotionType.excitement.index, 7);
    });

    test('InsightType enum mapping consistency', () {
      // Verify that InsightType enum values match expected indices
      expect(InsightType.thread.index, 0);
      expect(InsightType.global.index, 1);
    });

    test('InsightEntity copyWith works correctly', () {
      final now = DateTime.now();
      final original = InsightEntity(
        id: 'test_id',
        userId: 'user_123',
        type: InsightType.thread,
        threadId: 'thread_456',
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 0.5,
        dominantEmotion: EmotionType.neutral,
        keywords: const ['work'],
        aiThemes: const ['Progress'],
        summary: 'Original summary',
        messageCount: 5,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        moodScore: 0.7,
        summary: 'Updated summary',
      );

      expect(updated.id, original.id);
      expect(updated.moodScore, 0.7);
      expect(updated.summary, 'Updated summary');
      expect(updated.keywords, original.keywords);
    });

    test('InsightModel copyWith works correctly', () {
      final now = DateTime.now();
      final original = InsightModel.create(
        userId: 'user_123',
        threadId: 'thread_456',
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 0.5,
        dominantEmotion: EmotionType.neutral.index,
        keywords: const ['work'],
        aiThemes: const ['Progress'],
        summary: 'Original summary',
        messageCount: 5,
      );

      final updated = original.copyWith(
        moodScore: 0.8,
        messageCount: 10,
      );

      expect(updated.id, original.id);
      expect(updated.moodScore, 0.8);
      expect(updated.messageCount, 10);
      expect(updated.summary, original.summary);
    });
  });
}

