import '../entities/drink_entry.dart';

class ConvertToStandardDrinks {
  const ConvertToStandardDrinks();

  static const gramsPerStandardDrink = 14.0;
  static const ethanolDensity = 0.789;

  double call({
    required double volumeMl,
    required double alcoholPercent,
    int quantity = 1,
  }) {
    if (volumeMl <= 0 || alcoholPercent <= 0 || quantity <= 0) return 0;
    final grams = volumeMl * (alcoholPercent / 100) * ethanolDensity;
    return grams * quantity / gramsPerStandardDrink;
  }

  double ofEntry(DrinkEntry entry) => call(
    volumeMl: entry.volumeMl,
    alcoholPercent: entry.alcoholPercent,
    quantity: entry.quantity,
  );

  double total(Iterable<DrinkEntry> entries) =>
      entries.fold(0, (sum, entry) => sum + ofEntry(entry));
}
