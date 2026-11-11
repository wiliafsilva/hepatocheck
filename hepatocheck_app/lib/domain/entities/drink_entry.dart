/// Registro do diário de álcool, já convertido em drinques padrão.
class DrinkEntry {
  const DrinkEntry({
    required this.id,
    required this.dateTime,
    required this.standardDrinks,
  });

  final String id;
  final DateTime dateTime;

  /// Quantidade em drinques padrão (RF04).
  final double standardDrinks;
}
