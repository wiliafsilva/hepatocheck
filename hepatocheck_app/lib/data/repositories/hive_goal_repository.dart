import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../domain/entities/reduction_goal.dart';
import '../../domain/repositories/goal_repository.dart';

class HiveGoalRepository implements GoalRepository {
  HiveGoalRepository(this.box);
  final Box<String> box;

  @override
  List<ReductionGoal> getAll() =>
      box.values
          .map((value) => ReductionGoal.fromJson(jsonDecode(value)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> save(ReductionGoal goal) async {
    if (goal.target < 0 ||
        goal.target > 1000 ||
        (goal.type == GoalType.alcoholFreeDaysPerWeek &&
            (goal.target < 1 || goal.target > 7))) {
      throw ArgumentError('Meta inválida.');
    }
    await box.put(goal.id, jsonEncode(goal.toJson()));
  }

  @override
  Future<void> delete(String id) => box.delete(id);
}
