import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/sync_remote.dart';

class FirestoreSyncRemote implements SyncRemote {
  FirestoreSyncRemote(this._firestore);

  final FirebaseFirestore _firestore;

  static String collectionFor(SyncEntityType entityType) =>
      switch (entityType) {
        SyncEntityType.drink => 'drinks',
        SyncEntityType.exam => 'exams',
        SyncEntityType.goal => 'goals',
      };

  DocumentReference<Map<String, dynamic>> documentFor(
    String userId,
    SyncItem item,
  ) => _firestore
      .collection('users')
      .doc(userId)
      .collection(collectionFor(item.entityType))
      .doc(item.entityId);

  @override
  Future<void> sendBatch(String userId, List<SyncItem> items) async {
    final batch = _firestore.batch();
    for (final item in items) {
      final document = documentFor(userId, item);
      switch (item.operation) {
        case SyncOperation.create || SyncOperation.update:
          batch.set(document, item.payload);
        case SyncOperation.delete:
          batch.delete(document);
      }
    }
    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      throw SyncRemoteException(error.code);
    }
  }
}
