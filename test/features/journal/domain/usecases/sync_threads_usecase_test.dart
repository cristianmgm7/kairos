import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/domain/repositories/journal_thread_repository.dart';
import 'package:kairos/features/journal/domain/usecases/sync_threads_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'delete_thread_usecase_test.mocks.dart';


@GenerateMocks([JournalThreadRepository])
void main() {
  late SyncThreadsUseCase useCase;
  late MockJournalThreadRepository mockRepository;

  setUpAll(() {
    // Provide dummy value for Result<void>
    provideDummy<Result<void>>(const Success(null));
  });

  setUp(() {
    mockRepository = MockJournalThreadRepository();
    useCase = SyncThreadsUseCase(threadRepository: mockRepository);
  });

  group('SyncThreadsUseCase', () {
    const testUserId = 'user123';

    test('should return Success when repository sync succeeds', () async {
      // Arrange
      when(mockRepository.syncThreadsIncremental(testUserId))
          .thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result.isSuccess, true);
      verify(mockRepository.syncThreadsIncremental(testUserId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure when repository returns network error', () async {
      // Arrange
      when(mockRepository.syncThreadsIncremental(testUserId)).thenAnswer(
        (_) async => const Error(
          NetworkFailure(message: 'No internet connection'),
        ),
      );

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result.isError, true);
      expect(result.failureOrNull, isA<NetworkFailure>());
      verify(mockRepository.syncThreadsIncremental(testUserId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository returns server error', () async {
      // Arrange
      when(mockRepository.syncThreadsIncremental(testUserId)).thenAnswer(
        (_) async => const Error(
          ServerFailure(message: 'Server error'),
        ),
      );

      // Act
      final result = await useCase.execute(testUserId);

      // Assert
      expect(result.isError, true);
      expect(result.failureOrNull, isA<ServerFailure>());
      verify(mockRepository.syncThreadsIncremental(testUserId));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
