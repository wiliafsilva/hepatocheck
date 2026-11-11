import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/usecases/validate_drink_input.dart';

void main() {
  final now = DateTime(2026, 11, 11, 21);
  final validate = ValidateDrinkInput(now: () => now);

  test('aceita um registro válido com vírgula decimal', () {
    final result = validate(
      volume: '350',
      alcohol: '4,5',
      quantity: 2,
      consumedAt: now,
    );

    expect(result.isValid, isTrue);
    expect(result.volumeMl, 350);
    expect(result.alcoholPercent, 4.5);
    expect(result.quantity, 2);
  });

  test('recusa volume vazio, não numérico ou fora de 1 a 3000 ml', () {
    for (final volume in ['', 'abc', '0', '3001']) {
      final result = validate(
        volume: volume,
        alcohol: '5',
        quantity: 1,
        consumedAt: now,
      );
      expect(
        result.errors.containsKey(DrinkField.volume),
        isTrue,
        reason: volume,
      );
    }
  });

  test('recusa teor alcoólico fora de 0,5% a 96%', () {
    for (final alcohol in ['', '0,4', '97']) {
      final result = validate(
        volume: '350',
        alcohol: alcohol,
        quantity: 1,
        consumedAt: now,
      );
      expect(
        result.errors.containsKey(DrinkField.alcohol),
        isTrue,
        reason: alcohol,
      );
    }
  });

  test('recusa quantidade fora de 1 a 50', () {
    for (final quantity in [0, 51]) {
      final result = validate(
        volume: '350',
        alcohol: '5',
        quantity: quantity,
        consumedAt: now,
      );
      expect(result.errors.containsKey(DrinkField.quantity), isTrue);
    }
  });

  test('recusa data ausente ou no futuro', () {
    final missing = validate(
      volume: '350',
      alcohol: '5',
      quantity: 1,
      consumedAt: null,
    );
    final future = validate(
      volume: '350',
      alcohol: '5',
      quantity: 1,
      consumedAt: now.add(const Duration(hours: 1)),
    );

    expect(missing.errors.containsKey(DrinkField.consumedAt), isTrue);
    expect(future.errors.containsKey(DrinkField.consumedAt), isTrue);
  });
}
