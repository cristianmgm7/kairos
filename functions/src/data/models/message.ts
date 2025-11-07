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
  updatedAtMillis?: number;
  aiProcessingStatus: number; // AiProcessingStatus enum
  uploadStatus?: number; // UploadStatus enum
  isDeleted: boolean;
  version: number;
}

export interface CreateMessageInput {
  threadId: string;
  userId: string;
  role: number;
  messageType: number;
  content?: string;
  transcription?: string;
  storageUrl?: string;
  aiProcessingStatus?: number;
  uploadStatus?: number;
}

export interface UpdateMessageInput {
  content?: string;
  transcription?: string;
  storageUrl?: string;
  aiProcessingStatus?: number;
  uploadStatus?: number;
  updatedAtMillis?: number;
}

export interface ConversationMessage {
  role: string; // 'user' | 'ai' | 'system'
  content: string;
  createdAtMillis: number;
}

