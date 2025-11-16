import admin from 'firebase-admin';
import { MemoryService } from '../agents/kairos.memory';

/**
 * Populate memory from existing insights
 *
 * This script:
 * 1. Reads all insights from Firestore
 * 2. Creates memory documents for each insight summary
 * 3. Tags with source metadata
 *
 * Run once to backfill, then ongoing via trigger (optional)
 */
async function populateMemoryFromInsights() {
  // Initialize Firebase Admin
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const memoryService = new MemoryService(db);

  console.log('Starting memory population from insights...');

  // Get all insights (not deleted)
  const insightsSnapshot = await db.collection('insights')
    .where('isDeleted', '==', false)
    .get();

  console.log(`Found ${insightsSnapshot.size} insights to process`);

  let processedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  for (const insightDoc of insightsSnapshot.docs) {
    const insight = insightDoc.data();
    const insightId = insightDoc.id;

    // Skip if no summary
    if (!insight.summary || insight.summary.trim() === '') {
      console.log(`Skipping insight ${insightId} - no summary`);
      skippedCount++;
      continue;
    }

    try {
      // Check if memory already exists for this insight
      const existingMemory = await db.collection('kairos_memories')
        .where('metadata.insightId', '==', insightId)
        .limit(1)
        .get();

      if (!existingMemory.empty) {
        console.log(`Memory already exists for insight ${insightId}, skipping`);
        skippedCount++;
        continue;
      }

      // Create memory from insight
      await memoryService.storeInsightMemory(
        insight.userId,
        insightId,
        insight.summary,
        insight.threadId || undefined,
        insight.keywords || []
      );

      processedCount++;

      if (processedCount % 10 === 0) {
        console.log(`Processed ${processedCount} insights...`);
      }
    } catch (error) {
      console.error(`Error processing insight ${insightId}:`, error);
      errorCount++;
    }
  }

  console.log('\n=== Memory Population Complete ===');
  console.log(`Total insights: ${insightsSnapshot.size}`);
  console.log(`Processed: ${processedCount}`);
  console.log(`Skipped: ${skippedCount}`);
  console.log(`Errors: ${errorCount}`);
}

// Run script
populateMemoryFromInsights()
  .then(() => {
    console.log('Script completed successfully');
    process.exit(0);
  })
  .catch(error => {
    console.error('Script failed:', error);
    process.exit(1);
  });
