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

