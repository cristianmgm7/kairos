import { getMessageRepository } from '../../data/repositories';
import { ConversationMessage } from '../../data/models/message';
import { AI_CONFIG } from '../../config/constants';
import * as admin from 'firebase-admin';

export class ConversationBuilder {
  private messageRepo: ReturnType<typeof getMessageRepository>;

  constructor(db: admin.firestore.Firestore) {
    this.messageRepo = getMessageRepository(db);
  }

  /**
   * Load conversation history for a thread
   * Standardized version - removes inconsistencies between old implementations
   */
  async loadHistory(
    threadId: string,
    userId: string,
    excludeMessageId?: string,
    limit: number = AI_CONFIG.conversationHistoryLimit
  ): Promise<ConversationMessage[]> {
    return this.messageRepo.getConversationHistory(
      threadId,
      userId,
      limit,
      excludeMessageId
    );
  }

  /**
   * Build conversation context string from history
   */
  buildContextString(history: ConversationMessage[]): string {
    return history.map(msg => `${msg.role}: ${msg.content}`).join('\n');
  }

  /**
   * Build full conversation history with context string
   */
  async buildConversationContext(
    threadId: string,
    userId: string,
    excludeMessageId?: string
  ): Promise<string> {
    const history = await this.loadHistory(threadId, userId, excludeMessageId);
    return this.buildContextString(history);
  }
}

// Factory function
export function createConversationBuilder(
  db: admin.firestore.Firestore
): ConversationBuilder {
  return new ConversationBuilder(db);
}

