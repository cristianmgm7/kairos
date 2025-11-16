import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all Cloud Functions

// NEW: Callable functions for explicit client-side orchestration
export { transcribeAudioMessage } from './functions/transcription-callable';
export { analyzeImageMessage } from './functions/image-analysis-callable';
export { generateMessageResponse } from './functions/ai-response-callable';
export { generatePeriodInsight } from './functions/insights-callable';

// DEPRECATED: Firestore triggers (replaced by callable functions above)
// Commented out to prevent conflicts with new architecture
// export {
//   processUserMessage,
//   processImageUpload,
//   processTranscribedMessage,
// } from './functions/message-triggers';
// export {
//   transcribeAudio,
//   triggerAudioTranscription,
//   retryAiResponse,
// } from './functions/transcription';
export { generateInsight } from './functions/insights-triggers';
export { generateDailyInsights } from './functions/scheduled-insights';
export { onThreadDeleted } from './functions/thread-deletion';
