import 'package:isar/isar.dart';

part 'sync_metadata_model.g.dart';

/// Tracks sync metadata for each user
@collection
class SyncMetadataModel {
  Id? isarId;

  @Index(unique: true)
  final String userId;

  final int lastSyncTimeMillis;
  final String? dataHash;
  final int itemCount;
  final int version;

  SyncMetadataModel({
    this.isarId,
    required this.userId,
    required this.lastSyncTimeMillis,
    this.dataHash,
    required this.itemCount,
    required this.version,
  });

  DateTime get lastSyncTime =>
      DateTime.fromMillisecondsSinceEpoch(lastSyncTimeMillis);
}

