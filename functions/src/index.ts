import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all Cloud Functions

// NEW: Callable functions for explicit client-side orchestration
export { transcribeAudioMessage } from './functions/transcription-callable';
export { analyzeImageMessage } from './functions/image-analysis-callable';
export { generateMessageResponse } from './functions/ai-response-callable';

// Category Insights (NEW - Manual generation only)
export { generateCategoryInsight } from './functions/category-insights-callable';

// Thread Management
export { onThreadDeleted } from './functions/thread-deletion';
