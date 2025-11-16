export interface Insight {
  id: string;
  userId: string;
  type: number; // InsightType enum: 0=thread, 1=global, 2=dailyGlobal
  threadId: string | null;
  period?: string; // Period enum as string (oneDay, threeDays, oneWeek, oneMonth, daily)
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
  period?: string;
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

