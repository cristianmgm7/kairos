import { z } from 'zod';
import { googleAI } from '@genkit-ai/google-genai';
import { getAI, geminiApiKey } from '../config/genkit';
import { indexMemory } from './kairos.rag';

/**
 * Input schema for memory ingestion
 */
const IngestInputSchema = z.object({
  userId: z.string().describe('Firebase Auth UID'),
  threadId: z.string().describe('Thread ID where conversation occurred'),
  userMessage: z.string().describe('User message content'),
  aiResponse: z.string().describe('AI response content'),
  messageId: z.string().describe('Message ID for tracking'),
});

/**
 * Output schema for memory ingestion
 */
const IngestOutputSchema = z.object({
  success: z.boolean().describe('Whether extraction succeeded'),
  factsExtracted: z.number().describe('Number of facts extracted'),
  memoryIds: z.array(z.string()).describe('Firestore document IDs of created memories'),
  error: z.string().optional().describe('Error message if failed'),
});

/**
 * Fact extraction prompt
 *
 * This prompt instructs the LLM to extract durable, high-value facts.
 */
const EXTRACTION_PROMPT = `You are a memory extraction system. Analyze the following conversation turn and extract 3-5 durable, high-value facts that would be useful for future conversations.

Focus on:
- Important facts about the user (name, preferences, goals, challenges)
- Emotional patterns or significant feelings
- Key events or milestones mentioned
- Relationships or important people
- Commitments or future plans
- Skills, interests, or expertise areas

Rules:
- Each fact should be a complete, standalone sentence
- Be specific and concrete (avoid vague statements)
- Focus on what's memorable and likely to be relevant later
- Exclude trivial or transient information
- Exclude meta-conversation (e.g., "user asked a question")

Return ONLY the facts, one per line, numbered 1-5. If fewer than 3 significant facts, return what you have.

## Conversation Turn

User: {userMessage}

AI: {aiResponse}

## Extracted Facts (1-5):`;

/**
 * Memory Ingestion Flow
 *
 * Automatically extracts facts from conversations and indexes them.
 * Runs asynchronously after agent response (doesn't block user).
 *
 * Process:
 * 1. LLM analyzes conversation turn
 * 2. Extracts 3-5 durable facts
 * 3. Generates embeddings for each fact
 * 4. Stores in Firestore with vector field
 *
 * NOTE: AI instance is initialized at runtime to avoid accessing
 * secrets during deployment.
 */
export async function ingestMemoryFlow(input: z.infer<typeof IngestInputSchema>): Promise<z.infer<typeof IngestOutputSchema>> {
  const { userId, threadId, userMessage, aiResponse, messageId } = input;
  
  console.log(`[Memory Ingest] Starting extraction for message ${messageId}`);

  try {
    // Initialize AI at runtime (secrets only available at runtime)
    const ai = getAI(geminiApiKey.value());

    // 1. Extract facts using LLM (low-cost model)
    const prompt = EXTRACTION_PROMPT
      .replace('{userMessage}', userMessage)
      .replace('{aiResponse}', aiResponse);

    const extractionResponse = await ai.generate({
      model: googleAI.model('gemini-2.0-flash'), // Fast, cheap model
      prompt,
      config: {
        temperature: 0.3, // Lower temperature for consistent extraction
        maxOutputTokens: 300,
      },
    });

    const extractedText = extractionResponse.text || '';
    console.log(`[Memory Ingest] Raw extraction: ${extractedText}`);

    // 2. Parse extracted facts (one per line, numbered)
    const facts = extractedText
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .map(line => {
        // Remove numbering (e.g., "1. " or "- ")
        return line.replace(/^\d+\.\s*/, '').replace(/^-\s*/, '');
      })
      .filter(fact => fact.length > 10); // Minimum fact length

    console.log(`[Memory Ingest] Extracted ${facts.length} facts`);

    if (facts.length === 0) {
      console.log(`[Memory Ingest] No significant facts extracted, skipping indexing`);
      return {
        success: true,
        factsExtracted: 0,
        memoryIds: [],
      };
    }

    // 3. Index each fact as a separate memory
    const memoryIds: string[] = [];
    for (const fact of facts) {
      try {
        const memoryId = await indexMemory(userId, fact, {
          source: 'auto_extracted',
          threadId,
          messageId,
          extractedAt: Date.now(),
        });
        memoryIds.push(memoryId);
        console.log(`[Memory Ingest] Indexed fact: "${fact.substring(0, 50)}..."`);
      } catch (error) {
        console.error(`[Memory Ingest] Failed to index fact: ${error}`);
        // Continue with other facts
      }
    }

    console.log(`[Memory Ingest] Successfully indexed ${memoryIds.length}/${facts.length} facts`);

    return {
      success: true,
      factsExtracted: facts.length,
      memoryIds,
    };
  } catch (error) {
    console.error(`[Memory Ingest] Extraction failed:`, error);
    return {
      success: false,
      factsExtracted: 0,
      memoryIds: [],
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

/**
 * Helper: Run memory ingestion (for easier invocation)
 */
export async function runMemoryIngestion(config: {
  userId: string;
  threadId: string;
  userMessage: string;
  aiResponse: string;
  messageId: string;
}): Promise<z.infer<typeof IngestOutputSchema>> {
  return await ingestMemoryFlow(config);
}
