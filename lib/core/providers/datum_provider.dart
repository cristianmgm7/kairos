import 'package:blueprint_app/features/profile/data/adapters/user_profile_local_adapter.dart';
import 'package:blueprint_app/features/profile/data/adapters/user_profile_remote_adapter.dart';
import 'package:blueprint_app/features/profile/data/models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datum/datum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Provider for Datum instance
final datumProvider = Provider<Datum>((ref) {
  throw UnimplementedError('Datum provider must be overridden');
});

/// Initialize Datum with configuration
Future<Datum> initializeDatum({
  required String? initialUserId,
  required Isar isar,
  required FirebaseFirestore firestore,
}) async {
  final config = DatumConfig(
    enableLogging: true,
    autoStartSync: true,
    initialUserId: initialUserId,
    syncExecutionStrategy: ParallelStrategy(batchSize: 5),
    defaultSyncDirection: SyncDirection.pullThenPush,
    schemaVersion: 1,
  );

  return await Datum.initialize(
    config: config,
    connectivityChecker: DefaultConnectivityChecker(),
    registrations: [
      DatumRegistration<UserProfileModel>(
        localAdapter: UserProfileLocalAdapter(isar),
        remoteAdapter: UserProfileRemoteAdapter(firestore),
        conflictResolver: LastWriteWinsResolver<UserProfileModel>(),
      ),
    ],
  );
}
