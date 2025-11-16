import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { geminiApiKey } from '../config/genkit';
import { getMessageRepository } from '../data/repositories';
import { runKairos } from '../agents/kairos.agent';
import { MessageRole, MessageType, MessageStatus } from '../config/constants';

const db = admin.firestore();

/**
 * Callable function to generate AI response to a user message
 *
 * NEW: Uses Kairos agent with tools, memory, and session management
 *
 * Flow:
 * 1. Authenticate and authorize
 * 2. Retrieve user message
 * 3. Run Kairos agent (handles session, tools, memory)
 * 4. Save AI response
 * 5. Update message status
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

    console.log(`[Agent] Generating AI response for message ${messageId} by user ${userId}`);

    // 3. Initialize services
    const messageRepo = getMessageRepository(db);

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

      // 6. Prepare user input based on message type
      let userInput: string;

      if (message.messageType === MessageType.TEXT) {
        if (!message.content) {
          throw new HttpsError('invalid-argument', 'Text message has no content');
        }
        userInput = message.content;
      } else if (message.messageType === MessageType.AUDIO) {
        if (!message.transcription) {
          throw new HttpsError(
            'invalid-argument',
            'Audio message not transcribed yet'
          );
        }
        userInput = message.transcription;
      } else if (message.messageType === MessageType.IMAGE) {
        // For image messages, create descriptive input
        // Note: Multimodal vision will be handled separately
        userInput = '[User shared an image]';
        // TODO: Integrate image analysis with agent in future iteration
      } else {
        throw new HttpsError('invalid-argument', 'Unknown message type');
      }

      // 7. Run Kairos agent
      console.log(`[Agent] Running Kairos agent for thread ${threadId}`);

      const agentResponse = await runKairos(
        {
          userId,
          threadId,
          apiKey: geminiApiKey.value(),
          excludeMessageId: messageId, // Don't include current message in history
        },
        userInput
      );

      console.log(`[Agent] Response generated. Tools used: ${agentResponse.toolsUsed.join(', ') || 'none'}`);
      console.log(`[Agent] Memories retrieved: ${agentResponse.memoriesRetrieved}`);

      // 8. Update original user message to processed status
      await messageRepo.update(messageId, {
        status: MessageStatus.PROCESSED,
      });

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

      // 10. Return success with metadata
      return {
        success: true,
        message: 'AI response generated successfully',
        metadata: {
          toolsUsed: agentResponse.toolsUsed,
          memoriesRetrieved: agentResponse.memoriesRetrieved,
          tokensUsed: agentResponse.usage,
        },
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

