import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairos/features/journal/data/models/journal_entry_model.dart';

abstract class JournalEntryRemoteDataSource {
  Future<void> saveEntry(JournalEntryModel entry);
  Future<JournalEntryModel?> getEntryById(String entryId);
  Future<List<JournalEntryModel>> getEntriesByUserId(String userId);
  Future<void> updateEntry(JournalEntryModel entry);
  Future<void> deleteEntry(String entryId);
}

class JournalEntryRemoteDataSourceImpl implements JournalEntryRemoteDataSource {
  JournalEntryRemoteDataSourceImpl(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('journalEntries');

  @override
  Future<void> saveEntry(JournalEntryModel entry) async {
    await _collection.doc(entry.id).set(entry.toFirestoreMap());
  }

  @override
  Future<JournalEntryModel?> getEntryById(String entryId) async {
    final doc = await _collection.doc(entryId).get();
    if (!doc.exists) return null;
    return JournalEntryModel.fromMap(doc.data()!);
  }

  @override
  Future<List<JournalEntryModel>> getEntriesByUserId(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAtMillis', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => JournalEntryModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> updateEntry(JournalEntryModel entry) async {
    await _collection.doc(entry.id).update(entry.toFirestoreMap());
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    await _collection.doc(entryId).update({
      'isDeleted': true,
      'modifiedAtMillis': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
