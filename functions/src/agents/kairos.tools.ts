import { z } from 'zod';
import admin from 'firebase-admin';
import { getAI } from '../config/genkit';

/**
 * Create all Kairos tools for the agent
 *
 * Tools are defined using the Genkit instance's defineTool method
 */
export function createKairosTools(apiKey: string) {
  const ai = getAI(apiKey);

  // Tool 1: Get current date/time
  const getDateTool = ai.defineTool(
  {
    name: 'getDate',
    description: 'Returns the current date and time. Use this when the user asks about the current date, day of week, or time.',
    inputSchema: z.object({}),
    outputSchema: z.object({
      timestamp: z.string(),
      date: z.string(),
      time: z.string(),
      dayOfWeek: z.string(),
      timezone: z.string(),
    }),
  },
  async () => {
    const now = new Date();
    return {
      timestamp: now.toISOString(),
      date: now.toISOString().split('T')[0],
      time: now.toTimeString().split(' ')[0],
      dayOfWeek: now.toLocaleDateString('en-US', { weekday: 'long' }),
      timezone: 'UTC',
    };
  }
  );

  // Tool 2: Get user profile
  const getUserProfileTool = ai.defineTool(
  {
    name: 'getUserProfile',
    description: 'Returns user profile information including name, demographics, goals, and interests. Use this when you need to personalize responses or when the user asks about their profile.',
    inputSchema: z.object({
      userId: z.string().describe('The Firebase Auth UID of the user'),
    }),
    outputSchema: z.object({
      name: z.string().nullable(),
      age: z.number().nullable(),
      dateOfBirth: z.string().nullable(),
      country: z.string().nullable(),
      gender: z.string().nullable(),
      mainGoal: z.string().nullable(),
      interests: z.array(z.string()),
      experienceLevel: z.string().nullable(),
    }),
  },
  async ({ userId }: { userId: string }) => {
    const db = admin.firestore();

    // Query userProfiles collection
    const snapshot = await db.collection('userProfiles')
      .where('userId', '==', userId)
      .where('isDeleted', '==', false)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return {
        name: null,
        age: null,
        dateOfBirth: null,
        country: null,
        gender: null,
        mainGoal: null,
        interests: [],
        experienceLevel: null,
      };
    }

    const profile = snapshot.docs[0].data();

    // Calculate age from dateOfBirthMillis
    let age = null;
    if (profile.dateOfBirthMillis) {
      const birthDate = new Date(profile.dateOfBirthMillis);
      const ageDiff = Date.now() - birthDate.getTime();
      const ageDate = new Date(ageDiff);
      age = Math.abs(ageDate.getUTCFullYear() - 1970);
    }

    return {
      name: profile.name || null,
      age,
      dateOfBirth: profile.dateOfBirthMillis
        ? new Date(profile.dateOfBirthMillis).toISOString().split('T')[0]
        : null,
      country: profile.country || null,
      gender: profile.gender || null,
      mainGoal: profile.mainGoal || null,
      interests: profile.interests || [],
      experienceLevel: profile.experienceLevel || null,
    };
  }
  );

  // Tool 3: Get recent insights
  const getRecentInsightsTool = ai.defineTool(
  {
    name: 'getRecentInsights',
    description: 'Returns recent insights for the user, including both thread-specific and global insights. Use this to understand patterns, themes, and emotional trends.',
    inputSchema: z.object({
      userId: z.string().describe('The Firebase Auth UID of the user'),
      threadId: z.string().optional().describe('Optional thread ID to get thread-specific insights'),
      limit: z.number().default(5).describe('Number of insights to return'),
    }),
    outputSchema: z.object({
      threadInsights: z.array(z.object({
        summary: z.string(),
        moodScore: z.number(),
        dominantEmotion: z.string(),
        keywords: z.array(z.string()),
        themes: z.array(z.string()),
        period: z.string(),
      })),
      globalInsights: z.array(z.object({
        summary: z.string(),
        moodScore: z.number(),
        dominantEmotion: z.string(),
        keywords: z.array(z.string()),
        themes: z.array(z.string()),
        period: z.string(),
      })),
    }),
  },
  async ({ userId, threadId, limit }: { userId: string; threadId?: string; limit: number }) => {
    const db = admin.firestore();

    // Emotion enum mapping
    const emotionMap = ['joy', 'calm', 'neutral', 'sadness', 'stress', 'anger', 'fear', 'excitement'];

    // Get thread insights if threadId provided
    let threadInsights: Array<{
      summary: string;
      moodScore: number;
      dominantEmotion: string;
      keywords: string[];
      themes: string[];
      period: string;
    }> = [];
    if (threadId) {
      const threadSnapshot = await db.collection('insights')
        .where('userId', '==', userId)
        .where('threadId', '==', threadId)
        .where('isDeleted', '==', false)
        .orderBy('periodEndMillis', 'desc')
        .limit(limit)
        .get();

      threadInsights = threadSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
          summary: data.summary || '',
          moodScore: data.moodScore || 0,
          dominantEmotion: emotionMap[data.dominantEmotion] || 'neutral',
          keywords: data.keywords || [],
          themes: data.aiThemes || [],
          period: data.period || 'unknown',
        };
      });
    }

    // Get global insights
    const globalSnapshot = await db.collection('insights')
      .where('userId', '==', userId)
      .where('threadId', '==', null)
      .where('isDeleted', '==', false)
      .orderBy('periodEndMillis', 'desc')
      .limit(limit)
      .get();

    const globalInsights = globalSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        summary: data.summary || '',
        moodScore: data.moodScore || 0,
        dominantEmotion: emotionMap[data.dominantEmotion] || 'neutral',
        keywords: data.keywords || [],
        themes: data.aiThemes || [],
        period: data.period || 'unknown',
      };
    });

    return {
      threadInsights,
      globalInsights,
    };
  }
  );

  // Tool 4: Get conversation topic summary
  const getConversationTopicSummaryTool = ai.defineTool(
  {
    name: 'getConversationTopicSummary',
    description: 'Returns a brief summary of recent conversation topics in the current thread. Use this to understand what the user has been discussing recently.',
    inputSchema: z.object({
      userId: z.string().describe('The Firebase Auth UID of the user'),
      threadId: z.string().describe('The thread ID to summarize'),
      messageCount: z.number().default(10).describe('Number of recent messages to analyze'),
    }),
    outputSchema: z.object({
      summary: z.string(),
      messageCount: z.number(),
      topics: z.array(z.string()),
    }),
  },
  async ({ userId, threadId, messageCount }: { userId: string; threadId: string; messageCount: number }) => {
    const db = admin.firestore();

    // Get recent messages
    const snapshot = await db.collection('journalMessages')
      .where('threadId', '==', threadId)
      .where('userId', '==', userId)
      .where('isDeleted', '==', false)
      .orderBy('createdAtMillis', 'desc')
      .limit(messageCount)
      .get();

    if (snapshot.empty) {
      return {
        summary: 'No recent messages in this conversation.',
        messageCount: 0,
        topics: [],
      };
    }

    const messages = snapshot.docs.map(doc => {
      const data = doc.data();
      return data.content || data.transcription || '[media content]';
    }).reverse(); // Chronological order

    // Simple topic extraction (can be enhanced with AI later)
    const topics: string[] = [];

    // Basic keyword extraction (can be replaced with AI summarization)
    const summary = messages.length > 3
      ? `Recent conversation covers ${messages.length} messages discussing various topics.`
      : `Conversation includes: ${messages.join('. ')}`;

    return {
      summary,
      messageCount: messages.length,
      topics,
    };
  }
  );

  // Tool 5: Get user config (placeholder for future app settings)
  const getUserConfigTool = ai.defineTool(
  {
    name: 'getUserConfig',
    description: 'Returns user app configuration and preferences. Use this to understand how the user prefers to interact with the app.',
    inputSchema: z.object({
      userId: z.string().describe('The Firebase Auth UID of the user'),
    }),
    outputSchema: z.object({
      preferredTone: z.string(),
      language: z.string(),
      notificationsEnabled: z.boolean(),
    }),
  },
  async ({ userId }: { userId: string }) => {
    // Placeholder - return defaults for now
    // TODO: Integrate with actual user settings when available
    return {
      preferredTone: 'supportive and empathetic',
      language: 'en',
      notificationsEnabled: true,
    };
  }
  );

  // Return all tools as array
  return [
    getDateTool,
    getUserProfileTool,
    getRecentInsightsTool,
    getConversationTopicSummaryTool,
    getUserConfigTool,
  ];
}
