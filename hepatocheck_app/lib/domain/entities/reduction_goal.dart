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

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'target': target,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'active': active,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ReductionGoal.fromJson(Map<String, dynamic> data) => ReductionGoal(
    id: data['id'] as String,
    type: GoalType.values.byName(data['type'] as String),
    target: data['target'] as int,
    startDate: DateTime.parse(data['startDate'] as String),
    endDate: data['endDate'] == null
        ? null
        : DateTime.parse(data['endDate'] as String),
    active: data['active'] as bool,
    createdAt: DateTime.parse(data['createdAt'] as String),
    updatedAt: DateTime.parse(data['updatedAt'] as String),
  );

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
