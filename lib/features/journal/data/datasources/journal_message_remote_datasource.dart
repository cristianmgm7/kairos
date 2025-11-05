import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';

abstract class JournalMessageRemoteDataSource {
  Future<void> saveMessage(JournalMessageModel message);
  Future<JournalMessageModel?> getMessageById(String messageId);
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId);
  Future<void> updateMessage(JournalMessageModel message);
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId, String userId);
}

class JournalMessageRemoteDataSourceImpl
    implements JournalMessageRemoteDataSource {
  JournalMessageRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalMessages');

  @override
  Future<void> saveMessage(JournalMessageModel message) async {
    await _collection.doc(message.id).set(message.toFirestoreMap());
  }

  @override
  Future<JournalMessageModel?> getMessageById(String messageId) async {
    final doc = await _collection.doc(messageId).get();
    if (!doc.exists) return null;
    return JournalMessageModel.fromMap(doc.data()!);
  }

  @override
  Future<List<JournalMessageModel>> getMessagesByThreadId(
      String threadId) async {
    final querySnapshot = await _collection
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAtMillis', descending: false)
        .get();

    return querySnapshot.docs
        .map((doc) => JournalMessageModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> updateMessage(JournalMessageModel message) async {
    await _collection.doc(message.id).update(message.toFirestoreMap());
  }

  @override
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(String threadId, String userId) {
    return _collection
        .where('threadId', isEqualTo: threadId)
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAtMillis', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalMessageModel.fromMap(doc.data()))
            .toList());
  }
}
