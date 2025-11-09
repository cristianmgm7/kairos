import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/services/audio_recorder_service.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:record/record.dart';

@GenerateMocks([AudioRecorder])
import 'audio_recorder_service_test.mocks.dart';

void main() {
  late AudioRecorderService service;
  late MockAudioRecorder mockRecorder;

  setUp(() {
    mockRecorder = MockAudioRecorder();
    service = AudioRecorderService(mockRecorder);
  });

  group('AudioRecorderService', () {
    test('startRecording returns PermissionFailure when denied', () async {
      when(mockRecorder.hasPermission()).thenAnswer((_) async => false);

      final result = await service.startRecording();

      expect(result is Error, true);
      expect(result.failureOrNull, isA<PermissionFailure>());
      verify(mockRecorder.hasPermission()).called(1);
    });

    test('cancelRecording calls cancel on recorder', () async {
      when(mockRecorder.cancel()).thenAnswer((_) async {});

      final result = await service.cancelRecording();

      expect(result is Success, true);
      verify(mockRecorder.cancel()).called(1);
    });

    test('stopRecording calls stop on recorder', () async {
      when(mockRecorder.stop()).thenAnswer((_) async => null);

      final result = await service.stopRecording();

      // Will return error because path is null
      expect(result is Error, true);
      verify(mockRecorder.stop()).called(1);
    });

    test('isRecording returns false by default', () async {
      when(mockRecorder.isRecording()).thenAnswer((_) async => false);

      final result = await service.isRecording();

      expect(result, false);
      verify(mockRecorder.isRecording()).called(1);
    });
  });
}
