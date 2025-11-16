import { getAI } from '../config/genkit';
import { createKairosTools } from './kairos.tools';
import { KairosSession } from './kairos.session';
import { MemoryService } from './kairos.memory';
import { SYSTEM_PROMPT } from '../config/constants';

/**
 * Agent configuration
 */
export interface AgentConfig {
  userId: string;
  threadId: string;
  apiKey: string;
  excludeMessageId?: string;
}

/**
 * Agent response
 */
export interface AgentResponse {
  text: string;
  toolsUsed: string[];
  memoriesRetrieved: number;
  usage?: {
    inputTokens?: number;
    outputTokens?: number;
  };
}

/**
 * Run Kairos agent for a conversation
 *
 * The agent uses:
 * - Session history (from thread messages)
 * - Tools (for current information)
 * - Memory (for long-term context)
 */
export async function runKairos(config: AgentConfig, userInput: string): Promise<AgentResponse> {
  const { userId, threadId, apiKey, excludeMessageId } = config;

  // 1. Create session
  const session = new KairosSession({ userId, threadId });

  // 2. Load conversation history
  await session.loadHistory(excludeMessageId);

  // 3. Get AI instance and create tools
  const ai = getAI(apiKey);
  const tools = createKairosTools(apiKey);

  // 4. Retrieve relevant memories
  const memoryService = new MemoryService();
  const memories = await memoryService.getRecentMemories(userId, 5, threadId);

  // 5. Build context with memories
  let systemPromptWithMemory = SYSTEM_PROMPT;
  if (memories.length > 0) {
    const memoryContext = memories
      .map(m => m.content)
      .join('\n');
    systemPromptWithMemory += `\n\nRelevant context from past conversations:\n${memoryContext}`;
  }

  // 6. Convert session history to Genkit message format
  const historyMessages = session.getHistory().map(msg => {
    let role: 'user' | 'model' | 'system' | 'tool';
    if (msg.role === 'ai') {
      role = 'model';
    } else if (msg.role === 'user') {
      role = 'user';
    } else {
      role = 'system';
    }

    return {
      role,
      content: [{ text: msg.content }],
    };
  });

  // Add system message and user input
  const allMessages: Array<{
    role: 'user' | 'model' | 'system' | 'tool';
    content: Array<{ text: string }>;
  }> = [
    { role: 'system' as const, content: [{ text: systemPromptWithMemory }] },
    ...historyMessages,
    { role: 'user' as const, content: [{ text: userInput }] },
  ];

  // 7. Run generation with tools
  const response = await ai.generate({
    messages: allMessages,
    tools,
    config: {
      temperature: 0.7,
      maxOutputTokens: 500,
    },
  });

  // 8. Extract tool usage
  const toolsUsed: string[] = [];
  if (response.toolRequests && response.toolRequests.length > 0) {
    toolsUsed.push(...response.toolRequests.map(tr => tr.toolRequest.name));
  }

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

/**
 * Factory function for agent execution
 */
export function createAgentRunner(apiKey: string) {
  return (config: Omit<AgentConfig, 'apiKey'>, userInput: string) =>
    runKairos({ ...config, apiKey }, userInput);
}
