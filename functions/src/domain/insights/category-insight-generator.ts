import * as admin from 'firebase-admin';
import { googleAI } from '@genkit-ai/google-genai';
import { getAI, geminiApiKey } from '../../config/genkit';
import { CategoryInsightDocument, createEmptyCategoryInsight } from '../../data/models/category-insight';
import { getCategoryInsightRepository } from '../../data/repositories/category-insight-repository';
import {
  InsightCategory,
  INSIGHT_CATEGORY_DESCRIPTIONS,
  CATEGORY_INSIGHTS_CONFIG,
} from '../../config/constants';

/**
 * Insight Generation Prompt
 */
const INSIGHT_GENERATION_PROMPT = `You are an AI insight generator for a personal journaling app. Generate a thoughtful, personalized insight for the user based on their memories in the "{category}" category.

Category Description: {categoryDescription}

## User's Memories:
{memories}

## Instructions:
Analyze these memories and provide:

1. **Summary** (2-3 sentences): A high-level insight about the user's experiences, patterns, or themes in this area.

2. **Key Patterns** (3-5 bullet points): Specific recurring themes, behaviors, or situations you observe.

3. **Strengths** (2-3 bullet points): Positive qualities, achievements, or effective strategies the user demonstrates.

4. **Opportunities** (2-3 bullet points): Areas for growth, new approaches to try, or aspects to explore further.

## Output Format (JSON):
{
  "summary": "...",
  "keyPatterns": ["...", "...", "..."],
  "strengths": ["...", "..."],
  "opportunities": ["...", "..."]
}

Be specific, empathetic, and actionable. Focus on patterns rather than individual events.`;

export class CategoryInsightGenerator {
  private db: admin.firestore.Firestore;
  private repository: ReturnType<typeof getCategoryInsightRepository>;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
    this.repository = getCategoryInsightRepository(db);
  }

  /**
   * Generate insight for a specific category
   */
  async generate(
    userId: string,
    category: InsightCategory,
    forceRefresh: boolean = false
  ): Promise<CategoryInsightDocument> {
    console.log(`[Category Insight Generator] Generating insight for ${userId} - ${category}`);

    // Check rate limit
    if (!forceRefresh) {
      const canRefresh = await this.repository.canRefresh(
        userId,
        category,
        CATEGORY_INSIGHTS_CONFIG.refreshRateLimitMs
      );

      if (!canRefresh) {
        console.log(`[Category Insight Generator] Rate limit active, returning existing insight`);
        const existing = await this.repository.get(userId, category);
        if (existing) return existing;
      }
    }

    // 1. Fetch memories for this category
    const memories = await this.fetchCategoryMemories(userId, category);

    console.log(`[Category Insight Generator] Found ${memories.length} memories for ${category}`);

    // 2. If no memories, return empty insight
    if (memories.length === 0) {
      const emptyInsight = createEmptyCategoryInsight(userId, category);
      await this.repository.set(userId, emptyInsight);
      return emptyInsight;
    }

    // 3. Generate insight using LLM
    const insightData = await this.generateInsightWithLLM(category, memories);

    // 4. Create insight document
    const now = Date.now();
    const insight: CategoryInsightDocument = {
      userId,
      category,
      summary: insightData.summary,
      keyPatterns: insightData.keyPatterns,
      strengths: insightData.strengths,
      opportunities: insightData.opportunities,
      lastRefreshedAt: now,
      memoryCount: memories.length,
      memoryIds: memories.map(m => m.id),
      createdAt: now,
      updatedAt: now,
    };

    // 5. Save to Firestore
    await this.repository.set(userId, insight);

    console.log(`[Category Insight Generator] Generated insight for ${category}: ${insight.summary.substring(0, 60)}...`);

    return insight;
  }

  /**
   * Fetch memories for a category (limited to top N most recent)
   */
  private async fetchCategoryMemories(
    userId: string,
    category: InsightCategory
  ): Promise<Array<{ id: string; content: string; createdAt: number }>> {
    const snapshot = await this.db
      .collection('kairos_memories')
      .where('userId', '==', userId)
      .where('metadata.categories', 'array-contains', category)
      .orderBy('createdAt', 'desc')
      .limit(CATEGORY_INSIGHTS_CONFIG.maxMemoriesPerInsight)
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      content: doc.data().content as string,
      createdAt: (doc.data().createdAt as admin.firestore.Timestamp).toMillis(),
    }));
  }

  /**
   * Generate insight using LLM
   */
  private async generateInsightWithLLM(
    category: InsightCategory,
    memories: Array<{ content: string }>
  ): Promise<{
    summary: string;
    keyPatterns: string[];
    strengths: string[];
    opportunities: string[];
  }> {
    const ai = getAI(geminiApiKey.value());

    // Format memories as numbered list
    const memoriesText = memories.map((m, i) => `${i + 1}. ${m.content}`).join('\n');

    const prompt = INSIGHT_GENERATION_PROMPT
      .replace('{category}', category.replace(/_/g, ' '))
      .replace('{categoryDescription}', INSIGHT_CATEGORY_DESCRIPTIONS[category])
      .replace('{memories}', memoriesText);

    const response = await ai.generate({
      model: googleAI.model('gemini-1.5-flash'),
      prompt,
      config: {
        temperature: CATEGORY_INSIGHTS_CONFIG.generationTemperature,
        maxOutputTokens: CATEGORY_INSIGHTS_CONFIG.maxInsightTokens,
        responseFormat: 'json', // Request JSON output
      },
    });

    const rawText = response.text || '{}';

    try {
      const parsed = JSON.parse(rawText);
      return {
        summary: parsed.summary || 'No summary available.',
        keyPatterns: Array.isArray(parsed.keyPatterns) ? parsed.keyPatterns : [],
        strengths: Array.isArray(parsed.strengths) ? parsed.strengths : [],
        opportunities: Array.isArray(parsed.opportunities) ? parsed.opportunities : [],
      };
    } catch (error) {
      console.error(`[Category Insight Generator] Failed to parse JSON response:`, error);
      return {
        summary: 'Failed to generate insight.',
        keyPatterns: [],
        strengths: [],
        opportunities: [],
      };
    }
  }

  /**
   * Generate all category insights for a user
   */
  async generateAll(userId: string): Promise<CategoryInsightDocument[]> {
    const categories = Object.values(InsightCategory);
    const results: CategoryInsightDocument[] = [];

    for (const category of categories) {
      try {
        const insight = await this.generate(userId, category, false);
        results.push(insight);
      } catch (error) {
        console.error(`[Category Insight Generator] Failed to generate ${category}:`, error);
        // Continue with other categories
      }
    }

    return results;
  }
}

/**
 * Factory function
 */
export function createCategoryInsightGenerator(
  db: admin.firestore.Firestore
): CategoryInsightGenerator {
  return new CategoryInsightGenerator(db);
}

