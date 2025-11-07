/**
 * Extract storage path from Firebase Storage URL
 * Handles multiple URL formats from Firebase Storage
 */
export function extractStoragePath(url: string): string {
  console.log(`Extracting storage path from URL: ${url}`);

  // Extract path from URLs like:
  // https://firebasestorage.googleapis.com/v0/b/bucket/o/path%2Fto%2Ffile.m4a?alt=media&token=...
  // https://storage.googleapis.com/bucket/path/to/file.m4a?X-Goog-...
  // https://firebasestorage.app/v0/b/bucket/o/path%2Fto%2Ffile.m4a?alt=media&token=...

  let match = url.match(/\/o\/(.+?)\?/);
  if (match) {
    const path = decodeURIComponent(match[1]);
    console.log(`Extracted path (format 1): ${path}`);
    return path;
  }

  // Try direct Google Storage URL format
  match = url.match(/storage\.googleapis\.com\/([^/]+)\/(.+?)(?:\?|$)/);
  if (match) {
    const path = decodeURIComponent(match[2]);
    console.log(`Extracted path (format 2): ${path}`);
    return path;
  }

  // Try firebasestorage.app format
  match = url.match(/firebasestorage\.app\/v0\/b\/[^/]+\/o\/(.+?)(?:\?|$)/);
  if (match) {
    const path = decodeURIComponent(match[1]);
    console.log(`Extracted path (format 3): ${path}`);
    return path;
  }

  console.error(`Failed to extract path from URL: ${url}`);
  throw new Error(`Invalid Firebase Storage URL format: ${url}`);
}

