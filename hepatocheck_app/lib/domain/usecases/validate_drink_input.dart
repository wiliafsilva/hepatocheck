enum DrinkField { volume, alcohol, quantity, consumedAt }

class DrinkValidation {
  const DrinkValidation({
    required this.errors,
    this.volumeMl,
    this.alcoholPercent,
    this.quantity,
    this.consumedAt,
  });

  final Map<DrinkField, String> errors;
  final double? volumeMl;
  final double? alcoholPercent;
  final int? quantity;
  final DateTime? consumedAt;

  bool get isValid => errors.isEmpty;
}

class ValidateDrinkInput {
  const ValidateDrinkInput({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const minVolume = 1.0;
  static const maxVolume = 3000.0;
  static const minAlcohol = 0.5;
  static const maxAlcohol = 96.0;
  static const minQuantity = 1;
  static const maxQuantity = 50;
  static const futureTolerance = Duration(minutes: 5);

  DrinkValidation call({
    required String volume,
    required String alcohol,
    required int quantity,
    required DateTime? consumedAt,
  }) {
    final errors = <DrinkField, String>{};

    final volumeMl = _parse(volume);
    if (volumeMl == null) {
      errors[DrinkField.volume] = 'Informe o volume em ml.';
    } else if (volumeMl < minVolume || volumeMl > maxVolume) {
      errors[DrinkField.volume] = 'Use um volume entre 1 e 3000 ml.';
    }

    final alcoholPercent = _parse(alcohol);
    if (alcoholPercent == null) {
      errors[DrinkField.alcohol] = 'Informe o teor alcoólico.';
    } else if (alcoholPercent < minAlcohol || alcoholPercent > maxAlcohol) {
      errors[DrinkField.alcohol] = 'Use um teor entre 0,5% e 96%.';
    }

    if (quantity < minQuantity || quantity > maxQuantity) {
      errors[DrinkField.quantity] = 'Use uma quantidade entre 1 e 50.';
    }

    if (consumedAt == null) {
      errors[DrinkField.consumedAt] = 'Informe quando foi o consumo.';
    } else if (consumedAt.isAfter(_now().add(futureTolerance))) {
      errors[DrinkField.consumedAt] = 'A data não pode estar no futuro.';
    }

    return DrinkValidation(
      errors: errors,
      volumeMl: errors.containsKey(DrinkField.volume) ? null : volumeMl,
      alcoholPercent: errors.containsKey(DrinkField.alcohol)
          ? null
          : alcoholPercent,
      quantity: errors.containsKey(DrinkField.quantity) ? null : quantity,
      consumedAt: errors.containsKey(DrinkField.consumedAt) ? null : consumedAt,
    );
  }

  static double? _parse(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}
