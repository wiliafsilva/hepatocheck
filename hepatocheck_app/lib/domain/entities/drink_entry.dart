import 'drink_type.dart';

class DrinkEntry {
  const DrinkEntry({
    required this.id,
    required this.type,
    required this.volumeMl,
    required this.alcoholPercent,
    required this.quantity,
    required this.consumedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DrinkType type;
  final double volumeMl;
  final double alcoholPercent;
  final int quantity;
  final DateTime consumedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DrinkEntry copyWith({
    DrinkType? type,
    double? volumeMl,
    double? alcoholPercent,
    int? quantity,
    DateTime? consumedAt,
    DateTime? updatedAt,
  }) {
    return DrinkEntry(
      id: id,
      type: type ?? this.type,
      volumeMl: volumeMl ?? this.volumeMl,
      alcoholPercent: alcoholPercent ?? this.alcoholPercent,
      quantity: quantity ?? this.quantity,
      consumedAt: consumedAt ?? this.consumedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
