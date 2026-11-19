import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/entities/reduction_goal.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/cloud_restore.dart';
import '../../domain/repositories/cloud_vault.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../models/firestore_mappers.dart';
import 'firestore_sync_remote.dart';

class FirestoreCloudRestore implements CloudRestore {
  FirestoreCloudRestore(
    this._firestore,
    this._vault, {
    required this._drinks,
    required this._exams,
    required this._goals,
    required this._queue,
  });

  final FirebaseFirestore _firestore;
  final CloudVault _vault;
  final RestorableRepository<DrinkEntry> _drinks;
  final RestorableRepository<LabExam> _exams;
  final RestorableRepository<ReductionGoal> _goals;
  final SyncQueueRepository _queue;

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    SyncEntityType type,
  ) => _firestore
      .collection('users')
      .doc(uid)
      .collection(FirestoreSyncRemote.collectionFor(type));

  @override
  Future<RestoreReport> restore(String uid) async {
    if (!_vault.isUnlocked) throw const VaultLockedException();
    final waiting = {
      for (final item in [..._queue.pending(), ..._queue.failed()])
        _key(item.entityType, item.entityId),
    };
    final counter = _Counter();

    final drinks = await _restoreType<DrinkEntry>(
      uid,
      SyncEntityType.drink,
      _drinks,
      waiting,
      counter,
      idOf: (item) => item.id,
      updatedOf: (item) => item.updatedAt,
      fromCloud: (id, data) =>
          _localDrink(FirestoreMappers.drinkFromFirestore(id, data)),
      toPayload: FirestoreMappers.drinkToFirestore,
    );
    final exams = await _restoreType<LabExam>(
      uid,
      SyncEntityType.exam,
      _exams,
      waiting,
      counter,
      idOf: (item) => item.id,
      updatedOf: (item) => item.updatedAt,
      fromCloud: (id, data) =>
          _localExam(FirestoreMappers.examFromFirestore(id, data)),
      toPayload: FirestoreMappers.examToFirestore,
    );
    final goals = await _restoreType<ReductionGoal>(
      uid,
      SyncEntityType.goal,
      _goals,
      waiting,
      counter,
      idOf: (item) => item.id,
      updatedOf: (item) => item.updatedAt,
      fromCloud: (id, data) =>
          _localGoal(FirestoreMappers.goalFromFirestore(id, data)),
      toPayload: FirestoreMappers.goalToFirestore,
    );

    return RestoreReport(
      drinks: drinks,
      exams: exams,
      goals: goals,
      unreadable: counter.unreadable,
    );
  }

  Future<int> _restoreType<T>(
    String uid,
    SyncEntityType type,
    RestorableRepository<T> repository,
    Set<String> waiting,
    _Counter counter, {
    required String Function(T item) idOf,
    required DateTime Function(T item) updatedOf,
    required T Function(String id, Map<String, dynamic> data) fromCloud,
    required Map<String, dynamic> Function(T item) toPayload,
  }) async {
    final snapshot = await _collection(uid, type).get();
    final local = {for (final item in repository.getAll()) idOf(item): item};
    final remoteIds = <String>{};
    var restored = 0;

    for (final document in snapshot.docs) {
      remoteIds.add(document.id);
      if (waiting.contains(_key(type, document.id))) continue;
      final sealed = SealedData.fromFields(document.data());
      if (sealed == null) {
        counter.unreadable++;
        continue;
      }
      final T remote;
      try {
        remote = fromCloud(document.id, await _vault.open(sealed));
      } on VaultLockedException {
        rethrow;
      } catch (_) {
        counter.unreadable++;
        continue;
      }
      final current = local[document.id];
      if (current != null && !updatedOf(remote).isAfter(updatedOf(current))) {
        continue;
      }
      await repository.restore(remote);
      restored++;
    }

    for (final entry in local.entries) {
      if (remoteIds.contains(entry.key)) continue;
      if (waiting.contains(_key(type, entry.key))) continue;
      await _queue.enqueue(
        entityType: type,
        entityId: entry.key,
        operation: SyncOperation.create,
        payload: toPayload(entry.value),
      );
    }
    return restored;
  }

  @override
  Future<void> deleteRemote(String uid) async {
    for (final type in SyncEntityType.values) {
      final snapshot = await _collection(uid, type).get();
      final documents = snapshot.docs;
      for (var start = 0; start < documents.length; start += 400) {
        final batch = _firestore.batch();
        for (final document in documents.skip(start).take(400)) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }
    }
  }

  static String _key(SyncEntityType type, String id) => '${type.name}/$id';

  static DrinkEntry _localDrink(DrinkEntry entry) => DrinkEntry(
    id: entry.id,
    type: entry.type,
    volumeMl: entry.volumeMl,
    alcoholPercent: entry.alcoholPercent,
    quantity: entry.quantity,
    consumedAt: entry.consumedAt.toLocal(),
    createdAt: entry.createdAt.toLocal(),
    updatedAt: entry.updatedAt.toLocal(),
  );

  static LabExam _localExam(LabExam exam) => LabExam(
    id: exam.id,
    examDate: exam.examDate.toLocal(),
    age: exam.age,
    ast: exam.ast,
    alt: exam.alt,
    platelets: exam.platelets,
    createdAt: exam.createdAt.toLocal(),
    updatedAt: exam.updatedAt.toLocal(),
  );

  static ReductionGoal _localGoal(ReductionGoal goal) => ReductionGoal(
    id: goal.id,
    type: goal.type,
    target: goal.target,
    startDate: goal.startDate.toLocal(),
    endDate: goal.endDate?.toLocal(),
    active: goal.active,
    createdAt: goal.createdAt.toLocal(),
    updatedAt: goal.updatedAt.toLocal(),
  );
}

class _Counter {
  int unreadable = 0;
}
