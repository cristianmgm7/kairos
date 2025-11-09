import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/core/errors/firestore_exception_mapper.dart';
import 'package:kairos/features/journal/data/models/journal_message_model.dart';

abstract class JournalMessageRemoteDataSource {
  Future<void> saveMessage(JournalMessageModel message);
  Future<JournalMessageModel?> getMessageById(String messageId);
  Future<List<JournalMessageModel>> getMessagesByThreadId(String threadId);
  Future<List<JournalMessageModel>> getUpdatedMessages(
    String threadId,
    int lastUpdatedAtMillis,
  );
  Future<void> updateMessage(JournalMessageModel message);
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(
    String threadId,
    String userId,
  );
  Stream<List<JournalMessageModel>> watchUpdatedMessages(
    String threadId,
    int sinceUpdatedAtMillis,
  );
}

class JournalMessageRemoteDataSourceImpl
    implements JournalMessageRemoteDataSource {
  JournalMessageRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalMessages');

  @override
  Future<void> saveMessage(JournalMessageModel message) async {
    try {
      await _collection.doc(message.id).set(message.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to save message');
    }
  }

  @override
  Future<JournalMessageModel?> getMessageById(String messageId) async {
    try {
      final doc = await _collection.doc(messageId).get();
      if (!doc.exists) return null;
      // Include document ID in the data map
      final data = doc.data()!;
      data['id'] = doc.id;
      return JournalMessageModel.fromMap(data);
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get message by ID');
    }
  }

  @override
  Future<List<JournalMessageModel>> getMessagesByThreadId(
    String threadId,
  ) async {
    try {
      final querySnapshot = await _collection
          .where('threadId', isEqualTo: threadId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAtMillis', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        // Include document ID in the data map
        final data = doc.data();
        data['id'] = doc.id;
        return JournalMessageModel.fromMap(data);
      }).toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get messages by thread');
    }
  }

  @override
  Future<List<JournalMessageModel>> getUpdatedMessages(
    String threadId,
    int lastUpdatedAtMillis,
  ) async {
    try {
      final querySnapshot = await _collection
          .where('threadId', isEqualTo: threadId)
          .where('isDeleted', isEqualTo: false)
          .where('updatedAtMillis', isGreaterThan: lastUpdatedAtMillis)
          .orderBy('updatedAtMillis', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return JournalMessageModel.fromMap(data);
      }).toList();
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to get updated messages');
    }
  }

  @override
  Future<void> updateMessage(JournalMessageModel message) async {
    try {
      await _collection.doc(message.id).update(message.toFirestoreMap());
    } catch (e) {
      mapFirestoreException(e, context: 'Failed to update message');
    }
  }

  @override
  Stream<List<JournalMessageModel>> watchMessagesByThreadId(
    String threadId,
    String userId,
  ) {
    return _collection
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAtMillis', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            // Include document ID in the data map
            final data = doc.data();
            data['id'] = doc.id;
            return JournalMessageModel.fromMap(data);
          }).toList(),
        );
  }

  @override
  Stream<List<JournalMessageModel>> watchUpdatedMessages(
    String threadId,
    int sinceUpdatedAtMillis,
  ) {
    return _collection
        .where('threadId', isEqualTo: threadId)
        .where('isDeleted', isEqualTo: false)
        .where('updatedAtMillis', isGreaterThan: sinceUpdatedAtMillis)
        .orderBy('updatedAtMillis', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return JournalMessageModel.fromMap(data);
          }).toList(),
        );
  }
}
