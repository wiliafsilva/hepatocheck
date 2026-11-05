import 'package:flutter/material.dart';

/// Paleta do protótipo: tema escuro, verde oliva e cores do semáforo de risco.
abstract final class AppColors {
  // Superfícies
  static const background = Color(0xFF121410);
  static const surface = Color(0xFF1C1F18);
  static const surfaceVariant = Color(0xFF262A20);
  static const outline = Color(0xFF3A3F30);

  // Verde oliva (cor da marca)
  static const olive = Color(0xFF8A9A5B);
  static const oliveDark = Color(0xFF55612F);
  static const onOlive = Color(0xFF12140A);

  // Texto
  static const textPrimary = Color(0xFFF1F2EC);
  static const textSecondary = Color(0xFFB4B8A8);

  // Semáforo de risco
  static const riskGreen = Color(0xFF4CAF50);
  static const riskYellow = Color(0xFFF2B705);
  static const riskRed = Color(0xFFE5484D);
}
