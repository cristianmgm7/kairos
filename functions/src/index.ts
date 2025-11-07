import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all Cloud Functions
export {
  processUserMessage,
  processImageUpload,
  processTranscribedMessage,
} from './functions/message-triggers';
export {
  transcribeAudio,
  triggerAudioTranscription,
  retryAiResponse,
} from './functions/transcription';
export { generateInsight } from './functions/insights-triggers';
