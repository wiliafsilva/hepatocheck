import 'package:flutter/material.dart';

import '../../domain/entities/drink_serving.dart';
import '../../domain/entities/drink_type.dart';

extension DrinkTypeLabels on DrinkType {
  String get label => switch (this) {
    DrinkType.beer => 'Cerveja',
    DrinkType.wine => 'Vinho',
    DrinkType.spirit => 'Destilado',
    DrinkType.cocktail => 'Drinque',
    DrinkType.other => 'Outra',
  };

  String get noun => switch (this) {
    DrinkType.beer => 'cerveja',
    DrinkType.wine => 'vinho',
    DrinkType.spirit => 'destilado',
    DrinkType.cocktail => 'drinque',
    DrinkType.other => 'outra bebida',
  };

  IconData get icon => switch (this) {
    DrinkType.beer => Icons.sports_bar,
    DrinkType.wine => Icons.wine_bar,
    DrinkType.spirit => Icons.liquor,
    DrinkType.cocktail => Icons.local_bar,
    DrinkType.other => Icons.local_drink,
  };
}

String formatDecimal(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString().replaceAll('.', ',');
}

String formatStandardDrinks(double value) {
  final text = value.toStringAsFixed(1).replaceAll('.', ',');
  return '$text ${text == '1,0' ? 'drinque padrão' : 'drinques padrão'}';
}

String describeDrink({
  required DrinkType type,
  required double volumeMl,
  required double alcoholPercent,
  int quantity = 1,
}) {
  final serving = DrinkServing.matching(type, volumeMl);
  final details =
      '(${formatDecimal(volumeMl)} ml, ${formatDecimal(alcoholPercent)}%)';
  if (serving == null) return '$quantity × ${type.label} $details';
  final name = serving.name.toLowerCase();
  final unit = quantity == 1 ? name : '${name}s';
  return '$quantity $unit de ${type.noun} $details';
}
