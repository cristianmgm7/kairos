import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kairos/features/profile/data/models/user_profile_model.dart';

/// Remote data source using Firestore
abstract class UserProfileRemoteDataSource {
  /// Save profile to Firestore
  Future<void> saveProfile(UserProfileModel profile);

  /// Get profile by user ID from Firestore
  Future<UserProfileModel?> getProfileByUserId(String userId);

  /// Get profile by profile ID from Firestore
  Future<UserProfileModel?> getProfileById(String profileId);

  /// Update profile in Firestore
  Future<void> updateProfile(UserProfileModel profile);

  /// Delete profile from Firestore (soft delete)
  Future<void> deleteProfile(String profileId);

  /// Get profiles modified after a timestamp (for incremental sync)
  Future<List<UserProfileModel>> getProfilesModifiedAfter(
    String userId,
    DateTime timestamp,
  );
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  UserProfileRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection => firestore.collection('userProfiles');

  @override
  Future<void> saveProfile(UserProfileModel profile) async {
    await _collection.doc(profile.id).set(profile.toDatumMap());
  }

  @override
  Future<UserProfileModel?> getProfileByUserId(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return UserProfileModel.fromMap(querySnapshot.docs.first.data());
  }

  @override
  Future<UserProfileModel?> getProfileById(String profileId) async {
    final doc = await _collection.doc(profileId).get();
    if (!doc.exists) return null;

    return UserProfileModel.fromMap(doc.data()!);
  }

  @override
  Future<void> updateProfile(UserProfileModel profile) async {
    await _collection.doc(profile.id).update(profile.toDatumMap());
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    await _collection.doc(profileId).update({
      'isDeleted': true,
      'modifiedAtMillis': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<UserProfileModel>> getProfilesModifiedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where(
          'modifiedAtMillis',
          isGreaterThan: timestamp.millisecondsSinceEpoch,
        )
        .get();

    return querySnapshot.docs.map((doc) => UserProfileModel.fromMap(doc.data())).toList();
  }
}
