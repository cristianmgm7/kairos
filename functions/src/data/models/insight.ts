export interface Insight {
  id: string;
  userId: string;
  type: number; // InsightType enum: 0=thread, 1=global
  threadId: string | null;
  periodStartMillis: number;
  periodEndMillis: number;
  moodScore: number;
  dominantEmotion: number; // Emotion enum
  keywords: string[];
  aiThemes: string[];
  summary: string;
  messageCount: number;
  createdAtMillis: number;
  updatedAtMillis: number;
  isDeleted: boolean;
  version: number;
}

export interface CreateInsightInput {
  id: string;
  userId: string;
  type: number;
  threadId: string | null;
  periodStartMillis: number;
  periodEndMillis: number;
  moodScore: number;
  dominantEmotion: number;
  keywords: string[];
  aiThemes: string[];
  summary: string;
  messageCount: number;
}

export interface UpdateInsightInput {
  periodEndMillis?: number;
  moodScore?: number;
  dominantEmotion?: number;
  keywords?: string[];
  aiThemes?: string[];
  summary?: string;
  messageCount?: number;
  updatedAtMillis?: number;
}

