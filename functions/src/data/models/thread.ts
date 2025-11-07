export interface Thread {
  id: string;
  userId: string;
  title?: string;
  messageCount: number;
  lastMessageAt: number;
  createdAtMillis: number;
  updatedAtMillis: number;
  isDeleted: boolean;
  version: number;
}

export interface UpdateThreadInput {
  messageCount?: number;
  lastMessageAt?: number;
  updatedAtMillis?: number;
}

