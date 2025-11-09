import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import { enableFirebaseTelemetry } from '@genkit-ai/firebase';
import { defineSecret } from 'firebase-functions/params';

// Define secrets for API keys
export const geminiApiKey = defineSecret('GEMINI_API_KEY');

// Enable Firebase telemetry for monitoring
enableFirebaseTelemetry();

// Lazy initialization to avoid accessing secret during deployment
let aiInstance: ReturnType<typeof genkit> | null = null;

export function getAI(apiKey: string) {
  if (!aiInstance) {
    aiInstance = genkit({
      plugins: [
        googleAI({
          apiKey,
        }),
      ],
      model: googleAI.model('gemini-2.0-flash'),
    });
  }
  return aiInstance;
}
