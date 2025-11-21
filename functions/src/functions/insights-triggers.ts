import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { geminiApiKey } from '../config/genkit';
import { getAI } from '../config/genkit';
import { createInsightGenerator } from '../domain/insights/insight-generator';
import { MessageRole } from '../config/constants';

const db = admin.firestore();

/**
 * Firestore trigger: When a new AI message is created,
 * generate or update insights for the thread and global view
 */
export const generateInsight = onDocumentCreated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async function (event) {
    const messageData = event.data?.data();
    if (!messageData) return;

    // Only process AI messages
    if (messageData.role !== MessageRole.AI) {
      console.log('Skipping non-AI message for insight generation');
      return;
    }

    const threadId = messageData.threadId as string;
    const userId = messageData.userId as string;
    const now = Date.now();

    console.log(`Generating insight for thread ${threadId}`);

    const ai = getAI(geminiApiKey.value());
    const insightGenerator = createInsightGenerator(db);

    try {
      // Generate thread insight
      const insightData = await insightGenerator.generateThreadInsight(
        ai,
        threadId,
        userId,
        now
      );

      // Update thread document with insight cache
      if (insightData) {
        const threadRef = db.collection('journalThreads').doc(threadId);
        await threadRef.update({
          latestInsightSummary: insightData.summary,
          latestInsightMood: insightData.dominantEmotion,
          updatedAtMillis: now,
        });
        console.log(`Updated thread ${threadId} with insight cache`);
      }

      // Generate global insight
      await insightGenerator.generateGlobalInsight(userId, now);

      console.log(`Insight generation complete for thread ${threadId}`);
    } catch (error) {
      console.error('Error generating insight:', error);
    }
  }
);

