export interface Message {
  id: string;
  threadId: string;
  userId: string;
  role: number; // MessageRole enum
  messageType: number; // MessageType enum
  content?: string;
  transcription?: string;
  storageUrl?: string;
  createdAtMillis: number;
  updatedAtMillis: number;
  status: number; // MessageStatus enum: 0=localCreated, 1=uploadingMedia, 2=aiProcessing, 3=completed, 4=failed
  failureReason?: number;
  uploadProgress?: number;
  uploadError?: string;
  aiError?: string;
  attemptCount?: number;
  lastAttemptMillis?: number;
  isDeleted: boolean;
  version: number;
  // Deprecated - kept for backward compatibility
  aiProcessingStatus?: number;
  uploadStatus?: number;
}

export interface CreateMessageInput {
  threadId: string;
  userId: string;
  role: number;
  messageType: number;
  content?: string;
  transcription?: string;
  storageUrl?: string;
  status?: number;
  failureReason?: number;
  uploadError?: string;
  aiError?: string;
}

export interface UpdateMessageInput {
  content?: string;
  transcription?: string;
  storageUrl?: string;
  status?: number;
  failureReason?: number;
  uploadError?: string;
  aiError?: string;
  updatedAtMillis?: number;
}

export interface ConversationMessage {
  role: string; // 'user' | 'ai' | 'system'
  content: string;
  createdAtMillis: number;
}

