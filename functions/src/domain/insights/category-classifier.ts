import { googleAI } from '@genkit-ai/google-genai';
import { getAI, geminiApiKey } from '../../config/genkit';
import { InsightCategory, CATEGORY_INSIGHTS_CONFIG } from '../../config/constants';

/**
 * Classification prompt
 * 
 * Instructs LLM to classify a memory fact into 0-2 categories.
 */
const CLASSIFICATION_PROMPT = `You are a memory categorization system. Classify the following memory fact into 0-2 of these categories:

Categories:
1. mindset_wellbeing - Thought patterns, emotional regulation, stress, resilience, happiness
2. productivity_focus - Time management, procrastination, concentration, task completion
3. relationships_connection - Interpersonal dynamics, communication, empathy, social connections
4. career_growth - Professional development, learning skills, ambition, work challenges
5. health_lifestyle - Physical well-being, habits (sleep, exercise, nutrition), self-care
6. purpose_values - Life meaning, personal values, long-term vision, existential reflections

Rules:
- Return 0-2 categories maximum (most relevant)
- If the fact doesn't clearly fit any category, return empty
- Return ONLY category names, comma-separated, no explanation
- Examples:
  * "I'm learning React for my new job" → career_growth
  * "I felt anxious today but managed to calm down" → mindset_wellbeing
  * "I'm questioning whether this career path is right for me" → career_growth, purpose_values
  * "I slept 8 hours last night" → health_lifestyle
  * "I had a great conversation with my friend" → relationships_connection

Memory Fact: {fact}

Categories (0-2, comma-separated):`;

/**
 * Classify a memory fact into categories
 * 
 * @param fact - The memory fact to classify
 * @returns Array of category strings (0-2 items)
 */
export async function classifyMemoryFact(fact: string): Promise<string[]> {
  console.log(`[Category Classifier] Classifying: "${fact.substring(0, 60)}..."`);

  try {
    const ai = getAI(geminiApiKey.value());

    const prompt = CLASSIFICATION_PROMPT.replace('{fact}', fact);

    const response = await ai.generate({
      model: googleAI.model('gemini-2.0-flash'), // Fast, cheap
      prompt,
      config: {
        temperature: CATEGORY_INSIGHTS_CONFIG.classificationTemperature,
        maxOutputTokens: CATEGORY_INSIGHTS_CONFIG.maxClassificationTokens,
      },
    });

    const rawText = (response.text || '').trim();
    console.log(`[Category Classifier] Raw response: "${rawText}"`);

    // Parse comma-separated categories
    const categories = rawText
      .split(',')
      .map(cat => cat.trim())
      .filter(cat => Object.values(InsightCategory).includes(cat as InsightCategory))
      .slice(0, 2); // Max 2 categories

    console.log(`[Category Classifier] Extracted categories: [${categories.join(', ')}]`);

    return categories;
  } catch (error) {
    console.error(`[Category Classifier] Classification failed:`, error);
    return []; // Return empty on error (fact will be saved without categories)
  }
}

/**
 * Batch classify multiple facts
 * 
 * @param facts - Array of memory facts
 * @returns Array of category arrays (parallel to input)
 */
export async function classifyMemoryFacts(facts: string[]): Promise<string[][]> {
  console.log(`[Category Classifier] Batch classifying ${facts.length} facts`);

  // Classify sequentially to avoid rate limits
  // TODO: Could optimize with Promise.all if needed
  const results: string[][] = [];
  for (const fact of facts) {
    const categories = await classifyMemoryFact(fact);
    results.push(categories);
  }

  return results;
}

