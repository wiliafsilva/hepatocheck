import '../entities/drink_entry.dart';
import '../entities/drink_type.dart';
import '../entities/report_period.dart';
import 'convert_to_standard_drinks.dart';

enum DrinkSummaryPeriod { week, month, year }

class DrinkTypeSummary {
  const DrinkTypeSummary({required this.type, required this.standardDrinks});

  final DrinkType type;
  final double standardDrinks;
}

class SummarizeDrinksByType {
  const SummarizeDrinksByType(this._convert);

  static const alwaysShown = [DrinkType.beer, DrinkType.spirit, DrinkType.wine];
  static const shownWhenPresent = [DrinkType.cocktail, DrinkType.other];

  final ConvertToStandardDrinks _convert;

  List<DrinkTypeSummary> call(
    Iterable<DrinkEntry> entries, {
    required DrinkSummaryPeriod period,
    required DateTime today,
  }) {
    final (start, end) = range(period, today);
    final totals = <DrinkType, double>{};
    for (final entry in entries) {
      final moment = entry.consumedAt;
      if (moment.isBefore(start) || !moment.isBefore(end)) continue;
      totals[entry.type] = (totals[entry.type] ?? 0) + _convert.ofEntry(entry);
    }
    return [
      for (final type in alwaysShown)
        DrinkTypeSummary(type: type, standardDrinks: totals[type] ?? 0),
      for (final type in shownWhenPresent)
        if (totals.containsKey(type))
          DrinkTypeSummary(type: type, standardDrinks: totals[type]!),
    ];
  }

  static (DateTime, DateTime) range(DrinkSummaryPeriod period, DateTime today) {
    switch (period) {
      case DrinkSummaryPeriod.week:
        final week = ReportPeriod.containing(today, ReportPeriodType.week);
        return (week.start, week.end);
      case DrinkSummaryPeriod.month:
        final month = ReportPeriod.containing(today, ReportPeriodType.month);
        return (month.start, month.end);
      case DrinkSummaryPeriod.year:
        return (DateTime(today.year), DateTime(today.year + 1));
    }
  }
}
