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
      if (standardDrinks > 0 && moment.isBefore(endOfToday)) {
        drinkingDays.add(DateTime(moment.year, moment.month, moment.day));
      }
    }

    final elapsedDays = period.elapsedDays(today);
    final drinkingDayCount = drinkingDays.length > elapsedDays
        ? elapsedDays
        : drinkingDays.length;

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
        entries.where((entry) => previous.contains(entry.consumedAt)),
      ),
    );
  }
}
