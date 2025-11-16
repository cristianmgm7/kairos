import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createInsightGenerator } from '../domain/insights/insight-generator';
import { InsightType } from '../config/constants';
import { aggregateInsights } from '../domain/insights/insight-aggregator';
import { getInsightRepository } from '../data/repositories';

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
    const insightRepo = getInsightRepository(db);

    try {
      // Calculate period boundaries
      const daysMap: Record<string, number> = {
        oneDay: 1,
        threeDays: 3,
        oneWeek: 7,
        oneMonth: 30,
      };
      const days = daysMap[period];
      const periodStart = now - (days * 24 * 60 * 60 * 1000);

      // Get all daily insights in this period
      const dailyInsights = await insightRepo.getDailyInsightsInRange(
        userId,
        periodStart,
        now
      );

      // If no daily insights exist, fall back to generating from thread insights
      if (dailyInsights.length === 0) {
        console.log('No daily insights found, generating from thread insights');
        // This will aggregate thread insights (existing logic)
        await insightGenerator.generateGlobalInsight(userId, now);
        return { success: true, message: 'Generated from thread insights' };
      }

      // Aggregate daily insights into period insight
      const aggregated = aggregateInsights(dailyInsights);
      if (!aggregated) {
        throw new HttpsError('internal', 'Failed to aggregate insights');
      }

      // Create or update period insight
      const insightId = `${userId}_${period}_${periodStart}`;
      await insightRepo.create({
        id: insightId,
        userId,
        type: InsightType.GLOBAL,
        threadId: null,
        period,
        periodStartMillis: periodStart,
        periodEndMillis: now,
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
