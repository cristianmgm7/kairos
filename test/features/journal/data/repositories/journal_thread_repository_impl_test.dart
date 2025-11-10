import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/errors/exceptions.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_thread_remote_datasource.dart';
import 'package:kairos/features/journal/data/repositories/journal_thread_repository_impl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  JournalThreadLocalDataSource,
  JournalThreadRemoteDataSource,
])
import 'journal_thread_repository_impl_test.mocks.dart';

void main() {
  late JournalThreadRepositoryImpl repository;
  late MockJournalThreadLocalDataSource mockLocalDataSource;
  late MockJournalThreadRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    // Provide dummy value for Result<void>
    provideDummy<Result<void>>(const Success(null));
  });

  setUp(() {
    mockLocalDataSource = MockJournalThreadLocalDataSource();
    mockRemoteDataSource = MockJournalThreadRemoteDataSource();
    repository = JournalThreadRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('deleteThread', () {
    const testThreadId = 'test-thread-123';

    test('should return NetworkFailure when remote throws NetworkException', () async {
      // Arrange
      when(mockRemoteDataSource.softDeleteThread(testThreadId))
          .thenThrow(NetworkException(message: 'Network error'));

      // Act
      final result = await repository.deleteThread(testThreadId);

      // Assert
      expect(result.isError, true);
      expect(result.failureOrNull, isA<NetworkFailure>());
      final failure = result.failureOrNull!;
      expect(failure.message, 'You must be online to delete this thread');
      verifyNever(mockLocalDataSource.hardDeleteThreadAndMessages(any));
    });

    test('should soft-delete remotely then hard-delete locally on success', () async {
      // Arrange
      when(mockRemoteDataSource.softDeleteThread(testThreadId))
          .thenAnswer((_) async => Future.value());
      when(mockLocalDataSource.hardDeleteThreadAndMessages(testThreadId))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.deleteThread(testThreadId);

      // Assert
      expect(result.isSuccess, true);
      verify(mockRemoteDataSource.softDeleteThread(testThreadId));
      verify(mockLocalDataSource.hardDeleteThreadAndMessages(testThreadId));
    });

    test('should return ServerFailure when remote throws ServerException', () async {
      // Arrange
      when(mockRemoteDataSource.softDeleteThread(testThreadId))
          .thenThrow(ServerException(message: 'Server error'));

      // Act
      final result = await repository.deleteThread(testThreadId);

      // Assert
      expect(result.isError, true);
      expect(result.failureOrNull, isA<ServerFailure>());
      verifyNever(mockLocalDataSource.hardDeleteThreadAndMessages(any));
    });

    test('should succeed even if local deletion fails after remote success', () async {
      // Arrange
      when(mockRemoteDataSource.softDeleteThread(testThreadId))
          .thenAnswer((_) async => Future.value());
      when(mockLocalDataSource.hardDeleteThreadAndMessages(testThreadId))
          .thenThrow(Exception('Isar error'));

      // Act
      final result = await repository.deleteThread(testThreadId);

      // Assert
      expect(result.isSuccess, true); // Should still succeed
      verify(mockRemoteDataSource.softDeleteThread(testThreadId));
      verify(mockLocalDataSource.hardDeleteThreadAndMessages(testThreadId));
    });
  });
}
