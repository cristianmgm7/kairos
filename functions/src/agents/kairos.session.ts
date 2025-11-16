import admin from 'firebase-admin';
import { AI_CONFIG } from '../config/constants';

export interface SessionMessage {
  role: 'user' | 'ai' | 'system';
  content: string;
  timestamp: number;
}

export interface SessionConfig {
  threadId: string;
  userId: string;
  historyLimit?: number;
}

/**
 * Session management for Kairos agent
 *
 * A session = one conversation thread
 * Maintains ephemeral history during function execution
 * No persistence - rebuilt from Firestore on each call
 */
export class KairosSession {
  private threadId: string;
  private userId: string;
  private historyLimit: number;
  private history: SessionMessage[] = [];
  private db: admin.firestore.Firestore;

  constructor(config: SessionConfig, db?: admin.firestore.Firestore) {
    this.threadId = config.threadId;
    this.userId = config.userId;
    this.historyLimit = config.historyLimit || AI_CONFIG.conversationHistoryLimit;
    this.db = db || admin.firestore();
  }

  /**
   * Load conversation history from Firestore
   */
  async loadHistory(excludeMessageId?: string): Promise<void> {
    const snapshot = await this.db.collection('journalMessages')
      .where('threadId', '==', this.threadId)
      .where('userId', '==', this.userId)
      .where('isDeleted', '==', false)
      .orderBy('createdAtMillis', 'asc')
      .limit(this.historyLimit)
      .get();

    const roleMap = ['user', 'ai', 'system'] as const;

    this.history = snapshot.docs
      .filter(doc => doc.id !== excludeMessageId)
      .map(doc => {
        const data = doc.data();
        return {
          role: roleMap[data.role],
          content: data.content || data.transcription || '[media content]',
          timestamp: data.createdAtMillis,
        };
      });
  }

  /**
   * Add a user message to ephemeral history
   */
  addUserMessage(content: string): void {
    this.history.push({
      role: 'user',
      content,
      timestamp: Date.now(),
    });
  }

  /**
   * Add an assistant message to ephemeral history
   */
  addAssistantMessage(content: string): void {
    this.history.push({
      role: 'ai',
      content,
      timestamp: Date.now(),
    });
  }

  /**
   * Add a system message to ephemeral history
   */
  addSystemMessage(content: string): void {
    this.history.push({
      role: 'system',
      content,
      timestamp: Date.now(),
    });
  }

  /**
   * Get conversation history
   */
  getHistory(): SessionMessage[] {
    return [...this.history]; // Return copy to prevent external mutation
  }

  /**
   * Get history formatted for Genkit
   * Returns array of {role, content} objects
   */
  getFormattedHistory(): Array<{ role: string; content: string }> {
    return this.history.map(msg => ({
      role: msg.role === 'ai' ? 'model' : msg.role, // Genkit uses 'model' for assistant
      content: msg.content,
    }));
  }

  /**
   * Get history as context string (legacy format)
   */
  getHistoryAsString(): string {
    return this.history
      .map(msg => `${msg.role}: ${msg.content}`)
      .join('\n');
  }

  /**
   * Clear ephemeral history (useful for testing)
   */
  clearHistory(): void {
    this.history = [];
  }

  /**
   * Get session metadata
   */
  getMetadata() {
    return {
      threadId: this.threadId,
      userId: this.userId,
      messageCount: this.history.length,
      historyLimit: this.historyLimit,
    };
  }
}

/**
 * Factory function for creating sessions
 */
export function createSession(config: SessionConfig): KairosSession {
  return new KairosSession(config);
}
