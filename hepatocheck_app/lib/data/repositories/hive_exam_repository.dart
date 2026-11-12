import 'package:hive_ce/hive.dart';

import '../../domain/entities/lab_exam.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../models/firestore_mappers.dart';

class HiveExamRepository implements ExamRepository {
  HiveExamRepository(this._box, this._syncQueue);

  final Box<LabExam> _box;
  final SyncQueueRepository _syncQueue;

  @override
  List<LabExam> getAll() {
    final exams = _box.values.toList()
      ..sort((a, b) {
        final byDate = b.examDate.compareTo(a.examDate);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });
    return exams;
  }

  @override
  LabExam? getById(String id) => _box.get(id);

  @override
  Future<void> save(LabExam exam) async {
    final isNew = !_box.containsKey(exam.id);
    await _box.put(exam.id, exam);
    await _syncQueue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: exam.id,
      operation: isNew ? SyncOperation.create : SyncOperation.update,
      payload: FirestoreMappers.examToFirestore(exam),
    );
  }

  @override
  Future<void> delete(String id) async {
    if (!_box.containsKey(id)) return;
    await _box.delete(id);
    await _syncQueue.enqueue(
      entityType: SyncEntityType.exam,
      entityId: id,
      operation: SyncOperation.delete,
      payload: const {},
    );
  }
}
