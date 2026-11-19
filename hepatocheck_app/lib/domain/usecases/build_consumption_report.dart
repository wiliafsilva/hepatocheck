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
    final endOfToday = DateTime(today.year, today.month, today.day + 1);
    final inPeriod = entries
        .where(
          (entry) =>
              period.contains(entry.consumedAt) &&
              entry.consumedAt.isBefore(endOfToday),
        )
        .toList();
    final previous = period.previous;

    final byType = <DrinkType, double>{};
    final perDay = <DateTime, double>{};
    final drinkingDays = <DateTime>{};
    var total = 0.0;

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
      if (standardDrinks > 0) drinkingDays.add(day);
    }

    final elapsedDays = period.elapsedDays(today);
    final drinkingDayCount = drinkingDays.length > elapsedDays
        ? elapsedDays
        : drinkingDays.length;
    final inProgress = period.isCurrent(today);
    final window = _comparisonWindow(period, previous, today, inProgress);

    return ConsumptionReport(
      period: period,
      entryCount: inPeriod.length,
      totalStandardDrinks: total,
      averagePerDay: elapsedDays == 0 ? 0 : total / elapsedDays,
      elapsedDays: elapsedDays,
      drinkingDays: drinkingDayCount,
      alcoholFreeDays: elapsedDays - drinkingDayCount,
      byType: byType,
      comparedTotal: _convert.total(
        inPeriod.where((entry) => entry.consumedAt.isBefore(window.current)),
      ),
      previousTotal: _convert.total(
        entries.where(
          (entry) =>
              previous.contains(entry.consumedAt) &&
              entry.consumedAt.isBefore(window.previous),
        ),
      ),
      inProgress: inProgress,
      comparedDays: window.days,
      daily: [
        for (final day in period.days())
          DailyConsumption(day: day, standardDrinks: perDay[day] ?? 0),
      ],
    );
  }

  ({DateTime current, DateTime previous, int days}) _comparisonWindow(
    ReportPeriod period,
    ReportPeriod previous,
    DateTime today,
    bool inProgress,
  ) {
    final available = inProgress ? period.elapsedDays(today) : period.dayCount;
    if (available > previous.dayCount) {
      final days = previous.dayCount;
      return (
        current: period.firstDaysEnd(days),
        previous: previous.end,
        days: days,
      );
    }
    if (!inProgress) {
      return (
        current: period.end,
        previous: previous.firstDaysEnd(available),
        days: available,
      );
    }
    final fullDays = available - 1;
    final start = previous.start;
    final sameMoment = DateTime(
      start.year,
      start.month,
      start.day + fullDays,
      today.hour,
      today.minute,
      today.second,
      today.millisecond,
    );
    return (
      current: today,
      previous: sameMoment.isBefore(previous.end) ? sameMoment : previous.end,
      days: available,
    );
  }
}
