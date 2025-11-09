import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/exceptions.dart';

/// Maps Firestore exceptions to domain exceptions
///
/// Throws either [NetworkException] or [ServerException] based on the error type.
/// This follows the same pattern as FirebaseAuthRepository's exception mapping.
Never mapFirestoreException(Object error, {String? context}) {
  final contextPrefix = context != null ? '$context: ' : '';

  if (error is SocketException) {
    throw NetworkException(
      message: '${contextPrefix}No internet connection. Please check your network.',
    );
  }

  if (error is FirebaseException) {
    // Map specific Firestore error codes
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
        throw NetworkException(
          message: '${contextPrefix}Network timeout. Please try again.',
        );

      case 'permission-denied':
        throw ServerException(
          message: '${contextPrefix}Permission denied: ${error.message}',
          statusCode: 403,
        );

      case 'not-found':
        throw ServerException(
          message: '${contextPrefix}Resource not found: ${error.message}',
          statusCode: 404,
        );

      case 'already-exists':
        throw ServerException(
          message: '${contextPrefix}Resource already exists: ${error.message}',
          statusCode: 409,
        );

      case 'resource-exhausted':
        throw ServerException(
          message: '${contextPrefix}Quota exceeded: ${error.message}',
          statusCode: 429,
        );

      case 'failed-precondition':
      case 'aborted':
      case 'out-of-range':
      case 'unimplemented':
      case 'internal':
      case 'data-loss':
        throw ServerException(
          message: '${contextPrefix}Server error: ${error.message}',
          statusCode: 500,
        );

      default:
        throw ServerException(
          message: '${contextPrefix}Firestore error: ${error.message ?? 'Unknown error'}',
        );
    }
  }

  // Generic fallback for unknown errors
  throw ServerException(
    message: '${contextPrefix}Unexpected error: $error',
  );
}
