import { z } from 'zod';
import { getAI } from '../config/genkit';
import { createKairosTools } from './kairos.tools';
import { KairosSession } from './kairos.session';
import { retrieveMemories } from './kairos.rag';
import { SYSTEM_PROMPT } from '../config/constants';

/**
 * Input schema for the agent flow
 */
const AgentInputSchema = z.object({
  userId: z.string().describe('Firebase Auth UID of the user'),
  threadId: z.string().describe('Conversation thread ID'),
  userInput: z.string().describe('User message content'),
  apiKey: z.string().describe('Gemini API key'),
  excludeMessageId: z.string().optional().describe('Message ID to exclude from history'),
});

/**
 * Output schema for the agent flow
 */
const AgentOutputSchema = z.object({
  text: z.string().describe('AI response text'),
  toolsUsed: z.array(z.string()).describe('Names of tools called'),
  memoriesRetrieved: z.number().describe('Number of memories retrieved'),
  usage: z.object({
    inputTokens: z.number().optional(),
    outputTokens: z.number().optional(),
  }).optional().describe('Token usage statistics'),
});

/**
 * Kairos Agent Flow
 *
 * Main conversational agent that:
 * 1. Loads session history from thread messages
 * 2. Retrieves relevant long-term memories via semantic search
 * 3. Augments system prompt with memory context
 * 4. Generates response using tools and context
 *
 * This flow is the ONLY entry point for agent execution.
 */
export const kairosAgentFlow = (apiKey: string) => {
  const ai = getAI(apiKey);

  return ai.defineFlow(
    {
      name: 'kairosAgent',
      inputSchema: AgentInputSchema,
      outputSchema: AgentOutputSchema,
    },
    async ({ userId, threadId, userInput, apiKey: inputApiKey, excludeMessageId }) => {
      console.log(`[Agent Flow] Starting for user ${userId}, thread ${threadId}`);

      // 1. Create session and load conversation history
      const session = new KairosSession({ userId, threadId });
      await session.loadHistory(excludeMessageId);
      console.log(`[Agent Flow] Loaded ${session.getHistory().length} messages from history`);

      // 2. Retrieve relevant memories using semantic search
      const memories = await retrieveMemories(userInput, userId, 5);
      console.log(`[Agent Flow] Retrieved ${memories.length} relevant memories`);

      // 3. Build augmented system prompt with memory context
      let augmentedPrompt = SYSTEM_PROMPT;
      if (memories.length > 0) {
        const memoryContext = memories
          .map((m, i) => `${i + 1}. ${m.content}`)
          .join('\n');
        augmentedPrompt += `\n\n## Long-Term Memory Context\n\nRelevant facts from past conversations:\n${memoryContext}\n\nUse these memories to inform your response when relevant, but don't explicitly mention them unless asked.`;
      }

      // 4. Convert session history to Genkit message format
      const historyMessages = session.getHistory().map(msg => {
        const role = msg.role === 'ai' ? 'model' : msg.role;
        return {
          role: role as 'user' | 'model' | 'system',
          content: [{ text: msg.content }],
        };
      });

      // 5. Prepare final messages array
      const messages = [
        { role: 'system' as const, content: [{ text: augmentedPrompt }] },
        ...historyMessages,
        { role: 'user' as const, content: [{ text: userInput }] },
      ];

      // 6. Create tools (they need userId and threadId in scope)
      const tools = createKairosTools(inputApiKey, userId, threadId);

      // 7. Generate response with tools
      console.log(`[Agent Flow] Generating response...`);
      const response = await ai.generate({
        messages,
        tools,
        config: {
          temperature: 0.7,
          maxOutputTokens: 500,
        },
      });

      // 8. Extract tool usage
      const toolsUsed = response.toolRequests?.map(tr => tr.toolRequest.name) || [];
      console.log(`[Agent Flow] Tools used: ${toolsUsed.join(', ') || 'none'}`);

      return {
        text: response.text || '',
        toolsUsed,
        memoriesRetrieved: memories.length,
        usage: response.usage ? {
          inputTokens: response.usage.inputTokens,
          outputTokens: response.usage.outputTokens,
        } : undefined,
      };
    }
  );
};

/**
 * Factory function for easier invocation
 */
export async function runKairosAgent(
  config: {
    userId: string;
    threadId: string;
    userInput: string;
    apiKey: string;
    excludeMessageId?: string;
  }
): Promise<z.infer<typeof AgentOutputSchema>> {
  const flow = kairosAgentFlow(config.apiKey);
  return await flow(config);
}

/**
 * Legacy function for backward compatibility
 * @deprecated Use runKairosAgent instead
 */
export interface AgentConfig {
  userId: string;
  threadId: string;
  apiKey: string;
  excludeMessageId?: string;
}

export interface AgentResponse {
  text: string;
  toolsUsed: string[];
  memoriesRetrieved: number;
  usage?: {
    inputTokens?: number;
    outputTokens?: number;
  };
}

export async function runKairos(config: AgentConfig, userInput: string): Promise<AgentResponse> {
  return runKairosAgent({ ...config, userInput });
}
