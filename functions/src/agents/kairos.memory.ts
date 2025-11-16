import admin from 'firebase-admin';

/**
 * Memory document structure in Firestore
 */
export interface MemoryDocument {
  userId: string;
  threadId?: string;
  content: string;
  metadata: {
    source: 'insight' | 'user_confirmed' | 'auto_extracted';
    insightId?: string;
    messageId?: string;
    createdAt: number;
    tags?: string[];
  };
}

/**
 * Memory service for managing long-term memories
 *
 * Note: Genkit doesn't currently have a built-in defineMemory API.
 * This service provides custom memory management using Firestore.
 * Memories are stored with semantic content that can be queried later.
 */
export class MemoryService {
  private db: admin.firestore.Firestore;

  constructor(db?: admin.firestore.Firestore) {
    this.db = db || admin.firestore();
  }

  /**
   * Store an insight as memory
   */
  async storeInsightMemory(
    userId: string,
    insightId: string,
    insightSummary: string,
    threadId?: string,
    tags?: string[]
  ): Promise<void> {
    const memoryDoc: MemoryDocument = {
      userId,
      threadId,
      content: insightSummary,
      metadata: {
        source: 'insight',
        insightId,
        createdAt: Date.now(),
        tags,
      },
    };

    await this.db.collection('kairos_memories').add(memoryDoc);
  }

  /**
   * Store a user-confirmed important moment as memory
   */
  async storeUserConfirmedMemory(
    userId: string,
    content: string,
    messageId: string,
    threadId: string,
    tags?: string[]
  ): Promise<void> {
    const memoryDoc: MemoryDocument = {
      userId,
      threadId,
      content,
      metadata: {
        source: 'user_confirmed',
        messageId,
        createdAt: Date.now(),
        tags,
      },
    };

    await this.db.collection('kairos_memories').add(memoryDoc);
  }

  /**
   * Retrieve memories for a user
   *
   * Returns recent memories ordered by creation time.
   * Future enhancement: Add semantic search using embeddings.
   */
  async getRecentMemories(
    userId: string,
    limit: number = 15,
    threadId?: string
  ): Promise<MemoryDocument[]> {
    let query = this.db.collection('kairos_memories')
      .where('userId', '==', userId)
      .orderBy('metadata.createdAt', 'desc')
      .limit(limit);

    if (threadId) {
      query = query.where('threadId', '==', threadId) as admin.firestore.Query;
    }

    const snapshot = await query.get();
    return snapshot.docs.map(doc => ({
      ...doc.data() as MemoryDocument,
    }));
  }

  /**
   * Delete memories for a thread (when thread is deleted)
   */
  async deleteThreadMemories(threadId: string): Promise<void> {
    const snapshot = await this.db.collection('kairos_memories')
      .where('threadId', '==', threadId)
      .get();

    const batch = this.db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
  }

  /**
   * Get memory statistics for a user
   */
  async getMemoryStats(userId: string): Promise<{
    totalMemories: number;
    insightMemories: number;
    userConfirmedMemories: number;
  }> {
    const snapshot = await this.db.collection('kairos_memories')
      .where('userId', '==', userId)
      .get();

    const stats = {
      totalMemories: snapshot.size,
      insightMemories: 0,
      userConfirmedMemories: 0,
    };

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.metadata?.source === 'insight') {
        stats.insightMemories++;
      } else if (data.metadata?.source === 'user_confirmed') {
        stats.userConfirmedMemories++;
      }
    });

    return stats;
  }
}

/**
 * Factory function for creating memory service
 */
export function createMemoryService(): MemoryService {
  return new MemoryService();
}
