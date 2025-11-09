import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/firestore_exception_mapper.dart';
import 'package:kairos/features/journal/data/models/journal_thread_model.dart';

abstract class JournalThreadRemoteDataSource {
  Future<void> saveThread(JournalThreadModel thread);
  Future<JournalThreadModel?> getThreadById(String threadId);
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId);
  Future<void> updateThread(JournalThreadModel thread);

  /// Soft-deletes a thread in Firestore by setting isDeleted=true and deletedAtMillis.
  Future<void> softDeleteThread(String threadId);
}

class JournalThreadRemoteDataSourceImpl
    implements JournalThreadRemoteDataSource {
  JournalThreadRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalThreads');

  @override
  Future<void> saveThread(JournalThreadModel thread) async {
    try {
      await _collection.doc(thread.id).set(thread.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to save thread');
    }
  }

  @override
  Future<JournalThreadModel?> getThreadById(String threadId) async {
    try {
      final doc = await _collection.doc(threadId).get();
      if (!doc.exists) return null;
      return JournalThreadModel.fromMap(doc.data()!);
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get thread by ID');
    }
  }

  @override
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId) async {
    try {
      final querySnapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('lastMessageAtMillis', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JournalThreadModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get threads by user');
    }
  }

  @override
  Future<void> updateThread(JournalThreadModel thread) async {
    try {
      await _collection.doc(thread.id).update(thread.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to update thread');
    }
  }

  @override
  Future<void> softDeleteThread(String threadId) async {
    try {
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await _collection.doc(threadId).update({
        'isDeleted': true,
        'deletedAtMillis': now,
        'updatedAtMillis': now,
      });
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to delete thread');
    }
  }
}
