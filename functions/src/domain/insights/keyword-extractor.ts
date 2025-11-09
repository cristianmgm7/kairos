interface MessageData {
  content: string;
  role: number;
  createdAtMillis: number;
}

/**
 * Extract keywords from messages using simple frequency analysis
 */
export function extractKeywords(messages: MessageData[]): string[] {
  const stopWords = new Set([
    'the',
    'a',
    'an',
    'and',
    'or',
    'but',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'from',
    'as',
    'is',
    'was',
    'are',
    'were',
    'been',
    'be',
    'have',
    'has',
    'had',
    'do',
    'does',
    'did',
    'will',
    'would',
    'could',
    'should',
    'may',
    'might',
    'can',
    'i',
    'you',
    'he',
    'she',
    'it',
    'we',
    'they',
    'my',
    'your',
    'his',
    'her',
    'its',
    'our',
    'their',
    'this',
    'that',
    'these',
    'those',
    'am',
    'me',
    'im',
    'ive',
    'dont',
    'cant',
    'wont',
    'didnt',
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

