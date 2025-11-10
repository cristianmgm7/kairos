import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all Cloud Functions

// NEW: Callable functions for explicit client-side orchestration
export { transcribeAudioMessage } from './functions/transcription-callable';
export { analyzeImageMessage } from './functions/image-analysis-callable';
export { generateMessageResponse } from './functions/ai-response-callable';

// EXISTING: Firestore triggers (will be deprecated after migration)
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
export { onThreadDeleted } from './functions/thread-deletion';
