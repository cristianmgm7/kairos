import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import { enableFirebaseTelemetry } from '@genkit-ai/firebase';
import { defineSecret } from 'firebase-functions/params';

// Define secrets for API keys
export const geminiApiKey = defineSecret('GEMINI_API_KEY');

// Initialize Genkit with Google AI plugin
export const ai = genkit({
  plugins: [
    googleAI({
      apiKey: geminiApiKey.value(),
    }),
  ],
  model: googleAI.model('gemini-2.0-flash'),
});

// Enable Firebase telemetry for monitoring
enableFirebaseTelemetry();
