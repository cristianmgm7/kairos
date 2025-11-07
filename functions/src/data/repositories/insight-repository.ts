import * as admin from 'firebase-admin';
import { Insight, CreateInsightInput, UpdateInsightInput } from '../models/insight';

export class InsightRepository {
  private collection: admin.firestore.CollectionReference;

  constructor(db: admin.firestore.Firestore) {
    this.collection = db.collection('insights');
  }

  /**
   * Create a new insight
   */
  async create(input: CreateInsightInput): Promise<Insight> {
    const now = Date.now();
    const insight: Insight = {
      ...input,
      createdAtMillis: now,
      updatedAtMillis: now,
      isDeleted: false,
      version: 1,
    };

    await this.collection.doc(input.id).set(insight);
    return insight;
  }

  /**
   * Update an existing insight
   */
  async update(insightId: string, input: UpdateInsightInput): Promise<void> {
    await this.collection.doc(insightId).update({
      ...input,
      updatedAtMillis: input.updatedAtMillis ?? Date.now(),
    });
  }

  /**
   * Find recent insight for a thread
   */
  async findRecentThreadInsight(
    userId: string,
    threadId: string,
    afterMillis: number
  ): Promise<Insight | null> {
    const snapshot = await this.collection
      .where('userId', '==', userId)
      .where('threadId', '==', threadId)
      .where('periodEndMillis', '>=', afterMillis)
      .limit(1)
      .get();

    if (snapshot.empty) return null;
    return snapshot.docs[0].data() as Insight;
  }

  /**
   * Find recent global insight
   */
  async findRecentGlobalInsight(
    userId: string,
    afterMillis: number
  ): Promise<Insight | null> {
    const snapshot = await this.collection
      .where('userId', '==', userId)
      .where('threadId', '==', null)
      .where('periodEndMillis', '>=', afterMillis)
      .limit(1)
      .get();

    if (snapshot.empty) return null;
    return snapshot.docs[0].data() as Insight;
  }

  /**
   * Check if insight was recently updated (for debouncing)
   */
  async wasRecentlyUpdated(
    userId: string,
    threadId: string,
    afterMillis: number
  ): Promise<boolean> {
    const snapshot = await this.collection
      .where('userId', '==', userId)
      .where('threadId', '==', threadId)
      .where('updatedAtMillis', '>=', afterMillis)
      .limit(1)
      .get();

    return !snapshot.empty;
  }

  /**
   * Get all thread insights in a time range
   */
  async getThreadInsights(
    userId: string,
    afterMillis: number
  ): Promise<Insight[]> {
    const snapshot = await this.collection
      .where('userId', '==', userId)
      .where('threadId', '!=', null)
      .where('periodEndMillis', '>=', afterMillis)
      .get();

    return snapshot.docs.map(doc => doc.data() as Insight);
  }
}

