import 'dart:io';

import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Result containing audio file and duration metadata
class AudioRecordingResult {
  const AudioRecordingResult({
    required this.file,
    required this.durationSeconds,
  });

  final File file;
  final int durationSeconds;
}

/// Service for recording audio using the record package
class AudioRecorderService {
  AudioRecorderService(this._recorder);

  final AudioRecorder _recorder;
  DateTime? _recordingStartTime;

  /// Start recording audio
  /// Returns Success or Error with PermissionFailure if permission denied
  Future<Result<void>> startRecording() async {
    try {
      // Check microphone permission
      if (!await _recorder.hasPermission()) {
        return const Error(
          PermissionFailure(message: 'Microphone permission denied'),
        );
      }

      // Generate unique file path
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/recording_$timestamp.m4a';

      // Start recording with M4A/AAC codec
      await _recorder.start(const RecordConfig(), path: path);

      _recordingStartTime = DateTime.now();

      return const Success(null);
    } catch (e) {
      return Error(
        UnknownFailure(message: 'Failed to start recording: $e'),
      );
    }
  }

  /// Stop recording and return file with duration
  /// Returns Success with AudioRecordingResult or Error
  Future<Result<AudioRecordingResult>> stopRecording() async {
    try {
      final path = await _recorder.stop();

      if (path == null) {
        return const Error(
          UnknownFailure(message: 'Recording path is null'),
        );
      }

      final file = File(path);
      if (!file.existsSync()) {
        return const Error(
          UnknownFailure(message: 'Recording file does not exist'),
        );
      }

      // CRITICAL FIX: Poll file size until it's stable
      // The record package may return before file is fully written
      // Wait for file size to stop changing (indicates write is complete)
      var previousSize = 0;
      var stableCount = 0;
      const maxAttempts = 20; // Max 2 seconds

      for (var i = 0; i < maxAttempts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final currentSize = await file.length();

        if (currentSize == previousSize && currentSize > 1000) {
          // Size hasn't changed and is large enough
          stableCount++;
          if (stableCount >= 3) {
            // Stable for 300ms, consider it done
            break;
          }
        } else {
          stableCount = 0;
        }

        previousSize = currentSize;
      }

      // Final size check
      final fileSize = await file.length();
      if (fileSize < 1000) {
        return Error(
          UnknownFailure(
              message:
                  'Recording file is too small ($fileSize bytes). Please try recording again with a longer message.',),
        );
      }

      // Calculate duration
      var durationSeconds = 0;
      if (_recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        durationSeconds = duration.inSeconds;
      }

      _recordingStartTime = null;

      return Success(
        AudioRecordingResult(
          file: file,
          durationSeconds: durationSeconds,
        ),
      );
    } catch (e) {
      _recordingStartTime = null;
      return Error(
        UnknownFailure(message: 'Failed to stop recording: $e'),
      );
    }
  }

  /// Cancel recording without returning file
  Future<Result<void>> cancelRecording() async {
    try {
      await _recorder.cancel();
      _recordingStartTime = null;
      return const Success(null);
    } catch (e) {
      _recordingStartTime = null;
      return Error(
        UnknownFailure(message: 'Failed to cancel recording: $e'),
      );
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      return false;
    }
  }

  /// Get current recording duration in seconds
  int get currentDurationSeconds {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inSeconds;
  }

  /// Dispose the recorder
  void dispose() {
    _recorder.dispose();
  }
}
