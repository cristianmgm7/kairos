import { googleAI } from '@genkit-ai/google-genai';
import { getAI } from '../config/genkit';
import { getStorageService } from './storage-service';
import { AI_CONFIG } from '../config/constants';

export interface AiGenerateOptions {
  prompt: any[];
  temperature?: number;
  maxOutputTokens?: number;
}

export interface AiResponse {
  text: string;
  usage?: {
    inputTokens?: number;
    outputTokens?: number;
  };
}

export interface TranscriptionResult {
  text: string;
}

export class AiService {
  private apiKey: string;
  private storageService: ReturnType<typeof getStorageService>;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
    this.storageService = getStorageService();
  }

  /**
   * Generate AI response with Genkit
   */
  async generate(options: AiGenerateOptions): Promise<AiResponse> {
    const ai = getAI(this.apiKey);

    const response = await ai.generate({
      prompt: options.prompt,
      config: {
        temperature: options.temperature ?? AI_CONFIG.temperature,
        maxOutputTokens: options.maxOutputTokens ?? AI_CONFIG.maxOutputTokens,
      },
    });

    return {
      text: response.text,
      usage: response.usage,
    };
  }

  /**
   * Transcribe audio using Gemini 2.0 Flash
   */
  async transcribeAudio(audioUrl: string): Promise<TranscriptionResult> {
    const ai = getAI(this.apiKey);

    // Download audio and convert to data URL
    const audioDataUrl = await this.storageService.getAudioAsDataUrl(audioUrl);

    const { text } = await ai.generate({
      model: googleAI.model('gemini-2.0-flash'),
      prompt: [
        {
          text: 'Transcribe this audio recording accurately. Output only the transcription text, no additional commentary.',
        },
        { media: { url: audioDataUrl, contentType: 'audio/mp4' } },
      ],
    });

    return { text };
  }

  /**
   * Generate response for image message
   */
  async generateImageResponse(
    imageUrl: string,
    conversationContext: string
  ): Promise<AiResponse> {
    const imageDataUrl = await this.storageService.getImageAsDataUrl(imageUrl);

    const promptParts: any[] = [
      { text: conversationContext },
      { text: 'User sent this image:' },
      { media: { url: imageDataUrl, contentType: 'image/jpeg' } },
      { text: 'Describe what you see and respond naturally to the user.' },
      { text: 'Assistant:' },
    ];

    return this.generate({ prompt: promptParts });
  }

  /**
   * Generate response for text or audio message
   */
  async generateTextResponse(
    userMessage: string,
    conversationContext: string
  ): Promise<AiResponse> {
    const promptParts: any[] = [
      { text: conversationContext },
      { text: `User: ${userMessage}` },
      { text: 'Assistant:' },
    ];

    return this.generate({ prompt: promptParts });
  }

  /**
   * Analyze messages for insights
   */
  async analyzeForInsights(prompt: string): Promise<AiResponse> {
    return this.generate({
      prompt: [{ text: prompt }],
      temperature: 0.3,
      maxOutputTokens: 500,
    });
  }
}

// Factory function
export function createAiService(apiKey: string): AiService {
  return new AiService(apiKey);
}

