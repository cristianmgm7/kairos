import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';

enum FileType { image, audio, document }

class FirebaseStorageService {
  FirebaseStorageService(this._storage);
  final FirebaseStorage _storage;

  /// Build dynamic storage path: users/{userId}/journals/{journalId}/{filename}
  String buildJournalPath({
    required String userId,
    required String journalId,
    required String filename,
  }) {
    return 'users/$userId/journals/$journalId/$filename';
  }

  /// Upload file with optional processing and progress tracking
  Future<Result<String>> uploadFile({
    required File file,
    required String storagePath,
    required FileType fileType,
    Map<String, String>? metadata,
    int? imageMaxSize,
    int? imageQuality,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (!file.existsSync()) {
        return const Error(ValidationFailure(message: 'File does not exist'));
      }

      Uint8List fileBytes;
      String contentType;

      // Process based on file type
      switch (fileType) {
        case FileType.image:
          final result = await _processImage(
            file,
            maxSize: imageMaxSize ?? 1024,
            quality: imageQuality ?? 85,
          );
          if (result.isError) return Error(result.failureOrNull!);
          fileBytes = result.dataOrNull!;
          contentType = 'image/jpeg';

        case FileType.audio:
          fileBytes = await file.readAsBytes();
          contentType = 'audio/m4a'; // M4A/AAC for optimal compression

        case FileType.document:
          fileBytes = await file.readAsBytes();
          contentType = 'application/octet-stream';
      }

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedAt': DateTime.now().toUtc().toIso8601String(),
            'fileType': fileType.name,
            ...?metadata,
          },
        ),
      );

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          // Prevent division by zero and handle invalid progress values
          final totalBytes = snapshot.totalBytes;
          if (totalBytes > 0) {
            final progress = snapshot.bytesTransferred / totalBytes;
            // Ensure progress is a valid number between 0 and 1
            if (progress.isFinite && progress >= 0 && progress <= 1) {
              onProgress(progress);
            }
          }
        });
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return Success(downloadUrl);
    } catch (e) {
      return Error(StorageFailure(message: 'Failed to upload file: $e'));
    }
  }

  /// Process image: resize and compress
  Future<Result<Uint8List>> _processImage(
    File imageFile, {
    required int maxSize,
    required int quality,
  }) async {
    try {
      final imageBytes = imageFile.readAsBytesSync();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        return const Error(ValidationFailure(message: 'Invalid image format'));
      }

      final resizedImage = img.copyResize(
        originalImage,
        width: maxSize,
        height: maxSize,
        maintainAspect: true,
        backgroundColor: img.ColorRgb8(255, 255, 255),
      );

      final processedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: quality),
      );

      return Success(processedBytes);
    } catch (e) {
      return Error(StorageFailure(message: 'Failed to process image: $e'));
    }
  }

  /// Generate thumbnail from image file
  Future<Result<Uint8List>> generateThumbnail(
    File imageFile, {
    int size = 150,
  }) async {
    return _processImage(imageFile, maxSize: size, quality: 70);
  }

  /// Delete file from storage
  Future<Result<void>> deleteFile(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;
      final pathStartIndex = pathSegments.indexOf('o');

      if (pathStartIndex == -1 || pathStartIndex + 1 >= pathSegments.length) {
        return const Error(ValidationFailure(message: 'Invalid URL format'));
      }

      final encodedPath = pathSegments.sublist(pathStartIndex + 1).join('/');
      final storagePath = Uri.decodeFull(encodedPath);

      final storageRef = _storage.ref().child(storagePath);
      await storageRef.delete();

      return const Success(null);
    } catch (e) {
      return Error(StorageFailure(message: 'Failed to delete file: $e'));
    }
  }
}
