import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_serving.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/usecases/convert_to_standard_drinks.dart';

void main() {
  const convert = ConvertToStandardDrinks();

  double servingValue(DrinkType type) {
    final serving = DrinkServing.defaultFor(type);
    return convert(
      volumeMl: serving.volumeMl,
      alcoholPercent: serving.alcoholPercent,
    );
  }

  test('uma lata de cerveja equivale a 1 drinque padrão', () {
    expect(servingValue(DrinkType.beer), closeTo(1.0, 0.05));
  });

  test('uma taça de vinho e uma dose de destilado equivalem a 1 drinque', () {
    expect(servingValue(DrinkType.wine), closeTo(1.0, 0.05));
    expect(servingValue(DrinkType.spirit), closeTo(1.0, 0.05));
  });

  test('usa 14 g de álcool puro por drinque padrão', () {
    final grams = 1000 * 0.10 * ConvertToStandardDrinks.ethanolDensity;
    expect(
      convert(volumeMl: 1000, alcoholPercent: 10),
      closeTo(grams / 14, 1e-9),
    );
  });

  test('multiplica pela quantidade', () {
    final one = convert(volumeMl: 600, alcoholPercent: 5);
    expect(
      convert(volumeMl: 600, alcoholPercent: 5, quantity: 3),
      closeTo(one * 3, 1e-9),
    );
  });

  test('valores zerados ou negativos resultam em zero', () {
    expect(convert(volumeMl: 0, alcoholPercent: 5), 0);
    expect(convert(volumeMl: 350, alcoholPercent: 0), 0);
    expect(convert(volumeMl: 350, alcoholPercent: 5, quantity: 0), 0);
    expect(convert(volumeMl: -350, alcoholPercent: 5), 0);
  });

  test('soma o total de vários registros', () {
    final now = DateTime(2026, 11, 11, 20);
    DrinkEntry entry(String id, double volume, double alcohol, int quantity) =>
        DrinkEntry(
          id: id,
          type: DrinkType.beer,
          volumeMl: volume,
          alcoholPercent: alcohol,
          quantity: quantity,
          consumedAt: now,
          createdAt: now,
          updatedAt: now,
        );

    final entries = [entry('a', 350, 5, 2), entry('b', 150, 12, 1)];
    expect(
      convert.total(entries),
      closeTo(convert.ofEntry(entries[0]) + convert.ofEntry(entries[1]), 1e-9),
    );
  });
}
