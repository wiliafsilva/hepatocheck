import 'drink_type.dart';

class DrinkServing {
  const DrinkServing({
    required this.name,
    required this.type,
    required this.volumeMl,
    required this.alcoholPercent,
  });

  final String name;
  final DrinkType type;
  final double volumeMl;
  final double alcoholPercent;

  static const all = <DrinkServing>[
    DrinkServing(
      name: 'Lata',
      type: DrinkType.beer,
      volumeMl: 350,
      alcoholPercent: 5,
    ),
    DrinkServing(
      name: 'Long neck',
      type: DrinkType.beer,
      volumeMl: 355,
      alcoholPercent: 5,
    ),
    DrinkServing(
      name: 'Garrafa',
      type: DrinkType.beer,
      volumeMl: 600,
      alcoholPercent: 5,
    ),
    DrinkServing(
      name: 'Chope',
      type: DrinkType.beer,
      volumeMl: 300,
      alcoholPercent: 5,
    ),
    DrinkServing(
      name: 'Taça',
      type: DrinkType.wine,
      volumeMl: 150,
      alcoholPercent: 12,
    ),
    DrinkServing(
      name: 'Garrafa',
      type: DrinkType.wine,
      volumeMl: 750,
      alcoholPercent: 12,
    ),
    DrinkServing(
      name: 'Dose',
      type: DrinkType.spirit,
      volumeMl: 45,
      alcoholPercent: 40,
    ),
    DrinkServing(
      name: 'Copo',
      type: DrinkType.cocktail,
      volumeMl: 200,
      alcoholPercent: 8,
    ),
    DrinkServing(
      name: 'Copo',
      type: DrinkType.other,
      volumeMl: 200,
      alcoholPercent: 5,
    ),
  ];

  static List<DrinkServing> forType(DrinkType type) =>
      all.where((serving) => serving.type == type).toList();

  static DrinkServing defaultFor(DrinkType type) => forType(type).first;

  static DrinkServing? matching(DrinkType type, double volumeMl) {
    for (final serving in forType(type)) {
      if (serving.volumeMl == volumeMl) return serving;
    }
    return null;
  }
}
