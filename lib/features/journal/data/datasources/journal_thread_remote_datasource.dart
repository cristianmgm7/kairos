import 'package:cloud_firestore/cloud_firestore.dart';
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
    await _collection.doc(thread.id).set(thread.toFirestoreMap());
  }

  @override
  Future<JournalThreadModel?> getThreadById(String threadId) async {
    final doc = await _collection.doc(threadId).get();
    if (!doc.exists) return null;
    return JournalThreadModel.fromMap(doc.data()!);
  }

  @override
  Future<List<JournalThreadModel>> getThreadsByUserId(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .where('isArchived', isEqualTo: false)
        .orderBy('lastMessageAtMillis', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => JournalThreadModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> updateThread(JournalThreadModel thread) async {
    await _collection.doc(thread.id).update(thread.toFirestoreMap());
  }

  @override
  Future<void> softDeleteThread(String threadId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _collection.doc(threadId).update({
      'isDeleted': true,
      'deletedAtMillis': now,
      'updatedAtMillis': now,
    });
  }
}
