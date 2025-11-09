import * as admin from 'firebase-admin';
import {
  Message,
  CreateMessageInput,
  UpdateMessageInput,
  ConversationMessage,
} from '../models/message';

export class MessageRepository {
  private collection: admin.firestore.CollectionReference;

  constructor(db: admin.firestore.Firestore) {
    this.collection = db.collection('journalMessages');
  }

  /**
   * Get a message by ID
   */
  async getById(messageId: string): Promise<Message | null> {
    const doc = await this.collection.doc(messageId).get();
    if (!doc.exists) return null;
    return doc.data() as Message;
  }

  /**
   * Create a new message
   */
  async create(input: CreateMessageInput): Promise<Message> {
    const ref = this.collection.doc();
    const now = Date.now();

    const message: Message = {
      id: ref.id,
      ...input,
      createdAtMillis: now,
      updatedAtMillis: now,
      isDeleted: false,
      version: 1,
      aiProcessingStatus: input.aiProcessingStatus ?? 0,
      uploadStatus: input.uploadStatus ?? 2,
    };

    await ref.set(message);
    return message;
  }

  /**
   * Update a message
   */
  async update(messageId: string, input: UpdateMessageInput): Promise<void> {
    await this.collection.doc(messageId).update({
      ...input,
      updatedAtMillis: input.updatedAtMillis ?? Date.now(),
    });
  }

  /**
   * Get conversation history for a thread
   */
  async getConversationHistory(
    threadId: string,
    userId: string,
    limit: number,
    excludeMessageId?: string
  ): Promise<ConversationMessage[]> {
    const snapshot = await this.collection
      .where('threadId', '==', threadId)
      .where('userId', '==', userId)
      .where('isDeleted', '==', false)
      .orderBy('createdAtMillis', 'asc')
      .limit(limit)
      .get();

    const roleMap = ['user', 'ai', 'system'];

    return snapshot.docs
      .filter(doc => doc.id !== excludeMessageId)
      .map(doc => {
        const data = doc.data();
        return {
          role: roleMap[data.role],
          content: data.content || data.transcription || '[media content]',
          createdAtMillis: data.createdAtMillis,
        };
      });
  }

  /**
   * Get messages for a thread in a time range
   */
  async getMessagesInRange(
    threadId: string,
    userId: string,
    startMillis: number,
    endMillis?: number
  ): Promise<Array<{ content: string; role: number; createdAtMillis: number }>> {
    let query = this.collection
      .where('threadId', '==', threadId)
      .where('userId', '==', userId)
      .where('isDeleted', '==', false)
      .where('createdAtMillis', '>=', startMillis)
      .orderBy('createdAtMillis', 'asc');

    const snapshot = await query.get();

    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        content: data.content || data.transcription || '',
        role: data.role,
        createdAtMillis: data.createdAtMillis,
      };
    });
  }

  /**
   * Count messages in a thread
   */
  async countMessagesInThread(threadId: string, userId: string): Promise<number> {
    const result = await this.collection
      .where('threadId', '==', threadId)
      .where('userId', '==', userId)
      .where('isDeleted', '==', false)
      .count()
      .get();

    return result.data().count;
  }
}

