import '../entities/consumption_report.dart';
import '../entities/drink_entry.dart';
import '../entities/drink_type.dart';
import '../entities/report_period.dart';
import 'convert_to_standard_drinks.dart';

class BuildConsumptionReport {
  const BuildConsumptionReport([
    this._convert = const ConvertToStandardDrinks(),
  ]);

  final ConvertToStandardDrinks _convert;

  ConsumptionReport call(
    List<DrinkEntry> entries,
    ReportPeriod period, {
    required DateTime today,
  }) {
    final inPeriod = entries
        .where((entry) => period.contains(entry.consumedAt))
        .toList();
    final previous = period.previous;

    final byType = <DrinkType, double>{};
    final perDay = <DateTime, double>{};
    final drinkingDays = <DateTime>{};
    var total = 0.0;
    final endOfToday = DateTime(today.year, today.month, today.day + 1);

    for (final entry in inPeriod) {
      final standardDrinks = _convert.ofEntry(entry);
      total += standardDrinks;
      byType.update(
        entry.type,
        (value) => value + standardDrinks,
        ifAbsent: () => standardDrinks,
      );
      final moment = entry.consumedAt;
      final day = DateTime(moment.year, moment.month, moment.day);
      perDay.update(
        day,
        (value) => value + standardDrinks,
        ifAbsent: () => standardDrinks,
      );
      if (standardDrinks > 0 && moment.isBefore(endOfToday)) {
        drinkingDays.add(day);
      }
    }

    final elapsedDays = period.elapsedDays(today);
    final drinkingDayCount = drinkingDays.length > elapsedDays
        ? elapsedDays
        : drinkingDays.length;
    final inProgress = period.isCurrent(today);
    final comparedDays = inProgress
        ? elapsedDays.clamp(0, previous.dayCount)
        : previous.dayCount;

    return ConsumptionReport(
      period: period,
      entryCount: inPeriod.length,
      totalStandardDrinks: total,
      averagePerDay: elapsedDays == 0 ? 0 : total / elapsedDays,
      elapsedDays: elapsedDays,
      drinkingDays: drinkingDayCount,
      alcoholFreeDays: elapsedDays - drinkingDayCount,
      byType: byType,
      previousTotal: _convert.total(
        entries.where(
          (entry) =>
              previous.containsInFirstDays(entry.consumedAt, comparedDays),
        ),
      ),
      inProgress: inProgress,
      comparedDays: comparedDays,
      daily: [
        for (final day in period.days())
          DailyConsumption(day: day, standardDrinks: perDay[day] ?? 0),
      ],
    );
  }
}
