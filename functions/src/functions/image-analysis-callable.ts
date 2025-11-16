import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { getMessageRepository } from '../data/repositories';
import { MessageRole } from '../config/constants';

const db = admin.firestore();

/**
 * Callable function to analyze image message content
 *
 * Replaces Firestore trigger: processImageUpload
 * Called explicitly by client after image upload completes
 */
export const analyzeImageMessage = onCall(
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
    const { messageId, imageUrl } = request.data as {
      messageId: string;
      imageUrl: string;
    };

    if (!messageId || !imageUrl) {
      throw new HttpsError(
        'invalid-argument',
        'messageId and imageUrl required'
      );
    }

    console.log(`Analyzing image for message ${messageId} by user ${userId}`);

    // 3. Initialize services
    const messageRepo = getMessageRepository(db);
    const aiService = createAiService(geminiApiKey.value());

    try {
      // 4. Authorization check
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
          'Can only analyze user messages'
        );
      }

      // 6. Analyze image with AI
      // Build simple prompt for image description
      const prompt = 'Describe what you see in this image. If there is any text, transcribe it accurately.';

      // Note: we're not building full conversation context here
      // Just analyzing the image standalone for transcription/description
      const result = await aiService.generateImageResponse(imageUrl, prompt);

      console.log(`Image analysis complete for message ${messageId}`);

      // 7. Return description (client will update message)
      return {
        success: true,
        description: result.text,
      };
    } catch (error) {
      console.error(`Image analysis failed for message ${messageId}:`, error);

      if (error instanceof HttpsError) {
        throw error;
      }

      const message =
        error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `Image analysis failed: ${message}`);
    }
  }
);

