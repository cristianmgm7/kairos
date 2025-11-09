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
        messageType: messageType === MessageType.TEXT ? 'text' : messageType === MessageType.IMAGE ? 'image' : 'audio',
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
        messageType: messageType === MessageType.TEXT ? 'text' : messageType === MessageType.IMAGE ? 'image' : 'audio',
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
 * Firestore trigger: When storageUrl is added to an image message,
 * generate the AI response.
 */
export const processImageUpload = onDocumentUpdated(
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

    // Debug logging
    console.log('processImageUpload triggered for message:', event.params.messageId);
    console.log('Before storageUrl:', beforeData.storageUrl);
    console.log('After storageUrl:', afterData.storageUrl);
    console.log('Role:', afterData.role, 'Expected:', MessageRole.USER);
    console.log('MessageType:', afterData.messageType, 'Expected:', MessageType.IMAGE);
    console.log('AiProcessingStatus:', afterData.aiProcessingStatus, 'Completed?:', afterData.aiProcessingStatus === AiProcessingStatus.COMPLETED);

    // Only trigger if:
    // 1. Message is from user
    // 2. Message is image type
    // 3. storageUrl was just added (before had no storageUrl, after has storageUrl)
    // 4. AI processing hasn't completed yet
    if (
      afterData.role !== MessageRole.USER ||
      afterData.messageType !== MessageType.IMAGE ||
      beforeData.storageUrl ||
      !afterData.storageUrl ||
      afterData.aiProcessingStatus === AiProcessingStatus.COMPLETED
    ) {
      console.log('Skipping processImageUpload - conditions not met');
      return;
    }

    const messageId = event.params.messageId;
    const threadId = afterData.threadId as string;
    const userId = afterData.userId as string;

    console.log(`Image uploaded for message ${messageId}, generating AI response`);

    const startTime = Date.now();
    const messageRepo = getMessageRepository(db);
    const threadRepo = getThreadRepository(db);
    const conversationBuilder = createConversationBuilder(db);
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

      // Generate AI response for image
      const aiResponse = await aiService.generateImageResponse(
        afterData.storageUrl,
        conversationContext
      );

      const latencyMs = Date.now() - startTime;

      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: 'image',
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

      console.log(`AI response generated for image message ${messageId}`);
    } catch (error) {
      console.error(`Error processing image message ${messageId}:`, error);

      const latencyMs = Date.now() - startTime;

      logAiMetrics({
        messageId,
        userId,
        threadId,
        messageType: 'image',
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

