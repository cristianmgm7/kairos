import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';

/// Result returned from successful upload
class UploadResult {
  const UploadResult({
    required this.remoteUrl,
    required this.metadata,
  });

  final String remoteUrl;
  final Map<String, String> metadata;
}

/// Thin utility for uploading files to Firebase Storage
/// Does NOT handle business logic, orchestration, or state transitions
class MediaUploader {
  MediaUploader(this._storage);

  final FirebaseStorage _storage;

  /// Upload file to specified storage path with progress tracking
  ///
  /// Low-level operation that only handles:
  /// - Reading file bytes
  /// - Uploading to Firebase Storage
  /// - Progress callbacks
  /// - Basic network retry (via Firebase SDK)
  ///
  /// Does NOT:
  /// - Update message status
  /// - Call repositories
  /// - Trigger AI processing
  /// - Implement business retry logic
  Future<Result<UploadResult>> uploadFile({
    required File file,
    required String storagePath,
    required String contentType,
    Map<String, String>? metadata,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file exists
      if (!file.existsSync()) {
        return const Error(ValidationFailure(message: 'File does not exist'));
      }

      // Read file bytes
      final fileBytes = await file.readAsBytes();

      // Create storage reference
      final storageRef = _storage.ref().child(storagePath);

      // Create upload task
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toUtc().toIso8601String(),
            ...?metadata,
          },
        ),
      );

      // Listen to progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final totalBytes = snapshot.totalBytes;
          if (totalBytes > 0) {
            final progress = snapshot.bytesTransferred / totalBytes;
            if (progress.isFinite && progress >= 0 && progress <= 1) {
              onProgress(progress);
            }
          }
        });
      }

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return Success(
        UploadResult(
          remoteUrl: downloadUrl,
          metadata: metadata ?? {},
        ),
      );
    } on FirebaseException catch (e) {
      return Error(
        StorageFailure(
          message: 'Upload failed: ${e.message}',
          code: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Error(StorageFailure(message: 'Upload failed: $e'));
    }
  }

  /// Cancel an in-progress upload (if needed for future cancellation support)
  /// Not implemented yet - placeholder for future enhancement
  void cancel(UploadTask task) {
    task.cancel();
  }
}
