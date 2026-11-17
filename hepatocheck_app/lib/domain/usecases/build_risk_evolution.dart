import '../entities/drink_entry.dart';
import '../entities/lab_exam.dart';
import '../entities/risk_level.dart';
import 'calculate_liver_health.dart';

/// Um ponto da evolução do risco hepático: o FIB-4 e o medidor do fígado no
/// dia de um exame.
class RiskEvolutionPoint {
  const RiskEvolutionPoint({
    required this.examId,
    required this.date,
    required this.fib4,
    required this.percent,
    required this.risk,
  });

  final String examId;
  final DateTime date;
  final double fib4;

  /// Medidor de 0 a 100, já com o desconto do consumo das 4 semanas
  /// anteriores ao exame.
  final double percent;
  final RiskLevel risk;
}

/// Monta a série do gráfico de evolução temporal do risco (tarefa 30), com a
/// mesma regra do medidor do Início ([CalculateLiverHealth]).
class BuildRiskEvolution {
  const BuildRiskEvolution([
    this._calculator = const CalculateLiverHealth(),
  ]);

  final CalculateLiverHealth _calculator;

  List<RiskEvolutionPoint> call({
    required List<LabExam> exams,
    required List<DrinkEntry> drinks,
  }) {
    final sorted = [...exams]
      ..sort((a, b) {
        final byDate = a.examDate.compareTo(b.examDate);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });
    return [
      for (final exam in sorted) _pointFor(exam, drinks),
    ];
  }

  RiskEvolutionPoint _pointFor(LabExam exam, List<DrinkEntry> drinks) {
    final date = exam.examDate;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final health = _calculator(exams: [exam], drinks: drinks, now: endOfDay);
    return RiskEvolutionPoint(
      examId: exam.id,
      date: date,
      fib4: health.fib4!,
      percent: health.percent!,
      risk: health.risk!,
    );
  }
}
