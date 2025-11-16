# Genkit Agent Transformation Implementation Plan

## Overview

Transform Kairos from a basic AI chatbot (plain model calls with conversation context) into a full Genkit-based agent with:
- **Session-level reasoning** (ephemeral conversation history per thread)
- **Long-term semantic memory** (Firestore + embeddings for insights and important moments)
- **Tool calling capabilities** (read-only information providers)
- **Event-driven orchestration** (keeping existing callable functions architecture)
- **Clean separation of concerns** (modular, testable, maintainable)

This plan **augments** the existing production system rather than replacing it, preserving all current functionality while adding agentic capabilities.

---

## Current State Analysis

### What Already Works ✅

1. **Genkit Integration** ([genkit.ts:1-27](../../../functions/src/config/genkit.ts))
   - Google Generative AI plugin configured
   - Using `gemini-2.0-flash` model
   - Firebase telemetry enabled
   - Secret management via Firebase Functions params

2. **AI Service** ([ai-service.ts:1-136](../../../functions/src/services/ai-service.ts))
   - Text, audio, and image response generation
   - Multimodal support
   - Configurable temperature and token limits

3. **Conversation Context** ([conversation-builder.ts:1-57](../../../functions/src/domain/conversation/conversation-builder.ts))
   - Loads last 20 messages per thread
   - Formats as `role: content` strings
   - Clean separation from message repository

4. **Callable Functions Architecture** ([ai-response-callable.ts:1-151](../../../functions/src/functions/ai-response-callable.ts))
   - `generateMessageResponse` callable function
   - Proper authentication and authorization
   - Error handling and retry logic
   - Production-tested

5. **Insights System** ([insights/](../../../functions/src/domain/insights/))
   - Thread-level and global insights
   - Mood, emotion, keywords, themes extraction
   - Scheduled daily insights generation
   - Semantic analysis already in place

6. **Rich Data Models**
   - [UserProfileModel](../../../lib/features/profile/data/models/user_profile_model.dart) with demographics, goals, interests
   - [InsightModel](../../../lib/features/insights/data/models/insight_model.dart) with mood scores, emotions, themes
   - [JournalMessageModel](../../../lib/features/journal/data/models/journal_message_model.dart) with multimodal support

### What's Missing ❌

1. **No Agent Definition** - Not using Genkit's `defineAgent` API
2. **No Tools** - No `defineTool` for `getDate`, `getUserProfile`, etc.
3. **No Long-term Memory** - No `defineMemory` or semantic memory storage with embeddings
4. **No Session Management** - Context rebuilt from scratch on every call (stateless)
5. **Insights Not Integrated** - Agent doesn't have access to existing insights data

### Key Discoveries

- **Architecture Decision**: Current callable-based approach is superior to Firestore triggers (deprecated in codebase at [index.ts:12-13](../../../functions/src/index.ts#L12-L13))
- **Session Scope**: Each thread is a natural session boundary with its own ID and message history
- **Memory vs Insights**: These are separate concerns with different lifecycles and purposes
  - **Insights** = analytics, summaries, metadata (structured)
  - **Memory** = agent knowledge, continuity, semantic embeddings (vector-based)

---

## Desired End State

### Functional Requirements

1. **Agent responds with context awareness**
   - Remembers conversation within thread (session)
   - Recalls important facts from long-term memory
   - Uses tools to access current user data

2. **Tools provide real-time information**
   - `getDate` → current date/time
   - `getUserProfile` → user demographics, goals, interests
   - `getRecentInsights` → latest thread + global insights
   - `getConversationTopicSummary` → summary of last N messages
   - `getUserConfig` → app settings, tone preferences

3. **Memory enables continuity**
   - Stores extracted insights as semantic memory
   - Stores user-confirmed important moments
   - Retrieves via semantic search on user input
   - Does NOT store raw conversation history (stays in thread)

4. **Session management isolates threads**
   - Each thread = one session
   - History loaded per thread
   - No cross-thread contamination

### Technical Requirements

1. **Backward compatibility**: Existing client code continues to work
2. **Performance**: Response time ≤ current baseline (< 5s for text, < 10s for multimodal)
3. **Observability**: All agent actions logged and traceable
4. **Testability**: Each component unit-testable in isolation

### Verification Criteria

After implementation is complete:
- Send a message to a thread → Agent responds using tools
- Ask "What's my name?" → Agent calls `getUserProfile` tool and responds with correct name
- Ask "What date is it?" → Agent calls `getDate` tool and responds correctly
- Reference a past insight → Agent retrieves from memory and uses in response
- Check Firestore → Memory documents exist in `kairos_memories` collection
- Check logs → Tool calls and memory retrievals are visible

---

## What We're NOT Doing

**Explicitly out of scope to prevent scope creep:**

1. **Not changing callable architecture** - No migration to Firestore triggers
2. **Not modifying insights generation** - Insights pipeline stays external to agent
3. **Not adding write tools** - All tools are read-only
4. **Not changing client SDK** - Dart code continues calling `generateMessageResponse`
5. **Not replacing message repository** - Existing data access patterns unchanged
6. **Not implementing chat history UI** - Frontend changes are separate
7. **Not adding user authentication changes** - Auth stays as-is
8. **Not optimizing embeddings model** - Use Genkit defaults initially
9. **Not building memory management UI** - Memory is transparent to users initially
10. **Not implementing memory pruning** - Start with unlimited accumulation

---

## Implementation Approach

### Strategy

**Incremental augmentation over replacement:**
1. Build new components alongside existing code
2. Test each component in isolation
3. Integrate one piece at a time
4. Maintain rollback capability at each phase
5. Keep existing callable function as orchestrator

### Architecture Pattern

```
Client (Dart)
    ↓ calls
generateMessageResponse (existing callable function)
    ↓ orchestrates
┌─────────────────────────────────────────────┐
│ NEW: Kairos Agent (defineAgent)             │
│   ├─ Session (ephemeral history)            │
│   ├─ Tools (read-only)                      │
│   └─ Memory (semantic search)               │
└─────────────────────────────────────────────┘
    ↓ persists to
Firestore (messages, insights, memories)
```

### Migration Path

- **Phase 1**: Tools (no dependencies, safe to add)
- **Phase 2**: Session management (refactor existing context loading)
- **Phase 3**: Memory store (new collection, new queries)
- **Phase 4**: Agent definition (brings everything together)
- **Phase 5**: Integration (wire into existing callable)
- **Phase 6**: Memory population (backfill from insights)

---

## Phase 1: Tool Definitions

### Overview
Create read-only Genkit tools that provide the agent with real-time information about the user, time, and conversation context. Tools are pure functions with no side effects.

### Changes Required

#### 1. Create Tools Module

**File**: `functions/src/agents/kairos.tools.ts`

```typescript
import { defineTool } from 'genkit';
import { z } from 'zod';
import admin from 'firebase-admin';

// Tool 1: Get current date/time
export const getDateTool = defineTool(
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
export const getUserProfileTool = defineTool(
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
  async ({ userId }) => {
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
export const getRecentInsightsTool = defineTool(
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
  async ({ userId, threadId, limit }) => {
    const db = admin.firestore();

    // Emotion enum mapping
    const emotionMap = ['joy', 'calm', 'neutral', 'sadness', 'stress', 'anger', 'fear', 'excitement'];

    // Get thread insights if threadId provided
    let threadInsights = [];
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
export const getConversationTopicSummaryTool = defineTool(
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
  async ({ userId, threadId, messageCount }) => {
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
    const conversationText = messages.join(' ');
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
export const getUserConfigTool = defineTool(
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
  async ({ userId }) => {
    // Placeholder - return defaults for now
    // TODO: Integrate with actual user settings when available
    return {
      preferredTone: 'supportive and empathetic',
      language: 'en',
      notificationsEnabled: true,
    };
  }
);

// Export all tools as array
export const kairosTools = [
  getDateTool,
  getUserProfileTool,
  getRecentInsightsTool,
  getConversationTopicSummaryTool,
  getUserConfigTool,
];
```

#### 2. Add Zod Dependency Check

**File**: `functions/package.json`

Verify `zod` is already installed (it is at line 23):
```json
"zod": "^3.22.0"
```

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compilation succeeds: `cd functions && npm run build`
- [ ] No linting errors: `cd functions && npm run lint` (if lint script exists)
- [ ] Tools export successfully (no runtime errors on import)
- [ ] Each tool can be called directly in test:
  ```typescript
  const date = await getDateTool({});
  console.log(date.timestamp); // Should print current time
  ```

#### Manual Verification:
- [ ] `getDateTool` returns current date/time with correct format
- [ ] `getUserProfileTool` returns profile data for a real user from Firestore
- [ ] `getRecentInsightsTool` returns insights for a user with existing insights
- [ ] `getConversationTopicSummaryTool` returns summary for a thread with messages
- [ ] `getUserConfigTool` returns default config (placeholder values)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 2: Session Management

### Overview
Create a session management class that loads conversation history per thread and maintains ephemeral context during function execution. Each thread is a distinct session with isolated history.

### Changes Required

#### 1. Create Session Management Module

**File**: `functions/src/agents/kairos.session.ts`

```typescript
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
```

#### 2. Update Conversation Builder (Optional - Keep for Backward Compatibility)

**File**: `functions/src/domain/conversation/conversation-builder.ts`

Keep existing implementation unchanged for backward compatibility. The new `KairosSession` provides a superset of functionality.

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compilation succeeds: `cd functions && npm run build`
- [ ] Session class exports successfully
- [ ] Session can be instantiated:
  ```typescript
  const session = new KairosSession({ threadId: 'test', userId: 'test' });
  ```
- [ ] History manipulation methods work:
  ```typescript
  session.addUserMessage('Hello');
  session.addAssistantMessage('Hi there');
  assert(session.getHistory().length === 2);
  ```

#### Manual Verification:
- [ ] `loadHistory()` loads actual messages from Firestore for a real thread
- [ ] `excludeMessageId` parameter correctly filters out specified message
- [ ] History respects `historyLimit` configuration
- [ ] `getFormattedHistory()` returns correct format for Genkit (uses 'model' for AI role)
- [ ] Session metadata returns correct counts

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 3: Long-term Memory Store

### Overview
Implement semantic memory storage using Genkit's `defineMemory` API. Memory stores extracted insights and user-confirmed important moments as embeddings in Firestore. Retrieval uses semantic search.

**Key Principle**: Memory ≠ Insights
- **Insights** = analytics, metadata, structured summaries (existing pipeline)
- **Memory** = semantic knowledge for agent reasoning (new capability)

### Changes Required

#### 1. Create Memory Module

**File**: `functions/src/agents/kairos.memory.ts`

```typescript
import { defineMemory } from 'genkit';
import admin from 'firebase-admin';

/**
 * Memory document structure in Firestore
 */
export interface MemoryDocument {
  userId: string;
  threadId?: string;
  content: string;
  metadata: {
    source: 'insight' | 'user_confirmed' | 'auto_extracted';
    insightId?: string;
    messageId?: string;
    createdAt: number;
    tags?: string[];
  };
  embedding?: number[];
}

/**
 * Define long-term semantic memory for Kairos
 *
 * Memory stores:
 * 1. Extracted insights/themes (from insights collection)
 * 2. User-confirmed important moments
 *
 * Retrieval: Semantic search based on user input
 */
export const kairosMemory = defineMemory({
  name: 'kairos-memory',
  description: 'Long-term semantic memory for Kairos agent',

  // Firestore collection for memory storage
  collection: 'kairos_memories',

  // Embedding model (using Genkit default)
  // TODO: Can optimize to specific model later if needed
});

/**
 * Memory service for managing long-term memories
 */
export class MemoryService {
  private db: admin.firestore.Firestore;

  constructor(db?: admin.firestore.Firestore) {
    this.db = db || admin.firestore();
  }

  /**
   * Store an insight as memory
   */
  async storeInsightMemory(
    userId: string,
    insightId: string,
    insightSummary: string,
    threadId?: string,
    tags?: string[]
  ): Promise<void> {
    const memoryDoc: Omit<MemoryDocument, 'embedding'> = {
      userId,
      threadId,
      content: insightSummary,
      metadata: {
        source: 'insight',
        insightId,
        createdAt: Date.now(),
        tags,
      },
    };

    await this.db.collection('kairos_memories').add(memoryDoc);
  }

  /**
   * Store a user-confirmed important moment as memory
   */
  async storeUserConfirmedMemory(
    userId: string,
    content: string,
    messageId: string,
    threadId: string,
    tags?: string[]
  ): Promise<void> {
    const memoryDoc: Omit<MemoryDocument, 'embedding'> = {
      userId,
      threadId,
      content,
      metadata: {
        source: 'user_confirmed',
        messageId,
        createdAt: Date.now(),
        tags,
      },
    };

    await this.db.collection('kairos_memories').add(memoryDoc);
  }

  /**
   * Retrieve memories for a user via semantic search
   *
   * Note: Actual semantic search will be handled by Genkit's memory API
   * This method provides fallback/utility access
   */
  async getRecentMemories(
    userId: string,
    limit: number = 15,
    threadId?: string
  ): Promise<MemoryDocument[]> {
    let query = this.db.collection('kairos_memories')
      .where('userId', '==', userId)
      .orderBy('metadata.createdAt', 'desc')
      .limit(limit);

    if (threadId) {
      query = query.where('threadId', '==', threadId);
    }

    const snapshot = await query.get();
    return snapshot.docs.map(doc => ({
      ...doc.data() as MemoryDocument,
    }));
  }

  /**
   * Delete memories for a thread (when thread is deleted)
   */
  async deleteThreadMemories(threadId: string): Promise<void> {
    const snapshot = await this.db.collection('kairos_memories')
      .where('threadId', '==', threadId)
      .get();

    const batch = this.db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
  }

  /**
   * Get memory statistics for a user
   */
  async getMemoryStats(userId: string): Promise<{
    totalMemories: number;
    insightMemories: number;
    userConfirmedMemories: number;
  }> {
    const snapshot = await this.db.collection('kairos_memories')
      .where('userId', '==', userId)
      .get();

    const stats = {
      totalMemories: snapshot.size,
      insightMemories: 0,
      userConfirmedMemories: 0,
    };

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.metadata?.source === 'insight') {
        stats.insightMemories++;
      } else if (data.metadata?.source === 'user_confirmed') {
        stats.userConfirmedMemories++;
      }
    });

    return stats;
  }
}

/**
 * Factory function for creating memory service
 */
export function createMemoryService(): MemoryService {
  return new MemoryService();
}
```

#### 2. Create Firestore Index

**File**: `firestore.indexes.json` (if it exists in project root or functions/)

Add index for memory queries:

```json
{
  "indexes": [
    {
      "collectionGroup": "kairos_memories",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "metadata.createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "kairos_memories",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "threadId", "order": "ASCENDING" },
        { "fieldPath": "metadata.createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

If `firestore.indexes.json` doesn't exist, these indexes will auto-create when first queried (Firestore will provide the index creation link in logs).

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compilation succeeds: `cd functions && npm run build`
- [ ] Memory module exports successfully
- [ ] MemoryService can be instantiated:
  ```typescript
  const memoryService = new MemoryService();
  ```
- [ ] Memory storage methods work:
  ```typescript
  await memoryService.storeInsightMemory('user123', 'insight456', 'Test summary');
  ```

#### Manual Verification:
- [ ] `storeInsightMemory()` creates document in Firestore `kairos_memories` collection
- [ ] Memory document has correct structure (userId, content, metadata)
- [ ] `getRecentMemories()` retrieves stored memories for a user
- [ ] `threadId` filtering works correctly
- [ ] `getMemoryStats()` returns accurate counts by source type
- [ ] `deleteThreadMemories()` removes all memories for a thread

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 4: Agent Definition

### Overview
Define the Kairos agent using Genkit's `defineAgent` API, bringing together tools, memory, and session management. The agent has a clear personality and reasoning capabilities.

### Changes Required

#### 1. Create Agent Module

**File**: `functions/src/agents/kairos.agent.ts`

```typescript
import { defineAgent } from 'genkit';
import { getAI } from '../config/genkit';
import { kairosTools } from './kairos.tools';
import { kairosMemory } from './kairos.memory';
import { KairosSession } from './kairos.session';
import { SYSTEM_PROMPT } from '../config/constants';

/**
 * Agent configuration
 */
export interface AgentConfig {
  userId: string;
  threadId: string;
  apiKey: string;
  excludeMessageId?: string;
}

/**
 * Agent response
 */
export interface AgentResponse {
  text: string;
  toolsUsed: string[];
  memoriesRetrieved: number;
  usage?: {
    inputTokens?: number;
    outputTokens?: number;
  };
}

/**
 * Define Kairos agent
 *
 * The agent is an AI-first mentor who:
 * - Uses conversation history (session)
 * - Queries long-term memory (insights, important moments)
 * - Calls tools for current information
 * - Maintains empathetic, supportive tone
 */
export const defineKairosAgent = (apiKey: string) => {
  const ai = getAI(apiKey);

  return defineAgent({
    name: 'kairos',
    description: 'Kairos AI mentor for personal growth and journaling',

    // Tools available to agent
    tools: kairosTools,

    // Long-term memory
    memory: kairosMemory,

    // System prompt
    systemPrompt: SYSTEM_PROMPT,

    // Model configuration
    model: ai.model,

    config: {
      temperature: 0.7,
      maxOutputTokens: 500,
    },
  });
};

/**
 * Run Kairos agent for a conversation
 *
 * This is the main entry point for agent execution
 */
export async function runKairos(config: AgentConfig, userInput: string): Promise<AgentResponse> {
  const { userId, threadId, apiKey, excludeMessageId } = config;

  // 1. Create session
  const session = new KairosSession({ userId, threadId });

  // 2. Load conversation history
  await session.loadHistory(excludeMessageId);

  // 3. Define agent (lazy initialization with API key)
  const agent = defineKairosAgent(apiKey);

  // 4. Prepare context for agent
  // Agent will have access to:
  // - Tools (via tool calls)
  // - Memory (via semantic search on userInput)
  // - Session history (as messages)

  const messages = session.getFormattedHistory();
  messages.push({
    role: 'user',
    content: userInput,
  });

  // 5. Run agent
  const response = await agent.run({
    messages,
    context: {
      userId,
      threadId,
    },
  });

  // 6. Extract tool usage and memory stats
  const toolsUsed = response.toolCalls?.map(tc => tc.name) || [];
  const memoriesRetrieved = response.memoryResults?.length || 0;

  return {
    text: response.text,
    toolsUsed,
    memoriesRetrieved,
    usage: response.usage,
  };
}

/**
 * Factory function for agent execution
 */
export function createAgentRunner(apiKey: string) {
  return (config: Omit<AgentConfig, 'apiKey'>, userInput: string) =>
    runKairos({ ...config, apiKey }, userInput);
}
```

#### 2. Update System Prompt (Optional Enhancement)

**File**: `functions/src/config/constants.ts`

Consider enhancing the system prompt to mention tool usage:

```typescript
export const SYSTEM_PROMPT = `You are Kairos, an AI-first mentor in a personal journaling app.

Your role:
- Be empathetic, supportive, and encouraging
- Help users reflect on their thoughts and feelings
- Keep responses concise (2-3 sentences) unless asked for more detail
- Use available tools to personalize your responses (user profile, insights, current date)
- Draw on long-term memory to maintain continuity across conversations

Guidelines:
- Use the user's name when appropriate (from getUserProfile tool)
- Reference past insights to show continuity (from getRecentInsights tool)
- Be curious and ask thoughtful follow-up questions
- Celebrate growth and acknowledge challenges with compassion
- Never be diagnostic or clinical - focus on support and reflection`;
```

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compilation succeeds: `cd functions && npm run build`
- [ ] Agent module exports successfully
- [ ] `defineKairosAgent()` returns agent definition without errors
- [ ] Agent can be instantiated with valid API key

#### Manual Verification:
- [ ] `runKairos()` executes successfully with test input
- [ ] Agent response contains text reply
- [ ] Agent calls tools when relevant (check `toolsUsed` array)
- [ ] Agent retrieves memories when relevant (check `memoriesRetrieved` count)
- [ ] Agent maintains conversation context from session history
- [ ] Response tone matches system prompt (empathetic, supportive)
- [ ] Token usage is tracked in response

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 5: Integration with Existing Callable

### Overview
Wire the new Kairos agent into the existing `generateMessageResponse` callable function. This phase maintains backward compatibility while adding agentic capabilities.

### Changes Required

#### 1. Update AI Response Callable

**File**: `functions/src/functions/ai-response-callable.ts`

Replace the current implementation with agent-based approach:

```typescript
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import admin from 'firebase-admin';
import { getMessageRepository } from '../data/repositories';
import { runKairos } from '../agents/kairos.agent';
import { MessageRole, MessageType, MessageStatus } from '../config/constants';

const db = admin.firestore();

/**
 * Generate AI response for a user message
 *
 * NEW: Uses Kairos agent with tools, memory, and session management
 *
 * Flow:
 * 1. Authenticate and authorize
 * 2. Retrieve user message
 * 3. Run Kairos agent (handles session, tools, memory)
 * 4. Save AI response
 * 5. Update message status
 */
export const generateMessageResponse = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    // 1. Authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    // 2. Extract and validate parameters
    const { messageId } = request.data as {
      messageId: string;
    };

    if (!messageId) {
      throw new HttpsError('invalid-argument', 'messageId required');
    }

    console.log(`[Agent] Generating AI response for message ${messageId} by user ${userId}`);

    // 3. Initialize services
    const messageRepo = getMessageRepository(db);

    try {
      // 4. Authorization check
      const message = await messageRepo.getById(messageId);
      if (!message || message.userId !== userId) {
        throw new HttpsError(
          'permission-denied',
          'Message not found or access denied'
        );
      }

      // 5. Validate message type and role
      if (message.role !== MessageRole.USER) {
        throw new HttpsError(
          'invalid-argument',
          'Can only generate responses for user messages'
        );
      }

      const threadId = message.threadId;

      // 6. Prepare user input based on message type
      let userInput: string;

      if (message.messageType === MessageType.TEXT) {
        if (!message.content) {
          throw new HttpsError('invalid-argument', 'Text message has no content');
        }
        userInput = message.content;
      } else if (message.messageType === MessageType.AUDIO) {
        if (!message.transcription) {
          throw new HttpsError(
            'invalid-argument',
            'Audio message not transcribed yet'
          );
        }
        userInput = message.transcription;
      } else if (message.messageType === MessageType.IMAGE) {
        // For image messages, create descriptive input
        // Note: Multimodal vision will be handled separately
        userInput = '[User shared an image]';
        // TODO: Integrate image analysis with agent in future iteration
      } else {
        throw new HttpsError('invalid-argument', 'Unknown message type');
      }

      // 7. Run Kairos agent
      console.log(`[Agent] Running Kairos agent for thread ${threadId}`);

      const agentResponse = await runKairos(
        {
          userId,
          threadId,
          apiKey: geminiApiKey.value(),
          excludeMessageId: messageId, // Don't include current message in history
        },
        userInput
      );

      console.log(`[Agent] Response generated. Tools used: ${agentResponse.toolsUsed.join(', ') || 'none'}`);
      console.log(`[Agent] Memories retrieved: ${agentResponse.memoriesRetrieved}`);

      // 8. Update original user message to processed status
      await messageRepo.update(messageId, {
        status: MessageStatus.PROCESSED,
      });

      // 9. Save AI response as new message
      const responseMessage = {
        threadId,
        userId,
        role: MessageRole.AI,
        messageType: MessageType.TEXT,
        content: agentResponse.text,
        status: MessageStatus.REMOTE_CREATED,
      };

      await messageRepo.create(responseMessage);

      console.log(`[Agent] AI response created for message ${messageId}`);

      // 10. Return success with metadata
      return {
        success: true,
        message: 'AI response generated successfully',
        metadata: {
          toolsUsed: agentResponse.toolsUsed,
          memoriesRetrieved: agentResponse.memoriesRetrieved,
          tokensUsed: agentResponse.usage,
        },
      };
    } catch (error) {
      console.error(`[Agent] Response generation failed for message ${messageId}:`, error);

      if (error instanceof HttpsError) {
        throw error;
      }

      const message =
        error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `AI response generation failed: ${message}`);
    }
  }
);
```

#### 2. Update Index Exports (If Needed)

**File**: `functions/src/index.ts`

Verify `generateMessageResponse` is still exported (it should already be at line 5):

```typescript
export { generateMessageResponse } from './functions/ai-response-callable';
```

No changes needed if already exported.

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compilation succeeds: `cd functions && npm run build`
- [ ] Firebase Functions deployment succeeds: `npm run deploy` (or deploy to test environment first)
- [ ] Function appears in Firebase Console under Cloud Functions
- [ ] No runtime errors on function initialization

#### Manual Verification:
- [ ] Send a text message from app → Agent responds correctly
- [ ] Send an audio message (transcribed) → Agent responds to transcription
- [ ] Check logs → Tool usage is logged (e.g., `Tools used: getUserProfile, getDate`)
- [ ] Check logs → Memory retrieval is logged (e.g., `Memories retrieved: 3`)
- [ ] Response quality is similar or better than before (empathetic, contextual)
- [ ] Response time is acceptable (< 10s for most messages)
- [ ] Original message status updates to `PROCESSED`
- [ ] AI response message appears in Firestore with correct fields

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 6: Memory Population from Insights

### Overview
Backfill the memory store with existing insights to give the agent immediate access to historical context. This is a one-time migration plus ongoing sync.

### Changes Required

#### 1. Create Memory Population Script

**File**: `functions/src/scripts/populate-memory-from-insights.ts`

```typescript
import admin from 'firebase-admin';
import { MemoryService } from '../agents/kairos.memory';

/**
 * Populate memory from existing insights
 *
 * This script:
 * 1. Reads all insights from Firestore
 * 2. Creates memory documents for each insight summary
 * 3. Tags with source metadata
 *
 * Run once to backfill, then ongoing via trigger (optional)
 */
async function populateMemoryFromInsights() {
  // Initialize Firebase Admin
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const memoryService = new MemoryService(db);

  console.log('Starting memory population from insights...');

  // Get all insights (not deleted)
  const insightsSnapshot = await db.collection('insights')
    .where('isDeleted', '==', false)
    .get();

  console.log(`Found ${insightsSnapshot.size} insights to process`);

  let processedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  for (const insightDoc of insightsSnapshot.docs) {
    const insight = insightDoc.data();
    const insightId = insightDoc.id;

    // Skip if no summary
    if (!insight.summary || insight.summary.trim() === '') {
      console.log(`Skipping insight ${insightId} - no summary`);
      skippedCount++;
      continue;
    }

    try {
      // Check if memory already exists for this insight
      const existingMemory = await db.collection('kairos_memories')
        .where('metadata.insightId', '==', insightId)
        .limit(1)
        .get();

      if (!existingMemory.empty) {
        console.log(`Memory already exists for insight ${insightId}, skipping`);
        skippedCount++;
        continue;
      }

      // Create memory from insight
      await memoryService.storeInsightMemory(
        insight.userId,
        insightId,
        insight.summary,
        insight.threadId || undefined,
        insight.keywords || []
      );

      processedCount++;

      if (processedCount % 10 === 0) {
        console.log(`Processed ${processedCount} insights...`);
      }
    } catch (error) {
      console.error(`Error processing insight ${insightId}:`, error);
      errorCount++;
    }
  }

  console.log('\n=== Memory Population Complete ===');
  console.log(`Total insights: ${insightsSnapshot.size}`);
  console.log(`Processed: ${processedCount}`);
  console.log(`Skipped: ${skippedCount}`);
  console.log(`Errors: ${errorCount}`);
}

// Run script
populateMemoryFromInsights()
  .then(() => {
    console.log('Script completed successfully');
    process.exit(0);
  })
  .catch(error => {
    console.error('Script failed:', error);
    process.exit(1);
  });
```

#### 2. Add Script to Package.json

**File**: `functions/package.json`

Add script to run memory population:

```json
{
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log",
    "genkit:start": "genkit start",
    "test": "mocha --require ts-node/register 'src/test/**/*.test.ts' --timeout 10000",
    "test:watch": "npm test -- --watch",
    "populate-memory": "ts-node src/scripts/populate-memory-from-insights.ts"
  }
}
```

#### 3. Create Ongoing Sync Trigger (Optional - Future Enhancement)

**File**: `functions/src/functions/memory-sync-trigger.ts`

This is optional for initial implementation but recommended for ongoing sync:

```typescript
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { MemoryService } from '../agents/kairos.memory';

/**
 * Sync new insights to memory automatically
 *
 * Trigger: When new insight is created in Firestore
 * Action: Create corresponding memory document
 */
export const syncInsightToMemory = onDocumentCreated(
  {
    document: 'insights/{insightId}',
    region: 'us-central1',
  },
  async (event) => {
    const insight = event.data?.data();
    const insightId = event.params.insightId;

    if (!insight || !insight.summary) {
      console.log(`Skipping insight ${insightId} - no summary`);
      return;
    }

    // Skip if deleted
    if (insight.isDeleted) {
      console.log(`Skipping deleted insight ${insightId}`);
      return;
    }

    const memoryService = new MemoryService();

    try {
      await memoryService.storeInsightMemory(
        insight.userId,
        insightId,
        insight.summary,
        insight.threadId || undefined,
        insight.keywords || []
      );

      console.log(`Memory created for insight ${insightId}`);
    } catch (error) {
      console.error(`Failed to create memory for insight ${insightId}:`, error);
    }
  }
);
```

If implementing the trigger, export it from `functions/src/index.ts`:

```typescript
export { syncInsightToMemory } from './functions/memory-sync-trigger';
```

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compilation succeeds: `cd functions && npm run build`
- [ ] Script runs without errors: `npm run populate-memory`
- [ ] Script completes and logs summary (processed/skipped/errors counts)

#### Manual Verification:
- [ ] `kairos_memories` collection exists in Firestore
- [ ] Memory documents have correct structure:
  - `userId` field
  - `content` field (insight summary)
  - `metadata.source` = `'insight'`
  - `metadata.insightId` matches insight document ID
  - `metadata.tags` contains keywords from insight
- [ ] Number of memories created matches number of insights (minus skipped)
- [ ] No duplicate memories (re-running script skips existing memories)
- [ ] Agent can retrieve memories during conversation (test by asking about past topics)
- [ ] Memory retrieval is relevant to user input (semantic search works)

#### Optional - Trigger Verification:
- [ ] Create a new insight via existing pipeline → Memory automatically created
- [ ] Check Firestore → Corresponding memory document exists
- [ ] Memory has correct `insightId` reference

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Testing Strategy

### Unit Tests

Create tests for each component in isolation:

**File**: `functions/src/test/agents/tools.test.ts`
```typescript
import { expect } from 'chai';
import { getDateTool, getUserProfileTool } from '../../agents/kairos.tools';

describe('Kairos Tools', () => {
  describe('getDateTool', () => {
    it('should return current date/time', async () => {
      const result = await getDateTool({});
      expect(result).to.have.property('timestamp');
      expect(result).to.have.property('date');
      expect(result).to.have.property('dayOfWeek');
    });
  });

  describe('getUserProfileTool', () => {
    it('should return null profile when user not found', async () => {
      const result = await getUserProfileTool({ userId: 'nonexistent' });
      expect(result.name).to.be.null;
    });
  });
});
```

**File**: `functions/src/test/agents/session.test.ts`
```typescript
import { expect } from 'chai';
import { KairosSession } from '../../agents/kairos.session';

describe('KairosSession', () => {
  it('should create empty session', () => {
    const session = new KairosSession({
      threadId: 'test',
      userId: 'test'
    });
    expect(session.getHistory()).to.have.length(0);
  });

  it('should add messages to history', () => {
    const session = new KairosSession({
      threadId: 'test',
      userId: 'test'
    });
    session.addUserMessage('Hello');
    session.addAssistantMessage('Hi there');
    expect(session.getHistory()).to.have.length(2);
  });
});
```

**File**: `functions/src/test/agents/memory.test.ts`
```typescript
import { expect } from 'chai';
import { MemoryService } from '../../agents/kairos.memory';

describe('MemoryService', () => {
  // Note: These tests require Firestore emulator
  it('should create memory service', () => {
    const service = new MemoryService();
    expect(service).to.be.instanceOf(MemoryService);
  });
});
```

### Integration Tests

**File**: `functions/src/test/integration/agent-flow.test.ts`
```typescript
import { expect } from 'chai';
import { runKairos } from '../../agents/kairos.agent';

describe('Agent Integration', () => {
  // This test requires:
  // - Firestore emulator running
  // - Valid Gemini API key in environment
  // - Test data seeded

  it.skip('should generate response with tools and memory', async () => {
    const response = await runKairos(
      {
        userId: 'test-user',
        threadId: 'test-thread',
        apiKey: process.env.GEMINI_API_KEY || '',
      },
      'What is my name?'
    );

    expect(response.text).to.be.a('string');
    expect(response.toolsUsed).to.include('getUserProfile');
  });
});
```

### Manual Testing Steps

1. **End-to-End Agent Flow**
   - Create a new thread
   - Send message: "What's today's date?"
   - Verify: Agent calls `getDate` tool and responds with current date
   - Check logs: Tool call logged

2. **User Profile Integration**
   - Ensure user has profile with name filled in
   - Send message: "What do you know about me?"
   - Verify: Agent calls `getUserProfile` and mentions user's name, goals, interests
   - Check logs: `getUserProfile` tool called

3. **Memory Retrieval**
   - Ensure user has insights and memories populated
   - Send message: "How have I been feeling lately?"
   - Verify: Agent retrieves memories and references past insights
   - Check logs: Memory retrieval count > 0

4. **Session Continuity**
   - Send message: "I'm feeling stressed about work"
   - Agent responds
   - Send follow-up: "What should I do?"
   - Verify: Agent references previous message about stress
   - Check: Context maintained within session

5. **Tool Combination**
   - Send message: "Can you remind me what I was thinking about this week?"
   - Verify: Agent calls multiple tools (`getRecentInsights`, `getConversationTopicSummary`)
   - Check logs: Multiple tools used

---

## Performance Considerations

### Response Time Optimization

1. **Parallel Tool Calls**: Genkit automatically parallelizes independent tool calls
2. **Memory Limit**: Retrieve max 15 memories to avoid token bloat
3. **History Limit**: Keep at 20 messages (current setting works well)
4. **Embedding Cache**: Genkit caches embeddings for recent inputs

### Cost Management

1. **Token Usage Tracking**: Every response includes token counts
2. **Memory Pruning** (future): Implement LRU or importance-based pruning
3. **Tool Optimization**: Read-only tools minimize API calls

### Scaling

1. **Firestore Indexes**: Ensure composite indexes exist for memory queries
2. **Connection Pooling**: Firestore SDK handles connection reuse
3. **Function Concurrency**: Cloud Functions auto-scales (default 1000 concurrent)

---

## Migration Notes

### Backward Compatibility

- **Client SDK**: No changes required - same callable function signature
- **Response Format**: Same success response structure
- **Error Handling**: Same error codes and messages
- **Message Pipeline**: Same status transitions

### Rollback Plan

If issues arise:

1. **Revert Callable Function**: Deploy previous version of `ai-response-callable.ts`
2. **Keep Tools/Memory**: New modules don't affect old code
3. **Memory Data**: `kairos_memories` collection can remain (no harm)
4. **Gradual Rollout**: Use feature flags to enable agent for subset of users (future enhancement)

### Data Migration

- **Insights → Memory**: One-time backfill via script
- **No User Data Loss**: All new collections, no deletions
- **Idempotent Script**: Safe to re-run memory population

---

## References

- Original task description: [User prompt above]
- Current AI Service: [ai-service.ts](../../../functions/src/services/ai-service.ts)
- Current Callable: [ai-response-callable.ts](../../../functions/src/functions/ai-response-callable.ts)
- Conversation Builder: [conversation-builder.ts](../../../functions/src/domain/conversation/conversation-builder.ts)
- Insights System: [insights/](../../../functions/src/domain/insights/)
- Genkit Config: [genkit.ts](../../../functions/src/config/genkit.ts)
- User Profile Model: [user_profile_model.dart](../../../lib/features/profile/data/models/user_profile_model.dart)
- Insight Model: [insight_model.dart](../../../lib/features/insights/data/models/insight_model.dart)
- Message Model: [journal_message_model.dart](../../../lib/features/journal/data/models/journal_message_model.dart)

---

## Dependencies Check

All required dependencies are already installed in `functions/package.json`:

- ✅ `genkit: ^1.0.0`
- ✅ `@genkit-ai/google-genai: ^1.0.0`
- ✅ `@genkit-ai/firebase: ^1.0.0`
- ✅ `firebase-admin: ^12.0.0`
- ✅ `firebase-functions: ^5.0.0`
- ✅ `zod: ^3.22.0`

No additional dependencies needed.

---

## Success Checklist

### Phase 1: Tools
- [ ] All 5 tools implemented
- [ ] Tools export as array
- [ ] Each tool tested individually
- [ ] Zod schemas validate correctly

### Phase 2: Session
- [ ] `KairosSession` class created
- [ ] History loading works
- [ ] Message manipulation methods work
- [ ] Formatted output for Genkit correct

### Phase 3: Memory
- [ ] `defineMemory` configured
- [ ] `MemoryService` implements CRUD
- [ ] Firestore collection created
- [ ] Memory storage/retrieval tested

### Phase 4: Agent
- [ ] `defineAgent` configured with tools + memory
- [ ] `runKairos` executes successfully
- [ ] Agent calls tools when appropriate
- [ ] Agent retrieves memories when relevant

### Phase 5: Integration
- [ ] `generateMessageResponse` uses agent
- [ ] Callable function deploys successfully
- [ ] End-to-end flow works from client
- [ ] Logs show tool usage and memory retrieval

### Phase 6: Memory Population
- [ ] Backfill script runs successfully
- [ ] Memories created for all insights
- [ ] No duplicates on re-run
- [ ] Agent uses populated memories

### Overall
- [ ] No breaking changes to client
- [ ] Response time acceptable
- [ ] Error handling maintained
- [ ] Observability via logs
- [ ] All tests pass
