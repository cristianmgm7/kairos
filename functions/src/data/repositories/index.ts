import * as admin from 'firebase-admin';
import { MessageRepository } from './message-repository';
import { ThreadRepository } from './thread-repository';

// Singleton instances
let messageRepo: MessageRepository | null = null;
let threadRepo: ThreadRepository | null = null;

export function getMessageRepository(db: admin.firestore.Firestore): MessageRepository {
  if (!messageRepo) {
    messageRepo = new MessageRepository(db);
  }
  return messageRepo;
}

export function getThreadRepository(db: admin.firestore.Firestore): ThreadRepository {
  if (!threadRepo) {
    threadRepo = new ThreadRepository(db);
  }
  return threadRepo;
}

// Export repository classes
export { MessageRepository, ThreadRepository };

