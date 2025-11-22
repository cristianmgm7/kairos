import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createCategoryInsightGenerator } from '../domain/insights/category-insight-generator';
import { InsightCategory } from '../config/constants';

const db = admin.firestore();

/**
 * Callable function: Generate or refresh insight for a specific category
 * 
 * This is the ONLY way insights are generated - user-initiated only.
 * No automatic background processing.
 */
export const generateCategoryInsight = onCall(
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
    const { category, forceRefresh = false } = request.data;

    // Validate category
    if (!Object.values(InsightCategory).includes(category)) {
      throw new HttpsError('invalid-argument', `Invalid category: ${category}`);
    }

    console.log(`[Generate Category Insight] ${userId} - ${category} (force: ${forceRefresh})`);

    const generator = createCategoryInsightGenerator(db);

    try {
      const insight = await generator.generate(userId, category, forceRefresh);

      return {
        success: true,
        insight: {
          category: insight.category,
          summary: insight.summary,
          keyPatterns: insight.keyPatterns,
          strengths: insight.strengths,
          opportunities: insight.opportunities,
          lastRefreshedAt: insight.lastRefreshedAt,
          memoryCount: insight.memoryCount,
        },
      };
    } catch (error) {
      console.error(`[Generate Category Insight] Error:`, error);
      throw new HttpsError('internal', 'Failed to generate insight');
    }
  }
);

