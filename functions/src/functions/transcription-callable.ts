import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { getMessageRepository } from '../data/repositories';
import { MessageRole } from '../config/constants';

const db = admin.firestore();

/**
 * Callable function to transcribe audio message
 *
 * Replaces Firestore trigger: triggerAudioTranscription
 * Called explicitly by client after audio upload completes
 */
export const transcribeAudioMessage = onCall(
  {
    secrets: [geminiApiKey],
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async (request) => {
    // 1. Authentication
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    // 2. Extract and validate parameters
    const { messageId, audioUrl } = request.data as {
      messageId: string;
      audioUrl: string;
    };

    if (!messageId || !audioUrl) {
      throw new HttpsError(
        'invalid-argument',
        'messageId and audioUrl required'
      );
    }

    console.log(`Transcribing audio for message ${messageId} by user ${userId}`);

    // 3. Initialize services
    const messageRepo = getMessageRepository(db);
    const aiService = createAiService(geminiApiKey.value());

    try {
      // 4. Authorization check - verify user owns the message
      const message = await messageRepo.getById(messageId);
      if (!message || message.userId !== userId) {
        throw new HttpsError(
          'permission-denied',
          'Message not found or access denied'
        );
      }

      // 5. Validate message type
      if (message.role !== MessageRole.USER) {
        throw new HttpsError(
          'invalid-argument',
          'Can only transcribe user messages'
        );
      }

      // 6. Call AI service to transcribe
      const result = await aiService.transcribeAudio(audioUrl);

      console.log(`Transcription complete for message ${messageId}`);

      // 7. Return transcription (client will update message)
      return {
        success: true,
        transcription: result.text,
      };
    } catch (error) {
      console.error(`Transcription failed for message ${messageId}:`, error);

      // Re-throw HttpsError as-is
      if (error instanceof HttpsError) {
        throw error;
      }

      // Convert other errors
      const message =
        error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `Transcription failed: ${message}`);
    }
  }
);

