# Insights Feature Implementation Plan

## Overview

Implement a comprehensive Insights feature for Kairos that transforms journal conversations into actionable emotional and behavioral insights. This feature provides users with real-time feedback on their mood patterns, emotional trends, and recurring themes without waiting for weekly aggregation. The system uses AI-powered analysis to generate short-term insights from rolling 2-3 day windows of journal activity.

## Current State Analysis

### Existing Architecture
- **Journal System**: Users create threads with AI conversations (text, audio, image messages)
- **AI Integration**: Cloud Functions process messages using Gemini 2.0 Flash via Genkit
- **Data Architecture**: Clean Architecture with offline-first sync (Isar local + Firestore remote)
- **State Management**: Riverpod providers with StreamProviders for reactive UI
- **Dashboard**: Minimal home screen showing welcome message and profile info

### Current Patterns to Follow
- **Repository Pattern**: [journal_message_repository_impl.dart:14-237](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L14-L237)
- **Model Structure**: [journal_message_model.dart:7-231](lib/features/journal/data/models/journal_message_model.dart#L7-L231)
- **Cloud Functions**: [index.ts:18-713](functions/src/index.ts#L18-L713)
- **Bidirectional Sync**: [journal_message_repository_impl.dart:96-181](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L96-L181)

### Key Discoveries
- Cloud Functions already integrate with Gemini for message processing
- Existing metrics logging infrastructure in [monitoring.ts](functions/src/monitoring.ts)
- No chart packages installed (need to add `fl_chart`)
- Bottom navigation uses Material 3 NavigationBar with 4 tabs
- Home screen currently minimal, ready for dashboard widgets

## Desired End State

### Functional Requirements
1. **Automated Insight Generation**: Cloud Function triggers on AI responses, analyzing last 2-3 days
2. **Dual Insight Types**: Per-thread insights + global aggregated insights
3. **Rich Mood Analysis**: Mood score (0-1), dominant emotion, keywords, AI themes
4. **Visual Dashboard**: Bar chart (mood over time) + pie chart (emotion distribution)
5. **Offline-First**: Local insights sync with real-time Firestore updates
6. **Mock Data Seeding**: Dart script to generate test insights for UI development

### Technical Requirements
- **Firestore Collection**: `insights` with documents `{userId}_{threadId}_{timestamp}` or `{userId}_global_{timestamp}`
- **Isar Collection**: InsightModel with offline sync capability
- **Cloud Function**: `generateInsight` triggered by message updates
- **Repository**: InsightRepository with watch streams and sync logic
- **UI Components**: Mood chart widget, emotion distribution widget
- **Riverpod Providers**: InsightStreamProvider, chart data providers

### Verification Criteria
- Insights generate within 5 seconds of AI response
- Dashboard charts update in real-time when new insights arrive
- Offline mode displays cached insights without errors
- Mock data populates correctly with realistic mood variations
- Per-thread and global insights aggregate correctly

## What We're NOT Doing

- **Weekly aggregation logic** (focusing on short-term rolling windows)
- **Push notifications** for insight updates (may add later)
- **Guidance recommendations** (placeholder fields only, implementation deferred)
- **Export functionality** (insights export to PDF/CSV - future feature)
- **Multi-user comparison** (social features not in scope)
- **Advanced NLP** beyond Gemini's capabilities (no custom models)
- **Historical data migration** (only generates insights going forward)

## Implementation Approach

### Strategy
1. **Bottom-up Implementation**: Start with data models, then Cloud Functions, then repository, then UI
2. **Parallel Development Tracks**: Backend (Cloud Functions) and Frontend (Flutter) can progress simultaneously after models are defined
3. **Test-First for Mock Data**: Create seeding script early to enable UI development before backend is complete
4. **Incremental Deployment**: Deploy Cloud Functions first, then mobile app updates

### Architecture Decisions
- **Insight ID Format**: `{userId}_{threadId}_{startMillis}` for per-thread, `{userId}_global_{startMillis}` for global
- **Insight Type Field**: `type: "thread" | "global"` for clear Firestore queries and UI filtering
- **Rolling Window Logic**: Cloud Function queries messages from `now - 3 days` to `now`
- **Trigger Debouncing**: Update insights at most once per hour per user to prevent over-firing on quick message bursts
- **Aggregation Strategy**: Global insights created by merging all per-thread insights from same time window
- **Emotion Mapping**: Fixed enum (joy, calm, neutral, sadness, stress, anger, fear, excitement)
- **Mood Scoring**: AI returns direct 0-1 score (clamped and validated), not qualitative labels
- **Keyword Limit**: Top 10 keywords by frequency, top 5 AI themes
- **Summary Tone**: Supportive and encouraging, never diagnostic (enforced via Genkit prompt)

---

## Phase 1: Data Models and Firestore Schema

### Overview
Define domain entities and data models for Insights, establish Firestore collection structure, and register Isar schemas.

### Changes Required

#### 1. Domain Entity
**File**: `lib/features/insights/domain/entities/insight_entity.dart`
**Changes**: Create new entity class

```dart
import 'package:equatable/equatable.dart';

enum EmotionType {
  joy,
  calm,
  neutral,
  sadness,
  stress,
  anger,
  fear,
  excitement,
}

enum InsightType {
  thread,
  global,
}

class InsightEntity extends Equatable {
  const InsightEntity({
    required this.id,
    required this.userId,
    required this.type,
    this.threadId, // null for global insights
    required this.periodStart,
    required this.periodEnd,
    required this.moodScore,
    required this.dominantEmotion,
    required this.keywords,
    required this.aiThemes,
    required this.summary,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
    this.guidanceSuggestion, // Placeholder for future Guidance feature
    this.actionPrompt, // Placeholder for future Guidance feature
    this.metadata,
  });

  final String id;
  final String userId;
  final InsightType type;
  final String? threadId; // null for global insights
  final DateTime periodStart;
  final DateTime periodEnd;
  final double moodScore; // 0.0 to 1.0
  final EmotionType dominantEmotion;
  final List<String> keywords; // Top 10 keywords by frequency
  final List<String> aiThemes; // Top 5 AI-extracted themes
  final String summary; // Natural language summary
  final int messageCount; // Number of messages analyzed
  final DateTime createdAt;
  final DateTime updatedAt;

  // Future-compatibility fields
  final String? guidanceSuggestion;
  final String? actionPrompt;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        threadId,
        periodStart,
        periodEnd,
        moodScore,
        dominantEmotion,
        keywords,
        aiThemes,
        summary,
        messageCount,
        createdAt,
        updatedAt,
        guidanceSuggestion,
        actionPrompt,
        metadata,
      ];

  InsightEntity copyWith({
    String? id,
    String? userId,
    InsightType? type,
    String? threadId,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? moodScore,
    EmotionType? dominantEmotion,
    List<String>? keywords,
    List<String>? aiThemes,
    String? summary,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? guidanceSuggestion,
    String? actionPrompt,
    Map<String, dynamic>? metadata,
  }) {
    return InsightEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      threadId: threadId ?? this.threadId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      moodScore: moodScore ?? this.moodScore,
      dominantEmotion: dominantEmotion ?? this.dominantEmotion,
      keywords: keywords ?? this.keywords,
      aiThemes: aiThemes ?? this.aiThemes,
      summary: summary ?? this.summary,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      guidanceSuggestion: guidanceSuggestion ?? this.guidanceSuggestion,
      actionPrompt: actionPrompt ?? this.actionPrompt,
      metadata: metadata ?? this.metadata,
    );
  }
}
```

#### 2. Data Model
**File**: `lib/features/insights/data/models/insight_model.dart`
**Changes**: Create Isar collection model

```dart
import 'package:isar/isar.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:uuid/uuid.dart';

part 'insight_model.g.dart';

@collection
class InsightModel {
  InsightModel({
    required this.id,
    required this.userId,
    required this.type,
    this.threadId,
    required this.periodStartMillis,
    required this.periodEndMillis,
    required this.moodScore,
    required this.dominantEmotion,
    required this.keywords,
    required this.aiThemes,
    required this.summary,
    required this.messageCount,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    this.guidanceSuggestion,
    this.actionPrompt,
    this.isDeleted = false,
    this.version = 1,
  });

  /// Factory constructor for creating new insights
  factory InsightModel.create({
    required String userId,
    String? threadId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double moodScore,
    required int dominantEmotion,
    required List<String> keywords,
    required List<String> aiThemes,
    required String summary,
    required int messageCount,
  }) {
    final now = DateTime.now().toUtc();
    final startMillis = periodStart.millisecondsSinceEpoch;
    final insightType = threadId != null ? 0 : 1; // 0=thread, 1=global
    final insightId = threadId != null
        ? '${userId}_${threadId}_$startMillis'
        : '${userId}_global_$startMillis';

    return InsightModel(
      id: insightId,
      userId: userId,
      type: insightType,
      threadId: threadId,
      periodStartMillis: startMillis,
      periodEndMillis: periodEnd.millisecondsSinceEpoch,
      moodScore: moodScore,
      dominantEmotion: dominantEmotion,
      keywords: keywords,
      aiThemes: aiThemes,
      summary: summary,
      messageCount: messageCount,
      createdAtMillis: now.millisecondsSinceEpoch,
      updatedAtMillis: now.millisecondsSinceEpoch,
    );
  }

  factory InsightModel.fromEntity(InsightEntity entity) {
    return InsightModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type.index,
      threadId: entity.threadId,
      periodStartMillis: entity.periodStart.millisecondsSinceEpoch,
      periodEndMillis: entity.periodEnd.millisecondsSinceEpoch,
      moodScore: entity.moodScore,
      dominantEmotion: entity.dominantEmotion.index,
      keywords: entity.keywords,
      aiThemes: entity.aiThemes,
      summary: entity.summary,
      messageCount: entity.messageCount,
      createdAtMillis: entity.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: entity.updatedAt.millisecondsSinceEpoch,
      guidanceSuggestion: entity.guidanceSuggestion,
      actionPrompt: entity.actionPrompt,
    );
  }

  factory InsightModel.fromMap(Map<String, dynamic> map) {
    return InsightModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as int,
      threadId: map['threadId'] as String?,
      periodStartMillis: map['periodStartMillis'] as int,
      periodEndMillis: map['periodEndMillis'] as int,
      moodScore: (map['moodScore'] as num).toDouble(),
      dominantEmotion: map['dominantEmotion'] as int,
      keywords: List<String>.from(map['keywords'] as List),
      aiThemes: List<String>.from(map['aiThemes'] as List),
      summary: map['summary'] as String,
      messageCount: map['messageCount'] as int,
      createdAtMillis: map['createdAtMillis'] as int,
      updatedAtMillis: map['updatedAtMillis'] as int,
      guidanceSuggestion: map['guidanceSuggestion'] as String?,
      actionPrompt: map['actionPrompt'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
    );
  }

  @Index(unique: true)
  final String id;

  @Index()
  final String userId;

  final int type; // 0=thread, 1=global (InsightType.index)

  @Index()
  final String? threadId; // null for global insights

  final int periodStartMillis;
  final int periodEndMillis;
  final double moodScore;
  final int dominantEmotion; // EmotionType.index
  final List<String> keywords;
  final List<String> aiThemes;
  final String summary;
  final int messageCount;
  final int createdAtMillis;
  final int updatedAtMillis;

  // Future-compatibility fields
  final String? guidanceSuggestion;
  final String? actionPrompt;

  final bool isDeleted;
  final int version;

  Id get isarId => fastHash(id);

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'threadId': threadId,
      'periodStartMillis': periodStartMillis,
      'periodEndMillis': periodEndMillis,
      'moodScore': moodScore,
      'dominantEmotion': dominantEmotion,
      'keywords': keywords,
      'aiThemes': aiThemes,
      'summary': summary,
      'messageCount': messageCount,
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis,
      'guidanceSuggestion': guidanceSuggestion,
      'actionPrompt': actionPrompt,
      'isDeleted': isDeleted,
      'version': version,
    };
  }

  InsightEntity toEntity() {
    return InsightEntity(
      id: id,
      userId: userId,
      type: InsightType.values[type],
      threadId: threadId,
      periodStart: DateTime.fromMillisecondsSinceEpoch(periodStartMillis, isUtc: true),
      periodEnd: DateTime.fromMillisecondsSinceEpoch(periodEndMillis, isUtc: true),
      moodScore: moodScore,
      dominantEmotion: EmotionType.values[dominantEmotion],
      keywords: keywords,
      aiThemes: aiThemes,
      summary: summary,
      messageCount: messageCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMillis, isUtc: true),
      guidanceSuggestion: guidanceSuggestion,
      actionPrompt: actionPrompt,
    );
  }

  InsightModel copyWith({
    String? id,
    String? userId,
    String? threadId,
    int? periodStartMillis,
    int? periodEndMillis,
    double? moodScore,
    int? dominantEmotion,
    List<String>? keywords,
    List<String>? aiThemes,
    String? summary,
    int? messageCount,
    int? createdAtMillis,
    int? updatedAtMillis,
    String? guidanceSuggestion,
    String? actionPrompt,
    bool? isDeleted,
    int? version,
  }) {
    return InsightModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      threadId: threadId ?? this.threadId,
      periodStartMillis: periodStartMillis ?? this.periodStartMillis,
      periodEndMillis: periodEndMillis ?? this.periodEndMillis,
      moodScore: moodScore ?? this.moodScore,
      dominantEmotion: dominantEmotion ?? this.dominantEmotion,
      keywords: keywords ?? this.keywords,
      aiThemes: aiThemes ?? this.aiThemes,
      summary: summary ?? this.summary,
      messageCount: messageCount ?? this.messageCount,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      guidanceSuggestion: guidanceSuggestion ?? this.guidanceSuggestion,
      actionPrompt: actionPrompt ?? this.actionPrompt,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
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

#### 3. Register Isar Schema
**File**: `lib/core/providers/database_provider.dart`
**Changes**: Add InsightModelSchema to Isar.open

```dart
// Add import at top
import 'package:kairos/features/insights/data/models/insight_model.dart';

// Update initializeIsar function
Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  return Isar.open(
    [
      UserProfileModelSchema,
      SettingsModelSchema,
      JournalThreadModelSchema,
      JournalMessageModelSchema,
      InsightModelSchema, // ADD THIS LINE
    ],
    directory: dir.path,
    name: 'kairos_db',
  );
}
```

#### 4. Generate Isar Code
**Command**: Run build_runner to generate `.g.dart` files

```bash
~/flutter/bin/flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Success Criteria

#### Automated Verification:
- [ ] Build runner generates `insight_model.g.dart` without errors
- [ ] Dart analyzer passes: `~/flutter/bin/flutter analyze`
- [ ] No import errors in the codebase
- [ ] Isar database initializes with InsightModelSchema

#### Manual Verification:
- [ ] InsightEntity can be created and serialized correctly
- [ ] InsightModel converts to/from entity without data loss
- [ ] Enum values map correctly (EmotionType index matches storage)
- [ ] ID generation follows expected format pattern

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 2.

---

## Phase 2: Cloud Function for Insight Generation

### Overview
Implement Firebase Cloud Function that triggers on AI message responses, analyzes recent journal messages, extracts mood/emotion/keywords/themes using Gemini, and saves insights to Firestore.

### Changes Required

#### 1. Insight Analysis Helper Functions
**File**: `functions/src/insights-helper.ts` (new file)
**Changes**: Create helper utilities for insight generation

```typescript
import * as admin from 'firebase-admin';
import { googleAI } from '@genkit-ai/google-genai';

interface MessageData {
  content: string;
  role: number; // 0=user, 1=ai
  createdAtMillis: number;
}

interface InsightAnalysis {
  moodScore: number;
  dominantEmotion: number;
  keywords: string[];
  aiThemes: string[];
  summary: string;
}

/**
 * Extract keywords from messages using simple frequency analysis
 */
export function extractKeywords(messages: MessageData[]): string[] {
  const stopWords = new Set([
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
    'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'can', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
    'my', 'your', 'his', 'her', 'its', 'our', 'their', 'this', 'that', 'these',
    'those', 'am', 'me', 'im', 'ive', 'dont', 'cant', 'wont', 'didnt',
  ]);

  const wordFreq = new Map<string, number>();

  messages.forEach(msg => {
    if (!msg.content) return;

    const words = msg.content
      .toLowerCase()
      .replace(/[^\w\s]/g, '')
      .split(/\s+/)
      .filter(word => word.length > 3 && !stopWords.has(word));

    words.forEach(word => {
      wordFreq.set(word, (wordFreq.get(word) || 0) + 1);
    });
  });

  // Sort by frequency and return top 10
  return Array.from(wordFreq.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([word]) => word);
}

/**
 * Analyze messages using Gemini to extract mood, emotion, themes, and summary
 */
export async function analyzeMessagesWithAI(
  ai: any,
  messages: MessageData[]
): Promise<InsightAnalysis> {
  const conversationText = messages
    .map(msg => {
      const role = msg.role === 0 ? 'User' : 'Assistant';
      return `${role}: ${msg.content || '[media message]'}`;
    })
    .join('\n');

  const prompt = `Analyze the following journal conversation and provide a psychological insight.

Conversation:
${conversationText}

Provide your analysis in the following JSON format (respond with ONLY valid JSON, no markdown):
{
  "moodScore": <number between 0.0 and 1.0, where 0 is very negative and 1 is very positive>,
  "dominantEmotion": <number: 0=joy, 1=calm, 2=neutral, 3=sadness, 4=stress, 5=anger, 6=fear, 7=excitement>,
  "aiThemes": [<array of 3-5 key psychological themes as strings>],
  "summary": "<2-3 sentence natural language summary of the user's emotional state and progress>"
}`;

  const response = await ai.generate({
    prompt: [{ text: prompt }],
    config: {
      temperature: 0.3, // Lower temperature for more consistent analysis
      maxOutputTokens: 500,
    },
  });

  try {
    // Extract JSON from response (handle potential markdown wrapping)
    let jsonText = response.text.trim();

    // Remove markdown code blocks if present
    if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```json?\n?/g, '').replace(/```\n?$/g, '');
    }

    const analysis = JSON.parse(jsonText);

    return {
      moodScore: Math.max(0, Math.min(1, analysis.moodScore)),
      dominantEmotion: analysis.dominantEmotion,
      keywords: [], // Will be filled by extractKeywords
      aiThemes: analysis.aiThemes.slice(0, 5),
      summary: analysis.summary,
    };
  } catch (error) {
    console.error('Failed to parse AI analysis:', error);
    console.error('Raw response:', response.text);

    // Fallback to neutral values
    return {
      moodScore: 0.5,
      dominantEmotion: 2, // neutral
      keywords: [],
      aiThemes: ['Unable to analyze conversation'],
      summary: 'Analysis unavailable at this time.',
    };
  }
}

/**
 * Aggregate multiple per-thread insights into a global insight
 */
export function aggregateInsights(threadInsights: any[]): any {
  if (threadInsights.length === 0) {
    return null;
  }

  // Average mood score
  const avgMoodScore =
    threadInsights.reduce((sum, ins) => sum + ins.moodScore, 0) /
    threadInsights.length;

  // Count emotions and find dominant
  const emotionCounts = new Map<number, number>();
  threadInsights.forEach(ins => {
    const emotion = ins.dominantEmotion;
    emotionCounts.set(emotion, (emotionCounts.get(emotion) || 0) + 1);
  });
  const dominantEmotion = Array.from(emotionCounts.entries()).sort(
    (a, b) => b[1] - a[1]
  )[0][0];

  // Merge keywords (deduplicate and take top 10)
  const allKeywords = new Set<string>();
  threadInsights.forEach(ins => {
    ins.keywords.forEach((kw: string) => allKeywords.add(kw));
  });
  const keywords = Array.from(allKeywords).slice(0, 10);

  // Merge AI themes (deduplicate and take top 5)
  const allThemes = new Set<string>();
  threadInsights.forEach(ins => {
    ins.aiThemes.forEach((theme: string) => allThemes.add(theme));
  });
  const aiThemes = Array.from(allThemes).slice(0, 5);

  // Create aggregated summary
  const summary = `Across ${threadInsights.length} conversation${
    threadInsights.length > 1 ? 's' : ''
  }, your overall mood has been ${
    avgMoodScore > 0.6 ? 'positive' : avgMoodScore < 0.4 ? 'challenging' : 'neutral'
  }. Key themes include: ${aiThemes.join(', ')}.`;

  // Sum message counts
  const messageCount = threadInsights.reduce(
    (sum, ins) => sum + ins.messageCount,
    0
  );

  return {
    moodScore: avgMoodScore,
    dominantEmotion,
    keywords,
    aiThemes,
    summary,
    messageCount,
  };
}
```

#### 2. Generate Insight Cloud Function
**File**: `functions/src/index.ts`
**Changes**: Add new onDocumentCreated trigger

```typescript
// Add import at top
import {
  extractKeywords,
  analyzeMessagesWithAI,
  aggregateInsights,
} from './insights-helper';

// Add new function (insert after retryAiResponse function)

/**
 * Firestore trigger: When a new AI message is created,
 * generate or update insights for the thread and global view
 *
 * Hybrid approach:
 * - Updates existing insight if within 2-3 day window
 * - Creates new insight if no recent insight exists
 */
export const generateInsight = onDocumentCreated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    // Only process AI messages (role = 1)
    if (messageData.role !== 1) {
      console.log('Skipping non-AI message for insight generation');
      return;
    }

    const threadId = messageData.threadId as string;
    const userId = messageData.userId as string;
    const now = Date.now();
    const threeDaysAgo = now - 3 * 24 * 60 * 60 * 1000;

    console.log(`Generating insight for thread ${threadId}`);

    try {
      // 1. Query recent messages from this thread (last 3 days)
      const messagesSnapshot = await db
        .collection('journalMessages')
        .where('threadId', '==', threadId)
        .where('userId', '==', userId)
        .where('isDeleted', '==', false)
        .where('createdAtMillis', '>=', threeDaysAgo)
        .orderBy('createdAtMillis', 'asc')
        .get();

      if (messagesSnapshot.empty) {
        console.log('No recent messages found for insight generation');
        return;
      }

      const messages = messagesSnapshot.docs.map(doc => ({
        content: doc.data().content || doc.data().transcription || '',
        role: doc.data().role,
        createdAtMillis: doc.data().createdAtMillis,
      }));

      // 2. Extract keywords using frequency analysis
      const keywords = extractKeywords(messages);

      // 3. Analyze with AI
      const ai = getAI(geminiApiKey.value());
      const analysis = await analyzeMessagesWithAI(ai, messages);
      analysis.keywords = keywords;

      // 4. Determine period start/end
      const periodStart = messages[0].createdAtMillis;
      const periodEnd = now;

      // 5. Check if recent per-thread insight exists (within last 24 hours)
      const recentInsightSnapshot = await db
        .collection('insights')
        .where('userId', '==', userId)
        .where('threadId', '==', threadId)
        .where('periodEndMillis', '>=', now - 24 * 60 * 60 * 1000)
        .limit(1)
        .get();

      let insightId: string;
      let insightRef: admin.firestore.DocumentReference;

      if (!recentInsightSnapshot.empty) {
        // Update existing insight
        const existingInsight = recentInsightSnapshot.docs[0];
        insightId = existingInsight.id;
        insightRef = existingInsight.ref;

        await insightRef.update({
          periodEndMillis: periodEnd,
          moodScore: analysis.moodScore,
          dominantEmotion: analysis.dominantEmotion,
          keywords: analysis.keywords,
          aiThemes: analysis.aiThemes,
          summary: analysis.summary,
          messageCount: messages.length,
          updatedAtMillis: now,
        });

        console.log(`Updated existing insight ${insightId}`);
      } else {
        // Create new per-thread insight
        insightId = `${userId}_${threadId}_${periodStart}`;
        insightRef = db.collection('insights').doc(insightId);

        await insightRef.set({
          id: insightId,
          userId,
          threadId,
          periodStartMillis: periodStart,
          periodEndMillis: periodEnd,
          moodScore: analysis.moodScore,
          dominantEmotion: analysis.dominantEmotion,
          keywords: analysis.keywords,
          aiThemes: analysis.aiThemes,
          summary: analysis.summary,
          messageCount: messages.length,
          createdAtMillis: now,
          updatedAtMillis: now,
          isDeleted: false,
          version: 1,
        });

        console.log(`Created new insight ${insightId}`);
      }

      // 6. Generate or update global insight
      await generateGlobalInsight(userId, now);

      console.log(`Insight generation complete for thread ${threadId}`);
    } catch (error) {
      console.error('Error generating insight:', error);
    }
  }
);

/**
 * Helper function to generate global aggregated insight
 */
async function generateGlobalInsight(userId: string, now: number) {
  try {
    const threeDaysAgo = now - 3 * 24 * 60 * 60 * 1000;

    // Get all per-thread insights from last 3 days
    const threadInsightsSnapshot = await db
      .collection('insights')
      .where('userId', '==', userId)
      .where('threadId', '!=', null)
      .where('periodEndMillis', '>=', threeDaysAgo)
      .get();

    if (threadInsightsSnapshot.empty) {
      console.log('No thread insights found for global aggregation');
      return;
    }

    const threadInsights = threadInsightsSnapshot.docs.map(doc => doc.data());

    // Aggregate thread insights
    const aggregated = aggregateInsights(threadInsights);
    if (!aggregated) return;

    // Find earliest periodStart among thread insights
    const periodStart = Math.min(
      ...threadInsights.map(ins => ins.periodStartMillis)
    );

    // Check if recent global insight exists (within last 24 hours)
    const recentGlobalSnapshot = await db
      .collection('insights')
      .where('userId', '==', userId)
      .where('threadId', '==', null)
      .where('periodEndMillis', '>=', now - 24 * 60 * 60 * 1000)
      .limit(1)
      .get();

    let globalInsightId: string;
    let globalRef: admin.firestore.DocumentReference;

    if (!recentGlobalSnapshot.empty) {
      // Update existing global insight
      const existingGlobal = recentGlobalSnapshot.docs[0];
      globalInsightId = existingGlobal.id;
      globalRef = existingGlobal.ref;

      await globalRef.update({
        periodEndMillis: now,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
        updatedAtMillis: now,
      });

      console.log(`Updated global insight ${globalInsightId}`);
    } else {
      // Create new global insight
      globalInsightId = `${userId}_global_${periodStart}`;
      globalRef = db.collection('insights').doc(globalInsightId);

      await globalRef.set({
        id: globalInsightId,
        userId,
        threadId: null,
        periodStartMillis: periodStart,
        periodEndMillis: now,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
        createdAtMillis: now,
        updatedAtMillis: now,
        isDeleted: false,
        version: 1,
      });

      console.log(`Created global insight ${globalInsightId}`);
    }
  } catch (error) {
    console.error('Error generating global insight:', error);
  }
}
```

#### 3. Update Package Dependencies
**File**: `functions/package.json`
**Changes**: No new dependencies needed (uses existing Genkit/Gemini setup)

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compiles without errors: `npm run build` in functions directory
- [ ] Linting passes: `npm run lint` in functions directory
- [ ] Function deploys successfully: `firebase deploy --only functions:generateInsight`
- [ ] Cloud Function appears in Firebase Console

#### Manual Verification:
- [ ] Create a test journal message with AI response
- [ ] Verify insight document created in Firestore `insights` collection
- [ ] Check insight has correct fields (moodScore, dominantEmotion, keywords, etc.)
- [ ] Verify global insight aggregates multiple thread insights
- [ ] Test update logic by adding another message within 24 hours
- [ ] Check Cloud Function logs for successful execution

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 3.

---

## Phase 3: Repository and Data Sources

### Overview
Implement repository pattern for Insights following the existing journal repository architecture, including local/remote data sources and offline-first sync logic.

### Changes Required

#### 1. Local Data Source Interface
**File**: `lib/features/insights/data/datasources/insight_local_datasource.dart`
**Changes**: Create interface and implementation

```dart
import 'package:isar/isar.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';

abstract class InsightLocalDataSource {
  Future<void> saveInsight(InsightModel insight);
  Future<InsightModel?> getInsightById(String insightId);
  Future<List<InsightModel>> getInsightsByUserId(String userId);
  Future<List<InsightModel>> getGlobalInsights(String userId);
  Future<List<InsightModel>> getThreadInsights(String threadId);
  Stream<List<InsightModel>> watchGlobalInsights(String userId);
  Stream<List<InsightModel>> watchThreadInsights(String threadId);
  Future<void> updateInsight(InsightModel insight);
  Future<void> deleteInsight(String insightId);
}

class InsightLocalDataSourceImpl implements InsightLocalDataSource {
  InsightLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<void> saveInsight(InsightModel insight) async {
    await isar.writeTxn(() async {
      await isar.insightModels.put(insight);
    });
  }

  @override
  Future<InsightModel?> getInsightById(String insightId) async {
    return isar.insightModels
        .filter()
        .idEqualTo(insightId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<List<InsightModel>> getInsightsByUserId(String userId) async {
    return isar.insightModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .sortByPeriodEndMillisDesc()
        .findAll();
  }

  @override
  Future<List<InsightModel>> getGlobalInsights(String userId) async {
    return isar.insightModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .threadIdIsNull()
        .and()
        .isDeletedEqualTo(false)
        .sortByPeriodEndMillisDesc()
        .findAll();
  }

  @override
  Future<List<InsightModel>> getThreadInsights(String threadId) async {
    return isar.insightModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .sortByPeriodEndMillisDesc()
        .findAll();
  }

  @override
  Stream<List<InsightModel>> watchGlobalInsights(String userId) {
    return isar.insightModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .threadIdIsNull()
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((insights) {
      final sorted = insights.toList()
        ..sort((a, b) => b.periodEndMillis.compareTo(a.periodEndMillis));
      return sorted;
    });
  }

  @override
  Stream<List<InsightModel>> watchThreadInsights(String threadId) {
    return isar.insightModels
        .filter()
        .threadIdEqualTo(threadId)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((insights) {
      final sorted = insights.toList()
        ..sort((a, b) => b.periodEndMillis.compareTo(a.periodEndMillis));
      return sorted;
    });
  }

  @override
  Future<void> updateInsight(InsightModel insight) async {
    await isar.writeTxn(() async {
      await isar.insightModels.put(insight);
    });
  }

  @override
  Future<void> deleteInsight(String insightId) async {
    await isar.writeTxn(() async {
      final insight = await isar.insightModels
          .filter()
          .idEqualTo(insightId)
          .findFirst();

      if (insight != null) {
        final deleted = insight.copyWith(isDeleted: true);
        await isar.insightModels.put(deleted);
      }
    });
  }
}
```

#### 2. Remote Data Source Interface
**File**: `lib/features/insights/data/datasources/insight_remote_datasource.dart`
**Changes**: Create interface and implementation

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';

abstract class InsightRemoteDataSource {
  Future<void> saveInsight(InsightModel insight);
  Future<InsightModel?> getInsightById(String insightId);
  Future<List<InsightModel>> getGlobalInsights(String userId);
  Future<List<InsightModel>> getThreadInsights(String userId, String threadId);
  Stream<List<InsightModel>> watchGlobalInsights(String userId);
  Stream<List<InsightModel>> watchThreadInsights(String userId, String threadId);
  Future<void> updateInsight(InsightModel insight);
  Future<void> deleteInsight(String insightId);
}

class InsightRemoteDataSourceImpl implements InsightRemoteDataSource {
  InsightRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('insights');

  @override
  Future<void> saveInsight(InsightModel insight) async {
    await _collection.doc(insight.id).set(insight.toFirestoreMap());
  }

  @override
  Future<InsightModel?> getInsightById(String insightId) async {
    final doc = await _collection.doc(insightId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return InsightModel.fromMap(data);
  }

  @override
  Future<List<InsightModel>> getGlobalInsights(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('threadId', isEqualTo: null)
        .where('isDeleted', isEqualTo: false)
        .orderBy('periodEndMillis', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return InsightModel.fromMap(data);
    }).toList();
  }

  @override
  Future<List<InsightModel>> getThreadInsights(
      String userId, String threadId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('periodEndMillis', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return InsightModel.fromMap(data);
    }).toList();
  }

  @override
  Stream<List<InsightModel>> watchGlobalInsights(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('threadId', isEqualTo: null)
        .where('isDeleted', isEqualTo: false)
        .orderBy('periodEndMillis', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return InsightModel.fromMap(data);
            }).toList());
  }

  @override
  Stream<List<InsightModel>> watchThreadInsights(
      String userId, String threadId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('periodEndMillis', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return InsightModel.fromMap(data);
            }).toList());
  }

  @override
  Future<void> updateInsight(InsightModel insight) async {
    await _collection.doc(insight.id).update(insight.toFirestoreMap());
  }

  @override
  Future<void> deleteInsight(String insightId) async {
    await _collection.doc(insightId).update({'isDeleted': true});
  }
}
```

#### 3. Repository Interface
**File**: `lib/features/insights/domain/repositories/insight_repository.dart`
**Changes**: Create repository interface

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';

abstract class InsightRepository {
  Future<Result<InsightEntity?>> getInsightById(String insightId);
  Future<Result<List<InsightEntity>>> getGlobalInsights(String userId);
  Future<Result<List<InsightEntity>>> getThreadInsights(String threadId);
  Stream<List<InsightEntity>> watchGlobalInsights(String userId);
  Stream<List<InsightEntity>> watchThreadInsights(String threadId);
  Future<Result<void>> syncInsights(String userId);
}
```

#### 4. Repository Implementation
**File**: `lib/features/insights/data/repositories/insight_repository_impl.dart`
**Changes**: Implement repository with offline-first sync

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/insights/data/datasources/insight_local_datasource.dart';
import 'package:kairos/features/insights/data/datasources/insight_remote_datasource.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  final InsightLocalDataSource localDataSource;
  final InsightRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<InsightEntity?>> getInsightById(String insightId) async {
    try {
      final localInsight = await localDataSource.getInsightById(insightId);
      return Success(localInsight?.toEntity());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to retrieve insight: $e'));
    }
  }

  @override
  Future<Result<List<InsightEntity>>> getGlobalInsights(String userId) async {
    try {
      final localInsights = await localDataSource.getGlobalInsights(userId);
      return Success(localInsights.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to retrieve insights: $e'));
    }
  }

  @override
  Future<Result<List<InsightEntity>>> getThreadInsights(String threadId) async {
    try {
      final localInsights = await localDataSource.getThreadInsights(threadId);
      return Success(localInsights.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to retrieve insights: $e'));
    }
  }

  @override
  Stream<List<InsightEntity>> watchGlobalInsights(String userId) async* {
    // Check if online
    final isOnline = await _isOnline;

    if (!isOnline) {
      // Offline: just watch local DB
      yield* localDataSource
          .watchGlobalInsights(userId)
          .map((models) => models.map((m) => m.toEntity()).toList());
      return;
    }

    // Online: Set up bidirectional sync between Firestore and local DB
    StreamSubscription<List<InsightModel>>? remoteSub;

    try {
      // Listen to Firestore and sync to local DB in background
      remoteSub = remoteDataSource.watchGlobalInsights(userId).listen(
        (remoteModels) async {
          // Get current local insights to compare
          final localInsights = await localDataSource.getGlobalInsights(userId);
          final localIds = localInsights.map((m) => m.id).toSet();

          for (final remoteModel in remoteModels) {
            if (!localIds.contains(remoteModel.id)) {
              // New insight from remote
              await localDataSource.saveInsight(remoteModel);
              debugPrint('Synced new global insight: ${remoteModel.id}');
            } else {
              // Check if we need to update
              final localModel =
                  await localDataSource.getInsightById(remoteModel.id);
              if (localModel != null &&
                  localModel.updatedAtMillis < remoteModel.updatedAtMillis) {
                await localDataSource.updateInsight(remoteModel);
                debugPrint('Updated global insight: ${remoteModel.id}');
              }
            }
          }
        },
        onError: (Object error) {
          debugPrint('Remote sync error: $error');
        },
      );

      // Yield the local stream (which gets updated by the remote listener above)
      yield* localDataSource
          .watchGlobalInsights(userId)
          .map((models) => models.map((m) => m.toEntity()).toList());
    } finally {
      // Clean up subscription when stream is cancelled
      await remoteSub?.cancel();
    }
  }

  @override
  Stream<List<InsightEntity>> watchThreadInsights(String threadId) async* {
    // Check if online
    final isOnline = await _isOnline;

    if (!isOnline) {
      // Offline: just watch local DB
      yield* localDataSource
          .watchThreadInsights(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
      return;
    }

    // Get userId from local insights (needed for Firestore query)
    final localInsights = await localDataSource.getThreadInsights(threadId);
    if (localInsights.isEmpty) {
      // No insights yet, just watch local
      yield* localDataSource
          .watchThreadInsights(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
      return;
    }
    final userId = localInsights.first.userId;

    // Online: Set up bidirectional sync
    StreamSubscription<List<InsightModel>>? remoteSub;

    try {
      remoteSub =
          remoteDataSource.watchThreadInsights(userId, threadId).listen(
        (remoteModels) async {
          final localInsights =
              await localDataSource.getThreadInsights(threadId);
          final localIds = localInsights.map((m) => m.id).toSet();

          for (final remoteModel in remoteModels) {
            if (!localIds.contains(remoteModel.id)) {
              await localDataSource.saveInsight(remoteModel);
              debugPrint('Synced new thread insight: ${remoteModel.id}');
            } else {
              final localModel =
                  await localDataSource.getInsightById(remoteModel.id);
              if (localModel != null &&
                  localModel.updatedAtMillis < remoteModel.updatedAtMillis) {
                await localDataSource.updateInsight(remoteModel);
                debugPrint('Updated thread insight: ${remoteModel.id}');
              }
            }
          }
        },
        onError: (Object error) {
          debugPrint('Remote sync error: $error');
        },
      );

      yield* localDataSource
          .watchThreadInsights(threadId)
          .map((models) => models.map((m) => m.toEntity()).toList());
    } finally {
      await remoteSub?.cancel();
    }
  }

  @override
  Future<Result<void>> syncInsights(String userId) async {
    try {
      if (!await _isOnline) {
        return const Error(NetworkFailure(message: 'Device is offline'));
      }

      // Sync global insights
      final remoteGlobalInsights =
          await remoteDataSource.getGlobalInsights(userId);
      for (final insight in remoteGlobalInsights) {
        await localDataSource.saveInsight(insight);
      }

      // Note: Thread insights will sync when their specific streams are watched
      // This is an optimization to avoid loading all thread insights at once

      return const Success(null);
    } catch (e) {
      if (e.toString().contains('network')) {
        return Error(
          NetworkFailure(message: 'Network error syncing insights: $e'),
        );
      }
      return Error(ServerFailure(message: 'Failed to sync insights: $e'));
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] All repository files pass type checking: `~/flutter/bin/flutter analyze`
- [ ] No import errors in the codebase
- [ ] Build succeeds: `~/flutter/bin/flutter build apk --debug`

#### Manual Verification:
- [ ] Repository can fetch insights from local database
- [ ] Stream providers emit updates when data changes
- [ ] Offline mode works (displays cached insights)
- [ ] Online mode syncs new insights from Firestore
- [ ] Bidirectional sync updates local DB when Firestore changes

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 4.

---

## Phase 4: Riverpod Providers and State Management

### Overview
Wire up Riverpod providers for dependency injection and expose insight streams to the presentation layer.

### Changes Required

#### 1. Insight Providers
**File**: `lib/features/insights/presentation/providers/insight_providers.dart`
**Changes**: Create provider hierarchy

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';
import 'package:kairos/features/insights/data/datasources/insight_local_datasource.dart';
import 'package:kairos/features/insights/data/datasources/insight_remote_datasource.dart';
import 'package:kairos/features/insights/data/repositories/insight_repository_impl.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';

// Data source providers
final insightLocalDataSourceProvider =
    Provider<InsightLocalDataSource>((ref) {
  final isar = ref.watch(isarProvider);
  return InsightLocalDataSourceImpl(isar);
});

final insightRemoteDataSourceProvider =
    Provider<InsightRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return InsightRemoteDataSourceImpl(firestore);
});

// Repository provider
final insightRepositoryProvider = Provider<InsightRepository>((ref) {
  final localDataSource = ref.watch(insightLocalDataSourceProvider);
  final remoteDataSource = ref.watch(insightRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityProvider);

  return InsightRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    connectivity: connectivity,
  );
});

// Stream providers
final globalInsightsStreamProvider =
    StreamProvider.family<List<InsightEntity>, String>((ref, userId) {
  final repository = ref.watch(insightRepositoryProvider);
  return repository.watchGlobalInsights(userId);
});

final threadInsightsStreamProvider =
    StreamProvider.family<List<InsightEntity>, String>((ref, threadId) {
  final repository = ref.watch(insightRepositoryProvider);
  return repository.watchThreadInsights(threadId);
});

// Current user's global insights (convenience provider)
final currentUserGlobalInsightsProvider =
    StreamProvider<List<InsightEntity>>((ref) {
  final userId = ref.watch(currentUserProvider).value?.uid;
  if (userId == null) {
    return Stream.value([]);
  }
  return ref.watch(globalInsightsStreamProvider(userId).stream);
});
```

### Success Criteria

#### Automated Verification:
- [ ] Dart analyzer passes: `~/flutter/bin/flutter analyze`
- [ ] No circular dependency errors
- [ ] All providers resolve correctly

#### Manual Verification:
- [ ] Providers can be watched in widgets
- [ ] AsyncValue states transition correctly (loading → data)
- [ ] Stream emits updates when insights change
- [ ] Provider invalidation works when user logs out

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 5.

---

## Phase 5: Mock Data Seeding Script

### Overview
Create a Dart script to generate realistic mock insights for UI testing and development.

### Changes Required

#### 1. Mock Data Generator Script
**File**: `lib/features/insights/data/mock/generate_mock_insights.dart`
**Changes**: Create standalone script

```dart
import 'dart:math';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';

/// Run this script to populate mock insights for testing
/// Execute from terminal: flutter run lib/features/insights/data/mock/generate_mock_insights.dart
Future<void> main() async {
  print('🌱 Generating mock insights...');

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

  print('📝 Creating per-thread insights...');

  // Generate 5-7 insights per thread over the last 14 days
  for (final threadId in threadIds) {
    final insightCount = 5 + random.nextInt(3); // 5-7 insights

    for (int i = 0; i < insightCount; i++) {
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

      print('  ✓ Created insight for $threadId (${_formatDate(periodEnd)})');
    }
  }

  print('🌍 Creating global insights...');

  // Generate 10 global insights
  for (int i = 0; i < 10; i++) {
    final daysAgo = i * 1; // Daily
    final periodEnd = now.subtract(Duration(days: daysAgo));
    final periodStart = periodEnd.subtract(const Duration(days: 3));

    final insight = _generateMockInsight(
      userId: userId,
      threadId: null, // Global insight
      periodStart: periodStart,
      periodEnd: periodEnd,
      random: random,
    );

    await isar.writeTxn(() async {
      await isar.insightModels.put(insight);
    });

    print('  ✓ Created global insight (${_formatDate(periodEnd)})');
  }

  print('✅ Mock data generation complete!');
  print('   Total insights created: ${threadIds.length * 6 + 10}');

  await isar.close();
}

InsightModel _generateMockInsight({
  required String userId,
  String? threadId,
  required DateTime periodStart,
  required DateTime periodEnd,
  required Random random,
}) {
  // Randomly generate mood and emotion
  final moodScore = 0.2 + random.nextDouble() * 0.7; // 0.2 to 0.9
  final emotions = EmotionType.values;
  final dominantEmotion = emotions[random.nextInt(emotions.length)];

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
    dominantEmotion: dominantEmotion.index,
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
      'success'
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
      'progress'
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
      'boundaries'
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
    'improvement'
  ];

  final pool = threadId != null
      ? (keywordSets[threadId] ?? globalKeywords)
      : globalKeywords;

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
      'Sense of accomplishment'
    ],
    EmotionType.calm: [
      'Inner peace and balance',
      'Mindfulness practice',
      'Healthy boundaries',
      'Self-care routines',
      'Stress management'
    ],
    EmotionType.neutral: [
      'Steady emotional state',
      'Routine maintenance',
      'Balanced perspective',
      'Processing experiences',
      'Gradual progress'
    ],
    EmotionType.sadness: [
      'Processing difficult emotions',
      'Seeking support',
      'Self-compassion',
      'Acknowledging feelings',
      'Gentle self-reflection'
    ],
    EmotionType.stress: [
      'Managing overwhelm',
      'Time pressure concerns',
      'Seeking coping strategies',
      'Workload balance',
      'Need for rest'
    ],
    EmotionType.anger: [
      'Expressing frustration',
      'Setting boundaries',
      'Processing conflict',
      'Seeking resolution',
      'Emotional release'
    ],
    EmotionType.fear: [
      'Facing uncertainties',
      'Building courage',
      'Addressing anxieties',
      'Seeking reassurance',
      'Gradual exposure'
    ],
    EmotionType.excitement: [
      'Anticipating positive changes',
      'New opportunities',
      'Creative energy',
      'Motivated action',
      'Future planning'
    ],
  };

  final pool = themeSets[emotion] ?? themeSets[EmotionType.neutral]!;
  final shuffled = List<String>.from(pool)..shuffle(random);
  return shuffled.take(5).toList();
}

String _generateSummary(
    EmotionType emotion, double moodScore, String? threadId) {
  final moodDescriptors = {
    'high': ['positive', 'optimistic', 'energized', 'motivated'],
    'medium': ['balanced', 'steady', 'reflective', 'thoughtful'],
    'low': ['challenging', 'difficult', 'contemplative', 'processing'],
  };

  final moodCategory =
      moodScore > 0.6 ? 'high' : moodScore < 0.4 ? 'low' : 'medium';
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

  return 'You\'ve been $descriptor $context, ${emotionDescriptors[emotion]}. '
      'Your reflections show genuine engagement with your emotional journey.';
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
```

#### 2. Add Script Entry Point
**File**: `scripts/seed_mock_insights.sh` (new file)
**Changes**: Create bash script for easy execution

```bash
#!/bin/bash

echo "🌱 Seeding mock insights to local Isar database..."

# Run the Dart script
~/flutter/bin/flutter run lib/features/insights/data/mock/generate_mock_insights.dart

echo "✅ Mock data seeding complete!"
```

Make executable:
```bash
chmod +x scripts/seed_mock_insights.sh
```

### Success Criteria

#### Automated Verification:
- [ ] Script runs without errors: `./scripts/seed_mock_insights.sh`
- [ ] No Isar write transaction failures

#### Manual Verification:
- [ ] Script creates 20+ mock insights in local database
- [ ] Insights have realistic mood scores (0.2-0.9 range)
- [ ] Keywords and themes are contextual to thread types
- [ ] Global insights aggregate correctly
- [ ] Can view insights in Flutter app after seeding

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 6.

---

## Phase 6: Dashboard UI and Chart Widgets

### Overview
Implement visual dashboard with mood chart (bar graph) and emotion distribution chart (pie chart) on the home screen.

### Changes Required

#### 1. Add Chart Package
**File**: `pubspec.yaml`
**Changes**: Add fl_chart dependency

```yaml
dependencies:
  # ... existing dependencies
  fl_chart: ^0.69.0
```

Run:
```bash
~/flutter/bin/flutter pub get
```

#### 2. Mood Chart Widget
**File**: `lib/features/insights/presentation/widgets/mood_chart_widget.dart`
**Changes**: Create bar chart for mood over time

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:intl/intl.dart';

class MoodChartWidget extends StatelessWidget {
  const MoodChartWidget({
    super.key,
    required this.insights,
  });

  final List<InsightEntity> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No mood data available yet'),
        ),
      );
    }

    // Sort by date (oldest first for chronological display)
    final sortedInsights = List<InsightEntity>.from(insights)
      ..sort((a, b) => a.periodEnd.compareTo(b.periodEnd));

    // Take last 14 insights (2 weeks)
    final displayInsights = sortedInsights.length > 14
        ? sortedInsights.sublist(sortedInsights.length - 14)
        : sortedInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Mood Over Time',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                minY: 0.0,
                barGroups: displayInsights.asMap().entries.map((entry) {
                  final index = entry.key;
                  final insight = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: insight.moodScore,
                        color: _getEmotionColor(insight.dominantEmotion),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= displayInsights.length) {
                          return const SizedBox();
                        }
                        final insight = displayInsights[value.toInt()];
                        final date = DateFormat('M/d').format(insight.periodEnd);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            date,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    left: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: EmotionType.values.map((emotion) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getEmotionColor(emotion),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _getEmotionLabel(emotion),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getEmotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.joy:
        return Colors.amber;
      case EmotionType.calm:
        return Colors.blue.shade300;
      case EmotionType.neutral:
        return Colors.grey;
      case EmotionType.sadness:
        return Colors.grey.shade600;
      case EmotionType.stress:
        return Colors.orange;
      case EmotionType.anger:
        return Colors.red;
      case EmotionType.fear:
        return Colors.purple;
      case EmotionType.excitement:
        return Colors.pink;
    }
  }

  String _getEmotionLabel(EmotionType emotion) {
    return emotion.toString().split('.').last;
  }
}
```

#### 3. Emotion Distribution Widget
**File**: `lib/features/insights/presentation/widgets/emotion_distribution_widget.dart`
**Changes**: Create pie chart for emotion breakdown

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';

class EmotionDistributionWidget extends StatelessWidget {
  const EmotionDistributionWidget({
    super.key,
    required this.insights,
  });

  final List<InsightEntity> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No emotion data available yet'),
        ),
      );
    }

    // Count emotions
    final emotionCounts = <EmotionType, int>{};
    for (final insight in insights) {
      emotionCounts[insight.dominantEmotion] =
          (emotionCounts[insight.dominantEmotion] ?? 0) + 1;
    }

    final total = insights.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Emotion Distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sections: emotionCounts.entries.map((entry) {
                      final percentage = (entry.value / total * 100);
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        title: '${percentage.toStringAsFixed(0)}%',
                        color: _getEmotionColor(entry.key),
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: emotionCounts.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getEmotionColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _getEmotionLabel(entry.key),
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getEmotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.joy:
        return Colors.amber;
      case EmotionType.calm:
        return Colors.blue.shade300;
      case EmotionType.neutral:
        return Colors.grey;
      case EmotionType.sadness:
        return Colors.grey.shade600;
      case EmotionType.stress:
        return Colors.orange;
      case EmotionType.anger:
        return Colors.red;
      case EmotionType.fear:
        return Colors.purple;
      case EmotionType.excitement:
        return Colors.pink;
    }
  }

  String _getEmotionLabel(EmotionType emotion) {
    return emotion.toString().split('.').last;
  }
}
```

#### 4. Update Home Screen
**File**: `lib/features/home/presentation/screens/home_screen.dart`
**Changes**: Add insights dashboard widgets

```dart
// Add imports at top
import 'package:kairos/features/insights/presentation/providers/insight_providers.dart';
import 'package:kairos/features/insights/presentation/widgets/mood_chart_widget.dart';
import 'package:kairos/features/insights/presentation/widgets/emotion_distribution_widget.dart';

// Update build method to include charts
@override
Widget build(BuildContext context, WidgetRef ref) {
  final userAsyncValue = ref.watch(currentUserProvider);
  final profileAsyncValue = ref.watch(currentUserProfileProvider);
  final insightsAsyncValue = ref.watch(currentUserGlobalInsightsProvider);

  return userAsyncValue.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(child: Text('Error: $error')),
    data: (user) {
      if (user == null) {
        return const Center(child: Text('Not logged in'));
      }

      return profileAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (profile) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Existing welcome section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile?.avatarUrl != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(profile!.avatarUrl!),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome back, ${profile?.name ?? user.displayName ?? 'User'}!',
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
                const Divider(),
                // Insights dashboard
                insightsAsyncValue.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Failed to load insights: $error'),
                    ),
                  ),
                  data: (insights) {
                    if (insights.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.insights_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No insights yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start journaling to see your mood patterns',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        MoodChartWidget(insights: insights),
                        const Divider(),
                        EmotionDistributionWidget(insights: insights),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
```

### Success Criteria

#### Automated Verification:
- [ ] Charts render without errors: `~/flutter/bin/flutter build apk --debug`
- [ ] No UI overflow errors
- [ ] Dart analyzer passes: `~/flutter/bin/flutter analyze`

#### Manual Verification:
- [ ] Bar chart displays mood scores over time
- [ ] Bar colors match emotion types (joy=yellow, calm=blue, etc.)
- [ ] X-axis shows dates in chronological order
- [ ] Pie chart shows emotion distribution percentages
- [ ] Legend displays all emotion types with correct colors
- [ ] Empty state shows when no insights available
- [ ] Charts update in real-time when new insights arrive
- [ ] Scrolling works smoothly on small screens

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 7.

---

## Phase 7: Integration Testing and Refinement

### Overview
End-to-end testing of the complete Insights flow, from Cloud Function trigger to UI display.

### Changes Required

#### 1. Integration Test
**File**: `test/features/insights/integration/insights_flow_test.dart`
**Changes**: Create integration test

```dart
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
        threadId: 'thread_456',
        periodStart: now.subtract(const Duration(days: 3)),
        periodEnd: now,
        moodScore: 0.75,
        dominantEmotion: EmotionType.joy,
        keywords: ['happy', 'productive', 'grateful'],
        aiThemes: ['Positive outlook', 'Growth mindset'],
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
        keywords: ['peaceful', 'centered'],
        aiThemes: ['Mindfulness'],
        summary: 'You maintained calm.',
        messageCount: 8,
      );

      final map = model.toFirestoreMap();
      final deserialized = InsightModel.fromMap(map);

      expect(deserialized.moodScore, model.moodScore);
      expect(deserialized.dominantEmotion, model.dominantEmotion);
      expect(deserialized.keywords, model.keywords);
    });
  });
}
```

#### 2. Manual Testing Checklist
Create a testing document:

**File**: `thoughts/shared/plans/insights-testing-checklist.md`

```markdown
# Insights Feature Testing Checklist

## Cloud Function Testing
- [ ] Deploy generateInsight function successfully
- [ ] Create test journal message with AI response
- [ ] Verify insight document created in Firestore
- [ ] Check insight fields are populated correctly
- [ ] Test update logic (add message within 24 hours)
- [ ] Verify global insight aggregation
- [ ] Check Cloud Function logs for errors

## Repository Testing
- [ ] Sync insights from Firestore to local Isar
- [ ] Watch global insights stream (test real-time updates)
- [ ] Watch thread insights stream
- [ ] Test offline mode (disconnect network, verify cached data)
- [ ] Test online mode (reconnect, verify sync)
- [ ] Verify bidirectional sync updates local DB

## UI Testing
- [ ] Mock data displays correctly in charts
- [ ] Bar chart shows mood trends
- [ ] Bar colors match emotions
- [ ] Pie chart percentages add up to 100%
- [ ] Empty state displays when no insights
- [ ] Charts update when new insight arrives
- [ ] Scrolling works on small screens
- [ ] Dark mode compatibility
- [ ] Legend displays all emotions

## Performance Testing
- [ ] Charts render in < 500ms with 20 insights
- [ ] No frame drops during chart animations
- [ ] Memory usage stable during scrolling
- [ ] Cloud Function completes in < 5 seconds

## Edge Cases
- [ ] Single insight displays correctly
- [ ] Very high mood score (0.95+) renders properly
- [ ] Very low mood score (0.1-) renders properly
- [ ] Long keyword lists don't overflow
- [ ] Long summaries wrap correctly
- [ ] Multiple threads with same timestamp
```

### Success Criteria

#### Automated Verification:
- [ ] All unit tests pass: `~/flutter/bin/flutter test`
- [ ] Integration tests pass
- [ ] No memory leaks detected
- [ ] Build succeeds: `~/flutter/bin/flutter build apk --release`

#### Manual Verification:
- [ ] Complete manual testing checklist
- [ ] All edge cases handled gracefully
- [ ] Performance meets targets (< 5s function, < 500ms charts)
- [ ] No console errors during typical usage
- [ ] Feature works end-to-end from journal message to dashboard

**Implementation Note**: After completing this phase and all automated verification passes, the Insights feature is complete and ready for user testing.

---

## Testing Strategy

### Unit Tests
**Coverage Goals**: 80%+ for business logic

**Test Files to Create**:
- `test/features/insights/domain/entities/insight_entity_test.dart` - Entity equality and copyWith
- `test/features/insights/data/models/insight_model_test.dart` - Serialization/deserialization
- `test/features/insights/data/repositories/insight_repository_impl_test.dart` - Repository operations
- `functions/src/test/insights-helper.test.ts` - Keyword extraction, AI analysis, aggregation

**Key Test Cases**:
- Mood score clamping (0.0 to 1.0)
- Emotion enum mapping
- Keyword deduplication
- Theme extraction
- Global insight aggregation accuracy
- Date range calculations

### Integration Tests
**Test Files**:
- `integration_test/insights_flow_test.dart` - End-to-end flow

**Test Scenarios**:
1. Create journal message → AI responds → Insight generated → UI updates
2. Add message to existing thread → Insight updates
3. Create message in new thread → New insight created
4. Check global insight after multiple threads
5. Offline → create message → go online → verify sync

### Manual Testing
**Test on Devices**:
- iOS simulator (latest)
- Android emulator (API 30+)
- Physical device (at least one)

**Test Scenarios**:
- Seed mock data → verify charts render
- Create real journal messages → verify insights generate
- Toggle airplane mode → verify offline functionality
- Force-quit app → reopen → verify data persists
- Test with 0 insights, 1 insight, 20+ insights

## Performance Considerations

### Cloud Function Optimization
- **Limit conversation history**: Query only last 3 days (reduces Firestore reads)
- **Batch writes**: Use batch operations when creating insights
- **Cache AI responses**: Consider caching keyword extraction results
- **Timeout handling**: Set 60s timeout with graceful degradation

### Mobile App Optimization
- **Pagination**: Load insights incrementally (not all at once)
- **Chart debouncing**: Throttle chart redraws during rapid updates
- **Image caching**: Cache emotion color mappings
- **Lazy loading**: Don't render charts until scrolled into view

### Database Optimization
- **Firestore indexes**: Create composite index for (userId, threadId, periodEndMillis)
- **Isar indexes**: Already indexed on userId and threadId
- **Query limits**: Limit chart display to last 14 insights (2 weeks)

## Migration Notes

### No Data Migration Needed
- This is a new feature, no existing data to migrate
- Insights will be generated going forward as users journal
- Mock data script available for testing

### Future Schema Evolution
If we need to add fields later:
1. Update InsightEntity with new optional fields
2. Update InsightModel with defaults for new fields
3. Update toFirestoreMap() and fromMap()
4. Deploy Cloud Function changes
5. Update UI as needed

## References

- Original requirements: User's prompt above
- Journal repository pattern: [journal_message_repository_impl.dart:96-181](lib/features/journal/data/repositories/journal_message_repository_impl.dart#L96-L181)
- Cloud Functions: [index.ts:18-713](functions/src/index.ts#L18-L713)
- Riverpod providers: [journal_providers.dart:21-124](lib/features/journal/presentation/providers/journal_providers.dart#L21-L124)
- fl_chart documentation: https://pub.dev/packages/fl_chart
