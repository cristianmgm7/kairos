import { genkit } from 'genkit';
import { googleAI } from '@genkit-ai/google-genai';
import { defineFirestoreRetriever } from '@genkit-ai/firebase';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { geminiApiKey } from '../config/genkit';

// Initialize Firestore
const firestore = getFirestore();

/**
 * Embedder: text-embedding-004 (768 dimensions)
 *
 * This is Google's latest embedding model optimized for semantic search.
 * Dimensions: 768
 * Cost: $0.00001 per 1K characters (very cheap)
 */
export const kairosEmbedder = googleAI.embedder('text-embedding-004');

/**
 * Get or create Firestore Retriever: Semantic search for long-term memories
 *
 * Configuration:
 * - Collection: kairos_memories
 * - Content field: content (the extracted fact/theme)
 * - Vector field: embedding (768-dimensional vector)
 * - Distance: COSINE (best for text similarity)
 * - Embedder: text-embedding-004
 */
export function getKairosLtmRetriever() {
  const ai = genkit({
    plugins: [googleAI({ apiKey: geminiApiKey.value() })],
  });

  return defineFirestoreRetriever(ai, {
    name: 'kairosLtmRetriever',
    firestore,
    collection: 'kairos_memories',
    contentField: 'content',
    vectorField: 'embedding',
    embedder: kairosEmbedder,
    distanceMeasure: 'COSINE',
  });
}

/**
 * Helper: Generate embedding for text
 *
 * Use this when manually indexing documents (for ingestMemoryFlow).
 */
export async function generateEmbedding(text: string): Promise<number[]> {
  const ai = genkit({
    plugins: [googleAI({ apiKey: geminiApiKey.value() })],
  });

  const result = await ai.embed({
    embedder: kairosEmbedder,
    content: text,
  });

  return result[0].embedding;
}

/**
 * Helper: Index a memory document to Firestore
 *
 * This function:
 * 1. Generates embedding for the content
 * 2. Stores document with embedding vector in Firestore
 * 3. Returns the document ID
 */
export async function indexMemory(
  userId: string,
  content: string,
  metadata: {
    source: 'auto_extracted' | 'user_confirmed';
    threadId?: string;
    messageId?: string;
    extractedAt: number;
    tags?: string[];
    categories?: string[];
  }
): Promise<string> {
  // Generate embedding
  const embedding = await generateEmbedding(content);

  // Store in Firestore with vector field
  const docRef = await firestore.collection('kairos_memories').add({
    userId,
    content,
    embedding: FieldValue.vector(embedding), // CRITICAL: Use FieldValue.vector()
    metadata: {
      ...metadata,
      categories: metadata.categories || [], // Ensure categories field exists
    },
    createdAt: FieldValue.serverTimestamp(),
  });

  return docRef.id;
}

/**
 * Helper: Retrieve relevant memories for a user query
 *
 * This wraps the retriever for easier testing and reuse.
 */
export async function retrieveMemories(
  query: string,
  userId: string,
  limit: number = 5
): Promise<Array<{ content: string; metadata: any }>> {
  const ai = genkit({
    plugins: [googleAI({ apiKey: geminiApiKey.value() })],
  });

  const retriever = getKairosLtmRetriever();

  const docs = await ai.retrieve({
    retriever,
    query,
    options: {
      limit,
      where: { userId }, // CRITICAL: Filter by user
    },
  });

  return docs.map(doc => {
    // Extract text content from Part array
    const textContent = doc.content
      .filter((part): part is { text: string } => 'text' in part)
      .map(part => part.text)
      .join('\n');

    return {
      content: textContent,
      metadata: doc.metadata,
    };
  });
}
