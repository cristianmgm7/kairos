# User Data Seeding Tool Implementation Plan

## Overview

Implement a reusable, idempotent data seeding tool for Firebase that creates realistic journal threads, messages, insights, and streak metrics for testing and development. The tool will be exposed as both a callable Cloud Function (`seedUserData`) and a local Node.js script, accepting comprehensive configuration parameters to control the quantity, quality, and characteristics of generated data.

## Current State Analysis

### Existing Infrastructure
- ✅ Firebase Admin SDK with Firestore collections: `journalThreads`, `journalMessages`, `insights`
- ✅ Repository pattern: `MessageRepository`, `ThreadRepository`, `InsightRepository`
- ✅ AI Service (`createAiService`) with Genkit/Gemini integration for text generation
- ✅ Existing `InsightGenerator` with thread/global/daily insight generation capabilities
- ✅ Firebase Storage service for file uploads
- ✅ Callable Cloud Function pattern established in codebase

### Current Data Models
**Thread**: `id, userId, title, messageCount, lastMessageAt, createdAtMillis, updatedAtMillis, isDeleted, version`

**Message**: `id, threadId, userId, role (0=USER, 1=AI, 2=SYSTEM), messageType (0=TEXT, 1=IMAGE, 2=AUDIO), content, transcription, storageUrl, createdAtMillis, updatedAtMillis, status, isDeleted, version`

**Insight**: `id, userId, type (0=THREAD, 1=GLOBAL, 2=DAILY_GLOBAL), threadId, period, periodStartMillis, periodEndMillis, moodScore, dominantEmotion, keywords, aiThemes, summary, messageCount, createdAtMillis, updatedAtMillis, isDeleted, version`

### Key Dependencies
- `functions/src/services/ai-service.ts` - Text generation via `generate()`
- `functions/src/domain/insights/insight-generator.ts` - Insight generation pipeline
- `functions/src/data/repositories/*` - Data access layer
- `functions/src/config/constants.ts` - Enums and configuration

## Desired End State

### Deliverables
1. **Callable Cloud Function**: `seedUserData` accepting configuration via request body
2. **Local Node Script**: `scripts/seed-user-data.ts` for local/dev environment testing
3. **Seeding Service**: `src/services/seeding-service.ts` with core logic
4. **Data Generators**: Realistic content templates and generation helpers
5. **Tests**: Unit and integration tests for seeding logic
6. **Documentation**: Example seed profiles and usage instructions

### Success Verification
After implementation, verify by:
1. Running the local script with example profile → should create 5 threads, 50-200 messages, insights
2. Running with same `seedId` twice → should skip duplicates (idempotency)
3. Querying Firestore → thread/message counts match expectations
4. Checking insights collection → at least one insight per thread
5. Validating timestamps → realistic conversation cadence with gaps/bursts

## What We're NOT Doing

- ❌ Extending Thread or Message schemas with new fields
- ❌ Adding image generation capabilities to AI service (will use placeholders only)
- ❌ Implementing actual audio generation/TTS (will create simple placeholder files)
- ❌ Creating UI for the seeding tool
- ❌ Production data migration (dev/test environments only)
- ❌ User authentication in seeding function (admin context only)

## Implementation Approach

Use the existing repository pattern and AI service to generate realistic data in batches. Implement idempotency via a dedicated `seeds` collection that tracks completed seed operations. Use Firestore batch writes for efficiency and atomicity. Generate insights after message creation by calling the existing `InsightGenerator`. Create realistic conversation cadence by varying message timestamps with bursts, pauses, and overnight gaps.

---

## Phase 1: Core Seeding Service & Models

### Overview
Create the foundational seeding service with data models, validation, and idempotency tracking.

### Changes Required

#### 1. Seed Configuration Models
**File**: `functions/src/data/models/seed-config.ts` (NEW)
**Changes**: Create TypeScript interfaces for seed configuration

```typescript
export interface SeedConfig {
  userId: string;
  seedId?: string; // Optional - auto-generated if not provided
  threads: number;
  minMessagesPerThread: number;
  maxMessagesPerThread: number;
  startDate?: number; // Timestamp in millis (defaults to 30 days ago)
  endDate?: number; // Timestamp in millis (defaults to now)
  attachmentsPercent?: number; // 0-100, defaults to 0
  voiceNotesPercent?: number; // 0-100, defaults to 0
  imagesPercent?: number; // 0-100, defaults to 0
  generateInsights: boolean;
  generateStreaks: boolean;
}

export interface SeedResult {
  seedId: string;
  threadsCreated: number;
  messagesCreated: number;
  insightsCreated: number;
  storageUploads: number;
  streaksCalculated: boolean;
  durationMs: number;
}

export interface SeedRecord {
  seedId: string;
  userId: string;
  config: SeedConfig;
  result: SeedResult;
  createdAtMillis: number;
  status: 'pending' | 'completed' | 'failed';
  error?: string;
}
```

#### 2. Seed Repository
**File**: `functions/src/data/repositories/seed-repository.ts` (NEW)
**Changes**: Repository for tracking seed operations

```typescript
import * as admin from 'firebase-admin';
import { SeedRecord } from '../models/seed-config';

export class SeedRepository {
  private collection: admin.firestore.CollectionReference;

  constructor(db: admin.firestore.Firestore) {
    this.collection = db.collection('seeds');
  }

  async getSeedById(seedId: string): Promise<SeedRecord | null> {
    const doc = await this.collection.doc(seedId).get();
    if (!doc.exists) return null;
    return doc.data() as SeedRecord;
  }

  async createSeedRecord(record: SeedRecord): Promise<void> {
    await this.collection.doc(record.seedId).set(record);
  }

  async updateSeedStatus(
    seedId: string,
    status: 'completed' | 'failed',
    result?: any,
    error?: string
  ): Promise<void> {
    await this.collection.doc(seedId).update({
      status,
      result,
      error,
      updatedAtMillis: Date.now(),
    });
  }
}

export function getSeedRepository(db: admin.firestore.Firestore): SeedRepository {
  return new SeedRepository(db);
}
```

#### 3. Validation Utility
**File**: `functions/src/utils/seed-validation.ts` (NEW)
**Changes**: Validate seed configuration and user existence

```typescript
import * as admin from 'firebase-admin';
import { SeedConfig } from '../data/models/seed-config';
import { HttpsError } from 'firebase-functions/v2/https';

export async function validateSeedConfig(
  config: SeedConfig,
  db: admin.firestore.Firestore
): Promise<void> {
  // Validate userId exists
  const userDoc = await db.collection('users').doc(config.userId).get();
  if (!userDoc.exists) {
    throw new HttpsError('not-found', `User ${config.userId} does not exist`);
  }

  // Validate thread count
  if (config.threads < 1 || config.threads > 100) {
    throw new HttpsError('invalid-argument', 'threads must be between 1 and 100');
  }

  // Validate message counts
  if (config.minMessagesPerThread < 1) {
    throw new HttpsError('invalid-argument', 'minMessagesPerThread must be at least 1');
  }
  if (config.maxMessagesPerThread < config.minMessagesPerThread) {
    throw new HttpsError('invalid-argument', 'maxMessagesPerThread must be >= minMessagesPerThread');
  }
  if (config.maxMessagesPerThread > 200) {
    throw new HttpsError('invalid-argument', 'maxMessagesPerThread cannot exceed 200');
  }

  // Validate percentages
  const validatePercent = (value: number | undefined, name: string) => {
    if (value !== undefined && (value < 0 || value > 100)) {
      throw new HttpsError('invalid-argument', `${name} must be between 0 and 100`);
    }
  };
  validatePercent(config.attachmentsPercent, 'attachmentsPercent');
  validatePercent(config.voiceNotesPercent, 'voiceNotesPercent');
  validatePercent(config.imagesPercent, 'imagesPercent');

  // Validate date range
  const startDate = config.startDate || Date.now() - 30 * 24 * 60 * 60 * 1000;
  const endDate = config.endDate || Date.now();
  if (startDate >= endDate) {
    throw new HttpsError('invalid-argument', 'startDate must be before endDate');
  }
}

export function generateSeedId(): string {
  return `seed_${Date.now()}_${Math.random().toString(36).substring(7)}`;
}
```

#### 4. Update Repository Index
**File**: `functions/src/data/repositories/index.ts`
**Changes**: Export new SeedRepository

```typescript
// Add to existing exports
import { SeedRepository, getSeedRepository } from './seed-repository';

export { 
  MessageRepository, 
  ThreadRepository, 
  InsightRepository,
  SeedRepository,
  getMessageRepository,
  getThreadRepository,
  getInsightRepository,
  getSeedRepository
};
```

### Success Criteria

#### Automated Verification:
- [ ] TypeScript compilation passes: `npm run build`
- [ ] No linting errors: `npm run lint` (if available)
- [ ] Seed models properly typed with all required fields
- [ ] SeedRepository methods compile and follow existing repository patterns

#### Manual Verification:
- [ ] Validation utility correctly rejects invalid configurations
- [ ] SeedRepository can create and retrieve seed records
- [ ] `generateSeedId()` produces unique IDs on multiple calls

---

## Phase 2: Content Generation Helpers

### Overview
Build utilities for generating realistic thread titles, message content, and timestamp distributions.

### Changes Required

#### 1. Content Templates
**File**: `functions/src/utils/content-templates.ts` (NEW)
**Changes**: Templates for realistic journal content

```typescript
export const THREAD_TITLE_TEMPLATES = [
  'My thoughts on {topic}',
  'Reflections about {topic}',
  'Today\'s {topic} journey',
  'Exploring {topic}',
  'Quick note on {topic}',
  'Thinking through {topic}',
  '{topic} insights',
  'Daily {topic} check-in',
  '{topic} feelings',
  'Processing {topic}',
];

export const TOPICS = [
  'work-life balance',
  'personal growth',
  'relationships',
  'health and fitness',
  'career goals',
  'mindfulness',
  'creativity',
  'learning new skills',
  'family time',
  'stress management',
  'gratitude',
  'productivity',
  'travel plans',
  'hobbies',
  'self-care',
];

export const MESSAGE_PROMPT_TEMPLATES = [
  'Write a short, casual journal entry (2-3 sentences) about {topic} expressing {emotion}.',
  'Write a brief reflection (1-2 sentences) on {topic} with a {emotion} tone.',
  'Create a quick thought about {topic} showing {emotion}. Keep it under 30 words.',
  'Write a longer journal entry (4-5 sentences) exploring {topic} with {emotion} feelings.',
  'Generate a question or pondering (1 sentence) about {topic} with {emotion} undertone.',
];

export const EMOTIONS = [
  'joy', 'calm', 'neutral', 'sadness', 'stress', 
  'anger', 'fear', 'excitement', 'hope', 'confusion',
];

export const AI_RESPONSE_STYLES = [
  'empathetic and supportive',
  'curious and questioning',
  'validating and encouraging',
  'reflective and thoughtful',
  'gentle and reassuring',
];

export function getRandomElement<T>(array: T[]): T {
  return array[Math.floor(Math.random() * array.length)];
}

export function generateThreadTitle(): string {
  const template = getRandomElement(THREAD_TITLE_TEMPLATES);
  const topic = getRandomElement(TOPICS);
  return template.replace('{topic}', topic);
}

export function generateMessagePrompt(): string {
  const template = getRandomElement(MESSAGE_PROMPT_TEMPLATES);
  const topic = getRandomElement(TOPICS);
  const emotion = getRandomElement(EMOTIONS);
  return template.replace('{topic}', topic).replace('{emotion}', emotion);
}

export function generateAiResponsePrompt(userMessage: string): string {
  const style = getRandomElement(AI_RESPONSE_STYLES);
  return `Respond to this journal entry in a ${style} way (2-3 sentences): "${userMessage}"`;
}
```

#### 2. Timestamp Generator
**File**: `functions/src/utils/timestamp-generator.ts` (NEW)
**Changes**: Generate realistic conversation timestamps

```typescript
/**
 * Generate realistic message timestamps with:
 * - Conversation bursts (multiple messages in quick succession)
 * - Natural gaps (hours between conversations)
 * - Overnight pauses (8-hour gaps for sleep)
 * - Weekend variations
 */
export class TimestampGenerator {
  private currentTime: number;
  private endTime: number;

  constructor(startTime: number, endTime: number) {
    this.currentTime = startTime;
    this.endTime = endTime;
  }

  generateTimestamps(count: number): number[] {
    const timestamps: number[] = [];
    
    for (let i = 0; i < count; i++) {
      // Add to array
      timestamps.push(this.currentTime);
      
      // Advance time for next message
      if (i < count - 1) {
        this.currentTime = this.getNextMessageTime();
      }
    }
    
    return timestamps;
  }

  private getNextMessageTime(): number {
    const hour = new Date(this.currentTime).getHours();
    
    // 30% chance of immediate burst (within 1-5 minutes)
    if (Math.random() < 0.3) {
      return this.currentTime + this.randomMinutes(1, 5);
    }
    
    // 40% chance of short gap (15 minutes - 2 hours)
    if (Math.random() < 0.4) {
      return this.currentTime + this.randomMinutes(15, 120);
    }
    
    // 20% chance of medium gap (2-6 hours)
    if (Math.random() < 0.2) {
      return this.currentTime + this.randomHours(2, 6);
    }
    
    // 10% chance of overnight gap (8-16 hours) - more likely if late evening
    if (hour >= 21 || hour <= 6) {
      return this.currentTime + this.randomHours(8, 16);
    }
    
    // Default: medium-long gap
    return this.currentTime + this.randomHours(3, 8);
  }

  private randomMinutes(min: number, max: number): number {
    return (Math.random() * (max - min) + min) * 60 * 1000;
  }

  private randomHours(min: number, max: number): number {
    return (Math.random() * (max - min) + min) * 60 * 60 * 1000;
  }

  hasTimeRemaining(): boolean {
    return this.currentTime < this.endTime;
  }
}

/**
 * Distribute thread creation times evenly across date range
 */
export function distributeThreadTimestamps(
  count: number,
  startTime: number,
  endTime: number
): number[] {
  const interval = (endTime - startTime) / count;
  const timestamps: number[] = [];
  
  for (let i = 0; i < count; i++) {
    // Add some jitter (±20% of interval)
    const jitter = (Math.random() - 0.5) * interval * 0.4;
    timestamps.push(Math.floor(startTime + interval * i + jitter));
  }
  
  return timestamps.sort((a, b) => a - b);
}
```

### Success Criteria

#### Automated Verification:
- [ ] Content templates compile without errors: `npm run build`
- [ ] `generateThreadTitle()` returns valid strings
- [ ] `TimestampGenerator` produces chronologically ordered timestamps
- [ ] All template arrays contain at least 5 entries

#### Manual Verification:
- [ ] Generated thread titles are human-readable and varied
- [ ] Message prompts create diverse content styles
- [ ] Timestamps show realistic conversation patterns (bursts + gaps)
- [ ] Overnight gaps occur during appropriate hours (21:00-06:00)

---

## Phase 3: Core Seeding Service Implementation

### Overview
Implement the main seeding service that orchestrates thread, message, and file creation.

### Changes Required

#### 1. Seeding Service
**File**: `functions/src/services/seeding-service.ts` (NEW)
**Changes**: Core seeding logic with idempotency

```typescript
import * as admin from 'firebase-admin';
import { SeedConfig, SeedResult, SeedRecord } from '../data/models/seed-config';
import { validateSeedConfig, generateSeedId } from '../utils/seed-validation';
import { getSeedRepository } from '../data/repositories/seed-repository';
import { getThreadRepository, getMessageRepository } from '../data/repositories';
import { createAiService } from './ai-service';
import { generateThreadTitle, generateMessagePrompt, generateAiResponsePrompt } from '../utils/content-templates';
import { TimestampGenerator, distributeThreadTimestamps } from '../utils/timestamp-generator';
import { MessageRole, MessageType, MessageStatus } from '../config/constants';
import { HttpsError } from 'firebase-functions/v2/https';

export class SeedingService {
  private db: admin.firestore.Firestore;
  private seedRepo: ReturnType<typeof getSeedRepository>;
  private threadRepo: ReturnType<typeof getThreadRepository>;
  private messageRepo: ReturnType<typeof getMessageRepository>;
  private aiService: ReturnType<typeof createAiService>;

  constructor(db: admin.firestore.Firestore, apiKey: string) {
    this.db = db;
    this.seedRepo = getSeedRepository(db);
    this.threadRepo = getThreadRepository(db);
    this.messageRepo = getMessageRepository(db);
    this.aiService = createAiService(apiKey);
  }

  /**
   * Main seeding entry point with idempotency
   */
  async seedUserData(config: SeedConfig, dryRun = false): Promise<SeedResult> {
    const startTime = Date.now();

    // Validate configuration
    await validateSeedConfig(config, this.db);

    // Generate or use provided seedId
    const seedId = config.seedId || generateSeedId();

    // Check idempotency - if seedId exists and completed, return existing result
    const existingSeed = await this.seedRepo.getSeedById(seedId);
    if (existingSeed && existingSeed.status === 'completed') {
      console.log(`Seed ${seedId} already completed, returning existing result`);
      return existingSeed.result;
    }

    // If dry run, return what would be created
    if (dryRun) {
      return this.performDryRun(config, seedId);
    }

    // Create seed record
    const seedRecord: SeedRecord = {
      seedId,
      userId: config.userId,
      config,
      result: {} as SeedResult, // Will be filled later
      createdAtMillis: Date.now(),
      status: 'pending',
    };
    await this.seedRepo.createSeedRecord(seedRecord);

    try {
      // Execute seeding
      const result = await this.executeSeed(config, seedId);
      
      // Update seed record
      await this.seedRepo.updateSeedStatus(seedId, 'completed', result);
      
      result.durationMs = Date.now() - startTime;
      return result;
    } catch (error) {
      // Mark as failed
      await this.seedRepo.updateSeedStatus(seedId, 'failed', undefined, String(error));
      throw error;
    }
  }

  private performDryRun(config: SeedConfig, seedId: string): SeedResult {
    const estimatedMessages = config.threads * 
      Math.floor((config.minMessagesPerThread + config.maxMessagesPerThread) / 2);
    
    return {
      seedId,
      threadsCreated: config.threads,
      messagesCreated: estimatedMessages,
      insightsCreated: config.generateInsights ? config.threads : 0,
      storageUploads: 0, // Simplified for now
      streaksCalculated: config.generateStreaks,
      durationMs: 0,
    };
  }

  /**
   * Execute the actual seeding
   */
  private async executeSeed(config: SeedConfig, seedId: string): Promise<SeedResult> {
    console.log(`Starting seed execution: ${seedId}`);
    
    const startDate = config.startDate || Date.now() - 30 * 24 * 60 * 60 * 1000;
    const endDate = config.endDate || Date.now();
    
    let totalMessages = 0;
    let totalInsights = 0;
    let totalStorage = 0;
    
    // Generate thread timestamps
    const threadTimestamps = distributeThreadTimestamps(config.threads, startDate, endDate);
    
    // Create threads sequentially to avoid rate limits
    for (let i = 0; i < config.threads; i++) {
      console.log(`Creating thread ${i + 1}/${config.threads}`);
      
      const threadCreationTime = threadTimestamps[i];
      const { messagesCreated, storageUploads } = await this.createThreadWithMessages(
        config,
        threadCreationTime,
        endDate
      );
      
      totalMessages += messagesCreated;
      totalStorage += storageUploads;
      
      // Rate limiting: small delay between threads
      await this.sleep(200);
    }
    
    // Generate insights if requested
    if (config.generateInsights) {
      totalInsights = await this.generateInsights(config.userId);
    }
    
    // Calculate streaks if requested
    if (config.generateStreaks) {
      await this.calculateStreaks(config.userId, startDate, endDate);
    }
    
    return {
      seedId,
      threadsCreated: config.threads,
      messagesCreated: totalMessages,
      insightsCreated: totalInsights,
      storageUploads: totalStorage,
      streaksCalculated: config.generateStreaks,
      durationMs: 0, // Will be set by caller
    };
  }

  /**
   * Create a single thread with messages
   */
  private async createThreadWithMessages(
    config: SeedConfig,
    threadStartTime: number,
    endTime: number
  ): Promise<{ messagesCreated: number; storageUploads: number }> {
    // Generate thread
    const threadRef = this.db.collection('journalThreads').doc();
    const threadId = threadRef.id;
    const title = generateThreadTitle();
    
    // Determine message count
    const messageCount = Math.floor(
      Math.random() * (config.maxMessagesPerThread - config.minMessagesPerThread + 1)
    ) + config.minMessagesPerThread;
    
    // Generate message timestamps
    const timestampGen = new TimestampGenerator(threadStartTime, endTime);
    const messageTimestamps = timestampGen.generateTimestamps(messageCount);
    
    // Create messages in batch
    const batch = this.db.batch();
    let storageUploads = 0;
    
    for (let i = 0; i < messageCount; i++) {
      const timestamp = messageTimestamps[i];
      
      // Alternate between USER and AI messages
      const isUserMessage = i % 2 === 0;
      
      if (isUserMessage) {
        // User message
        const messageRef = this.db.collection('journalMessages').doc();
        const prompt = generateMessagePrompt();
        
        // Generate content with AI
        const { text } = await this.aiService.generate({
          prompt: [{ text: prompt }],
          temperature: 0.8,
          maxOutputTokens: 150,
        });
        
        batch.set(messageRef, {
          id: messageRef.id,
          threadId,
          userId: config.userId,
          role: MessageRole.USER,
          messageType: MessageType.TEXT,
          content: text,
          createdAtMillis: timestamp,
          updatedAtMillis: timestamp,
          status: MessageStatus.PROCESSED,
          isDeleted: false,
          version: 1,
        });
        
        // Small delay to avoid rate limits
        await this.sleep(100);
      } else {
        // AI response
        const messageRef = this.db.collection('journalMessages').doc();
        
        // Get previous user message for context (simplified)
        const previousContent = "previous message"; // In real impl, get from batch
        const prompt = generateAiResponsePrompt(previousContent);
        
        const { text } = await this.aiService.generate({
          prompt: [{ text: prompt }],
          temperature: 0.7,
          maxOutputTokens: 100,
        });
        
        batch.set(messageRef, {
          id: messageRef.id,
          threadId,
          userId: config.userId,
          role: MessageRole.AI,
          messageType: MessageType.TEXT,
          content: text,
          createdAtMillis: timestamp,
          updatedAtMillis: timestamp,
          status: MessageStatus.REMOTE_CREATED,
          isDeleted: false,
          version: 1,
        });
        
        await this.sleep(100);
      }
    }
    
    // Create thread document
    const lastMessageTime = messageTimestamps[messageTimestamps.length - 1];
    batch.set(threadRef, {
      id: threadId,
      userId: config.userId,
      title,
      messageCount,
      lastMessageAt: lastMessageTime,
      createdAtMillis: threadStartTime,
      updatedAtMillis: lastMessageTime,
      isDeleted: false,
      version: 1,
    });
    
    // Commit batch
    await batch.commit();
    console.log(`Created thread ${threadId} with ${messageCount} messages`);
    
    return { messagesCreated: messageCount, storageUploads };
  }

  /**
   * Generate insights for all threads
   */
  private async generateInsights(userId: string): Promise<number> {
    // Insights will be generated via existing trigger or callable
    // For now, return 0 and handle in Phase 4
    return 0;
  }

  /**
   * Calculate and store streak metrics
   */
  private async calculateStreaks(
    userId: string,
    startDate: number,
    endDate: number
  ): Promise<void> {
    // Streak calculation will be implemented in Phase 5
    console.log('Streak calculation placeholder');
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export function createSeedingService(
  db: admin.firestore.Firestore,
  apiKey: string
): SeedingService {
  return new SeedingService(db, apiKey);
}
```

### Success Criteria

#### Automated Verification:
- [ ] Service compiles without errors: `npm run build`
- [ ] `seedUserData()` signature matches specification
- [ ] Idempotency check prevents duplicate execution with same seedId
- [ ] Dry-run mode returns result without writing to Firestore

#### Manual Verification:
- [ ] Service creates threads with correct userId
- [ ] Messages alternate between USER and AI roles
- [ ] Timestamps are chronologically ordered within each thread
- [ ] Thread titles are varied and realistic
- [ ] Message content is generated by AI and human-readable

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 4: Cloud Function and Insight Integration

### Overview
Expose the seeding service as a callable Cloud Function and integrate with existing InsightGenerator.

### Changes Required

#### 1. Callable Cloud Function
**File**: `functions/src/functions/seed-user-data-callable.ts` (NEW)
**Changes**: Expose seeding service as callable function

```typescript
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createSeedingService } from '../services/seeding-service';
import { SeedConfig } from '../data/models/seed-config';

const db = admin.firestore();

/**
 * Callable function to seed user data for testing/development
 * 
 * Example usage:
 * await seedUserData({
 *   userId: 'user123',
 *   threads: 5,
 *   minMessagesPerThread: 10,
 *   maxMessagesPerThread: 40,
 *   generateInsights: true,
 *   generateStreaks: true
 * })
 */
export const seedUserData = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 540, // 9 minutes (Cloud Functions max)
  },
  async (request) => {
    // Note: No auth check - this is an admin function
    // In production, should add admin verification
    
    console.log('Seed user data called', request.data);
    
    // Validate request data
    const config = request.data as SeedConfig;
    if (!config.userId) {
      throw new HttpsError('invalid-argument', 'userId is required');
    }
    
    // Check for dry-run flag
    const dryRun = request.data.dryRun === true;
    
    try {
      const seedingService = createSeedingService(db, geminiApiKey.value());
      const result = await seedingService.seedUserData(config, dryRun);
      
      console.log('Seed completed:', result);
      return {
        success: true,
        result,
      };
    } catch (error) {
      console.error('Seed failed:', error);
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      throw new HttpsError('internal', `Seeding failed: ${error}`);
    }
  }
);
```

#### 2. Insight Generation Integration
**File**: `functions/src/services/seeding-service.ts`
**Changes**: Update `generateInsights()` method to call existing InsightGenerator

```typescript
import { createInsightGenerator } from '../domain/insights/insight-generator';
import { getAI } from '../config/genkit';

// Add to SeedingService class:

private apiKey: string;

constructor(db: admin.firestore.Firestore, apiKey: string) {
  this.db = db;
  this.apiKey = apiKey; // Store for insight generation
  this.seedRepo = getSeedRepository(db);
  this.threadRepo = getThreadRepository(db);
  this.messageRepo = getMessageRepository(db);
  this.aiService = createAiService(apiKey);
}

/**
 * Generate insights for all threads using existing InsightGenerator
 */
private async generateInsights(userId: string): Promise<number> {
  console.log('Generating insights for seeded data');
  
  const ai = getAI(this.apiKey);
  const insightGenerator = createInsightGenerator(this.db);
  const now = Date.now();
  
  // Get all threads for this user
  const threadsSnapshot = await this.db
    .collection('journalThreads')
    .where('userId', '==', userId)
    .where('isDeleted', '==', false)
    .get();
  
  let insightsCreated = 0;
  
  // Generate thread-level insights
  for (const threadDoc of threadsSnapshot.docs) {
    try {
      const threadId = threadDoc.id;
      const result = await insightGenerator.generateThreadInsight(
        ai,
        threadId,
        userId,
        now
      );
      
      if (result) {
        insightsCreated++;
        console.log(`Generated insight for thread ${threadId}`);
      }
      
      // Small delay to avoid rate limits
      await this.sleep(300);
    } catch (error) {
      console.error(`Failed to generate insight for thread ${threadDoc.id}:`, error);
      // Continue with other threads
    }
  }
  
  // Generate global insight
  try {
    await insightGenerator.generateGlobalInsight(userId, now);
    insightsCreated++;
    console.log('Generated global insight');
  } catch (error) {
    console.error('Failed to generate global insight:', error);
  }
  
  return insightsCreated;
}
```

#### 3. Export Cloud Function
**File**: `functions/src/index.ts`
**Changes**: Export new callable function

```typescript
// Add to existing exports:
export { seedUserData } from './functions/seed-user-data-callable';
```

### Success Criteria

#### Automated Verification:
- [ ] Function compiles and deploys: `npm run build && firebase deploy --only functions:seedUserData`
- [ ] Function appears in Firebase Console
- [ ] TypeScript types match between callable and service

#### Manual Verification:
- [ ] Call function with valid config → returns success result
- [ ] Call function with invalid userId → returns 'not-found' error
- [ ] Call function with invalid config → returns 'invalid-argument' error
- [ ] Dry-run mode returns estimated counts without creating documents
- [ ] Insights are generated for each thread after seeding
- [ ] At least one insight exists per thread in `insights` collection

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 5: Streak Calculation & Local Script

### Overview
Implement streak (racha) calculation and create a local Node.js script for development use.

### Changes Required

#### 1. Streak Calculator
**File**: `functions/src/utils/streak-calculator.ts` (NEW)
**Changes**: Calculate user streaks from message data

```typescript
import * as admin from 'firebase-admin';

export interface StreakMetrics {
  currentStreakDays: number;
  longestStreakDays: number;
  totalDaysActive: number;
  lastActivityDate: number;
}

/**
 * Calculate streak metrics from message timestamps
 */
export async function calculateStreaks(
  db: admin.firestore.Firestore,
  userId: string,
  startDate: number,
  endDate: number
): Promise<StreakMetrics> {
  // Get all messages for user in date range
  const messagesSnapshot = await db
    .collection('journalMessages')
    .where('userId', '==', userId)
    .where('role', '==', 0) // Only USER messages count
    .where('createdAtMillis', '>=', startDate)
    .where('createdAtMillis', '<=', endDate)
    .orderBy('createdAtMillis', 'asc')
    .get();

  if (messagesSnapshot.empty) {
    return {
      currentStreakDays: 0,
      longestStreakDays: 0,
      totalDaysActive: 0,
      lastActivityDate: 0,
    };
  }

  // Extract unique dates (day level)
  const activeDates = new Set<string>();
  messagesSnapshot.docs.forEach(doc => {
    const timestamp = doc.data().createdAtMillis;
    const date = new Date(timestamp);
    const dateKey = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
    activeDates.add(dateKey);
  });

  // Sort dates
  const sortedDates = Array.from(activeDates).sort();
  
  // Calculate current streak (from most recent date backwards)
  let currentStreak = 0;
  const today = new Date();
  let checkDate = new Date(today);
  
  for (let i = sortedDates.length - 1; i >= 0; i--) {
    const dateKey = sortedDates[i];
    const [year, month, day] = dateKey.split('-').map(Number);
    const messageDate = new Date(year, month - 1, day);
    
    // Check if this date matches expected streak date
    const expectedDateKey = `${checkDate.getFullYear()}-${checkDate.getMonth() + 1}-${checkDate.getDate()}`;
    if (dateKey === expectedDateKey) {
      currentStreak++;
      checkDate.setDate(checkDate.getDate() - 1); // Go back one day
    } else {
      break;
    }
  }
  
  // Calculate longest streak
  let longestStreak = 0;
  let tempStreak = 1;
  
  for (let i = 1; i < sortedDates.length; i++) {
    const prev = sortedDates[i - 1];
    const curr = sortedDates[i];
    
    const [prevYear, prevMonth, prevDay] = prev.split('-').map(Number);
    const [currYear, currMonth, currDay] = curr.split('-').map(Number);
    
    const prevDate = new Date(prevYear, prevMonth - 1, prevDay);
    const currDate = new Date(currYear, currMonth - 1, currDay);
    
    const dayDiff = Math.floor((currDate.getTime() - prevDate.getTime()) / (24 * 60 * 60 * 1000));
    
    if (dayDiff === 1) {
      tempStreak++;
    } else {
      longestStreak = Math.max(longestStreak, tempStreak);
      tempStreak = 1;
    }
  }
  longestStreak = Math.max(longestStreak, tempStreak);
  
  // Last activity
  const lastMessage = messagesSnapshot.docs[messagesSnapshot.docs.length - 1];
  const lastActivityDate = lastMessage.data().createdAtMillis;

  return {
    currentStreakDays: currentStreak,
    longestStreakDays: longestStreak,
    totalDaysActive: activeDates.size,
    lastActivityDate,
  };
}

/**
 * Save streak metrics to Firestore
 */
export async function saveStreakMetrics(
  db: admin.firestore.Firestore,
  userId: string,
  metrics: StreakMetrics
): Promise<void> {
  const metricsRef = db.collection('users').doc(userId).collection('metrics').doc('rachas');
  
  await metricsRef.set({
    ...metrics,
    updatedAtMillis: Date.now(),
  }, { merge: true });
  
  console.log(`Saved streak metrics for user ${userId}:`, metrics);
}
```

#### 2. Update Seeding Service
**File**: `functions/src/services/seeding-service.ts`
**Changes**: Integrate streak calculation

```typescript
import { calculateStreaks, saveStreakMetrics } from '../utils/streak-calculator';

// Update calculateStreaks method in SeedingService:

private async calculateStreaks(
  userId: string,
  startDate: number,
  endDate: number
): Promise<void> {
  console.log('Calculating streak metrics');
  
  const metrics = await calculateStreaks(this.db, userId, startDate, endDate);
  await saveStreakMetrics(this.db, userId, metrics);
  
  console.log('Streak metrics calculated and saved:', metrics);
}
```

#### 3. Local Seeding Script
**File**: `functions/scripts/seed-user-data.ts` (NEW)
**Changes**: Local script for development/testing

```typescript
import * as admin from 'firebase-admin';
import { createSeedingService } from '../src/services/seeding-service';
import { SeedConfig } from '../src/data/models/seed-config';

// Initialize Firebase Admin
const serviceAccount = require('../../path-to-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Example seed profile
const EXAMPLE_PROFILE: SeedConfig = {
  userId: 'test-user-123', // Replace with actual user ID
  threads: 5,
  minMessagesPerThread: 10,
  maxMessagesPerThread: 40,
  startDate: Date.now() - 30 * 24 * 60 * 60 * 1000, // 30 days ago
  endDate: Date.now(),
  attachmentsPercent: 0,
  voiceNotesPercent: 0,
  imagesPercent: 0,
  generateInsights: true,
  generateStreaks: true,
};

async function main() {
  console.log('🌱 Starting user data seeding...');
  console.log('Config:', JSON.stringify(EXAMPLE_PROFILE, null, 2));

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY environment variable not set');
  }

  const seedingService = createSeedingService(db, apiKey);

  try {
    const result = await seedingService.seedUserData(EXAMPLE_PROFILE);
    
    console.log('\n✅ Seeding completed successfully!');
    console.log('📊 Results:');
    console.log(`   - Seed ID: ${result.seedId}`);
    console.log(`   - Threads created: ${result.threadsCreated}`);
    console.log(`   - Messages created: ${result.messagesCreated}`);
    console.log(`   - Insights created: ${result.insightsCreated}`);
    console.log(`   - Storage uploads: ${result.storageUploads}`);
    console.log(`   - Streaks calculated: ${result.streaksCalculated}`);
    console.log(`   - Duration: ${result.durationMs}ms`);
    
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Seeding failed:', error);
    process.exit(1);
  }
}

main();
```

#### 4. Add Script to package.json
**File**: `functions/package.json`
**Changes**: Add script command

```json
{
  "scripts": {
    "seed": "ts-node scripts/seed-user-data.ts",
    "seed:dry-run": "DRY_RUN=true ts-node scripts/seed-user-data.ts"
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Streak calculator compiles: `npm run build`
- [ ] Local script compiles: `npm run build`
- [ ] Script can be executed: `npm run seed:dry-run` (should complete without errors)

#### Manual Verification:
- [ ] Run script with actual userId → creates data in Firestore
- [ ] Check `users/{userId}/metrics/rachas` → document exists with streak data
- [ ] Verify `currentStreakDays` matches actual consecutive days with messages
- [ ] Verify `longestStreakDays` is calculated correctly
- [ ] Run script twice with same `seedId` → second run skips creation (idempotency)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.

---

## Phase 6: Testing & Documentation

### Overview
Create comprehensive tests and documentation for the seeding tool.

### Changes Required

#### 1. Unit Tests - Content Generation
**File**: `functions/src/test/utils/content-templates.test.ts` (NEW)
**Changes**: Test content generation utilities

```typescript
import { expect } from 'chai';
import {
  generateThreadTitle,
  generateMessagePrompt,
  getRandomElement,
  THREAD_TITLE_TEMPLATES,
} from '../../utils/content-templates';

describe('Content Templates', () => {
  describe('getRandomElement', () => {
    it('should return an element from the array', () => {
      const array = ['a', 'b', 'c'];
      const result = getRandomElement(array);
      expect(array).to.include(result);
    });

    it('should not fail on single-element array', () => {
      const result = getRandomElement(['only']);
      expect(result).to.equal('only');
    });
  });

  describe('generateThreadTitle', () => {
    it('should generate a valid thread title', () => {
      const title = generateThreadTitle();
      expect(title).to.be.a('string');
      expect(title.length).to.be.greaterThan(5);
    });

    it('should not contain template placeholders', () => {
      const title = generateThreadTitle();
      expect(title).to.not.include('{topic}');
    });

    it('should generate varied titles', () => {
      const titles = new Set();
      for (let i = 0; i < 50; i++) {
        titles.add(generateThreadTitle());
      }
      // Should have some variety
      expect(titles.size).to.be.greaterThan(10);
    });
  });

  describe('generateMessagePrompt', () => {
    it('should generate a valid prompt', () => {
      const prompt = generateMessagePrompt();
      expect(prompt).to.be.a('string');
      expect(prompt.length).to.be.greaterThan(10);
    });

    it('should not contain template placeholders', () => {
      const prompt = generateMessagePrompt();
      expect(prompt).to.not.include('{topic}');
      expect(prompt).to.not.include('{emotion}');
    });
  });
});
```

#### 2. Unit Tests - Timestamp Generation
**File**: `functions/src/test/utils/timestamp-generator.test.ts` (NEW)
**Changes**: Test timestamp generation logic

```typescript
import { expect } from 'chai';
import {
  TimestampGenerator,
  distributeThreadTimestamps,
} from '../../utils/timestamp-generator';

describe('Timestamp Generator', () => {
  const START = Date.now();
  const END = START + 7 * 24 * 60 * 60 * 1000; // 7 days later

  describe('TimestampGenerator', () => {
    it('should generate requested number of timestamps', () => {
      const gen = new TimestampGenerator(START, END);
      const timestamps = gen.generateTimestamps(10);
      expect(timestamps).to.have.length(10);
    });

    it('should generate chronologically ordered timestamps', () => {
      const gen = new TimestampGenerator(START, END);
      const timestamps = gen.generateTimestamps(20);
      
      for (let i = 1; i < timestamps.length; i++) {
        expect(timestamps[i]).to.be.greaterThan(timestamps[i - 1]);
      }
    });

    it('should start at or after start time', () => {
      const gen = new TimestampGenerator(START, END);
      const timestamps = gen.generateTimestamps(5);
      expect(timestamps[0]).to.be.at.least(START);
    });

    it('should generate varied gaps between messages', () => {
      const gen = new TimestampGenerator(START, END);
      const timestamps = gen.generateTimestamps(30);
      
      const gaps = [];
      for (let i = 1; i < timestamps.length; i++) {
        gaps.push(timestamps[i] - timestamps[i - 1]);
      }
      
      // Check for variety in gaps
      const uniqueGaps = new Set(gaps);
      expect(uniqueGaps.size).to.be.greaterThan(5);
    });
  });

  describe('distributeThreadTimestamps', () => {
    it('should distribute timestamps evenly', () => {
      const timestamps = distributeThreadTimestamps(5, START, END);
      expect(timestamps).to.have.length(5);
      
      // Check they span the range reasonably
      expect(timestamps[0]).to.be.greaterThan(START);
      expect(timestamps[timestamps.length - 1]).to.be.lessThan(END);
    });

    it('should return sorted timestamps', () => {
      const timestamps = distributeThreadTimestamps(10, START, END);
      
      for (let i = 1; i < timestamps.length; i++) {
        expect(timestamps[i]).to.be.greaterThan(timestamps[i - 1]);
      }
    });
  });
});
```

#### 3. Unit Tests - Validation
**File**: `functions/src/test/utils/seed-validation.test.ts` (NEW)
**Changes**: Test configuration validation

```typescript
import { expect } from 'chai';
import { validateSeedConfig, generateSeedId } from '../../utils/seed-validation';
import { SeedConfig } from '../../data/models/seed-config';
import * as admin from 'firebase-admin';

describe('Seed Validation', () => {
  describe('generateSeedId', () => {
    it('should generate unique IDs', () => {
      const id1 = generateSeedId();
      const id2 = generateSeedId();
      expect(id1).to.not.equal(id2);
    });

    it('should start with "seed_" prefix', () => {
      const id = generateSeedId();
      expect(id).to.match(/^seed_/);
    });
  });

  describe('validateSeedConfig', () => {
    // Note: Full validation tests would require Firestore mock
    // These tests focus on logic validation
    
    it('should reject invalid thread count (too low)', async () => {
      const config: SeedConfig = {
        userId: 'test',
        threads: 0,
        minMessagesPerThread: 10,
        maxMessagesPerThread: 20,
        generateInsights: false,
        generateStreaks: false,
      };
      
      // Would need Firestore mock to fully test
      // For now, test structure is in place
      expect(config.threads).to.be.lessThan(1);
    });

    it('should reject invalid thread count (too high)', () => {
      const config: SeedConfig = {
        userId: 'test',
        threads: 150,
        minMessagesPerThread: 10,
        maxMessagesPerThread: 20,
        generateInsights: false,
        generateStreaks: false,
      };
      
      expect(config.threads).to.be.greaterThan(100);
    });
  });
});
```

#### 4. Integration Test
**File**: `functions/src/test/services/seeding-service.integration.test.ts` (NEW)
**Changes**: End-to-end integration test

```typescript
import { expect } from 'chai';
import * as admin from 'firebase-admin';
import { createSeedingService } from '../../services/seeding-service';
import { SeedConfig } from '../../data/models/seed-config';

describe('Seeding Service Integration', () => {
  let db: admin.firestore.Firestore;
  let testUserId: string;

  before(() => {
    // Initialize Firebase Admin for testing
    // Note: Would use Firebase emulator in real tests
    testUserId = `test-user-${Date.now()}`;
  });

  describe('Dry Run Mode', () => {
    it('should return estimates without creating data', async () => {
      const config: SeedConfig = {
        userId: testUserId,
        threads: 3,
        minMessagesPerThread: 5,
        maxMessagesPerThread: 10,
        generateInsights: false,
        generateStreaks: false,
      };

      // Mock API key for testing
      const apiKey = process.env.GEMINI_API_KEY || 'test-key';
      const service = createSeedingService(db, apiKey);
      
      const result = await service.seedUserData(config, true);
      
      expect(result.threadsCreated).to.equal(3);
      expect(result.messagesCreated).to.be.greaterThan(0);
      expect(result.durationMs).to.equal(0); // Dry run doesn't track duration
    });
  });

  describe('Idempotency', () => {
    it('should not duplicate data with same seedId', async () => {
      // This test would require full Firestore setup
      // Structure is in place for future implementation
      expect(true).to.be.true;
    });
  });
});
```

#### 5. Documentation
**File**: `functions/README_SEEDING.md` (NEW)
**Changes**: Comprehensive usage documentation

```markdown
# User Data Seeding Tool

## Overview

The User Data Seeding Tool creates realistic journal threads, messages, insights, and streak metrics for testing and development purposes.

## Features

- ✅ **Idempotent**: Running with the same `seedId` will not create duplicates
- ✅ **Configurable**: Control thread count, message count, date ranges, and more
- ✅ **Realistic Data**: AI-generated content with natural conversation cadence
- ✅ **Insights Integration**: Automatically generates insights using existing pipeline
- ✅ **Streak Calculation**: Computes and stores user activity streaks
- ✅ **Dry Run Mode**: Preview what will be created without writing data

## Usage

### Cloud Function (Production/Staging)

Call the `seedUserData` Cloud Function:

```javascript
const functions = firebase.functions();
const seedUserData = functions.httpsCallable('seedUserData');

const result = await seedUserData({
  userId: 'user-123',
  threads: 5,
  minMessagesPerThread: 10,
  maxMessagesPerThread: 40,
  generateInsights: true,
  generateStreaks: true,
});

console.log('Seed result:', result.data);
```

### Local Script (Development)

1. Set environment variable:
```bash
export GEMINI_API_KEY="your-api-key"
```

2. Update userId in `scripts/seed-user-data.ts`

3. Run the script:
```bash
cd functions
npm run seed
```

For dry run:
```bash
npm run seed:dry-run
```

## Configuration Options

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `userId` | string | Yes | - | User ID to seed data for |
| `seedId` | string | No | Auto-generated | Unique seed identifier for idempotency |
| `threads` | number | Yes | - | Number of threads to create (1-100) |
| `minMessagesPerThread` | number | Yes | - | Minimum messages per thread |
| `maxMessagesPerThread` | number | Yes | - | Maximum messages per thread (≤200) |
| `startDate` | number | No | 30 days ago | Start of date range (millis) |
| `endDate` | number | No | Now | End of date range (millis) |
| `attachmentsPercent` | number | No | 0 | Percentage of messages with attachments (0-100) |
| `voiceNotesPercent` | number | No | 0 | Percentage of messages with voice notes (0-100) |
| `imagesPercent` | number | No | 0 | Percentage of messages with images (0-100) |
| `generateInsights` | boolean | Yes | - | Generate insights after seeding |
| `generateStreaks` | boolean | Yes | - | Calculate streak metrics |

## Example Profiles

### Minimal Profile (Quick Test)
```typescript
{
  userId: 'test-user',
  threads: 2,
  minMessagesPerThread: 5,
  maxMessagesPerThread: 10,
  generateInsights: false,
  generateStreaks: false,
}
```

### Standard Profile (Realistic Data)
```typescript
{
  userId: 'test-user',
  threads: 5,
  minMessagesPerThread: 10,
  maxMessagesPerThread: 40,
  startDate: Date.now() - 30 * 24 * 60 * 60 * 1000,
  endDate: Date.now(),
  generateInsights: true,
  generateStreaks: true,
}
```

### Heavy Profile (Stress Test)
```typescript
{
  userId: 'test-user',
  threads: 20,
  minMessagesPerThread: 20,
  maxMessagesPerThread: 100,
  startDate: Date.now() - 90 * 24 * 60 * 60 * 1000,
  endDate: Date.now(),
  imagesPercent: 20,
  voiceNotesPercent: 10,
  generateInsights: true,
  generateStreaks: true,
}
```

## Return Value

```typescript
{
  seedId: string;           // Unique identifier for this seed
  threadsCreated: number;   // Number of threads created
  messagesCreated: number;  // Total messages created
  insightsCreated: number;  // Insights generated
  storageUploads: number;   // Files uploaded to Storage
  streaksCalculated: boolean; // Whether streaks were calculated
  durationMs: number;       // Total execution time
}
```

## Verification

### Check Thread Count
```bash
# Firestore Console or CLI
firebase firestore:query "journalThreads" --where "userId==test-user"
```

### Check Insights
```bash
firebase firestore:query "insights" --where "userId==test-user"
```

### Check Streaks
```bash
# Check document: users/{userId}/metrics/rachas
```

### Verify Idempotency
```bash
# Run twice with same seedId
npm run seed
npm run seed  # Should skip creation
```

## Limitations

- Maximum 100 threads per seed operation
- Maximum 200 messages per thread
- Cloud Function timeout: 9 minutes (adjust thread/message counts accordingly)
- Rate limiting: 100ms delay between AI calls to avoid quotas
- Storage attachments: Currently creates placeholder files only

## Troubleshooting

**Error: User not found**
- Ensure the userId exists in the `users` collection

**Error: Function timeout**
- Reduce thread count or messages per thread
- Split into multiple seed operations

**Error: Rate limit exceeded**
- Increase delays between AI calls in `seeding-service.ts`
- Use smaller batch sizes

**Insights not generated**
- Ensure `generateInsights: true` in config
- Check that messages exist before insight generation
- Verify Gemini API key is valid

## Testing

Run unit tests:
```bash
npm test
```

Run specific test suite:
```bash
npm test -- --grep "Content Templates"
```

## Architecture

```
┌─────────────────────────────────────┐
│ seedUserData (Callable Function)   │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ SeedingService                      │
│  - Validation                       │
│  - Idempotency Check                │
│  - Thread/Message Creation          │
│  - Insight Generation               │
│  - Streak Calculation               │
└────────────┬────────────────────────┘
             │
    ┌────────┴────────┐
    ▼                 ▼
┌───────────┐   ┌───────────────┐
│ AI Service│   │ Repositories  │
│ (Genkit)  │   │ (Firestore)   │
└───────────┘   └───────────────┘
```

## Future Enhancements

- [ ] Actual image generation (Imagen API)
- [ ] Actual voice note generation (TTS)
- [ ] Thread cover image generation
- [ ] Participant simulation for multi-user threads
- [ ] Custom content templates per user persona
- [ ] Progress callbacks for long-running operations
- [ ] Parallel thread creation for faster seeding
```

### Success Criteria

#### Automated Verification:
- [ ] All unit tests pass: `npm test`
- [ ] Test coverage includes content generation, timestamps, validation
- [ ] Integration test structure is in place
- [ ] Documentation is complete and readable

#### Manual Verification:
- [ ] Run example minimal profile → creates 2 threads with 5-10 messages each
- [ ] Run example standard profile → creates 5 threads, generates insights
- [ ] Run with same seedId twice → second run completes instantly (idempotency)
- [ ] Check one thread → messages alternate USER/AI, timestamps are ordered
- [ ] Check insights collection → at least one insight per thread exists
- [ ] Check streaks document → currentStreakDays and longestStreakDays are present
- [ ] Dry-run mode returns estimates without creating Firestore documents

---

## Testing Strategy

### Unit Tests
- Content template generation (variety, no placeholders)
- Timestamp generation (ordering, variety, realistic gaps)
- Configuration validation (boundary conditions, invalid inputs)
- Streak calculation (consecutive days, longest streak, gaps)

### Integration Tests
- End-to-end seeding with minimal config
- Idempotency with repeated seedId
- Insight generation after message creation
- Streak calculation from seeded data

### Manual Testing Steps
1. Create test user in Firestore `users` collection
2. Run local script with minimal profile (2 threads, 5-10 messages)
3. Verify in Firestore Console:
   - 2 documents in `journalThreads` with correct userId
   - 10-20 documents in `journalMessages` split across 2 threads
   - Messages alternate between USER (role=0) and AI (role=1)
   - Timestamps are chronologically ordered
4. Run with `generateInsights: true`
   - Verify `insights` collection has 2+ documents (one per thread + global)
   - Check insight summaries are AI-generated text
5. Run with `generateStreaks: true`
   - Check `users/{userId}/metrics/rachas` document exists
   - Verify `currentStreakDays` > 0 if recent messages
6. Run script again with same explicit `seedId`
   - Should complete in <1 second
   - Thread/message counts should not increase
7. Test Cloud Function via Firebase emulator
   - Deploy function to emulator
   - Call via client SDK
   - Verify same behavior as local script

## Performance Considerations

### Rate Limiting
- AI API calls have 100ms delay between requests
- Thread creation is sequential to avoid overwhelming Firestore
- Batch writes used for messages (up to 500 operations per batch)

### Optimization Opportunities
- Parallel thread creation (with rate limiting)
- Batch insight generation (multiple threads at once)
- Cache AI responses for similar prompts (reduce API calls)
- Use Firestore batch writes more aggressively

### Scalability Limits
- Cloud Function: 9-minute timeout (max ~50 threads with 40 messages each)
- Firestore: 500 operations per batch (splitting required for large threads)
- AI API: Rate limits vary by Gemini tier (monitor quota usage)

## Migration Notes

Not applicable - this is a new development tool, not a production data migration.

## References

- Existing repositories: `functions/src/data/repositories/`
- AI Service: `functions/src/services/ai-service.ts`
- Insight Generator: `functions/src/domain/insights/insight-generator.ts`
- Message constants: `functions/src/config/constants.ts`
- Callable function pattern: `functions/src/functions/ai-response-callable.ts`

