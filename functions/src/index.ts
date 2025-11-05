import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
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
