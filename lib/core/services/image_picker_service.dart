import 'dart:io';

import 'package:blueprint_app/core/errors/failures.dart';
import 'package:blueprint_app/core/utils/result.dart';
import 'package:image_picker/image_picker.dart';

/// Service for handling image picking from gallery or camera
class ImagePickerService {
  ImagePickerService(this._picker);

  final ImagePicker _picker;

  /// Pick image from gallery
  Future<Result<File>> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048, // Limit size to prevent huge files
        maxHeight: 2048,
        imageQuality: 85, // Compress to reasonable quality
      );

      if (pickedFile == null) {
        return Error(
          const UserCancelledFailure(message: 'User cancelled image selection'),
        );
      }

      return Success(File(pickedFile.path));
    } catch (e) {
      return Error(
        PermissionFailure(
          message: 'Failed to pick image from gallery: ${e.toString()}',
        ),
      );
    }
  }

  /// Pick image from camera
  Future<Result<File>> pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048, // Limit size to prevent huge files
        maxHeight: 2048,
        imageQuality: 85, // Compress to reasonable quality
      );

      if (pickedFile == null) {
        return Error(
          const UserCancelledFailure(message: 'User cancelled image capture'),
        );
      }

      return Success(File(pickedFile.path));
    } catch (e) {
      return Error(
        PermissionFailure(
          message: 'Failed to capture image from camera: ${e.toString()}',
        ),
      );
    }
  }
}
