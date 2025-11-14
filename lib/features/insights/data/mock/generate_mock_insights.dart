import 'dart:math';

import 'package:isar/isar.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:path_provider/path_provider.dart';

/// Run this script to populate mock insights for testing
/// Execute from terminal: flutter run lib/features/insights/data/mock/generate_mock_insights.dart
Future<void> main() async {
  logger.i('🌱 Generating mock insights...');

  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [InsightModelSchema],
    directory: dir.path,
    name: 'kairos_db',
  );

  // Mock user and thread IDs
  const userId = 'mock_user_123';
  const threadIds = [
    'thread_work_stress',
    'thread_personal_growth',
    'thread_relationships',
  ];

  final random = Random();
  final now = DateTime.now();

  // Clear existing mock data
  await isar.writeTxn(() async {
    await isar.insightModels.filter().userIdEqualTo(userId).deleteAll();
  });

  logger.i('📝 Creating per-thread insights...');

  // Generate 5-7 insights per thread over the last 14 days
  for (final threadId in threadIds) {
    final insightCount = 5 + random.nextInt(3); // 5-7 insights

    for (var i = 0; i < insightCount; i++) {
      final daysAgo = i * 2; // Every 2 days
      final periodEnd = now.subtract(Duration(days: daysAgo));
      final periodStart = periodEnd.subtract(const Duration(days: 3));

      final insight = _generateMockInsight(
        userId: userId,
        threadId: threadId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        random: random,
      );

      await isar.writeTxn(() async {
        await isar.insightModels.put(insight);
      });

      logger.i('  ✓ Created insight for $threadId (${_formatDate(periodEnd)})');
    }
  }

  logger.i('🌍 Creating global insights...');

  // Generate 10 global insights
  for (var i = 0; i < 10; i++) {
    final daysAgo = i * 1; // Daily
    final periodEnd = now.subtract(Duration(days: daysAgo));
    final periodStart = periodEnd.subtract(const Duration(days: 3));

    final insight = _generateMockInsight(
      userId: userId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      random: random,
    );

    await isar.writeTxn(() async {
      await isar.insightModels.put(insight);
    });

    logger.i('  ✓ Created global insight (${_formatDate(periodEnd)})');
  }

  logger.i('✅ Mock data generation complete!');
  logger.i('   Total insights created: ${threadIds.length * 6 + 10}');

  await isar.close();
}

InsightModel _generateMockInsight({
  required String userId,
  required DateTime periodStart,
  required DateTime periodEnd,
  required Random random,
  String? threadId,
}) {
  // Generate realistic mood distribution:
  // 40% positive (0.6-0.9), 30% neutral (0.4-0.6), 30% challenging (0.1-0.4)
  final moodCategory = random.nextDouble();
  final double moodScore;
  final EmotionType dominantEmotion;

  if (moodCategory < 0.4) {
    // Positive mood
    moodScore = 0.6 + random.nextDouble() * 0.3; // 0.6 to 0.9
    final positiveEmotions = [EmotionType.joy, EmotionType.calm, EmotionType.excitement];
    dominantEmotion = positiveEmotions[random.nextInt(positiveEmotions.length)];
  } else if (moodCategory < 0.7) {
    // Neutral mood
    moodScore = 0.4 + random.nextDouble() * 0.2; // 0.4 to 0.6
    final neutralEmotions = [EmotionType.neutral, EmotionType.calm];
    dominantEmotion = neutralEmotions[random.nextInt(neutralEmotions.length)];
  } else {
    // Challenging mood
    moodScore = 0.15 + random.nextDouble() * 0.25; // 0.15 to 0.4
    final challengingEmotions = [
      EmotionType.sadness,
      EmotionType.stress,
      EmotionType.fear,
      EmotionType.anger,
    ];
    dominantEmotion = challengingEmotions[random.nextInt(challengingEmotions.length)];
  }

  // Generate keywords based on thread
  final keywords = _generateKeywords(threadId, random);

  // Generate AI themes
  final themes = _generateThemes(dominantEmotion, random);

  // Generate summary
  final summary = _generateSummary(dominantEmotion, moodScore, threadId);

  final messageCount = 5 + random.nextInt(15); // 5-20 messages

  return InsightModel.create(
    userId: userId,
    threadId: threadId,
    periodStart: periodStart,
    periodEnd: periodEnd,
    moodScore: moodScore,
    dominantEmotion: dominantEmotion.value,
    keywords: keywords,
    aiThemes: themes,
    summary: summary,
    messageCount: messageCount,
  );
}

List<String> _generateKeywords(String? threadId, Random random) {
  final keywordSets = {
    'thread_work_stress': [
      'deadline',
      'project',
      'meeting',
      'team',
      'stress',
      'productivity',
      'goals',
      'progress',
      'challenges',
      'success',
    ],
    'thread_personal_growth': [
      'learning',
      'habits',
      'meditation',
      'exercise',
      'reading',
      'goals',
      'mindfulness',
      'growth',
      'reflection',
      'progress',
    ],
    'thread_relationships': [
      'family',
      'friends',
      'communication',
      'support',
      'connection',
      'understanding',
      'quality time',
      'listening',
      'empathy',
      'boundaries',
    ],
  };

  final globalKeywords = [
    'feeling',
    'today',
    'better',
    'working',
    'trying',
    'thinking',
    'positive',
    'grateful',
    'challenge',
    'improvement',
  ];

  final pool = threadId != null ? (keywordSets[threadId] ?? globalKeywords) : globalKeywords;

  final shuffled = List<String>.from(pool)..shuffle(random);
  return shuffled.take(10).toList();
}

List<String> _generateThemes(EmotionType emotion, Random random) {
  final themeSets = {
    EmotionType.joy: [
      'Celebrating small wins',
      'Positive outlook on challenges',
      'Gratitude practice',
      'Strong social connections',
      'Sense of accomplishment',
    ],
    EmotionType.calm: [
      'Inner peace and balance',
      'Mindfulness practice',
      'Healthy boundaries',
      'Self-care routines',
      'Stress management',
    ],
    EmotionType.neutral: [
      'Steady emotional state',
      'Routine maintenance',
      'Balanced perspective',
      'Processing experiences',
      'Gradual progress',
    ],
    EmotionType.sadness: [
      'Processing difficult emotions',
      'Seeking support',
      'Self-compassion',
      'Acknowledging feelings',
      'Gentle self-reflection',
    ],
    EmotionType.stress: [
      'Managing overwhelm',
      'Time pressure concerns',
      'Seeking coping strategies',
      'Workload balance',
      'Need for rest',
    ],
    EmotionType.anger: [
      'Expressing frustration',
      'Setting boundaries',
      'Processing conflict',
      'Seeking resolution',
      'Emotional release',
    ],
    EmotionType.fear: [
      'Facing uncertainties',
      'Building courage',
      'Addressing anxieties',
      'Seeking reassurance',
      'Gradual exposure',
    ],
    EmotionType.excitement: [
      'Anticipating positive changes',
      'New opportunities',
      'Creative energy',
      'Motivated action',
      'Future planning',
    ],
  };

  final pool = themeSets[emotion] ?? themeSets[EmotionType.neutral]!;
  final shuffled = List<String>.from(pool)..shuffle(random);
  return shuffled.take(5).toList();
}

String _generateSummary(EmotionType emotion, double moodScore, String? threadId) {
  final moodDescriptors = {
    'high': ['positive', 'optimistic', 'energized', 'motivated'],
    'medium': ['balanced', 'steady', 'reflective', 'thoughtful'],
    'low': ['challenging', 'difficult', 'contemplative', 'processing'],
  };

  final moodCategory = moodScore > 0.6
      ? 'high'
      : moodScore < 0.4
          ? 'low'
          : 'medium';
  final descriptor = (moodDescriptors[moodCategory]!..shuffle()).first;

  final emotionDescriptors = {
    EmotionType.joy: 'experiencing joy and satisfaction',
    EmotionType.calm: 'maintaining a calm and centered state',
    EmotionType.neutral: 'in a neutral and observant state',
    EmotionType.sadness: 'processing sadness and seeking comfort',
    EmotionType.stress: 'managing stress and seeking balance',
    EmotionType.anger: 'expressing frustration and seeking resolution',
    EmotionType.fear: 'working through fears and building courage',
    EmotionType.excitement: 'feeling excited about possibilities',
  };

  final context = threadId != null
      ? 'in your ${threadId.replaceAll('thread_', '').replaceAll('_', ' ')} conversations'
      : 'overall';

  return "You've been $descriptor $context, ${emotionDescriptors[emotion]}. "
      'Your reflections show genuine engagement with your emotional journey.';
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
