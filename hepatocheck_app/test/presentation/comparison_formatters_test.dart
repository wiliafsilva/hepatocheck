import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/consumption_report.dart';
import 'package:hepatocheck_app/domain/entities/report_period.dart';
import 'package:hepatocheck_app/presentation/formatters.dart';

ConsumptionReport _report({
  required ReportPeriod period,
  double total = 0,
  double? compared,
  double previous = 0,
  int elapsedDays = 7,
  int comparedDays = 7,
  bool inProgress = false,
}) => ConsumptionReport(
  period: period,
  entryCount: total > 0 ? 1 : 0,
  totalStandardDrinks: total,
  averagePerDay: 0,
  elapsedDays: elapsedDays,
  drinkingDays: 0,
  alcoholFreeDays: elapsedDays,
  byType: const {},
  previousTotal: previous,
  comparedTotal: compared,
  inProgress: inProgress,
  comparedDays: comparedDays,
);

void main() {
  final week = ReportPeriod.containing(
    DateTime(2026, 11, 4),
    ReportPeriodType.week,
  );
  final march = ReportPeriod.containing(
    DateTime(2027, 3, 1),
    ReportPeriodType.month,
  );
  final february = ReportPeriod.containing(
    DateTime(2027, 2, 1),
    ReportPeriodType.month,
  );

  test('sem consumo no período anterior não mostra porcentagem', () {
    final report = _report(period: week, total: 3);

    expect(formatDifference(roundedDifference(report)), '+3,0');
    expect(formatChangePercent(report), 'sem consumo antes');
  });

  test('diferença negativa usa o sinal de menos e a porcentagem', () {
    final report = _report(period: week, total: 1, previous: 4);

    expect(formatDifference(roundedDifference(report)), '−3,0');
    expect(formatChangePercent(report), '75%');
  });

  test('a comparação usa o total dos mesmos dias, não o total do mês', () {
    final report = _report(
      period: march,
      total: 5,
      compared: 2,
      previous: 2,
      elapsedDays: 31,
      comparedDays: 28,
    );

    expect(formatDifference(roundedDifference(report)), 'Igual');
    expect(
      formatComparisonNote(report),
      'Comparados os 28 primeiros dias deste mês e do mês anterior, '
      'que é mais curto.',
    );
  });

  test('mês mais curto avisa que compara o começo do mês anterior', () {
    final report = _report(period: february, elapsedDays: 28, comparedDays: 28);

    expect(report.hasComparisonNote, isTrue);
    expect(
      formatComparisonNote(report),
      'Comparado com os 28 primeiros dias do mês anterior, que é mais longo.',
    );
  });

  test('semana encerrada não tem aviso', () {
    expect(_report(period: week).hasComparisonNote, isFalse);
  });
}
