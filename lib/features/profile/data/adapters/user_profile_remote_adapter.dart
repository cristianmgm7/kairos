import 'package:blueprint_app/features/profile/data/models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datum/datum.dart';

class UserProfileRemoteAdapter extends RemoteAdapter<UserProfileModel> {
  final FirebaseFirestore firestore;

  UserProfileRemoteAdapter(this.firestore);

  /// Firestore collection path: /users/{userId}/profile
  String _getCollectionPath(String userId) => 'users/$userId/profile';

  @override
  Future<List<UserProfileModel>> readAll({
    String? userId,
    DatumSyncScope? scope,
  }) async {
    if (userId == null) {
      throw ArgumentError('userId is required for readAll');
    }

    Query query = firestore
        .collection(_getCollectionPath(userId));

    // Use sync scope for incremental sync
    if (scope?.lastSyncTime != null) {
      query = query.where(
        'modifiedAtMillis',
        isGreaterThan: scope!.lastSyncTime!.millisecondsSinceEpoch,
      );
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => UserProfileModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserProfileModel?> read(String id) async {
    // Need to query across all user collections - this is inefficient
    // Better to use readAll with userId
    throw UnimplementedError(
      'Use readAll with userId instead of read by id',
    );
  }

  @override
  Future<UserProfileModel> create(UserProfileModel entity) async {
    final docRef = firestore
        .collection(_getCollectionPath(entity.userId))
        .doc(entity.id);

    await docRef.set(entity.toDatumMap());
    return entity;
  }

  @override
  Future<UserProfileModel> update(UserProfileModel entity) async {
    final docRef = firestore
        .collection(_getCollectionPath(entity.userId))
        .doc(entity.id);

    await docRef.update(entity.toDatumMap());
    return entity;
  }

  @override
  Future<UserProfileModel> patch(String id, Map<String, dynamic> updates) async {
    throw UnimplementedError('Patch not supported, use update instead');
  }

  @override
  Future<void> delete(String id) async {
    throw UnimplementedError('Delete by ID not supported without userId');
  }

  /// Delete with userId context
  Future<void> deleteWithUserId(String id, String userId) async {
    final docRef = firestore
        .collection(_getCollectionPath(userId))
        .doc(id);

    // Soft delete
    await docRef.update({
      'isDeleted': true,
      'modifiedAtMillis': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<DatumSyncMetadata> getSyncMetadata(String userId) async {
    final metadataDoc = await firestore
        .collection('sync_metadata')
        .doc(userId)
        .get();

    if (!metadataDoc.exists) {
      return DatumSyncMetadata(
        lastSyncTime: DateTime.fromMillisecondsSinceEpoch(0),
        itemCount: 0,
        version: 0,
      );
    }

    final data = metadataDoc.data()!;
    return DatumSyncMetadata(
      lastSyncTime: DateTime.fromMillisecondsSinceEpoch(
        data['lastSyncTimeMillis'] as int,
      ),
      dataHash: data['dataHash'] as String?,
      itemCount: data['itemCount'] as int? ?? 0,
      version: data['version'] as int? ?? 0,
    );
  }

  @override
  Stream<DatumChangeDetail<UserProfileModel>>? get changeStream {
    // Firestore doesn't support listening to all users
    // Return null, use watchByUserId instead
    return null;
  }

  /// Watch changes for specific user
  Stream<DatumChangeDetail<UserProfileModel>> watchByUserId(String userId) {
    return firestore
        .collection(_getCollectionPath(userId))
        .snapshots()
        .map((snapshot) {
      return DatumChangeDetail<UserProfileModel>(
        entityType: UserProfileModel,
        timestamp: DateTime.now(),
        changes: snapshot.docChanges.map((change) {
          return UserProfileModel.fromMap(
            change.doc.data() as Map<String, dynamic>,
          );
        }).toList(),
      );
    });
  }
}

