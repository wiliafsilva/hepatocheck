import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/usecases/convert_to_standard_drinks.dart';
import 'package:hepatocheck_app/domain/usecases/summarize_drinks_by_type.dart';

DrinkEntry drink(
  DrinkType type,
  DateTime at, {
  double volumeMl = 350,
  double alcoholPercent = 5,
  int quantity = 1,
}) => DrinkEntry(
  id: '$type-${at.microsecondsSinceEpoch}-$volumeMl',
  type: type,
  volumeMl: volumeMl,
  alcoholPercent: alcoholPercent,
  quantity: quantity,
  consumedAt: at,
  createdAt: at,
  updatedAt: at,
);

void main() {
  const convert = ConvertToStandardDrinks();
  const summarize = SummarizeDrinksByType(convert);
  final today = DateTime(2026, 11, 20, 10);

  Map<DrinkType, double> totals(
    List<DrinkEntry> entries,
    DrinkSummaryPeriod period,
  ) => {
    for (final item in summarize(entries, period: period, today: today))
      item.type: item.standardDrinks,
  };

  final beerMonday = drink(DrinkType.beer, DateTime(2026, 11, 16, 20));
  final beerEarlyMonth = drink(
    DrinkType.beer,
    DateTime(2026, 11, 2, 20),
    quantity: 2,
  );
  final wineLastWeek = drink(
    DrinkType.wine,
    DateTime(2026, 11, 15, 21),
    volumeMl: 150,
    alcoholPercent: 12,
  );
  final spiritMarch = drink(
    DrinkType.spirit,
    DateTime(2026, 3, 10, 22),
    volumeMl: 50,
    alcoholPercent: 40,
  );
  final beerLastYear = drink(DrinkType.beer, DateTime(2025, 12, 31, 23));
  final entries = [
    beerMonday,
    beerEarlyMonth,
    wineLastWeek,
    spiritMarch,
    beerLastYear,
  ];

  test('a semana começa na segunda, como no Relatório', () {
    final week = totals(entries, DrinkSummaryPeriod.week);

    expect(week[DrinkType.beer], closeTo(convert.ofEntry(beerMonday), 1e-9));
    expect(week[DrinkType.wine], 0);
    expect(week[DrinkType.spirit], 0);
  });

  test('o mês soma do dia 1 até o fim do mês', () {
    final month = totals(entries, DrinkSummaryPeriod.month);

    expect(
      month[DrinkType.beer],
      closeTo(
        convert.ofEntry(beerMonday) + convert.ofEntry(beerEarlyMonth),
        1e-9,
      ),
    );
    expect(month[DrinkType.wine], closeTo(convert.ofEntry(wineLastWeek), 1e-9));
  });

  test('o ano soma de janeiro a dezembro do ano atual', () {
    final year = totals(entries, DrinkSummaryPeriod.year);

    expect(year[DrinkType.spirit], closeTo(convert.ofEntry(spiritMarch), 1e-9));
    expect(
      year[DrinkType.beer],
      closeTo(
        convert.ofEntry(beerMonday) + convert.ofEntry(beerEarlyMonth),
        1e-9,
      ),
    );
  });

  test(
    'cerveja, destilado e vinho aparecem sempre; drinque e outra só se houver',
    () {
      final empty = summarize(
        const [],
        period: DrinkSummaryPeriod.month,
        today: today,
      );
      expect(empty.map((item) => item.type), [
        DrinkType.beer,
        DrinkType.spirit,
        DrinkType.wine,
      ]);
      expect(empty.every((item) => item.standardDrinks == 0), isTrue);

      final withCocktail = summarize(
        [drink(DrinkType.cocktail, DateTime(2026, 11, 18, 20))],
        period: DrinkSummaryPeriod.month,
        today: today,
      );
      expect(withCocktail.map((item) => item.type), [
        DrinkType.beer,
        DrinkType.spirit,
        DrinkType.wine,
        DrinkType.cocktail,
      ]);
    },
  );
}
