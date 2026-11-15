import '../entities/reduction_goal.dart';

abstract interface class GoalRepository {
  List<ReductionGoal> getAll();
  Future<void> save(ReductionGoal goal);
  Future<void> delete(String id);
}
