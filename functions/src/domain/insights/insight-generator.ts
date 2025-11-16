import * as admin from 'firebase-admin';
import { getMessageRepository, getInsightRepository } from '../../data/repositories';
import { extractKeywords } from './keyword-extractor';
import { analyzeMessagesWithAI } from './ai-analyzer';
import { aggregateInsights } from './insight-aggregator';
import { INSIGHTS_CONFIG, InsightType } from '../../config/constants';

export class InsightGenerator {
  private messageRepo: ReturnType<typeof getMessageRepository>;
  private insightRepo: ReturnType<typeof getInsightRepository>;

  constructor(db: admin.firestore.Firestore) {
    this.messageRepo = getMessageRepository(db);
    this.insightRepo = getInsightRepository(db);
  }

  /**
   * Generate or update thread-level insight
   * Returns the insight data for caching on thread document
   */
  async generateThreadInsight(
    ai: any,
    threadId: string,
    userId: string,
    now: number
  ): Promise<{ summary: string; dominantEmotion: number } | null> {
    const threeDaysAgo = now - INSIGHTS_CONFIG.threeDaysMs;
    const oneHourAgo = now - INSIGHTS_CONFIG.oneHourMs;
    const oneDayAgo = now - INSIGHTS_CONFIG.oneDayMs;

    // Debounce check
    const wasRecentlyUpdated = await this.insightRepo.wasRecentlyUpdated(
      userId,
      threadId,
      oneHourAgo
    );

    if (wasRecentlyUpdated) {
      console.log(`Skipping insight generation - updated within last hour for thread ${threadId}`);
      return null;
    }

    // Get recent messages
    const messages = await this.messageRepo.getMessagesInRange(
      threadId,
      userId,
      threeDaysAgo
    );

    if (messages.length === 0) {
      console.log('No recent messages found for insight generation');
      return null;
    }

    // Extract keywords
    const keywords = extractKeywords(messages);

    // Analyze with AI
    const analysis = await analyzeMessagesWithAI(ai, messages);
    analysis.keywords = keywords;

    // Determine period
    const periodStart = messages[0].createdAtMillis;
    const periodEnd = now;

    // Check for recent insight (within 24 hours)
    const recentInsight = await this.insightRepo.findRecentThreadInsight(
      userId,
      threadId,
      oneDayAgo
    );

    if (recentInsight) {
      // Update existing
      await this.insightRepo.update(recentInsight.id, {
        periodEndMillis: periodEnd,
        moodScore: analysis.moodScore,
        dominantEmotion: analysis.dominantEmotion,
        keywords: analysis.keywords,
        aiThemes: analysis.aiThemes,
        summary: analysis.summary,
        messageCount: messages.length,
      });

      console.log(`Updated existing insight ${recentInsight.id}`);
    } else {
      // Create new
      const insightId = `${userId}_${threadId}_${periodStart}`;
      await this.insightRepo.create({
        id: insightId,
        userId,
        type: InsightType.THREAD,
        threadId,
        periodStartMillis: periodStart,
        periodEndMillis: periodEnd,
        moodScore: analysis.moodScore,
        dominantEmotion: analysis.dominantEmotion,
        keywords: analysis.keywords,
        aiThemes: analysis.aiThemes,
        summary: analysis.summary,
        messageCount: messages.length,
      });

      console.log(`Created new insight ${insightId}`);
    }

    // Return summary and emotion for caching on thread
    return {
      summary: analysis.summary,
      dominantEmotion: analysis.dominantEmotion,
    };
  }

  /**
   * Generate or update global aggregated insight
   */
  async generateGlobalInsight(userId: string, now: number): Promise<void> {
    const threeDaysAgo = now - INSIGHTS_CONFIG.threeDaysMs;
    const oneDayAgo = now - INSIGHTS_CONFIG.oneDayMs;

    // Get all thread insights from last 3 days
    const threadInsights = await this.insightRepo.getThreadInsights(userId, threeDaysAgo);

    if (threadInsights.length === 0) {
      console.log('No thread insights found for global aggregation');
      return;
    }

    // Aggregate
    const aggregated = aggregateInsights(threadInsights);
    if (!aggregated) return;

    // Find earliest periodStart
    const periodStart = Math.min(...threadInsights.map(ins => ins.periodStartMillis));

    // Check for recent global insight
    const recentGlobal = await this.insightRepo.findRecentGlobalInsight(userId, oneDayAgo);

    if (recentGlobal) {
      // Update existing
      await this.insightRepo.update(recentGlobal.id, {
        periodEndMillis: now,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
      });

      console.log(`Updated global insight ${recentGlobal.id}`);
    } else {
      // Create new
      const globalInsightId = `${userId}_global_${periodStart}`;
      await this.insightRepo.create({
        id: globalInsightId,
        userId,
        type: InsightType.GLOBAL,
        threadId: null,
        periodStartMillis: periodStart,
        periodEndMillis: now,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
      });

      console.log(`Created global insight ${globalInsightId}`);
    }
  }

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
}

// Factory function
export function createInsightGenerator(
  db: admin.firestore.Firestore
): InsightGenerator {
  return new InsightGenerator(db);
}

