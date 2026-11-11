import 'dart:math' as math;

/// Exame laboratorial usado no cálculo do FIB-4.
class LabExam {
  const LabExam({
    required this.id,
    required this.date,
    required this.age,
    required this.ast,
    required this.alt,
    required this.platelets,
  });

  final String id;
  final DateTime date;

  /// Idade em anos na data do exame.
  final int age;

  /// TGO (AST) em U/L.
  final double ast;

  /// TGP (ALT) em U/L.
  final double alt;

  /// Plaquetas em 10⁹/L.
  final double platelets;

  /// FIB-4 = (idade × TGO) / (plaquetas × √TGP). Sempre recalculado.
  double get fib4 => (age * ast) / (platelets * math.sqrt(alt));
}
