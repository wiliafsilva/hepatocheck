import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/entities/report_period.dart';
import 'package:hepatocheck_app/domain/entities/risk_level.dart';
import 'package:hepatocheck_app/domain/usecases/assess_current_risk.dart';

import '../support/test_data.dart';

ReductionGoal _goal({
  GoalType type = GoalType.maxDrinksPerWeek,
  int target = 5,
  bool active = true,
  DateTime? startDate,
  String id = 'g1',
}) {
  final start = startDate ?? DateTime(2026, 11, 2);
  return ReductionGoal(
    id: id,
    type: type,
    target: target,
    startDate: start,
    active: active,
    createdAt: start,
    updatedAt: start,
  );
}

void main() {
  const assess = AssessCurrentRisk();
  final today = DateTime(2026, 11, 11, 18);

  test('sem exame não há risco', () {
    expect(
      assess(exams: const [], drinks: const [], goals: const [], today: today),
      isNull,
    );
  });

  test('usa o exame mais recente pela data do exame', () {
    final risk = assess(
      exams: [
        testExam(id: 'novo', examDate: DateTime(2026, 10, 1)),
        testExam(id: 'antigo', examDate: DateTime(2026, 1, 1), ast: 80),
      ],
      drinks: const [],
      goals: const [],
      today: today,
    );

    expect(risk!.exam.id, 'novo');
    expect(risk.level, RiskLevel.low);
  });

  test('sem meta de limite fica só o FIB-4', () {
    final risk = assess(
      exams: [testExam()],
      drinks: [testDrink(20, DateTime(2026, 11, 10))],
      goals: [_goal(type: GoalType.alcoholFreeDaysPerWeek, target: 3)],
      today: today,
    );

    expect(risk!.weeklyLimit, isNull);
    expect(risk.level, RiskLevel.low);
    expect(risk.raisedByConsumption, isFalse);
  });

  test('passar do limite semanal sobe um nível', () {
    final risk = assess(
      exams: [testExam()],
      drinks: [
        testDrink(4, DateTime(2026, 11, 9)),
        testDrink(3, DateTime(2026, 11, 10)),
        testDrink(10, DateTime(2026, 11, 8)),
      ],
      goals: [_goal(target: 5)],
      today: today,
    );

    expect(risk!.weeklyStandardDrinks, closeTo(7, 0.0001));
    expect(risk.weeklyLimit, 5);
    expect(risk.level, RiskLevel.intermediate);
    expect(risk.raisedByConsumption, isTrue);
  });

  test('igual ao limite não sobe', () {
    final risk = assess(
      exams: [testExam()],
      drinks: [testDrink(5, DateTime(2026, 11, 9))],
      goals: [_goal(target: 5)],
      today: today,
    );

    expect(risk!.level, RiskLevel.low);
  });

  test('ignora metas inativas ou que ainda não começaram', () {
    final risk = assess(
      exams: [testExam()],
      drinks: [testDrink(9, DateTime(2026, 11, 9))],
      goals: [
        _goal(id: 'inativa', target: 1, active: false),
        _goal(id: 'futura', target: 1, startDate: DateTime(2026, 11, 16)),
      ],
      today: today,
    );

    expect(risk!.weeklyLimit, isNull);
    expect(risk.level, RiskLevel.low);
  });

  test('com duas metas de limite vale a menor', () {
    expect(
      AssessCurrentRisk.weeklyLimit([
        _goal(id: 'a', target: 7),
        _goal(id: 'b', target: 3),
      ], ReportPeriod.containing(today, ReportPeriodType.week)),
      3,
    );
  });
}
