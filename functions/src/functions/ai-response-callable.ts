import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { createAiService } from '../services/ai-service';
import { getMessageRepository } from '../data/repositories';
import { createConversationBuilder } from '../domain/conversation/conversation-builder';
import { MessageRole, MessageType, MessageStatus } from '../config/constants';

const db = admin.firestore();

/**
 * Callable function to generate AI response to a user message
 *
 * Replaces Firestore triggers: processUserMessage, processTranscribedMessage
 * Called explicitly by client after message is ready (text/transcription/image analysis done)
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

    console.log(`Generating AI response for message ${messageId} by user ${userId}`);

    // 3. Initialize services
    const messageRepo = getMessageRepository(db);  // instance of MessageRepository
    const aiService = createAiService(geminiApiKey.value());  // instance of AiService  
    const conversationBuilder = createConversationBuilder(db);  // instance of ConversationBuilder

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

      // 6. Build conversation context
      const context = await conversationBuilder.buildConversationContext(
        threadId,
        userId,
        messageId
      );

      // 7. Generate AI response based on message type
      let aiResponse;

      if (message.messageType === MessageType.TEXT) {
        // Text message - use content directly
        if (!message.content) {
          throw new HttpsError('invalid-argument', 'Text message has no content');
        }
        aiResponse = await aiService.generateTextResponse(
          message.content,
          context
        );
      } else if (message.messageType === MessageType.AUDIO) {
        // Audio message - use transcription
        if (!message.transcription) {
          throw new HttpsError(
            'invalid-argument',
            'Audio message not transcribed yet'
          );
        }
        aiResponse = await aiService.generateTextResponse(
          message.transcription,
          context
        );
      } else if (message.messageType === MessageType.IMAGE) {
        // Image message - use storage URL for multimodal generation
        if (!message.storageUrl) {
          throw new HttpsError(
            'invalid-argument',
            'Image message not uploaded yet'
          );
        }
        aiResponse = await aiService.generateImageResponse(
          message.storageUrl,
          context
        );
      } else {
        throw new HttpsError('invalid-argument', 'Unknown message type');
      }

      // 8. Update original user message to processed status
      await messageRepo.update(messageId, {
        status: MessageStatus.PROCESSED,
      });

      // 9. Save AI response as new message (created directly in Firestore)
      const responseMessage = {
        threadId,
        userId,
        role: MessageRole.AI,
        messageType: MessageType.TEXT,
        content: aiResponse.text,
        status: MessageStatus.REMOTE_CREATED, // Backend-created messages are remoteCreated
      };

      await messageRepo.create(responseMessage);

      console.log(`AI response created for message ${messageId}`);

      // 10. Return success
      return {
        success: true,
        message: 'AI response generated successfully',
      };
    } catch (error) {
      console.error(`AI response generation failed for message ${messageId}:`, error);

      if (error instanceof HttpsError) {
        throw error;
      }

      const message =
        error instanceof Error ? error.message : String(error);
      throw new HttpsError('internal', `AI response generation failed: ${message}`);
    }
  }
);

