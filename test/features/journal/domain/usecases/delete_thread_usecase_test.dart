import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/usecases/delete_thread_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([JournalThreadRepository])
import 'delete_thread_usecase_test.mocks.dart';

void main() {
  late DeleteThreadUseCase useCase;
  late MockJournalThreadRepository mockRepository;

  setUpAll(() {
    // Provide dummy value for Result<void>
    provideDummy<Result<void>>(const Success(null));
  });

  setUp(() {
    mockRepository = MockJournalThreadRepository();
    useCase = DeleteThreadUseCase(threadRepository: mockRepository);
  });

  group('DeleteThreadUseCase', () {
    const testThreadId = 'test-thread-123';

    test('should delete thread successfully when online', () async {
      // Arrange
      when(mockRepository.deleteThread(testThreadId))
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase(testThreadId);

      // Assert
      expect(result.isSuccess, true);
      verify(mockRepository.deleteThread(testThreadId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      when(mockRepository.deleteThread(testThreadId)).thenAnswer(
        (_) async => const Error(
          NetworkFailure(message: 'You must be online to delete this thread'),
        ),
      );

      // Act
      final result = await useCase(testThreadId);

      // Assert
      expect(result.isError, true);
      expect(result.failureOrNull, isA<NetworkFailure>());
      final failure = result.failureOrNull as NetworkFailure;
      expect(failure.message, 'You must be online to delete this thread');
      verify(mockRepository.deleteThread(testThreadId));
    });

    test('should return ServerFailure when remote deletion fails', () async {
      // Arrange
      when(mockRepository.deleteThread(testThreadId)).thenAnswer(
        (_) async => const Error(
          ServerFailure(message: 'Failed to delete thread'),
        ),
      );

      // Act
      final result = await useCase(testThreadId);

      // Assert
      expect(result.isError, true);
      expect(result.failureOrNull, isA<ServerFailure>());
      final failure = result.failureOrNull as ServerFailure;
      expect(failure.message, 'Failed to delete thread');
      verify(mockRepository.deleteThread(testThreadId));
    });
  });
}

