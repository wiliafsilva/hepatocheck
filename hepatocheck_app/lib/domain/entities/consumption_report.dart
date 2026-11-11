import 'drink_type.dart';
import 'report_period.dart';

class ConsumptionReport {
  const ConsumptionReport({
    required this.period,
    required this.entryCount,
    required this.totalStandardDrinks,
    required this.averagePerDay,
    required this.elapsedDays,
    required this.drinkingDays,
    required this.alcoholFreeDays,
    required this.byType,
    required this.previousTotal,
  });

  final ReportPeriod period;
  final int entryCount;
  final double totalStandardDrinks;
  final double averagePerDay;
  final int elapsedDays;
  final int drinkingDays;
  final int alcoholFreeDays;
  final Map<DrinkType, double> byType;
  final double previousTotal;

  bool get hasData => entryCount > 0;

  double get difference => totalStandardDrinks - previousTotal;

  double? get changePercent =>
      previousTotal == 0 ? null : difference / previousTotal * 100;
}
