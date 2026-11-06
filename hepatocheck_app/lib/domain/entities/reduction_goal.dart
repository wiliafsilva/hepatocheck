enum GoalType { maxDrinksPerWeek, alcoholFreeDaysPerWeek }

class ReductionGoal {
  const ReductionGoal({
    required this.id,
    required this.type,
    required this.target,
    required this.startDate,
    this.endDate,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final GoalType type;
  final int target;
  final DateTime startDate;
  final DateTime? endDate;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReductionGoal copyWith({
    GoalType? type,
    int? target,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    DateTime? updatedAt,
  }) {
    return ReductionGoal(
      id: id,
      type: type ?? this.type,
      target: target ?? this.target,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
