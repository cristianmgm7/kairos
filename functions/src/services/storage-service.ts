import * as admin from 'firebase-admin';
import { extractStoragePath } from '../utils/storage-utils';

export class StorageService {
  private bucket: ReturnType<ReturnType<typeof admin.storage>['bucket']>;

  constructor() {
    this.bucket = admin.storage().bucket();
  }

  /**
   * Download file from Firebase Storage and convert to base64 data URL
   * Works for both audio and image files
   */
  async getFileAsDataUrl(storageUrl: string, contentType: string): Promise<string> {
    try {
      const storagePath = extractStoragePath(storageUrl);
      console.log(`Attempting to download from path: ${storagePath}`);

      const file = this.bucket.file(storagePath);

      // Check if file exists
      const [exists] = await file.exists();
      if (!exists) {
        console.error(`File does not exist at path: ${storagePath}`);
        throw new Error(`File not found: ${storagePath}`);
      }

      // Get file metadata
      const [metadata] = await file.getMetadata();
      console.log(`File metadata - size: ${metadata.size}, contentType: ${metadata.contentType}`);

      // Download file as buffer
      const [buffer] = await file.download();

      console.log(`Downloaded file: ${storagePath}, size: ${buffer.length} bytes`);

      // Log first few bytes to debug
      if (buffer.length < 100) {
        console.warn(
          `File is suspiciously small (${buffer.length} bytes). Content: ${buffer
            .toString('utf8')
            .substring(0, 100)}`
        );
      }

      // Convert to base64 data URL
      const base64Data = buffer.toString('base64');
      const dataUrl = `data:${contentType};base64,${base64Data}`;

      return dataUrl;
    } catch (error) {
      console.error('Failed to download file:', error);
      throw error;
    }
  }

  /**
   * Download image from Firebase Storage
   */
  async getImageAsDataUrl(storageUrl: string): Promise<string> {
    return this.getFileAsDataUrl(storageUrl, 'image/jpeg');
  }

  /**
   * Download audio from Firebase Storage
   */
  async getAudioAsDataUrl(storageUrl: string): Promise<string> {
    return this.getFileAsDataUrl(storageUrl, 'audio/mp4');
  }
}

// Singleton instance
let storageServiceInstance: StorageService | null = null;

export function getStorageService(): StorageService {
  if (!storageServiceInstance) {
    storageServiceInstance = new StorageService();
  }
  return storageServiceInstance;
}

