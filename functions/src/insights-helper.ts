interface MessageData {
  content: string;
  role: number; // 0=user, 1=ai
  createdAtMillis: number;
}

interface InsightAnalysis {
  moodScore: number;
  dominantEmotion: number;
  keywords: string[];
  aiThemes: string[];
  summary: string;
}

/**
 * Extract keywords from messages using simple frequency analysis
 */
export function extractKeywords(messages: MessageData[]): string[] {
  const stopWords = new Set([
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
    'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'can', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
    'my', 'your', 'his', 'her', 'its', 'our', 'their', 'this', 'that', 'these',
    'those', 'am', 'me', 'im', 'ive', 'dont', 'cant', 'wont', 'didnt',
  ]);

  const wordFreq = new Map<string, number>();

  messages.forEach(msg => {
    if (!msg.content) return;

    const words = msg.content
      .toLowerCase()
      .replace(/[^\w\s]/g, '')
      .split(/\s+/)
      .filter(word => word.length > 3 && !stopWords.has(word));

    words.forEach(word => {
      wordFreq.set(word, (wordFreq.get(word) || 0) + 1);
    });
  });

  // Sort by frequency and return top 10
  return Array.from(wordFreq.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([word]) => word);
}

/**
 * Analyze messages using Gemini to extract mood, emotion, themes, and summary
 */
export async function analyzeMessagesWithAI(
  ai: any,
  messages: MessageData[]
): Promise<InsightAnalysis> {
  const conversationText = messages
    .map(msg => {
      const role = msg.role === 0 ? 'User' : 'Assistant';
      return `${role}: ${msg.content || '[media message]'}`;
    })
    .join('\n');

  const prompt = `You are an empathetic journaling companion analyzing a user's emotional journey in the Kairos app. Your role is to provide supportive, encouraging insights that help users understand their progress.

IMPORTANT GUIDELINES:
- Be warm, supportive, and encouraging (never diagnostic or clinical)
- Focus on growth, progress, and positive patterns
- Acknowledge challenges with compassion
- Use "you" language to make it personal and supportive
- Return a direct numerical mood score (0.0 to 1.0)

Conversation to analyze:
${conversationText}

Provide your analysis in the following JSON format (respond with ONLY valid JSON, no markdown or code blocks):
{
  "moodScore": <number between 0.0 and 1.0, where 0.0 is very low/difficult and 1.0 is very high/positive>,
  "dominantEmotion": <number: 0=joy, 1=calm, 2=neutral, 3=sadness, 4=stress, 5=anger, 6=fear, 7=excitement>,
  "aiThemes": [<array of 3-5 supportive themes like "Building resilience" or "Practicing self-compassion">],
  "summary": "<2-3 sentence supportive summary emphasizing growth, progress, and emotional awareness. Use warm, encouraging language.>"
}

Example of good summary tone:
"You've been showing great self-awareness in your reflections this week. Even when facing challenges, you're taking time to process your feelings thoughtfully. This kind of mindful engagement with your emotions is a powerful step in your journey."

Example of bad summary tone (too clinical):
"Patient exhibits moderate anxiety symptoms with occasional depressive episodes. Cognitive patterns suggest need for intervention."`;

  const response = await ai.generate({
    prompt: [{ text: prompt }],
    config: {
      temperature: 0.3, // Lower temperature for more consistent analysis
      maxOutputTokens: 500,
    },
  });

  try {
    // Extract JSON from response (handle potential markdown wrapping)
    let jsonText = response.text.trim();

    // Remove markdown code blocks if present
    if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```json?\n?/g, '').replace(/```\n?$/g, '');
    }

    const analysis = JSON.parse(jsonText);

    return {
      moodScore: Math.max(0, Math.min(1, analysis.moodScore)),
      dominantEmotion: analysis.dominantEmotion,
      keywords: [], // Will be filled by extractKeywords
      aiThemes: analysis.aiThemes.slice(0, 5),
      summary: analysis.summary,
    };
  } catch (error) {
    console.error('Failed to parse AI analysis:', error);
    console.error('Raw response:', response.text);

    // Fallback to neutral values
    return {
      moodScore: 0.5,
      dominantEmotion: 2, // neutral
      keywords: [],
      aiThemes: ['Unable to analyze conversation'],
      summary: 'Analysis unavailable at this time.',
    };
  }
}

/**
 * Aggregate multiple per-thread insights into a global insight
 */
export function aggregateInsights(threadInsights: any[]): any {
  if (threadInsights.length === 0) {
    return null;
  }

  // Average mood score
  const avgMoodScore =
    threadInsights.reduce((sum, ins) => sum + ins.moodScore, 0) /
    threadInsights.length;

  // Count emotions and find dominant
  const emotionCounts = new Map<number, number>();
  threadInsights.forEach(ins => {
    const emotion = ins.dominantEmotion;
    emotionCounts.set(emotion, (emotionCounts.get(emotion) || 0) + 1);
  });
  const dominantEmotion = Array.from(emotionCounts.entries()).sort(
    (a, b) => b[1] - a[1]
  )[0][0];

  // Merge keywords (deduplicate and take top 10)
  const allKeywords = new Set<string>();
  threadInsights.forEach(ins => {
    ins.keywords.forEach((kw: string) => allKeywords.add(kw));
  });
  const keywords = Array.from(allKeywords).slice(0, 10);

  // Merge AI themes (deduplicate and take top 5)
  const allThemes = new Set<string>();
  threadInsights.forEach(ins => {
    ins.aiThemes.forEach((theme: string) => allThemes.add(theme));
  });
  const aiThemes = Array.from(allThemes).slice(0, 5);

  // Create aggregated summary
  const summary = `Across ${threadInsights.length} conversation${
    threadInsights.length > 1 ? 's' : ''
  }, your overall mood has been ${
    avgMoodScore > 0.6 ? 'positive' : avgMoodScore < 0.4 ? 'challenging' : 'neutral'
  }. Key themes include: ${aiThemes.join(', ')}.`;

  // Sum message counts
  const messageCount = threadInsights.reduce(
    (sum, ins) => sum + ins.messageCount,
    0
  );

  return {
    moodScore: avgMoodScore,
    dominantEmotion,
    keywords,
    aiThemes,
    summary,
    messageCount,
  };
}
