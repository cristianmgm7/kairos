import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/firestore_exception_mapper.dart';
import 'package:kairos/features/insights/data/models/insight_model.dart';

abstract class InsightRemoteDataSource {
  Future<void> saveInsight(InsightModel insight);
  Future<InsightModel?> getInsightById(String insightId);
  Future<List<InsightModel>> getGlobalInsights(String userId);
  Future<List<InsightModel>> getThreadInsights(String userId, String threadId);
  Stream<List<InsightModel>> watchGlobalInsights(String userId);
  Stream<List<InsightModel>> watchThreadInsights(
    String userId,
    String threadId,
  );
  Future<void> updateInsight(InsightModel insight);
  Future<void> deleteInsight(String insightId);
}

class InsightRemoteDataSourceImpl implements InsightRemoteDataSource {
  InsightRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('insights');

  @override
  Future<void> saveInsight(InsightModel insight) async {
    try {
      await _collection.doc(insight.id).set(insight.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to save insight');
    }
  }

  @override
  Future<InsightModel?> getInsightById(String insightId) async {
    try {
      final doc = await _collection.doc(insightId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return InsightModel.fromMap(data);
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get insight by ID');
    }
  }

  @override
  Future<List<InsightModel>> getGlobalInsights(String userId) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('threadId', isEqualTo: null)
          .where('isDeleted', isEqualTo: false)
          .orderBy('periodEndMillis', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return InsightModel.fromMap(data);
      }).toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get global insights');
    }
  }

  @override
  Future<List<InsightModel>> getThreadInsights(
    String userId,
    String threadId,
  ) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('threadId', isEqualTo: threadId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('periodEndMillis', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return InsightModel.fromMap(data);
      }).toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get thread insights');
    }
  }

  @override
  Stream<List<InsightModel>> watchGlobalInsights(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('threadId', isEqualTo: null)
        .where('isDeleted', isEqualTo: false)
        .orderBy('periodEndMillis', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return InsightModel.fromMap(data);
          }).toList(),
        );
  }

  @override
  Stream<List<InsightModel>> watchThreadInsights(
    String userId,
    String threadId,
  ) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('periodEndMillis', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return InsightModel.fromMap(data);
          }).toList(),
        );
  }

  @override
  Future<void> updateInsight(InsightModel insight) async {
    try {
      await _collection.doc(insight.id).update(insight.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to update insight');
    }
  }

  @override
  Future<void> deleteInsight(String insightId) async {
    try {
      await _collection.doc(insightId).update({'isDeleted': true});
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to delete insight');
    }
  }
}
