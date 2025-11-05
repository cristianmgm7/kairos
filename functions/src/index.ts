import * as admin from 'firebase-admin';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getAI, geminiApiKey } from './genkit-config';
import { googleAI } from '@genkit-ai/google-genai';
import { logAiMetrics } from './monitoring';

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
 * Helper function to extract storage path from Firebase Storage URL
 */
function extractStoragePath(url: string): string {
  // Extract path from URLs like:
  // https://firebasestorage.googleapis.com/v0/b/bucket/o/path%2Fto%2Ffile.m4a?alt=media&token=...
  const match = url.match(/\/o\/(.+?)\?/);
  if (!match) {
    throw new Error('Invalid Firebase Storage URL');
  }
  return decodeURIComponent(match[1]);
}

/**
 * Helper function to download file from Firebase Storage and convert to base64 data URL
 * Works for both audio and image files
 */
async function getFileAsDataUrl(storageUrl: string, contentType: string): Promise<string> {
  try {
    const storagePath = extractStoragePath(storageUrl);
    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);

    // Download file as buffer
    const [buffer] = await file.download();
    
    // Convert to base64 data URL
    const base64Data = buffer.toString('base64');
    const dataUrl = `data:${contentType};base64,${base64Data}`;
    
    console.log(`Downloaded file: ${storagePath}, size: ${buffer.length} bytes`);
    
    return dataUrl;
  } catch (error) {
    console.error('Failed to download file:', error);
    throw error;
  }
}

/**
 * Helper: generate a V4 signed URL for a Storage file (valid ~1 hour)
 */
async function getSignedFileUrl(storageUrl: string): Promise<string> {
  try {
    const storagePath = extractStoragePath(storageUrl);
    const bucket = admin.storage().bucket();
    const file = bucket.file(storagePath);

    const [signedUrl] = await file.getSignedUrl({
      action: 'read',
      version: 'v4',
      expires: Date.now() + 60 * 60 * 1000, // 1 hour
    });

    console.log(`Generated signed URL for ${storagePath}`);
    return signedUrl;
  } catch (error) {
    console.error('Failed to create signed URL:', error);
    throw error;
  }
}

// Removed inlineData helper; using data URL via getFileAsDataUrl for media parts

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

      // Generate signed URL so Gemini can fetch the audio
      const signedAudioUrl = await getSignedFileUrl(audioUrl);

      // Get AI instance
      const ai = getAI(geminiApiKey.value());

      // Use Gemini for transcription (supports audio input)
      // m4a files should use audio/mp4 content type
      const { text } = await ai.generate({
        model: googleAI.model('gemini-2.0-flash'),
        prompt: [
          { text: 'Transcribe this audio recording accurately. Output only the transcription text, no additional commentary.' },
          { media: { url: signedAudioUrl, contentType: 'audio/mp4' } },
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
          const signedAudioUrl = await getSignedFileUrl(messageData.storageUrl);
          const ai = getAI(geminiApiKey.value());

          const { text } = await ai.generate({
            model: googleAI.model('gemini-2.0-flash'),
            prompt: [
              { text: 'Transcribe this audio accurately. Output only the transcription text.' },
              { media: { url: signedAudioUrl, contentType: 'audio/mp4' } },
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
        // Generate signed URL so Gemini can fetch the audio
        const signedAudioUrl = await getSignedFileUrl(afterData.storageUrl);

        // Get AI instance
        const ai = getAI(geminiApiKey.value());

        const { text } = await ai.generate({
          model: googleAI.model('gemini-2.0-flash'),
          prompt: [
            { text: 'Transcribe this audio accurately. Output only the transcription text.' },
            { media: { url: signedAudioUrl, contentType: 'audio/mp4' } },
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
