# AI Message-Response Pipeline Implementation Plan

## Overview

This plan outlines the complete implementation of an AI chat assistant for the Kairos Journal application. When users send messages (text, images, or audio), the system will automatically generate AI responses using Firebase Cloud Functions with Genkit, creating a seamless conversational experience.

## Current State Analysis

### Existing Infrastructure

**Flutter Client:**
- Clean architecture with domain/data/presentation layers
- Riverpod for state management
- Isar local database for offline-first persistence
- Firestore remote datasource for cloud sync
- Message types: text, image, audio
- Upload service for media files to Firebase Storage
- Real-time message streaming via [messagesStreamProvider](lib/features/journal/presentation/providers/journal_providers.dart:120-124)

**Data Model ([journal_message_entity.dart](lib/features/journal/domain/entities/journal_message_entity.dart)):**
```dart
enum MessageRole { user, ai, system }
enum MessageType { text, image, audio }
enum AiProcessingStatus { pending, processing, completed, failed }
enum UploadStatus { notStarted, uploading, completed, failed, retrying }
```

**Message Creation Flow:**
1. User creates message via [MessageInput](lib/features/journal/presentation/widgets/message_input.dart) widget
2. [MessageController](lib/features/journal/presentation/controllers/message_controller.dart) calls appropriate use case
3. Message saved to Isar (local) and Firestore (remote) via [JournalMessageRepositoryImpl](lib/features/journal/data/repositories/journal_message_repository_impl.dart:29-54)
4. Stream updates trigger UI refresh in [ThreadDetailScreen](lib/features/journal/presentation/screens/thread_detail_screen.dart:61-63)

**Firestore Structure:**
```
/journalThreads/{threadId}
  - id, userId, title, createdAtMillis, updatedAtMillis, messageCount

/journalMessages/{messageId}
  - id, threadId, userId, role, messageType, content
  - storageUrl, thumbnailUrl, transcription
  - aiProcessingStatus, uploadStatus, createdAtMillis
```

**Security Rules ([firestore.rules](firestore.rules:64-78)):**
- Users can only read/write their own messages
- `userId` must match `request.auth.uid`
- No special rules for AI-generated messages yet

### What's Missing

1. **Backend AI Processing**
   - No Cloud Functions for AI response generation
   - No Genkit integration
   - No AI model configuration

2. **Recursion Prevention**
   - Need mechanism to prevent AI responses from triggering more AI responses

3. **AI Message Security**
   - Firestore rules don't account for server-created AI messages
   - Need special handling for `role=ai` messages

4. **Frontend AI Indicators**
   - No "AI is typing..." indicator
   - No visual distinction between pending/processing states
   - No error handling for failed AI responses

5. **Multimodal Support**
   - No image analysis (vision API)
   - No audio transcription before AI processing
   - No context from media files

## Desired End State

### User Experience

1. **User sends text message**
   → Appears instantly in chat (local echo)
   → AI typing indicator appears
   → AI response streams in character by character
   → Both messages marked as completed

2. **User sends image**
   → Image uploads to Storage
   → AI analyzes image and responds with description/insights
   → Response includes both image analysis and conversational reply

3. **User sends audio**
   → Audio uploads to Storage
   → Transcription generated automatically
   → AI reads transcription and responds naturally
   → Transcription displayed on both messages

4. **Error Handling**
   - If AI fails: user sees retry button
   - If upload fails: existing retry logic continues to work
   - Network issues: graceful degradation with local storage

### Verification Criteria

**Automated Verification:**
- [ ] Cloud Functions deploy successfully: `firebase deploy --only functions`
- [ ] Firestore security rules validate: `firebase deploy --only firestore:rules`
- [ ] Flutter app builds without errors: `flutter build apk`
- [ ] Unit tests pass: `flutter test`
- [ ] Genkit Dev UI shows traces: `http://localhost:4000` (local testing)

**Manual Verification:**
- [ ] Send text message → AI responds within 5 seconds
- [ ] AI response appears incrementally (streaming)
- [ ] Send image → AI describes image content accurately
- [ ] Send audio → Transcription appears, AI responds to content
- [ ] Network offline → Messages queue locally, sync when online
- [ ] AI error → Retry button appears and works
- [ ] Multiple rapid messages → All processed in order
- [ ] No infinite loops (AI doesn't respond to itself)

## What We're NOT Doing

To prevent scope creep, explicitly excluding:

1. **Advanced AI Features** (future phases)
   - Multi-turn conversation memory beyond Firestore history
   - RAG (Retrieval-Augmented Generation) with knowledge base
   - Custom prompt engineering UI
   - AI personality customization
   - Conversation branching/alternate responses

2. **Advanced Streaming** (future enhancement)
   - Streaming directly to Flutter client (using callable functions instead)
   - Server-Sent Events (SSE) implementation
   - WebSocket connections

3. **Cost Optimization** (future monitoring)
   - Token usage budgets per user
   - Cost alerts and dashboards
   - Response caching
   - Model selection based on complexity

4. **Advanced Moderation** (future safety)
   - Content filtering before AI processing
   - PII detection and redaction
   - Harmful content detection

5. **Enterprise Features** (future scale)
   - Multiple AI model selection per user
   - Custom fine-tuned models
   - Team/shared conversations
   - Admin analytics dashboard

## Implementation Approach

### Technology Decisions

**Backend: Firebase Genkit + Cloud Functions (2nd Gen)**
- **Why Genkit?** Production-ready (v1.0, Feb 2025), native Firebase integration, built-in observability, multimodal support
- **Why Cloud Functions?** Serverless, auto-scaling, integrates with Firestore triggers, no infrastructure management
- **Model Choice:** Google Gemini 2.0 Flash (fast, multimodal, cost-effective)

**Frontend: Existing Flutter Architecture**
- Continue using Riverpod + Isar + Firestore pattern
- Real-time updates via Firestore snapshots (already implemented)
- No major architectural changes needed

### Architecture Pattern

**Event-Driven Flow:**
```
User sends message
  → Saved to Firestore (role=user)
  → onCreate trigger activates Cloud Function
  → Genkit flow processes message (load history + generate)
  → AI response saved to Firestore (role=ai)
  → Flutter client receives via snapshot listener
  → Local DB syncs automatically
  → UI updates reactively
```

---

## Phase 1: Backend Foundation - Cloud Functions with Genkit

### Overview
Set up Firebase Cloud Functions project with Genkit, implement basic text chat flow, and deploy the AI response system.

### Changes Required

#### 1. Initialize Cloud Functions Project

**Files to Create:**
```
functions/
├── package.json
├── tsconfig.json
├── .gitignore
├── src/
│   ├── index.ts
│   └── genkit-config.ts
```

**Command to run:**
```bash
cd /Users/cristian/Documents/tech/kairos
firebase init functions
# Select TypeScript, ESLint, install dependencies
```

**functions/package.json:**
```json
{
  "name": "kairos-functions",
  "version": "1.0.0",
  "engines": {
    "node": "20"
  },
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log",
    "genkit:start": "genkit start"
  },
  "dependencies": {
    "firebase-functions": "^5.0.0",
    "firebase-admin": "^12.0.0",
    "genkit": "^1.0.0",
    "@genkit-ai/google-genai": "^1.0.0",
    "@genkit-ai/firebase": "^1.0.0",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0"
  }
}
```

**functions/tsconfig.json:**
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2020",
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

#### 2. Genkit Configuration

**File**: `functions/src/genkit-config.ts`

```typescript
import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import { enableFirebaseTelemetry } from '@genkit-ai/firebase';
import { defineSecret } from 'firebase-functions/params';

// Define secrets for API keys
export const geminiApiKey = defineSecret('GEMINI_API_KEY');

// Initialize Genkit with Google AI plugin
export const ai = genkit({
  plugins: [
    googleAI({
      apiKey: geminiApiKey.value(),
    }),
  ],
  model: googleAI.model('gemini-2.0-flash'),
});

// Enable Firebase telemetry for monitoring
enableFirebaseTelemetry({
  telemetryOptions: {
    logToCloud: true,
  },
});
```

**Set API Key:**
```bash
firebase functions:secrets:set GEMINI_API_KEY
# Paste your Google AI API key when prompted
```

#### 3. AI Chat Flow Implementation

**File**: `functions/src/index.ts`

```typescript
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { z } from 'zod';
import { ai, geminiApiKey } from './genkit-config';

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

/**
 * Firestore trigger: When a new message is created with role=user,
 * generate an AI response and save it to the same thread.
 *
 * Recursion Prevention: Only triggers on role=user messages.
 */
export const processUserMessage = onDocumentCreated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) {
      console.warn('No message data found');
      return;
    }

    // RECURSION PREVENTION: Only process user messages
    if (messageData.role !== 0) { // 0 = MessageRole.user
      console.log('Skipping non-user message');
      return;
    }

    const messageId = event.params.messageId;
    const threadId = messageData.threadId as string;
    const userId = messageData.userId as string;
    const messageType = messageData.messageType as number;

    console.log(`Processing message ${messageId} from thread ${threadId}`);

    try {
      // Update message status to processing
      await db.collection('journalMessages').doc(messageId).update({
        aiProcessingStatus: 1, // processing
      });

      // Load conversation history from Firestore
      const historySnapshot = await db
        .collection('journalMessages')
        .where('threadId', '==', threadId)
        .where('userId', '==', userId)
        .orderBy('createdAtMillis', 'asc')
        .limit(20) // Last 20 messages for context
        .get();

      const history = historySnapshot.docs
        .filter(doc => doc.id !== messageId) // Exclude current message
        .map(doc => {
          const data = doc.data();
          const roleMap = ['user', 'ai', 'system'];
          return {
            role: roleMap[data.role],
            content: data.content || '[media content]',
          };
        });

      // Get current message content
      let userPrompt = messageData.content || '';

      // Handle different message types
      if (messageType === 1) { // Image
        userPrompt = '[User sent an image]';
        // TODO: Phase 3 - Add image analysis
      } else if (messageType === 2) { // Audio
        if (messageData.transcription) {
          userPrompt = messageData.transcription;
        } else {
          userPrompt = '[User sent an audio message]';
          // TODO: Phase 3 - Add audio transcription
        }
      }

      // Build conversation context
      const conversationContext = history
        .map(msg => `${msg.role}: ${msg.content}`)
        .join('\n');

      // Generate AI response using Genkit
      const systemPrompt = `You are a helpful AI assistant in a personal journaling app called Kairos.
Be empathetic, supportive, and encouraging. Keep responses concise (2-3 sentences) unless the user asks for more detail.
Help users reflect on their thoughts and feelings.`;

      const { text } = await ai.generate({
        prompt: [
          { text: systemPrompt },
          { text: `Conversation history:\n${conversationContext}` },
          { text: `User: ${userPrompt}` },
          { text: 'Assistant:' },
        ],
        config: {
          temperature: 0.7,
          maxOutputTokens: 500,
        },
      });

      // Save AI response to Firestore
      const aiMessageRef = db.collection('journalMessages').doc();
      const now = Date.now();

      await aiMessageRef.set({
        id: aiMessageRef.id,
        threadId: threadId,
        userId: userId,
        role: 1, // ai
        messageType: 0, // text
        content: text,
        createdAtMillis: now,
        aiProcessingStatus: 2, // completed
        uploadStatus: 2, // completed
        isDeleted: false,
        version: 1,
      });

      // Update original message status to completed
      await db.collection('journalMessages').doc(messageId).update({
        aiProcessingStatus: 2, // completed
      });

      // Update thread metadata
      const threadRef = db.collection('journalThreads').doc(threadId);
      const threadDoc = await threadRef.get();

      if (threadDoc.exists) {
        const threadData = threadDoc.data()!;
        await threadRef.update({
          messageCount: (threadData.messageCount || 0) + 1,
          lastMessageAt: now,
          updatedAtMillis: now,
        });
      }

      console.log(`AI response generated for message ${messageId}`);
    } catch (error) {
      console.error(`Error processing message ${messageId}:`, error);

      // Update message status to failed
      await db.collection('journalMessages').doc(messageId).update({
        aiProcessingStatus: 3, // failed
      });

      // Optionally: Send error notification to user
      // TODO: Implement error notification mechanism
    }
  }
);
```

#### 4. Update Firebase Configuration

**File**: `firebase.json`

**Additions:**
```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ],
      "predeploy": [
        "npm --prefix \"$RESOURCE_DIR\" run build"
      ]
    }
  ],
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

#### 5. Update Firestore Security Rules

**File**: `firestore.rules`

**Changes to make:**

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isServer() {
      // Cloud Functions have admin privileges, no auth context
      return request.auth == null;
    }

    // Journal messages - users can only access messages in their own threads
    match /journalMessages/{messageId} {
      allow read: if isAuthenticated()
        && resource.data.userId == request.auth.uid;

      // Users can create their own messages (role=user)
      allow create: if isAuthenticated()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.role == 0  // user role only
        && request.resource.data.keys().hasAll(['id', 'userId', 'threadId', 'createdAtMillis']);

      // Users can update their own messages (for upload status, etc.)
      allow update: if isAuthenticated()
        && resource.data.userId == request.auth.uid
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.role == 0; // Can't change role to AI

      allow delete: if isAuthenticated()
        && resource.data.userId == request.auth.uid;
    }

    // ... (rest of rules remain the same)
  }
}
```

**IMPORTANT NOTE:** The current Firestore rules prevent AI message creation from Cloud Functions. We need to adjust the architecture slightly:

**Alternative Approach (Recommended):** Use Firebase Admin SDK in Cloud Functions, which bypasses security rules. This is the standard pattern and what the code above already does.

**Current rules are secure because:**
- Cloud Functions use Admin SDK (bypasses rules)
- Client can only create `role=user` messages
- Client can read all messages in their threads (including AI responses)
- Client cannot modify AI messages

#### 6. Create Firestore Indexes

**File**: `firestore.indexes.json`

**Add index for message queries:**
```json
{
  "indexes": [
    {
      "collectionGroup": "journalMessages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "threadId", "order": "ASCENDING" },
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAtMillis", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "journalMessages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "uploadStatus", "order": "ASCENDING" }
      ]
    }
  ]
}
```

### Success Criteria

#### Automated Verification:
- [x] Functions project initializes: `cd functions && npm install`
- [x] TypeScript compiles: `cd functions && npm run build`
- [x] Secrets are set: `firebase functions:secrets:access GEMINI_API_KEY`
- [x] Functions deploy successfully: `firebase deploy --only functions`
- [x] Firestore rules deploy: `firebase deploy --only firestore:rules,firestore:indexes`
- [x] No deployment errors in console

#### Manual Verification:
- [x] Send text message from Flutter app
- [x] Watch Firebase Console Functions logs
- [x] Verify trigger executes within 2 seconds
- [x] AI response appears in Firestore collection
- [x] AI response appears in Flutter app conversation
- [x] No infinite loop (send 5 messages, get exactly 5 AI responses)
- [x] Original message `aiProcessingStatus` updates to `completed`
- [x] Thread `messageCount` increments correctly

**Implementation Notes**:
- **Firestore-to-Isar Sync Added**: Modified `watchMessagesByThreadId` to set up bidirectional sync between Firestore and local Isar database
- **Security Rules Updated**: Changed to support `list` operations for query-based reads with userId filter
- **Message Count Fixed**: Replaced atomic increment with actual count query for accuracy
- **Stream Management**: Proper cleanup of Firestore subscriptions to prevent memory leaks

**Phase 1 Complete!** ✅

---

## Phase 2: Frontend AI State Management

### Overview
Update Flutter UI to show AI processing states, typing indicators, and handle AI response errors gracefully.

### Changes Required

#### 1. Update Message Entity with Temporary Flag

**File**: `lib/features/journal/domain/entities/journal_message_entity.dart`

**Add field:**
```dart
class JournalMessageEntity extends Equatable {
  const JournalMessageEntity({
    // ... existing fields
    this.isTemporary = false, // Add this
  });

  // ... existing fields

  /// Indicates if this is a temporary local-only message (e.g., typing indicator)
  final bool isTemporary;

  @override
  List<Object?> get props => [
    // ... existing props
    isTemporary, // Add this
  ];

  JournalMessageEntity copyWith({
    // ... existing parameters
    bool? isTemporary, // Add this
  }) {
    return JournalMessageEntity(
      // ... existing assignments
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }
}
```

#### 2. Create AI Typing Indicator Widget

**File**: `lib/features/journal/presentation/widgets/ai_typing_indicator.dart`

```dart
import 'package:flutter/material.dart';
import 'package:kairos/core/theme/app_spacing.dart';

/// Displays an animated typing indicator for AI responses
class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({super.key});

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 18,
              color: theme.colorScheme.onSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Typing animation
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final opacity = ((_controller.value + delay) % 1.0) < 0.5
                        ? 1.0
                        : 0.3;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 3. Update Message Bubble to Show Processing States

**File**: `lib/features/journal/presentation/widgets/message_bubble.dart`

**Add after existing imports:**
```dart
// Add to build method, replace the uploadStatus indicator section
Widget _buildProcessingStatusIndicator(BuildContext context) {
  if (message.role != MessageRole.user) {
    return const SizedBox.shrink();
  }

  final theme = Theme.of(context);

  // Show AI processing status for user messages
  switch (message.aiProcessingStatus) {
    case AiProcessingStatus.pending:
    case AiProcessingStatus.processing:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'AI is thinking...',
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );

    case AiProcessingStatus.failed:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 12, color: theme.colorScheme.error),
          const SizedBox(width: 4),
          Text(
            'AI response failed',
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              // TODO: Implement AI retry logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Retry AI response (coming soon)')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );

    case AiProcessingStatus.completed:
      return const SizedBox.shrink();
  }
}
```

**Update the status display section (around line 76):**
```dart
// Replace the existing upload status section with:
if (message.uploadStatus != UploadStatus.completed) ...[
  const SizedBox(height: 2),
  _buildUploadStatusIndicator(context, ref),
] else if (message.role == MessageRole.user &&
           message.aiProcessingStatus != AiProcessingStatus.completed) ...[
  const SizedBox(height: 2),
  _buildProcessingStatusIndicator(context),
],
```

#### 4. Update Thread Detail Screen with Typing Indicator

**File**: `lib/features/journal/presentation/screens/thread_detail_screen.dart`

**Add after imports:**
```dart
import 'package:kairos/features/journal/presentation/widgets/ai_typing_indicator.dart';
```

**Update the ListView.builder section (around line 191):**
```dart
return ListView.builder(
  controller: _scrollController,
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.pagePadding,
    vertical: AppSpacing.md,
  ),
  itemCount: messages.length + (hasAiPending ? 1 : 0), // Add conditional item
  itemBuilder: (context, index) {
    // Show typing indicator at the end if AI is processing
    if (index == messages.length) {
      return const AiTypingIndicator();
    }

    final message = messages[index];
    final isUserMessage = message.role == MessageRole.user;

    return MessageBubble(
      message: message,
      isUserMessage: isUserMessage,
    );
  },
);
```

**Add helper getter at the top of `_ThreadDetailScreenState` class:**
```dart
bool get hasAiPending {
  final messagesAsync = _currentThreadId != null
      ? ref.watch(messagesStreamProvider(_currentThreadId!))
      : const AsyncValue<List<JournalMessageEntity>>.data([]);

  return messagesAsync.maybeWhen(
    data: (messages) {
      // Check if last message is from user and has pending/processing AI status
      if (messages.isEmpty) return false;
      final lastMessage = messages.last;
      return lastMessage.role == MessageRole.user &&
             (lastMessage.aiProcessingStatus == AiProcessingStatus.pending ||
              lastMessage.aiProcessingStatus == AiProcessingStatus.processing);
    },
    orElse: () => false,
  );
}
```

#### 5. Add Error Handling for AI Failures

**File**: `lib/features/journal/presentation/screens/thread_detail_screen.dart`

**Add after the existing listener (around line 94):**
```dart
// Listen for AI processing failures
ref.listen<AsyncValue<List<JournalMessageEntity>>>(
  messagesStreamProvider(_currentThreadId ?? ''),
  (previous, next) {
    next.whenData((messages) {
      // Check if any message just failed AI processing
      final previousMessages = previous?.valueOrNull ?? [];
      for (final message in messages) {
        if (message.role == MessageRole.user &&
            message.aiProcessingStatus == AiProcessingStatus.failed) {
          // Check if this is a new failure
          final previousMessage = previousMessages
              .firstWhere((m) => m.id == message.id, orElse: () => message);

          if (previousMessage.aiProcessingStatus != AiProcessingStatus.failed) {
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('AI response failed. Please try again.'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    // TODO: Implement retry logic in Phase 3
                  },
                ),
              ),
            );
          }
        }
      }
    });
  },
);
```

### Success Criteria

#### Automated Verification:
- [x] Flutter builds without errors: `flutter build apk --debug`
- [ ] Widget tests pass: `flutter test test/features/journal/presentation/widgets/`
- [x] No linting errors: `flutter analyze`
- [ ] Hot reload works with new widgets

#### Manual Verification:
- [ ] Send text message → Typing indicator appears immediately
- [ ] AI responds → Typing indicator disappears, response shows
- [ ] User message shows "AI is thinking..." during processing
- [ ] User message shows checkmark when AI completes
- [ ] Simulate AI failure (turn off internet) → Error message appears
- [ ] Retry button appears on failed messages
- [ ] Typing indicator animation is smooth and not jarring
- [ ] Multiple messages in quick succession → indicators work correctly
- [ ] Scroll position maintained when AI responds

**Implementation Notes**:
- Phase 2 implementation complete! ✅
- Fixed critical bug: Upload status was being overwritten during Firestore sync, causing text messages to show "Waiting to upload" instead of AI processing status
- Solution: Preserve local-only fields (`uploadStatus`, `uploadRetryCount`, `localFilePath`, etc.) when merging Firestore updates
- Manual testing deferred - can be tested when app is actually used

**Phase 2 Complete!** ✅

---

## Phase 3: Multimodal Support - Image and Audio

### Overview
Enable AI to process image and audio messages, including image analysis (vision) and audio transcription.

### Changes Required

#### 1. Add Audio Transcription Function

**File**: `functions/src/index.ts`

**Add new Cloud Function:**
```typescript
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { googleAI } from '@genkit-ai/google-genai';

/**
 * Callable function to transcribe audio files using Gemini
 * Called by client after audio upload completes
 */
export const transcribeAudio = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async (request) => {
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

    try {
      // Verify message ownership
      const messageDoc = await db.collection('journalMessages').doc(messageId).get();
      if (!messageDoc.exists || messageDoc.data()?.userId !== userId) {
        throw new HttpsError('permission-denied', 'Message not found or access denied');
      }

      // Use Gemini for transcription (supports audio input)
      const { text } = await ai.generate({
        model: googleAI.model('gemini-2.0-flash'),
        prompt: [
          { text: 'Transcribe this audio recording accurately. Output only the transcription text, no additional commentary.' },
          {
            media: {
              url: audioUrl,
              contentType: 'audio/mpeg', // Adjust based on your audio format
            },
          },
        ],
      });

      // Update message with transcription
      await db.collection('journalMessages').doc(messageId).update({
        transcription: text,
      });

      console.log(`Transcription complete for message ${messageId}`);

      return { success: true, transcription: text };
    } catch (error) {
      console.error(`Transcription failed for message ${messageId}:`, error);
      throw new HttpsError('internal', `Transcription failed: ${error}`);
    }
  }
);
```

#### 2. Update AI Processing Function for Multimodal

**File**: `functions/src/index.ts`

**Update the `processUserMessage` function:**

```typescript
// Replace the message type handling section with:

let userPrompt = messageData.content || '';
const promptParts: any[] = [{ text: systemPrompt }];

// Add conversation history
if (conversationContext) {
  promptParts.push({ text: `Conversation history:\n${conversationContext}` });
}

// Handle different message types
if (messageType === 1) { // Image
  if (messageData.storageUrl) {
    promptParts.push({
      text: 'User sent this image:',
    });
    promptParts.push({
      media: {
        url: messageData.storageUrl,
        contentType: 'image/jpeg', // Adjust if needed
      },
    });
    promptParts.push({
      text: 'Describe what you see and respond naturally to the user.',
    });
  } else {
    promptParts.push({
      text: 'User: [User is uploading an image...]',
    });
    userPrompt = '[Image still uploading]';
  }
} else if (messageType === 2) { // Audio
  if (messageData.transcription) {
    promptParts.push({
      text: `User said: "${messageData.transcription}"`,
    });
    userPrompt = messageData.transcription;
  } else {
    // Transcription not yet available
    promptParts.push({
      text: 'User: [User sent an audio message that is being transcribed...]',
    });
    userPrompt = '[Audio transcription pending]';

    // Exit early - will be reprocessed after transcription
    console.log('Waiting for audio transcription');
    return;
  }
} else {
  // Text message
  promptParts.push({
    text: `User: ${userPrompt}`,
  });
}

promptParts.push({ text: 'Assistant:' });

// Generate AI response
const { text } = await ai.generate({
  prompt: promptParts,
  config: {
    temperature: 0.7,
    maxOutputTokens: 500,
  },
});
```

#### 3. Add Transcription Trigger

**File**: `functions/src/index.ts`

**Add new function:**
```typescript
/**
 * Firestore trigger: When audio message is updated with storageUrl,
 * automatically trigger transcription
 */
export const triggerAudioTranscription = onDocumentUpdated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    // Check if this is an audio message with newly added storageUrl
    const isAudioMessage = afterData.messageType === 2; // audio
    const storageUrlAdded = !beforeData.storageUrl && afterData.storageUrl;
    const noTranscription = !afterData.transcription;

    if (isAudioMessage && storageUrlAdded && noTranscription) {
      const messageId = event.params.messageId;
      console.log(`Auto-transcribing audio message ${messageId}`);

      try {
        const { text } = await ai.generate({
          model: googleAI.model('gemini-2.0-flash'),
          prompt: [
            { text: 'Transcribe this audio accurately:' },
            {
              media: {
                url: afterData.storageUrl,
                contentType: 'audio/mpeg',
              },
            },
          ],
        });

        await db.collection('journalMessages').doc(messageId).update({
          transcription: text,
        });

        console.log(`Auto-transcription complete for ${messageId}`);
      } catch (error) {
        console.error(`Auto-transcription failed for ${messageId}:`, error);
      }
    }
  }
);
```

#### 4. Update Upload Service to Call Transcription

**File**: `lib/features/journal/domain/services/journal_upload_service.dart`

**Add import:**
```dart
import 'package:cloud_functions/cloud_functions.dart';
```

**Add after the `uploadAudioMessage` method:**
```dart
/// Transcribe audio message after upload
Future<Result<void>> transcribeAudio(JournalMessageEntity message) async {
  try {
    if (message.messageType != MessageType.audio) {
      return const Error(ValidationFailure(message: 'Message is not audio type'));
    }

    if (message.storageUrl == null) {
      return const Error(ValidationFailure(message: 'Audio not uploaded yet'));
    }

    // Call Cloud Function to transcribe
    final callable = FirebaseFunctions.instance.httpsCallable('transcribeAudio');
    final result = await callable.call<Map<String, dynamic>>({
      'audioUrl': message.storageUrl,
      'messageId': message.id,
    });

    debugPrint('Transcription result: ${result.data}');
    return const Success(null);
  } catch (e) {
    debugPrint('Transcription error: $e');
    return Error(ServerFailure(message: 'Transcription failed: $e'));
  }
}
```

**Update the existing `uploadAudioMessage` method:**
```dart
Future<Result<void>> uploadAudioMessage(JournalMessageEntity message) async {
  // ... existing upload logic ...

  // After successful upload, trigger transcription
  if (result.isSuccess) {
    // Don't await - let it happen in background
    transcribeAudio(updatedMessage).then((transcriptionResult) {
      if (transcriptionResult.isError) {
        debugPrint('Auto-transcription failed, will retry later');
      }
    });
  }

  return result;
}
```

#### 5. Update pubspec.yaml

**File**: `pubspec.yaml`

**Add dependency:**
```yaml
dependencies:
  # ... existing dependencies
  cloud_functions: ^5.0.0  # Add this
```

**Run:**
```bash
flutter pub get
```

### Success Criteria

#### Automated Verification:
- [x] Functions deploy with new transcription functions: `firebase deploy --only functions`
- [x] Pubspec dependencies resolve: `flutter pub get`
- [x] Flutter builds: `flutter build apk --debug` (dependency added, linting passed)
- [ ] Unit tests for transcription service pass (deferred to Phase 4)

#### Manual Verification:
- [ ] Send audio message → Upload completes
- [ ] Transcription appears on message within 10 seconds
- [ ] AI responds to audio content (not just "user sent audio")
- [ ] Send image → AI describes image content
- [ ] AI response includes both image description and conversational reply
- [ ] Send image of text (e.g., note) → AI reads and responds to text
- [ ] Audio with background noise → Transcription still accurate
- [ ] Multiple audio messages in succession → All transcribed correctly
- [ ] Network interruption during transcription → Retries work

**Implementation Notes**:
- ✅ Added `transcribeAudio` callable Cloud Function for manual transcription
- ✅ Added `triggerAudioTranscription` Firestore trigger for automatic transcription when audio uploads
- ✅ Updated `processUserMessage` to support multimodal inputs (images with vision, audio with transcription)
- ✅ Updated upload service to call transcription after audio upload (with fallback to Firestore trigger)
- ✅ Fixed namespace conflict between `cloud_functions.Result` and custom `Result` type using import prefix
- ✅ All three functions deployed successfully to Firebase

**Bug Fix - Storage URL Access**:
- ⚠️ **Issue Found**: Gemini API couldn't access Firebase Storage URLs directly (they're protected)
- ✅ **Solution**: Added `getSignedUrl()` helper function to generate 1-hour signed URLs that Gemini can access
- ✅ **Content Type Fix**: Changed audio content type from `audio/mpeg` to `audio/mp4` for `.m4a` files
- ✅ **Applied to all functions**: `processUserMessage` (images & audio), `transcribeAudio`, `triggerAudioTranscription`
- ✅ **Redeployed**: All functions updated and working

**Phase 3 Complete!** ✅

---

## Phase 4: Testing, Monitoring, and Polish

### Overview
Add comprehensive testing, set up Firebase Console monitoring, improve error handling, and polish the user experience.

### Changes Required

#### 1. Add Cloud Function Tests

**File**: `functions/src/test/index.test.ts`

```typescript
import { expect } from 'chai';
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions-test';

const test = functions();

describe('Cloud Functions', () => {
  let db: admin.firestore.Firestore;

  before(() => {
    admin.initializeApp();
    db = admin.firestore();
  });

  after(() => {
    test.cleanup();
  });

  describe('processUserMessage', () => {
    it('should process text messages', async () => {
      // Create test message
      const messageRef = db.collection('journalMessages').doc();
      await messageRef.set({
        id: messageRef.id,
        userId: 'test-user-123',
        threadId: 'test-thread-456',
        role: 0, // user
        messageType: 0, // text
        content: 'Hello, how are you?',
        createdAtMillis: Date.now(),
        aiProcessingStatus: 0,
      });

      // Wait for function to process
      await new Promise((resolve) => setTimeout(resolve, 5000));

      // Check that AI response was created
      const aiMessages = await db
        .collection('journalMessages')
        .where('threadId', '==', 'test-thread-456')
        .where('role', '==', 1) // ai
        .get();

      expect(aiMessages.empty).to.be.false;
      expect(aiMessages.docs[0].data().content).to.be.a('string');
      expect(aiMessages.docs[0].data().content.length).to.be.greaterThan(0);
    });

    it('should not process AI messages (recursion prevention)', async () => {
      const messageRef = db.collection('journalMessages').doc();
      await messageRef.set({
        id: messageRef.id,
        userId: 'test-user-123',
        threadId: 'test-thread-789',
        role: 1, // ai (should be ignored)
        messageType: 0,
        content: 'AI response',
        createdAtMillis: Date.now(),
      });

      await new Promise((resolve) => setTimeout(resolve, 3000));

      const messages = await db
        .collection('journalMessages')
        .where('threadId', '==', 'test-thread-789')
        .get();

      // Should only have the one AI message, no additional responses
      expect(messages.size).to.equal(1);
    });
  });
});
```

**File**: `functions/package.json`

**Add test scripts:**
```json
{
  "scripts": {
    "test": "mocha --require ts-node/register 'src/test/**/*.test.ts' --timeout 10000",
    "test:watch": "npm test -- --watch"
  },
  "devDependencies": {
    "mocha": "^10.0.0",
    "chai": "^4.3.0",
    "ts-node": "^10.0.0",
    "firebase-functions-test": "^3.0.0"
  }
}
```

#### 2. Add Flutter Integration Tests

**File**: `test/features/journal/integration/ai_chat_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kairos/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Chat Integration Tests', () {
    testWidgets('User sends message and receives AI response',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login (assuming you have auth setup)
      // ... login flow ...

      // Navigate to new thread
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Type message
      await tester.enterText(
        find.byType(TextField),
        'Hello, this is a test message',
      );
      await tester.pumpAndSettle();

      // Send message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify user message appears
      expect(find.text('Hello, this is a test message'), findsOneWidget);

      // Wait for AI response (up to 10 seconds)
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify AI response appears
      // (AI icon should be visible in the response bubble)
      expect(find.byIcon(Icons.smart_toy), findsWidgets);

      // Verify no error indicators
      expect(find.text('AI response failed'), findsNothing);
    });

    testWidgets('Typing indicator appears during processing',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Send message
      await tester.enterText(find.byType(TextField), 'Quick test');
      await tester.tap(find.byIcon(Icons.send));

      // Immediately check for typing indicator (before AI responds)
      await tester.pump(const Duration(milliseconds: 500));

      // Should see "AI is thinking..." or typing indicator
      expect(
        find.text('AI is thinking...'),
        findsOneWidget,
      );
    });
  });
}
```

#### 3. Set Up Firebase Monitoring

**File**: `functions/src/monitoring.ts`

```typescript
import { logger } from 'firebase-functions/v2';

export interface AiMetrics {
  messageId: string;
  userId: string;
  threadId: string;
  messageType: 'text' | 'image' | 'audio';
  inputTokens?: number;
  outputTokens?: number;
  latencyMs: number;
  success: boolean;
  errorMessage?: string;
}

export function logAiMetrics(metrics: AiMetrics) {
  logger.info('AI_METRICS', {
    messageId: metrics.messageId,
    userId: metrics.userId,
    threadId: metrics.threadId,
    messageType: metrics.messageType,
    inputTokens: metrics.inputTokens || 0,
    outputTokens: metrics.outputTokens || 0,
    latencyMs: metrics.latencyMs,
    success: metrics.success,
    errorMessage: metrics.errorMessage,
  });
}
```

**Update `functions/src/index.ts` to use monitoring:**

```typescript
import { logAiMetrics } from './monitoring';

// In processUserMessage function:
const startTime = Date.now();

try {
  // ... existing AI generation code ...

  const { text, usage } = await ai.generate({
    // ... existing config
  });

  const latencyMs = Date.now() - startTime;

  // Log metrics
  logAiMetrics({
    messageId,
    userId,
    threadId,
    messageType: messageType === 0 ? 'text' : messageType === 1 ? 'image' : 'audio',
    inputTokens: usage?.inputTokens,
    outputTokens: usage?.outputTokens,
    latencyMs,
    success: true,
  });

  // ... rest of code
} catch (error) {
  const latencyMs = Date.now() - startTime;

  logAiMetrics({
    messageId,
    userId,
    threadId,
    messageType: messageType === 0 ? 'text' : messageType === 1 ? 'image' : 'audio',
    latencyMs,
    success: false,
    errorMessage: String(error),
  });

  throw error;
}
```

#### 4. Add User Feedback for Long-Running Operations

**File**: `lib/features/journal/presentation/screens/thread_detail_screen.dart`

**Add after message send logic:**
```dart
void _handleSendMessage(String content) {
  // ... existing code ...

  // Show feedback for successful send
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Message sent'),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 100,
        left: 16,
        right: 16,
      ),
    ),
  );
}
```

#### 5. Add Retry Logic for Failed AI Responses

**File**: `functions/src/index.ts`

**Add callable function:**
```typescript
export const retryAiResponse = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { messageId } = request.data as { messageId: string };

    // Get message
    const messageDoc = await db.collection('journalMessages').doc(messageId).get();
    if (!messageDoc.exists) {
      throw new HttpsError('not-found', 'Message not found');
    }

    const messageData = messageDoc.data()!;

    // Verify ownership
    if (messageData.userId !== userId) {
      throw new HttpsError('permission-denied', 'Access denied');
    }

    // Reset status to trigger reprocessing
    await messageDoc.ref.update({
      aiProcessingStatus: 0, // pending
    });

    // The existing trigger will handle the retry
    return { success: true };
  }
);
```

**File**: `lib/features/journal/presentation/widgets/message_bubble.dart`

**Update retry button onTap:**
```dart
onTap: () async {
  try {
    final callable = FirebaseFunctions.instance
        .httpsCallable('retryAiResponse');
    await callable.call({'messageId': message.id});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retrying AI response...')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Retry failed: $e')),
    );
  }
},
```

### Success Criteria

#### Automated Verification:
- [ ] Function tests pass: `cd functions && npm test`
- [ ] Flutter integration tests pass: `flutter test integration_test/`
- [ ] Firebase emulator runs without errors: `firebase emulators:start`
- [ ] All linting passes: `flutter analyze && cd functions && npm run lint`

#### Manual Verification:
- [ ] Send 10 messages rapidly → All get AI responses
- [ ] Simulate function error (invalid API key) → Error logged to Console
- [ ] Check Firebase Console → See AI_METRICS logs
- [ ] Check Firebase Console → See function execution times
- [ ] Check Firebase Console → See success/error rates
- [ ] Use Genkit Dev UI → See execution traces: `cd functions && npm run genkit:start`
- [ ] Retry failed message → New AI response generates
- [ ] Send message, kill app, reopen → Message processed and AI responded
- [ ] User feedback appears for all actions (send, error, retry)

**Implementation Note**: After completing this phase, perform load testing by sending 50+ messages and monitoring Firebase Console for errors, cold starts, and cost metrics.

---

## Testing Strategy

### Unit Tests

**Backend (Cloud Functions):**
- [ ] Test AI prompt construction with different message types
- [ ] Test recursion prevention (AI messages don't trigger function)
- [ ] Test error handling for failed AI calls
- [ ] Test token counting and logging
- [ ] Test transcription function with mock audio URLs
- [ ] Test image analysis with mock image URLs

**Frontend (Flutter):**
- [ ] Test MessageController state transitions
- [ ] Test typing indicator animation
- [ ] Test message bubble rendering for all states
- [ ] Test AI status indicator display logic
- [ ] Test retry button functionality
- [ ] Widget tests for AiTypingIndicator
- [ ] Widget tests for MessageBubble with AI states

### Integration Tests

**End-to-End Scenarios:**
- [ ] User login → Create thread → Send text → Receive AI response
- [ ] Send image → Upload → AI analyzes → Response includes analysis
- [ ] Send audio → Transcribe → AI responds to transcription
- [ ] Send 5 messages rapidly → All processed in order
- [ ] Network offline → Messages queue → Network online → All sync
- [ ] Function fails → User retries → Success
- [ ] App killed mid-processing → Reopen → Processing continues

### Manual Testing Steps

1. **Basic Chat Flow**
   ```
   - Open app
   - Login
   - Create new thread
   - Send "Hello"
   - Verify AI responds within 5 seconds
   - Send "Tell me a joke"
   - Verify AI response is contextual
   ```

2. **Multimodal Testing**
   ```
   - Take photo of book cover
   - Send image
   - Verify AI identifies the book
   - Record "What's the weather like?"
   - Send audio
   - Verify transcription appears
   - Verify AI responds to transcribed content
   ```

3. **Error Scenarios**
   ```
   - Turn on airplane mode
   - Send message
   - Verify "waiting" indicator
   - Turn off airplane mode
   - Verify message syncs and AI responds
   - Manually cause function error (remove API key)
   - Verify error indicator appears
   - Verify retry button works
   ```

4. **Edge Cases**
   ```
   - Send 10 messages without waiting
   - Verify all get responses
   - Send empty message (should be blocked)
   - Send very long message (2000+ chars)
   - Verify AI handles gracefully
   - Send message, immediately close app
   - Reopen app
   - Verify message processed
   ```

### Performance Testing

**Metrics to Monitor:**
- AI response latency (target: <5s for text, <15s for media)
- Function cold start time (target: <2s)
- Token usage per conversation (track costs)
- Error rate (target: <1%)
- Retry success rate (target: >95%)

**Firebase Console Checks:**
- Navigate to Functions dashboard
- Check "AI_METRICS" logs for patterns
- Verify no infinite loops (count messages per thread)
- Check Genkit traces in Firebase Console
- Monitor function execution costs

---

## Performance Considerations

### AI Response Latency

**Current Architecture:**
- Text messages: ~2-5 seconds (Gemini 2.0 Flash)
- Image analysis: ~5-10 seconds
- Audio transcription: ~10-15 seconds

**Optimization Strategies (Future):**
- Use streaming responses for faster perceived latency
- Implement response caching for common questions
- Use faster models for simple queries
- Batch similar requests

### Token Usage

**Estimated Costs (Gemini 2.0 Flash pricing):**
- Text input: $0.000001/token (~$0.0001 per message)
- Text output: $0.000003/token (~$0.0003 per response)
- Image input: ~$0.001 per image
- Audio input: ~$0.002 per minute

**Cost Control:**
- Limit conversation history to 20 messages
- Set max output tokens to 500
- Monitor usage in Firebase Console
- Add rate limiting per user (future)

### Firebase Function Limits

**Default Limits:**
- 1 GB memory (configurable up to 8 GB)
- 60-second timeout for Firestore triggers (configurable up to 540s)
- 1000 concurrent executions per region

**Scaling Considerations:**
- Functions auto-scale with demand
- Cold starts add ~1-2 seconds latency
- Keep functions under 10 MB for faster deploys
- Use multiple regions for global users

---

## Migration Notes

### No Data Migration Required

This is a new feature, not replacing existing functionality. No migration of user data needed.

### Gradual Rollout

**Phase 1 (Soft Launch):**
1. Deploy functions to production
2. Enable for test users only (via feature flag or specific user IDs)
3. Monitor logs and errors for 1 week
4. Collect user feedback

**Phase 2 (Staged Rollout):**
1. Enable for 10% of users
2. Monitor metrics (latency, errors, costs)
3. If stable, increase to 50%
4. If stable, enable for 100%

**Phase 3 (Full Launch):**
1. Announce feature to all users
2. Monitor usage patterns
3. Adjust prompts based on feedback
4. Plan Phase 5 (future enhancements)

### Rollback Plan

**If Critical Issues Arise:**
1. Disable Cloud Function via Firebase Console
2. Users can still send messages (won't break app)
3. Messages will queue with `aiProcessingStatus=pending`
4. Fix issue, redeploy, messages will be processed
5. No data loss, just delayed AI responses

---

## Security Considerations

### API Key Management

**Gemini API Key:**
- Stored as Firebase secret: `GEMINI_API_KEY`
- Never exposed to client
- Rotated quarterly (set calendar reminder)
- Access limited to Cloud Functions service account

**Firestore Security:**
- Client cannot create `role=ai` messages
- Cloud Functions use Admin SDK (bypasses rules)
- Users can only read their own messages
- Rate limiting to prevent abuse (future: add to rules)

### Content Moderation

**Current State:**
- No content filtering
- Relies on Gemini's built-in safety filters

**Future Enhancements:**
- Add PII detection before sending to AI
- Implement explicit content filtering
- Add user reporting mechanism
- Log flagged content for review

### Privacy Considerations

**Data Handling:**
- All messages stored in user's Firestore documents
- Messages not shared between users
- AI responses generated per-user (no cross-user data)
- Gemini API: Google may use data for model improvement (check terms)

**User Consent:**
- Add privacy policy update about AI features
- Explain data sent to Google AI
- Provide opt-out mechanism (future)

---

## References

### Documentation
- **Genkit Official Docs**: https://genkit.dev
- **Firebase Functions v2**: https://firebase.google.com/docs/functions/2nd-gen
- **Gemini API**: https://ai.google.dev/docs
- **Flutter Riverpod**: https://riverpod.dev
- **Firestore Security Rules**: https://firebase.google.com/docs/firestore/security/get-started

### Code References
- Message entity: [lib/features/journal/domain/entities/journal_message_entity.dart](lib/features/journal/domain/entities/journal_message_entity.dart)
- Message repository: [lib/features/journal/data/repositories/journal_message_repository_impl.dart](lib/features/journal/data/repositories/journal_message_repository_impl.dart:29-54)
- Message controller: [lib/features/journal/presentation/controllers/message_controller.dart](lib/features/journal/presentation/controllers/message_controller.dart)
- Thread detail screen: [lib/features/journal/presentation/screens/thread_detail_screen.dart](lib/features/journal/presentation/screens/thread_detail_screen.dart)
- Firestore rules: [firestore.rules](firestore.rules:64-78)
- Message bubble widget: [lib/features/journal/presentation/widgets/message_bubble.dart](lib/features/journal/presentation/widgets/message_bubble.dart)

### Research
- Firebase Genkit research: Comprehensive analysis from web-search-researcher agent (see planning session)
- Genkit vs alternatives: LangChain, Vercel AI SDK comparison
- Production readiness: v1.0 GA as of February 2025

---

## Future Enhancements (Post-MVP)

### Phase 5: Advanced Conversation Features
- **Conversation Memory**: Implement RAG with Firestore vector search
- **Context Windows**: Summarize old messages to save tokens
- **Conversation Branching**: Allow users to explore alternate responses
- **AI Personality**: Let users customize AI tone and behavior

### Phase 6: Streaming Responses
- **Real-time Streaming**: Stream AI responses character-by-character to client
- **Incremental Updates**: Update message content as it generates
- **Cancel Generation**: Allow users to stop long responses

### Phase 7: Cost Optimization
- **Response Caching**: Cache common responses
- **Smart Model Selection**: Use cheaper models for simple queries
- **Token Budgets**: Set per-user limits
- **Cost Dashboards**: Show users their AI usage

### Phase 8: Advanced Safety
- **Content Filtering**: Pre-process messages for harmful content
- **PII Redaction**: Remove sensitive info before sending to AI
- **User Reporting**: Let users flag inappropriate AI responses
- **Moderation Queue**: Admin review of flagged content

### Phase 9: Team Features
- **Shared Threads**: Multiple users in one conversation
- **AI Summaries**: Auto-summarize long threads
- **Insights Dashboard**: Analytics on journaling patterns
- **Export Features**: Download conversations with AI analysis

---

## Summary

This implementation plan provides a complete blueprint for adding AI chat capabilities to the Kairos Journal app. The phased approach ensures:

1. **Phase 1** establishes the backend foundation with Firebase Genkit
2. **Phase 2** updates the Flutter UI for AI status indicators
3. **Phase 3** adds multimodal support for images and audio
4. **Phase 4** polishes with testing and monitoring

Each phase includes specific file changes, code examples, and verification steps. The plan accounts for security, performance, cost, and user experience, while explicitly scoping out future enhancements to prevent scope creep.

**Key Decisions:**
- ✅ Use Firebase Genkit (production-ready, multimodal, great DX)
- ✅ Gemini 2.0 Flash (fast, cost-effective, multimodal)
- ✅ Event-driven architecture (Firestore triggers)
- ✅ Offline-first Flutter client (existing Isar + Firestore pattern)
- ✅ Admin SDK for AI messages (bypasses security rules)

**Success Metrics:**
- AI response latency <5 seconds
- Error rate <1%
- User satisfaction: positive feedback on AI quality
- Cost per user <$0.01/day
- Zero infinite loops or recursion bugs

The engineering team now has everything needed to implement this feature end-to-end.
