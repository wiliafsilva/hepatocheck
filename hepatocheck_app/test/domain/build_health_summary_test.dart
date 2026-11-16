import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/entities/report_period.dart';
import 'package:hepatocheck_app/domain/entities/risk_level.dart';
import 'package:hepatocheck_app/domain/usecases/build_exam_evolution.dart';
import 'package:hepatocheck_app/domain/usecases/build_health_summary.dart';

import '../support/test_data.dart';

void main() {
  final now = DateTime(2026, 11, 11, 18);

  group('Evolução dos exames', () {
    test('ordena do mais antigo para o mais recente', () {
      final points = const BuildExamEvolution()([
        testExam(id: 'c', examDate: DateTime(2026, 9, 1)),
        testExam(id: 'a', examDate: DateTime(2026, 1, 1), ast: 60),
        testExam(id: 'b', examDate: DateTime(2026, 5, 1), ast: 45),
      ]);

      expect([for (final p in points) p.exam.id], ['a', 'b', 'c']);
      expect(points.first.fib4.score, closeTo(1.80, 0.001));
      expect(points.first.fib4.riskLevel, RiskLevel.intermediate);
      expect(points.last.fib4.score, closeTo(0.90, 0.001));
    });

    test('sem exames devolve lista vazia', () {
      expect(const BuildExamEvolution()(const []), isEmpty);
    });
  });

  group('Resumo do PDF', () {
    const build = BuildHealthSummary();

    test('junta risco, exames, consumo e metas do período', () {
      final month = ReportPeriod.containing(now, ReportPeriodType.month);
      final goal = ReductionGoal(
        id: 'g1',
        type: GoalType.maxDrinksPerWeek,
        target: 2,
        startDate: DateTime(2026, 11, 2),
        active: true,
        createdAt: DateTime(2026, 11, 2),
        updatedAt: DateTime(2026, 11, 2),
      );
      final summary = build(
        exams: [
          testExam(id: 'a', examDate: DateTime(2026, 3, 1), ast: 45),
          testExam(id: 'b', examDate: DateTime(2026, 10, 1)),
        ],
        drinks: [
          testDrink(3, DateTime(2026, 11, 3)),
          testDrink(1, DateTime(2026, 11, 10)),
        ],
        goals: [goal],
        period: month,
        now: now,
      );

      expect(summary.generatedAt, now);
      expect(summary.period, month);
      expect(summary.risk!.exam.id, 'b');
      expect(summary.risk!.level, RiskLevel.low);
      expect(summary.evolution, hasLength(2));
      expect(summary.examHistory!.examCount, 2);
      expect(summary.report.totalStandardDrinks, closeTo(4, 0.0001));
      expect(summary.report.daily, hasLength(30));
      expect(
        [for (final progress in summary.goals) progress.week.start],
        [
          DateTime(2026, 11, 2),
          DateTime(2026, 11, 9),
          DateTime(2026, 11, 16),
          DateTime(2026, 11, 23),
          DateTime(2026, 11, 30),
        ],
      );
    });

    test('sem dados gera um resumo vazio', () {
      final summary = build(
        exams: const [],
        drinks: const [],
        goals: const [],
        period: ReportPeriod.containing(now, ReportPeriodType.week),
        now: now,
      );

      expect(summary.risk, isNull);
      expect(summary.evolution, isEmpty);
      expect(summary.examHistory, isNull);
      expect(summary.report.hasData, isFalse);
      expect(summary.goals, isEmpty);
    });
  });
}
