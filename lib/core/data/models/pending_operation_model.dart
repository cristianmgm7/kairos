import 'package:isar/isar.dart';

part 'pending_operation_model.g.dart';

/// Tracks pending operations for offline sync
@collection
class PendingOperationModel {
  Id? isarId;

  @Index(unique: true)
  final String id;

  @Index()
  final String userId;

  final String entityType;
  final String operationType;
  final String entityId;

  /// Stored as JSON string
  final String dataJson;

  final int timestampMillis;
  final bool isProcessed;
  final String? error;

  PendingOperationModel({
    this.isarId,
    required this.id,
    required this.userId,
    required this.entityType,
    required this.operationType,
    required this.entityId,
    required this.dataJson,
    required this.timestampMillis,
    this.isProcessed = false,
    this.error,
  });

  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampMillis);
}

