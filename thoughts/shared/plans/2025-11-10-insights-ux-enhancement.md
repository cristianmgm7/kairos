# Insights UX Enhancement Implementation Plan

## Overview

Transform the Insights feature from a passive dashboard display into a dynamic, integrated experience with:
1. **Thread Insights as Visual Covers** - Each thread card displays an AI-generated visual cover (mood-gradient) and summary that updates in real-time
2. **Enhanced Global Insights Dashboard** - New dedicated Insights tab with time period selection (1 day, 3 days, 1 week, 1 month) showing summaries and emotion bars
3. **Daily Insight Generation** - Backend generates daily global insights automatically, aggregated client-side based on user's time period selection
4. **Reactive Sync Architecture** - Mirror the journal message pipeline pattern with use cases, controllers, and watch streams

## Current State Analysis

### What Exists:
- **Domain Layer**: `InsightEntity` with `InsightType.thread` and `InsightType.global`
- **Data Layer**: Local (Isar) and Remote (Firestore) data sources with watch streams
- **Repository**: `InsightRepositoryImpl` follows message pattern (local-first, dual-stream sync)
- **Backend**: `generateInsight` Cloud Function triggers on AI message creation
  - Generates thread insights (last 3 days of messages)
  - Aggregates thread insights into global insights
  - 1-hour debounce to prevent excessive generation
- **UI**: Global insights displayed on Home screen with `MoodChartWidget` and `EmotionDistributionWidget`
- **Thread Cards**: Basic `ThreadListTile` with icon, title, message count, timestamp

### What's Missing:
- ✗ Thread entity does not store insight reference or cover data
- ✗ No visual cover generation for thread cards
- ✗ No time period enum or filtering logic
- ✗ No dedicated Insights tab in bottom navigation
- ✗ No daily insight generation (currently generates on message creation only)
- ✗ No use cases for triggering insight generation
- ✗ No controller for orchestrating insight operations
- ✗ No UI for time period selection
- ✗ No emotion bars per day visualization
- ✗ Backend doesn't support custom time period analysis

## Desired End State

### User Experience:
1. **Thread List**: Each thread card shows a gradient cover (colored by mood) with insight summary overlay
2. **Insights Tab**: Dedicated bottom nav tab with:
   - Time period dropdown (1 day, 3 days, 1 week, 1 month)
   - Global summary card
   - Emotion bars chart (one bar per day in selected period)
   - Optional: "Refresh" button to trigger on-demand re-analysis
3. **Real-time Updates**: Insights update automatically when new messages arrive (when online)
4. **Offline Support**: Display last cached insights when offline

### Technical Verification:
- Thread cards display gradient covers based on `dominantEmotion` from latest thread insight
- Insights tab switches between time periods without flickering
- Backend generates daily global insights automatically (via scheduled Cloud Function)
- Client-side aggregates daily insights based on user's selected time period
- Insights sync pattern mirrors journal messages (watch streams, local-first)

## What We're NOT Doing

- Creating custom AI-generated cover images (using color gradients only)
- Showing insights on thread detail screen (only on thread cards for now)
- Supporting custom date range selection (only predefined periods)
- Migrating existing insights (will regenerate fresh from messages)
- Adding push notifications for new insights
- Building a "trends over time" historical analysis view

---

## Phase 1: Extend Domain Models and Enums

### Overview
Add time period support, daily insights type, and extend thread entity to reference insights.

### Changes Required:

#### 1. Domain Entities - Add Time Period Enum

**File**: `lib/features/insights/domain/entities/insight_entity.dart`

**Changes**: Add `InsightPeriod` enum and extend `InsightType`

```dart
// Add after EmotionType enum (line 12)
enum InsightPeriod {
  oneDay,    // Last 24 hours
  threeDays, // Last 3 days
  oneWeek,   // Last 7 days
  oneMonth,  // Last 30 days
  daily,     // Single day snapshot (for aggregation)
}

// Extend InsightType enum (line 14-17)
enum InsightType {
  thread,       // Per-thread insight
  global,       // Global aggregated insight
  dailyGlobal,  // NEW: Single day global snapshot
}

// Add to InsightEntity class (after line 43)
final InsightPeriod? period; // null for thread insights, set for global insights

// Update constructor (line 19-38)
const InsightEntity({
  required this.id,
  required this.userId,
  required this.type,
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
  this.threadId,
  this.period, // NEW
  this.guidanceSuggestion,
  this.actionPrompt,
  this.metadata,
});

// Update props getter (line 60-79) to include period
// Update copyWith (line 81-119) to include period parameter
```

#### 2. Thread Entity - Add Insight Reference

**File**: `lib/features/journal/domain/entities/journal_thread_entity.dart`

**Changes**: Add optional insight reference for cover data

```dart
// Add after line 11 (after updatedAt)
this.latestInsightId,        // Reference to latest thread insight
this.latestInsightSummary,   // Cached summary for quick display
this.latestInsightMood,      // Cached dominant emotion for gradient

// Add field declarations (after line 23)
final String? latestInsightId;
final String? latestInsightSummary;
final EmotionType? latestInsightMood; // Import from insight_entity.dart

// Update props getter (line 26-37) to include new fields
// Update copyWith (line 39-61) to include new fields
```

### Success Criteria:

#### Automated Verification:
- [x] Code compiles: `~/flutter/bin/flutter analyze`
- [x] Type checking passes with no errors
- [x] Existing tests still pass: `~/flutter/bin/flutter test`

#### Manual Verification:
- [x] Enums are properly defined with correct values
- [x] Thread entity properly imports EmotionType
- [x] No breaking changes to existing insight consumers

---

## Phase 2: Update Data Models and Database Schema

### Overview
Update data models to match domain changes, regenerate Isar schema, and update Firestore mappers.

### Changes Required:

#### 1. Insight Model - Add New Fields

**File**: `lib/features/insights/data/models/insight_model.dart`

**Changes**: Add period field, update from/to mappers

```dart
// Add to InsightModel class
final String? period; // Stored as string for Firestore/Isar compatibility

// Update fromEntity factory
static InsightModel fromEntity(InsightEntity entity) {
  return InsightModel(
    // ... existing fields ...
    period: entity.period?.name, // Convert enum to string
  );
}

// Update toEntity method
InsightEntity toEntity() {
  return InsightEntity(
    // ... existing fields ...
    period: period != null
      ? InsightPeriod.values.firstWhere((e) => e.name == period)
      : null,
  );
}

// Update fromMap (Firestore deserializer)
factory InsightModel.fromMap(Map<String, dynamic> map) {
  // ... existing fields ...
  period: map['period'] as String?,
}

// Update toFirestoreMap
Map<String, dynamic> toFirestoreMap() {
  return {
    // ... existing fields ...
    'period': period,
  };
}
```

#### 2. Thread Model - Add Insight Fields

**File**: `lib/features/journal/data/models/journal_thread_model.dart`

**Changes**: Add insight cache fields

```dart
// Add to model class
final String? latestInsightId;
final String? latestInsightSummary;
final String? latestInsightMood; // Store as string (emotion enum name)

// Update all mappers (fromEntity, toEntity, fromMap, toFirestoreMap)
// following the same pattern as InsightModel above
```

#### 3. Regenerate Isar Schema

**File**: Run code generation after updating models

**Command**:
```bash
~/flutter/bin/flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Expected Output**: New `*.g.dart` files generated with updated schema

#### 4. Update Firestore Indexes (if needed)

**File**: `firestore.indexes.json`

**Changes**: Add index for daily global insights if needed

```json
{
  "indexes": [
    {
      "collectionGroup": "insights",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "type", "order": "ASCENDING"},
        {"fieldPath": "period", "order": "ASCENDING"},
        {"fieldPath": "periodEndMillis", "order": "DESCENDING"}
      ]
    }
  ]
}
```

### Success Criteria:

#### Automated Verification:
- [x] Build runner completes: `~/flutter/bin/flutter packages pub run build_runner build --delete-conflicting-outputs`
- [x] No analyzer errors: `~/flutter/bin/flutter analyze`
- [x] App builds successfully: `~/flutter/bin/flutter build apk --debug` (or equivalent for your platform)

#### Manual Verification:
- [ ] Isar Inspector shows updated schema with new fields
- [ ] Firestore console shows documents with new fields after first write
- [ ] Existing insights data is not corrupted (graceful handling of missing fields)

**Implementation Note**: After completing this phase and automated verification passes, test manually that existing data loads correctly before proceeding.

---

## Phase 3: Backend - Daily Insight Generation

### Overview
Add scheduled Cloud Function to generate daily global insights, and add callable function for on-demand time period analysis.

### Changes Required:

#### 1. Add Scheduled Function for Daily Insights

**File**: `functions/src/functions/scheduled-insights.ts` (NEW FILE)

**Changes**: Create new scheduled function

```typescript
import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { geminiApiKey } from '../config/genkit';
import { getAI } from '../config/genkit';
import { createInsightGenerator } from '../domain/insights/insight-generator';

const db = admin.firestore();

/**
 * Scheduled function: Generate daily global insights for all active users
 * Runs daily at 2:00 AM UTC
 */
export const generateDailyInsights = onSchedule(
  {
    schedule: '0 2 * * *', // Every day at 2:00 AM UTC
    timeZone: 'UTC',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 540, // 9 minutes (max for scheduled functions)
  },
  async (event) => {
    console.log('Starting daily insight generation job');

    const now = Date.now();
    const oneDayAgo = now - (24 * 60 * 60 * 1000);

    try {
      // Get all users who have journaled in the last 24 hours
      const recentMessagesSnapshot = await db.collection('journalMessages')
        .where('createdAtMillis', '>=', oneDayAgo)
        .select('userId') // Only fetch userId field for efficiency
        .get();

      // Get unique user IDs
      const userIds = new Set<string>();
      recentMessagesSnapshot.docs.forEach(doc => {
        const userId = doc.data().userId as string;
        if (userId) userIds.add(userId);
      });

      console.log(`Found ${userIds.size} active users in last 24 hours`);

      const ai = getAI(geminiApiKey.value());
      const insightGenerator = createInsightGenerator(db);

      // Generate daily insights for each user
      let successCount = 0;
      let errorCount = 0;

      for (const userId of userIds) {
        try {
          await insightGenerator.generateDailyGlobalInsight(userId, now);
          successCount++;
        } catch (error) {
          console.error(`Failed to generate daily insight for user ${userId}:`, error);
          errorCount++;
        }
      }

      console.log(`Daily insight generation complete: ${successCount} succeeded, ${errorCount} failed`);
    } catch (error) {
      console.error('Error in daily insight generation job:', error);
      throw error; // Re-throw to mark Cloud Function execution as failed
    }
  }
);
```

#### 2. Add Daily Insight Generator Method

**File**: `functions/src/domain/insights/insight-generator.ts`

**Changes**: Add `generateDailyGlobalInsight` method (after line 165)

```typescript
/**
 * Generate daily global insight snapshot
 * Analyzes all messages from the last 24 hours
 */
async generateDailyGlobalInsight(userId: string, now: number): Promise<void> {
  const oneDayAgo = now - INSIGHTS_CONFIG.oneDayMs;
  const periodStart = this.getStartOfDay(now); // Midnight of current day

  // Check if daily insight already exists for today
  const todayInsightId = `${userId}_daily_${periodStart}`;
  const existingInsight = await this.insightRepo.getById(todayInsightId);

  if (existingInsight) {
    console.log(`Daily insight already exists for ${userId} on ${new Date(periodStart).toISOString()}`);
    return;
  }

  // Get all thread insights from last 24 hours
  const threadInsights = await this.insightRepo.getThreadInsights(userId, oneDayAgo);

  if (threadInsights.length === 0) {
    console.log(`No thread insights found for user ${userId} in last 24 hours`);
    return;
  }

  // Aggregate thread insights into daily snapshot
  const aggregated = aggregateInsights(threadInsights);
  if (!aggregated) return;

  // Create daily global insight
  await this.insightRepo.create({
    id: todayInsightId,
    userId,
    type: InsightType.DAILY_GLOBAL,
    threadId: null,
    periodStartMillis: periodStart,
    periodEndMillis: now,
    period: 'daily',
    moodScore: aggregated.moodScore,
    dominantEmotion: aggregated.dominantEmotion,
    keywords: aggregated.keywords,
    aiThemes: aggregated.aiThemes,
    summary: aggregated.summary,
    messageCount: aggregated.messageCount,
  });

  console.log(`Created daily global insight ${todayInsightId}`);
}

/**
 * Helper: Get start of day timestamp (midnight UTC)
 */
private getStartOfDay(timestamp: number): number {
  const date = new Date(timestamp);
  date.setUTCHours(0, 0, 0, 0);
  return date.getTime();
}
```

#### 3. Add Callable Function for Custom Period Analysis

**File**: `functions/src/functions/insights-callable.ts` (NEW FILE)

**Changes**: Create callable function for on-demand analysis

```typescript
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { getAI } from '../config/genkit';
import { createInsightGenerator } from '../domain/insights/insight-generator';
import { InsightType } from '../config/constants';

const db = admin.firestore();

/**
 * Callable function: Generate insight for custom time period
 * Called from client when user selects different time period
 */
export const generatePeriodInsight = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;
    const { period } = request.data;

    // Validate period
    const validPeriods = ['oneDay', 'threeDays', 'oneWeek', 'oneMonth'];
    if (!validPeriods.includes(period)) {
      throw new HttpsError('invalid-argument', `Invalid period: ${period}`);
    }

    console.log(`Generating ${period} insight for user ${userId}`);

    const now = Date.now();
    const insightGenerator = createInsightGenerator(db);

    try {
      // Calculate period boundaries
      const daysMap = {
        oneDay: 1,
        threeDays: 3,
        oneWeek: 7,
        oneMonth: 30,
      };
      const days = daysMap[period as keyof typeof daysMap];
      const periodStart = now - (days * 24 * 60 * 60 * 1000);

      // Get all daily insights in this period
      const dailyInsights = await insightGenerator.insightRepo.getDailyInsightsInRange(
        userId,
        periodStart,
        now
      );

      // If no daily insights exist, fall back to generating from messages directly
      if (dailyInsights.length === 0) {
        console.log('No daily insights found, generating from messages');
        // This will aggregate thread insights (existing logic)
        await insightGenerator.generateGlobalInsight(userId, now);
        return { success: true, message: 'Generated from messages' };
      }

      // Aggregate daily insights into period insight
      const aggregated = aggregateInsights(dailyInsights);
      if (!aggregated) {
        throw new HttpsError('internal', 'Failed to aggregate insights');
      }

      // Create or update period insight
      const insightId = `${userId}_${period}_${periodStart}`;
      await insightGenerator.insightRepo.create({
        id: insightId,
        userId,
        type: InsightType.GLOBAL,
        threadId: null,
        periodStartMillis: periodStart,
        periodEndMillis: now,
        period,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
      });

      console.log(`Created period insight ${insightId}`);
      return { success: true, insightId };
    } catch (error) {
      console.error('Error generating period insight:', error);
      throw new HttpsError('internal', 'Failed to generate insight');
    }
  }
);
```

#### 4. Update Repository to Support Daily Insights

**File**: `functions/src/data/repositories/insight-repository.ts`

**Changes**: Add methods for querying daily insights

```typescript
// Add after existing methods

/**
 * Get all daily global insights in a time range
 */
async getDailyInsightsInRange(
  userId: string,
  startMillis: number,
  endMillis: number
): Promise<Insight[]> {
  const snapshot = await this.collection
    .where('userId', '==', userId)
    .where('type', '==', InsightType.DAILY_GLOBAL)
    .where('periodStartMillis', '>=', startMillis)
    .where('periodStartMillis', '<=', endMillis)
    .orderBy('periodStartMillis', 'asc')
    .get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
  } as Insight));
}
```

#### 5. Update Constants

**File**: `functions/src/config/constants.ts`

**Changes**: Add DAILY_GLOBAL to InsightType enum

```typescript
export enum InsightType {
  THREAD = 'thread',
  GLOBAL = 'global',
  DAILY_GLOBAL = 'dailyGlobal', // NEW
}
```

#### 6. Export New Functions

**File**: `functions/src/index.ts`

**Changes**: Export new functions (add after line 25)

```typescript
export { generateDailyInsights } from './functions/scheduled-insights';
export { generatePeriodInsight } from './functions/insights-callable';
```

### Success Criteria:

#### Automated Verification:
- [ ] TypeScript compiles: `cd functions && npm run build`
- [ ] Linting passes: `cd functions && npm run lint`
- [ ] Functions deploy successfully: `firebase deploy --only functions`
- [ ] No deployment errors or warnings

#### Manual Verification:
- [ ] Scheduled function appears in Firebase Console under Cloud Functions
- [ ] Callable function can be invoked from Firebase Console Test Lab
- [ ] Daily insights are created in Firestore after scheduled run
- [ ] Logs show correct execution flow with no errors

**Implementation Note**: After deployment, trigger the scheduled function manually once to verify it works before waiting for the daily schedule.

---

## Phase 4: Flutter Domain - Use Cases

### Overview
Create use cases for generating and refreshing insights, following the journal message pattern.

### Changes Required:

#### 1. Generate Thread Insight Use Case

**File**: `lib/features/insights/domain/usecases/generate_thread_insight_usecase.dart` (NEW FILE)

**Changes**: Create use case for generating thread insights

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Use case for triggering thread insight generation
///
/// This does NOT generate the insight itself - it calls the backend
/// Cloud Function which handles AI analysis.
/// The generated insight will appear via the repository watch stream.
class GenerateThreadInsightUseCase {
  GenerateThreadInsightUseCase({
    required this.insightRepository,
    required this.functions,
  });

  final InsightRepository insightRepository;
  final FirebaseFunctions functions;

  /// Request thread insight generation
  /// Returns immediately - insight appears via stream when backend completes
  Future<Result<void>> execute(String threadId) async {
    try {
      // Note: Current backend generateInsight trigger fires on AI message creation
      // This use case is for future manual refresh capability
      // For now, we just trigger a sync to fetch any new insights

      final user = /* get current user from auth */;
      if (user == null) {
        return const Error(ValidationFailure(message: 'User not authenticated'));
      }

      // Sync insights from remote to ensure we have latest
      final syncResult = await insightRepository.syncInsights(user.id);

      return syncResult.when(
        success: (_) => const Success(null),
        error: (failure) => Error(failure),
      );
    } catch (e) {
      return Error(ServerFailure(message: 'Failed to sync thread insight: $e'));
    }
  }
}
```

#### 2. Generate Global Insight Use Case

**File**: `lib/features/insights/domain/usecases/generate_global_insight_usecase.dart` (NEW FILE)

**Changes**: Create use case for generating global insights with period selection

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';

class GenerateGlobalInsightParams {
  const GenerateGlobalInsightParams({
    required this.period,
    this.forceRefresh = false,
  });

  final InsightPeriod period;
  final bool forceRefresh; // If true, calls backend to regenerate
}

/// Use case for getting/generating global insights for a specific period
///
/// Behavior:
/// - First checks local DB for cached insight for this period
/// - If not found or forceRefresh=true, calls backend to generate
/// - Returns immediately, insight appears via repository watch stream
class GenerateGlobalInsightUseCase {
  GenerateGlobalInsightUseCase({
    required this.insightRepository,
    required this.functions,
  });

  final InsightRepository insightRepository;
  final FirebaseFunctions functions;

  Future<Result<void>> execute(
    String userId,
    GenerateGlobalInsightParams params,
  ) async {
    try {
      // Check if we already have insight for this period (unless forcing refresh)
      if (!params.forceRefresh) {
        final existingResult = await insightRepository.getGlobalInsights(userId);

        final hasInsightForPeriod = existingResult.when(
          success: (insights) {
            // Check if any insight matches the requested period
            return insights.any((insight) => insight.period == params.period);
          },
          error: (_) => false,
        );

        if (hasInsightForPeriod) {
          // Already have insight for this period, no need to regenerate
          return const Success(null);
        }
      }

      // Call backend to generate insight for this period
      final callable = functions.httpsCallable(
        'generatePeriodInsight',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      await callable.call<Map<String, dynamic>>({
        'period': params.period.name,
      });

      // Sync to get the newly generated insight
      await insightRepository.syncInsights(userId);

      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      return Error(ServerFailure(
        message: 'Failed to generate insight: ${e.message}',
      ));
    } catch (e) {
      return Error(ServerFailure(
        message: 'Failed to generate global insight: $e',
      ));
    }
  }
}
```

#### 3. Sync Insights Use Case

**File**: `lib/features/insights/domain/usecases/sync_insights_usecase.dart` (NEW FILE)

**Changes**: Create use case for manual sync

```dart
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/insights/domain/repositories/insight_repository.dart';

/// Use case for manually syncing insights from remote
/// Similar to SyncThreadMessagesUseCase pattern
class SyncInsightsUseCase {
  SyncInsightsUseCase({
    required this.insightRepository,
  });

  final InsightRepository insightRepository;

  Future<Result<void>> execute(String userId) async {
    try {
      return await insightRepository.syncInsights(userId);
    } catch (e) {
      return Error(CacheFailure(message: 'Failed to sync insights: $e'));
    }
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `~/flutter/bin/flutter analyze`
- [ ] No type errors or warnings
- [ ] Use cases follow same pattern as journal message use cases

#### Manual Verification:
- [ ] Use case constructors accept required dependencies
- [ ] Error handling matches existing patterns
- [ ] Result types are correctly defined

---

## Phase 5: Flutter Presentation - Providers and Controller

### Overview
Set up dependency injection providers and create InsightController following the MessageController pattern.

### Changes Required:

#### 1. Update Insight Providers

**File**: `lib/features/insights/presentation/providers/insight_providers.dart`

**Changes**: Add use case and controller providers (after line 44)

```dart
// Use case providers
final generateThreadInsightUseCaseProvider = Provider<GenerateThreadInsightUseCase>((ref) {
  final repository = ref.watch(insightRepositoryProvider);
  return GenerateThreadInsightUseCase(
    insightRepository: repository,
    functions: FirebaseFunctions.instance,
  );
});

final generateGlobalInsightUseCaseProvider = Provider<GenerateGlobalInsightUseCase>((ref) {
  final repository = ref.watch(insightRepositoryProvider);
  return GenerateGlobalInsightUseCase(
    insightRepository: repository,
    functions: FirebaseFunctions.instance,
  );
});

final syncInsightsUseCaseProvider = Provider<SyncInsightsUseCase>((ref) {
  final repository = ref.watch(insightRepositoryProvider);
  return SyncInsightsUseCase(insightRepository: repository);
});

// Stream provider for period-filtered global insights
final globalInsightsByPeriodProvider = StreamProvider.family<InsightEntity?, (String, InsightPeriod)>(
  (ref, params) {
    final (userId, period) = params;
    final repository = ref.watch(insightRepositoryProvider);

    return repository.watchGlobalInsights(userId).map(
      (insights) => insights.firstWhere(
        (insight) => insight.period == period,
        orElse: () => null,
      ),
    );
  },
);

// Controller provider
final insightControllerProvider = StateNotifierProvider<InsightController, InsightState>((ref) {
  final generateThreadUseCase = ref.watch(generateThreadInsightUseCaseProvider);
  final generateGlobalUseCase = ref.watch(generateGlobalInsightUseCaseProvider);
  final syncUseCase = ref.watch(syncInsightsUseCaseProvider);

  return InsightController(
    generateThreadInsightUseCase: generateThreadUseCase,
    generateGlobalInsightUseCase: generateGlobalUseCase,
    syncInsightsUseCase: syncUseCase,
  );
});
```

#### 2. Create Insight Controller

**File**: `lib/features/insights/presentation/controllers/insight_controller.dart` (NEW FILE)

**Changes**: Create controller for insight operations

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/domain/usecases/generate_thread_insight_usecase.dart';
import 'package:kairos/features/insights/domain/usecases/generate_global_insight_usecase.dart';
import 'package:kairos/features/insights/domain/usecases/sync_insights_usecase.dart';

/// States for insight operations
abstract class InsightState {
  const InsightState();
}

class InsightInitial extends InsightState {
  const InsightInitial();
}

class InsightLoading extends InsightState {
  const InsightLoading();
}

class InsightSuccess extends InsightState {
  const InsightSuccess();
}

class InsightError extends InsightState {
  const InsightError(this.message);
  final String message;
}

/// Controller for insight generation and sync operations
/// Follows MessageController pattern
class InsightController extends StateNotifier<InsightState> {
  InsightController({
    required this.generateThreadInsightUseCase,
    required this.generateGlobalInsightUseCase,
    required this.syncInsightsUseCase,
  }) : super(const InsightInitial());

  final GenerateThreadInsightUseCase generateThreadInsightUseCase;
  final GenerateGlobalInsightUseCase generateGlobalInsightUseCase;
  final SyncInsightsUseCase syncInsightsUseCase;

  /// Generate thread insight (or sync existing)
  Future<void> generateThreadInsight(String threadId) async {
    state = const InsightLoading();

    final result = await generateThreadInsightUseCase.execute(threadId);

    result.when(
      success: (_) {
        state = const InsightSuccess();
      },
      error: (failure) {
        state = InsightError(_getErrorMessage(failure));
      },
    );
  }

  /// Generate global insight for specific period
  Future<void> generateGlobalInsight({
    required String userId,
    required InsightPeriod period,
    bool forceRefresh = false,
  }) async {
    state = const InsightLoading();

    final params = GenerateGlobalInsightParams(
      period: period,
      forceRefresh: forceRefresh,
    );

    final result = await generateGlobalInsightUseCase.execute(userId, params);

    result.when(
      success: (_) {
        state = const InsightSuccess();
      },
      error: (failure) {
        state = InsightError(_getErrorMessage(failure));
      },
    );
  }

  /// Manual sync of all insights
  Future<void> syncInsights(String userId) async {
    state = const InsightLoading();

    final result = await syncInsightsUseCase.execute(userId);

    result.when(
      success: (_) {
        state = const InsightSuccess();
      },
      error: (failure) {
        state = InsightError(_getErrorMessage(failure));
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error. Please check your connection.',
      CacheFailure() => 'Local storage error: ${failure.message}',
      ServerFailure() => 'Server error: ${failure.message}',
      _ => 'An unexpected error occurred: ${failure.message}',
    };
  }
}
```

#### 3. Create Insight State Classes

**File**: Same file as above (`insight_controller.dart`)

**Note**: State classes are defined at the top of the controller file (see above)

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `~/flutter/bin/flutter analyze`
- [ ] Providers correctly typed with no warnings
- [ ] Controller extends StateNotifier correctly

#### Manual Verification:
- [ ] Providers can be watched in UI without errors
- [ ] Controller methods can be called from UI
- [ ] State transitions work correctly (Initial → Loading → Success/Error)

---

## Phase 6: UI - Enhanced Global Insights Dashboard

### Overview
Create dedicated Insights tab with time period selection, summary card, and emotion bars.

### Changes Required:

#### 1. Add Insights Route

**File**: `lib/core/routing/app_routes.dart`

**Changes**: Add insights route constant

```dart
// Add after notifications route
static const String insights = '/insights';
```

#### 2. Update Router Configuration

**File**: `lib/core/routing/router_provider.dart`

**Changes**: Add insights route to ShellRoute

```dart
// Add GoRoute for insights (in the ShellRoute routes list)
GoRoute(
  path: AppRoutes.insights,
  builder: (context, state) => const InsightsScreen(),
),
```

#### 3. Update Bottom Navigation

**File**: `lib/core/widgets/main_scaffold.dart`

**Changes**: Replace notifications tab with insights tab

```dart
// Update destinations list (line 41-62)
destinations: [
  NavigationDestination(
    icon: const Icon(Icons.home_outlined),
    selectedIcon: const Icon(Icons.home),
    label: l10n.home,
  ),
  NavigationDestination(
    icon: const Icon(Icons.book_outlined),
    selectedIcon: const Icon(Icons.book),
    label: l10n.journal,
  ),
  NavigationDestination(
    icon: const Icon(Icons.insights_outlined), // CHANGED
    selectedIcon: const Icon(Icons.insights), // CHANGED
    label: 'Insights', // CHANGED (or add to l10n)
  ),
  NavigationDestination(
    icon: const Icon(Icons.settings_outlined),
    selectedIcon: const Icon(Icons.settings),
    label: l10n.settings,
  ),
],

// Update route mapping (line 66-72)
int _getSelectedIndex(String location) {
  if (location.startsWith(AppRoutes.home)) return 0;
  if (location.startsWith(AppRoutes.journal)) return 1;
  if (location.startsWith(AppRoutes.insights)) return 2; // CHANGED
  if (location.startsWith(AppRoutes.settings)) return 3;
  return 0;
}

// Update navigation handler (line 74-84)
void _onItemTapped(int index, BuildContext context) {
  switch (index) {
    case 0:
      context.go(AppRoutes.home);
    case 1:
      context.go(AppRoutes.journal);
    case 2:
      context.go(AppRoutes.insights); // CHANGED
    case 3:
      context.go(AppRoutes.settings);
  }
}
```

#### 4. Create Period Selection Widget

**File**: `lib/features/insights/presentation/widgets/period_selector_widget.dart` (NEW FILE)

**Changes**: Create dropdown for period selection

```dart
import 'package:flutter/material.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/core/theme/app_spacing.dart';

class PeriodSelectorWidget extends StatelessWidget {
  const PeriodSelectorWidget({
    required this.selectedPeriod,
    required this.onPeriodChanged,
    super.key,
  });

  final InsightPeriod selectedPeriod;
  final ValueChanged<InsightPeriod> onPeriodChanged;

  String _getPeriodLabel(InsightPeriod period) {
    return switch (period) {
      InsightPeriod.oneDay => '1 Day',
      InsightPeriod.threeDays => '3 Days',
      InsightPeriod.oneWeek => '1 Week',
      InsightPeriod.oneMonth => '1 Month',
      InsightPeriod.daily => 'Daily', // Not user-selectable
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Only show user-selectable periods
    final selectablePeriods = [
      InsightPeriod.oneDay,
      InsightPeriod.threeDays,
      InsightPeriod.oneWeek,
      InsightPeriod.oneMonth,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InsightPeriod>(
          value: selectedPeriod,
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          items: selectablePeriods.map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(_getPeriodLabel(period)),
            );
          }).toList(),
          onChanged: (period) {
            if (period != null) {
              onPeriodChanged(period);
            }
          },
        ),
      ),
    );
  }
}
```

#### 5. Create Emotion Bars Widget

**File**: `lib/features/insights/presentation/widgets/emotion_bars_widget.dart` (NEW FILE)

**Changes**: Create bar chart showing daily emotions

```dart
import 'package:flutter/material.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/theme/app_colors.dart';

class EmotionBarsWidget extends StatelessWidget {
  const EmotionBarsWidget({
    required this.dailyInsights,
    super.key,
  });

  final List<InsightEntity> dailyInsights;

  Color _getEmotionColor(EmotionType emotion) {
    return switch (emotion) {
      EmotionType.joy => Colors.yellow.shade600,
      EmotionType.calm => Colors.blue.shade400,
      EmotionType.neutral => Colors.grey.shade400,
      EmotionType.sadness => Colors.blue.shade800,
      EmotionType.stress => Colors.orange.shade600,
      EmotionType.anger => Colors.red.shade600,
      EmotionType.fear => Colors.purple.shade600,
      EmotionType.excitement => Colors.pink.shade400,
    };
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (dailyInsights.isEmpty) {
      return Center(
        child: Text(
          'No daily data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Sort insights by date
    final sortedInsights = [...dailyInsights]
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Emotions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Bar chart
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: sortedInsights.map((insight) {
              final barHeight = insight.moodScore * 180; // Max 180px
              final color = _getEmotionColor(insight.dominantEmotion);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bar
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Date label
                      Text(
                        _formatDate(insight.periodStart),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
```

#### 6. Create Insights Screen

**File**: `lib/features/insights/presentation/screens/insights_screen.dart` (NEW FILE)

**Changes**: Create main insights dashboard screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/widgets/empty_state.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:kairos/features/insights/presentation/providers/insight_providers.dart';
import 'package:kairos/features/insights/presentation/widgets/period_selector_widget.dart';
import 'package:kairos/features/insights/presentation/widgets/emotion_bars_widget.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightPeriod _selectedPeriod = InsightPeriod.oneWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    // Watch insights for selected period
    final insightsAsync = ref.watch(currentUserGlobalInsightsProvider);

    return Column(
      children: [
        AppBar(
          title: const Text('Insights'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(insightControllerProvider.notifier).generateGlobalInsight(
                  userId: user.id,
                  period: _selectedPeriod,
                  forceRefresh: true,
                );
              },
            ),
          ],
        ),
        Expanded(
          child: insightsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading insights: $error'),
            ),
            data: (allInsights) {
              // Filter insights by selected period
              final periodInsight = allInsights.firstWhere(
                (i) => i.period == _selectedPeriod,
                orElse: () => null,
              );

              // Get daily insights for bars
              final dailyInsights = allInsights
                .where((i) => i.type == InsightType.dailyGlobal)
                .where((i) {
                  // Filter by period range
                  final now = DateTime.now();
                  final periodDays = switch (_selectedPeriod) {
                    InsightPeriod.oneDay => 1,
                    InsightPeriod.threeDays => 3,
                    InsightPeriod.oneWeek => 7,
                    InsightPeriod.oneMonth => 30,
                    InsightPeriod.daily => 1,
                  };
                  final cutoff = now.subtract(Duration(days: periodDays));
                  return i.periodStart.isAfter(cutoff);
                })
                .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    PeriodSelectorWidget(
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: (period) {
                        setState(() => _selectedPeriod = period);

                        // Trigger generation if insight doesn't exist
                        ref.read(insightControllerProvider.notifier).generateGlobalInsight(
                          userId: user.id,
                          period: period,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Summary card
                    if (periodInsight != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Summary',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                periodInsight.summary,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Icon(
                                    Icons.message_outlined,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${periodInsight.messageCount} messages analyzed',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Emotion bars
                    if (dailyInsights.isNotEmpty) ...[
                      EmotionBarsWidget(dailyInsights: dailyInsights),
                    ] else ...[
                      EmptyState(
                        icon: Icons.bar_chart_outlined,
                        title: 'No daily data yet',
                        message: 'Start journaling to see your emotional patterns',
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `~/flutter/bin/flutter analyze`
- [ ] No routing errors when navigating to insights tab
- [ ] Widgets render without layout errors

#### Manual Verification:
- [ ] Insights tab appears in bottom navigation
- [ ] Tapping Insights tab navigates to InsightsScreen
- [ ] Period dropdown displays and changes selection
- [ ] Summary card displays when period insight exists
- [ ] Emotion bars render correctly with daily data
- [ ] Empty state shows when no data exists
- [ ] Refresh button triggers insight regeneration
- [ ] Loading states display correctly

**Implementation Note**: Test with mock data first to verify UI layouts before connecting to real backend.

---

## Phase 7: UI - Thread Card Visual Covers

### Overview
Update thread cards to display gradient covers based on latest thread insight mood.

### Changes Required:

#### 1. Create Emotion Gradient Helper

**File**: `lib/core/utils/emotion_gradient_helper.dart` (NEW FILE)

**Changes**: Create helper for generating emotion gradients

```dart
import 'package:flutter/material.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';

class EmotionGradientHelper {
  /// Get gradient colors for an emotion
  static LinearGradient getGradientForEmotion(EmotionType emotion) {
    final colors = _getColorsForEmotion(emotion);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  /// Get solid color for emotion (fallback)
  static Color getColorForEmotion(EmotionType emotion) {
    return _getColorsForEmotion(emotion).first;
  }

  static List<Color> _getColorsForEmotion(EmotionType emotion) {
    return switch (emotion) {
      EmotionType.joy => [
          const Color(0xFFFFF176), // Light yellow
          const Color(0xFFFFD54F), // Amber
        ],
      EmotionType.calm => [
          const Color(0xFF81D4FA), // Light blue
          const Color(0xFF4FC3F7), // Sky blue
        ],
      EmotionType.neutral => [
          const Color(0xFFE0E0E0), // Light gray
          const Color(0xFFBDBDBD), // Gray
        ],
      EmotionType.sadness => [
          const Color(0xFF90CAF9), // Pale blue
          const Color(0xFF5C6BC0), // Indigo
        ],
      EmotionType.stress => [
          const Color(0xFFFFB74D), // Light orange
          const Color(0xFFFF9800), // Orange
        ],
      EmotionType.anger => [
          const Color(0xFFEF5350), // Light red
          const Color(0xFFD32F2F), // Red
        ],
      EmotionType.fear => [
          const Color(0xFFBA68C8), // Light purple
          const Color(0xFF8E24AA), // Purple
        ],
      EmotionType.excitement => [
          const Color(0xFFFF80AB), // Light pink
          const Color(0xFFF06292), // Pink
        ],
    };
  }

  /// Get readable text color for emotion background
  static Color getTextColorForEmotion(EmotionType emotion) {
    // Dark text for light emotions, light text for dark emotions
    return switch (emotion) {
      EmotionType.joy ||
      EmotionType.calm ||
      EmotionType.neutral ||
      EmotionType.excitement => Colors.black87,
      EmotionType.sadness ||
      EmotionType.stress ||
      EmotionType.anger ||
      EmotionType.fear => Colors.white,
    };
  }
}
```

#### 2. Update Thread List Tile with Cover

**File**: `lib/features/insights/presentation/widgets/thread_card_with_insight.dart` (NEW FILE)

**Changes**: Create enhanced thread card with insight cover

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/core/utils/emotion_gradient_helper.dart';
import 'package:kairos/features/journal/domain/entities/journal_thread_entity.dart';
import 'package:kairos/features/insights/domain/entities/insight_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

class ThreadCardWithInsight extends StatelessWidget {
  const ThreadCardWithInsight({
    required this.thread,
    required this.insight,
    required this.onTap,
    super.key,
  });

  final JournalThreadEntity thread;
  final InsightEntity? insight; // null if no insight yet
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessageTime = thread.lastMessageAt ?? thread.createdAt;
    final timeAgo = timeago.format(lastMessageTime, locale: 'en_short');

    // Determine gradient based on insight or use default
    final gradient = insight != null
        ? EmotionGradientHelper.getGradientForEmotion(insight.dominantEmotion)
        : LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer,
            ],
          );

    final textColor = insight != null
        ? EmotionGradientHelper.getTextColorForEmotion(insight.dominantEmotion)
        : theme.colorScheme.onPrimaryContainer;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thread title
              Text(
                thread.title ?? 'Untitled Thread',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Insight summary (if available)
              if (insight != null) ...[
                Text(
                  insight.summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Metadata row
              Row(
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${thread.messageCount} ${thread.messageCount == 1 ? 'message' : 'messages'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '• $timeAgo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: textColor.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 3. Update Thread List Screen

**File**: `lib/features/journal/presentation/screens/thread_list_screen.dart`

**Changes**: Replace ThreadListTile with ThreadCardWithInsight

```dart
// Add import at top
import 'package:kairos/features/insights/presentation/providers/insight_providers.dart';
import 'package:kairos/features/insights/presentation/widgets/thread_card_with_insight.dart';

// In build method, update ListView.separated itemBuilder (around line 50-70)

itemBuilder: (context, index) {
  final thread = threads[index];

  // Watch thread insight
  final threadInsightAsync = ref.watch(
    threadInsightsStreamProvider(thread.id),
  );

  return threadInsightAsync.when(
    data: (insights) {
      // Get latest insight (most recent)
      final latestInsight = insights.isNotEmpty ? insights.first : null;

      return ThreadCardWithInsight(
        thread: thread,
        insight: latestInsight,
        onTap: () => context.push('${AppRoutes.journal}/${thread.id}'),
      );
    },
    loading: () => ThreadListTile(
      thread: thread,
      onTap: () => context.push('${AppRoutes.journal}/${thread.id}'),
    ),
    error: (_, __) => ThreadListTile(
      thread: thread,
      onTap: () => context.push('${AppRoutes.journal}/${thread.id}'),
    ),
  );
},
```

### Success Criteria:

#### Automated Verification:
- [ ] Code compiles: `~/flutter/bin/flutter analyze`
- [ ] No import errors or circular dependencies
- [ ] Gradient helper methods return correct types

#### Manual Verification:
- [ ] Thread cards display gradient covers based on insight emotion
- [ ] Summary text overlays on cover with readable contrast
- [ ] Cards without insights show default gradient
- [ ] Tapping cards navigates to thread detail
- [ ] Loading state shows fallback ThreadListTile
- [ ] Gradients animate smoothly when insights update
- [ ] Text remains readable on all gradient backgrounds

**Implementation Note**: Test with threads that have different emotions to verify all gradient combinations look good.

---

## Phase 8: Real-time Insight Updates

### Overview
Ensure insights update automatically when new messages arrive, following the message sync pattern.

### Changes Required:

#### 1. Update Existing Insight Trigger

**File**: `functions/src/functions/insights-triggers.ts`

**Changes**: Ensure trigger updates thread insight cache on thread entity (after line 48)

```typescript
// After generating thread insight, update the thread document with cache
const threadInsightId = `${userId}_${threadId}_${now}`;
const threadRef = db.collection('journalThreads').doc(threadId);

await threadRef.update({
  latestInsightId: threadInsightId,
  latestInsightSummary: /* summary from generated insight */,
  latestInsightMood: /* dominantEmotion from generated insight */,
  updatedAtMillis: now,
});
```

**Note**: This requires accessing the generated insight from insightGenerator - may need to refactor `generateThreadInsight` to return the insight data.

#### 2. Update Thread Repository to Sync Insight Cache

**File**: `lib/features/journal/data/repositories/journal_thread_repository_impl.dart`

**Changes**: Ensure thread updates from Firestore include insight cache fields

**Verification**: Check that `upsertFromRemote` in local data source properly handles the new fields (it should, since we added them to the model in Phase 2).

#### 3. Update Thread Detail Screen to Trigger Sync

**File**: `lib/features/journal/presentation/screens/thread_detail_screen.dart`

**Changes**: Trigger insight sync when entering thread (similar to message sync)

```dart
@override
void initState() {
  super.initState();
  _currentThreadId = widget.threadId;

  // Trigger initial sync on screen entry
  if (_currentThreadId != null) {
    Future.microtask(() {
      ref.read(syncControllerProvider.notifier).syncThread(_currentThreadId!);

      // Also sync insights for this thread
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(insightControllerProvider.notifier).generateThreadInsight(_currentThreadId!);
      }
    });
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] Backend functions deploy successfully: `firebase deploy --only functions`
- [ ] No TypeScript compilation errors
- [ ] Flutter code compiles: `~/flutter/bin/flutter analyze`

#### Manual Verification:
- [ ] Sending a new message in a thread triggers insight generation
- [ ] Thread card cover updates within a few seconds of message sent
- [ ] Thread insight summary updates on the card
- [ ] Gradient color changes if dominant emotion shifts
- [ ] Works when online (immediate update)
- [ ] Works offline (shows cached insight, updates when back online)
- [ ] Multiple threads update independently

**Implementation Note**: Test the entire flow: create message → AI response → insight generated → thread card updates. Verify timing and that no steps are skipped.

---

## Testing Strategy

### Unit Tests

#### Backend Tests:
- **File**: `functions/src/test/insights-generator.test.ts` (NEW FILE)
- Test daily insight generation logic
- Test period insight aggregation
- Test edge cases (empty data, single day, etc.)

#### Flutter Tests:
- **File**: `test/features/insights/domain/usecases/generate_global_insight_usecase_test.dart` (NEW FILE)
- Test use case success paths
- Test use case error handling
- Mock repository and functions calls

### Integration Tests

#### Backend Integration:
- Deploy to staging environment
- Trigger scheduled function manually
- Verify daily insights created in Firestore
- Call `generatePeriodInsight` function manually
- Verify period insights created correctly

#### Flutter Integration:
- **File**: `test/features/insights/integration/insights_ux_flow_test.dart` (NEW FILE)
- Test full flow: navigate to Insights tab → select period → see summary and bars
- Test thread card displays insight cover
- Test offline behavior (cache)

### Manual Testing Steps

1. **Global Insights Dashboard**:
   - Navigate to Insights tab
   - Select "1 Day" - verify summary and bars update
   - Select "1 Week" - verify different data loads
   - Tap refresh - verify loading state and data refresh
   - Go offline - verify cached data displays
   - Come back online - verify sync occurs

2. **Thread Card Covers**:
   - Navigate to Journal tab
   - Verify thread cards show gradient covers
   - Verify summary text is readable
   - Create new message in thread
   - Wait ~10 seconds
   - Pull to refresh thread list
   - Verify card cover updates

3. **Real-time Updates**:
   - Open thread detail screen
   - Send text message
   - Wait for AI response
   - Navigate back to thread list
   - Verify card cover updated

4. **Edge Cases**:
   - New thread with no insight - verify default cover
   - Thread with one message - verify insight generates
   - Period with no daily data - verify empty state
   - Backend error - verify error message displays

---

## Performance Considerations

### Backend Optimizations:
1. **Scheduled Function Batching**: Process users in batches to stay within memory limits
2. **Debouncing**: 1-hour debounce on thread insight generation prevents excessive calls
3. **Indexes**: Firestore composite indexes for efficient period queries
4. **Caching**: Daily insights cached and reused for period aggregations

### Flutter Optimizations:
1. **Stream Providers**: Use Riverpod's caching to prevent redundant fetches
2. **Widget Keys**: Use keys on thread cards to prevent unnecessary rebuilds
3. **Image Caching**: Gradient colors computed once and cached
4. **Lazy Loading**: Load daily insights only when Insights tab is active
5. **Debouncing**: Debounce period selector to prevent rapid backend calls

### Memory Management:
- Limit daily insights query to last 30 days max
- Clean up old insights (>90 days) periodically (future enhancement)
- Use Isar's efficient binary storage for local caching

---

## Migration Notes

### Data Migration:
- **No breaking changes** to existing insight schema (only adding optional fields)
- Existing insights will continue to work (period field defaults to null)
- New insights generated with period field populated
- Thread entities updated lazily as new insights generate

### Backend Deployment:
1. Deploy new functions first: `firebase deploy --only functions:generateDailyInsights,functions:generatePeriodInsight`
2. Manually trigger daily insight generation once to populate initial data
3. Existing `generateInsight` trigger continues working unchanged

### Client Updates:
1. App update includes new UI but gracefully handles missing insights (empty states)
2. Old app versions continue working with existing global insights
3. No forced update required

---

## References

- Original feature plan: `thoughts/shared/plans/2025-11-06-insights-feature.md`
- Journal message pipeline pattern: Analyzed in Phase 1 research
- Backend insight generator: `functions/src/domain/insights/insight-generator.ts`
- Thread entity: `lib/features/journal/domain/entities/journal_thread_entity.dart:1-63`
- Insight entity: `lib/features/insights/domain/entities/insight_entity.dart:1-121`
