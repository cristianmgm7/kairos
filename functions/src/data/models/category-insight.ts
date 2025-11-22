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

