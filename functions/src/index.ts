import * as admin from 'firebase-admin';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getAI, geminiApiKey } from './genkit-config';
import { googleAI } from '@genkit-ai/google-genai';
import { logAiMetrics } from './monitoring';
import {
  extractKeywords,
  analyzeMessagesWithAI,
  aggregateInsights,
} from './insights-helper';

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

    const startTime = Date.now();

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

      // Build conversation context
      const conversationContext = history
        .map(msg => `${msg.role}: ${msg.content}`)
        .join('\n');

      // Generate AI response using Genkit
      const systemPrompt = `You are a helpful AI assistant in a personal journaling app called Kairos.
Be empathetic, supportive, and encouraging. Keep responses concise (2-3 sentences) unless the user asks for more detail.
Help users reflect on their thoughts and feelings.`;

      // Get AI instance with the secret value (only available at runtime)
      const ai = getAI(geminiApiKey.value());

      // Build multimodal prompt parts
      const promptParts: any[] = [{ text: systemPrompt }];

      // Add conversation history
      if (conversationContext) {
        promptParts.push({ text: `Conversation history:\n${conversationContext}` });
      }

      // Handle different message types
      if (messageType === 1) { // Image
        if (messageData.storageUrl) {
          // Download image and convert to data URL
          const imageDataUrl = await getFileAsDataUrl(messageData.storageUrl, 'image/jpeg');
          
          promptParts.push({
            text: 'User sent this image:',
          });
          promptParts.push({
            media: {
              url: imageDataUrl,
              contentType: 'image/jpeg',
            },
          });
          promptParts.push({
            text: 'Describe what you see and respond naturally to the user.',
          });
        } else {
          // Image still uploading
          promptParts.push({
            text: 'User: [User is uploading an image...]',
          });
          console.log('Image still uploading, waiting...');
          return;
        }
      } else if (messageType === 2) { // Audio
        if (messageData.transcription) {
          promptParts.push({
            text: `User said: "${messageData.transcription}"`,
          });
        } else {
          // Transcription not yet available
          console.log('Waiting for audio transcription');
          return;
        }
      } else {
        // Text message
        const userPrompt = messageData.content || '';
        promptParts.push({
          text: `User: ${userPrompt}`,
        });
      }

      promptParts.push({ text: 'Assistant:' });

      // Generate AI response
      const response = await ai.generate({
        prompt: promptParts,
        config: {
          temperature: 0.7,
          maxOutputTokens: 500,
        },
      });

      const text = response.text;
      const latencyMs = Date.now() - startTime;

      // Log metrics
      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: messageType === 0 ? 'text' : messageType === 1 ? 'image' : 'audio',
        inputTokens: response.usage?.inputTokens,
        outputTokens: response.usage?.outputTokens,
        latencyMs,
        success: true,
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

      // Update thread metadata - recalculate accurate message count
      const threadRef = db.collection('journalThreads').doc(threadId);
      const messageCount = await db
        .collection('journalMessages')
        .where('threadId', '==', threadId)
        .where('userId', '==', userId)
        .where('isDeleted', '==', false)
        .count()
        .get();

      await threadRef.update({
        messageCount: messageCount.data().count,
        lastMessageAt: now,
        updatedAtMillis: now,
      });

      console.log(`AI response generated for message ${messageId}`);
    } catch (error) {
      console.error(`Error processing message ${messageId}:`, error);

      const latencyMs = Date.now() - startTime;

      // Log error metrics
      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: messageType === 0 ? 'text' : messageType === 1 ? 'image' : 'audio',
        latencyMs,
        success: false,
        errorMessage: error instanceof Error ? error.message : String(error),
      });

      // Update message status to failed
      await db.collection('journalMessages').doc(messageId).update({
        aiProcessingStatus: 3, // failed
      });

      // Optionally: Send error notification to user
      // TODO: Implement error notification mechanism
    }
  }
);

/**
 * Firestore trigger: When transcription is added to an audio message,
 * generate the AI response.
 *
 * This handles the case where audio messages are created without transcription,
 * and transcription is added later by triggerAudioTranscription.
 */
export const processTranscribedMessage = onDocumentUpdated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      return;
    }

    // Only trigger if:
    // 1. Message is from user (role = 0)
    // 2. Message is audio (messageType = 2)
    // 3. Transcription was just added (before had no transcription, after has transcription)
    // 4. AI processing hasn't completed yet (status != 2)
    if (
      afterData.role !== 0 ||
      afterData.messageType !== 2 ||
      beforeData.transcription ||
      !afterData.transcription ||
      afterData.aiProcessingStatus === 2
    ) {
      return;
    }

    const messageId = event.params.messageId;
    const threadId = afterData.threadId as string;
    const userId = afterData.userId as string;

    console.log(`Transcription added to message ${messageId}, generating AI response`);

    const startTime = Date.now();

    try {
      // Update message status to processing
      await db.collection('journalMessages').doc(messageId).update({
        aiProcessingStatus: 1, // processing
      });

      // Get conversation history
      const conversationSnapshot = await db
        .collection('journalMessages')
        .where('threadId', '==', threadId)
        .where('userId', '==', userId)
        .where('isDeleted', '==', false)
        .orderBy('createdAtMillis', 'asc')
        .limit(10)
        .get();

      let conversationContext = '';
      for (const doc of conversationSnapshot.docs) {
        if (doc.id === messageId) break; // Don't include current message
        const msg = doc.data();
        const roleLabel = msg.role === 0 ? 'User' : 'Assistant';
        const content = msg.content || msg.transcription || '[media message]';
        conversationContext += `${roleLabel}: ${content}\n`;
      }

      const systemPrompt = `You are a helpful AI assistant in a personal journaling app called Kairos.
Be empathetic, supportive, and encouraging. Keep responses concise (2-3 sentences) unless the user asks for more detail.
Help users reflect on their thoughts and feelings.`;

      // Get AI instance
      const ai = getAI(geminiApiKey.value());

      // Build prompt with transcription
      const promptParts: any[] = [{ text: systemPrompt }];

      if (conversationContext) {
        promptParts.push({ text: `Conversation history:\n${conversationContext}` });
      }

      promptParts.push({
        text: `User said: "${afterData.transcription}"`,
      });

      promptParts.push({ text: 'Assistant:' });

      // Generate AI response
      const response = await ai.generate({
        prompt: promptParts,
        config: {
          temperature: 0.7,
          maxOutputTokens: 500,
        },
      });

      const text = response.text;
      const latencyMs = Date.now() - startTime;

      // Log metrics
      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: 'audio',
        inputTokens: response.usage?.inputTokens,
        outputTokens: response.usage?.outputTokens,
        latencyMs,
        success: true,
      });

      // Create AI response message
      const now = Date.now();
      await db.collection('journalMessages').add({
        threadId,
        userId,
        role: 1, // assistant
        content: text,
        messageType: 0, // text
        createdAtMillis: now,
        updatedAtMillis: now,
        isDeleted: false,
        aiProcessingStatus: 0, // not applicable for AI messages
        version: 1,
      });

      // Update original message status to completed
      await db.collection('journalMessages').doc(messageId).update({
        aiProcessingStatus: 2, // completed
      });

      // Update thread metadata
      const threadRef = db.collection('journalThreads').doc(threadId);
      const messageCount = await db
        .collection('journalMessages')
        .where('threadId', '==', threadId)
        .where('userId', '==', userId)
        .where('isDeleted', '==', false)
        .count()
        .get();

      await threadRef.update({
        messageCount: messageCount.data().count,
        lastMessageAt: now,
        updatedAtMillis: now,
      });

      console.log(`AI response generated for transcribed message ${messageId}`);
    } catch (error) {
      console.error(`Error processing transcribed message ${messageId}:`, error);

      const latencyMs = Date.now() - startTime;

      // Log error metrics
      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: 'audio',
        latencyMs,
        success: false,
        errorMessage: error instanceof Error ? error.message : String(error),
      });

      // Update message status to failed
      await db.collection('journalMessages').doc(messageId).update({
        aiProcessingStatus: 3, // failed
      });
    }
  }
);

/**
 * Helper function to extract storage path from Firebase Storage URL
 */
function extractStoragePath(url: string): string {
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

/**
 * Helper function to download file from Firebase Storage and convert to base64 data URL
 * Works for both audio and image files
 */
async function getFileAsDataUrl(storageUrl: string, contentType: string): Promise<string> {
  try {
    const storagePath = extractStoragePath(storageUrl);
    console.log(`Attempting to download from path: ${storagePath}`);

    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);

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
      console.warn(`File is suspiciously small (${buffer.length} bytes). Content: ${buffer.toString('utf8').substring(0, 100)}`);
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

// Using data URL via getFileAsDataUrl for media parts (images and audio)

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

      // Download audio and convert to data URL for Gemini
      const audioDataUrl = await getFileAsDataUrl(audioUrl, 'audio/mp4');

      // Get AI instance
      const ai = getAI(geminiApiKey.value());

      // Use Gemini for transcription (supports audio input)
      // m4a files should use audio/mp4 content type
      const { text } = await ai.generate({
        model: googleAI.model('gemini-2.0-flash'),
        prompt: [
          { text: 'Transcribe this audio recording accurately. Output only the transcription text, no additional commentary.' },
          { media: { url: audioDataUrl, contentType: 'audio/mp4' } },
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

      // Mark AI processing as failed so user can retry
      await db.collection('journalMessages').doc(messageId).update({
        aiProcessingStatus: 3, // failed
      });

      const message = error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `Transcription failed: ${message}`);
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
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { messageId } = request.data as { messageId: string };

    if (!messageId) {
      throw new HttpsError('invalid-argument', 'messageId required');
    }

    console.log(`Retrying AI response for message ${messageId}`);

    try {
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

      // Verify this is a user message
      if (messageData.role !== 0) {
        throw new HttpsError('invalid-argument', 'Can only retry user messages');
      }

      // If it's an audio message without transcription, retry transcription first
      const messageType = messageData.messageType as number;
      if (messageType === 2 && !messageData.transcription && messageData.storageUrl) {
        console.log(`Retrying transcription for audio message ${messageId}`);

        try {
          // Download audio and convert to data URL for Gemini
          const audioDataUrl = await getFileAsDataUrl(messageData.storageUrl, 'audio/mp4');
          const ai = getAI(geminiApiKey.value());

          const { text } = await ai.generate({
            model: googleAI.model('gemini-2.0-flash'),
            prompt: [
              { text: 'Transcribe this audio accurately. Output only the transcription text.' },
              { media: { url: audioDataUrl, contentType: 'audio/mp4' } },
            ],
          });

          // Update with transcription and reset AI status to trigger processing
          await messageDoc.ref.update({
            transcription: text,
            aiProcessingStatus: 0, // pending - will trigger AI response
          });

          console.log(`Transcription retry successful for ${messageId}`);
        } catch (transcriptionError) {
          console.error(`Transcription retry failed for ${messageId}:`, transcriptionError);
          throw new HttpsError('internal', 'Transcription retry failed. Please try again.');
        }
      } else {
        // For text/image messages or audio with transcription, just reset AI status
        await messageDoc.ref.update({
          aiProcessingStatus: 0, // pending
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
        // Download audio and convert to data URL for Gemini
        const audioDataUrl = await getFileAsDataUrl(afterData.storageUrl, 'audio/mp4');

        // Get AI instance
        const ai = getAI(geminiApiKey.value());

        const { text } = await ai.generate({
          model: googleAI.model('gemini-2.0-flash'),
          prompt: [
            { text: 'Transcribe this audio accurately. Output only the transcription text.' },
            { media: { url: audioDataUrl, contentType: 'audio/mp4' } },
          ],
        });

        await db.collection('journalMessages').doc(messageId).update({
          transcription: text,
        });

        console.log(`Auto-transcription complete for ${messageId}`);
      } catch (error) {
        console.error(`Auto-transcription failed for ${messageId}:`, error);

        // Mark AI processing as failed so user can retry
        await db.collection('journalMessages').doc(messageId).update({
          aiProcessingStatus: 3, // failed
        });
      }
    }
  }
);

/**
 * Firestore trigger: When a new AI message is created,
 * generate or update insights for the thread and global view
 *
 * Hybrid approach with debouncing:
 * - Updates existing insight if within 2-3 day window
 * - Creates new insight if no recent insight exists
 * - Debounces to max once per hour per user to prevent over-firing
 */
export const generateInsight = onDocumentCreated(
  {
    document: 'journalMessages/{messageId}',
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    // Only process AI messages (role = 1)
    if (messageData.role !== 1) {
      console.log('Skipping non-AI message for insight generation');
      return;
    }

    const threadId = messageData.threadId as string;
    const userId = messageData.userId as string;
    const now = Date.now();
    const threeDaysAgo = now - 3 * 24 * 60 * 60 * 1000;
    const oneHourAgo = now - 60 * 60 * 1000;

    console.log(`Generating insight for thread ${threadId}`);

    try {
      // 0. Debounce check: Skip if insight was updated within last hour
      const recentUpdateSnapshot = await db
        .collection('insights')
        .where('userId', '==', userId)
        .where('threadId', '==', threadId)
        .where('updatedAtMillis', '>=', oneHourAgo)
        .limit(1)
        .get();

      if (!recentUpdateSnapshot.empty) {
        console.log(`Skipping insight generation - updated within last hour for thread ${threadId}`);
        return;
      }

      // 1. Query recent messages from this thread (last 3 days)
      const messagesSnapshot = await db
        .collection('journalMessages')
        .where('threadId', '==', threadId)
        .where('userId', '==', userId)
        .where('isDeleted', '==', false)
        .where('createdAtMillis', '>=', threeDaysAgo)
        .orderBy('createdAtMillis', 'asc')
        .get();

      if (messagesSnapshot.empty) {
        console.log('No recent messages found for insight generation');
        return;
      }

      const messages = messagesSnapshot.docs.map(doc => ({
        content: doc.data().content || doc.data().transcription || '',
        role: doc.data().role,
        createdAtMillis: doc.data().createdAtMillis,
      }));

      // 2. Extract keywords using frequency analysis
      const keywords = extractKeywords(messages);

      // 3. Analyze with AI
      const ai = getAI(geminiApiKey.value());
      const analysis = await analyzeMessagesWithAI(ai, messages);
      analysis.keywords = keywords;

      // 4. Determine period start/end
      const periodStart = messages[0].createdAtMillis;
      const periodEnd = now;

      // 5. Check if recent per-thread insight exists (within last 24 hours)
      const recentInsightSnapshot = await db
        .collection('insights')
        .where('userId', '==', userId)
        .where('threadId', '==', threadId)
        .where('periodEndMillis', '>=', now - 24 * 60 * 60 * 1000)
        .limit(1)
        .get();

      let insightId: string;
      let insightRef: admin.firestore.DocumentReference;

      if (!recentInsightSnapshot.empty) {
        // Update existing insight
        const existingInsight = recentInsightSnapshot.docs[0];
        insightId = existingInsight.id;
        insightRef = existingInsight.ref;

        await insightRef.update({
          periodEndMillis: periodEnd,
          moodScore: analysis.moodScore,
          dominantEmotion: analysis.dominantEmotion,
          keywords: analysis.keywords,
          aiThemes: analysis.aiThemes,
          summary: analysis.summary,
          messageCount: messages.length,
          updatedAtMillis: now,
        });

        console.log(`Updated existing insight ${insightId}`);
      } else {
        // Create new per-thread insight
        insightId = `${userId}_${threadId}_${periodStart}`;
        insightRef = db.collection('insights').doc(insightId);

        await insightRef.set({
          id: insightId,
          userId,
          type: 0, // thread insight
          threadId,
          periodStartMillis: periodStart,
          periodEndMillis: periodEnd,
          moodScore: analysis.moodScore,
          dominantEmotion: analysis.dominantEmotion,
          keywords: analysis.keywords,
          aiThemes: analysis.aiThemes,
          summary: analysis.summary,
          messageCount: messages.length,
          createdAtMillis: now,
          updatedAtMillis: now,
          isDeleted: false,
          version: 1,
        });

        console.log(`Created new insight ${insightId}`);
      }

      // 6. Generate or update global insight
      await generateGlobalInsight(userId, now);

      console.log(`Insight generation complete for thread ${threadId}`);
    } catch (error) {
      console.error('Error generating insight:', error);
    }
  }
);

/**
 * Helper function to generate global aggregated insight
 */
async function generateGlobalInsight(userId: string, now: number) {
  try {
    const threeDaysAgo = now - 3 * 24 * 60 * 60 * 1000;

    // Get all per-thread insights from last 3 days
    const threadInsightsSnapshot = await db
      .collection('insights')
      .where('userId', '==', userId)
      .where('threadId', '!=', null)
      .where('periodEndMillis', '>=', threeDaysAgo)
      .get();

    if (threadInsightsSnapshot.empty) {
      console.log('No thread insights found for global aggregation');
      return;
    }

    const threadInsights = threadInsightsSnapshot.docs.map(doc => doc.data());

    // Aggregate thread insights
    const aggregated = aggregateInsights(threadInsights);
    if (!aggregated) return;

    // Find earliest periodStart among thread insights
    const periodStart = Math.min(
      ...threadInsights.map(ins => ins.periodStartMillis)
    );

    // Check if recent global insight exists (within last 24 hours)
    const recentGlobalSnapshot = await db
      .collection('insights')
      .where('userId', '==', userId)
      .where('threadId', '==', null)
      .where('periodEndMillis', '>=', now - 24 * 60 * 60 * 1000)
      .limit(1)
      .get();

    let globalInsightId: string;
    let globalRef: admin.firestore.DocumentReference;

    if (!recentGlobalSnapshot.empty) {
      // Update existing global insight
      const existingGlobal = recentGlobalSnapshot.docs[0];
      globalInsightId = existingGlobal.id;
      globalRef = existingGlobal.ref;

      await globalRef.update({
        periodEndMillis: now,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
        updatedAtMillis: now,
      });

      console.log(`Updated global insight ${globalInsightId}`);
    } else {
      // Create new global insight
      globalInsightId = `${userId}_global_${periodStart}`;
      globalRef = db.collection('insights').doc(globalInsightId);

      await globalRef.set({
        id: globalInsightId,
        userId,
        type: 1, // global insight
        threadId: null,
        periodStartMillis: periodStart,
        periodEndMillis: now,
        moodScore: aggregated.moodScore,
        dominantEmotion: aggregated.dominantEmotion,
        keywords: aggregated.keywords,
        aiThemes: aggregated.aiThemes,
        summary: aggregated.summary,
        messageCount: aggregated.messageCount,
        createdAtMillis: now,
        updatedAtMillis: now,
        isDeleted: false,
        version: 1,
      });

      console.log(`Created global insight ${globalInsightId}`);
    }
  } catch (error) {
    console.error('Error generating global insight:', error);
  }
}

