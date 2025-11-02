import 'dart:io';
import 'dart:typed_data';

import 'package:blueprint_app/core/errors/failures.dart';
import 'package:blueprint_app/core/utils/result.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

/// Service for handling Firebase Storage operations
class FirebaseStorageService {
  FirebaseStorageService(this._storage);

  final FirebaseStorage _storage;

  /// Upload profile avatar for a user
  /// Resizes image to 512x512, uploads to Firebase Storage, and returns download URL
  Future<Result<String>> uploadProfileAvatar({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // 1. Validate inputs
      if (!await imageFile.exists()) {
        return const Error(
          ValidationFailure(message: 'Image file does not exist'),
        );
      }

      // 2. Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        return const Error(
          ValidationFailure(message: 'Invalid image format'),
        );
      }

      // 3. Resize image to 512x512 (maintaining aspect ratio, fitting within bounds)
      final resizedImage = img.copyResize(
        originalImage,
        width: 512,
        height: 512,
        maintainAspect: true,
        backgroundColor: img.ColorRgb8(255, 255, 255), // White background
      );

      // 4. Encode as JPEG with quality 85%
      final resizedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 85),
      );

      // 5. Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_$timestamp.jpg';
      final storagePath = 'profile_avatars/$userId/$fileName';

      // 6. Upload to Firebase Storage
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = storageRef.putData(
        resizedBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          },
        ),
      );

      // 7. Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return Success(downloadUrl);
    } catch (e) {
      return Error(
        StorageFailure(
          message: 'Failed to upload avatar: ${e.toString()}',
        ),
      );
    }
  }

  /// Delete profile avatar for a user
  Future<Result<void>> deleteProfileAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      // Extract the storage path from the download URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;

      // Firebase Storage URLs typically have the path after '/o/'
      final pathStartIndex = pathSegments.indexOf('o');
      if (pathStartIndex == -1 || pathStartIndex + 1 >= pathSegments.length) {
        return const Error(
          ValidationFailure(message: 'Invalid avatar URL format'),
        );
      }

      // Decode URL-encoded path
      final encodedPath = pathSegments.sublist(pathStartIndex + 1).join('/');
      final storagePath = Uri.decodeFull(encodedPath);

      // Delete from Firebase Storage
      final storageRef = _storage.ref().child(storagePath);
      await storageRef.delete();

      return const Success(null);
    } catch (e) {
      return Error(
        StorageFailure(
          message: 'Failed to delete avatar: ${e.toString()}',
        ),
      );
    }
  }
}



