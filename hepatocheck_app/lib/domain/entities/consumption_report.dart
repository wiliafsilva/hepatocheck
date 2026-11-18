import 'drink_type.dart';
import 'report_period.dart';

class DailyConsumption {
  const DailyConsumption({required this.day, required this.standardDrinks});

  final DateTime day;
  final double standardDrinks;
}

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
    double? comparedTotal,
    this.inProgress = false,
    this.comparedDays = 0,
    this.daily = const [],
  }) : comparedTotal = comparedTotal ?? totalStandardDrinks;

  final ReportPeriod period;
  final int entryCount;
  final double totalStandardDrinks;
  final double averagePerDay;
  final int elapsedDays;
  final int drinkingDays;
  final int alcoholFreeDays;
  final Map<DrinkType, double> byType;
  final double previousTotal;
  final double comparedTotal;
  final bool inProgress;
  final int comparedDays;
  final List<DailyConsumption> daily;

  bool get hasData => entryCount > 0;

  bool get comparesFewerDays => comparedDays < elapsedDays;

  bool get comparesPartOfPrevious =>
      comparedDays < period.previous.dayCount || inProgress;

  bool get hasComparisonNote => comparesFewerDays || comparesPartOfPrevious;

  double get difference => comparedTotal - previousTotal;

  double? get changePercent =>
      previousTotal == 0 ? null : difference / previousTotal * 100;
}
