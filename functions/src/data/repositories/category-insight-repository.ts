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

