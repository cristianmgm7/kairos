import { SYSTEM_PROMPT } from '../../config/constants';

export interface PromptContext {
  systemPrompt?: string;
  conversationContext?: string;
  userMessage?: string;
  userTranscription?: string;
  imageUrl?: string;
}

export class PromptBuilder {
  /**
   * Build multimodal prompt parts for AI generation
   */
  buildPromptParts(context: PromptContext): any[] {
    const parts: any[] = [];

    // Add system prompt
    parts.push({ text: context.systemPrompt ?? SYSTEM_PROMPT });

    // Add conversation history
    if (context.conversationContext) {
      parts.push({ text: `Conversation history:\n${context.conversationContext}` });
    }

    // Add user message (text, transcription, or image)
    if (context.userMessage) {
      parts.push({ text: `User: ${context.userMessage}` });
    } else if (context.userTranscription) {
      parts.push({ text: `User said: "${context.userTranscription}"` });
    }

    // Add assistant prompt
    parts.push({ text: 'Assistant:' });

    return parts;
  }

  /**
   * Build prompt parts for text message
   */
  buildTextPrompt(conversationContext: string, userMessage: string): any[] {
    return this.buildPromptParts({
      conversationContext,
      userMessage,
    });
  }

  /**
   * Build prompt parts for audio message (with transcription)
   */
  buildAudioPrompt(conversationContext: string, transcription: string): any[] {
    return this.buildPromptParts({
      conversationContext,
      userTranscription: transcription,
    });
  }
}

// Singleton instance
let promptBuilderInstance: PromptBuilder | null = null;

export function getPromptBuilder(): PromptBuilder {
  if (!promptBuilderInstance) {
    promptBuilderInstance = new PromptBuilder();
  }
  return promptBuilderInstance;
}

