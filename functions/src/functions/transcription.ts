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

