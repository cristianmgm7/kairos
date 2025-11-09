import * as admin from 'firebase-admin';
import { Thread, UpdateThreadInput } from '../models/thread';

export class ThreadRepository {
  private collection: admin.firestore.CollectionReference;

  constructor(db: admin.firestore.Firestore) {
    this.collection = db.collection('journalThreads');
  }

  /**
   * Get a thread by ID
   */
  async getById(threadId: string): Promise<Thread | null> {
    const doc = await this.collection.doc(threadId).get();
    if (!doc.exists) return null;
    return doc.data() as Thread;
  }

  /**
   * Update thread metadata
   */
  async update(threadId: string, input: UpdateThreadInput): Promise<void> {
    await this.collection.doc(threadId).update({
      ...input,
      updatedAtMillis: input.updatedAtMillis ?? Date.now(),
    });
  }

  /**
   * Update thread with recalculated message count
   */
  async updateWithMessageCount(
    threadId: string,
    messageCount: number,
    lastMessageAt: number
  ): Promise<void> {
    const now = Date.now();
    await this.collection.doc(threadId).update({
      messageCount,
      lastMessageAt,
      updatedAtMillis: now,
    });
  }
}

