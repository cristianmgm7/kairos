// System prompts
export const SYSTEM_PROMPT = `You are Kairos, an empathetic AI companion in a personal journaling app.

Your role is to help users reflect on their thoughts and feelings with warmth and understanding.

IMPORTANT: You have access to tools that provide you with information about the user. Use these tools proactively:
- When greeting a user or starting a conversation, use getUserProfile to learn about them and personalize your response
- When the user asks about dates or time, use getDate
- When referencing past conversations, use getConversationTopicSummary
- Use getUserConfig to understand their preferences

Always use the user's name (from getUserProfile) when you know it to create a more personal connection.

Keep responses concise (2-3 sentences) unless the user asks for more detail.`;

// Message roles
export enum MessageRole {
  USER = 0,
  AI = 1,
  SYSTEM = 2,
}

// Message types
export enum MessageType {
  TEXT = 0,
  IMAGE = 1,
  AUDIO = 2,
}

// Message Status (unified status for messages)
// Must match Flutter's MessageStatus enum exactly
export enum MessageStatus {
  LOCAL_CREATED = 0,
  UPLOADING_MEDIA = 1,
  MEDIA_UPLOADED = 2,
  PROCESSING_AI = 3,
  PROCESSED = 4,
  REMOTE_CREATED = 5,
  FAILED = 6,
}

// AI Processing Status (deprecated - use MessageStatus instead)
export enum AiProcessingStatus {
  PENDING = 0,
  PROCESSING = 1,
  COMPLETED = 2,
  FAILED = 3,
}

// Upload Status (deprecated - use MessageStatus instead)
export enum UploadStatus {
  PENDING = 0,
  UPLOADING = 1,
  COMPLETED = 2,
  FAILED = 3,
}

// Insight Type
export enum InsightType {
  THREAD = 0,
  GLOBAL = 1,
  DAILY_GLOBAL = 2,
}

// Emotion enum
export enum Emotion {
  JOY = 0,
  CALM = 1,
  NEUTRAL = 2,
  SADNESS = 3,
  STRESS = 4,
  ANGER = 5,
  FEAR = 6,
  EXCITEMENT = 7,
}

// AI Config
export const AI_CONFIG = {
  temperature: 0.7,
  maxOutputTokens: 500,
  conversationHistoryLimit: 20,
};

// Insights Config
export const INSIGHTS_CONFIG = {
  threeDaysMs: 3 * 24 * 60 * 60 * 1000,
  oneDayMs: 24 * 60 * 60 * 1000,
  oneHourMs: 60 * 60 * 1000,
  analysisTemperature: 0.3,
  maxAnalysisTokens: 500,
  conversationHistoryLimit: 10,
};

// Insight Categories
export enum InsightCategory {
  MINDSET_WELLBEING = 'mindset_wellbeing',
  PRODUCTIVITY_FOCUS = 'productivity_focus',
  RELATIONSHIPS_CONNECTION = 'relationships_connection',
  CAREER_GROWTH = 'career_growth',
  HEALTH_LIFESTYLE = 'health_lifestyle',
  PURPOSE_VALUES = 'purpose_values',
}

export const INSIGHT_CATEGORY_DESCRIPTIONS = {
  [InsightCategory.MINDSET_WELLBEING]: 'Thought patterns, emotional regulation, stress, resilience, and happiness',
  [InsightCategory.PRODUCTIVITY_FOCUS]: 'Time management, procrastination, concentration, and task completion',
  [InsightCategory.RELATIONSHIPS_CONNECTION]: 'Interpersonal dynamics, communication, empathy, and social connections',
  [InsightCategory.CAREER_GROWTH]: 'Professional development, learning new skills, ambition, and work challenges',
  [InsightCategory.HEALTH_LIFESTYLE]: 'Physical well-being, habits (sleep, exercise, nutrition), and self-care',
  [InsightCategory.PURPOSE_VALUES]: 'Life meaning, personal values, long-term vision, and existential reflections',
};

// Category Insights Config
export const CATEGORY_INSIGHTS_CONFIG = {
  maxMemoriesPerInsight: 50, // Limit memories used for insight generation
  refreshRateLimitMs: 60 * 60 * 1000, // 1 hour
  classificationTemperature: 0.2, // Low temperature for consistent classification
  generationTemperature: 0.7, // Higher for creative insights
  maxClassificationTokens: 100,
  maxInsightTokens: 800,
};

