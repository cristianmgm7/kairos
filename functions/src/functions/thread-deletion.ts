import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';

/**
 * Cloud Function triggered when a thread document is updated.
 * Detects when isDeleted changes from false to true and permanently hard-deletes
 * all messages and media files associated with the thread.
 */
export const onThreadDeleted = onDocumentUpdated(
  {
    document: 'journalThreads/{threadId}',
    memory: '512MiB',
    timeoutSeconds: 120,
    region: 'us-central1',
  },
  async (event) => {
    const threadId = event.params.threadId;
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    // Only proceed if isDeleted changed from false to true
    if (beforeData?.isDeleted === false && afterData?.isDeleted === true) {
      logger.info(`Thread ${threadId} was soft-deleted. Starting permanent cascade deletion of messages and media.`);

      const db = getFirestore();
      const bucket = getStorage().bucket();

      try {
        // Step 1: Query all messages for this thread (no isDeleted filter needed for hard delete)
        const messagesSnapshot = await db
          .collection('journalMessages')
          .where('threadId', '==', threadId)
          .get();

        logger.info(`Permanently deleting ${messagesSnapshot.size} messages and associated media for thread ${threadId}`);

        // Step 2: Batch delete messages (Firestore batches limited to 500 operations)
        const batchSize = 500;
        const batches: FirebaseFirestore.WriteBatch[] = [];
        let currentBatch = db.batch();
        let operationCount = 0;

        const storageFilesToDelete: string[] = [];

        for (const messageDoc of messagesSnapshot.docs) {
          const messageData = messageDoc.data();

          // Hard delete message (permanently remove from Firestore)
          currentBatch.delete(messageDoc.ref);

          // Collect storage URLs for deletion
          if (messageData.storageUrl) {
            storageFilesToDelete.push(messageData.storageUrl as string);
          }
          if (messageData.thumbnailUrl) {
            storageFilesToDelete.push(messageData.thumbnailUrl as string);
          }

          operationCount++;

          // Create new batch if limit reached
          if (operationCount >= batchSize) {
            batches.push(currentBatch);
            currentBatch = db.batch();
            operationCount = 0;
          }
        }

        // Add final batch if it has operations
        if (operationCount > 0) {
          batches.push(currentBatch);
        }

        // Step 3: Commit all batches
        logger.info(`Committing ${batches.length} batch(es) to permanently delete messages`);
        await Promise.all(batches.map((batch) => batch.commit()));
        logger.info(`✅ Successfully permanently deleted ${messagesSnapshot.size} messages`);

        // Step 4: Delete storage files
        logger.info(`Deleting ${storageFilesToDelete.length} storage file(s)`);
        const deletePromises = storageFilesToDelete.map(async (url) => {
          try {
            // Extract file path from URL
            const filePath = extractFilePathFromUrl(url);
            if (filePath) {
              await bucket.file(filePath).delete();
              logger.info(`Deleted storage file: ${filePath}`);
            }
          } catch (error) {
            logger.error(`Failed to delete storage file ${url}:`, error);
            // Don't fail the entire operation if one file fails
          }
        });

        await Promise.all(deletePromises);
        logger.info(`✅ Storage cleanup completed for thread ${threadId}`);

      } catch (error) {
        logger.error(`Failed to cascade-delete thread ${threadId}:`, error);
        throw error; // Re-throw to trigger Cloud Function retry
      }
    }
  }
);

/**
 * Extracts the file path from a Firebase Storage URL.
 * Handles both https:// and gs:// URL formats.
 */
function extractFilePathFromUrl(url: string): string | null {
  try {
    if (url.startsWith('gs://')) {
      // Format: gs://bucket-name/path/to/file
      const match = url.match(/^gs:\/\/[^/]+\/(.+)$/);
      return match ? match[1] : null;
    } else if (url.includes('storage.googleapis.com')) {
      // Format: https://storage.googleapis.com/bucket-name/path/to/file
      const match = url.match(/storage\.googleapis\.com\/[^/]+\/(.+)$/);
      return match ? match[1] : null;
    } else if (url.includes('firebasestorage.googleapis.com')) {
      // Format: https://firebasestorage.googleapis.com/v0/b/bucket-name/o/encoded-path
      const match = url.match(/\/o\/(.+?)(\?|$)/);
      if (match) {
        return decodeURIComponent(match[1]);
      }
    }
    return null;
  } catch (error) {
    logger.error(`Failed to parse storage URL ${url}:`, error);
    return null;
  }
}
