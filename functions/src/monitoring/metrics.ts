import { logger } from 'firebase-functions/v2';

export interface AiMetrics {
  messageId: string;
  userId: string;
  threadId: string;
  messageType: 'text' | 'image' | 'audio';
  inputTokens?: number;
  outputTokens?: number;
  latencyMs: number;
  success: boolean;
  errorMessage?: string;
}

export function logAiMetrics(metrics: AiMetrics) {
  logger.info('AI_METRICS', {
    messageId: metrics.messageId,
    userId: metrics.userId,
    threadId: metrics.threadId,
    messageType: metrics.messageType,
    inputTokens: metrics.inputTokens || 0,
    outputTokens: metrics.outputTokens || 0,
    latencyMs: metrics.latencyMs,
    success: metrics.success,
    errorMessage: metrics.errorMessage,
  });
}
