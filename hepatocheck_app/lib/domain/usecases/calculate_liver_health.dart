import '../entities/drink_entry.dart';
import '../entities/lab_exam.dart';
import '../entities/risk_level.dart';

/// Resultado do medidor de saúde do fígado.
class LiverHealth {
  const LiverHealth({
    required this.exam,
    required this.percent,
    required this.risk,
    required this.weeklyAverage,
    required this.consumptionPenalty,
  });

  /// Sem exame cadastrado não há como calcular o medidor.
  const LiverHealth.empty({this.weeklyAverage = 0})
    : exam = null,
      percent = null,
      risk = null,
      consumptionPenalty = 0;

  /// Exame mais recente usado no cálculo.
  final LabExam? exam;

  /// Medidor de 0 a 100, ou nulo quando não há exame.
  final double? percent;

  final RiskLevel? risk;

  /// Média de drinques padrão por semana nas últimas 4 semanas.
  final double weeklyAverage;

  /// Pontos descontados do medidor por causa do consumo (0 a 15).
  final double consumptionPenalty;

  bool get hasExam => exam != null;
}

/// Regra do medidor de saúde do fígado (educativo, não é resultado clínico):
///
/// 1. Base: 100% com FIB-4 igual a 0, 0% com FIB-4 de 3,25 ou mais, linear
///    entre os dois, usando o exame mais recente.
/// 2. Desconto de até 15 pontos pelo consumo das últimas 4 semanas: se a média
///    semanal passa de [weeklyLowRiskLimit], o desconto cresce de forma linear
///    e chega a 15 quando a média é o dobro do limite.
/// 3. A cor (risco) segue só a faixa do FIB-4.
class CalculateLiverHealth {
  const CalculateLiverHealth();

  /// Limite semanal de baixo risco, em drinques padrão.
  static const weeklyLowRiskLimit = 7.0;
  static const maxFib4 = 3.25;
  static const maxPenalty = 15.0;
  static const windowDays = 28;

  LiverHealth call({
    required List<LabExam> exams,
    required List<DrinkEntry> drinks,
    required DateTime now,
  }) {
    final average = _weeklyAverage(drinks, now);
    if (exams.isEmpty) return LiverHealth.empty(weeklyAverage: average);

    final latest = exams.reduce((a, b) => b.date.isAfter(a.date) ? b : a);
    final fib4 = latest.fib4;

    final base = (100 * (1 - fib4 / maxFib4)).clamp(0.0, 100.0);
    final excess = average - weeklyLowRiskLimit;
    final penalty = excess <= 0
        ? 0.0
        : (maxPenalty * excess / weeklyLowRiskLimit).clamp(0.0, maxPenalty);

    return LiverHealth(
      exam: latest,
      percent: (base - penalty).clamp(0.0, 100.0),
      risk: RiskLevel.fromFib4(fib4, age: latest.age),
      weeklyAverage: average,
      consumptionPenalty: penalty,
    );
  }

  double _weeklyAverage(List<DrinkEntry> drinks, DateTime now) {
    final start = now.subtract(const Duration(days: windowDays));
    final total = drinks
        .where((d) => !d.dateTime.isBefore(start) && !d.dateTime.isAfter(now))
        .fold<double>(0, (sum, d) => sum + d.standardDrinks);
    return total / (windowDays / 7);
  }
}
