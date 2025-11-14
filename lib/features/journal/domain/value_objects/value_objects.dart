enum MessageRole {
  user(value: 0), // Human-created content
  ai(value: 1), // AI-generated responses
  system(value: 2); // App-generated metadata

  const MessageRole({required this.value});

  final int value;

  static MessageRole fromInt(int code) {
    return MessageRole.values.firstWhere(
      (e) => e.value == code,
      orElse: () => MessageRole.user,
    );
  }
}

enum MessageType {
  text(value: 0),
  image(value: 1),
  audio(value: 2);

  const MessageType({required this.value});

  final int value;

  static MessageType fromInt(int code) {
    return MessageType.values.firstWhere(
      (e) => e.value == code,
      orElse: () => MessageType.text,
    );
  }
}

/// Single authoritative status modeling the entire message pipeline
enum MessageStatus {
  /// Message created locally but not yet processed
  localCreated(value: 0),

  /// Media file is being uploaded (audio/image only)
  uploadingMedia(value: 1),

  /// Media file uploaded successfully
  mediaUploaded(value: 2),

  /// AI processing in progress (transcription or response generation)
  processingAi(value: 3),

  /// AI processing completed (transcription/analysis done)
  processed(value: 4),

  /// Message synced to remote Firestore
  remoteCreated(value: 5),

  /// Terminal failure state
  failed(value: 6);

  const MessageStatus({required this.value});

  final int value;

  static MessageStatus fromInt(int code) {
    return MessageStatus.values.firstWhere(
      (e) => e.value == code,
      orElse: () => MessageStatus.localCreated,
    );
  }
}

/// Detailed substatus for failed state to enable targeted retry
enum FailureReason {
  uploadFailed(value: 0),
  transcriptionFailed(value: 1),
  aiResponseFailed(value: 2),
  remoteCreationFailed(value: 3),
  networkError(value: 4),
  unknown(value: 5);

  const FailureReason({required this.value});

  final int value;

  static FailureReason fromInt(int code) {
    return FailureReason.values.firstWhere(
      (e) => e.value == code,
      orElse: () => FailureReason.unknown,
    );
  }
}
