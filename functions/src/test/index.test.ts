import { expect } from 'chai';
import { logAiMetrics } from '../monitoring/metrics.js';
import {
  transcribeAudioMessage,
  analyzeImageMessage,
  generateMessageResponse,
  generateInsight,
  onThreadDeleted,
} from '../index.js';

describe('Cloud Functions', () => {
  describe('Monitoring', () => {
    it('should export logAiMetrics function', () => {
      expect(logAiMetrics).to.be.a('function');
    });
  });

  describe('New Callable Functions', () => {
    it('should export transcribeAudioMessage', () => {
      expect(transcribeAudioMessage).to.exist;
    });

    it('should export analyzeImageMessage', () => {
      expect(analyzeImageMessage).to.exist;
    });

    it('should export generateMessageResponse', () => {
      expect(generateMessageResponse).to.exist;
    });
  });

  describe('Other Functions', () => {
    it('should export generateInsight', () => {
      expect(generateInsight).to.exist;
    });

    it('should export onThreadDeleted', () => {
      expect(onThreadDeleted).to.exist;
    });
  });
});
