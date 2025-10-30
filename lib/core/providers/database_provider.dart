import 'package:blueprint_app/core/data/models/pending_operation_model.dart';
import 'package:blueprint_app/core/data/models/sync_metadata_model.dart';
import 'package:blueprint_app/features/profile/data/models/user_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Provider that throws by default, will be overridden in main
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar provider must be overridden');
});

/// Initialize Isar database before app starts
Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  return await Isar.open(
    [
      UserProfileModelSchema,
      PendingOperationModelSchema,
      SyncMetadataModelSchema,
    ],
    directory: dir.path,
    name: 'kairos_db',
    inspector: true, // Enable Isar Inspector in debug mode
  );
}
