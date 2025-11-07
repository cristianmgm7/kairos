# Backend Architecture Refactor Implementation Plan

## Overview

Reorganize Firebase Functions backend from a monolithic 962-line index.ts into a clean, maintainable architecture with clear separation of concerns. Extract reusable modules, eliminate code duplication, and establish scalable boundaries between data access, domain logic, AI services, and storage utilities.

## Current State Analysis

**Existing Structure:**
- `functions/src/index.ts` - 962 lines containing all Cloud Functions
- `functions/src/genkit-config.ts` - AI service initialization (28 lines)
- `functions/src/monitoring.ts` - Metrics logging (28 lines)
- `functions/src/insights-helper.ts` - Insights analysis logic (191 lines)

**Key Problems Identified:**

1. **Mixed Concerns in index.ts:**
   - AI response generation (lines 23-235, 244-411)
   - Audio transcription (lines 501-568, 665-718, 573-659)
   - Media handling (lines 416-493)
   - Insights generation (lines 729-868, 873-960)
   - Firestore operations scattered throughout
   - Conversation history building duplicated

2. **Code Duplication:**
   - Conversation history loading: 2 implementations (lines 60-82, 290-306)
   - System prompt definition: duplicated (lines 85-87, 308-310)
   - AI message creation: duplicated (lines 171-186, 353-365)
   - Thread metadata updates: duplicated (lines 194-207, 373-386)
   - Transcription logic: 3 implementations (lines 533-546, 617-627, 689-701)
   - Error handling: repeated pattern in every function

3. **No Clear Boundaries:**
   - Business logic mixed with Firestore triggers
   - No separation between data access and domain logic
   - AI service calls scattered across functions
   - Storage utilities embedded in main file

## Desired End State

**Target Architecture:**
```
functions/src/
├── index.ts                          # Slim entry point (exports only)
├── config/
│   ├── genkit.ts                     # AI configuration
│   └── constants.ts                  # Shared constants, prompts, enums
├── data/
│   ├── models/
│   │   ├── message.ts                # Message types
│   │   ├── thread.ts                 # Thread types
│   │   └── insight.ts                # Insight types
│   └── repositories/
│       ├── message-repository.ts     # Message CRUD
│       ├── thread-repository.ts      # Thread CRUD
│       └── insight-repository.ts     # Insight CRUD
├── services/
│   ├── ai-service.ts                 # Genkit wrapper, AI calls
│   └── storage-service.ts            # Firebase Storage operations
├── domain/
│   ├── conversation/
│   │   ├── conversation-builder.ts   # Build conversation history
│   │   └── prompt-builder.ts         # Assemble prompts
│   ├── insights/
│   │   ├── insight-generator.ts      # Core insights logic
│   │   ├── keyword-extractor.ts      # Keyword analysis
│   │   └── ai-analyzer.ts            # AI-based analysis
│   └── media/
│       ├── transcription-service.ts  # Audio transcription
│       └── image-processor.ts        # Image handling
├── functions/
│   ├── message-triggers.ts           # processUserMessage, processTranscribedMessage
│   ├── transcription.ts              # transcribeAudio, triggerAudioTranscription, retryAiResponse
│   └── insights-triggers.ts          # generateInsight
├── monitoring/
│   └── metrics.ts                    # Metrics (existing)
└── utils/
    ├── storage-utils.ts              # Storage path parsing
    └── error-handlers.ts             # Shared error patterns
```

**Verification Criteria:**
- All Cloud Function signatures remain unchanged
- External behavior is identical (user-facing)
- No duplication - shared logic extracted once
- Clear dependency flow: Functions → Domain → Services → Data
- Each module has single responsibility
- TypeScript compilation passes
- Tests pass for all extracted modules

## What We're NOT Doing

- Not changing external Cloud Function APIs or signatures
- Not refactoring Flutter client code
- Not modifying Firestore schema or data structures
- Not changing AI model parameters or prompts (content stays same, just moved)
- Not adding new features (pure refactor)
- Not backfilling tests for existing untested code (only test new extractions)

## Implementation Approach

**Strategy:** Incremental extraction with phased deployment
- Extract one domain at a time
- Keep all functions working after each phase
- Deploy after each major phase to minimize risk
- Standardize duplicated logic during extraction
- Add tests for newly extracted modules

**Key Principles:**
- External behavior unchanged
- Internal consistency improved
- Repository pattern for data access
- Service layer for external dependencies (AI, Storage)
- Domain layer for business logic
- Functions layer for orchestration only

---

## Phase 1: Foundation & Configuration

### Overview
Create folder structure and extract shared configuration, constants, and types. No behavior changes, pure organization.

### Changes Required:

#### 1. Create Folder Structure
**Action**: Create new directories

```bash
mkdir -p functions/src/config
mkdir -p functions/src/data/models
mkdir -p functions/src/data/repositories
mkdir -p functions/src/services
mkdir -p functions/src/domain/conversation
mkdir -p functions/src/domain/insights
mkdir -p functions/src/domain/media
mkdir -p functions/src/functions
mkdir -p functions/src/utils
```

#### 2. Extract Constants
**File**: `functions/src/config/constants.ts`
**Changes**: Create new file with shared constants

```typescript
// System prompts
export const SYSTEM_PROMPT = `You are a helpful AI assistant in a personal journaling app called Kairos.
Be empathetic, supportive, and encouraging. Keep responses concise (2-3 sentences) unless the user asks for more detail.
Help users reflect on their thoughts and feelings.`;

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

// AI Processing Status
export enum AiProcessingStatus {
  PENDING = 0,
  PROCESSING = 1,
  COMPLETED = 2,
  FAILED = 3,
}

// Upload Status
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
```

#### 3. Rename and Move genkit-config.ts
**File**: `functions/src/config/genkit.ts`
**Changes**: Move `genkit-config.ts` to `config/genkit.ts`

```bash
mv functions/src/genkit-config.ts functions/src/config/genkit.ts
```

#### 4. Move monitoring.ts
**File**: `functions/src/monitoring/metrics.ts`
**Changes**: Move `monitoring.ts` to `monitoring/metrics.ts`

```bash
mkdir -p functions/src/monitoring
mv functions/src/monitoring.ts functions/src/monitoring/metrics.ts
```

#### 5. Update imports in index.ts
**File**: `functions/src/index.ts`
**Changes**: Update import paths

```typescript
// Old imports
import { getAI, geminiApiKey } from './genkit-config';
import { logAiMetrics } from './monitoring';

// New imports
import { getAI, geminiApiKey } from './config/genkit';
import { logAiMetrics } from './monitoring/metrics';
import {
  MessageRole,
  MessageType,
  AiProcessingStatus,
  SYSTEM_PROMPT,
  AI_CONFIG,
} from './config/constants';
```

### Success Criteria:

#### Automated Verification:
- [x] TypeScript compilation passes: `npm run build`
- [x] All imports resolve correctly
- [ ] No linting errors: `npm run lint` (if configured)

#### Manual Verification:
- [ ] Deploy to Firebase Functions: `npm run deploy`
- [ ] Test one user message in the app - AI responds correctly
- [ ] Test one audio message - transcription works
- [ ] Check logs for no import errors

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to Phase 2.

---

## Phase 2: Data Access Layer

### Overview
Extract Firestore operations into repositories with type-safe models. Standardize query patterns and eliminate direct Firestore access from business logic.

### Changes Required:

#### 1. Create Data Models
**File**: `functions/src/data/models/message.ts`
**Changes**: Define message types

```typescript
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
```

**File**: `functions/src/data/models/thread.ts`
**Changes**: Define thread types

```typescript
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
```

**File**: `functions/src/data/models/insight.ts`
**Changes**: Define insight types

```typescript
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
```

#### 2. Create Message Repository
**File**: `functions/src/data/repositories/message-repository.ts`
**Changes**: Extract message Firestore operations

```typescript
import * as admin from 'firebase-admin';
import {
  Message,
  CreateMessageInput,
  UpdateMessageInput,
  ConversationMessage,
} from '../models/message';

export class MessageRepository {
  private db: admin.firestore.Firestore;
  private collection: admin.firestore.CollectionReference;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
    this.collection = db.collection('journalMessages');
  }

  /**
   * Get a message by ID
   */
  async getById(messageId: string): Promise<Message | null> {
    const doc = await this.collection.doc(messageId).get();
    if (!doc.exists) return null;
    return doc.data() as Message;
  }

  /**
   * Create a new message
   */
  async create(input: CreateMessageInput): Promise<Message> {
    const ref = this.collection.doc();
    const now = Date.now();

    const message: Message = {
      id: ref.id,
      ...input,
      createdAtMillis: now,
      updatedAtMillis: now,
      isDeleted: false,
      version: 1,
      aiProcessingStatus: input.aiProcessingStatus ?? 0,
      uploadStatus: input.uploadStatus ?? 2,
    };

    await ref.set(message);
    return message;
  }

  /**
   * Update a message
   */
  async update(messageId: string, input: UpdateMessageInput): Promise<void> {
    await this.collection.doc(messageId).update({
      ...input,
      updatedAtMillis: input.updatedAtMillis ?? Date.now(),
    });
  }

  /**
   * Get conversation history for a thread
   */
  async getConversationHistory(
    threadId: string,
    userId: string,
    limit: number,
    excludeMessageId?: string
  ): Promise<ConversationMessage[]> {
    const snapshot = await this.collection
      .where('threadId', '==', threadId)
      .where('userId', '==', userId)
      .where('isDeleted', '==', false)
      .orderBy('createdAtMillis', 'asc')
      .limit(limit)
      .get();

    const roleMap = ['user', 'ai', 'system'];

    return snapshot.docs
      .filter(doc => doc.id !== excludeMessageId)
      .map(doc => {
        const data = doc.data();
        return {
          role: roleMap[data.role],
          content: data.content || data.transcription || '[media content]',
          createdAtMillis: data.createdAtMillis,
        };
      });
  }

  /**
   * Get messages for a thread in a time range
   */
  async getMessagesInRange(
    threadId: string,
    userId: string,
    startMillis: number,
    endMillis?: number
  ): Promise<Array<{ content: string; role: number; createdAtMillis: number }>> {
    let query = this.collection
      .where('threadId', '==', threadId)
      .where('userId', '==', userId)
      .where('isDeleted', '==', false)
      .where('createdAtMillis', '>=', startMillis)
      .orderBy('createdAtMillis', 'asc');

    const snapshot = await query.get();

    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        content: data.content || data.transcription || '',
        role: data.role,
        createdAtMillis: data.createdAtMillis,
      };
    });
  }

  /**
   * Count messages in a thread
   */
  async countMessagesInThread(threadId: string, userId: string): Promise<number> {
    const result = await this.collection
      .where('threadId', '==', threadId)
      .where('userId', '==', userId)
      .where('isDeleted', '==', false)
      .count()
      .get();

    return result.data().count;
  }
}
```

#### 3. Create Thread Repository
**File**: `functions/src/data/repositories/thread-repository.ts`
**Changes**: Extract thread Firestore operations

```typescript
import * as admin from 'firebase-admin';
import { Thread, UpdateThreadInput } from '../models/thread';

export class ThreadRepository {
  private db: admin.firestore.Firestore;
  private collection: admin.firestore.CollectionReference;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
    this.collection = db.collection('journalThreads');
  }

  /**
   * Get a thread by ID
   */
  async getById(threadId: string): Promise<Thread | null> {
    const doc = await this.collection.doc(threadId).get();
    if (!doc.exists) return null;
    return doc.data() as Thread;
  }

  /**
   * Update thread metadata
   */
  async update(threadId: string, input: UpdateThreadInput): Promise<void> {
    await this.collection.doc(threadId).update({
      ...input,
      updatedAtMillis: input.updatedAtMillis ?? Date.now(),
    });
  }

  /**
   * Update thread with recalculated message count
   */
  async updateWithMessageCount(
    threadId: string,
    messageCount: number,
    lastMessageAt: number
  ): Promise<void> {
    const now = Date.now();
    await this.collection.doc(threadId).update({
      messageCount,
      lastMessageAt,
      updatedAtMillis: now,
    });
  }
}
```

#### 4. Create Insight Repository
**File**: `functions/src/data/repositories/insight-repository.ts`
**Changes**: Extract insight Firestore operations

```typescript
import * as admin from 'firebase-admin';
import { Insight, CreateInsightInput, UpdateInsightInput } from '../models/insight';

export class InsightRepository {
  private db: admin.firestore.Firestore;
  private collection: admin.firestore.CollectionReference;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
    this.collection = db.collection('insights');
  }

  /**
   * Create a new insight
   */
  async create(input: CreateInsightInput): Promise<Insight> {
    const now = Date.now();
    const insight: Insight = {
      ...input,
      createdAtMillis: now,
      updatedAtMillis: now,
      isDeleted: false,
      version: 1,
    };

    await this.collection.doc(input.id).set(insight);
    return insight;
  }

  /**
   * Update an existing insight
   */
  async update(insightId: string, input: UpdateInsightInput): Promise<void> {
    await this.collection.doc(insightId).update({
      ...input,
      updatedAtMillis: input.updatedAtMillis ?? Date.now(),
    });
  }

  /**
   * Find recent insight for a thread
   */
  async findRecentThreadInsight(
    userId: string,
    threadId: string,
    afterMillis: number
  ): Promise<Insight | null> {
    const snapshot = await this.collection
      .where('userId', '==', userId)
      .where('threadId', '==', threadId)
      .where('periodEndMillis', '>=', afterMillis)
      .limit(1)
      .get();

    if (snapshot.empty) return null;
    return snapshot.docs[0].data() as Insight;
  }

  /**
   * Find recent global insight
   */
  async findRecentGlobalInsight(
    userId: string,
    afterMillis: number
  ): Promise<Insight | null> {
    const snapshot = await this.collection
      .where('userId', '==', userId)
      .where('threadId', '==', null)
      .where('periodEndMillis', '>=', afterMillis)
      .limit(1)
      .get();

    if (snapshot.empty) return null;
    return snapshot.docs[0].data() as Insight;
  }

  /**
   * Check if insight was recently updated (for debouncing)
   */
  async wasRecentlyUpdated(
    userId: string,
    threadId: string,
    afterMillis: number
  ): Promise<boolean> {
    const snapshot = await this.collection
      .where('userId', '==', userId)
      .where('threadId', '==', threadId)
      .where('updatedAtMillis', '>=', afterMillis)
      .limit(1)
      .get();

    return !snapshot.empty;
  }

  /**
   * Get all thread insights in a time range
   */
  async getThreadInsights(
    userId: string,
    afterMillis: number
  ): Promise<Insight[]> {
    const snapshot = await this.collection
      .where('userId', '==', userId)
      .where('threadId', '!=', null)
      .where('periodEndMillis', '>=', afterMillis)
      .get();

    return snapshot.docs.map(doc => doc.data() as Insight);
  }
}
```

#### 5. Create Repository Factory
**File**: `functions/src/data/repositories/index.ts`
**Changes**: Export all repositories

```typescript
import * as admin from 'firebase-admin';
import { MessageRepository } from './message-repository';
import { ThreadRepository } from './thread-repository';
import { InsightRepository } from './insight-repository';

// Singleton instances
let messageRepo: MessageRepository | null = null;
let threadRepo: ThreadRepository | null = null;
let insightRepo: InsightRepository | null = null;

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

export function getInsightRepository(db: admin.firestore.Firestore): InsightRepository {
  if (!insightRepo) {
    insightRepo = new InsightRepository(db);
  }
  return insightRepo;
}

// Export repository classes
export { MessageRepository, ThreadRepository, InsightRepository };
```

### Success Criteria:

#### Automated Verification:
- [ ] TypeScript compilation passes: `npm run build`
- [ ] All repository files compile without errors
- [ ] No linting errors

#### Manual Verification:
- [ ] Repository methods align with existing Firestore queries
- [ ] Type definitions match current data structures
- [ ] No breaking changes to data access patterns

**Implementation Note**: This phase creates the data layer but doesn't integrate it yet. Integration happens in later phases. After automated verification passes, proceed to Phase 3.

---

## Phase 3: Storage & Media Services

### Overview
Extract Firebase Storage utilities and consolidate transcription logic (3 duplicates → 1 service).

### Changes Required:

#### 1. Create Storage Utilities
**File**: `functions/src/utils/storage-utils.ts`
**Changes**: Extract storage path parsing from index.ts (lines 416-449)

```typescript
/**
 * Extract storage path from Firebase Storage URL
 * Handles multiple URL formats from Firebase Storage
 */
export function extractStoragePath(url: string): string {
  console.log(`Extracting storage path from URL: ${url}`);

  // Extract path from URLs like:
  // https://firebasestorage.googleapis.com/v0/b/bucket/o/path%2Fto%2Ffile.m4a?alt=media&token=...
  // https://storage.googleapis.com/bucket/path/to/file.m4a?X-Goog-...
  // https://firebasestorage.app/v0/b/bucket/o/path%2Fto%2Ffile.m4a?alt=media&token=...

  let match = url.match(/\/o\/(.+?)\?/);
  if (match) {
    const path = decodeURIComponent(match[1]);
    console.log(`Extracted path (format 1): ${path}`);
    return path;
  }

  // Try direct Google Storage URL format
  match = url.match(/storage\.googleapis\.com\/([^/]+)\/(.+?)(?:\?|$)/);
  if (match) {
    const path = decodeURIComponent(match[2]);
    console.log(`Extracted path (format 2): ${path}`);
    return path;
  }

  // Try firebasestorage.app format
  match = url.match(/firebasestorage\.app\/v0\/b\/[^/]+\/o\/(.+?)(?:\?|$)/);
  if (match) {
    const path = decodeURIComponent(match[1]);
    console.log(`Extracted path (format 3): ${path}`);
    return path;
  }

  console.error(`Failed to extract path from URL: ${url}`);
  throw new Error(`Invalid Firebase Storage URL format: ${url}`);
}
```

#### 2. Create Storage Service
**File**: `functions/src/services/storage-service.ts`
**Changes**: Extract file download logic from index.ts (lines 455-493)

```typescript
import * as admin from 'firebase-admin';
import { extractStoragePath } from '../utils/storage-utils';

export class StorageService {
  private bucket: admin.storage.Bucket;

  constructor() {
    this.bucket = admin.storage().bucket();
  }

  /**
   * Download file from Firebase Storage and convert to base64 data URL
   * Works for both audio and image files
   */
  async getFileAsDataUrl(storageUrl: string, contentType: string): Promise<string> {
    try {
      const storagePath = extractStoragePath(storageUrl);
      console.log(`Attempting to download from path: ${storagePath}`);

      const file = this.bucket.file(storagePath);

      // Check if file exists
      const [exists] = await file.exists();
      if (!exists) {
        console.error(`File does not exist at path: ${storagePath}`);
        throw new Error(`File not found: ${storagePath}`);
      }

      // Get file metadata
      const [metadata] = await file.getMetadata();
      console.log(`File metadata - size: ${metadata.size}, contentType: ${metadata.contentType}`);

      // Download file as buffer
      const [buffer] = await file.download();

      console.log(`Downloaded file: ${storagePath}, size: ${buffer.length} bytes`);

      // Log first few bytes to debug
      if (buffer.length < 100) {
        console.warn(
          `File is suspiciously small (${buffer.length} bytes). Content: ${buffer
            .toString('utf8')
            .substring(0, 100)}`
        );
      }

      // Convert to base64 data URL
      const base64Data = buffer.toString('base64');
      const dataUrl = `data:${contentType};base64,${base64Data}`;

      return dataUrl;
    } catch (error) {
      console.error('Failed to download file:', error);
      throw error;
    }
  }

  /**
   * Download image from Firebase Storage
   */
  async getImageAsDataUrl(storageUrl: string): Promise<string> {
    return this.getFileAsDataUrl(storageUrl, 'image/jpeg');
  }

  /**
   * Download audio from Firebase Storage
   */
  async getAudioAsDataUrl(storageUrl: string): Promise<string> {
    return this.getFileAsDataUrl(storageUrl, 'audio/mp4');
  }
}

// Singleton instance
let storageServiceInstance: StorageService | null = null;

export function getStorageService(): StorageService {
  if (!storageServiceInstance) {
    storageServiceInstance = new StorageService();
  }
  return storageServiceInstance;
}
```

### Success Criteria:

#### Automated Verification:
- [ ] TypeScript compilation passes: `npm run build`
- [ ] Storage utilities compile without errors
- [ ] No linting errors

#### Manual Verification:
- [ ] Storage path extraction logic matches original
- [ ] File download logic preserves all error handling
- [ ] No breaking changes to storage operations

**Implementation Note**: This phase creates storage services but doesn't integrate them yet. After automated verification passes, proceed to Phase 4.

---

## Phase 4: AI Service Layer

### Overview
Extract Genkit interaction wrapper, centralize AI response generation patterns, and consolidate error handling. This provides a clean abstraction for all AI operations.

### Changes Required:

#### 1. Create AI Service
**File**: `functions/src/services/ai-service.ts`
**Changes**: Create centralized AI service wrapper

```typescript
import { googleAI } from '@genkit-ai/google-genai';
import { getAI } from '../config/genkit';
import { getStorageService } from './storage-service';
import { AI_CONFIG } from '../config/constants';

export interface AiGenerateOptions {
  prompt: any[];
  temperature?: number;
  maxOutputTokens?: number;
}

export interface AiResponse {
  text: string;
  usage?: {
    inputTokens?: number;
    outputTokens?: number;
  };
}

export interface TranscriptionResult {
  text: string;
}

export class AiService {
  private apiKey: string;
  private storageService: ReturnType<typeof getStorageService>;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
    this.storageService = getStorageService();
  }

  /**
   * Generate AI response with Genkit
   */
  async generate(options: AiGenerateOptions): Promise<AiResponse> {
    const ai = getAI(this.apiKey);

    const response = await ai.generate({
      prompt: options.prompt,
      config: {
        temperature: options.temperature ?? AI_CONFIG.temperature,
        maxOutputTokens: options.maxOutputTokens ?? AI_CONFIG.maxOutputTokens,
      },
    });

    return {
      text: response.text,
      usage: response.usage,
    };
  }

  /**
   * Transcribe audio using Gemini 2.0 Flash
   */
  async transcribeAudio(audioUrl: string): Promise<TranscriptionResult> {
    const ai = getAI(this.apiKey);

    // Download audio and convert to data URL
    const audioDataUrl = await this.storageService.getAudioAsDataUrl(audioUrl);

    const { text } = await ai.generate({
      model: googleAI.model('gemini-2.0-flash'),
      prompt: [
        {
          text: 'Transcribe this audio recording accurately. Output only the transcription text, no additional commentary.',
        },
        { media: { url: audioDataUrl, contentType: 'audio/mp4' } },
      ],
    });

    return { text };
  }

  /**
   * Generate response for image message
   */
  async generateImageResponse(
    imageUrl: string,
    conversationContext: string
  ): Promise<AiResponse> {
    const imageDataUrl = await this.storageService.getImageAsDataUrl(imageUrl);

    const promptParts: any[] = [
      { text: conversationContext },
      { text: 'User sent this image:' },
      { media: { url: imageDataUrl, contentType: 'image/jpeg' } },
      { text: 'Describe what you see and respond naturally to the user.' },
      { text: 'Assistant:' },
    ];

    return this.generate({ prompt: promptParts });
  }

  /**
   * Generate response for text or audio message
   */
  async generateTextResponse(
    userMessage: string,
    conversationContext: string
  ): Promise<AiResponse> {
    const promptParts: any[] = [
      { text: conversationContext },
      { text: `User: ${userMessage}` },
      { text: 'Assistant:' },
    ];

    return this.generate({ prompt: promptParts });
  }

  /**
   * Analyze messages for insights
   */
  async analyzeForInsights(prompt: string): Promise<AiResponse> {
    return this.generate({
      prompt: [{ text: prompt }],
      temperature: 0.3,
      maxOutputTokens: 500,
    });
  }
}

// Factory function
export function createAiService(apiKey: string): AiService {
  return new AiService(apiKey);
}
```

### Success Criteria:

#### Automated Verification:
- [ ] TypeScript compilation passes: `npm run build`
- [ ] AI service compiles without errors
- [ ] No linting errors

#### Manual Verification:
- [ ] AI service methods match existing Genkit usage patterns
- [ ] Transcription logic consolidated correctly
- [ ] Image and text response patterns preserved

**Implementation Note**: This phase creates the AI service abstraction. Integration happens in later phases. After automated verification passes, proceed to Phase 5.

---

## Phase 5: Domain Logic - Conversation

### Overview
Extract conversation history building and prompt assembly logic. Eliminate duplication between processUserMessage and processTranscribedMessage.

### Changes Required:

#### 1. Create Conversation Builder
**File**: `functions/src/domain/conversation/conversation-builder.ts`
**Changes**: Extract conversation history logic (consolidate lines 60-82 and 290-306)

```typescript
import { getMessageRepository } from '../../data/repositories';
import { ConversationMessage } from '../../data/models/message';
import { AI_CONFIG } from '../../config/constants';
import * as admin from 'firebase-admin';

export class ConversationBuilder {
  private messageRepo: ReturnType<typeof getMessageRepository>;

  constructor(db: admin.firestore.Firestore) {
    this.messageRepo = getMessageRepository(db);
  }

  /**
   * Load conversation history for a thread
   * Standardized version - removes inconsistencies between old implementations
   */
  async loadHistory(
    threadId: string,
    userId: string,
    excludeMessageId?: string,
    limit: number = AI_CONFIG.conversationHistoryLimit
  ): Promise<ConversationMessage[]> {
    return this.messageRepo.getConversationHistory(
      threadId,
      userId,
      limit,
      excludeMessageId
    );
  }

  /**
   * Build conversation context string from history
   */
  buildContextString(history: ConversationMessage[]): string {
    return history.map(msg => `${msg.role}: ${msg.content}`).join('\n');
  }

  /**
   * Build full conversation history with context string
   */
  async buildConversationContext(
    threadId: string,
    userId: string,
    excludeMessageId?: string
  ): Promise<string> {
    const history = await this.loadHistory(threadId, userId, excludeMessageId);
    return this.buildContextString(history);
  }
}

// Factory function
export function createConversationBuilder(
  db: admin.firestore.Firestore
): ConversationBuilder {
  return new ConversationBuilder(db);
}
```

#### 2. Create Prompt Builder
**File**: `functions/src/domain/conversation/prompt-builder.ts`
**Changes**: Extract prompt assembly logic

```typescript
import { SYSTEM_PROMPT, MessageType } from '../../config/constants';

export interface PromptContext {
  systemPrompt?: string;
  conversationContext?: string;
  userMessage?: string;
  userTranscription?: string;
  imageUrl?: string;
}

export class PromptBuilder {
  /**
   * Build multimodal prompt parts for AI generation
   */
  buildPromptParts(context: PromptContext): any[] {
    const parts: any[] = [];

    // Add system prompt
    parts.push({ text: context.systemPrompt ?? SYSTEM_PROMPT });

    // Add conversation history
    if (context.conversationContext) {
      parts.push({ text: `Conversation history:\n${context.conversationContext}` });
    }

    // Add user message (text, transcription, or image)
    if (context.userMessage) {
      parts.push({ text: `User: ${context.userMessage}` });
    } else if (context.userTranscription) {
      parts.push({ text: `User said: "${context.userTranscription}"` });
    }

    // Add assistant prompt
    parts.push({ text: 'Assistant:' });

    return parts;
  }

  /**
   * Build prompt parts for text message
   */
  buildTextPrompt(conversationContext: string, userMessage: string): any[] {
    return this.buildPromptParts({
      conversationContext,
      userMessage,
    });
  }

  /**
   * Build prompt parts for audio message (with transcription)
   */
  buildAudioPrompt(conversationContext: string, transcription: string): any[] {
    return this.buildPromptParts({
      conversationContext,
      userTranscription: transcription,
    });
  }
}

// Singleton instance
let promptBuilderInstance: PromptBuilder | null = null;

export function getPromptBuilder(): PromptBuilder {
  if (!promptBuilderInstance) {
    promptBuilderInstance = new PromptBuilder();
  }
  return promptBuilderInstance;
}
```

### Success Criteria:

#### Automated Verification:
- [ ] TypeScript compilation passes: `npm run build`
- [ ] Conversation builder compiles without errors
- [ ] Prompt builder compiles without errors
- [ ] No linting errors

#### Manual Verification:
- [ ] Conversation history logic matches original behavior
- [ ] Prompt building preserves all message types
- [ ] No breaking changes to conversation flow

**Implementation Note**: This phase creates conversation domain logic. Integration happens in Phase 6. After automated verification passes, proceed to Phase 5.

---

## Phase 6: Domain Logic - Insights

### Overview
Reorganize insights generation and move existing insights-helper into new structure. Maintain current logic.

### Changes Required:

#### 1. Extract Keyword Extractor
**File**: `functions/src/domain/insights/keyword-extractor.ts`
**Changes**: Move from insights-helper.ts (lines 16-49)

```typescript
interface MessageData {
  content: string;
  role: number;
  createdAtMillis: number;
}

/**
 * Extract keywords from messages using simple frequency analysis
 */
export function extractKeywords(messages: MessageData[]): string[] {
  const stopWords = new Set([
    'the',
    'a',
    'an',
    'and',
    'or',
    'but',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'from',
    'as',
    'is',
    'was',
    'are',
    'were',
    'been',
    'be',
    'have',
    'has',
    'had',
    'do',
    'does',
    'did',
    'will',
    'would',
    'could',
    'should',
    'may',
    'might',
    'can',
    'i',
    'you',
    'he',
    'she',
    'it',
    'we',
    'they',
    'my',
    'your',
    'his',
    'her',
    'its',
    'our',
    'their',
    'this',
    'that',
    'these',
    'those',
    'am',
    'me',
    'im',
    'ive',
    'dont',
    'cant',
    'wont',
    'didnt',
  ]);

  const wordFreq = new Map<string, number>();

  messages.forEach(msg => {
    if (!msg.content) return;

    const words = msg.content
      .toLowerCase()
      .replace(/[^\w\s]/g, '')
      .split(/\s+/)
      .filter(word => word.length > 3 && !stopWords.has(word));

    words.forEach(word => {
      wordFreq.set(word, (wordFreq.get(word) || 0) + 1);
    });
  });

  // Sort by frequency and return top 10
  return Array.from(wordFreq.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([word]) => word);
}
```

#### 2. Extract AI Analyzer
**File**: `functions/src/domain/insights/ai-analyzer.ts`
**Changes**: Move from insights-helper.ts (lines 51-130)

```typescript
interface MessageData {
  content: string;
  role: number;
  createdAtMillis: number;
}

interface InsightAnalysis {
  moodScore: number;
  dominantEmotion: number;
  keywords: string[];
  aiThemes: string[];
  summary: string;
}

/**
 * Analyze messages using Gemini to extract mood, emotion, themes, and summary
 */
export async function analyzeMessagesWithAI(
  ai: any,
  messages: MessageData[]
): Promise<InsightAnalysis> {
  const conversationText = messages
    .map(msg => {
      const role = msg.role === 0 ? 'User' : 'Assistant';
      return `${role}: ${msg.content || '[media message]'}`;
    })
    .join('\n');

  const prompt = `You are an empathetic journaling companion analyzing a user's emotional journey in the Kairos app. Your role is to provide supportive, encouraging insights that help users understand their progress.

IMPORTANT GUIDELINES:
- Be warm, supportive, and encouraging (never diagnostic or clinical)
- Focus on growth, progress, and positive patterns
- Acknowledge challenges with compassion
- Use "you" language to make it personal and supportive
- Return a direct numerical mood score (0.0 to 1.0)

Conversation to analyze:
${conversationText}

Provide your analysis in the following JSON format (respond with ONLY valid JSON, no markdown or code blocks):
{
  "moodScore": <number between 0.0 and 1.0, where 0.0 is very low/difficult and 1.0 is very high/positive>,
  "dominantEmotion": <number: 0=joy, 1=calm, 2=neutral, 3=sadness, 4=stress, 5=anger, 6=fear, 7=excitement>,
  "aiThemes": [<array of 3-5 supportive themes like "Building resilience" or "Practicing self-compassion">],
  "summary": "<2-3 sentence supportive summary emphasizing growth, progress, and emotional awareness. Use warm, encouraging language.>"
}

Example of good summary tone:
"You've been showing great self-awareness in your reflections this week. Even when facing challenges, you're taking time to process your feelings thoughtfully. This kind of mindful engagement with your emotions is a powerful step in your journey."

Example of bad summary tone (too clinical):
"Patient exhibits moderate anxiety symptoms with occasional depressive episodes. Cognitive patterns suggest need for intervention."`;

  const response = await ai.generate({
    prompt: [{ text: prompt }],
    config: {
      temperature: 0.3,
      maxOutputTokens: 500,
    },
  });

  try {
    // Extract JSON from response (handle potential markdown wrapping)
    let jsonText = response.text.trim();

    // Remove markdown code blocks if present
    if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```json?\n?/g, '').replace(/```\n?$/g, '');
    }

    const analysis = JSON.parse(jsonText);

    return {
      moodScore: Math.max(0, Math.min(1, analysis.moodScore)),
      dominantEmotion: analysis.dominantEmotion,
      keywords: [],
      aiThemes: analysis.aiThemes.slice(0, 5),
      summary: analysis.summary,
    };
  } catch (error) {
    console.error('Failed to parse AI analysis:', error);
    console.error('Raw response:', response.text);

    // Fallback to neutral values
    return {
      moodScore: 0.5,
      dominantEmotion: 2, // neutral
      keywords: [],
      aiThemes: ['Unable to analyze conversation'],
      summary: 'Analysis unavailable at this time.',
    };
  }
}
```

#### 3. Create Insight Aggregator
**File**: `functions/src/domain/insights/insight-aggregator.ts`
**Changes**: Move from insights-helper.ts (lines 132-190)

```typescript
/**
 * Aggregate multiple per-thread insights into a global insight
 */
export function aggregateInsights(threadInsights: any[]): any {
  if (threadInsights.length === 0) {
    return null;
  }

  // Average mood score
  const avgMoodScore =
    threadInsights.reduce((sum, ins) => sum + ins.moodScore, 0) /
    threadInsights.length;

  // Count emotions and find dominant
  const emotionCounts = new Map<number, number>();
  threadInsights.forEach(ins => {
    const emotion = ins.dominantEmotion;
    emotionCounts.set(emotion, (emotionCounts.get(emotion) || 0) + 1);
  });
  const dominantEmotion = Array.from(emotionCounts.entries()).sort(
    (a, b) => b[1] - a[1]
  )[0][0];

  // Merge keywords (deduplicate and take top 10)
  const allKeywords = new Set<string>();
  threadInsights.forEach(ins => {
    ins.keywords.forEach((kw: string) => allKeywords.add(kw));
  });
  const keywords = Array.from(allKeywords).slice(0, 10);

  // Merge AI themes (deduplicate and take top 5)
  const allThemes = new Set<string>();
  threadInsights.forEach(ins => {
    ins.aiThemes.forEach((theme: string) => allThemes.add(theme));
  });
  const aiThemes = Array.from(allThemes).slice(0, 5);

  // Create aggregated summary
  const summary = `Across ${threadInsights.length} conversation${
    threadInsights.length > 1 ? 's' : ''
  }, your overall mood has been ${
    avgMoodScore > 0.6 ? 'positive' : avgMoodScore < 0.4 ? 'challenging' : 'neutral'
  }. Key themes include: ${aiThemes.join(', ')}.`;

  // Sum message counts
  const messageCount = threadInsights.reduce(
    (sum, ins) => sum + ins.messageCount,
    0
  );

  return {
    moodScore: avgMoodScore,
    dominantEmotion,
    keywords,
    aiThemes,
    summary,
    messageCount,
  };
}
```

#### 4. Create Insight Generator Service
**File**: `functions/src/domain/insights/insight-generator.ts`
**Changes**: Orchestrate insight generation logic

```typescript
import * as admin from 'firebase-admin';
import { getMessageRepository, getInsightRepository } from '../../data/repositories';
import { extractKeywords } from './keyword-extractor';
import { analyzeMessagesWithAI } from './ai-analyzer';
import { aggregateInsights } from './insight-aggregator';
import { INSIGHTS_CONFIG, InsightType } from '../../config/constants';

export class InsightGenerator {
  private db: admin.firestore.Firestore;
  private messageRepo: ReturnType<typeof getMessageRepository>;
  private insightRepo: ReturnType<typeof getInsightRepository>;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
    this.messageRepo = getMessageRepository(db);
    this.insightRepo = getInsightRepository(db);
  }

  /**
   * Generate or update thread-level insight
   */
  async generateThreadInsight(
    ai: any,
    threadId: string,
    userId: string,
    now: number
  ): Promise<void> {
    const threeDaysAgo = now - INSIGHTS_CONFIG.threeDaysMs;
    const oneHourAgo = now - INSIGHTS_CONFIG.oneHourMs;
    const oneDayAgo = now - INSIGHTS_CONFIG.oneDayMs;

    // Debounce check
    const wasRecentlyUpdated = await this.insightRepo.wasRecentlyUpdated(
      userId,
      threadId,
      oneHourAgo
    );

    if (wasRecentlyUpdated) {
      console.log(`Skipping insight generation - updated within last hour for thread ${threadId}`);
      return;
    }

    // Get recent messages
    const messages = await this.messageRepo.getMessagesInRange(
      threadId,
      userId,
      threeDaysAgo
    );

    if (messages.length === 0) {
      console.log('No recent messages found for insight generation');
      return;
    }

    // Extract keywords
    const keywords = extractKeywords(messages);

    // Analyze with AI
    const analysis = await analyzeMessagesWithAI(ai, messages);
    analysis.keywords = keywords;

    // Determine period
    const periodStart = messages[0].createdAtMillis;
    const periodEnd = now;

    // Check for recent insight (within 24 hours)
    const recentInsight = await this.insightRepo.findRecentThreadInsight(
      userId,
      threadId,
      oneDayAgo
    );

    if (recentInsight) {
      // Update existing
      await this.insightRepo.update(recentInsight.id, {
        periodEndMillis: periodEnd,
        moodScore: analysis.moodScore,
        dominantEmotion: analysis.dominantEmotion,
        keywords: analysis.keywords,
        aiThemes: analysis.aiThemes,
        summary: analysis.summary,
        messageCount: messages.length,
      });

      console.log(`Updated existing insight ${recentInsight.id}`);
    } else {
      // Create new
      const insightId = `${userId}_${threadId}_${periodStart}`;
      await this.insightRepo.create({
        id: insightId,
        userId,
        type: InsightType.THREAD,
        threadId,
        periodStartMillis: periodStart,
        periodEndMillis: periodEnd,
        moodScore: analysis.moodScore,
        dominantEmotion: analysis.dominantEmotion,
        keywords: analysis.keywords,
        aiThemes: analysis.aiThemes,
        summary: analysis.summary,
        messageCount: messages.length,
      });

      console.log(`Created new insight ${insightId}`);
    }
  }

  /**
   * Generate or update global aggregated insight
   */
  async generateGlobalInsight(userId: string, now: number): Promise<void> {
    const threeDaysAgo = now - INSIGHTS_CONFIG.threeDaysMs;
    const oneDayAgo = now - INSIGHTS_CONFIG.oneDayMs;

    // Get all thread insights from last 3 days
    const threadInsights = await this.insightRepo.getThreadInsights(userId, threeDaysAgo);

    if (threadInsights.length === 0) {
      console.log('No thread insights found for global aggregation');
      return;
    }

    // Aggregate
    const aggregated = aggregateInsights(threadInsights);
    if (!aggregated) return;

    // Find earliest periodStart
    const periodStart = Math.min(...threadInsights.map(ins => ins.periodStartMillis));

    // Check for recent global insight
    const recentGlobal = await this.insightRepo.findRecentGlobalInsight(userId, oneDayAgo);

    if (recentGlobal) {
      // Update existing
      await this.insightRepo.update(recentGlobal.id, {
        periodEndMillis: now,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
      });

      console.log(`Updated global insight ${recentGlobal.id}`);
    } else {
      // Create new
      const globalInsightId = `${userId}_global_${periodStart}`;
      await this.insightRepo.create({
        id: globalInsightId,
        userId,
        type: InsightType.GLOBAL,
        threadId: null,
        periodStartMillis: periodStart,
        periodEndMillis: now,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
      });

      console.log(`Created global insight ${globalInsightId}`);
    }
  }
}

// Factory function
export function createInsightGenerator(
  db: admin.firestore.Firestore
): InsightGenerator {
  return new InsightGenerator(db);
}
```

### Success Criteria:

#### Automated Verification:
- [ ] TypeScript compilation passes: `npm run build`
- [ ] All insights domain modules compile without errors
- [ ] No linting errors

#### Manual Verification:
- [ ] Insights logic matches original insights-helper behavior
- [ ] Keyword extraction preserved
- [ ] AI analysis preserved
- [ ] Aggregation logic preserved

**Implementation Note**: This phase reorganizes insights domain logic. Integration happens in Phase 7. After automated verification passes, proceed to Phase 7.

---

## Phase 7: Refactor Cloud Functions

### Overview
Update all Cloud Functions to use new modules. Remove duplicated code from index.ts and slim down to orchestration only. This is the integration phase.

### Changes Required:

#### 1. Create Message Triggers Module
**File**: `functions/src/functions/message-triggers.ts`
**Changes**: Extract and refactor processUserMessage and processTranscribedMessage

```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { getMessageRepository, getThreadRepository } from '../data/repositories';
import { createConversationBuilder } from '../domain/conversation/conversation-builder';
import { getPromptBuilder } from '../domain/conversation/prompt-builder';
import { logAiMetrics } from '../monitoring/metrics';
import { MessageRole, MessageType, AiProcessingStatus } from '../config/constants';

const db = admin.firestore();

/**
 * Firestore trigger: When a new message is created with role=user,
 * generate an AI response and save it to the same thread.
 */
export const processUserMessage = onDocumentCreated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async event => {
    const messageData = event.data?.data();
    if (!messageData) {
      console.warn('No message data found');
      return;
    }

    // Only process user messages
    if (messageData.role !== MessageRole.USER) {
      console.log('Skipping non-user message');
      return;
    }

    const messageId = event.params.messageId;
    const threadId = messageData.threadId as string;
    const userId = messageData.userId as string;
    const messageType = messageData.messageType as number;

    console.log(`Processing message ${messageId} from thread ${threadId}`);

    const startTime = Date.now();
    const messageRepo = getMessageRepository(db);
    const threadRepo = getThreadRepository(db);
    const conversationBuilder = createConversationBuilder(db);
    const promptBuilder = getPromptBuilder();
    const aiService = createAiService(geminiApiKey.value());

    try {
      // Update status to processing
      await messageRepo.update(messageId, {
        aiProcessingStatus: AiProcessingStatus.PROCESSING,
      });

      // Build conversation context
      const conversationContext = await conversationBuilder.buildConversationContext(
        threadId,
        userId,
        messageId
      );

      // Handle different message types
      let aiResponse;

      if (messageType === MessageType.IMAGE) {
        if (!messageData.storageUrl) {
          console.log('Image still uploading, waiting...');
          return;
        }
        aiResponse = await aiService.generateImageResponse(
          messageData.storageUrl,
          conversationContext
        );
      } else if (messageType === MessageType.AUDIO) {
        if (!messageData.transcription) {
          console.log('Waiting for audio transcription');
          return;
        }
        const promptParts = promptBuilder.buildAudioPrompt(
          conversationContext,
          messageData.transcription
        );
        aiResponse = await aiService.generate({ prompt: promptParts });
      } else {
        // Text message
        const userPrompt = messageData.content || '';
        const promptParts = promptBuilder.buildTextPrompt(conversationContext, userPrompt);
        aiResponse = await aiService.generate({ prompt: promptParts });
      }

      const latencyMs = Date.now() - startTime;

      // Log metrics
      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: messageType === 0 ? 'text' : messageType === 1 ? 'image' : 'audio',
        inputTokens: aiResponse.usage?.inputTokens,
        outputTokens: aiResponse.usage?.outputTokens,
        latencyMs,
        success: true,
      });

      // Save AI response
      await messageRepo.create({
        threadId,
        userId,
        role: MessageRole.AI,
        messageType: MessageType.TEXT,
        content: aiResponse.text,
        aiProcessingStatus: AiProcessingStatus.COMPLETED,
        uploadStatus: 2,
      });

      // Update original message status
      await messageRepo.update(messageId, {
        aiProcessingStatus: AiProcessingStatus.COMPLETED,
      });

      // Update thread metadata
      const messageCount = await messageRepo.countMessagesInThread(threadId, userId);
      await threadRepo.updateWithMessageCount(threadId, messageCount, Date.now());

      console.log(`AI response generated for message ${messageId}`);
    } catch (error) {
      console.error(`Error processing message ${messageId}:`, error);

      const latencyMs = Date.now() - startTime;

      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: messageType === 0 ? 'text' : messageType === 1 ? 'image' : 'audio',
        latencyMs,
        success: false,
        errorMessage: error instanceof Error ? error.message : String(error),
      });

      await messageRepo.update(messageId, {
        aiProcessingStatus: AiProcessingStatus.FAILED,
      });
    }
  }
);

/**
 * Firestore trigger: When transcription is added to an audio message,
 * generate the AI response.
 */
export const processTranscribedMessage = onDocumentUpdated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async event => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    // Only trigger if transcription was just added
    if (
      afterData.role !== MessageRole.USER ||
      afterData.messageType !== MessageType.AUDIO ||
      beforeData.transcription ||
      !afterData.transcription ||
      afterData.aiProcessingStatus === AiProcessingStatus.COMPLETED
    ) {
      return;
    }

    const messageId = event.params.messageId;
    const threadId = afterData.threadId as string;
    const userId = afterData.userId as string;

    console.log(`Transcription added to message ${messageId}, generating AI response`);

    const startTime = Date.now();
    const messageRepo = getMessageRepository(db);
    const threadRepo = getThreadRepository(db);
    const conversationBuilder = createConversationBuilder(db);
    const promptBuilder = getPromptBuilder();
    const aiService = createAiService(geminiApiKey.value());

    try {
      await messageRepo.update(messageId, {
        aiProcessingStatus: AiProcessingStatus.PROCESSING,
      });

      // Build conversation context
      const conversationContext = await conversationBuilder.buildConversationContext(
        threadId,
        userId,
        messageId
      );

      // Generate AI response
      const promptParts = promptBuilder.buildAudioPrompt(
        conversationContext,
        afterData.transcription
      );
      const aiResponse = await aiService.generate({ prompt: promptParts });

      const latencyMs = Date.now() - startTime;

      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: 'audio',
        inputTokens: aiResponse.usage?.inputTokens,
        outputTokens: aiResponse.usage?.outputTokens,
        latencyMs,
        success: true,
      });

      // Create AI response message
      await messageRepo.create({
        threadId,
        userId,
        role: MessageRole.AI,
        messageType: MessageType.TEXT,
        content: aiResponse.text,
        aiProcessingStatus: AiProcessingStatus.COMPLETED,
      });

      // Update original message
      await messageRepo.update(messageId, {
        aiProcessingStatus: AiProcessingStatus.COMPLETED,
      });

      // Update thread
      const messageCount = await messageRepo.countMessagesInThread(threadId, userId);
      await threadRepo.updateWithMessageCount(threadId, messageCount, Date.now());

      console.log(`AI response generated for transcribed message ${messageId}`);
    } catch (error) {
      console.error(`Error processing transcribed message ${messageId}:`, error);

      const latencyMs = Date.now() - startTime;

      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: 'audio',
        latencyMs,
        success: false,
        errorMessage: error instanceof Error ? error.message : String(error),
      });

      await messageRepo.update(messageId, {
        aiProcessingStatus: AiProcessingStatus.FAILED,
      });
    }
  }
);
```

#### 2. Create Transcription Module
**File**: `functions/src/functions/transcription.ts`
**Changes**: Extract transcribeAudio, triggerAudioTranscription, retryAiResponse

```typescript
import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { getMessageRepository } from '../data/repositories';
import { MessageRole, MessageType, AiProcessingStatus } from '../config/constants';

const db = admin.firestore();

/**
 * Callable function to transcribe audio files using Gemini
 */
export const transcribeAudio = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async request => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { audioUrl, messageId } = request.data as {
      audioUrl: string;
      messageId: string;
    };

    if (!audioUrl || !messageId) {
      throw new HttpsError('invalid-argument', 'audioUrl and messageId required');
    }

    console.log(`Transcribing audio for message ${messageId}`);

    const messageRepo = getMessageRepository(db);
    const aiService = createAiService(geminiApiKey.value());

    try {
      // Verify message ownership
      const message = await messageRepo.getById(messageId);
      if (!message || message.userId !== userId) {
        throw new HttpsError('permission-denied', 'Message not found or access denied');
      }

      // Transcribe audio
      const result = await aiService.transcribeAudio(audioUrl);

      // Update message with transcription
      await messageRepo.update(messageId, {
        transcription: result.text,
      });

      console.log(`Transcription complete for message ${messageId}`);

      return { success: true, transcription: result.text };
    } catch (error) {
      console.error(`Transcription failed for message ${messageId}:`, error);

      await messageRepo.update(messageId, {
        aiProcessingStatus: AiProcessingStatus.FAILED,
      });

      const message = error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `Transcription failed: ${message}`);
    }
  }
);

/**
 * Firestore trigger: When audio message is updated with storageUrl,
 * automatically trigger transcription
 */
export const triggerAudioTranscription = onDocumentUpdated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async event => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    // Check if this is an audio message with newly added storageUrl
    const isAudioMessage = afterData.messageType === MessageType.AUDIO;
    const storageUrlAdded = !beforeData.storageUrl && afterData.storageUrl;
    const noTranscription = !afterData.transcription;

    if (isAudioMessage && storageUrlAdded && noTranscription) {
      const messageId = event.params.messageId;
      console.log(`Auto-transcribing audio message ${messageId}`);

      const messageRepo = getMessageRepository(db);
      const aiService = createAiService(geminiApiKey.value());

      try {
        const result = await aiService.transcribeAudio(afterData.storageUrl);

        await messageRepo.update(messageId, {
          transcription: result.text,
        });

        console.log(`Auto-transcription complete for ${messageId}`);
      } catch (error) {
        console.error(`Auto-transcription failed for ${messageId}:`, error);

        await messageRepo.update(messageId, {
          aiProcessingStatus: AiProcessingStatus.FAILED,
        });
      }
    }
  }
);

/**
 * Callable function to retry AI response generation for a failed message
 */
export const retryAiResponse = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
  },
  async request => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { messageId } = request.data as { messageId: string };

    if (!messageId) {
      throw new HttpsError('invalid-argument', 'messageId required');
    }

    console.log(`Retrying AI response for message ${messageId}`);

    const messageRepo = getMessageRepository(db);
    const aiService = createAiService(geminiApiKey.value());

    try {
      const message = await messageRepo.getById(messageId);
      if (!message) {
        throw new HttpsError('not-found', 'Message not found');
      }

      if (message.userId !== userId) {
        throw new HttpsError('permission-denied', 'Access denied');
      }

      if (message.role !== MessageRole.USER) {
        throw new HttpsError('invalid-argument', 'Can only retry user messages');
      }

      // If audio message without transcription, retry transcription first
      if (
        message.messageType === MessageType.AUDIO &&
        !message.transcription &&
        message.storageUrl
      ) {
        console.log(`Retrying transcription for audio message ${messageId}`);

        try {
          const result = await aiService.transcribeAudio(message.storageUrl);

          await messageRepo.update(messageId, {
            transcription: result.text,
            aiProcessingStatus: AiProcessingStatus.PENDING,
          });

          console.log(`Transcription retry successful for ${messageId}`);
        } catch (transcriptionError) {
          console.error(`Transcription retry failed for ${messageId}:`, transcriptionError);
          throw new HttpsError('internal', 'Transcription retry failed. Please try again.');
        }
      } else {
        // For text/image or audio with transcription, reset AI status
        await messageRepo.update(messageId, {
          aiProcessingStatus: AiProcessingStatus.PENDING,
        });
      }

      console.log(`Reset message ${messageId} to pending for retry`);

      return { success: true, message: 'AI response retry initiated' };
    } catch (error) {
      console.error(`Retry AI response failed for message ${messageId}:`, error);
      if (error instanceof HttpsError) {
        throw error;
      }
      const message = error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `Retry failed: ${message}`);
    }
  }
);
```

#### 3. Create Insights Triggers Module
**File**: `functions/src/functions/insights-triggers.ts`
**Changes**: Extract generateInsight

```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { createInsightGenerator } from '../domain/insights/insight-generator';
import { MessageRole } from '../config/constants';

const db = admin.firestore();

/**
 * Firestore trigger: When a new AI message is created,
 * generate or update insights for the thread and global view
 */
export const generateInsight = onDocumentCreated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async event => {
    const messageData = event.data?.data();
    if (!messageData) return;

    // Only process AI messages
    if (messageData.role !== MessageRole.AI) {
      console.log('Skipping non-AI message for insight generation');
      return;
    }

    const threadId = messageData.threadId as string;
    const userId = messageData.userId as string;
    const now = Date.now();

    console.log(`Generating insight for thread ${threadId}`);

    const aiService = createAiService(geminiApiKey.value());
    const insightGenerator = createInsightGenerator(db);

    try {
      // Generate thread insight
      await insightGenerator.generateThreadInsight(
        aiService,
        threadId,
        userId,
        now
      );

      // Generate global insight
      await insightGenerator.generateGlobalInsight(userId, now);

      console.log(`Insight generation complete for thread ${threadId}`);
    } catch (error) {
      console.error('Error generating insight:', error);
    }
  }
);
```

#### 4. Update Main index.ts
**File**: `functions/src/index.ts`
**Changes**: Slim down to exports only

```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all Cloud Functions
export { processUserMessage, processTranscribedMessage } from './functions/message-triggers';
export {
  transcribeAudio,
  triggerAudioTranscription,
  retryAiResponse,
} from './functions/transcription';
export { generateInsight } from './functions/insights-triggers';
```

#### 5. Delete old insights-helper.ts
**Action**: Remove obsolete file

```bash
rm functions/src/insights-helper.ts
```

### Success Criteria:

#### Automated Verification:
- [ ] TypeScript compilation passes: `npm run build`
- [ ] All function modules compile without errors
- [ ] No linting errors
- [ ] Build output shows all functions exported

#### Manual Verification:
- [ ] Deploy to Firebase Functions: `npm run deploy`
- [ ] Test text message - AI responds correctly
- [ ] Test audio message - transcription + AI response works
- [ ] Test image message - AI describes image and responds
- [ ] Test retry functionality - failed messages can be retried
- [ ] Check insights generation - thread and global insights created
- [ ] Verify thread metadata updates correctly
- [ ] Check logs for no errors or warnings

**Implementation Note**: This is the critical integration phase. After completing this phase and all automated verification passes, pause here for thorough manual testing from the human before proceeding to Phase 8.

---

## Phase 8: Testing & Validation

### Overview
Add unit tests for extracted modules and integration tests for critical paths. Validate entire refactor.

### Changes Required:

#### 1. Create Repository Tests
**File**: `functions/src/test/repositories/message-repository.test.ts`
**Changes**: Add unit tests for MessageRepository

```typescript
import { expect } from 'chai';
import * as admin from 'firebase-admin';
import { MessageRepository } from '../../data/repositories/message-repository';

// Mock Firestore for testing
describe('MessageRepository', () => {
  let messageRepo: MessageRepository;

  beforeEach(() => {
    // Initialize with test database
    // Note: Use Firebase emulator for testing
    const db = admin.firestore();
    messageRepo = new MessageRepository(db);
  });

  it('should create a message with correct defaults', async () => {
    const input = {
      threadId: 'test-thread',
      userId: 'test-user',
      role: 0,
      messageType: 0,
      content: 'Test message',
    };

    const message = await messageRepo.create(input);

    expect(message.id).to.exist;
    expect(message.threadId).to.equal('test-thread');
    expect(message.userId).to.equal('test-user');
    expect(message.content).to.equal('Test message');
    expect(message.isDeleted).to.be.false;
    expect(message.version).to.equal(1);
  });

  it('should load conversation history correctly', async () => {
    // Test conversation history building
    // Add test implementation
  });

  it('should count messages in thread correctly', async () => {
    // Test message counting
    // Add test implementation
  });
});
```

#### 2. Create Conversation Builder Tests
**File**: `functions/src/test/domain/conversation-builder.test.ts`
**Changes**: Add unit tests for ConversationBuilder

```typescript
import { expect } from 'chai';
import { ConversationBuilder } from '../../domain/conversation/conversation-builder';

describe('ConversationBuilder', () => {
  it('should build conversation context string correctly', () => {
    // Test context string building
    // Add test implementation
  });

  it('should exclude specified message from history', async () => {
    // Test message exclusion
    // Add test implementation
  });
});
```

#### 3. Create Keyword Extractor Tests
**File**: `functions/src/test/domain/keyword-extractor.test.ts`
**Changes**: Add unit tests for keyword extraction

```typescript
import { expect } from 'chai';
import { extractKeywords } from '../../domain/insights/keyword-extractor';

describe('extractKeywords', () => {
  it('should extract top keywords from messages', () => {
    const messages = [
      { content: 'feeling happy today happy happy', role: 0, createdAtMillis: 1000 },
      { content: 'work was productive productive', role: 0, createdAtMillis: 2000 },
    ];

    const keywords = extractKeywords(messages);

    expect(keywords).to.include('happy');
    expect(keywords).to.include('productive');
  });

  it('should filter out stop words', () => {
    const messages = [
      { content: 'the quick brown fox', role: 0, createdAtMillis: 1000 },
    ];

    const keywords = extractKeywords(messages);

    expect(keywords).to.not.include('the');
  });

  it('should filter out short words', () => {
    const messages = [{ content: 'a bb ccc dddd', role: 0, createdAtMillis: 1000 }];

    const keywords = extractKeywords(messages);

    expect(keywords).to.not.include('a');
    expect(keywords).to.not.include('bb');
    expect(keywords).to.not.include('ccc');
    expect(keywords).to.include('dddd');
  });
});
```

#### 4. Create Storage Utils Tests
**File**: `functions/src/test/utils/storage-utils.test.ts`
**Changes**: Add unit tests for storage path extraction

```typescript
import { expect } from 'chai';
import { extractStoragePath } from '../../utils/storage-utils';

describe('extractStoragePath', () => {
  it('should extract path from firebasestorage.googleapis.com URL', () => {
    const url =
      'https://firebasestorage.googleapis.com/v0/b/bucket/o/path%2Fto%2Ffile.m4a?alt=media&token=abc';
    const path = extractStoragePath(url);
    expect(path).to.equal('path/to/file.m4a');
  });

  it('should extract path from storage.googleapis.com URL', () => {
    const url = 'https://storage.googleapis.com/bucket/path/to/file.m4a?X-Goog-test';
    const path = extractStoragePath(url);
    expect(path).to.equal('path/to/file.m4a');
  });

  it('should extract path from firebasestorage.app URL', () => {
    const url =
      'https://firebasestorage.app/v0/b/bucket/o/path%2Fto%2Ffile.m4a?alt=media';
    const path = extractStoragePath(url);
    expect(path).to.equal('path/to/file.m4a');
  });

  it('should throw error for invalid URL', () => {
    const url = 'https://example.com/file.m4a';
    expect(() => extractStoragePath(url)).to.throw('Invalid Firebase Storage URL format');
  });
});
```

#### 5. Create Integration Test
**File**: `functions/src/test/integration/message-flow.test.ts`
**Changes**: Add integration test for full message flow

```typescript
import { expect } from 'chai';
import * as admin from 'firebase-admin';

describe('Message Flow Integration', () => {
  it('should process user message and generate AI response', async () => {
    // Test full flow:
    // 1. Create user message
    // 2. Trigger processUserMessage
    // 3. Verify AI response created
    // 4. Verify thread metadata updated
    // Add test implementation
  });

  it('should handle audio message with transcription', async () => {
    // Test audio flow:
    // 1. Create audio message with storageUrl
    // 2. Trigger transcription
    // 3. Verify transcription added
    // 4. Trigger AI response
    // 5. Verify AI response created
    // Add test implementation
  });
});
```

#### 6. Update package.json test script
**File**: `functions/package.json`
**Changes**: Ensure test script includes new test files

```json
{
  "scripts": {
    "test": "mocha --require ts-node/register 'src/test/**/*.test.ts' --timeout 10000",
    "test:watch": "npm test -- --watch",
    "test:unit": "mocha --require ts-node/register 'src/test/{domain,data,utils}/**/*.test.ts' --timeout 10000",
    "test:integration": "mocha --require ts-node/register 'src/test/integration/**/*.test.ts' --timeout 10000"
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All unit tests pass: `npm run test:unit`
- [ ] All integration tests pass: `npm run test:integration`
- [ ] Full test suite passes: `npm test`
- [ ] TypeScript compilation passes: `npm run build`
- [ ] No linting errors

#### Manual Verification:
- [ ] Deploy to production: `npm run deploy`
- [ ] Test all message types in production (text, audio, image)
- [ ] Verify insights generation works in production
- [ ] Monitor logs for 24 hours - no errors
- [ ] Check Firebase console - all functions deployed correctly
- [ ] Verify performance metrics - no degradation in latency
- [ ] Test retry functionality in production
- [ ] Confirm thread metadata updates correctly

**Implementation Note**: After completing this phase and all verification passes, the refactor is complete. Document any findings and close out the project.

---

## Testing Strategy

### Unit Tests
Focus on:
- Repository CRUD operations
- Conversation history building
- Keyword extraction logic
- Storage path parsing
- Prompt building

### Integration Tests
Focus on:
- Full message processing flow (user → AI response)
- Audio transcription flow
- Insights generation flow
- Thread metadata updates
- Error handling and retry logic

### Manual Testing Steps
For each phase deployment:
1. Send text message via app - verify AI responds
2. Send audio message via app - verify transcription + AI response
3. Send image message via app - verify AI describes image
4. Trigger retry on failed message - verify retry works
5. Check insights in app - verify thread and global insights appear
6. Monitor Firebase console logs - verify no errors
7. Check Firestore data - verify data structure unchanged

## Performance Considerations

- Repository pattern may add slight overhead, but improves testability
- Conversation history loading standardized to prevent over-fetching
- AI service layer enables future caching/optimization
- No changes to AI model parameters - performance should remain identical
- Monitor Cloud Functions execution time before/after refactor

## Migration Notes

**Deployment Strategy:**
- Deploy after each phase (1-8)
- Use Firebase Functions deployment: `npm run deploy`
- Monitor logs after each deployment
- Roll back if issues detected (use previous deployment)

**Rollback Plan:**
- Keep previous working version in git
- If issues arise, revert to previous commit
- Redeploy: `npm run deploy`

**No Database Migrations Required:**
- Pure code refactor - no Firestore schema changes
- No data migration needed
- Existing data remains compatible

## References

- Original index.ts: `functions/src/index.ts` (962 lines)
- Existing helpers: `genkit-config.ts`, `monitoring.ts`, `insights-helper.ts`
- Firebase Functions docs: https://firebase.google.com/docs/functions
- Repository pattern: https://martinfowler.com/eaaCatalog/repository.html
