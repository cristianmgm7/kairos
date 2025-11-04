import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/services/firebase_storage_service.dart';
import 'package:kairos/features/journal/domain/repositories/journal_message_repository.dart';
import 'package:kairos/features/journal/domain/services/journal_upload_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseStorageService, JournalMessageRepository])
import 'journal_upload_service_test.mocks.dart';

void main() {
  late JournalUploadService service;
  late MockFirebaseStorageService mockStorageService;
  late MockJournalMessageRepository mockRepository;

  setUp(() {
    mockStorageService = MockFirebaseStorageService();
    mockRepository = MockJournalMessageRepository();
    service = JournalUploadService(
      storageService: mockStorageService,
      messageRepository: mockRepository,
    );
  });

  group('JournalUploadService', () {
    test('service can be instantiated', () {
      expect(service, isNotNull);
      expect(service.storageService, equals(mockStorageService));
      expect(service.messageRepository, equals(mockRepository));
    });

    test('buildJournalPath is accessible through storage service', () {
      when(
        mockStorageService.buildJournalPath(
          userId: anyNamed('userId'),
          journalId: anyNamed('journalId'),
          filename: anyNamed('filename'),
        ),
      ).thenReturn('users/user123/journals/journal456/test.jpg');

      final path = mockStorageService.buildJournalPath(
        userId: 'user123',
        journalId: 'journal456',
        filename: 'test.jpg',
      );

      expect(path, equals('users/user123/journals/journal456/test.jpg'));
    });
  });
}
