import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/risk_level.dart';
import 'package:hepatocheck_app/domain/usecases/build_risk_evolution.dart';

import '../support/test_data.dart';

void main() {
  const build = BuildRiskEvolution();

  test('sem exames não há pontos', () {
    expect(build(exams: const [], drinks: const []), isEmpty);
  });

  test('um ponto por exame, em ordem de data', () {
    final points = build(
      exams: [
        testExam(id: 'novo', examDate: DateTime(2026, 11, 1)),
        testExam(id: 'antigo', examDate: DateTime(2026, 5, 1)),
      ],
      drinks: const [],
    );

    expect(points.map((p) => p.examId), ['antigo', 'novo']);
  });

  test('FIB-4 e medidor seguem a mesma regra do Início', () {
    final points = build(exams: [testExam()], drinks: const []);

    expect(points.single.fib4, closeTo(0.90, 0.01));
    expect(points.single.percent, closeTo(72.3, 0.1));
    expect(points.single.risk, RiskLevel.low);
  });

  test('o consumo das 4 semanas antes do exame reduz o medidor daquele ponto', () {
    final examDate = DateTime(2026, 11, 1);
    final points = build(
      exams: [testExam(examDate: examDate)],
      drinks: [
        testDrink(42, examDate.subtract(const Duration(days: 2))),
        // Depois do exame: não pode influenciar o ponto.
        testDrink(100, examDate.add(const Duration(days: 3))),
      ],
    );

    expect(points.single.percent, closeTo(64.8, 0.1));
  });

  test('exame piorando muda a faixa do ponto', () {
    final points = build(
      exams: [
        testExam(id: 'a', examDate: DateTime(2026, 1, 10)),
        testExam(
          id: 'b',
          examDate: DateTime(2026, 11, 1),
          ast: 120,
          platelets: 120,
        ),
      ],
      drinks: const [],
    );

    expect(points.last.fib4, greaterThan(points.first.fib4));
    expect(points.last.percent, lessThan(points.first.percent));
    expect(points.last.risk, isNot(RiskLevel.low));
  });
}
