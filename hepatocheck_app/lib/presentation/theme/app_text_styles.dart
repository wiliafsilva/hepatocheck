import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Níveis de texto do app, todos na fonte Inter.
///
/// Escala: display (número grande do medidor) > title (títulos de tela) >
/// subtitle (títulos de cartão) > body (texto corrido) > label (botões e
/// rótulos) > caption (avisos e notas).
abstract final class AppTextStyles {
  static const fontFamily = 'Inter';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Mapeia os níveis acima para o [TextTheme] do Material.
  static const textTheme = TextTheme(
    displayLarge: display,
    headlineMedium: title,
    titleMedium: subtitle,
    bodyLarge: body,
    bodyMedium: body,
    labelLarge: label,
    bodySmall: caption,
  );
}
