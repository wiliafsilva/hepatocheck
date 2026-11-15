import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../domain/entities/reduction_goal.dart';
import '../../domain/entities/sync_item.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../models/firestore_mappers.dart';

class HiveGoalRepository implements GoalRepository {
  HiveGoalRepository(this.box, this._syncQueue);
  final Box<String> box;
  final SyncQueueRepository _syncQueue;

  @override
  List<ReductionGoal> getAll() =>
      box.values
          .map((value) => ReductionGoal.fromJson(jsonDecode(value)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> save(ReductionGoal goal) async {
    if (goal.target < 0 ||
        goal.target > 100 ||
        (goal.type == GoalType.alcoholFreeDaysPerWeek &&
            (goal.target < 1 || goal.target > 7))) {
      throw ArgumentError('Meta inválida.');
    }
    final isNew = !box.containsKey(goal.id);
    await box.put(goal.id, jsonEncode(goal.toJson()));
    await _syncQueue.enqueue(
      entityType: SyncEntityType.goal,
      entityId: goal.id,
      operation: isNew ? SyncOperation.create : SyncOperation.update,
      payload: FirestoreMappers.goalToFirestore(goal),
    );
  }

  @override
  Future<void> delete(String id) async {
    if (!box.containsKey(id)) return;
    await box.delete(id);
    await _syncQueue.enqueue(
      entityType: SyncEntityType.goal,
      entityId: id,
      operation: SyncOperation.delete,
      payload: const {},
    );
  }
}
