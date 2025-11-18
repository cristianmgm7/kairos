# Semantic Long-Term Memory with RAG Implementation Plan

## Overview

Implement production-ready semantic long-term memory (LTM) for the Kairos agent using Genkit's RAG (Retrieval-Augmented Generation) capabilities. This plan **completely separates** the LTM system from the insights feature and replaces the current time-based memory retrieval with true semantic search using embeddings.

## Current State Analysis

### What Exists Now

1. **Agent Pipeline** ([kairos.agent.ts:38-116](../../../functions/src/agents/kairos.agent.ts#L38-L116))
   - ✅ Session management (thread-based conversation history)
   - ✅ Tool calling (getDate, getUserProfile, etc.)
   - ❌ **Fake memory**: Uses `MemoryService.getRecentMemories()` which is just time-based retrieval
   - ❌ **No embeddings**: No semantic search capability

2. **Memory Service** ([kairos.memory.ts:26-154](../../../functions/src/agents/kairos.memory.ts#L26-L154))
   - ✅ Firestore storage in `kairos_memories` collection
   - ✅ Metadata tracking (source, insightId, createdAt, tags)
   - ❌ **No vector embeddings**: Missing `embedding` field
   - ❌ **Time-based queries only**: `orderBy('metadata.createdAt', 'desc')`
   - ❌ **No semantic search**: Cannot find relevant memories based on meaning

3. **Insights Tool** ([kairos.tools.ts:159-248](../../../functions/src/agents/kairos.tools.ts#L159-L248))
   - ❌ **VIOLATION**: Agent retrieves insights as if they were memories
   - ❌ **Inappropriate mixing**: Insights (analytics) being used as context (memory)
   - Must be completely removed from agent access

4. **Migration Script** ([populate-memory-from-insights.ts:14-96](../../../functions/src/scripts/populate-memory-from-insights.ts#L14-L96))
   - ❌ **Wrong approach**: Copies insights to memory without embeddings
   - ❌ **Perpetuates coupling**: Reinforces insights-as-memory pattern
   - Must be deleted

### Key Discoveries

- **Genkit has NO `defineMemory` API**: The previous plan was based on incorrect assumptions
- **RAG is the correct approach**: Genkit implements semantic memory via embeddings + retrieval
- **Firestore vector search is available**: Via `@genkit-ai/firebase` plugin with `text-embedding-004`
- **Vector indexes exist**: Already configured at [firestore.indexes.json:234-263](../../../firestore.indexes.json#L234-L263) (but for wrong schema)

## Desired End State

### Functional Requirements

1. **Semantic Memory Retrieval (Agent Read)**
   - Agent receives user input → Generates embedding → Searches Firestore vector index
   - Returns top-K most relevant memory documents based on cosine similarity
   - Memory content is injected into system prompt as context
   - **Zero dependency on insights collection**

2. **Automatic Memory Extraction (Agent Write)**
   - After every conversation turn → Secondary LLM extracts 3-5 durable facts
   - Facts are embedded and indexed to `kairos_memories` collection
   - Extraction happens asynchronously (doesn't block user response)
   - Focuses on: user facts, emotional patterns, goals, preferences, significant events

3. **Complete Insights Separation**
   - `getRecentInsights` tool removed entirely from agent
   - Agent never queries `insights` collection
   - Insights remain user-facing analytics only
   - Clear architectural boundary enforced

4. **Production-Ready RAG Architecture**
   - Firestore as vector database
   - `text-embedding-004` (768 dimensions)
   - Cosine similarity distance measure
   - Top-5 retrieval with metadata filtering (userId)

### Technical Requirements

1. **Backward compatibility**: Existing callable function signature unchanged
2. **Performance**: Memory retrieval adds < 500ms latency (embeddings are fast)
3. **Cost efficiency**: Use `gemini-2.0-flash` for extraction (low-cost, low-latency)
4. **Observability**: Log memory retrieval count, extraction success/failure
5. **Testability**: RAG components testable in isolation

### Verification Criteria

#### Automated Verification:
- [ ] TypeScript compilation succeeds: `cd functions && npm run build`
- [ ] All imports resolve correctly
- [ ] No runtime errors on function initialization
- [ ] Firestore vector index exists and is active

#### Manual Verification:
- [ ] Send message: "I'm stressed about work" → Agent responds
- [ ] Check logs: Memory retrieval shows semantic matches (not just recent)
- [ ] Send follow-up after 1 hour: "How have I been feeling?" → Agent recalls work stress
- [ ] Check Firestore: New memory documents have `embedding` field (array of 768 numbers)
- [ ] Verify: Agent NEVER calls insights collection (check logs for Firestore queries)
- [ ] Test: Ask "What are my insights?" → Agent cannot answer (tool removed)

## What We're NOT Doing

**Explicitly out of scope to prevent scope creep:**

1. **Not modifying insights generation pipeline** - Insights remain completely unchanged
2. **Not building memory management UI** - Memory is transparent to users
3. **Not implementing memory pruning** - Start with unlimited accumulation
4. **Not adding user-triggered memory storage** - Only automatic extraction
5. **Not supporting multimodal memory** - Text embeddings only (images separate)
6. **Not changing client SDK** - Dart code unchanged
7. **Not optimizing chunk size** - Use full extracted facts as-is
8. **Not implementing reranking** - Single-stage retrieval sufficient initially
9. **Not adding memory deletion triggers** - Memories persist indefinitely
10. **Not backfilling from insights** - Start fresh, no migration

---

## Implementation Approach

### Strategy

**Clean break, not gradual migration:**
1. Build new RAG components from scratch
2. Delete all fake memory code
3. Replace agent pipeline with flow-based architecture
4. Test end-to-end before deployment
5. Deploy as atomic change (no gradual rollout)

### Architecture Pattern

```
Client (Dart)
    ↓ calls
generateMessageResponse (callable function)
    ↓ orchestrates
┌─────────────────────────────────────────────┐
│ kairosAgentFlow (Genkit Flow)               │
│   1. Load session history                   │
│   2. Retrieve memories (RAG semantic search)│
│   3. Augment system prompt with memories    │
│   4. Generate response with tools           │
│   5. Return response to user                │
└─────────────────────────────────────────────┘
    ↓ triggers async
┌─────────────────────────────────────────────┐
│ ingestMemoryFlow (Genkit Flow)              │
│   1. LLM extracts facts from conversation   │
│   2. Generate embeddings for each fact      │
│   3. Index to Firestore (kairos_memories)   │
└─────────────────────────────────────────────┘
    ↓ stores in
Firestore: kairos_memories { userId, content, embedding[768], metadata }
```

---

## Phase 1: RAG Components Setup

### Overview
Create the foundational Genkit components for semantic memory: embedder, indexer, and retriever. These components handle all vector operations.

### Changes Required

#### 1. Create RAG Module

**File**: `functions/src/agents/kairos.rag.ts`

**Purpose**: Define all RAG-related Genkit components in one place.

```typescript
import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import { defineFirestoreRetriever } from '@genkit-ai/firebase';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { geminiApiKey } from '../config/genkit';

// Initialize Firestore (if not already initialized elsewhere)
const firestore = getFirestore();

/**
 * Embedder: text-embedding-004 (768 dimensions)
 *
 * This is Google's latest embedding model optimized for semantic search.
 * Dimensions: 768
 * Cost: $0.00001 per 1K characters (very cheap)
 */
export const kairosEmbedder = googleAI.embedder('text-embedding-004');

/**
 * Firestore Retriever: Semantic search for long-term memories
 *
 * Configuration:
 * - Collection: kairos_memories
 * - Content field: content (the extracted fact/theme)
 * - Vector field: embedding (768-dimensional vector)
 * - Distance: COSINE (best for text similarity)
 * - Embedder: text-embedding-004
 */
export const kairosLtmRetriever = defineFirestoreRetriever({
  name: 'kairosLtmRetriever',
  firestore,
  collection: 'kairos_memories',
  contentField: 'content',
  vectorField: 'embedding',
  embedder: kairosEmbedder,
  distanceMeasure: 'COSINE',
});

/**
 * Helper: Generate embedding for text
 *
 * Use this when manually indexing documents (for ingestMemoryFlow).
 */
export async function generateEmbedding(text: string): Promise<number[]> {
  const ai = genkit({
    plugins: [googleAI({ apiKey: geminiApiKey.value() })],
  });

  const result = await ai.embed({
    embedder: kairosEmbedder,
    content: text,
  });

  return result[0].embedding;
}

/**
 * Helper: Index a memory document to Firestore
 *
 * This function:
 * 1. Generates embedding for the content
 * 2. Stores document with embedding vector in Firestore
 * 3. Returns the document ID
 */
export async function indexMemory(
  userId: string,
  content: string,
  metadata: {
    source: 'auto_extracted' | 'user_confirmed';
    threadId?: string;
    messageId?: string;
    extractedAt: number;
    tags?: string[];
  }
): Promise<string> {
  // Generate embedding
  const embedding = await generateEmbedding(content);

  // Store in Firestore with vector field
  const docRef = await firestore.collection('kairos_memories').add({
    userId,
    content,
    embedding: FieldValue.vector(embedding), // CRITICAL: Use FieldValue.vector()
    metadata,
    createdAt: FieldValue.serverTimestamp(),
  });

  return docRef.id;
}

/**
 * Helper: Retrieve relevant memories for a user query
 *
 * This wraps the retriever for easier testing and reuse.
 */
export async function retrieveMemories(
  query: string,
  userId: string,
  limit: number = 5
): Promise<Array<{ content: string; metadata: any }>> {
  const ai = genkit({
    plugins: [googleAI({ apiKey: geminiApiKey.value() })],
  });

  const docs = await ai.retrieve({
    retriever: kairosLtmRetriever,
    query,
    options: {
      limit,
      where: { userId }, // CRITICAL: Filter by user
    },
  });

  return docs.map(doc => ({
    content: doc.content,
    metadata: doc.metadata,
  }));
}
```

#### 2. Update Firestore Vector Index

**File**: `firestore.indexes.json`

**Changes**: Update the existing `kairos_memories` indexes to support vector search.

**CRITICAL**: The current indexes ([lines 234-263](../../../firestore.indexes.json#L234-L263)) are for time-based queries only. We need to **replace them** with a vector index.

**ACTION**: Delete the existing two `kairos_memories` indexes (lines 233-263) and add this single vector index:

```json
{
  "indexes": [
    // ... keep all existing indexes for other collections ...

    // NEW: Vector index for semantic memory search
    {
      "collectionGroup": "kairos_memories",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "embedding",
          "vectorConfig": {
            "dimension": 768,
            "flat": {}
          }
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**IMPORTANT**: After updating the file, you must create the index using gcloud CLI:

```bash
gcloud alpha firestore indexes composite create \
  --project=<your-project-id> \
  --collection-group=kairos_memories \
  --field-config=vector-config='{"dimension":"768","flat":{}}',field-path=embedding
```

Alternatively, attempt a query first and Firestore will provide the exact command.

#### 3. Update Genkit Config

**File**: `functions/src/config/genkit.ts`

**Changes**: Add Firebase plugin for Firestore integration.

```typescript
import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import { firebase } from '@genkit-ai/firebase'; // ADD THIS
import { enableFirebaseTelemetry } from '@genkit-ai/firebase';
import { defineSecret } from 'firebase-functions/params';

// Define secrets for API keys
export const geminiApiKey = defineSecret('GEMINI_API_KEY');

// Enable Firebase telemetry for monitoring
enableFirebaseTelemetry();

// Lazy initialization to avoid accessing secret during deployment
let aiInstance: ReturnType<typeof genkit> | null = null;

export function getAI(apiKey: string) {
  if (!aiInstance) {
    aiInstance = genkit({
      plugins: [
        googleAI({ apiKey }),
        firebase(), // ADD THIS: Enables Firestore retriever
      ],
      model: googleAI.model('gemini-2.0-flash'),
    });
  }
  return aiInstance;
}
```

#### 4. Verify Dependencies

**File**: `functions/package.json`

**Check**: Ensure `@genkit-ai/firebase` is installed. If not, add it:

```json
{
  "dependencies": {
    "firebase-functions": "^5.0.0",
    "firebase-admin": "^12.0.0",
    "genkit": "^1.0.0",
    "@genkit-ai/google-genai": "^1.0.0",
    "@genkit-ai/firebase": "^1.0.0",
    "zod": "^3.22.0"
  }
}
```

If missing, run:
```bash
cd functions && npm install @genkit-ai/firebase
```

### Success Criteria

#### Automated Verification:
- [x] TypeScript compilation succeeds: `cd functions && npm run build`
- [x] No import errors for `defineFirestoreRetriever`
- [x] `kairosEmbedder` can be called: `await kairosEmbedder.embed('test')`
- [x] `indexMemory()` successfully stores a test document
- [x] `retrieveMemories()` returns results (after vector index is created)

#### Manual Verification:
- [x] Create vector index via gcloud CLI (or wait for auto-creation)
- [x] Verify index exists in Firebase Console → Firestore → Indexes
- [x] Index status shows "Enabled" (not "Building")
- [x] Test indexing: Call `indexMemory()` with sample data
- [x] Check Firestore: Document has `embedding` field with 768 numbers
- [x] Test retrieval: Call `retrieveMemories()` with a query
- [x] Verify: Returns semantically relevant documents (not just recent)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the vector index is active and retrieval works before proceeding to the next phase.

---

## Phase 2: Agent Flow (Read Path)

### Overview
Create the main `kairosAgentFlow` that replaces the current `runKairos` function. This flow performs semantic memory retrieval and generates responses using RAG.

### Changes Required

#### 1. Create Agent Flow

**File**: `functions/src/agents/kairos.agent.ts`

**Changes**: Replace the entire file with a Genkit flow-based implementation.

```typescript
import { z } from 'zod';
import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import { getAI } from '../config/genkit';
import { createKairosTools } from './kairos.tools';
import { KairosSession } from './kairos.session';
import { retrieveMemories } from './kairos.rag';
import { SYSTEM_PROMPT } from '../config/constants';

/**
 * Input schema for the agent flow
 */
const AgentInputSchema = z.object({
  userId: z.string().describe('Firebase Auth UID of the user'),
  threadId: z.string().describe('Conversation thread ID'),
  userInput: z.string().describe('User message content'),
  apiKey: z.string().describe('Gemini API key'),
  excludeMessageId: z.string().optional().describe('Message ID to exclude from history'),
});

/**
 * Output schema for the agent flow
 */
const AgentOutputSchema = z.object({
  text: z.string().describe('AI response text'),
  toolsUsed: z.array(z.string()).describe('Names of tools called'),
  memoriesRetrieved: z.number().describe('Number of memories retrieved'),
  usage: z.object({
    inputTokens: z.number().optional(),
    outputTokens: z.number().optional(),
  }).optional().describe('Token usage statistics'),
});

/**
 * Kairos Agent Flow
 *
 * Main conversational agent that:
 * 1. Loads session history from thread messages
 * 2. Retrieves relevant long-term memories via semantic search
 * 3. Augments system prompt with memory context
 * 4. Generates response using tools and context
 *
 * This flow is the ONLY entry point for agent execution.
 */
export const kairosAgentFlow = (apiKey: string) => {
  const ai = getAI(apiKey);

  return ai.defineFlow(
    {
      name: 'kairosAgent',
      inputSchema: AgentInputSchema,
      outputSchema: AgentOutputSchema,
    },
    async ({ userId, threadId, userInput, apiKey: inputApiKey, excludeMessageId }) => {
      console.log(`[Agent Flow] Starting for user ${userId}, thread ${threadId}`);

      // 1. Create session and load conversation history
      const session = new KairosSession({ userId, threadId });
      await session.loadHistory(excludeMessageId);
      console.log(`[Agent Flow] Loaded ${session.getHistory().length} messages from history`);

      // 2. Retrieve relevant memories using semantic search
      const memories = await retrieveMemories(userInput, userId, 5);
      console.log(`[Agent Flow] Retrieved ${memories.length} relevant memories`);

      // 3. Build augmented system prompt with memory context
      let augmentedPrompt = SYSTEM_PROMPT;
      if (memories.length > 0) {
        const memoryContext = memories
          .map((m, i) => `${i + 1}. ${m.content}`)
          .join('\n');
        augmentedPrompt += `\n\n## Long-Term Memory Context\n\nRelevant facts from past conversations:\n${memoryContext}\n\nUse these memories to inform your response when relevant, but don't explicitly mention them unless asked.`;
      }

      // 4. Convert session history to Genkit message format
      const historyMessages = session.getHistory().map(msg => {
        const role = msg.role === 'ai' ? 'model' : msg.role;
        return {
          role: role as 'user' | 'model' | 'system',
          content: [{ text: msg.content }],
        };
      });

      // 5. Prepare final messages array
      const messages = [
        { role: 'system' as const, content: [{ text: augmentedPrompt }] },
        ...historyMessages,
        { role: 'user' as const, content: [{ text: userInput }] },
      ];

      // 6. Create tools (they need userId and threadId in scope)
      const tools = createKairosTools(inputApiKey, userId, threadId);

      // 7. Generate response with tools
      console.log(`[Agent Flow] Generating response...`);
      const response = await ai.generate({
        messages,
        tools,
        config: {
          temperature: 0.7,
          maxOutputTokens: 500,
        },
      });

      // 8. Extract tool usage
      const toolsUsed = response.toolRequests?.map(tr => tr.toolRequest.name) || [];
      console.log(`[Agent Flow] Tools used: ${toolsUsed.join(', ') || 'none'}`);

      return {
        text: response.text || '',
        toolsUsed,
        memoriesRetrieved: memories.length,
        usage: response.usage ? {
          inputTokens: response.usage.inputTokens,
          outputTokens: response.usage.outputTokens,
        } : undefined,
      };
    }
  );
};

/**
 * Factory function for easier invocation
 */
export async function runKairosAgent(
  config: {
    userId: string;
    threadId: string;
    userInput: string;
    apiKey: string;
    excludeMessageId?: string;
  }
): Promise<z.infer<typeof AgentOutputSchema>> {
  const flow = kairosAgentFlow(config.apiKey);
  return await flow(config);
}
```

#### 2. Update Tools to Remove Insights

**File**: `functions/src/agents/kairos.tools.ts`

**Changes**: Delete the `getRecentInsights` tool entirely (lines 158-248).

**Before** (lines 158-248):
```typescript
// Tool 3: Get recent insights
const getRecentInsightsTool = ai.defineTool(
  // ... entire implementation ...
);
```

**After**: Delete the entire tool definition and remove it from the tools array.

Update the tools array at the end of the file:

```typescript
// Export all tools as array
const tools = [
  getDateTool,
  getUserProfileTool,
  // getRecentInsightsTool, // REMOVED
  getConversationTopicSummaryTool,
  getUserConfigTool,
];

setCachedTools(userId, threadId, tools);

return tools;
```

#### 3. Update Callable Function

**File**: `functions/src/functions/ai-response-callable.ts`

**Changes**: Replace `runKairos` call with new `runKairosAgent` function.

**Before** (lines 95-106):
```typescript
// 7. Run Kairos agent
console.log(`[Agent] Running Kairos agent for thread ${threadId}`);

const agentResponse = await runKairos(
  {
    userId,
    threadId,
    apiKey: geminiApiKey.value(),
    excludeMessageId: messageId,
  },
  userInput
);
```

**After**:
```typescript
// 7. Run Kairos agent flow
console.log(`[Agent] Running Kairos agent for thread ${threadId}`);

const agentResponse = await runKairosAgent({
  userId,
  threadId,
  userInput,
  apiKey: geminiApiKey.value(),
  excludeMessageId: messageId,
});
```

Update imports at the top:
```typescript
import { runKairosAgent } from '../agents/kairos.agent'; // Changed from runKairos
```

### Success Criteria

#### Automated Verification:
- [x] TypeScript compilation succeeds: `cd functions && npm run build`
- [x] Flow definition succeeds (no runtime errors on import)
- [x] All tool references resolve correctly
- [x] No references to `getRecentInsights` remain in codebase

#### Manual Verification:
- [ ] Send test message from app → Agent responds correctly
- [ ] Check logs: Memory retrieval count appears (e.g., "Retrieved 3 relevant memories")
- [ ] Check logs: Memory context is semantically relevant (not just recent)
- [ ] Agent response quality is similar or better than before
- [ ] Response time is acceptable (< 3s for text messages)
- [ ] Tools still work (test "What's today's date?" → calls getDate)
- [ ] Verify: No Firestore queries to `insights` collection (check logs)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the agent flow works correctly before proceeding to the next phase.

---

## Phase 3: Memory Ingestion Flow (Write Path)

### Overview
Create the `ingestMemoryFlow` that automatically extracts facts from conversations and indexes them as embeddings. This flow runs asynchronously after each agent response.

### Changes Required

#### 1. Create Ingestion Flow

**File**: `functions/src/agents/kairos.ingest.ts` (new file)

**Purpose**: Handle automatic memory extraction and storage.

```typescript
import { z } from 'zod';
import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import { getAI } from '../config/genkit';
import { indexMemory } from './kairos.rag';

/**
 * Input schema for memory ingestion
 */
const IngestInputSchema = z.object({
  userId: z.string().describe('Firebase Auth UID'),
  threadId: z.string().describe('Thread ID where conversation occurred'),
  userMessage: z.string().describe('User message content'),
  aiResponse: z.string().describe('AI response content'),
  messageId: z.string().describe('Message ID for tracking'),
  apiKey: z.string().describe('Gemini API key'),
});

/**
 * Output schema for memory ingestion
 */
const IngestOutputSchema = z.object({
  success: z.boolean().describe('Whether extraction succeeded'),
  factsExtracted: z.number().describe('Number of facts extracted'),
  memoryIds: z.array(z.string()).describe('Firestore document IDs of created memories'),
  error: z.string().optional().describe('Error message if failed'),
});

/**
 * Fact extraction prompt
 *
 * This prompt instructs the LLM to extract durable, high-value facts.
 */
const EXTRACTION_PROMPT = `You are a memory extraction system. Analyze the following conversation turn and extract 3-5 durable, high-value facts that would be useful for future conversations.

Focus on:
- Important facts about the user (name, preferences, goals, challenges)
- Emotional patterns or significant feelings
- Key events or milestones mentioned
- Relationships or important people
- Commitments or future plans
- Skills, interests, or expertise areas

Rules:
- Each fact should be a complete, standalone sentence
- Be specific and concrete (avoid vague statements)
- Focus on what's memorable and likely to be relevant later
- Exclude trivial or transient information
- Exclude meta-conversation (e.g., "user asked a question")

Return ONLY the facts, one per line, numbered 1-5. If fewer than 3 significant facts, return what you have.

## Conversation Turn

User: {userMessage}

AI: {aiResponse}

## Extracted Facts (1-5):`;

/**
 * Memory Ingestion Flow
 *
 * Automatically extracts facts from conversations and indexes them.
 * Runs asynchronously after agent response (doesn't block user).
 *
 * Process:
 * 1. LLM analyzes conversation turn
 * 2. Extracts 3-5 durable facts
 * 3. Generates embeddings for each fact
 * 4. Stores in Firestore with vector field
 */
export const ingestMemoryFlow = (apiKey: string) => {
  const ai = getAI(apiKey);

  return ai.defineFlow(
    {
      name: 'ingestMemory',
      inputSchema: IngestInputSchema,
      outputSchema: IngestOutputSchema,
    },
    async ({ userId, threadId, userMessage, aiResponse, messageId, apiKey: inputApiKey }) => {
      console.log(`[Memory Ingest] Starting extraction for message ${messageId}`);

      try {
        // 1. Extract facts using LLM (low-cost model)
        const prompt = EXTRACTION_PROMPT
          .replace('{userMessage}', userMessage)
          .replace('{aiResponse}', aiResponse);

        const extractionResponse = await ai.generate({
          model: googleAI.model('gemini-2.0-flash'), // Fast, cheap model
          prompt,
          config: {
            temperature: 0.3, // Lower temperature for consistent extraction
            maxOutputTokens: 300,
          },
        });

        const extractedText = extractionResponse.text || '';
        console.log(`[Memory Ingest] Raw extraction: ${extractedText}`);

        // 2. Parse extracted facts (one per line, numbered)
        const facts = extractedText
          .split('\n')
          .map(line => line.trim())
          .filter(line => line.length > 0)
          .map(line => {
            // Remove numbering (e.g., "1. " or "- ")
            return line.replace(/^\d+\.\s*/, '').replace(/^-\s*/, '');
          })
          .filter(fact => fact.length > 10); // Minimum fact length

        console.log(`[Memory Ingest] Extracted ${facts.length} facts`);

        if (facts.length === 0) {
          console.log(`[Memory Ingest] No significant facts extracted, skipping indexing`);
          return {
            success: true,
            factsExtracted: 0,
            memoryIds: [],
          };
        }

        // 3. Index each fact as a separate memory
        const memoryIds: string[] = [];
        for (const fact of facts) {
          try {
            const memoryId = await indexMemory(userId, fact, {
              source: 'auto_extracted',
              threadId,
              messageId,
              extractedAt: Date.now(),
            });
            memoryIds.push(memoryId);
            console.log(`[Memory Ingest] Indexed fact: "${fact.substring(0, 50)}..."`);
          } catch (error) {
            console.error(`[Memory Ingest] Failed to index fact: ${error}`);
            // Continue with other facts
          }
        }

        console.log(`[Memory Ingest] Successfully indexed ${memoryIds.length}/${facts.length} facts`);

        return {
          success: true,
          factsExtracted: facts.length,
          memoryIds,
        };
      } catch (error) {
        console.error(`[Memory Ingest] Extraction failed:`, error);
        return {
          success: false,
          factsExtracted: 0,
          memoryIds: [],
          error: error instanceof Error ? error.message : String(error),
        };
      }
    }
  );
};

/**
 * Helper: Run memory ingestion (for easier invocation)
 */
export async function runMemoryIngestion(config: {
  userId: string;
  threadId: string;
  userMessage: string;
  aiResponse: string;
  messageId: string;
  apiKey: string;
}): Promise<z.infer<typeof IngestOutputSchema>> {
  const flow = ingestMemoryFlow(config.apiKey);
  return await flow(config);
}
```

#### 2. Integrate Ingestion into Callable Function

**File**: `functions/src/functions/ai-response-callable.ts`

**Changes**: Add async memory ingestion after response is saved.

Add import at the top:
```typescript
import { runMemoryIngestion } from '../agents/kairos.ingest';
```

Update the flow after saving the AI response (after line 126):

```typescript
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

      // 10. ASYNC: Extract and index memories (don't await - fire and forget)
      runMemoryIngestion({
        userId,
        threadId,
        userMessage: userInput,
        aiResponse: agentResponse.text,
        messageId,
        apiKey: geminiApiKey.value(),
      }).catch(error => {
        // Log but don't fail the response
        console.error(`[Memory Ingest] Background ingestion failed:`, error);
      });

      // 11. Return success with metadata
      return {
        success: true,
        message: 'AI response generated successfully',
        metadata: {
          toolsUsed: agentResponse.toolsUsed,
          memoriesRetrieved: agentResponse.memoriesRetrieved,
          tokensUsed: agentResponse.usage,
        },
      };
```

### Success Criteria

#### Automated Verification:
- [x] TypeScript compilation succeeds: `cd functions && npm run build`
- [x] Ingestion flow definition succeeds
- [x] Can call `runMemoryIngestion()` directly in test
- [x] Test extraction: Mock conversation → parses facts correctly

#### Manual Verification:
- [ ] Send message: "My name is Alex and I'm building a journal app"
- [ ] Agent responds normally
- [ ] Wait 2-3 seconds for background ingestion
- [ ] Check Firestore: New documents in `kairos_memories` collection
- [ ] Verify extracted facts make sense (e.g., "User's name is Alex", "User is building a journal app")
- [ ] Check logs: Shows "Extracted N facts" and "Indexed N facts"
- [ ] Send follow-up: "What do you know about me?" → Agent recalls name and project
- [ ] Verify: Memory retrieval finds the indexed facts

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that memory ingestion works correctly before proceeding to the next phase.

---

## Phase 4: Cleanup and Deletion

### Overview
Remove all legacy code related to the old memory system and insights-as-memory pattern. This enforces the architectural separation.

### Changes Required

#### 1. Delete Old Memory Service

**File**: `functions/src/agents/kairos.memory.ts`

**ACTION**: Delete the entire file.

**Reason**: The old `MemoryService` class is completely replaced by RAG components in `kairos.rag.ts`.

#### 2. Delete Migration Script

**File**: `functions/src/scripts/populate-memory-from-insights.ts`

**ACTION**: Delete the entire file.

**Reason**: We're not migrating from insights. LTM starts fresh with proper embeddings.

#### 3. Remove Script from Package.json

**File**: `functions/package.json`

**Changes**: Remove the `populate-memory` script.

**Before**:
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

**After**:
```json
{
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log",
    "genkit:start": "genkit start",
    "test": "mocha --require ts-node/register 'src/test/**/*.test.ts' --timeout 10000",
    "test:watch": "npm test -- --watch"
  }
}
```

#### 4. Update Imports Across Codebase

**ACTION**: Search for any remaining imports of deleted files and remove them.

```bash
# Check for references to old memory service
cd functions
grep -r "kairos.memory" src/
grep -r "MemoryService" src/
grep -r "populate-memory-from-insights" src/
```

If any references found (besides in this plan), remove them.

#### 5. Clear Old Memory Documents (Optional)

**ACTION**: Optionally clear the old memory documents that were created without embeddings.

**Option A**: Delete via Firestore Console
- Go to Firestore Console
- Navigate to `kairos_memories` collection
- Delete all documents that don't have an `embedding` field

**Option B**: Run a cleanup script (one-time)

Create `functions/src/scripts/cleanup-old-memories.ts`:

```typescript
import admin from 'firebase-admin';

async function cleanupOldMemories() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();

  // Get all memories without embeddings
  const snapshot = await db.collection('kairos_memories').get();

  let deletedCount = 0;
  const batch = db.batch();

  snapshot.docs.forEach(doc => {
    const data = doc.data();
    if (!data.embedding) {
      batch.delete(doc.ref);
      deletedCount++;
    }
  });

  await batch.commit();
  console.log(`Deleted ${deletedCount} old memory documents without embeddings`);
}

cleanupOldMemories()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('Cleanup failed:', error);
    process.exit(1);
  });
```

Run once:
```bash
cd functions
ts-node src/scripts/cleanup-old-memories.ts
# Then delete the script
rm src/scripts/cleanup-old-memories.ts
```

### Success Criteria

#### Automated Verification:
- [x] TypeScript compilation succeeds: `cd functions && npm run build`
- [x] No import errors (all deleted files removed from imports)
- [x] Grep returns no results for `MemoryService` (except in plan docs)
- [x] Grep returns no results for `populate-memory-from-insights`

#### Manual Verification:
- [ ] Verify deleted files no longer exist in `src/`
- [ ] Check `kairos_memories` collection: Only documents with `embedding` field remain
- [ ] Run full test: Send message → Receive response → Memory ingested → Retrieval works
- [ ] Confirm: No Firestore queries to `insights` collection (check logs)
- [ ] Verify: Agent cannot access insights (tool removed)

**Implementation Note**: After completing this phase, perform a full end-to-end test before considering the migration complete.

---

## Phase 5: Testing and Validation

### Overview
Comprehensive testing to ensure the RAG system works correctly and the separation is enforced.

### Testing Strategy

#### Unit Tests

Create `functions/src/test/agents/rag.test.ts`:

```typescript
import { expect } from 'chai';
import { generateEmbedding, indexMemory, retrieveMemories } from '../../agents/kairos.rag';

describe('RAG Components', () => {
  describe('generateEmbedding', () => {
    it('should generate 768-dimensional embedding', async () => {
      const embedding = await generateEmbedding('Test text');
      expect(embedding).to.be.an('array');
      expect(embedding).to.have.lengthOf(768);
      expect(embedding[0]).to.be.a('number');
    });
  });

  describe('indexMemory', () => {
    it('should index memory with embedding', async () => {
      const memoryId = await indexMemory(
        'test-user',
        'Test fact',
        {
          source: 'auto_extracted',
          threadId: 'test-thread',
          messageId: 'test-message',
          extractedAt: Date.now(),
        }
      );
      expect(memoryId).to.be.a('string');
    });
  });

  describe('retrieveMemories', () => {
    it('should retrieve semantically similar memories', async () => {
      // Index a test memory first
      await indexMemory('test-user', 'User loves TypeScript', {
        source: 'auto_extracted',
        extractedAt: Date.now(),
      });

      // Retrieve with similar query
      const memories = await retrieveMemories('What programming languages does the user like?', 'test-user');
      expect(memories).to.be.an('array');
      expect(memories.length).to.be.greaterThan(0);
      expect(memories[0].content).to.include('TypeScript');
    });
  });
});
```

Create `functions/src/test/agents/ingest.test.ts`:

```typescript
import { expect } from 'chai';
import { runMemoryIngestion } from '../../agents/kairos.ingest';

describe('Memory Ingestion', () => {
  it('should extract facts from conversation', async () => {
    const result = await runMemoryIngestion({
      userId: 'test-user',
      threadId: 'test-thread',
      userMessage: 'My name is Sarah and I work as a software engineer',
      aiResponse: 'Nice to meet you, Sarah! How long have you been in software engineering?',
      messageId: 'test-message',
      apiKey: process.env.GEMINI_API_KEY || '',
    });

    expect(result.success).to.be.true;
    expect(result.factsExtracted).to.be.greaterThan(0);
    expect(result.memoryIds).to.be.an('array');
  });

  it('should handle conversations with no significant facts', async () => {
    const result = await runMemoryIngestion({
      userId: 'test-user',
      threadId: 'test-thread',
      userMessage: 'ok',
      aiResponse: 'Alright.',
      messageId: 'test-message',
      apiKey: process.env.GEMINI_API_KEY || '',
    });

    expect(result.success).to.be.true;
    expect(result.factsExtracted).to.equal(0);
  });
});
```

#### Integration Tests

Create `functions/src/test/integration/agent-e2e.test.ts`:

```typescript
import { expect } from 'chai';
import { runKairosAgent } from '../../agents/kairos.agent';
import { indexMemory } from '../../agents/kairos.rag';

describe('Agent End-to-End', () => {
  it('should retrieve relevant memories during conversation', async () => {
    const testUserId = 'test-user-e2e';
    const testThreadId = 'test-thread-e2e';

    // 1. Index a test memory
    await indexMemory(testUserId, 'User is passionate about climate change', {
      source: 'auto_extracted',
      threadId: testThreadId,
      extractedAt: Date.now(),
    });

    // 2. Run agent with related query
    const response = await runKairosAgent({
      userId: testUserId,
      threadId: testThreadId,
      userInput: 'What causes am I interested in?',
      apiKey: process.env.GEMINI_API_KEY || '',
    });

    expect(response.text).to.be.a('string');
    expect(response.memoriesRetrieved).to.be.greaterThan(0);
    expect(response.text.toLowerCase()).to.include('climate');
  });

  it('should NOT retrieve memories from other users', async () => {
    const user1 = 'user-1';
    const user2 = 'user-2';

    // Index memory for user 1
    await indexMemory(user1, 'User plays guitar', {
      source: 'auto_extracted',
      extractedAt: Date.now(),
    });

    // Query as user 2
    const response = await runKairosAgent({
      userId: user2,
      threadId: 'thread-2',
      userInput: 'What instruments do I play?',
      apiKey: process.env.GEMINI_API_KEY || '',
    });

    // Should not retrieve user 1's memory
    expect(response.text.toLowerCase()).to.not.include('guitar');
  });
});
```

### Manual Testing Checklist

#### End-to-End Flow Test

1. **Fresh Conversation**
   - [ ] Send: "Hi, I'm Jamie and I'm learning React"
   - [ ] Agent responds appropriately
   - [ ] Wait 5 seconds for memory ingestion
   - [ ] Check Firestore: 2-3 new memory documents exist
   - [ ] Verify: Documents have `embedding` field (768 numbers)
   - [ ] Check logs: "Extracted N facts" appears

2. **Memory Recall Test**
   - [ ] Wait 1 minute (or clear cache)
   - [ ] Send: "What do you remember about me?"
   - [ ] Agent mentions: name (Jamie), learning React
   - [ ] Check logs: "Retrieved N relevant memories" with N > 0
   - [ ] Verify: Response is coherent and accurate

3. **Semantic Search Test**
   - [ ] Send: "What programming topics am I exploring?"
   - [ ] Agent retrieves React memory (even though query used "topics" not "learning")
   - [ ] Demonstrates semantic matching (not keyword matching)

4. **Separation Enforcement Test**
   - [ ] Ensure user has insights in Firestore
   - [ ] Send: "Show me my insights"
   - [ ] Agent responds: Cannot access insights OR doesn't understand
   - [ ] Check logs: NO queries to `insights` collection
   - [ ] Verify: Agent only queries `kairos_memories` collection

5. **Cross-Thread Isolation Test**
   - [ ] Create new thread
   - [ ] Send: "What's my name?"
   - [ ] Agent should still recall "Jamie" (global memory)
   - [ ] Send thread-specific question
   - [ ] Verify: Retrieves only relevant memories

6. **Performance Test**
   - [ ] Send message
   - [ ] Measure response time (should be < 3s)
   - [ ] Check logs: Memory retrieval latency (should be < 500ms)
   - [ ] Verify: Background ingestion doesn't block response

7. **Error Handling Test**
   - [ ] Disable internet connection temporarily
   - [ ] Send message
   - [ ] Verify: Agent responds with appropriate error
   - [ ] Check logs: Error logged, but doesn't crash
   - [ ] Re-enable connection
   - [ ] Verify: System recovers

### Success Criteria

#### Automated Verification:
- [ ] All unit tests pass: `cd functions && npm test`
- [ ] Integration tests pass (requires Firestore emulator)
- [ ] TypeScript compilation succeeds
- [ ] No console errors during test run

#### Manual Verification:
- [ ] All 7 manual test scenarios pass
- [ ] Firestore contains only valid memories (with embeddings)
- [ ] Logs show semantic retrieval working
- [ ] No queries to `insights` collection
- [ ] Agent responses are coherent and contextual
- [ ] Performance meets targets (< 3s response, < 500ms retrieval)

**Implementation Note**: This phase is critical. Do not proceed to deployment until all tests pass.

---

## Performance Considerations

### Response Time Breakdown

**Target**: < 3 seconds total

1. **Memory Retrieval**: ~300ms
   - Embedding generation: ~100ms (text-embedding-004 is fast)
   - Firestore vector search: ~200ms (with proper indexes)

2. **Session History Load**: ~100ms
   - Firestore query for last 20 messages

3. **LLM Generation**: ~2000ms
   - Depends on model (gemini-2.0-flash is fast)
   - Includes tool calls if any

4. **Message Persistence**: ~50ms
   - Single Firestore write

**Total**: ~2.45 seconds (within target)

### Memory Ingestion (Async)

**Target**: Complete within 5 seconds (non-blocking)

1. **Fact Extraction**: ~1500ms
   - LLM call to gemini-2.0-flash
   - Low temperature (0.3) for speed

2. **Embedding Generation**: ~500ms
   - 3-5 facts × ~100ms each

3. **Firestore Writes**: ~300ms
   - Batch write of 3-5 documents

**Total**: ~2.3 seconds (well within 5s target)

### Cost Considerations

**Per Conversation Turn:**

1. **Memory Retrieval**:
   - Embedding: $0.00001 × 0.1 (100 chars) = $0.000001
   - Firestore read: $0.00006 (5 documents)
   - **Total**: ~$0.00006

2. **Agent Generation**:
   - Input tokens: ~2000 (history + memory + prompt)
   - Output tokens: ~200
   - Gemini 2.0 Flash: ~$0.0002
   - **Total**: ~$0.0002

3. **Memory Ingestion**:
   - Extraction LLM: ~$0.0001
   - Embeddings: $0.000005 × 5 facts = $0.000025
   - Firestore writes: $0.00018 (5 documents)
   - **Total**: ~$0.0003

**Cost per conversation turn**: ~$0.0005 ($0.50 per 1000 conversations)

Very affordable for production use.

### Scaling Considerations

1. **Firestore Vector Index**: Auto-scales, no configuration needed
2. **Embedding Generation**: Parallelizable (batch processing possible)
3. **Cloud Functions**: Auto-scales to handle load
4. **Memory Growth**: Linear with conversations (pruning can be added later)

---

## Migration Notes

### Data Migration

**NO MIGRATION NEEDED**:
- Start with empty `kairos_memories` collection
- Old memory documents (without embeddings) are ignored
- LTM builds up organically from new conversations
- Optional: Clean up old documents (see Phase 4)

### Rollback Plan

If critical issues arise:

1. **Immediate Rollback**:
   ```bash
   # Revert to previous deployment
   git revert <commit-hash>
   cd functions && npm run deploy
   ```

2. **Partial Rollback** (keep new code, disable RAG):
   - Comment out memory retrieval in agent flow
   - Comment out memory ingestion call
   - Deploy (agent works without memory)

3. **Data Cleanup** (if needed):
   - Run cleanup script to remove test memories
   - Keep Firestore indexes (harmless if unused)

### Feature Flags (Optional Future Enhancement)

For gradual rollout, add feature flag:

```typescript
const RAG_ENABLED = process.env.RAG_ENABLED === 'true';

// In agent flow:
const memories = RAG_ENABLED
  ? await retrieveMemories(userInput, userId, 5)
  : [];
```

Not required for initial launch, but useful for A/B testing.

---

## References

- Genkit RAG Documentation: https://genkit.dev/docs/rag/
- Firestore Vector Search: https://firebase.google.com/docs/firestore/vector-search
- Google AI Embeddings: https://ai.google.dev/gemini-api/docs/embeddings
- Current Agent Implementation: [kairos.agent.ts](../../../functions/src/agents/kairos.agent.ts)
- Current Tools: [kairos.tools.ts](../../../functions/src/agents/kairos.tools.ts)
- Current Memory Service (to be replaced): [kairos.memory.ts](../../../functions/src/agents/kairos.memory.ts)
- Callable Function: [ai-response-callable.ts](../../../functions/src/functions/ai-response-callable.ts)
- Genkit Configuration: [genkit.ts](../../../functions/src/config/genkit.ts)

---

## Dependencies Summary

**All required dependencies already installed:**

- ✅ `genkit: ^1.0.0`
- ✅ `@genkit-ai/google-genai: ^1.0.0`
- ✅ `@genkit-ai/firebase: ^1.0.0`
- ✅ `firebase-admin: ^12.0.0`
- ✅ `firebase-functions: ^5.0.0`
- ✅ `zod: ^3.22.0`

**No new dependencies required.**

---

## Implementation Checklist

### Phase 1: RAG Components
- [ ] Create `kairos.rag.ts` with embedder, indexer, retriever
- [ ] Update `firestore.indexes.json` with vector index
- [ ] Run gcloud command to create vector index
- [ ] Update `genkit.ts` to add Firebase plugin
- [ ] Verify dependencies in `package.json`
- [ ] Test embedding generation
- [ ] Test memory indexing
- [ ] Test memory retrieval

### Phase 2: Agent Flow
- [ ] Create new `kairosAgentFlow` in `kairos.agent.ts`
- [ ] Replace `runKairos` with `runKairosAgent`
- [ ] Delete `getRecentInsights` tool from `kairos.tools.ts`
- [ ] Update `ai-response-callable.ts` to use new function
- [ ] Test agent flow end-to-end
- [ ] Verify memory retrieval works
- [ ] Confirm insights tool is removed

### Phase 3: Memory Ingestion
- [ ] Create `kairos.ingest.ts` with extraction flow
- [ ] Add ingestion call to `ai-response-callable.ts`
- [ ] Test fact extraction
- [ ] Test async ingestion
- [ ] Verify memories are created with embeddings
- [ ] Test memory recall works

### Phase 4: Cleanup
- [ ] Delete `kairos.memory.ts`
- [ ] Delete `populate-memory-from-insights.ts`
- [ ] Remove `populate-memory` script from `package.json`
- [ ] Search and remove all `MemoryService` imports
- [ ] Optionally clean old memory documents
- [ ] Verify no broken imports

### Phase 5: Testing
- [ ] Write unit tests for RAG components
- [ ] Write unit tests for ingestion
- [ ] Write integration tests
- [ ] Run all automated tests
- [ ] Perform manual testing (7 scenarios)
- [ ] Verify performance targets met
- [ ] Check logs for errors

### Deployment
- [ ] Build: `cd functions && npm run build`
- [ ] Test locally if possible
- [ ] Deploy: `npm run deploy`
- [ ] Monitor logs for errors
- [ ] Test in production
- [ ] Verify costs are as expected

---

## Success Metrics

**After 1 week in production:**

1. **Functionality**:
   - Memory retrieval rate > 80% (when relevant memories exist)
   - Fact extraction success rate > 90%
   - Zero crashes or critical errors

2. **Performance**:
   - P50 response time < 2s
   - P95 response time < 5s
   - Memory retrieval latency < 500ms

3. **Quality**:
   - User feedback: Agent responses more contextual
   - Memory relevance: Retrieved memories match query intent
   - No false positives: Agent doesn't hallucinate memories

4. **Separation**:
   - Zero queries to `insights` collection from agent
   - Insights feature continues working independently
   - No coupling between systems

5. **Cost**:
   - Average cost per conversation < $0.001
   - Total monthly cost within budget

---

## Open Questions & Future Enhancements

### Open Questions (Resolved)

✅ All questions answered in requirements gathering phase.

### Future Enhancements (Out of Scope)

1. **Memory Pruning**: Implement LRU or importance-based pruning when memory grows large
2. **Memory Management UI**: Let users view/edit/delete memories
3. **Semantic Chunking**: Split long conversations into chunks before extraction
4. **Reranking**: Add two-stage retrieval (broad + rerank) for higher precision
5. **Multimodal Memory**: Store embeddings for images/audio
6. **Cross-User Patterns**: Aggregate anonymous insights across users (privacy-compliant)
7. **Memory Verification**: User confirmation for extracted facts
8. **Memory Importance Scoring**: Weight memories by importance/recency
9. **Topic-Based Memory**: Organize memories by topic/category
10. **Memory Consolidation**: Periodic job to merge similar memories

These can be tackled in future iterations based on user feedback and analytics.

---

## Conclusion

This plan provides a complete, production-ready implementation of semantic long-term memory for the Kairos agent using Genkit's RAG capabilities. The key principles enforced are:

1. **True Semantic Search**: Vector embeddings + cosine similarity (not time-based)
2. **Complete Separation**: LTM and insights are architecturally decoupled
3. **Automatic Extraction**: Facts extracted after every conversation turn
4. **Production Quality**: Proper error handling, logging, testing
5. **Cost Efficient**: Optimized for low cost per conversation

The implementation is broken into 5 clear phases, each with specific success criteria and verification steps. Follow the checklist to ensure nothing is missed.

**Estimated implementation time**: 2-3 days for an experienced developer familiar with the codebase.

**Ready to proceed? Start with Phase 1: RAG Components Setup.**