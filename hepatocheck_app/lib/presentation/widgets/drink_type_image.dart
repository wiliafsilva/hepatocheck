import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/drink_type.dart';
import '../theme/app_colors.dart';
import '../theme/drink_type_labels.dart';

class DrinkTypeImage extends StatelessWidget {
  const DrinkTypeImage({
    super.key,
    required this.type,
    required this.selected,
    this.size = 40,
  });

  static const assets = {
    DrinkType.beer: 'assets/images/bebidas/cerveja.svg',
    DrinkType.spirit: 'assets/images/bebidas/destilado.svg',
    DrinkType.wine: 'assets/images/bebidas/vinho.svg',
    DrinkType.cocktail: 'assets/images/bebidas/drinque.svg',
  };

  final DrinkType type;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = assets[type];
    if (asset == null) {
      return Icon(
        type.icon,
        size: size * 0.7,
        color: selected ? AppColors.olive : AppColors.textPrimary,
      );
    }
    return SvgPicture.asset(asset, width: size, height: size);
  }
}
