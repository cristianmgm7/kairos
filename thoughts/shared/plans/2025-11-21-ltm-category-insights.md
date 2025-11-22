# LTM-Powered Category Insights Implementation Plan

## Overview

Complete rewrite of the insights feature to generate insights from Long Term Memory (LTM) organized into 6 fixed categories. This is a green-field implementation with **zero backward compatibility** - the old message-based insights system will be entirely deleted.

## Current State Analysis

### What Exists Now

1. **Old Insights System** (TO BE DELETED)
   - Message-based insight generation ([insight-generator.ts:8-231](../../../functions/src/domain/insights/insight-generator.ts#L8-L231))
   - Three insight types: Thread, Global, Daily Global
   - Time-period filtering (1 day, 3 days, 1 week, 1 month)
   - Firestore triggers on message creation ([insights-triggers.ts:14-69](../../../functions/src/functions/insights-triggers.ts#L14-L69))
   - Scheduled daily insight generation ([scheduled-insights.ts:12-65](../../../functions/src/functions/scheduled-insights.ts#L12-L65))
   - Complex aggregation logic ([insight-aggregator.ts:4-59](../../../functions/src/domain/insights/insight-aggregator.ts#L4-L59))
   - Frontend with period selectors, mood charts, emotion widgets

2. **Long Term Memory System** (CURRENT - KEEP)
   - Memory extraction from conversations ([kairos.ingest.ts:74-156](../../../functions/src/agents/kairos.ingest.ts#L74-L156))
   - Vector embeddings with `text-embedding-004` ([kairos.rag.ts:17-135](../../../functions/src/agents/kairos.rag.ts#L17-L135))
   - Firestore collection: `kairos_memories` with vector search
   - Semantic retrieval for agent context
   - **Missing**: Category classification (to be added)

### Key Discoveries

- Memory ingestion already extracts 3-5 facts per conversation turn
- Memories stored with metadata: `source`, `threadId`, `messageId`, `extractedAt`
- No category field exists yet on memories
- Vector indexes configured at [firestore.indexes.json:234-263](../../../firestore.indexes.json#L234-L263)
- Old insights completely decoupled from agent - safe to delete entirely

## Desired End State

### Functional Requirements

1. **Memory Category Classification**
   - Every memory gets classified into 0-2 categories when created
   - 6 fixed categories:
     - `mindset_wellbeing`: Thought patterns, emotional regulation, stress, resilience, happiness
     - `productivity_focus`: Time management, procrastination, concentration, task completion
     - `relationships_connection`: Interpersonal dynamics, communication, empathy, social connections
     - `career_growth`: Professional development, learning, ambition, work challenges
     - `health_lifestyle`: Physical well-being, habits (sleep, exercise, nutrition), self-care
     - `purpose_values`: Life meaning, personal values, long-term vision, existential reflections
   - Cheap LLM classifies before memory is saved

2. **One Insight Per Category**
   - Exactly 6 insight documents per user: `users/{userId}/kairos_insights/{category}`
   - Each insight generated from all memories in that category (or top N if >100)
   - Structure:
     ```typescript
     {
       category: string,
       summary: string,
       keyPatterns: string[],
       strengths: string[],
       opportunities: string[],
       lastRefreshedAt: number,
       memoryCount: number,
       memoryIds: string[], // Top N memory IDs used
     }
     ```

3. **Manual Generation & Refresh (No Automatic Triggers)**
   - First time: User clicks "Generate Insights" button for a category
   - After generation: User can click "Refresh" to regenerate
   - No automatic background processing - all user-initiated
   - User can manually refresh any category insight
   - Rate limit: 1 refresh per category per hour
   - Frontend checks `lastRefreshedAt` to enable/disable button

5. **Clean UI**
   - Main screen: 6 cards (one per category)
   - Card shows: category icon, name, brief summary (1 line)
   - Tap card → Detail screen with full insight
   - Detail screen has "Refresh" button
   - Empty state: "No insights yet in this domain" with category description

6. **Complete Deletion of Old System**
   - All old insights code deleted (backend + frontend)
   - No migration scripts
   - No backward compatibility
   - Fresh start

### Technical Requirements

1. **Category classification**: Use `gemini-2.0-flash` (fast, cheap)
2. **Insight generation**: Use `gemini-1.5-flash` (good balance)
3. **Rate limiting**: Store `lastRefreshedAt` in insight document
4. **Cost efficiency**: Batch memory retrieval, limit to top 50 memories per category
5. **Observability**: Log category classification, insight generation success/failure
6. **Testability**: Category classifier and insight generator testable in isolation

## What We're NOT Doing

- No migration from old insights to new system
- No backward compatibility with old insights
- No time-based filtering (1 day, 3 days, etc.)
- No thread-level insights (only user-level category insights)
- No mood scores or emotion tracking (unless extracted from memories)
- No scheduled daily generation (only on-demand + background triggers)
- No period selectors in UI

## Implementation Approach

**Strategy**: Delete old, build new with clean separation of concerns.

**Order**: Backend first (classification + generation), then delete old code, then frontend.

**Philosophy**: Simple, predictable, future-proof. One source of truth (LTM), one insight per category, one clear UI.

---

## Phase 1: Add Category Classification to Memory Ingestion

### Overview
Extend the memory ingestion flow to classify each extracted fact into 0-2 categories before saving.

### Changes Required

#### 1. Create Category Constants

**File**: `functions/src/config/constants.ts`

Add after line 93:

```typescript
// Insight Categories
export enum InsightCategory {
  MINDSET_WELLBEING = 'mindset_wellbeing',
  PRODUCTIVITY_FOCUS = 'productivity_focus',
  RELATIONSHIPS_CONNECTION = 'relationships_connection',
  CAREER_GROWTH = 'career_growth',
  HEALTH_LIFESTYLE = 'health_lifestyle',
  PURPOSE_VALUES = 'purpose_values',
}

export const INSIGHT_CATEGORY_DESCRIPTIONS = {
  [InsightCategory.MINDSET_WELLBEING]: 'Thought patterns, emotional regulation, stress, resilience, and happiness',
  [InsightCategory.PRODUCTIVITY_FOCUS]: 'Time management, procrastination, concentration, and task completion',
  [InsightCategory.RELATIONSHIPS_CONNECTION]: 'Interpersonal dynamics, communication, empathy, and social connections',
  [InsightCategory.CAREER_GROWTH]: 'Professional development, learning new skills, ambition, and work challenges',
  [InsightCategory.HEALTH_LIFESTYLE]: 'Physical well-being, habits (sleep, exercise, nutrition), and self-care',
  [InsightCategory.PURPOSE_VALUES]: 'Life meaning, personal values, long-term vision, and existential reflections',
};

// Category Insights Config
export const CATEGORY_INSIGHTS_CONFIG = {
  maxMemoriesPerInsight: 50, // Limit memories used for insight generation
  refreshRateLimitMs: 60 * 60 * 1000, // 1 hour
  classificationTemperature: 0.2, // Low temperature for consistent classification
  generationTemperature: 0.7, // Higher for creative insights
  maxClassificationTokens: 100,
  maxInsightTokens: 800,
};
```

#### 2. Create Category Classifier

**File**: `functions/src/domain/insights/category-classifier.ts` (NEW)

```typescript
import { z } from 'zod';
import { googleAI } from '@genkit-ai/google-genai';
import { getAI, geminiApiKey } from '../../config/genkit';
import { InsightCategory, CATEGORY_INSIGHTS_CONFIG } from '../../config/constants';

/**
 * Classification prompt
 * 
 * Instructs LLM to classify a memory fact into 0-2 categories.
 */
const CLASSIFICATION_PROMPT = `You are a memory categorization system. Classify the following memory fact into 0-2 of these categories:

Categories:
1. mindset_wellbeing - Thought patterns, emotional regulation, stress, resilience, happiness
2. productivity_focus - Time management, procrastination, concentration, task completion
3. relationships_connection - Interpersonal dynamics, communication, empathy, social connections
4. career_growth - Professional development, learning skills, ambition, work challenges
5. health_lifestyle - Physical well-being, habits (sleep, exercise, nutrition), self-care
6. purpose_values - Life meaning, personal values, long-term vision, existential reflections

Rules:
- Return 0-2 categories maximum (most relevant)
- If the fact doesn't clearly fit any category, return empty
- Return ONLY category names, comma-separated, no explanation
- Examples:
  * "I'm learning React for my new job" → career_growth
  * "I felt anxious today but managed to calm down" → mindset_wellbeing
  * "I'm questioning whether this career path is right for me" → career_growth, purpose_values
  * "I slept 8 hours last night" → health_lifestyle
  * "I had a great conversation with my friend" → relationships_connection

Memory Fact: {fact}

Categories (0-2, comma-separated):`;

/**
 * Classify a memory fact into categories
 * 
 * @param fact - The memory fact to classify
 * @returns Array of category strings (0-2 items)
 */
export async function classifyMemoryFact(fact: string): Promise<string[]> {
  console.log(`[Category Classifier] Classifying: "${fact.substring(0, 60)}..."`);

  try {
    const ai = getAI(geminiApiKey.value());

    const prompt = CLASSIFICATION_PROMPT.replace('{fact}', fact);

    const response = await ai.generate({
      model: googleAI.model('gemini-2.0-flash'), // Fast, cheap
      prompt,
      config: {
        temperature: CATEGORY_INSIGHTS_CONFIG.classificationTemperature,
        maxOutputTokens: CATEGORY_INSIGHTS_CONFIG.maxClassificationTokens,
      },
    });

    const rawText = (response.text || '').trim();
    console.log(`[Category Classifier] Raw response: "${rawText}"`);

    // Parse comma-separated categories
    const categories = rawText
      .split(',')
      .map(cat => cat.trim())
      .filter(cat => Object.values(InsightCategory).includes(cat as InsightCategory))
      .slice(0, 2); // Max 2 categories

    console.log(`[Category Classifier] Extracted categories: [${categories.join(', ')}]`);

    return categories;
  } catch (error) {
    console.error(`[Category Classifier] Classification failed:`, error);
    return []; // Return empty on error (fact will be saved without categories)
  }
}

/**
 * Batch classify multiple facts
 * 
 * @param facts - Array of memory facts
 * @returns Array of category arrays (parallel to input)
 */
export async function classifyMemoryFacts(facts: string[]): Promise<string[][]> {
  console.log(`[Category Classifier] Batch classifying ${facts.length} facts`);

  // Classify sequentially to avoid rate limits
  // TODO: Could optimize with Promise.all if needed
  const results: string[][] = [];
  for (const fact of facts) {
    const categories = await classifyMemoryFact(fact);
    results.push(categories);
  }

  return results;
}
```

#### 3. Update Memory Schema to Include Categories

**File**: `functions/src/agents/kairos.rag.ts`

Update `indexMemory` function (lines 71-95) to include categories:

```typescript
export async function indexMemory(
  userId: string,
  content: string,
  metadata: {
    source: 'auto_extracted' | 'user_confirmed';
    threadId?: string;
    messageId?: string;
    extractedAt: number;
    tags?: string[];
    categories?: string[]; // NEW: Add categories
  }
): Promise<string> {
  // Generate embedding
  const embedding = await generateEmbedding(content);

  // Store in Firestore with vector field
  const docRef = await firestore.collection('kairos_memories').add({
    userId,
    content,
    embedding: FieldValue.vector(embedding),
    metadata: {
      ...metadata,
      categories: metadata.categories || [], // NEW: Store categories
    },
    createdAt: FieldValue.serverTimestamp(),
  });

  return docRef.id;
}
```

#### 4. Update Memory Ingestion to Classify Facts

**File**: `functions/src/agents/kairos.ingest.ts`

Update the memory indexing loop (lines 123-138):

```typescript
import { classifyMemoryFacts } from '../domain/insights/category-classifier';

// ... (keep existing code until line 121)

    // 2.5. Classify all facts into categories (NEW)
    console.log(`[Memory Ingest] Classifying ${facts.length} facts into categories...`);
    const factsCategories = await classifyMemoryFacts(facts);

    // 3. Index each fact as a separate memory with categories
    const memoryIds: string[] = [];
    for (let i = 0; i < facts.length; i++) {
      const fact = facts[i];
      const categories = factsCategories[i] || [];

      try {
        const memoryId = await indexMemory(userId, fact, {
          source: 'auto_extracted',
          threadId,
          messageId,
          extractedAt: Date.now(),
          categories, // NEW: Pass categories
        });
        memoryIds.push(memoryId);
        console.log(
          `[Memory Ingest] Indexed fact with categories [${categories.join(', ')}]: "${fact.substring(0, 50)}..."`
        );
      } catch (error) {
        console.error(`[Memory Ingest] Failed to index fact: ${error}`);
        // Continue with other facts
      }
    }
```

### Success Criteria

#### Automated Verification:
- [x] Type checking passes: `cd functions && npm run typecheck`
- [x] Linting passes: `cd functions && npm run lint`
- [x] Build succeeds: `cd functions && npm run build`

#### Manual Verification:
- [ ] Create a test conversation in the app
- [ ] Check Firestore `kairos_memories` collection for new memory documents
- [ ] Verify `metadata.categories` field exists and contains 0-2 valid category names
- [ ] Check Cloud Functions logs for classification output
- [ ] Test with various fact types (career, health, relationships, etc.)
- [ ] Verify empty categories for non-categorizable facts

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 2: Create Category Insights Generation System

### Overview
Create the new insights system that generates one insight per category from relevant memories. Includes data models, repository, and generation logic.

### Changes Required

#### 1. Create Category Insight Data Model

**File**: `functions/src/data/models/category-insight.ts` (NEW)

```typescript
import { InsightCategory } from '../../config/constants';

/**
 * Category Insight Document (Firestore)
 * 
 * Path: users/{userId}/kairos_insights/{category}
 */
export interface CategoryInsightDocument {
  userId: string;
  category: InsightCategory;
  summary: string; // Natural language insight summary
  keyPatterns: string[]; // 3-5 identified patterns
  strengths: string[]; // 2-3 user strengths in this area
  opportunities: string[]; // 2-3 growth opportunities
  lastRefreshedAt: number; // Timestamp of last generation
  memoryCount: number; // Total memories in this category
  memoryIds: string[]; // IDs of memories used (for reference)
  createdAt: number;
  updatedAt: number;
}

/**
 * Helper: Create empty insight for category
 */
export function createEmptyCategoryInsight(
  userId: string,
  category: InsightCategory
): CategoryInsightDocument {
  const now = Date.now();
  return {
    userId,
    category,
    summary: '',
    keyPatterns: [],
    strengths: [],
    opportunities: [],
    lastRefreshedAt: 0,
    memoryCount: 0,
    memoryIds: [],
    createdAt: now,
    updatedAt: now,
  };
}
```

#### 2. Create Category Insight Repository

**File**: `functions/src/data/repositories/category-insight-repository.ts` (NEW)

```typescript
import * as admin from 'firebase-admin';
import { CategoryInsightDocument } from '../models/category-insight';
import { InsightCategory } from '../../config/constants';

export class CategoryInsightRepository {
  private db: admin.firestore.Firestore;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
  }

  /**
   * Get insight for a specific category
   */
  async get(userId: string, category: InsightCategory): Promise<CategoryInsightDocument | null> {
    const docRef = this.db.collection('users').doc(userId).collection('kairos_insights').doc(category);
    const doc = await docRef.get();

    if (!doc.exists) {
      return null;
    }

    return doc.data() as CategoryInsightDocument;
  }

  /**
   * Get all insights for a user (all 6 categories)
   */
  async getAll(userId: string): Promise<CategoryInsightDocument[]> {
    const snapshot = await this.db
      .collection('users')
      .doc(userId)
      .collection('kairos_insights')
      .get();

    return snapshot.docs.map(doc => doc.data() as CategoryInsightDocument);
  }

  /**
   * Create or update insight
   */
  async set(userId: string, insight: CategoryInsightDocument): Promise<void> {
    const docRef = this.db
      .collection('users')
      .doc(userId)
      .collection('kairos_insights')
      .doc(insight.category);

    await docRef.set(insight, { merge: false });
  }

  /**
   * Check if insight can be refreshed (rate limit check)
   */
  async canRefresh(userId: string, category: InsightCategory, rateLimitMs: number): Promise<boolean> {
    const insight = await this.get(userId, category);
    if (!insight) return true; // No insight yet, allow generation

    const now = Date.now();
    const timeSinceLastRefresh = now - insight.lastRefreshedAt;
    return timeSinceLastRefresh >= rateLimitMs;
  }

  /**
   * Delete insight
   */
  async delete(userId: string, category: InsightCategory): Promise<void> {
    const docRef = this.db
      .collection('users')
      .doc(userId)
      .collection('kairos_insights')
      .doc(category);

    await docRef.delete();
  }
}

/**
 * Factory function
 */
export function getCategoryInsightRepository(
  db: admin.firestore.Firestore
): CategoryInsightRepository {
  return new CategoryInsightRepository(db);
}
```

#### 3. Create Category Insight Generator

**File**: `functions/src/domain/insights/category-insight-generator.ts` (NEW)

```typescript
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
```

#### 4. Create Callable Function for Manual Generation/Refresh

**File**: `functions/src/functions/category-insights-callable.ts` (NEW)

```typescript
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
```

#### 5. Export New Functions

**File**: `functions/src/index.ts`

Add after existing exports (around line 30):

```typescript
// Category Insights (NEW - Manual generation only)
export { generateCategoryInsight } from './functions/category-insights-callable';
```

#### 6. Update Firestore Indexes

**File**: `firestore.indexes.json`

Add index for category queries (after existing indexes):

```json
{
  "collectionGroup": "kairos_memories",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "userId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "metadata.categories",
      "arrayConfig": "CONTAINS"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

### Success Criteria

#### Automated Verification:
- [ ] Type checking passes: `cd functions && npm run typecheck`
- [ ] Linting passes: `cd functions && npm run lint`
- [ ] Build succeeds: `cd functions && npm run build`
- [ ] Deploy functions: `npm run deploy:functions` (or your deploy command)
- [ ] Firestore indexes created: Check Firebase Console

#### Manual Verification:
- [ ] Create memories with categories (from Phase 1)
- [ ] Call `generateCategoryInsight` function manually via Firebase Console
- [ ] Pass: `{category: 'mindset_wellbeing', forceRefresh: true}`
- [ ] Check Firestore `users/{userId}/kairos_insights/` collection for insight document
- [ ] Verify insight contains: summary, keyPatterns, strengths, opportunities
- [ ] Test rate limiting: Call again with `forceRefresh: false`
- [ ] Verify rate limit prevents second generation (returns existing insight)
- [ ] Verify no automatic triggers fire when new memories are created

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 3: Delete Old Insights System (Backend)

### Overview
Remove all code related to the old message-based insights system. This includes triggers, callables, domain logic, repositories, and data models.

### Changes Required

#### 1. Delete Old Insights Domain Files

**Delete these files**:
- `functions/src/domain/insights/insight-generator.ts`
- `functions/src/domain/insights/insight-aggregator.ts`
- `functions/src/domain/insights/ai-analyzer.ts`
- `functions/src/domain/insights/keyword-extractor.ts` (if exists)

```bash
cd functions/src/domain/insights
rm -f insight-generator.ts insight-aggregator.ts ai-analyzer.ts keyword-extractor.ts
```

Keep only:
- `category-classifier.ts` (new from Phase 1)
- `category-insight-generator.ts` (new from Phase 2)

#### 2. Delete Old Insights Data Layer

**Delete these files**:
- `functions/src/data/models/insight.ts`
- `functions/src/data/repositories/insight-repository.ts`

```bash
cd functions/src/data
rm -f models/insight.ts
rm -f repositories/insight-repository.ts
```

Keep `category-insight.ts` and `category-insight-repository.ts` (new files from Phase 2).

#### 3. Delete Old Insights Functions

**Delete these files**:
- `functions/src/functions/insights-triggers.ts`
- `functions/src/functions/insights-callable.ts`
- `functions/src/functions/scheduled-insights.ts`

```bash
cd functions/src/functions
rm -f insights-triggers.ts insights-callable.ts scheduled-insights.ts
```

Keep `category-insights-triggers.ts` and `category-insights-callable.ts` (new files from Phase 2).

#### 4. Remove Old Exports from Index

**File**: `functions/src/index.ts`

Remove these lines (approximately lines 20-25):

```typescript
// OLD - DELETE THESE LINES:
export { generateInsight } from './functions/insights-triggers';
export { generatePeriodInsight } from './functions/insights-callable';
export { generateDailyInsights } from './functions/scheduled-insights';
```

#### 5. Clean Up Repository Index

**File**: `functions/src/data/repositories/index.ts`

Remove old insight repository exports:

```typescript
// OLD - DELETE THESE LINES:
export { getInsightRepository, InsightRepository } from './insight-repository';
```

#### 6. Remove Old Insight Types from Constants

**File**: `functions/src/config/constants.ts`

Remove (lines 58-63):

```typescript
// OLD - DELETE THESE LINES:
// Insight Type
export enum InsightType {
  THREAD = 0,
  GLOBAL = 1,
  DAILY_GLOBAL = 2,
}
```

Also remove (lines 84-92):

```typescript
// OLD - DELETE THESE LINES:
// Insights Config
export const INSIGHTS_CONFIG = {
  threeDaysMs: 3 * 24 * 60 * 60 * 1000,
  oneDayMs: 24 * 60 * 60 * 1000,
  oneHourMs: 60 * 60 * 1000,
  analysisTemperature: 0.3,
  maxAnalysisTokens: 500,
  conversationHistoryLimit: 10,
};
```

#### 7. Remove Insights References from Tests

**File**: `functions/src/test/index.test.ts`

Remove any test cases related to old insights system.

### Success Criteria

#### Automated Verification:
- [ ] No import errors: `cd functions && npm run typecheck`
- [ ] No linting errors: `cd functions && npm run lint`
- [ ] Build succeeds: `cd functions && npm run build`
- [ ] No references to old files: `cd functions && grep -r "insight-generator" src/`
- [ ] No references to old files: `cd functions && grep -r "InsightType" src/`
- [ ] No references to old files: `cd functions && grep -r "generateInsight" src/`

#### Manual Verification:
- [ ] Deploy functions successfully: `npm run deploy:functions`
- [ ] Verify old functions are removed from Firebase Console (Functions section)
- [ ] Check that `generateInsight`, `generatePeriodInsight`, `generateDailyInsights` are gone
- [ ] Verify new function exists: `generateCategoryInsight` (only one function needed)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 4: Delete Old Insights System (Frontend)

### Overview
Remove all Flutter code related to the old insights system. This includes the entire `lib/features/insights` directory and any references to it.

### Changes Required

#### 1. Delete Old Insights Feature Directory

**Delete entire directory**:

```bash
cd lib/features
rm -rf insights/
```

This removes:
- All data sources (local & remote)
- All repositories
- All domain entities, use cases, value objects
- All presentation (screens, controllers, providers, widgets)
- All mocks

#### 2. Remove Insights from Navigation

**File**: Find your main navigation file (likely `lib/features/home/` or `lib/core/navigation/`)

Remove any routes or navigation items pointing to `InsightsScreen`.

Example (may vary based on your navigation structure):

```dart
// OLD - DELETE:
case '/insights':
  return MaterialPageRoute(builder: (_) => const InsightsScreen());

// OR in bottom nav:
BottomNavigationBarItem(
  icon: Icon(Icons.insights),
  label: 'Insights',
),
```

#### 3. Remove Provider References

**Search for provider imports**:

```bash
cd lib
grep -r "insight_providers" .
grep -r "insightControllerProvider" .
grep -r "insightRepositoryProvider" .
```

Remove any imports or usages found.

#### 4. Clean Up Dependencies (if any)

**File**: `pubspec.yaml`

Check if any packages were added specifically for the old insights system. If found, remove them and run:

```bash
flutter pub get
```

### Success Criteria

#### Automated Verification:
- [ ] No import errors: `flutter analyze`
- [ ] No linting errors: Verify no errors in IDE
- [ ] Build succeeds: `flutter build ios --release --no-codesign` (or Android)

#### Manual Verification:
- [ ] App launches without errors
- [ ] Navigation works (old insights route removed)
- [ ] No references to old insights in any screen
- [ ] Search codebase: `grep -r "insight" lib/` (only finds new code if any)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 5: Create New Category Insights UI (Flutter)

### Overview
Build the new Flutter UI for category-based insights. This includes new data models, providers, and the main 6-card grid screen.

### Changes Required

#### 1. Create Category Insights Feature Structure

**Create directories**:

```bash
mkdir -p lib/features/category_insights/data/{models,datasources,repositories}
mkdir -p lib/features/category_insights/domain/{entities,repositories,usecases}
mkdir -p lib/features/category_insights/presentation/{screens,widgets,providers,controllers}
```

#### 2. Create Domain Entities

**File**: `lib/features/category_insights/domain/entities/category_insight_entity.dart` (NEW)

```dart
import 'package:equatable/equatable.dart';

enum InsightCategory {
  mindsetWellbeing('mindset_wellbeing', 'Mindset & Emotional Well-being', '🧠'),
  productivityFocus('productivity_focus', 'Productivity & Focus', '⚡'),
  relationshipsConnection('relationships_connection', 'Relationships & Connection', '💝'),
  careerGrowth('career_growth', 'Career & Growth', '🚀'),
  healthLifestyle('health_lifestyle', 'Health & Lifestyle', '💪'),
  purposeValues('purpose_values', 'Purpose & Values', '🌟');

  const InsightCategory(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static InsightCategory fromString(String value) {
    return InsightCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InsightCategory.mindsetWellbeing,
    );
  }
}

class CategoryInsightEntity extends Equatable {
  const CategoryInsightEntity({
    required this.userId,
    required this.category,
    required this.summary,
    required this.keyPatterns,
    required this.strengths,
    required this.opportunities,
    required this.lastRefreshedAt,
    required this.memoryCount,
    required this.memoryIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final InsightCategory category;
  final String summary;
  final List<String> keyPatterns;
  final List<String> strengths;
  final List<String> opportunities;
  final DateTime lastRefreshedAt;
  final int memoryCount;
  final List<String> memoryIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => summary.isEmpty && keyPatterns.isEmpty && memoryCount == 0;

  bool canRefresh(Duration rateLimitDuration) {
    final now = DateTime.now();
    final timeSinceLastRefresh = now.difference(lastRefreshedAt);
    return timeSinceLastRefresh >= rateLimitDuration;
  }

  @override
  List<Object?> get props => [
        userId,
        category,
        summary,
        keyPatterns,
        strengths,
        opportunities,
        lastRefreshedAt,
        memoryCount,
      ];
}
```

#### 3. Create Data Models

**File**: `lib/features/category_insights/data/models/category_insight_model.dart` (NEW)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';

class CategoryInsightModel {
  CategoryInsightModel({
    required this.userId,
    required this.category,
    required this.summary,
    required this.keyPatterns,
    required this.strengths,
    required this.opportunities,
    required this.lastRefreshedAt,
    required this.memoryCount,
    required this.memoryIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryInsightModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryInsightModel(
      userId: data['userId'] as String,
      category: data['category'] as String,
      summary: data['summary'] as String? ?? '',
      keyPatterns: List<String>.from(data['keyPatterns'] as List? ?? []),
      strengths: List<String>.from(data['strengths'] as List? ?? []),
      opportunities: List<String>.from(data['opportunities'] as List? ?? []),
      lastRefreshedAt: (data['lastRefreshedAt'] as int?) ?? 0,
      memoryCount: (data['memoryCount'] as int?) ?? 0,
      memoryIds: List<String>.from(data['memoryIds'] as List? ?? []),
      createdAt: (data['createdAt'] as int?) ?? 0,
      updatedAt: (data['updatedAt'] as int?) ?? 0,
    );
  }

  final String userId;
  final String category;
  final String summary;
  final List<String> keyPatterns;
  final List<String> strengths;
  final List<String> opportunities;
  final int lastRefreshedAt;
  final int memoryCount;
  final List<String> memoryIds;
  final int createdAt;
  final int updatedAt;

  CategoryInsightEntity toEntity() {
    return CategoryInsightEntity(
      userId: userId,
      category: InsightCategory.fromString(category),
      summary: summary,
      keyPatterns: keyPatterns,
      strengths: strengths,
      opportunities: opportunities,
      lastRefreshedAt: DateTime.fromMillisecondsSinceEpoch(lastRefreshedAt),
      memoryCount: memoryCount,
      memoryIds: memoryIds,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}
```

#### 4. Create Remote Data Source

**File**: `lib/features/category_insights/data/datasources/category_insight_remote_datasource.dart` (NEW)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kairos/features/category_insights/data/models/category_insight_model.dart';

abstract class CategoryInsightRemoteDataSource {
  Stream<List<CategoryInsightModel>> watchAllInsights(String userId);
  Future<void> generateInsight(String category, {bool forceRefresh});
}

class CategoryInsightRemoteDataSourceImpl implements CategoryInsightRemoteDataSource {
  CategoryInsightRemoteDataSourceImpl(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<CategoryInsightModel>> watchAllInsights(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('kairos_insights')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryInsightModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> generateInsight(String category, {bool forceRefresh = true}) async {
    final callable = _functions.httpsCallable('generateCategoryInsight');
    await callable.call({
      'category': category,
      'forceRefresh': forceRefresh,
    });
  }
}
```

#### 5. Create Repository Implementation

**File**: `lib/features/category_insights/data/repositories/category_insight_repository_impl.dart` (NEW)

```dart
import 'package:kairos/features/category_insights/data/datasources/category_insight_remote_datasource.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/domain/repositories/category_insight_repository.dart';

class CategoryInsightRepositoryImpl implements CategoryInsightRepository {
  CategoryInsightRepositoryImpl({required this.remoteDataSource});

  final CategoryInsightRemoteDataSource remoteDataSource;

  @override
  Stream<List<CategoryInsightEntity>> watchAllInsights(String userId) {
    return remoteDataSource
        .watchAllInsights(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> generateInsight(String category, {bool forceRefresh = true}) async {
    await remoteDataSource.generateInsight(category, forceRefresh: forceRefresh);
  }
}
```

#### 6. Create Domain Repository Interface

**File**: `lib/features/category_insights/domain/repositories/category_insight_repository.dart` (NEW)

```dart
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';

abstract class CategoryInsightRepository {
  Stream<List<CategoryInsightEntity>> watchAllInsights(String userId);
  Future<void> generateInsight(String category, {bool forceRefresh});
}
```

#### 7. Create Providers

**File**: `lib/features/category_insights/presentation/providers/category_insight_providers.dart` (NEW)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/category_insights/data/datasources/category_insight_remote_datasource.dart';
import 'package:kairos/features/category_insights/data/repositories/category_insight_repository_impl.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/domain/repositories/category_insight_repository.dart';

// Data source provider
final categoryInsightRemoteDataSourceProvider =
    Provider<CategoryInsightRemoteDataSource>((ref) {
  return CategoryInsightRemoteDataSourceImpl(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
});

// Repository provider
final categoryInsightRepositoryProvider =
    Provider<CategoryInsightRepository>((ref) {
  final remoteDataSource = ref.watch(categoryInsightRemoteDataSourceProvider);
  return CategoryInsightRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Stream provider for all category insights
final allCategoryInsightsProvider =
    StreamProvider<List<CategoryInsightEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(categoryInsightRepositoryProvider);
  return repository.watchAllInsights(userId);
});

// Provider for a specific category insight
final categoryInsightProvider = StreamProvider.family<
    CategoryInsightEntity?,
    InsightCategory>((ref, category) {
  final allInsightsAsync = ref.watch(allCategoryInsightsProvider);

  return allInsightsAsync.when(
    data: (insights) {
      try {
        final insight = insights.firstWhere((i) => i.category == category);
        return Stream.value(insight);
      } catch (_) {
        return Stream.value(null);
      }
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
```

#### 8. Create Main Insights Screen (6 Cards)

**File**: `lib/features/category_insights/presentation/screens/category_insights_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/presentation/providers/category_insight_providers.dart';
import 'package:kairos/features/category_insights/presentation/screens/category_insight_detail_screen.dart';

class CategoryInsightsScreen extends ConsumerWidget {
  const CategoryInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insightsAsync = ref.watch(allCategoryInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error loading insights',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (insights) {
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.9,
            ),
            itemCount: InsightCategory.values.length,
            itemBuilder: (context, index) {
              final category = InsightCategory.values[index];
              final insight = insights
                  .where((i) => i.category == category)
                  .firstOrNull;

              return _CategoryCard(
                category: category,
                insight: insight,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryInsightDetailScreen(
                        category: category,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.insight,
    required this.onTap,
  });

  final InsightCategory category;
  final CategoryInsightEntity? insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = insight == null || insight!.isEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Text(
                category.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category name
              Text(
                category.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Summary preview or empty state
              Expanded(
                child: isEmpty
                    ? Text(
                        'No insights yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Text(
                        insight!.summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),

              // Memory count
              if (!isEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${insight!.memoryCount} memories',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] No import errors: `flutter analyze`
- [ ] No linting errors in IDE
- [ ] Build succeeds: `flutter build ios --no-codesign` or `flutter build apk`

#### Manual Verification:
- [ ] App launches and displays insights screen
- [ ] 6 cards are visible in 2x3 grid
- [ ] Each card shows category icon, name, and preview
- [ ] Empty state shows "No insights yet" for categories without data
- [ ] Cards with insights show memory count
- [ ] Tapping a card navigates to detail screen (will implement in Phase 6)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 6: Create Insight Detail Screen with Refresh

### Overview
Create the detail screen that shows full insight content with a "Refresh" button. Includes rate limiting logic in the UI.

### Changes Required

#### 1. Create Detail Screen

**File**: `lib/features/category_insights/presentation/screens/category_insight_detail_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/theme/app_spacing.dart';
import 'package:kairos/features/category_insights/domain/entities/category_insight_entity.dart';
import 'package:kairos/features/category_insights/presentation/providers/category_insight_providers.dart';

class CategoryInsightDetailScreen extends ConsumerStatefulWidget {
  const CategoryInsightDetailScreen({
    super.key,
    required this.category,
  });

  final InsightCategory category;

  @override
  ConsumerState<CategoryInsightDetailScreen> createState() =>
      _CategoryInsightDetailScreenState();
}

class _CategoryInsightDetailScreenState
    extends ConsumerState<CategoryInsightDetailScreen> {
  bool _isRefreshing = false;

  Future<void> _generateOrRefreshInsight({bool forceRefresh = true}) async {
    setState(() => _isRefreshing = true);

    try {
      final repository = ref.read(categoryInsightRepositoryProvider);
      await repository.generateInsight(
        widget.category.value,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insight generated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate insight: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightAsync = ref.watch(categoryInsightProvider(widget.category));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.displayName),
      ),
      body: insightAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (insight) {
          final isEmpty = insight == null || insight.isEmpty;
          final canRefresh = isEmpty ? true : insight.canRefresh(const Duration(hours: 1));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon and title
                Row(
                  children: [
                    Text(
                      widget.category.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.displayName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isEmpty)
                            Text(
                              '${insight.memoryCount} memories',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Generate/Refresh button
                if (isEmpty)
                  // First time: Show "Generate Insights" button
                  Column(
                    children: [
                      Text(
                        _getCategoryDescription(widget.category),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isRefreshing
                              ? null
                              : () => _generateOrRefreshInsight(forceRefresh: true),
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(_isRefreshing
                              ? 'Generating...'
                              : 'Generate Insights'),
                        ),
                      ),
                    ],
                  )
                else ...[
                  // After first generation: Show "Refresh" button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isRefreshing || !canRefresh
                          ? null
                          : () => _generateOrRefreshInsight(forceRefresh: true),
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isRefreshing
                          ? 'Refreshing...'
                          : canRefresh
                              ? 'Refresh Insight'
                              : 'Available in ${_getTimeUntilRefresh(insight!)}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Summary
                  _buildSection(
                  theme,
                  'Summary',
                  Icons.insights,
                  Text(
                    insight.summary,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                  const SizedBox(height: AppSpacing.xl),

                  // Key Patterns
                  if (insight!.keyPatterns.isNotEmpty) ...[
                  _buildSection(
                    theme,
                    'Key Patterns',
                    Icons.pattern,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: insight.keyPatterns
                          .map((pattern) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ',
                                        style: theme.textTheme.bodyMedium),
                                    Expanded(
                                      child: Text(
                                        pattern,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                  // Strengths
                  if (insight!.strengths.isNotEmpty) ...[
                    _buildSection(
                      theme,
                      'Strengths',
                      Icons.star,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: insight.strengths
                          .map((strength) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('✓ ',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                        )),
                                    Expanded(
                                      child: Text(
                                        strength,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                  // Opportunities
                  if (insight!.opportunities.isNotEmpty) ...[
                    _buildSection(
                      theme,
                      'Opportunities for Growth',
                      Icons.trending_up,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: insight.opportunities
                          .map((opportunity) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('→ ',
                                        style: theme.textTheme.bodyMedium),
                                    Expanded(
                                      child: Text(
                                        opportunity,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],

                  // Last updated
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      'Last updated: ${_formatDate(insight!.lastRefreshedAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        content,
      ],
    );
  }

  String _getCategoryDescription(InsightCategory category) {
    return switch (category) {
      InsightCategory.mindsetWellbeing =>
        'Kairos will generate insights here once you talk about your emotions, stress, or mental well-being.',
      InsightCategory.productivityFocus =>
        'Kairos will generate insights here once you talk about your work, focus, or productivity.',
      InsightCategory.relationshipsConnection =>
        'Kairos will generate insights here once you talk about your relationships and connections.',
      InsightCategory.careerGrowth =>
        'Kairos will generate insights here once you talk about your career, goals, or professional growth.',
      InsightCategory.healthLifestyle =>
        'Kairos will generate insights here once you talk about your health, habits, or lifestyle.',
      InsightCategory.purposeValues =>
        'Kairos will generate insights here once you talk about your values, purpose, or life vision.',
    };
  }

  String _getTimeUntilRefresh(CategoryInsightEntity insight) {
    final now = DateTime.now();
    final nextRefreshTime =
        insight.lastRefreshedAt.add(const Duration(hours: 1));
    final difference = nextRefreshTime.difference(now);

    if (difference.inMinutes < 1) {
      return 'less than a minute';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else {
      return '1 hour';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] No import errors: `flutter analyze`
- [ ] No linting errors in IDE
- [ ] Build succeeds: `flutter build ios --no-codesign` or `flutter build apk`

#### Manual Verification:
- [ ] Tap a category card from main screen (without insights)
- [ ] Detail screen shows category description and "Generate Insights" button
- [ ] Click "Generate Insights" → function is called and insight is created
- [ ] After generation completes, screen shows full insight content
- [ ] Summary, key patterns, strengths, and opportunities are displayed
- [ ] Button now shows "Refresh Insight" instead of "Generate"
- [ ] Click refresh button → insight regenerates
- [ ] After refresh, button is disabled for 1 hour (shows countdown)
- [ ] Last updated timestamp displays correctly
- [ ] Navigation back to main screen works
- [ ] Card on main screen now shows insight preview

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to deployment.

---

## Testing Strategy

### Unit Tests

**Backend**:
1. Category classifier (classify various fact types)
2. Category insight generator (memory fetching, LLM prompt, JSON parsing)
3. Repository methods (CRUD operations)

**Frontend**:
1. Entity methods (isEmpty, canRefresh)
2. Model conversions (toEntity, fromFirestore)

### Integration Tests

**Backend**:
1. Full memory ingestion → classification → indexing flow
2. Manual generation callable function (no automatic triggers)
3. Rate limiting enforcement in generation logic

**Frontend**:
1. Stream provider updates when insights are generated
2. Generate/Refresh button triggers backend call
3. Navigation between screens
4. Button state changes based on insight existence (Generate vs Refresh)

### Manual Testing Steps

1. **Create memories with classification**:
   - Journal about different topics
   - Verify memories get correct categories in Firestore
   - Check Cloud Functions logs for classification output

2. **Verify insight generation**:
   - Check Firestore `users/{userId}/kairos_insights/` for 6 documents
   - Verify each insight has summary, patterns, strengths, opportunities
   - Test with 0 memories (empty state), 5 memories, 50+ memories

3. **Test UI flow**:
   - Open insights screen → see 6 cards (all show "No insights yet")
   - Tap card without insight → see "Generate Insights" button
   - Click "Generate Insights" → verify generation
   - After generation, button changes to "Refresh"
   - Click refresh → verify regeneration
   - Try refreshing again immediately → verify rate limit (button disabled)

4. **Test edge cases**:
   - User with no memories → can't generate insights (memoryCount = 0)
   - User with memories in only 1 category → only that category can generate insights
   - Memory with 0 categories → no impact on insights (requires manual generation)
   - Memory with 2 categories → both categories have memories available for generation

## Performance Considerations

1. **Category Classification**:
   - Uses `gemini-2.0-flash` (fast, cheap)
   - Classifies sequentially to avoid rate limits
   - Accepts failure gracefully (memory saved without categories)

2. **Insight Generation**:
   - Limits to top 50 memories per category
   - Uses `gemini-1.5-flash` (good balance of speed/quality)
   - Rate limited to 1 refresh per hour

3. **Frontend**:
   - Uses Riverpod streams for real-time updates
   - Caches insights client-side via StreamProvider
   - Grid view with efficient card rendering

4. **Firestore Queries**:
   - Indexed query on `userId` + `categories` + `createdAt`
   - Subcollection structure prevents large document reads
   - Streams automatically manage subscriptions

## Migration Notes

**No migration needed** - this is a green-field implementation. Old insights are deleted, not migrated.

Users will start with empty insights that populate as they journal going forward.

## References

- New category constants: `functions/src/config/constants.ts` (Phase 1)
- Memory classification: `functions/src/domain/insights/category-classifier.ts` (Phase 1)
- Insight generation: `functions/src/domain/insights/category-insight-generator.ts` (Phase 2)
- Flutter entities: `lib/features/category_insights/domain/entities/category_insight_entity.dart` (Phase 5)
- Main UI: `lib/features/category_insights/presentation/screens/category_insights_screen.dart` (Phase 5)
- Detail screen: `lib/features/category_insights/presentation/screens/category_insight_detail_screen.dart` (Phase 6)


