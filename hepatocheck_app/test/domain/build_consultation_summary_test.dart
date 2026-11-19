import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/risk_level.dart';
import 'package:hepatocheck_app/domain/usecases/build_consultation_summary.dart';
import 'package:hepatocheck_app/domain/usecases/summarize_exam_history.dart';

import '../support/test_data.dart';

void main() {
  const build = BuildConsultationSummary();
  final today = DateTime(2026, 11, 18, 15);

  test('sem exames e sem diário', () {
    final summary = build(
      exams: const [],
      drinks: const [],
      goals: const [],
      today: today,
    );

    expect(summary.risk, isNull);
    expect(summary.recentExams, isEmpty);
    expect(summary.hasDiary, isFalse);
    expect(summary.weeklyAverage, 0);
    expect(summary.alcoholFreeDays, 28);
    expect(summary.recentDelta, isNull);
  });

  test('média semanal e dias sem álcool dos últimos 28 dias', () {
    final summary = build(
      exams: const [],
      drinks: [
        testDrink(4, DateTime(2026, 10, 21, 23)),
        testDrink(6, DateTime(2026, 10, 22, 20)),
        testDrink(10, DateTime(2026, 11, 1, 20)),
        testDrink(2, DateTime(2026, 11, 1, 22)),
        testDrink(14, DateTime(2026, 11, 18, 12)),
        testDrink(5, DateTime(2026, 11, 19, 12)),
      ],
      goals: const [],
      today: today,
    );

    expect(summary.windowStart, DateTime(2026, 10, 22));
    expect(summary.weeklyAverage, closeTo(32 / 4, 0.0001));
    expect(summary.alcoholFreeDays, 25);
    expect(summary.hasDiary, isTrue);
  });

  test('mostra só os 3 exames mais recentes, do mais antigo ao atual', () {
    final summary = build(
      exams: [
        testExam(id: 'a', examDate: DateTime(2025, 6, 1), ast: 70),
        testExam(id: 'b', examDate: DateTime(2026, 3, 1), ast: 54),
        testExam(id: 'c', examDate: DateTime(2026, 9, 12), ast: 30),
        testExam(id: 'd', examDate: DateTime(2026, 6, 1), ast: 52),
      ],
      drinks: const [],
      goals: const [],
      today: today,
    );

    expect(summary.recentExams.map((point) => point.exam.id), ['b', 'd', 'c']);
    expect(summary.risk!.exam.id, 'c');
    expect(summary.risk!.level, RiskLevel.low);
    expect(summary.recentTrend, Fib4Trend.improved);
    expect(
      summary.recentDelta,
      closeTo(
        summary.recentExams.last.fib4.score -
            summary.recentExams.first.fib4.score,
        0.01,
      ),
    );
  });
}
