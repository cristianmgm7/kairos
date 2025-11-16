import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { geminiApiKey } from '../config/genkit';
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
